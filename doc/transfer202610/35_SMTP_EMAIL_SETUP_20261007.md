# SMTP メール設定ガイド
**作成日**: 2026/10/07  
**対象**: バックアップ通知メール機能の設定

---

## 🔧 X-Server SMTP 設定情報（Google Workspace）

### 認証情報
- **SMTP サーバー**: sv17149.xserver.jp
- **ポート**: 587 (TLS/STARTTLS)
- **認証ユーザー**: no-reply@tricycle-stars.ayatori-inc.co.jp
- **パスワード**: ayatorimio123!
- **差出人アドレス**: no-reply@tricycle-stars.ayatori-inc.co.jp
- **送信先テストアドレス**: tech@ayatori-inc.co.jp

### 使用方法

#### ① Django `.env` ファイル設定

サーバーの `/var/www/toybox/backend/.env` に以下を設定：

```bash
# メール設定
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=sv17149.xserver.jp
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=noreply@ayatori-inc.co.jp
EMAIL_HOST_PASSWORD=ayatorimio123!
DEFAULT_FROM_EMAIL=noreply@toybox.ayatori-inc.co.jp
```

#### ② バックアップスクリプト設定

ファイル: `/var/www/toybox/scripts/send_backup_notification.sh`

```bash
# メールサーバー設定（Xserver + Google Workspace）
SMTP_HOST="sv17149.xserver.jp"
SMTP_PORT="587"
SMTP_USER="no-reply@tricycle-stars.ayatori-inc.co.jp"  # Google Workspace アカウント
SMTP_PASS="ayatorimio123!"

# メール送信先
TO_EMAILS="tech@ayatori-inc.co.jp"

# 差出人アドレス（Google Workspace）
FROM_EMAIL="no-reply@tricycle-stars.ayatori-inc.co.jp"
```

**状態**: ✅ 修正完了（ローカル）

---

## 🚀 テスト実行手順

### ステップ 1: サーバー接続確認

```bash
# CloudFlare Tunnel 経由で SSH 接続
ssh toyboxssh.ayatori-inc.co.jp

# CloudFlare Tunnel 状態確認
sudo systemctl status cloudflared
```

### ステップ 2: テストメール送信

```bash
# バックアップ通知スクリプトでテスト送信
/var/www/toybox/scripts/send_backup_notification.sh \
  "success" \
  "test_email" \
  "これはテストメールです。SMTP設定が正しく機能しています。"
```

### ステップ 3: 受信確認

- 送信先: `kobuchi@ayatori-inc.co.jp`
- 予想送信者: TOYBOX Backup System <noreply@toybox.ayatori-inc.co.jp>
- 予想件名: ✅ TOYBOXバックアップ成功 - test_email

---

## 📧 スクリプト詳細

### send_backup_notification.sh の流れ

1. **引数**: `<status> <backup_type> <details>`
   - status: "success" または "failure"
   - backup_type: バックアップタイプ（例: "database", "volumes", "full"）
   - details: 詳細メッセージ

2. **メール作成**:
   - From: TOYBOX Backup System <noreply@toybox.ayatori-inc.co.jp>
   - To: $TO_EMAILS（複数指定可）
   - Subject: ✅/❌ + タイプ + 日時

3. **送信方法**:
   - 優先: `msmtp` コマンド（設定ファイルベース）
   - 代替: `mail` コマンド（system mail）

4. **一時ファイル**:
   - 作成: `/tmp/backup_notification.txt`
   - 送信後: 自動削除

---

## ⚠️ トラブルシューティング

### メール送信コマンドが見つからない場合

```bash
# インストール（Ubuntu/Debian）
sudo apt-get install msmtp msmtp-mta mailutils
```

### msmtp の設定（オプション）

ファイル: `~/.msmtprc`

```
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        ~/.msmtp.log

account xserver
host            sv17149.xserver.jp
port            587
from            noreply@ayatori-inc.co.jp
user            noreply@ayatori-inc.co.jp
password        ayatorimio123!

account default
host            sv17149.xserver.jp
port            587
from            noreply@toybox.ayatori-inc.co.jp
user            noreply@ayatori-inc.co.jp
password        ayatorimio123!
```

### テスト送信（msmtp で直接）

```bash
# テストメール生成
cat > /tmp/test_mail.txt << 'EOF'
From: noreply@ayatori-inc.co.jp
To: kobuchi@ayatori-inc.co.jp
Subject: Test Email

This is a test email from SMTP configuration.
EOF

# 送信実行
msmtp --from=noreply@ayatori-inc.co.jp \
      -t < /tmp/test_mail.txt
```

---

## 🔍 接続テスト（telnet）

```bash
# SMTP サーバー接続確認
telnet sv17149.xserver.jp 587

# 接続後、以下を入力：
# EHLO toybox
# STARTTLS
# AUTH LOGIN
# <base64 encoded user>
# <base64 encoded password>
```

---

## 📌 関連ファイル

- `/var/www/toybox/scripts/send_backup_notification.sh` - メール送信スクリプト
- `/var/www/toybox/backend/.env` - Django 環境設定
- `/var/www/toybox/scripts/backup_nightly.sh` - バックアップ実行スクリプト（メール送信の呼び出し）

---

## 🎯 次のステップ

1. サーバーの CloudFlare Tunnel が復旧するまで待機
2. SSH 接続確認後、修正済みスクリプトをサーバーに転送
3. テストメール送信を実行
4. 本番環境 DNS 切替えに進む
