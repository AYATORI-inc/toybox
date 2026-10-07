# ローカル環境 - クイックスタート
**作成日**: 2026/10/07 11:48 JST

---

## 🚀 最速実行方法（5分でスタート）

### 前提条件

- ✅ Docker Desktop インストール済み
- ✅ C:\github\toybox にクローン済み
- ✅ 20260930/toybox_20260929_210014.dump 存在
- ✅ 20260930/media_volume_20260929_210020.tar.gz 存在

### 実行コマンド

#### Windows (PowerShell)

```powershell
cd C:\github\toybox

# スクリプト実行（自動でセットアップ）
powershell -File scripts/local-setup.ps1

# または手動で実行
docker-compose up -d --build
```

#### Linux / macOS (Bash)

```bash
cd ~/github/toybox

# スクリプト実行
bash scripts/local-setup.sh

# または手動で実行
docker-compose up -d --build
```

---

## ✅ セットアップチェックリスト

### 起動直後

```bash
# コンテナが全て起動しているか確認
docker-compose ps

# 期待される出力:
# NAME              STATUS            PORTS
# toybox-web-1      Up (healthy)      0.0.0.0:8000->8000/tcp
# toybox-db-1       Up (healthy)
# toybox-redis-1    Up (healthy)
# toybox-worker-1   Up
# toybox-beat-1     Up
```

### ヘルスチェック

```bash
# API が応答しているか確認
curl http://localhost:8000/api/health/

# 期待される出力:
# {"status":"ok"}
```

### DB データ確認

```bash
# ユーザー数確認（60 であることを確認）
docker exec toybox-db-1 psql -U toybox_user -d toybox -c "SELECT COUNT(*) FROM auth_user;"

# 記事数確認
docker exec toybox-db-1 psql -U toybox_user -d toybox -c "SELECT COUNT(*) FROM articles_article;"

# リアクション数確認
docker exec toybox-db-1 psql -U toybox_user -d toybox -c "SELECT COUNT(*) FROM reactions_reaction;"
```

### ブラウザからアクセス

```
API:       http://localhost:8000/api/
管理画面:   http://localhost:8000/admin/
ヘルス:     http://localhost:8000/api/health/
```

---

## 🛑 停止・クリーンアップ

```bash
# コンテナを停止（データ保持）
docker-compose stop

# コンテナを再起動
docker-compose restart

# 完全に削除（ボリューム含む）
docker-compose down -v

# ログ確認
docker-compose logs -f web      # web サーバー
docker-compose logs -f worker   # Celery worker
docker-compose logs -f db       # PostgreSQL
```

---

## 📋 ファイル構成

```
C:\github\toybox/
├── docker-compose.yml              ← 完全な定義（Caddy なし）
├── .env.local                       ← ローカル用 .env テンプレート
├── .env                             ← コピーして使用（.gitignore）
├── backend/
│   ├── Dockerfile
│   ├── manage.py
│   └── requirements.txt
├── scripts/
│   ├── local-setup.ps1              ← Windows 自動セットアップ
│   └── local-setup.sh               ← Linux/macOS 自動セットアップ
├── 20260930/
│   ├── toybox_20260929_210014.dump
│   └── media_volume_20260929_210020.tar.gz
└── doc/
    └── transfer202610/
        └── 27_LOCAL_COMPLETE_SETUP_20261007.md
```

---

## 🔄 ローカルテスト完了後

1. **docker-compose.yml を Git にコミット**

```bash
git add docker-compose.yml
git commit -m "chore: Add complete docker-compose without Caddy"
git push origin main
```

2. **新規サーバーで pull**

```bash
ssh root@192.168.122.140
cd /var/www/toybox
git pull origin main
```

3. **新規サーバーで実行**

```bash
# .env を本番用に設定後
docker-compose up -d --build

# バックアップリストア
docker cp /tmp/toybox_20260929_210014.dump toybox-db-1:/tmp/
docker exec toybox-db-1 pg_restore -U toybox_user -d toybox /tmp/toybox.dump

# 検証
curl http://localhost:8000/api/health/
```

---

## 📊 docker-compose.yml の内容確認

```bash
# 定義されているサービスを確認
docker-compose config --services

# 期待される出力:
# beat
# db
# redis
# web
# worker
```

---

## ⚠️ トラブルシューティング

### Q: メディアが展開されない

```bash
# ボリュームマウント確認
docker inspect toybox-web-1 | grep -A 5 "media_volume"

# アップロードフォルダの内容確認
docker exec toybox-web-1 ls -la /app/public/uploads/ | head -10
```

### Q: DB データが復元されない

```bash
# ダンプファイルの確認
docker exec toybox-db-1 ls -la /tmp/toybox.dump

# リストア ログ確認
docker-compose logs db | tail -50
```

### Q: API が応答しない

```bash
# web コンテナのログ
docker-compose logs web | tail -100

# ポート確認
docker-compose ps | grep web
```

---

**ステータス**: 🚀 ローカル環境完成  
**次のステップ**: スクリプト実行 → Git コミット → 新規サーバーへ移行

