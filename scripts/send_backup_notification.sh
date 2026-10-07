#!/bin/bash
# バックアップ通知メール送信スクリプト
# 使用方法: send_backup_notification.sh <success|failure> <backup_type> <details>

STATUS=$1
BACKUP_TYPE=$2
DETAILS=$3

# メール送信先
TO_EMAILS="kobuchi1106@myou-kou.com"

# メールサーバー設定（Xserver + Google Workspace）
SMTP_HOST="sv17149.xserver.jp"
SMTP_PORT="587"
SMTP_USER="no-reply@tricycle-stars.ayatori-inc.co.jp"
SMTP_PASS="ayatorimio123!"

# メール内容を生成
if [ "$STATUS" = "success" ]; then
    SUBJECT="✅ TOYBOXバックアップ成功 - $BACKUP_TYPE"
    PRIORITY="Normal"
    COLOR="成功"
else
    SUBJECT="❌ TOYBOXバックアップ失敗 - $BACKUP_TYPE"
    PRIORITY="High"
    COLOR="失敗"
fi

DATE=$(date "+%Y年%m月%d日 %H:%M:%S")
HOSTNAME=$(hostname)

# メール本文を作成
cat > /tmp/backup_notification.txt << EOF
From: TOYBOX Backup System <no-reply@tricycle-stars.ayatori-inc.co.jp>
To: $TO_EMAILS
Subject: $SUBJECT
Content-Type: text/plain; charset=UTF-8

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TOYBOX バックアップ通知
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

【ステータス】$COLOR
【バックアップ種別】$BACKUP_TYPE
【日時】$DATE
【サーバー】$HOSTNAME

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

【詳細】
$DETAILS

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

このメールは自動送信されています。
TOYBOX バックアップシステム
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

# メール送信（msmtp → mail → Python SMTP の順で試行）
SEND_RESULT=1
if command -v msmtp &> /dev/null; then
    cat /tmp/backup_notification.txt | msmtp --from="$SMTP_USER" -t $TO_EMAILS
    SEND_RESULT=$?
elif command -v mail &> /dev/null; then
    mail -s "$SUBJECT" $TO_EMAILS < /tmp/backup_notification.txt
    SEND_RESULT=$?
elif command -v python3 &> /dev/null; then
    python3 - "$SMTP_HOST" "$SMTP_PORT" "$SMTP_USER" "$SMTP_PASS" "$TO_EMAILS" "$SUBJECT" <<'PY'
import smtplib, sys
from email.mime.text import MIMEText

host, port, user, password, to_email, subject = sys.argv[1:7]
body = open("/tmp/backup_notification.txt", encoding="utf-8").read()
# ヘッダ行を除いた本文だけ使う
parts = body.split("\n\n", 1)
text = parts[1] if len(parts) > 1 else body
msg = MIMEText(text, "plain", "utf-8")
msg["From"] = f"TOYBOX Backup System <{user}>"
msg["To"] = to_email
msg["Subject"] = subject
with smtplib.SMTP(host, int(port), timeout=30) as server:
    server.starttls()
    server.login(user, password)
    server.send_message(msg)
print("email sent via python smtp")
PY
    SEND_RESULT=$?
else
    echo "メール送信コマンドが見つかりません（msmtp / mail / python3）"
    SEND_RESULT=1
fi

# 一時ファイル削除
rm -f /tmp/backup_notification.txt

exit $SEND_RESULT
