# SMTP メール＋バックアップ Cron 最終設定
**作成日**: 2026/10/07  
**完成日**: 2026/10/07 16:20 JST  
**対象**: 新規本番サーバー（toyboxssh.ayatori-inc.co.jp）  
**ステータス**: ✅ 完全実装済み

---

## 🎯 実装完了項目

### ✅ SMTP メール通知機能

**差出人設定**
```
From: TOYBOX Backup System <no-reply@tricycle-stars.ayatori-inc.co.jp>
(Google Workspace ドメイン)
```

**SMTP 認証情報**
| 項目 | 値 |
|------|---|
| SMTP ホスト | sv17149.xserver.jp |
| SMTP ポート | 587 (TLS) |
| 認証ユーザー | no-reply@tricycle-stars.ayatori-inc.co.jp |
| 認証パスワード | ayatorimio123! |

**送信先**
| 環境 | メールアドレス | 用途 |
|------|---|---|
| 本番 | kobuchi1106@myou-kou.com | バックアップ通知 |

**メール内容**
```
【件名】✅ TOYBOXバックアップ成功 - {バックアップ種別}
       または
       ❌ TOYBOXバックアップ失敗 - {バックアップ種別}

【本文】
- ステータス（成功/失敗）
- バックアップ種別
- 実行日時
- サーバー名
- 詳細メッセージ
```

**テスト実績**
```
✅ 2026-10-07 16:06 JST - メール送信成功
   kobuchi1106@myou-kou.com で受信確認済み
```

---

### ✅ バックアップ定期実行（Cron）

**スケジュール**
```
0 2 * * * /var/www/toybox/scripts/backup_nightly.sh >> /home/ayatori/backups/cron.log 2>&1
```

**実行時刻**
- 毎日午前 2:00 JST
- タイムゾーン: Asia/Tokyo

**バックアップ内容**
1. **データベース**
   - PostgreSQL 15 フルダンプ
   - 形式: `.dump`
   - 保存先: `/home/ayatori/backups/toybox/database/`

2. **メディア**
   - Docker ボリューム `media_volume`
   - 形式: `tar.gz`
   - 保存先: `/home/ayatori/backups/toybox/volumes/`

**世代管理**
- 保持世代数: 1 世代（デフォルト）
- 古いバックアップは自動削除

**ログ出力**
- スクリプトログ: `/home/ayatori/backups/toybox_backup.log`
- Cron ログ: `/home/ayatori/backups/cron.log`

---

## 📂 修正されたファイル一覧

### スクリプトファイル

#### `/var/www/toybox/scripts/send_backup_notification.sh`
**修正内容:**
```diff
- TO_EMAILS="kobuchi@ayatori-inc.co.jp"          # 旧
+ TO_EMAILS="kobuchi1106@myou-kou.com"           # 新（外部ドメイン）

- SMTP_USER="noreply@ayatori-inc.co.jp"          # 旧
+ SMTP_USER="no-reply@tricycle-stars.ayatori-inc.co.jp"  # 新（Google Workspace）

- From: TOYBOX Backup System <noreply@toybox.ayatori-inc.co.jp>  # 旧
+ From: TOYBOX Backup System <no-reply@tricycle-stars.ayatori-inc.co.jp>  # 新
```

**状態:** ✅ サーバーに反映済み ✅ ローカルに反映済み

#### `/var/www/toybox/scripts/backup_nightly.sh`
**Cron 登録で自動実行するように設定**

**状態:** ✅ Cron ジョブ登録済み（毎日02:00）

---

## 🔧 構成図

```
┌─────────────────────────────────────────────────────┐
│         Cron スケジューラ（Ubuntu 24.04）            │
│         毎日午前2時に自動実行                        │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│    /var/www/toybox/scripts/backup_nightly.sh        │
│    - DB バックアップ                                 │
│    - ボリュームバックアップ                          │
│    - 世代管理（古いファイル削除）                    │
└──────────────────┬──────────────────────────────────┘
                   │
        ┌──────────┴──────────┐
        ▼                     ▼
┌─────────────────┐   ┌──────────────────────────────┐
│  バックアップ    │   │ send_backup_notification.sh  │
│  ファイル生成    │   │  - メール作成                │
│                 │   │  - SMTP 送信                 │
└─────────────────┘   └──────────────┬───────────────┘
                                     │
                                     ▼
                      ┌──────────────────────────┐
                      │  sv17149.xserver.jp      │
                      │  (X-Server SMTP)         │
                      │  - STARTTLS で接続       │
                      │  - Google Workspace 認証 │
                      └──────────────┬───────────┘
                                     │
                                     ▼
                      ┌──────────────────────────┐
                      │ 外部メールサーバー        │
                      │ (myou-kou.com)           │
                      └──────────────┬───────────┘
                                     │
                                     ▼
                      ┌──────────────────────────┐
                      │ kobuchi1106@myou-kou.com │
                      │ (メール受信完了)          │
                      └──────────────────────────┘
```

---

## 📋 次のアクション

### 🔍 動作確認（明日朝）

1. **初回実行ログ確認**
   ```bash
   tail -100 /home/ayatori/backups/toybox_backup.log
   ```

2. **バックアップファイル確認**
   ```bash
   ls -lh /home/ayatori/backups/toybox/database/
   ls -lh /home/ayatori/backups/toybox/volumes/
   ```

3. **メール通知到着確認**
   - 送信先: kobuchi1106@myou-kou.com
   - 送信元: no-reply@tricycle-stars.ayatori-inc.co.jp

### 🚀 次フェーズ（確認後）

1. DNS 切替え準備（Phase 2 of 34_DNS_SWITCHOVER_PLAN）
2. 本番環境カットオーバー
3. 既存サーバー停止

---

## 🔐 セキュリティ注記

### SMTP パスワード管理
- ✅ Google Workspace アカウントで認証
- ✅ X-Server のリレーサーバーを経由
- ⚠️ パスワードは本番サーバーのスクリプトに埋め込まれている
- 📌 将来的には環境変数や Secrets 管理への移行推奨

### メール配信仕様
- X-Server のポリシー: 同じドメイン宛は内部として処理
- 外部ドメイン（myou-kou.com）への配信で機能確認
- SPF/DKIM/DMARC は Google Workspace ドメインで認証

---

## 📞 トラブルシューティング

### メールが届かない場合

1. **Cron が実行されたか確認**
   ```bash
   grep "backup_nightly.sh" /var/log/syslog | tail -5
   ```

2. **スクリプトログを確認**
   ```bash
   tail -100 /home/ayatori/backups/toybox_backup.log | grep -i "mail\|error"
   ```

3. **SMTP 接続テスト**
   ```bash
   python3 /var/www/toybox/scripts/send_backup_notification.sh success test "Test message"
   ```

### バックアップが実行されない場合

1. **Cron デーモン確認**
   ```bash
   sudo systemctl status cron
   ```

2. **Crontab 確認**
   ```bash
   crontab -l
   ```

3. **スクリプト実行権限確認**
   ```bash
   ls -l /var/www/toybox/scripts/backup_nightly.sh
   # -rwxr-xr-x であることを確認
   ```

---

## ✅ 完成チェックリスト

- [x] SMTP 設定完了（Google Workspace）
- [x] メール送信テスト成功（kobuchi1106@myou-kou.com）
- [x] バックアップスクリプト修正（送信先、認証情報）
- [x] Cron ジョブ登録（毎日02:00）
- [x] ログ出力設定
- [x] ドキュメント整備
- [ ] 初回実行ログ確認（明日朝）
- [ ] DNS 切替え準備

---

**実装者**: AI Assistant  
**検証者**: 開発チーム  
**本番環境準備率**: 90%（バックアップ + メール通知完了）
