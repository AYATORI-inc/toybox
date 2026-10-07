# 本番環境 最終アーキテクチャ
**作成日**: 2026/10/07  
**対象**: 新規本番サーバー（toyboxssh.ayatori-inc.co.jp）  
**環境**: CloudFlare Tunnel + Docker Compose

---

## 🏗️ システム全体構成図

```
┌─────────────────────────────────────────────────────────────────┐
│                         ユーザー（インターネット）               │
└──────────────────────────────┬──────────────────────────────────┘
                               │ HTTPS
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                     CloudFlare（CDN + SSL/TLS）                 │
│  - toybox-check.ayatori-inc.co.jp (テスト)                      │
│  - toybox.ayatori-inc.co.jp (本番)                              │
└──────────────────────────────┬──────────────────────────────────┘
                               │ HTTP (CloudFlare Tunnel)
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│               新規本番サーバー（Ubuntu 24.04.4 LTS）             │
│           IP: 192.168.122.140 (VPS/クラウド)                   │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ cloudflared (CloudFlare Tunnel エージェント)               │ │
│  │  - ポート: 8000 → localhost:8000 に転送                    │ │
│  │  - 接続: QUIC/HTTP/2 で CloudFlare に接続                  │ │
│  └────────────────────────────────────────────────────────────┘ │
│                               │ HTTP
│                               ▼
│  ┌────────────────────────────────────────────────────────────┐ │
│  │          Docker Compose（開発用: docker-compose.yml）       │ │
│  │                                                              │ │
│  │  ┌────────────────────────────────────────────────────────┐│ │
│  │  │ toybox-web-1 (Gunicorn)                                ││ │
│  │  │  - Django 5.2 アプリケーション                         ││ │
│  │  │  - ポート: 0.0.0.0:8000                                ││ │
│  │  │  - HealthCheck: /api/health/                           ││ │
│  │  │  - リストア済み: @20260930 バックアップ                ││ │
│  │  │    - ユーザー: 60 件                                    ││ │
│  │  │    - 投稿: 1,853 件                                     ││ │
│  │  │    - メディアファイル: 9,532 個                         ││ │
│  │  └────────────────────────────────────────────────────────┘│ │
│  │                               │                             │ │
│  │  ┌────────────────────────────┴─────────────────────────┐  │ │
│  │  │                              │                       │  │ │
│  │  ▼                              ▼                       ▼  │ │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌──────────┐ │ │
│  │  │ toybox-db-1      │  │ toybox-redis-1   │  │ toybox-  │ │ │
│  │  │ (PostgreSQL 15)  │  │ (Redis 7)        │  │ worker-1 │ │ │
│  │  │                  │  │                  │  │(Celery)  │ │ │
│  │  │ - Port: 5432     │  │ - Port: 6379     │  │ - Celery │ │ │
│  │  │ - DB: toybox     │  │ - Cache/Broker   │  │   Worker │ │ │
│  │  │ - User: 60       │  │ - Session Store  │  └──────────┘ │ │
│  │  │ - Posts: 1,853   │  │                  │  ┌──────────┐ │ │
│  │  │ - Status: healthy│  │ - Status: healthy│  │ toybox-  │ │ │
│  │  │                  │  │                  │  │ beat-1   │ │ │
│  │  │ Volume:          │  │ Volume:          │  │(Celery   │ │ │
│  │  │ - db_data        │  │ - redis_data     │  │ Beat)    │ │ │
│  │  │                  │  │                  │  │ - Beat   │ │ │
│  │  └──────────────────┘  └──────────────────┘  │ Scheduler│ │ │
│  │                                               └──────────┘ │ │
│  │  ┌────────────────────────────────────────────────────────┐│ │
│  │  │ Volumes（永続化ストレージ）                            ││ │
│  │  │  - db_data: PostgreSQL データ                          ││ │
│  │  │  - static_volume: Django スタティックファイル          ││ │
│  │  │  - media_volume: ユーザーアップロードファイル          ││ │
│  │  │    (展開済み: /app/public/uploads → 9,532 ファイル)   ││ │
│  │  └────────────────────────────────────────────────────────┘│ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ ネットワーク: Docker Compose デフォルトネットワーク         │ │
│  │  - ブリッジネットワーク（toybox_default）                 │ │
│  │  - コンテナ間通信: コンテナ名での DNS 解決               │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📊 データフロー

### ユーザーがアクセスしたときの流れ

```
1. ユーザーがブラウザで https://toybox-check.ayatori-inc.co.jp/ にアクセス
                   ↓
2. CloudFlare が HTTPS 通信を終了（SSL/TLS）
                   ↓
3. CloudFlare Tunnel 経由で新規サーバーのポート 8000 に HTTP で転送
                   ↓
4. cloudflared エージェントが localhost:8000 に中継
                   ↓
5. Gunicorn（toybox-web-1）が HTTP リクエストを受け取り
                   ↓
6. Django アプリケーションが処理
   - 必要に応じて PostgreSQL（toybox-db-1）にアクセス
   - 必要に応じて Redis（toybox-redis-1）にアクセス
   - Celery タスク（toybox-worker-1）をトリガー
   - スケジュール済みタスク（toybox-beat-1）を実行
                   ↓
7. レスポンスを HTTP で CloudFlare に返す
                   ↓
8. CloudFlare が HTTPS にラップして ユーザーに返す
```

---

## 🔐 セキュリティレイヤー

| レイヤー | 技術 | 役割 |
|---------|------|------|
| **レイヤー 1** | CloudFlare | DDoS 対策、SSL/TLS 管理、地域ブロック |
| **レイヤー 2** | CloudFlare Tunnel | プライベート接続、SSH トンネルなし |
| **レイヤー 3** | Django | ALLOWED_HOSTS チェック、CSRF 保護 |
| **レイヤー 4** | Docker ネットワーク | コンテナ間の隔離 |

---

## 🔄 ストレージ・永続化

| ストレージ | 内容 | 容量 | バックアップ |
|-----------|------|------|------------|
| **db_data** | PostgreSQL データベース | ~200MB | DB ダンプ形式 |
| **media_volume** | ユーザーアップロード | 5.5GB | tar.gz 圧縮 |
| **static_volume** | Django スタティック | 184 ファイル | tar.gz 圧縮 |

---

## 🚀 本番運用のポイント

### 起動順序
```
1. PostgreSQL（db_data） → 起動
2. Redis（redis_data） → 起動
3. Gunicorn（web） → 起動（db & redis に依存）
4. Celery Worker（worker） → 起動（db & redis に依存）
5. Celery Beat（beat） → 起動（db & redis に依存）
```

### 停止順序（逆順）
```
1. Celery Beat → 停止
2. Celery Worker → 停止
3. Gunicorn → 停止
4. Redis → 停止
5. PostgreSQL → 停止
```

### ヘルスチェック
```
curl https://toybox-check.ayatori-inc.co.jp/api/health/
# 期待: {"status": "ok"}
```

---

## 📝 現在の構成サマリー

### ✅ 採用した技術
- **Web サーバー**: Gunicorn（Django 標準）
- **リバースプロキシ**: CloudFlare Tunnel（Caddy 不要）
- **SSL/TLS**: CloudFlare 管理
- **コンテナオーケストレーション**: Docker Compose
- **キャッシュ/ブローカー**: Redis
- **データベース**: PostgreSQL 15

### ❌ 不採用（理由）
- **Caddy**: CloudFlare Tunnel が HTTP トラフィック管理のため不要
  - Let's Encrypt の設定が複雑
  - CloudFlare が既に SSL を管理している

### 💾 バックアップ戦略
- **DB**: pg_restore 形式で保存
- **メディア**: tar.gz 圧縮で保存
- **スケジュール**: 毎日自動実行推奨

---

## 🎯 次のステップ

### 本番切替（DNS更新）
```
CloudFlare DNS を更新：
toybox.ayatori-inc.co.jp → CloudFlare Tunnel（新規サーバー）
```

### 最新バックアップリストア（オプション）
```
1. 最新バックアップをダウンロード
2. DB をリストア
3. メディアボリュームを再展開
4. アプリを再起動
```

---

## 📞 トラブルシューティング

### 502 Bad Gateway が表示される場合
- CloudFlare Tunnel の設定を確認（ポート 8000 を指定しているか）
- Gunicorn が起動しているか確認：`docker compose ps`

### ALLOWED_HOSTS エラー
- docker-compose.yml の ALLOWED_HOSTS に新しいドメインが含まれているか確認
- コンテナを再作成：`docker compose down && docker compose up -d`

### データベース接続エラー
- PostgreSQL が起動しているか確認：`docker compose ps`
- DB ポート 5432 が開いているか確認

---

**作成日**: 2026/10/07  
**最後更新**: 2026/10/07 14:47 JST  
**ステータス**: ✅ テスト環境稼働中（toybox-check.ayatori-inc.co.jp）
