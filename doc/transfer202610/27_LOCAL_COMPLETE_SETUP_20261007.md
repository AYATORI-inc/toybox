# ローカル環境完全セットアップガイド - Caddy なし
**作成日**: 2026/10/07 11:45 JST  
**目的**: docker-compose を完成させてローカルで検証 → 新規サーバーへ持っていく

---

## 🎯 目標

1. ✅ **ローカルで docker-compose.yml を完成** (Caddy なし)
2. ✅ **20260930 のバックアップをローカルにインポート**
3. ✅ **ローカルで完全に動作確認**
4. ✅ **新規サーバーへ移行**

---

## 📦 現在の状態

### ローカルリポジトリ

```
✅ docker-compose.yml              ← 新規作成（Caddy なし）
✅ backend/Dockerfile              ← 存在
✅ backend/requirements.txt         ← 存在
✅ 20260930/toybox_20260929_210014.dump        ← DB バックアップ
✅ 20260930/media_volume_20260929_210020.tar.gz ← メディア (5.8GB)
```

---

## 🚀 ステップバイステップ実行

### Step 1: .env ファイルをローカルに作成

```bash
cd C:\github\toybox

# .env ファイルを作成（開発用）
cat > .env << 'EOF'
DEBUG=False
DB_HOST=db
DB_NAME=toybox
DB_USER=toybox_user
DB_PASSWORD=toybox_password
DB_PORT=5432

REDIS_URL=redis://redis:6379/0

ALLOWED_HOSTS=localhost,127.0.0.1

SECURE_SSL_REDIRECT=false
SECURE_HSTS_SECONDS=0

SECRET_KEY=your-secret-key-local-development-only

CELERY_BROKER_URL=redis://redis:6379/0
CELERY_RESULT_BACKEND=redis://redis:6379/0

# Email（ローカルでは送信しない）
EMAIL_BACKEND=django.core.mail.backends.console.EmailBackend
EOF

# 確認
cat .env
```

### Step 2: docker-compose で全サービス起動

```bash
cd C:\github\toybox

# イメージのビルド & コンテナ起動
docker-compose up -d

# ステータス確認
docker-compose ps

# 期待される出力:
# NAME              STATUS            PORTS
# toybox-web-1      Up (healthy)      0.0.0.0:8000->8000/tcp
# toybox-db-1       Up (healthy)
# toybox-redis-1    Up (healthy)
# toybox-worker-1   Up
# toybox-beat-1     Up
```

### Step 3: データベースにバックアップをリストア

```bash
cd C:\github\toybox

# DB コンテナへダンプファイルをコピー
docker cp 20260930/toybox_20260929_210014.dump toybox-db-1:/tmp/toybox.dump

# リストア実行
docker exec toybox-db-1 pg_restore -U toybox_user -d toybox /tmp/toybox.dump

# 確認
docker exec toybox-db-1 psql -U toybox_user -d toybox -c "SELECT COUNT(*) FROM auth_user;"

# 期待される出力: 60 (ユーザー数)
```

### Step 4: メディアボリュームを展開

```bash
cd C:\github\toybox

# メディアボリュームを展開
docker exec toybox-web-1 mkdir -p /app/public/uploads

# tar を展開（別ウィンドウで）
cd 20260930
tar -xzf media_volume_20260929_210020.tar.gz -C ../backend/public/uploads/

# または WSL/Docker経由:
docker cp 20260930/media_volume_20260929_210020.tar.gz toybox-web-1:/tmp/
docker exec toybox-web-1 tar -xzf /tmp/media_volume_20260929_210020.tar.gz -C /app/public/uploads/

# 確認
docker exec toybox-web-1 ls -la /app/public/uploads/ | head -20
```

### Step 5: Django マイグレーション実行

```bash
cd C:\github\toybox

# マイグレーション実行
docker-compose exec web python manage.py migrate

# スーパーユーザー作成（必要なら）
docker-compose exec web python manage.py createsuperuser
```

### Step 6: スタティックファイル収集

```bash
cd C:\github\toybox

# スタティックファイル収集
docker-compose exec web python manage.py collectstatic --noinput
```

### Step 7: ローカルで動作確認

```bash
# ヘルスチェック
curl http://localhost:8000/api/health/

# 期待される出力:
# {"status":"ok"}

# 管理画面にアクセス
# http://localhost:8000/admin/
# ユーザー: (復元したユーザー)
# パスワード: (復元したパスワード)

# API にアクセス
# http://localhost:8000/api/
```

---

## 📋 完全なコマンドチェーン（まとめ）

```bash
cd C:\github\toybox

# 1. .env 作成
cat > .env << 'EOF'
DEBUG=False
DB_HOST=db
DB_NAME=toybox
DB_USER=toybox_user
DB_PASSWORD=toybox_password
REDIS_URL=redis://redis:6379/0
ALLOWED_HOSTS=localhost,127.0.0.1
SECRET_KEY=dev-key-local-only
EMAIL_BACKEND=django.core.mail.backends.console.EmailBackend
EOF

# 2. コンテナ起動
docker-compose up -d

# 3. DB バックアップ復元
docker cp 20260930/toybox_20260929_210014.dump toybox-db-1:/tmp/toybox.dump
docker exec toybox-db-1 pg_restore -U toybox_user -d toybox /tmp/toybox.dump

# 4. マイグレーション
docker-compose exec web python manage.py migrate

# 5. スタティックファイル
docker-compose exec web python manage.py collectstatic --noinput

# 6. メディア展開
docker exec toybox-web-1 mkdir -p /app/public/uploads
docker cp 20260930/media_volume_20260929_210020.tar.gz toybox-web-1:/tmp/
docker exec toybox-web-1 tar -xzf /tmp/media_volume_20260929_210020.tar.gz -C /app/public/uploads/

# 7. 確認
curl http://localhost:8000/api/health/
docker-compose ps
```

---

## ✅ ローカルでの検証チェックリスト

```
[ ] docker-compose up -d で全サービス起動
[ ] docker-compose ps で全コンテナ healthy
[ ] curl http://localhost:8000/api/health/ → {"status":"ok"}
[ ] DB ユーザー数: 60
[ ] DB 記事数確認
[ ] メディアファイル展開確認
[ ] http://localhost:8000/admin/ にアクセス可能
[ ] API エンドポイント動作確認
[ ] Celery worker ログ確認
[ ] Celery beat ログ確認
```

---

## 🔄 ローカル → 新規サーバーへの移行

### ローカルで検証完了後

```bash
# 1. docker-compose.yml を Git にコミット
git add docker-compose.yml
git commit -m "chore: Add complete docker-compose without Caddy

- Complete services: web, db, redis, worker, beat
- No Caddy (Nginx later)
- Ready for production deployment
- Local testing complete"

git push origin main

# 2. 新規サーバーで git pull
ssh root@192.168.122.140
cd /var/www/toybox
git pull origin main

# 3. .env を新規サーバー用に設定
# (本番用の .env 値を設定)

# 4. 新規サーバーで起動
docker-compose up -d

# 5. バックアップをリストア
docker cp /tmp/toybox_20260929_210014.dump toybox-db-1:/tmp/
docker exec toybox-db-1 pg_restore -U toybox_user -d toybox /tmp/toybox.dump

# 6. マイグレーション＆検証
docker-compose exec web python manage.py migrate
curl http://localhost:8000/api/health/
```

---

## 📊 docker-compose.yml の構成

| サービス | ポート | 用途 | ヘルスチェック |
|---------|--------|------|----------------|
| web | 8000 | Gunicorn | curl /api/health/ |
| db | (internal) | PostgreSQL 15 | pg_isready |
| redis | (internal) | Redis 7 | redis-cli ping |
| worker | (internal) | Celery worker | - |
| beat | (internal) | Celery beat | - |

---

## ⚠️ トラブルシューティング

### Issue: `docker-compose: command not found`

```bash
# 解決策
docker compose --version  # v2 を使用（ハイフンなし）

# または
docker-compose.exe --version  # Windows
```

### Issue: DB 復元失敗

```bash
# ユーザー確認
docker exec toybox-db-1 psql -U toybox_user -d toybox -c "\du"

# テーブル確認
docker exec toybox-db-1 psql -U toybox_user -d toybox -c "\dt"
```

### Issue: メディア展開失敗

```bash
# パーミッション確認
docker exec toybox-web-1 ls -la /app/public/uploads/

# 手動マウント確認
docker inspect toybox-web-1 | grep -A 10 "Mounts"
```

### Issue: Celery worker が起動しない

```bash
# ログ確認
docker-compose logs worker

# Redis 接続確認
docker-compose exec worker redis-cli -u redis://redis:6379/0 ping
```

---

## 📝 新規サーバー用の .env テンプレート

```env
# 本番環境用
DEBUG=False
DB_HOST=db
DB_NAME=toybox
DB_USER=toybox_user
DB_PASSWORD=your-strong-password-here
DB_PORT=5432

REDIS_URL=redis://redis:6379/0

ALLOWED_HOSTS=toybox.ayatori-inc.co.jp,localhost,127.0.0.1

SECURE_SSL_REDIRECT=false
SECURE_HSTS_SECONDS=0

SECRET_KEY=your-secure-secret-key-here

CELERY_BROKER_URL=redis://redis:6379/0
CELERY_RESULT_BACKEND=redis://redis:6379/0

# Email
EMAIL_HOST=smtp.mail1006.conoha.ne.jp
EMAIL_PORT=587
EMAIL_USE_TLS=true
EMAIL_HOST_USER=contact@toybox.ayatori-inc.co.jp
EMAIL_HOST_PASSWORD=your-smtp-password
DEFAULT_FROM_EMAIL=no-reply@toybox.local
CONTACT_EMAIL=maki@ayatori-inc.co.jp
```

---

**ステータス**: 📋 ローカル完全セットアップガイド完成  
**次のステップ**: ローカルで Step 1-7 を実行 → Git コミット → 新規サーバーへ

