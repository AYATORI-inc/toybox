# バックアップ定期実行スケジュール設定
**作成日**: 2026/10/07  
**対象**: 新規本番サーバー（toyboxssh.ayatori-inc.co.jp）  
**目的**: 自動バックアップの定期実行 + メール通知

---

## 📅 スケジュール

### 実行時刻
- **毎日午前 2:00（02:00）**
- タイムゾーン: Asia/Tokyo（JST）

### 実行内容
1. **データベースバックアップ**
   - PostgreSQL 15 のフルダンプ
   - ファイル形式: `.dump`
   - 復元コマンド: `pg_restore`

2. **メディアボリュームバックアップ**
   - Docker ボリューム `media_volume` を tar.gz 圧縮
   - 全ユーザーアップロードファイルを保存

3. **メール通知**
   - 成功時: ✅ メール送信
   - 失敗時: ❌ メール送信
   - 送信先: `kobuchi1106@myou-kou.com`
   - 差出人: `no-reply@tricycle-stars.ayatori-inc.co.jp`

4. **世代管理**
   - 保持世代数: 1 世代（デフォルト）
   - 古いバックアップは自動削除
   - 設定変更: `BACKUP_KEEP_GENERATIONS` 環境変数

---

## 🔧 Cron ジョブ登録内容

```bash
# ファイル: /var/spool/cron/crontabs/ayatori

# TOYBOX バックアップスケジュール - 毎日午前2時実行
0 2 * * * /var/www/toybox/scripts/backup_nightly.sh >> /home/ayatori/backups/cron.log 2>&1
```

### Cron フォーマット解説
```
0    2    *    *    *    /var/www/toybox/scripts/backup_nightly.sh
分   時   日   月   曜日  コマンド
0    2    *    *    *    毎日午前2時に実行
```

---

## 📂 ログと出力

### ログファイル
- **スクリプトログ**: `/home/ayatori/backups/toybox_backup.log`
  - バックアッププロセスの詳細ログ
  
- **Cron ログ**: `/home/ayatori/backups/cron.log`
  - Cron 実行の成否、エラー情報

### 確認方法

```bash
# スクリプトログ確認
tail -100 /home/ayatori/backups/toybox_backup.log

# Cron ログ確認
tail -50 /home/ayatori/backups/cron.log

# システムログ確認（cron 実行履歴）
grep CRON /var/log/syslog | tail -20
```

---

## 🔍 管理コマンド

### Crontab 確認
```bash
crontab -l
```

### Crontab 編集
```bash
crontab -e
```

### Crontab 削除
```bash
crontab -r
```

### バックアップファイル確認
```bash
# データベースバックアップ
ls -lh /home/ayatori/backups/toybox/database/

# メディアバックアップ
ls -lh /home/ayatori/backups/toybox/volumes/
```

---

## 📊 バックアップ保持ポリシー

### 現在の設定
- **保持世代数**: 1 世代
- **動作**: 新規バックアップ成功後、前世代を削除

### 世代数を変更する場合

```bash
# 一時的に変更（その実行のみ）
BACKUP_KEEP_GENERATIONS=2 /var/www/toybox/scripts/backup_nightly.sh

# 永続的に変更（crontab の cron ジョブを編集）
BACKUP_KEEP_GENERATIONS=2 0 2 * * * /var/www/toybox/scripts/backup_nightly.sh
```

---

## 🚨 トラブルシューティング

### バックアップが実行されない

1. **Cron デーモンが動作しているか確認**
   ```bash
   sudo systemctl status cron
   ```

2. **Crontab が正しく登録されているか確認**
   ```bash
   crontab -l
   ```

3. **ログを確認**
   ```bash
   tail -50 /home/ayatori/backups/cron.log
   grep CRON /var/log/syslog
   ```

### メール通知が届かない

1. **スクリプトログを確認**
   ```bash
   tail -100 /home/ayatori/backups/toybox_backup.log
   ```

2. **メール送信スクリプトをテスト**
   ```bash
   /var/www/toybox/scripts/send_backup_notification.sh success test "テストメール"
   ```

3. **SMTP 設定を確認**
   - SMTP_HOST: sv17149.xserver.jp
   - SMTP_PORT: 587
   - SMTP_USER: no-reply@tricycle-stars.ayatori-inc.co.jp
   - 差出人: no-reply@tricycle-stars.ayatori-inc.co.jp

### ディスク容量が足りない

1. **ディスク使用状況確認**
   ```bash
   df -h /home/ayatori/backups/
   du -sh /home/ayatori/backups/toybox/
   ```

2. **古いバックアップを手動削除**
   ```bash
   find /home/ayatori/backups/toybox/ -type f -mtime +7 -delete
   ```

---

## ✅ 動作確認チェックリスト

- [ ] Cron ジョブが登録されている（`crontab -l`で確認）
- [ ] スクリプトに実行権限がある
- [ ] ログディレクトリ `/home/ayatori/backups/` が存在
- [ ] メール設定が正しい
- [ ] ディスク容量が充分ある（最低 50GB 推奨）
- [ ] CloudFlare Tunnel が稼働中

---

## 📌 関連ファイル

- `/var/www/toybox/scripts/backup_nightly.sh` - メインバックアップスクリプト
- `/var/www/toybox/scripts/backup_database.sh` - DB バックアップ
- `/var/www/toybox/scripts/backup_volumes.sh` - ボリュームバックアップ
- `/var/www/toybox/scripts/send_backup_notification.sh` - メール通知スクリプト
- `/var/www/toybox/scripts/backup_retention.sh` - 世代管理スクリプト

---

## 🎯 次のステップ

1. ✅ **Cron スケジュール設定完了**
2. [ ] 初回実行を待機（翌日午前2時）
3. [ ] メール通知確認
4. [ ] バックアップファイル確認
5. [ ] DNS 切替え準備（Phase 2）

---

**設定日時**: 2026-10-07 16:15 JST  
**次回実行**: 2026-10-08 02:00 JST
