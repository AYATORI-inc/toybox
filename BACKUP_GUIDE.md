# 🔄 バックアップ・復元ガイド

このドキュメントでは、ToyBox の**データベース**と**メディアボリューム**のバックアップ・復元方法を説明します。

---

## 概要

ToyBox のバックアップは以下の2つで構成されています：

| 対象 | 形式 | 説明 | サイズ目安 |
|------|------|------|----------|
| **PostgreSQL データベース** | `.dump`（カスタムフォーマット） | ユーザー、投稿、設定などの全データ | ～100MB |
| **メディアボリューム** | `.tar.gz`（圧縮アーカイブ） | アップロードされた画像、動画ファイル等 | ～5GB |

---

## 自動バックアップ（推奨）

### セットアップ

本番環境では、毎晩自動的にバックアップが実行されます：

```bash
# バックアップスクリプトを確認
ls -la /var/www/toybox/scripts/backup*.sh

# cron ジョブで夜間実行（例：毎晩 22:00）
crontab -e
# 以下を追加:
# 0 22 * * * /var/www/toybox/scripts/backup_nightly.sh >> /var/log/toybox_cron.log 2>&1
```

### バックアップファイルの場所

```
/backup/toybox/
├── database/
│   └── toybox_20260930_210014.dump    # PostgreSQL ダンプ
└── volumes/
    └── media_volume_20260929_210020.tar.gz  # メディアボリューム
```

### ログ確認

```bash
# バックアップ実行ログ
tail -f /var/log/toybox_backup.log

# メール通知を確認（スクリプト実行時）
# send_backup_notification.sh で成功/失敗を通知
```

---

## 手動バックアップ

### 本番環境での実行

#### 1. PostgreSQL データベースのバックアップ

```bash
cd /var/www/toybox

# 手動でダンプを作成
export BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
./scripts/backup_database.sh

# ファイルが作成されたか確認
ls -lh /backup/toybox/database/toybox_*.dump
```

**オプション：バックアップをスキップ**

```bash
# 何らかの理由でバックアップをスキップしたい場合
export ENABLE_DB_DUMP_BACKUP=false
./scripts/backup_database.sh  # 何もせず終了
```

#### 2. メディアボリュームのバックアップ

```bash
cd /var/www/toybox

# メディアボリュームをバックアップ
export BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
./scripts/backup_volumes.sh

# ファイルが作成されたか確認
ls -lh /backup/toybox/volumes/media_volume_*.tar.gz
```

#### 3. 同時実行（推奨：タイムスタンプを統一）

```bash
cd /var/www/toybox

# DB と メディアボリュームの タイムスタンプを統一
export BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
./scripts/backup_database.sh && ./scripts/backup_volumes.sh

# 両方のファイルが作成されたか確認
ls -lh /backup/toybox/{database,volumes}/ | grep "$BACKUP_DATE"
```

### ローカル環境での実行

**Windows/Mac から本番環境のバックアップを取得する場合：**

```bash
# SSH 経由で本番サーバーからファイルをダウンロード
scp root@160.251.168.144:/backup/toybox/database/toybox_20260930_210014.dump ./20260930/
scp root@160.251.168.144:/backup/toybox/volumes/media_volume_20260929_210020.tar.gz ./20260930/
```

---

## 復元手順

### ローカル開発環境での復元

#### 前提

- Docker が起動している
- バックアップファイルが `./20260930/` ディレクトリに配置されている

#### 1. Docker コンテナの起動

```bash
docker-compose up -d
```

#### 2. PostgreSQL データベースの復元

```bash
# バックアップファイルをコンテナにコピー
docker cp ./20260930/toybox_20260930_210014.dump toybox-db-1:/tmp/toybox.dump

# 既存テーブルを削除（必要な場合）
docker exec toybox-db-1 psql -U toybox_user -d toybox -c \
  "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

# ダンプファイルをリストア
docker exec toybox-db-1 pg_restore -U toybox_user -d toybox -O /tmp/toybox.dump

# 確認
docker exec toybox-db-1 psql -U toybox_user -d toybox -c "SELECT COUNT(*) FROM users;"
```

#### 3. メディアボリュームの復元

```bash
# アップロードディレクトリを作成
docker exec toybox-web-1 mkdir -p /app/public/uploads

# アーカイブをコンテナにコピー
docker cp ./20260930/media_volume_20260929_210020.tar.gz toybox-web-1:/tmp/

# 展開
docker exec toybox-web-1 tar -xzf /tmp/media_volume_20260929_210020.tar.gz -C /app/public/uploads/

# 確認
docker exec toybox-web-1 ls -lh /app/public/uploads/
```

#### 4. Django マイグレーション（初回のみ）

```bash
# 新しいテーブルがあればマイグレーション実行
docker-compose exec -T web python manage.py migrate

# スタティックファイル収集
docker-compose exec -T web python manage.py collectstatic --noinput

# API 確認
docker exec toybox-web-1 python -c \
  "import requests; r = requests.get('http://localhost:8000/api/health/'); print(r.json())"
```

### 本番環境での復元

```bash
cd /var/www/toybox

# 1. DBの復元
docker exec toybox-db-1 psql -U toybox_user -d toybox -c \
  "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

docker cp /backup/toybox/database/toybox_20260930_210014.dump toybox-db-1:/tmp/
docker exec toybox-db-1 pg_restore -U toybox_user -d toybox -O /tmp/toybox.dump

# 2. メディアボリュームの復元
mkdir -p /tmp/media_extract
cd /tmp/media_extract
tar -xzf /backup/toybox/volumes/media_volume_20260929_210020.tar.gz

# Docker ボリュームに復元
docker run --rm -v toybox_media_volume:/data -v /tmp/media_extract:/source \
  alpine cp -r /source/* /data/

# クリーンアップ
rm -rf /tmp/media_extract

# 3. マイグレーション実行
docker-compose exec -T web python manage.py migrate

# 4. 確認
docker-compose ps  # すべてが Up か確認
```

---

## バックアップ保持ポリシー

| 種類 | 保持世代数 | 説明 |
|------|----------|------|
| **PostgreSQL .dump** | 1世代（カスタマイズ可能） | 最新のダンプのみ保持（サイズ削減） |
| **メディアボリューム .tar.gz** | 1世代 | 最新のみ保持（容量が大きいため） |

**保持世代数を変更する場合：**

```bash
# backup_database.sh を実行する際、環境変数を設定
export BACKUP_KEEP_GENERATIONS=3
./scripts/backup_database.sh
```

---

## トラブルシューティング

### バックアップが失敗する

```bash
# ログを確認
tail -100 /var/log/toybox_backup.log

# よくある原因:
# 1. Docker コンテナが起動していない
docker ps | grep toybox

# 2. PostgreSQL が接続できない
docker exec toybox-db-1 pg_isready -U toybox_user

# 3. ディスク容量が不足している
df -h /backup
```

### ファイルが破損している

```bash
# カスタムフォーマット (.dump) の検証
docker exec toybox-db-1 pg_restore --list /tmp/toybox.dump

# エラーが出た場合は、バックアップファイルが破損している可能性
```

### リストア後にエラーが発生する

```bash
# 1. マイグレーション再実行
docker-compose exec -T web python manage.py migrate --no-input

# 2. キャッシュをクリア
docker-compose exec -T web python manage.py shell << EOF
from django.core.cache import cache
cache.clear()
EOF

# 3. コンテナを再起動
docker-compose restart web worker beat
```

---

## ベストプラクティス

1. ✅ **定期的にバックアップを取得**
   - 毎日の自動バックアップを設定
   - 週1回は外部ストレージに保存

2. ✅ **バックアップを定期的に検証**
   ```bash
   # 月1回、バックアップをテスト復元して動作確認
   docker-compose exec -T web python manage.py shell
   ```

3. ✅ **複数の場所に保管**
   - `/backup/toybox/` （ローカルサーバー）
   - クラウドストレージ（S3, Google Drive など）

4. ✅ **バージョン管理**
   ```bash
   # タイムスタンプをファイル名に含める
   toybox_20260930_210014.dump
   media_volume_20260929_210020.tar.gz
   ```

---

## 参考資料

- [PostgreSQL pg_dump ドキュメント](https://www.postgresql.org/docs/15/app-pgdump.html)
- [Docker Volume バックアップ](https://docs.docker.com/storage/volumes/#backup-restore-or-migrate-data-volumes)
- [本番環境移行ガイド](./doc/transfer202610/31_TWO_PHASE_EXECUTION_20261007.md)
