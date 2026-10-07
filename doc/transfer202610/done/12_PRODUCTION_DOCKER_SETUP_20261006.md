# 新本番サーバー Docker セットアップガイド
日付: 2026/10/06 17:00 JST

## 📋 概要

新本番サーバー（toyboxssh.ayatori-inc.co.jp）に Docker を使用して PostgreSQL、Redis、Django アプリケーション（Gunicorn）、Celery をセットアップする手順。

---

## 🔧 セットアップ手順

### ステップ 1: Docker インストール

新本番サーバーで実行：

```bash
# Docker と Docker Compose をインストール
sudo apt update
sudo apt install -y docker.io docker-compose-v2

# 現在のユーザーを docker グループに追加
sudo usermod -aG docker ayatori

# グループの変更を反映（ログアウト・ログインしたのと同じ効果）
newgrp docker

# 確認
docker --version
docker compose --version
```

### ステップ 2: ディレクトリ構造確認

```bash
cd /var/www/toybox
ls -la

# 期待される構造:
# toybox/
# └── backend/
#     ├── docker-compose.yml
#     ├── Dockerfile
#     ├── manage.py
#     ├── requirements.txt
#     └── ...
```

### ステップ 3: 環境変数ファイル作成

```bash
cd /var/www/toybox/toybox/backend

# .env ファイル作成
cat > .env << 'EOF'
# Django
DJANGO_SETTINGS_MODULE=toybox.settings.prod
SECRET_KEY=your-secret-key-here-change-in-production
DEBUG=False
ALLOWED_HOSTS=toybox-check.ayatori-inc.co.jp,localhost

# Database (PostgreSQL)
DB_NAME=toybox
DB_USER=toybox_user
DB_PASSWORD=your-strong-password-here
DB_HOST=db
DB_PORT=5432

# Redis
REDIS_URL=redis://redis:6379/0

# Email (SMTP) - オプション
EMAIL_HOST=smtp.mail1006.conoha.ne.jp
EMAIL_PORT=587
EMAIL_USE_TLS=true
EMAIL_HOST_USER=contact@toybox.ayatori-inc.co.jp
EMAIL_HOST_PASSWORD=your-smtp-password
DEFAULT_FROM_EMAIL=no-reply@toybox.ayatori-inc.co.jp
CONTACT_EMAIL=maki@ayatori-inc.co.jp

# Discord - オプション
DISCORD_CLIENT_ID=1430428352568889476
DISCORD_CLIENT_SECRET=your-discord-secret
DISCORD_REDIRECT_URI=https://toybox-check.ayatori-inc.co.jp/api/auth/callback/discord
DISCORD_BOT_TOKEN=your-bot-token
DISCORD_CHANNEL_ID=1384344383658393711
DISCORD_GUILD_ID=1384343074494484630

# Security
SECURE_SSL_REDIRECT=false
SECURE_HSTS_SECONDS=0

# Admin URL
ADMIN_URL=manage-toybox-2024
EOF
```

**⚠️ 重要**: 以下を修正してください：
- `SECRET_KEY`: 安全な長いランダム文字列に変更
- `DB_PASSWORD`: 強力なパスワードに変更
- `EMAIL_HOST_PASSWORD`: 実際のメールパスワード
- `DISCORD_*`: 実際の Discord トークン（不要なら削除）

### ステップ 4: Docker ネットワーク作成（Caddy 用）

```bash
# backend_default ネットワーク作成（docker-compose.prod.yml で参照）
docker network create backend_default
```

### ステップ 5: Docker Compose で起動

```bash
cd /var/www/toybox/toybox/backend

# イメージのビルド
docker compose build

# コンテナの起動
docker compose up -d

# ログ確認
docker compose logs -f

# Ctrl+C で終了
```

### ステップ 6: マイグレーション実行

別のターミナルで（docker compose ログが走っている場合）：

```bash
cd /var/www/toybox/toybox/backend

# マイグレーション実行
docker compose exec web python manage.py migrate

# スタティックファイル収集（Docker 内で既に実行されているはず）
docker compose exec web python manage.py collectstatic --noinput

# スーパーユーザー作成（オプション）
docker compose exec web python manage.py createsuperuser
```

### ステップ 7: ヘルスチェック

```bash
# サービス確認
docker compose ps

# PostgreSQL 接続確認
docker compose exec db psql -U toybox_user -d toybox -c "SELECT 1;"

# Redis 接続確認
docker compose exec redis redis-cli ping

# Django ヘルスチェック
curl http://localhost:8000/api/health/ || echo "API not ready"

# Gunicorn ログ確認
docker compose logs web
```

---

## 📊 コンテナ構成

| コンテナ | 目的 | ポート | 注意 |
|---------|------|--------|------|
| **db** | PostgreSQL 15 | 5432 | データベース |
| **redis** | Redis 7 | 6379 | キャッシュ・ブローカー |
| **web** | Gunicorn + Django | 8000 | メインアプリ |
| **worker** | Celery ワーカー | なし | バックグラウンドタスク |
| **beat** | Celery beat | なし | スケジュール実行 |

---

## 🚀 本番運用時の操作

### 再起動

```bash
cd /var/www/toybox/toybox/backend
docker compose restart
```

### ログ確認

```bash
# 全サービスのログ
docker compose logs -f

# 特定サービスのログ
docker compose logs -f web
docker compose logs -f db
docker compose logs -f worker
```

### シェルアクセス

```bash
# Django シェル
docker compose exec web python manage.py shell

# psql（データベース）
docker compose exec db psql -U toybox_user -d toybox

# redis-cli
docker compose exec redis redis-cli
```

### 停止

```bash
docker compose down

# ボリューム削除（データ削除）
docker compose down -v
```

---

## ⚠️ トラブルシューティング

### "Connection refused" エラー

```bash
# サービスが起動しているか確認
docker compose ps

# ログを見る
docker compose logs web
docker compose logs db
```

### PostgreSQL 起動失敗

```bash
# db コンテナの詳細ログ
docker compose logs db

# ボリューム確認
docker volume ls

# リセット（データ削除）
docker compose down -v
docker compose up -d db
```

### ポートが既に使用中

```bash
# ポート確認
netstat -tlnp | grep -E "5432|6379|8000"

# または lsof
lsof -i :5432
lsof -i :6379
lsof -i :8000

# 既存コンテナを停止
docker compose down
```

---

## 📝 チェックリスト

- [ ] Docker / Docker Compose インストール
- [ ] .env ファイル作成・設定
- [ ] バックアップネットワーク作成（backend_default）
- [ ] docker compose build 実行
- [ ] docker compose up -d で起動
- [ ] docker compose ps で全サービス running 確認
- [ ] マイグレーション実行
- [ ] スーパーユーザー作成
- [ ] http://localhost:8000 でアクセス確認
- [ ] API エンドポイント確認
- [ ] ログで エラーなし 確認

---

## 🔗 関連ドキュメント

- `docker-compose.yml` - 開発環境用
- `docker-compose.prod.yml` - 本番用（Caddy）
- `Dockerfile` - Django アプリイメージ
- `PRODUCTION_GOTCHAS_20261006.md` - セットアップ時の注意点

---

**ステータス**: 📋 セットアップガイド完成  
**用途**: 新本番サーバーへの Docker 構築  
**更新**: 不定期（問題発生時に追記）

