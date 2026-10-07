#!/bin/bash
# 新規本番サーバーアップデート通知 Announcement を作成

set -euo pipefail

BACKEND_DIR="${BACKEND_DIR:-/var/www/toybox/backend}"

# お知らせのタイトルと内容を定義
TITLE="🚀 新規本番サーバーへの移行が完了しました"

CONTENT="本日から TOYBOX は新しい本番サーバーで稼働しており、以下の新機能・改善がリリースされました！

✨ 新機能・改善点:

📸 **記事作成時の見出し画像が全て表示されるように改善**
  • 以前は見出し画像が縦横比により上下が切れていました
  • 今後は、アップロードされた画像のサイズそのままで表示されます
  • 16:9 の画像も、9:16 の縦長画像も、すべてきれいに表示されます

🔍 **「みんなの記事」に検索機能が追加されました**
  • タイトル・本文・著者名を全文検索できます
  • 検索フォームにキーワードを入力してEnterキーを押すだけです
  • 気になる記事をすぐに見つけられるようになりました

🍂 **トップページの動画が秋の季節に更新されました**
  • より季節感のある動画に変更されています

🚀 インフラの改善:
• CloudFlare Tunnel による安全で高速な接続
• 自動バックアップシステムの導入（毎日午前2時）
• SMTP メール通知機能の実装

🔔 その他:
データベースとメディアファイルは毎日自動的にバックアップされています。

ご質問やお問い合わせは tech@ayatori-inc.co.jp までお願いします。
ご利用ありがとうございます！"

# Django 管理コマンドでアナウンスを作成
cd "$BACKEND_DIR"

python manage.py create_announcement \
  --title "$TITLE" \
  --content "$CONTENT"

echo ""
echo "✅ アップデート通知を作成しました"
echo ""
echo "📝 確認方法:"
echo "1. Django Admin: http://toybox-check.ayatori-inc.co.jp/admin/"
echo "2. API: curl http://localhost:8000/api/announcements/"
echo ""
