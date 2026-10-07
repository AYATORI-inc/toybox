# 既存本番サーバー完全仕様書（2026/10/07 確定版）

**作成日**: 2026/10/07 11:22 JST  
**ステータス**: ✅ 完全に把握 - 本番移行準備完了

---

## 🔍 本番サーバー構成（確定版）

### Caddy リバースプロキシ - 完全設定

**ドメイン**: `toybox.ayatori-inc.co.jp`

**リバースプロキシ先**: `web:8000` (toybox-web-1 コンテナ)

**ルーティング設定**:

```
✅ 大容量アップロード (/api/submit/upload*)
   - リバースプロキシ: web:8000
   - タイムアウト: read 600s, write 600s
   - 用途: 動画・ゲーム ZIP アップロード

✅ API エンドポイント (/api/*)
   - リバースプロキシ: web:8000
   - タイムアウト: read 30s, write 30s

✅ 静的ファイル (/static/*)
   - ローカルファイルサーバー
   - パス: /app/staticfiles
   - ストリップ: /static プリフィックス削除
   - 直接配信（リバースプロキシ不要）

✅ アップロードファイル (/uploads/*)
   - リバースプロキシ: web:8000
   - タイムアウト: read 60s, write 60s
   - Django メディア配信

✅ ファビコン (/favicon.ico)
   - リバースプロキシ: web:8000

✅ ヘルスチェック (/health)
   - リバースプロキシ: web:8000

✅ SSO エンドポイント (/sso/*)
   - リバースプロキシ: web:8000
   - タイムアウト: read 90s, write 90s
   - 認証処理用（タイムアウト延長）

✅ その他のリクエスト（デフォルト）
   - リバースプロキシ: web:8000
   - タイムアウト: read 30s, write 30s
```

**ヘッダー設定**:
```
X-Forwarded-Proto: {scheme}    ← HTTP/HTTPS プロトコル転送
X-Forwarded-For: {remote_host} ← クライアント IP 転送
```

**エンコーディング**: gzip 圧縮有効

**SSL/TLS**: ✅ HTTPS対応（Let's Encrypt 推定）

### docker-compose.prod.yml 設定

```yaml
services:
  caddy:
    build:
      context: .
      dockerfile: Dockerfile.caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - caddy-data:/data
      - caddy-config:/config
      - backend_static_volume:/app/staticfiles:ro
    networks:
      - toybox_default

networks:
  toybox_default:
    external: true

volumes:
  caddy-data:
  caddy-config:
  backend_static_volume:
    external: true
    name: backend_static_volume
```

### ディスク使用状況（詳細）

| パス | サイズ | 説明 |
|------|--------|------|
| backend/ | 1.9G | Django アプリケーション |
| static/ | 51M | 開発用スタティックファイル |
| scripts/ | 84K | バックアップ・ユーティリティ |
| deploy/ | 44K | デプロイスクリプト |
| server/ | 16K | サーバー設定 |
| staticfiles/ | 4.0K | 収集済みスタティックファイル |
| **uploads** | **≈5.8GB** | **メディアボリューム（シンボリックリンク）** |

**総容量**: ≈ 1.95GB (uploads を除く)

### メディアボリューム

**パス**: `/var/www/toybox/backend/public/uploads/`  
**アクセス**: シンボリックリンク `uploads -> /var/www/toybox/backend/public/uploads`  
**推定サイズ**: ≈ 5.8GB（バックアップから）  
**状態**: 🔴 ディスク容量逼迫 (84.7% 使用中)

### 環境変数 (.env)

```env
# Django Settings
SECRET_KEY=your-secret-key-here-change-in-production
DEBUG=False
ALLOWED_HOSTS=toybox.ayatori-inc.co.jp
CSRF_TRUSTED_ORIGINS=https://toybox.ayatori-inc.co.jp

# Database
DB_NAME=toybox
DB_USER=postgres
DB_PASSWORD=postgres
DB_HOST=127.0.0.1        # ← Docker 内部
DB_PORT=5432

# Redis
REDIS_URL=redis://127.0.0.1:6379/0  # ← Docker 内部

# Security
SECURE_SSL_REDIRECT=true
SECURE_HSTS_SECONDS=31536000        # ← 本番設定（31536000秒 = 1年）
CORS_ORIGINS=https://toybox.ayatori-inc.co.jp

# Email (SMTP)
EMAIL_HOST=smtp.mail1006.conoha.ne.jp
EMAIL_PORT=587
EMAIL_USE_TLS=true
EMAIL_HOST_USER=contact@toybox.ayatori-inc.co.jp
EMAIL_HOST_PASSWORD=replace-with-smtp-password
DEFAULT_FROM_EMAIL=no-reply@toybox.local
CONTACT_EMAIL=maki@ayatori-inc.co.jp

# Discord (未設定)
DISCORD_CLIENT_ID=
DISCORD_CLIENT_SECRET=
DISCORD_REDIRECT_URI=
DISCORD_BOT_TOKEN=
DISCORD_CHANNEL_ID=

# AWS S3 (未使用)
USE_S3=false
```

---

## 🐳 Docker コンテナ構成（確定版）

### 本番稼働中（3ヶ月以上）

| # | コンテナ | イメージ | ステータス | 用途 |
|----|---------|---------|----------|------|
| 1 | toybox-caddy-1 | toybox-caddy | ✅ Up 3 months | リバースプロキシ (80/443) |
| 2 | toybox-web-1 | toybox-web | ✅ Up 3 months | Django Gunicorn (8000) |
| 3 | toybox-worker-1 | toybox-worker | ✅ Up 3 months | Celery ワーカー |
| 4 | toybox-beat-1 | toybox-beat | ✅ Up 3 months | Celery スケジューラー |
| 5 | toybox-db-1 | postgres:15-alpine | ✅ Up 3 months | PostgreSQL 15 (5432) |
| 6 | toybox-redis-1 | redis:7-alpine | ✅ Up 3 months | Redis 7 (6379) |

### テスト環境（14時間前から稼働 → 失敗）

| # | コンテナ | イメージ | ステータス | 用途 | 状態 |
|----|---------|---------|----------|------|------|
| 7 | backend-web-1 | backend-web | ✅ Up 14 hours | Django テスト | 稼働中 |
| 8 | backend-db-1 | postgres:15-alpine | ✅ Up 14 hours | PostgreSQL テスト | 稼働中 |
| 9 | backend-redis-1 | redis:7-alpine | ✅ Up 14 hours | Redis テスト | 稼働中 |
| 10 | backend-worker-1 | backend-worker | ❌ Exited (1) 13h ago | Celery テスト | **失敗** |
| 11 | backend-beat-1 | backend-beat | ❌ Exited (1) 13h ago | Celery Beat テスト | **失敗** |

**注**: backend-* は削除予定の古いテスト環境と考えられます

### ネットワーク構成

```
外部トラフィック
    ↓
toybox-caddy-1 (ポート 80/443)
    ↓
web:8000 (toybox-web-1)
    ↓
toybox-db-1 / toybox-redis-1

ネットワーク: toybox_default (外部: true)
```

### ボリューム構成

```
caddy-data: /data
  ├─ SSL 証明書
  └─ Let's Encrypt キャッシュ

caddy-config: /config
  └─ Caddy 設定キャッシュ

backend_static_volume:
  └─ Django static files
  └─ 読み取り専用マウント (:ro)
```

---

## 📊 本番ログ分析

### toybox-web-1 ログ（2026/10/07 11:17-11:41）

**状況**: ✅ 正常稼働中

**ログパターン**:
```
✅ 画像処理ログ（デバッグ出力）
   - User 55, 54 のプロフィール画像キャッシュ確認
   - URL: https://toybox.ayatori-inc.co.jp/uploads/profiles/*

✅ タイトル処理ログ
   - User 55: "コラムニスト" (タイトルなし)
   - User 54: "駆け出しクリエイター" (タイトルあり)

⚠️ 小さな警告
   - User 55 - Title object not found for "コラムニスト"
   - ただし、処理は正常に完了

✅ 最終ステータス
   - activeTitle 正常返却
   - activeTitleImageUrl 正常返却
```

**API応答時間**: ≈ 200-400ms（正常範囲）

### Gunicorn ログ（2026/10/03-2026/10/06）

**パターン**:
```
[2026-10-XX 12:04:XX +0000] [1] [INFO] Starting gunicorn 23.0.0
[2026-10-XX 12:04:XX +0000] [1] [INFO] Listening at: http://0.0.0.0:8000 (1)
[2026-10-XX 12:04:XX +0000] [8-11] [INFO] Booting worker with pid: X

（稼働...）

[2026-10-XX 12:00:XX +0000] [1] [INFO] Handling signal: term
[2026-10-XX 21:00:XX +0900] [8-11] [INFO] Worker exiting (pid: X)
```

**パターン解釈**:
- 1日1回、UTC 12:00 (JST 21:00) にグレースフルシャットダウン
- 新しいプロセスが即座に起動
- エラーなし ✅

---

## ⚠️ 既知の問題・注意点

### リスク 1: ディスク容量逼迫
```
使用率: 84.7% (98.24GB 中)
残り: ≈ 15GB
```
**対策**: バックアップ取得後、即座にローカル転送、削除

### リスク 2: メモリ高負荷
```
使用率: 84%
Swap: 54%
```
**対策**: 新規本番への移行で解決

### リスク 3: Git にコミットなし
```
ブランチ: master
状態: fatal: your current branch 'master' does not have any commits yet
```
**対策**: 新規本番は git clone で構築済み → 新規本番を使用

### リスク 4: システム再起動必要
```
*** System restart required ***
```
**対策**: 移行後に実施可能

### 小さな警告（無視可能）
```
WARNING: Title object not found for "コラムニスト"
```
**原因**: ユーザーデータの不整合（軽微）  
**影響**: API 応答には問題なし

---

## ✅ 本番移行可能性

| 項目 | 評価 | 根拠 |
|------|------|------|
| **安定性** | ⭐⭐⭐⭐⭐ | 3ヶ月以上連続稼働 |
| **パフォーマンス** | ⭐⭐⭐⭐ | API応答 200-400ms |
| **セキュリティ** | ⭐⭐⭐⭐ | HTTPS 対応、HSTS有効 |
| **リソース** | ⭐⭐ | ディスク逼迫、メモリ高負荷 |
| **Git管理** | ⭐ | コミットなし（新規本番で解決） |

**総合評価**: 🟢 **本番移行可能・推奨**

---

## 📋 移行前最終チェックリスト

- [x] Caddy 設定確認済み
- [x] docker-compose.prod.yml 確認済み
- [x] ディスク使用状況把握済み
- [x] ログ確認（エラーなし）
- [x] リソース逼迫把握済み
- [ ] バックアップ取得（火曜実施予定）
- [ ] 新規本番でのテスト（火曜実施予定）
- [ ] DNS 切替準備（水曜実施予定）

---

**ステータス**: ✅ 既存本番の完全把握完了  
**次のステップ**: 火曜朝にバックアップ取得開始

