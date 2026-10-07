# 🔄 バックアップ・復元ガイド

**最終更新**: 2026/10/07  
**対象環境**: 新規本番サーバー（toyboxssh.ayatori-inc.co.jp）

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

本番環境では、**毎日午前2時（02:00 JST）** に自動的にバックアップが実行されます。

#### Cron ジョブの確認

```bash
# Cron ジョブが登録されているか確認
crontab -l

# 出力例:
# 0 2 * * * /var/www/toybox/scripts/backup_nightly.sh >> /home/ayatori/backups/cron.log 2>&1
```

#### Cron ジョブの登録（未設定の場合）

```bash
# Python スクリプトで自動登録
python3 << 'EOF'
import subprocess
CRON_ENTRY = "0 2 * * * /var/www/toybox/scripts/backup_nightly.sh >> /home/ayatori/backups/cron.log 2>&1"
process = subprocess.Popen(['crontab', '-'], stdin=subprocess.PIPE, text=True)
process.communicate(input=CRON_ENTRY)
EOF
```

### バックアップファイルの場所

```
/home/ayatori/backups/toybox/
├── database/
│   └── toybox_20261007_020015.dump        # PostgreSQL ダンプ
└── volumes/
    └── media_volume_20261007_020045.tar.gz  # メディアボリューム
```

### ログ確認

```bash
# バックアップ実行ログ
tail -100 /home/ayatori/backups/toybox_backup.log

# Cron 実行ログ（エラーが出た場合）
tail -50 /home/ayatori/backups/cron.log

# システムログ（Cron 実行履歴）
grep CRON /var/log/syslog | tail -10
```

### メール通知機能

バックアップ実行結果は自動的にメール送信されます：

| 項目 | 設定値 |
|------|-------|
| **送信元** | TOYBOX Backup System <no-reply@tricycle-stars.ayatori-inc.co.jp> |
| **送信先** | kobuchi1106@myou-kou.com |
| **SMTP サーバー** | sv17149.xserver.jp:587 |
| **認証方式** | TLS/STARTTLS |

#### メール送信テスト

```bash
# テストメールを手動送信
/var/www/toybox/scripts/send_backup_notification.sh success test "これはテストメールです"

# スクリプトログで確認
tail -20 /home/ayatori/backups/toybox_backup.log | grep -i "mail\|error"
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
ls -lh /home/ayatori/backups/toybox/database/toybox_*.dump
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
ls -lh /home/ayatori/backups/toybox/volumes/media_volume_*.tar.gz
```

#### 3. 同時実行（推奨：タイムスタンプを統一）

```bash
cd /var/www/toybox

# DB と メディアボリュームの タイムスタンプを統一
export BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
./scripts/backup_database.sh && ./scripts/backup_volumes.sh

# 両方のファイルが作成されたか確認
ls -lh /home/ayatori/backups/toybox/{database,volumes}/ | grep "$BACKUP_DATE"
```

#### 4. バックアップスクリプト全体の実行（推奨）

```bash
cd /var/www/toybox

# メインスクリプトで DB + ボリューム + メール通知を一括実行
# （実行中は web/worker/beat を一時停止します）
./scripts/backup_nightly.sh

# ログで確認
tail -50 /home/ayatori/backups/toybox_backup.log

# 生成物確認
ls -lh /home/ayatori/backups/toybox/database/
ls -lh /home/ayatori/backups/toybox/volumes/
```

**注意（本番スタック固有）**
- `backup_nightly.sh` の compose 作業ディレクトリは `/var/www/toybox`
- DB ユーザーは `toybox_user`（`postgres` ではない）
- 通知メールは `msmtp` が無い環境では Python SMTP にフォールバック

### CloudFlare Tunnel 経由での手動バックアップ

新規本番サーバーは CloudFlare Tunnel で接続されています：

```bash
# CloudFlare Tunnel 経由で SSH 接続
ssh toyboxssh.ayatori-inc.co.jp

# サーバーに接続後、バックアップ実行
cd /var/www/toybox && ./scripts/backup_nightly.sh
```

### ローカル環境でのバックアップ取得

**CloudFlare Tunnel 経由でローカルにダウンロード：**

```bash
# SSH トンネル経由でファイルを取得
scp -i ~/.ssh/ayatori_vps1.pem ayatori@toyboxssh.ayatori-inc.co.jp:/home/ayatori/backups/toybox/database/toybox_*.dump ./backup/
scp -i ~/.ssh/ayatori_vps1.pem ayatori@toyboxssh.ayatori-inc.co.jp:/home/ayatori/backups/toybox/volumes/media_volume_*.tar.gz ./backup/
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

| 種類 | 保持世代数（デフォルト） | 説明 |
|------|----------|------|
| **PostgreSQL .dump** | 1世代 | 最新のダンプのみ保持（サイズ削減） |
| **メディアボリューム .tar.gz** | 1世代 | 最新のみ保持（容量が大きいため） |

新規バックアップ成功後、古いバイナリは自動削除されます。

**保持世代数を変更する場合：**

```bash
# Cron ジョブの設定を編集
crontab -e

# 以下のように修正（例：2世代保持）
BACKUP_KEEP_GENERATIONS=2 0 2 * * * /var/www/toybox/scripts/backup_nightly.sh >> /home/ayatori/backups/cron.log 2>&1

# または、スクリプト直接実行時に指定
export BACKUP_KEEP_GENERATIONS=2
./scripts/backup_nightly.sh
```

**ディスク容量の監視：**

```bash
# バックアップディレクトリの使用量確認
du -sh /home/ayatori/backups/
du -sh /home/ayatori/backups/toybox/database/
du -sh /home/ayatori/backups/toybox/volumes/

# ディスク全体の確認
df -h /home/ayatori/
```

---

## トラブルシューティング

### バックアップが実行されない

```bash
# 1. Cron デーモンが起動しているか確認
sudo systemctl status cron

# 2. Cron ジョブが登録されているか確認
crontab -l

# 3. スクリプトに実行権限があるか確認
ls -l /var/www/toybox/scripts/backup_nightly.sh
# -rwxr-xr-x であることを確認

# 4. Cron ログで実行履歴を確認
grep "backup_nightly" /var/log/syslog | tail -10
```

### バックアップが失敗する

```bash
# ログを確認
tail -100 /home/ayatori/backups/toybox_backup.log

# Cron ログも確認
tail -50 /home/ayatori/backups/cron.log

# よくある原因:
# 1. Docker コンテナが起動していない
docker ps | grep toybox

# 2. PostgreSQL が接続できない
docker exec toybox-db-1 pg_isready -U toybox_user

# 3. ディスク容量が不足している
df -h /home/ayatori/backups/

# 4. メディアボリュームのマウント問題
docker volume ls | grep toybox
docker volume inspect toybox_media_volume
```

### メール通知が届かない

```bash
# 1. スクリプトログを確認
tail -100 /home/ayatori/backups/toybox_backup.log | grep -i "mail\|error"

# 2. メール送信テスト
/var/www/toybox/scripts/send_backup_notification.sh success test "テストメール"

# 3. SMTP 設定確認
grep "SMTP_" /var/www/toybox/scripts/send_backup_notification.sh

# 4. Python で直接テスト
python3 << 'EOF'
import smtplib
from email.mime.text import MIMEText

msg = MIMEText("Test")
msg['From'] = "no-reply@tricycle-stars.ayatori-inc.co.jp"
msg['To'] = "kobuchi1106@myou-kou.com"
msg['Subject'] = "Test"

try:
    server = smtplib.SMTP("sv17149.xserver.jp", 587, timeout=10)
    server.starttls()
    server.login("no-reply@tricycle-stars.ayatori-inc.co.jp", "ayatorimio123!")
    server.send_message(msg)
    server.quit()
    print("✅ SMTP 接続・送信 OK")
except Exception as e:
    print(f"❌ エラー: {e}")
EOF
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

### ローカルドキュメント
- [SMTP メール設定ガイド](./doc/transfer202610/35_SMTP_EMAIL_SETUP_20261007.md)
- [バックアップ Cron 設定](./doc/transfer202610/36_BACKUP_CRON_SETUP_20261007.md)
- [SMTP + Cron 最終設定](./doc/transfer202610/37_SMTP_AND_CRON_FINAL_SETUP_20261007.md)
- [本番環境アーキテクチャ](./doc/transfer202610/33_FINAL_ARCHITECTURE_20261007.md)
- [本番環境移行ガイド](./doc/transfer202610/31_TWO_PHASE_EXECUTION_20261007.md)
- [DNS 切替え計画](./doc/transfer202610/34_DNS_SWITCHOVER_PLAN_20261007.md)

### 外部リソース
- [PostgreSQL pg_dump ドキュメント](https://www.postgresql.org/docs/15/app-pgdump.html)
- [PostgreSQL pg_restore ドキュメント](https://www.postgresql.org/docs/15/app-pgrestore.html)
- [Docker Volume バックアップ](https://docs.docker.com/storage/volumes/#backup-restore-or-migrate-data-volumes)
- [Linux Cron リファレンス](https://linux.die.net/man/5/crontab)

## バージョン履歴

| 日付 | バージョン | 変更内容 |
|------|-----------|---------|
| 2026-10-07 | 2.0 | 新規本番サーバー向けに全更新（ログパス、時刻、メール通知対応） |
| 旧 | 1.0 | 開発環境向けガイド |
