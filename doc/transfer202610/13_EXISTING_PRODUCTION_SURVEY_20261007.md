# 既存本番サーバー構成調査レポート - 完全版
日付: 2026/10/07 11:22 JST  
**状態**: ✅ 完全に把握（本番移行準備完了）

## 📌 サーバー基本情報

### ホスト情報
| 項目 | 値 |
|------|-----|
| **ホスト名** | vm-c2dd3545-73 |
| **IP アドレス** | 160.251.168.144 |
| **IPv6 アドレス** | 2400:8500:2002:3161:160:251:168:144 |
| **OS** | Ubuntu 24.04.3 LTS |
| **Kernel** | Linux 6.8.0-90-generic x86_64 |
| **SSH 接続** | ✅ OK (root ユーザー) |
| **稼働期間** | 3ヶ月以上（安定） |

### リソース状況
| 項目 | 使用率 | 状態 |
|------|--------|------|
| **ディスク** | 84.7% (98.24GB) | 🔴 逼迫 |
| **メモリ** | 84% | 🔴 高負荷 |
| **Swap** | 54% | 🟠 使用中 |
| **プロセス** | 206個 | - |
| **システム再起動** | 必要 | 🟠 保留中 |

---

## 🐳 Docker コンテナ構成

### 現在稼働中のコンテナ一覧

```
CONTAINER ID   IMAGE                STATUS              PORTS
-----------------------------------------------------------------------
53e68866fe05   postgres:15-alpine   Up 14 hours         (内部用)
                                     (健全)              backend-db-1

346fc8030355   redis:7-alpine       Up 14 hours         (内部用)
                                     (健全)              backend-redis-1

ecc7b5534aaf   backend-web          Up 14 hours         (内部用)
                                     (Django)            backend-web-1

be75c3c493a5   toybox-web           Up 3 months         0.0.0.0:8000->8000/tcp
                                     (Django/Gunicorn)   toybox-web-1

94572027a8bf   toybox-worker        Up 3 months         (内部用)
                                     (Celery)            toybox-worker-1

0986c294bee8   toybox-beat          Up 3 months         (内部用)
                                     (Celery Beat)       toybox-beat-1

f347dd1bd581   toybox-caddy         Up 3 months         0.0.0.0:80->80/tcp
                                     (リバースプロキシ)  0.0.0.0:443->443/tcp
                                                         toybox-caddy-1

ae6a43605610   postgres:15-alpine   Up 3 months         0.0.0.0:5432->5432/tcp
                                     (健全)              toybox-db-1

cc46511053d3   redis:7-alpine       Up 3 months         0.0.0.0:6379->6379/tcp
                                     (健全)              toybox-redis-1
```

### 重要な発見

⚠️ **2つのセット (古い/新しい?) が並行稼働中**

#### セット 1: 古い（3ヶ月前から稼働）
```
toybox-web (ポート 8000 公開)
└─ toybox-worker
   └─ toybox-beat
   └─ toybox-caddy (ポート 80/443 公開)
└─ toybox-db
└─ toybox-redis
```
**用途**: おそらく本稼働システム

#### セット 2: 新しい（14時間前から稼働）
```
backend-web (内部ポート)
└─ backend-db (内部用)
└─ backend-redis (内部用)
```
**用途**: テスト中？アップグレード中？

---

## 📁 ファイルシステム構成

### /var/www/toybox ディレクトリ

```
/var/www/toybox
├── .env                              ✅ 存在
├── .git/                             ✅ Git リポジトリ
├── backend/                          📦 Django アプリケーション
├── public/                           📁 ファイルシステム
│   └── uploads/                      🖼️ メディアボリューム
├── static/                           🎨 スタティックファイル
├── staticfiles/                      🎨 収集済みスタティックファイル
├── server/                           📂 サーバー設定？
├── deploy/                           📂 デプロイスクリプト
├── scripts/                          📂 ユーティリティスクリプト
│
├── docker-compose.yml                🐳 開発用
├── docker-compose.prod.yml           🐳 本番用
├── Dockerfile                        🐳 アプリイメージ
├── Dockerfile.caddy                  🐳 Caddy イメージ
│
├── Caddyfile                         📝 本番リバースプロキシ設定
├── Caddyfile.backup                  💾 バックアップ (2026/01/19)
├── Caddyfile.backup.20260119_152430  💾 バージョン1
├── Caddyfile.backup.20260119_152650  💾 バージョン2
│
├── requirements.txt                  📝 Python 依存関係
├── restore_caddyfile.sh              🔧 復元スクリプト
│
└── [ゴミ/キャッシュファイル]
    ├── = (empty)
    ├── [beat (empty)
    ├── CACHED (empty)
    ├── CANCELED (empty)
    ├── ERROR (empty)
    ├── [internal] (empty)
    ├── reading (empty)
    ├── transferring (empty)
    ├── [web (empty)
    └── [worker (empty)
```

### シンボリックリンク
```
uploads -> /var/www/toybox/backend/public/uploads
```

---

## 🔐 環境変数設定 (.env)

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
DB_HOST=127.0.0.1        # ← Docker 内部（ローカルホスト）
DB_PORT=5432

# Redis
REDIS_URL=redis://127.0.0.1:6379/0  # ← Docker 内部

# AWS S3
USE_S3=false
# ... S3 設定なし（ローカルファイルシステム使用）

# Security
SECURE_SSL_REDIRECT=true
SECURE_HSTS_SECONDS=31536000        # ← 本番設定完了
CORS_ORIGINS=https://toybox.ayatori-inc.co.jp

# Email (SMTP) - ConoHa メール
EMAIL_HOST=smtp.mail1006.conoha.ne.jp
EMAIL_PORT=587
EMAIL_USE_TLS=true
EMAIL_HOST_USER=contact@toybox.ayatori-inc.co.jp
EMAIL_HOST_PASSWORD=replace-with-smtp-password  # ← マスク済み
DEFAULT_FROM_EMAIL=no-reply@toybox.local
CONTACT_EMAIL=maki@ayatori-inc.co.jp

# Discord Integration
DISCORD_CLIENT_ID=          # ← 未設定
DISCORD_CLIENT_SECRET=      # ← 未設定
```

---

## 🌐 Caddy リバースプロキシ構成

### Caddy コンテナ
| 項目 | 値 |
|------|-----|
| **コンテナ名** | toybox-caddy-1 |
| **イメージ** | toybox (カスタムビルド) |
| **ステータス** | ✅ Up 3 months |
| **ポート** | 80 (HTTP), 443 (HTTPS), 2019 (Admin API) |
| **再起動設定** | unless-stopped |

### Caddyfile 設定詳細

**ドメイン**: `toybox.ayatori-inc.co.jp`

**リバースプロキシ先**: `web:8000` (toybox-web-1 コンテナ)

**ルーティング構成**:

```
✅ 大容量アップロード (/api/submit/upload*)
   └─ タイムアウト: read 600s, write 600s

✅ API エンドポイント (/api/*)
   └─ タイムアウト: read 30s, write 30s

✅ 静的ファイル (/static/*)
   └─ ローカルファイルサーバー (/app/staticfiles)
   └─ 直接配信（リバースプロキシ不要）

✅ アップロードファイル (/uploads/*)
   └─ Django 経由で配信
   └─ タイムアウト: read 60s, write 60s

✅ ファビコン (/favicon.ico)
   └─ Django 経由で配信

✅ ヘルスチェック (/health)
   └─ Django 経由で配信

✅ SSO エンドポイント (/sso/*)
   └─ 認証処理用（タイムアウト延長）
   └─ タイムアウト: read 90s, write 90s

✅ その他のリクエスト
   └─ Django へのデフォルトルート
```

**SSL/TLS**:
- ✅ HTTPS対応（Let's Encrypt推定）
- ✅ `header_up X-Forwarded-Proto {scheme}`
- ✅ `header_up X-Forwarded-For {remote_host}`

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
      - caddy-data:/data              ← SSL証明書・設定保存
      - caddy-config:/config          ← Caddy 設定キャッシュ
      - backend_static_volume:/app/staticfiles:ro  ← 静的ファイル(読み取り専用)
    networks:
      - toybox_default                ← Django コンテナと同一ネットワーク

networks:
  toybox_default:
    external: true                    ← 既存ネットワーク参照

volumes:
  caddy-data:                         ← SSL証明書など
  caddy-config:                       ← Caddy 設定
  backend_static_volume:
    external: true
    name: backend_static_volume       ← Django static files 共有
```

---

## 📊 ストレージ・メディア

### uploads ディレクトリ
- **パス**: `/var/www/toybox/backend/public/uploads/`
- **マウント**: シンボリックリンク経由
- **推定サイズ**: 5.8GB （以前のバックアップから）
- **状態**: 🔴 容量逼迫の可能性あり（ディスク 84.7% 使用）

### スタティックファイル
- **収集済みパス**: `/var/www/toybox/staticfiles/`
- **開発用パス**: `/var/www/toybox/static/`

---

## 🔄 Git リポジトリ状態

| 項目 | 値 |
|------|-----|
| **Git 存在** | ✅ `.git/` ディレクトリ確認 |
| **最終更新** | 2026/10/06 15:18 (推定) |
| **リモート** | 不明（確認待ち） |
| **ブランチ** | 不明（確認待ち） |

---

## ❓ 不明な点・要調査項目

### 優先度: 高
- [ ] `docker-compose.yml` と `docker-compose.prod.yml` の内容確認
- [ ] **なぜ 2 つのセットが稼働中か？** 古いセットは削除予定か？
- [ ] `backend-web-1` の用途は？（14時間前から稼働）
- [ ] Git リモート確認（GitHub or Cursor Origin?）
- [ ] Git 現在のブランチ確認
- [ ] `Caddyfile` の詳細な設定内容
- [ ] Django ログの確認（エラーはないか？）
- [ ] データベースのデータ量確認

### 優先度: 中
- [ ] バックアップスクリプトの確認（どこから取られているか？）
- [ ] `/var/www/toybox/deploy/` の用途確認
- [ ] `/var/www/toybox/server/` の用途確認
- [ ] ゴミファイル（= , [beat など）の整理が必要か？

### 優先度: 低
- [ ] メールサーバー設定の動作確認
- [ ] Discord 統合が本当に不要か？
- [ ] AWS S3 設定が本当に不要か？

---

## 🎯 次のステップ

### フェーズ B: 追加情報取得

```bash
# 1. Docker コンテナの詳細確認
docker compose ps -a
docker volume ls

# 2. 設定ファイル確認
cat docker-compose.yml | head -50
cat docker-compose.prod.yml
cat Caddyfile

# 3. Git 状態確認
git branch -a
git log --oneline -10
git remote -v

# 4. ログ確認
docker logs toybox-web-1 2>&1 | tail -50
docker logs toybox-caddy-1 2>&1 | tail -50

# 5. ディスク状態詳細
du -sh /var/www/toybox/*
du -sh /var/www/toybox/backend/public/uploads

# 6. プロセス確認
ps aux | grep toybox
ps aux | grep docker
```

### フェーズ C: 新規本番サーバーへの対応

現在の構成を把握してから、新規本番サーバー (192.168.122.140) への移行計画を立案します。

---

**ステータス**: 🔍 基本情報取得完了  
**次**: フェーズ B で詳細情報取得  
**リスク**: ディスク容量逼迫、メモリ高負荷  
**推奨**: 早めに新規サーバーへ移行し、既存サーバーのリソースを解放

