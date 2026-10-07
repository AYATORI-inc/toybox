# 🎮 ToyBox

**Django 5 + DRF + PostgreSQL + Celery + Redis** で構築された、モダンな Web アプリケーション

---

## 📋 目次

- [概要](#概要)
- [技術スタック](#技術スタック)
- [クイックスタート](#クイックスタート)
- [プロジェクト構成](#プロジェクト構成)
- [開発環境のセットアップ](#開発環境のセットアップ)
- [本番環境デプロイメント](#本番環境デプロイメント)
- [バックアップ・復元](#バックアップ復元)
- [API ドキュメント](#api-ドキュメント)
- [トラブルシューティング](#トラブルシューティング)

---

## 概要

**ToyBox** は、ユーザー認証、投稿機能、ゲーミフィケーション、抽選システムなどを備えた包括的な Web プラットフォームです。

### 主な機能

- 🔐 ユーザー認証・プロフィール管理
- 📸 投稿機能（画像アップロード対応）
- 👍 いいね機能・通知システム
- 🎰 抽選・報酬処理
- 🏆 称号・カード収集（ゲーミフィケーション）
- 🎵 Discord シェア機能
- 📊 管理画面

---

## 技術スタック

| レイヤー | 技術 |
|---------|------|
| **バックエンド** | Django 5, Django REST Framework 3.15 |
| **データベース** | PostgreSQL 15 |
| **キャッシュ/ブローカー** | Redis 7 |
| **タスクキュー** | Celery 5.4 + Celery Beat |
| **Web サーバー** | Gunicorn 23 |
| **リバースプロキシ（本番）** | Caddy 2 |
| **コンテナ化** | Docker + Docker Compose |

---

## クイックスタート

### Docker での起動（推奨）

```bash
# ローカル開発環境
docker-compose up -d

# アクセス可能な URL
# - API: http://localhost:8000/api/
# - Admin: http://localhost:8000/admin/
# - Health: http://localhost:8000/api/health/
```

### 本番環境での起動

```bash
# 本番構成（Caddy 付き）
docker-compose -f docker-compose.prod.yml up -d --build
```

---

## プロジェクト構成

```
toybox/
├── backend/                          # Django バックエンド
│   ├── toybox/                       # プロジェクト設定
│   │   ├── settings/
│   │   │   ├── base.py              # 共通設定
│   │   │   └── [その他の環境設定]
│   │   ├── wsgi.py
│   │   └── asgi.py
│   │
│   ├── users/                        # ユーザー認証・プロフィール
│   ├── submissions/                  # 投稿機能
│   ├── lottery/                      # 抽選・報酬処理
│   ├── gamification/                 # 称号・カード収集
│   ├── sharing/                      # SNS シェア
│   ├── articles/                     # ブログ・記事
│   ├── adminpanel/                   # 管理画面
│   ├── frontend/                     # Django テンプレート
│   │
│   ├── manage.py
│   ├── requirements.txt               # Python 依存関係
│   └── Dockerfile
│
├── caddy/                            # リバースプロキシ設定（本番環境）
│   ├── Dockerfile
│   └── Caddyfile
│
├── scripts/                          # ユーティリティスクリプト
│   ├── local-setup.ps1               # ローカル開発環境セットアップ
│   └── cleanup-refactoring.ps1       # クリーンアップ
│
├── doc/transfer202610/               # 移行ドキュメント
├── docker-compose.yml                # ローカル開発環境
├── docker-compose.prod.yml           # 本番環境
└── README.md
```

---

## 開発環境のセットアップ

### 前提条件

- **Docker Desktop** (Windows/Mac) または **Docker Engine** (Linux)
- **Python 3.11+** （ローカル開発の場合）
- **Git**

### 環境変数の設定

```bash
# ローカル開発用
cp backend/.env.local backend/.env

# 本番環境用（必要に応じて）
cp backend/.env.prod backend/.env
```

### 開発サーバーの起動

**方法 1：Docker Compose（推奨）**

```bash
docker-compose up -d
```

**方法 2：ローカル Python**

```bash
cd backend
python -m venv venv

# Windows
.\venv\Scripts\Activate.ps1
# Mac/Linux
source venv/bin/activate

pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

### ローカルアクセス

| 目的 | URL |
|------|-----|
| **API** | http://localhost:8000/api/ |
| **管理画面** | http://localhost:8000/admin/ |
| **ヘルスチェック** | http://localhost:8000/api/health/ |

---

## 本番環境デプロイメント

### 本番環境での起動

```bash
# 本番構成を使用（Caddy + Gunicorn）
docker-compose -f docker-compose.prod.yml up -d --build
```

### 必要な環境変数

```env
# Django
DEBUG=False
ALLOWED_HOSTS=toybox.ayatori-inc.co.jp,localhost
SECRET_KEY=your-production-secret-key

# Database
DB_NAME=toybox
DB_USER=toybox_user
DB_PASSWORD=<strong-password>
DB_HOST=db
DB_PORT=5432

# Redis
REDIS_URL=redis://redis:6379/0

# SSL/TLS (Caddy により自動)
SECURE_SSL_REDIRECT=true
SECURE_HSTS_SECONDS=31536000

# Email
EMAIL_HOST=smtp.mail1006.conoha.ne.jp
EMAIL_PORT=587
EMAIL_USE_TLS=true
EMAIL_HOST_USER=contact@toybox.ayatori-inc.co.jp
EMAIL_HOST_PASSWORD=<smtp-password>
DEFAULT_FROM_EMAIL=no-reply@toybox.local
```

### Caddy の役割（本番環境）

- 🔒 **HTTPS** → Let's Encrypt 自動証明書管理
- 🔄 **HTTP → HTTPS** リダイレクト
- ⚡ **Reverse Proxy** → Gunicorn へのルーティング
- 📦 **Static Files** → 直接配信（gzip 圧縮）
- 📤 **メディアファイル** → Gunicorn へのリバースプロキシ

---

## バックアップ・復元

### 自動バックアップ

本番環境では、毎晩自動的にバックアップが実行されます：

- **PostgreSQL データベース** → `.dump` 形式
- **メディアボリューム** → `.tar.gz` 形式

```bash
# バックアップファイルの場所
/backup/toybox/database/toybox_YYYYMMDD_HHMMSS.dump
/backup/toybox/volumes/media_volume_YYYYMMDD_HHMMSS.tar.gz

# ログ確認
tail -f /var/log/toybox_backup.log
```

### ローカルでの復元

```bash
# ダウンロード
scp root@160.251.168.144:/backup/toybox/database/toybox_*.dump ./20260930/
scp root@160.251.168.144:/backup/toybox/volumes/media_volume_*.tar.gz ./20260930/

# Docker で復元
docker-compose up -d
docker cp ./20260930/toybox_*.dump toybox-db-1:/tmp/
docker exec toybox-db-1 pg_restore -U toybox_user -d toybox -O /tmp/toybox_*.dump
docker cp ./20260930/media_volume_*.tar.gz toybox-web-1:/tmp/
docker exec toybox-web-1 tar -xzf /tmp/media_volume_*.tar.gz -C /app/public/uploads/
```

📖 詳細は [BACKUP_GUIDE.md](./BACKUP_GUIDE.md) を参照してください。

---

## API ドキュメント

### ヘルスチェック

```bash
GET /api/health/
```

**レスポンス:**
```json
{
  "status": "ok"
}
```

### OpenAPI スキーマ

```bash
GET /api/schema/
GET /api/docs/
```

詳細は [backend/README_DJANGO.md](./backend/README_DJANGO.md) を参照してください。

---

## コマンド集

### コンテナ操作

```bash
# すべてのサービスを起動
docker-compose up -d

# ログを確認
docker-compose logs -f web
docker-compose logs -f worker
docker-compose logs -f beat

# サービスを再起動
docker-compose restart web
docker-compose restart db

# すべてを停止・削除
docker-compose down
docker-compose down -v  # ボリュームも削除
```

### Django コマンド

```bash
# マイグレーション実行
docker-compose exec -T web python manage.py migrate

# スタティックファイル収集
docker-compose exec -T web python manage.py collectstatic --noinput

# スーパーユーザー作成
docker-compose exec -T web python manage.py createsuperuser

# シェル起動
docker-compose exec -T web python manage.py shell
```

---

## トラブルシューティング

### ポート競合エラー

```
Error: bind: address already in use
```

**解決方法:**

```bash
# ポート 8000 を使用しているプロセスを確認
lsof -i :8000  # Mac/Linux
netstat -ano | findstr :8000  # Windows

# 別のポートで起動
docker-compose -p toybox-alt up -d
```

### データベース接続エラー

```bash
# PostgreSQL コンテナの状態確認
docker ps | grep postgres

# ログを確認
docker-compose logs db

# コンテナを再起動
docker-compose restart db
```

### メモリ不足エラー

```bash
# Docker のリソース制限を確認・拡張
# Docker Desktop 設定 → Resources を確認

# または手動で制限を設定
docker-compose down
# docker-compose.yml 内で メモリ制限を追加
docker-compose up -d
```

---

## 開発ガイド

詳細な開発ドキュメントは以下を参照してください：

- 📖 [Django 開発ガイド](./backend/README_DJANGO.md)
- 💾 [バックアップ・復元ガイド](./BACKUP_GUIDE.md)
- 🚀 [デプロイメントガイド](./doc/transfer202610/31_TWO_PHASE_EXECUTION_20261007.md)
- 🔧 [トラブルシューティング](./doc/transfer202610/)

---

## ライセンス

Proprietary - All rights reserved
