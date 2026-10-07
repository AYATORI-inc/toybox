# 本番環境移行実行手順（Step-by-Step）

**作成日**: 2026/10/07  
**対象**: 新規本番サーバー（`toyboxssh.ayatori-inc.co.jp`）への移行  
**前提**: ローカル開発環境がすべてテスト完了済み

---

## 🎯 移行の概要

### 方針
- ✅ 新規本番サーバーをクリーン状態からセットアップ
- ✅ 既存本番サーバー（160.251.168.144）からバックアップをコピー（SCP）
- ✅ Git は混乱を避けるため削除し、以降は SCP で管理
- ✅ Docker Compose で `docker-compose.prod.yml` を使用

### 前提条件
- [ ] 新規本番サーバー（`toyboxssh.ayatori-inc.co.jp`）が起動している
- [ ] SSH ログイン可能（root）
- [ ] Docker / Docker Compose がインストール済み
- [ ] 既存本番サーバー（160.251.168.144）にバックアップ @20260930 がある

---

## 📋 実行チェックリスト

**以下の作業をこのドキュメントに沿って実行してください。**

```
□ Step 1: 新規本番サーバー初期化
  □ 1-1: SSH ログイン
  □ 1-2: Docker 停止・削除
  □ 1-3: ディスク確認
  □ 1-4: リポジトリクローン

□ Step 2: バックアップデータ転送
  □ 2-1: ディレクトリ作成
  □ 2-2: DB ダンプ転送
  □ 2-3: メディアボリューム転送
  □ 2-4: ファイル確認

□ Step 3: Git 削除
  □ 3-1: .git ディレクトリ削除
  □ 3-2: 確認

□ Step 4: 本番環境起動
  □ 4-1: 環境変数準備
  □ 4-2: Docker Compose 起動
  □ 4-3: コンテナ確認

□ Step 5: データリストア
  □ 5-1: DB リストア
  □ 5-2: メディアボリューム展開
  □ 5-3: Django マイグレーション
  □ 5-4: スタティックファイル収集

□ Step 6: ヘルスチェック
  □ 6-1: API 確認
  □ 6-2: ログ確認
  □ 6-3: データ確認

□ Step 7: DNS 切替え
  □ 7-1: DNS レコード更新
  □ 7-2: TTL 待機
  □ 7-3: アクセス確認
```

---

## Step 1: 新規本番サーバー初期化

### 1-1: SSH ログイン

```bash
# ローカル開発マシンから実行
ssh toyboxssh.ayatori-inc.co.jp

# または SSH キーを指定
ssh -i ~/.ssh/toybox-key.pem toyboxssh.ayatori-inc.co.jp
```

**確認**:
```bash
# ホスト名確認
hostname

# OS 確認
cat /etc/os-release

# ディスク確認
df -h
```

### 1-2: Docker 停止・削除

**Caddy の混乱をクリアするため、既存の Docker 環境をすべて削除**

```bash
# コンテナ停止・削除
docker-compose down -v 2>/dev/null || true
docker stop $(docker ps -aq) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true

# イメージ削除
docker system prune -af

# ボリューム削除
docker volume prune -f

# 確認
docker ps -a
docker images
docker volume ls
```

**出力例：**
```
No stopped containers
No images to remove
No volumes to remove
```

### 1-3: ディスク確認

```bash
# ディスク容量確認
df -h

# 最低 10GB 以上の空き容量が必要
# 出力例:
# Filesystem     Size  Used Avail Use% Mounted on
# /dev/sda1      50G   10G   40G  20%  /
```

### 1-4: リポジトリクローン

```bash
# リポジトリクローンディレクトリ作成
mkdir -p /var/www
cd /var/www

# リポジトリをクローン
git clone <origin-url> toybox

# 確認
cd toybox
ls -la
```

**出力確認：**
```
docker-compose.yml ✅
docker-compose.prod.yml ✅
backend/ ✅
caddy/ ✅
README.md ✅
BACKUP_GUIDE.md ✅
```

---

## Step 2: バックアップデータ転送（SCP）

### 2-1: バックアップディレクトリ作成

```bash
# 新規本番サーバーで実行
mkdir -p /backup/toybox/{database,volumes}
ls -lR /backup/toybox/
```

### 2-2: DB ダンプ転送（@20260930 を使用）

```bash
# 新規本番サーバーで実行（別ターミナルで）

# 既存本番サーバーから @20260930 のバックアップをコピー
scp root@160.251.168.144:/backup/toybox/database/toybox_20260930*.dump \
  /backup/toybox/database/

# 確認
ls -lh /backup/toybox/database/
# 出力例:
# toybox_20260929_210014.dump  95M
```

**トラブル：接続できない場合**
```bash
# SSH が起動していないか確認
ssh root@160.251.168.144 "docker ps"

# ファイルが存在するか確認
ssh root@160.251.168.144 "ls -lh /backup/toybox/database/"
```

### 2-3: メディアボリューム転送（@20260930 を使用）

```bash
# 新規本番サーバーで実行
scp root@160.251.168.144:/backup/toybox/volumes/media_volume_20260930*.tar.gz \
  /backup/toybox/volumes/

# 確認
ls -lh /backup/toybox/volumes/
# 出力例:
# media_volume_20260929_210020.tar.gz  5.2G
```

### 2-4: ファイル確認

```bash
# 新規本番サーバーで実行
echo "=== Database ==="
ls -lh /backup/toybox/database/

echo "=== Media Volume ==="
ls -lh /backup/toybox/volumes/

# ファイルサイズが正常か確認（0 バイトでないこと）
```

---

## Step 3: Git 削除（以降は SCP のみ）

### 3-1: Git ディレクトリ削除

```bash
# 新規本番サーバーで実行
cd /var/www/toybox

# .git ディレクトリ削除
rm -rf .git

# 確認
ls -la | grep "^d.*git"
# 出力なし ✅

# Git 不要なので確認
git status
# fatal: not a git repository ✅
```

**重要**: これ以降、変更が必要な場合は SCP で転送します。

---

## Step 4: 本番環境起動

### 4-1: 環境変数準備

```bash
# 新規本番サーバーで実行
cd /var/www/toybox/backend

# ローカル開発用テンプレートをコピー
cp .env.local .env

# 本番環境に合わせて編集
nano .env
# または vi .env
```

**必要な環境変数（本番環境用）:**

```env
# Django
DEBUG=False
ALLOWED_HOSTS=toybox.ayatori-inc.co.jp,192.168.122.140,localhost
SECRET_KEY=<generate-new-strong-secret-key>

# Database
DB_NAME=toybox
DB_USER=toybox_user
DB_PASSWORD=<strong-password>
DB_HOST=db
DB_PORT=5432

# Redis
REDIS_URL=redis://redis:6379/0

# Security
SECURE_SSL_REDIRECT=true
SECURE_HSTS_SECONDS=31536000

# Email（既存設定から）
EMAIL_HOST=smtp.mail1006.conoha.ne.jp
EMAIL_PORT=587
EMAIL_USE_TLS=true
EMAIL_HOST_USER=contact@toybox.ayatori-inc.co.jp
EMAIL_HOST_PASSWORD=<smtp-password>
```

### 4-2: Docker Compose 起動

```bash
# 新規本番サーバーで実行
cd /var/www/toybox

# 本番構成で起動（ビルド含む）
docker-compose -f docker-compose.prod.yml up -d --build

# ビルドプロセスを確認（数分かかります）
docker-compose logs -f
```

**ビルド完了の目安：**
```
toybox-web-1 | Starting gunicorn
toybox-worker-1 | celery worker started
toybox-beat-1 | celery beat started
```

### 4-3: コンテナ確認

```bash
# 新規本番サーバーで実行
docker-compose ps

# 期待出力:
# NAME          STATUS
# toybox-caddy-1   Up
# toybox-web-1     Up (health: starting)
# toybox-db-1      Up (healthy)
# toybox-redis-1   Up (healthy)
# toybox-worker-1  Up
# toybox-beat-1    Up
```

---

## Step 5: データリストア

### 5-1: DB リストア

```bash
# 新規本番サーバーで実行

# 既存テーブル削除（初回のみ）
docker exec toybox-db-1 psql -U toybox_user -d toybox -c \
  "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

# DB ダンプをコンテナにコピー
docker cp /backup/toybox/database/toybox_*.dump toybox-db-1:/tmp/toybox.dump

# リストア実行
docker exec toybox-db-1 pg_restore -U toybox_user -d toybox -O /tmp/toybox.dump

# 確認
docker exec toybox-db-1 psql -U toybox_user -d toybox -c "SELECT COUNT(*) as user_count FROM users;"

# 期待出力:
#  user_count
# -----------
#          60
```

**トラブル：ファイルが見つからない**
```bash
# ファイルを確認
ls -lh /backup/toybox/database/
file /backup/toybox/database/toybox_*.dump
```

### 5-2: メディアボリューム展開

```bash
# 新規本番サーバーで実行

# アップロードディレクトリ作成
docker exec toybox-web-1 mkdir -p /app/public/uploads

# アーカイブをコンテナにコピー
docker cp /backup/toybox/volumes/media_volume_*.tar.gz toybox-web-1:/tmp/

# 展開
docker exec toybox-web-1 tar -xzf /tmp/media_volume_*.tar.gz -C /app/public/uploads/

# 確認
docker exec toybox-web-1 ls -lh /app/public/uploads/

# 期待出力:
# drwxr-xr-x cards/
# drwxr-xr-x games/
# drwxr-xr-x profiles/
# drwxr-xr-x submissions/
# drwxr-xr-x titles/
```

### 5-3: Django マイグレーション実行

```bash
# 新規本番サーバーで実行

# マイグレーション実行
docker-compose exec -T web python manage.py migrate

# 期待出力:
# Running migrations:
#   Applying django_celery_beat.0001_initial... OK
#   ...
```

### 5-4: スタティックファイル収集

```bash
# 新規本番サーバーで実行

# スタティックファイル収集
docker-compose exec -T web python manage.py collectstatic --noinput

# 期待出力:
# 164 static files copied to '/app/staticfiles', 20 unmodified.
```

---

## Step 6: ヘルスチェック

### 6-1: API 確認

```bash
# 新規本番サーバーで実行

# ヘルスチェック
docker exec toybox-web-1 python -c \
  "import requests; r = requests.get('http://localhost:8000/api/health/'); print(r.json())"

# 期待出力:
# {'status': 'ok'}
```

**ローカルマシンから確認（SSH トンネル経由）：**
```bash
# SSH トンネルで新規サーバーの HTTP をローカルにフォワード
ssh -L 8000:localhost:8000 toyboxssh.ayatori-inc.co.jp

# 別のターミナルで確認
curl http://localhost:8000/api/health/
# または
curl -k https://localhost:8443/api/health/
```

### 6-2: ログ確認

```bash
# 新規本番サーバーで実行

# 各サービスのログを確認
echo "=== Web ==="
docker-compose logs web | tail -20

echo "=== Worker ==="
docker-compose logs worker | tail -20

echo "=== Beat ==="
docker-compose logs beat | tail -20

# エラーがないか確認
```

### 6-3: データ確認

```bash
# 新規本番サーバーで実行

# ユーザー数確認
docker exec toybox-db-1 psql -U toybox_user -d toybox -c \
  "SELECT COUNT(*) FROM users;"

# 投稿数確認
docker exec toybox-db-1 psql -U toybox_user -d toybox -c \
  "SELECT COUNT(*) FROM submissions;"

# メディアファイル確認
docker exec toybox-web-1 find /app/public/uploads -type f | wc -l
```

---

## Step 7: DNS 切替え

### 7-1: DNS レコード更新

```bash
# ローカル開発マシンから実行

# DNS プロバイダーで以下を更新:
# toybox.ayatori-inc.co.jp A レコード → 192.168.122.140（新規本番）
# （現在は 160.251.168.144 を指しているはず）
```

### 7-2: TTL 待機

```bash
# TTL（Time To Live）の間（数分～1時間）待機

# TTL を確認:
nslookup toybox.ayatori-inc.co.jp
# または
dig toybox.ayatori-inc.co.jp

# 新しい IP が返ってくるまで待機
```

### 7-3: アクセス確認

```bash
# ローカル開発マシンから実行

# 新しい IP でアクセス可能か確認
curl https://toybox.ayatori-inc.co.jp/api/health/

# ブラウザから確認:
# https://toybox.ayatori-inc.co.jp/api/
# https://toybox.ayatori-inc.co.jp/admin/
```

---

## ✅ 完了チェック

すべてが完了したら、以下を確認：

```bash
# 新規本番サーバーで実行

echo "=== Docker コンテナ ==="
docker-compose ps

echo "=== ディスク使用率 ==="
df -h /

echo "=== メモリ使用率 ==="
free -h

echo "=== API テスト ==="
docker exec toybox-web-1 curl -s http://localhost:8000/api/health/

echo "=== データベース ==="
docker exec toybox-db-1 psql -U toybox_user -d toybox -c \
  "SELECT COUNT(*) FROM users; SELECT COUNT(*) FROM submissions;"
```

---

## 🆘 トラブルシューティング

### Docker ビルドがタイムアウト

```bash
# ビルドを再開
docker-compose -f docker-compose.prod.yml up -d --build

# または個別にビルド
docker build -t toybox-web:latest ./backend
```

### DB リストアが失敗

```bash
# ログを確認
docker-compose logs db

# ファイル確認
docker exec toybox-db-1 pg_restore --list /tmp/toybox.dump | head -20
```

### メディアボリューム展開がパーミッションエラー

```bash
# パーミッション確認
docker exec toybox-web-1 ls -la /app/public/

# パーミッション修正
docker exec toybox-web-1 chmod -R 755 /app/public/uploads
```

### API が 502 Bad Gateway を返す

```bash
# Gunicorn ログ確認
docker-compose logs web

# Worker を再起動
docker-compose restart web worker beat

# ポート確認
docker exec toybox-web-1 netstat -tlnp | grep 8000
```

---

## 📋 追加注意事項

### テストフェーズについて
- **まず @20260930 のバックアップでテストします** ✅ 実施完了
- 本番環境での問題がないことを確認してから、最新のバックアップで更新します
- テスト期間中は DNS 切替えを行わず、SSH トンネルで動作確認します

### 2026/10/07 実施内容

**✅ 完了した作業：**
- Step 1-4: リポジトリクローン（GitHub から最新版）
- Step 2: バックアップデータ転送（@20260930）
- Step 3: Git ディレクトリ削除
- Step 4-2: Docker Compose 起動（本番構成）
- Step 5-1: DB リストア → ユーザー60件、投稿1,853件 確認
- Step 5-2: メディアボリューム展開 → 9,532ファイル 確認
- Step 5-3: Django マイグレーション 実行
- Step 5-4: スタティックファイル収集 実行

**🔄 確認中の問題：**
- beat コンテナ再起動ループ
- caddy コンテナ再起動ループ
- web healthcheck 失敗

**⏳ 次のステップ：**
- Caddy 設定・ログ確認
- API エンドポイント動作確認
- 最新バックアップでの本番切替（別途実施予定）

## 📚 参考資料

- [BACKUP_GUIDE.md](../../BACKUP_GUIDE.md) - バックアップ復元の詳細
- [31_TWO_PHASE_EXECUTION_20261007.md](./31_TWO_PHASE_EXECUTION_20261007.md) - 2フェーズ実行ガイド
- [README.md](../../README.md) - プロジェクト概要

---

**移行完了後、[既存本番サーバー（160.251.168.144）は停止・削除]** してください。

頑張ってください！ 🚀
