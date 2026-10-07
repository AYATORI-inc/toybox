# サーバー更新通知（Announcement）の作成
**作成日**: 2026/10/07  
**対象**: 新規本番サーバー（toyboxssh.ayatori-inc.co.jp）  
**目的**: ユーザーへの主な変更点・新機能の通知

---

## 📝 アナウンスメント内容

### タイトル
🚀 新規本番サーバーへの移行が完了しました

### 本文（ユーザーに表示される内容）

```
本日から TOYBOX は新しい本番サーバーで稼働しており、以下の新機能・改善がリリースされました！

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
ご利用ありがとうございます！
```

---

## 🛠️ 作成方法

### 方法 1: スクリプト実行（推奨）

#### A. スクリプトをサーバーに転送

```bash
# ローカルマシンから実行
scp -i ~/.ssh/ayatori_vps1.pem \
  /path/to/create_server_update_announcement.sh \
  ayatori@toyboxssh.ayatori-inc.co.jp:/var/www/toybox/scripts/
```

#### B. サーバーで実行

```bash
# SSH で接続後
ssh toyboxssh.ayatori-inc.co.jp

# スクリプト実行
cd /var/www/toybox/scripts
bash create_server_update_announcement.sh

# 出力例:
# ✅ アップデート通知を作成しました
```

### 方法 2: Django Admin（Web UI）

#### A. Django Admin にアクセス

```
URL: http://toybox-check.ayatori-inc.co.jp/admin/
（または http://toybox.ayatori-inc.co.jp/admin/）
```

#### B. Announcements メニューをクリック

1. 左メニューの **Announcements** をクリック
2. **+ Add Announcement** ボタンをクリック

#### C. フォームに入力

| フィールド | 入力値 |
|-----------|-------|
| **Title** | 🚀 新規本番サーバーへの移行が完了しました |
| **Content** | （上記の本文をコピペ） |
| **Is Active** | ☑️ チェック（有効にする） |
| **Created by** | （自動的に現在のユーザーが設定） |

#### D. Save ボタンで保存

### 方法 3: Django 管理コマンド（ターミナル）

```bash
# サーバーで SSH 接続後
cd /var/www/toybox/backend

# コマンド実行
python manage.py create_announcement \
  --title "🚀 新規本番サーバーへの移行が完了しました" \
  --content "本日から TOYBOX は新しい本番サーバーで稼働しており..."
```

---

## ✅ 確認方法

### 1. Django Admin で確認

```
URL: http://toybox-check.ayatori-inc.co.jp/admin/frontend/announcement/
```

新しいアナウンスメントが一覧に表示されるはず

### 2. API で確認

```bash
# ターミナルで実行
curl http://localhost:8000/api/announcements/

# レスポンス例:
# {
#   "results": [
#     {
#       "id": 1,
#       "title": "🚀 新規本番サーバーへの移行が完了しました",
#       "content": "本日から TOYBOX は...",
#       "is_active": true,
#       "created_at": "2026-10-07T17:20:00Z"
#     }
#   ]
# }
```

### 3. ユーザーフロントエンドで確認

```
URL: http://toybox-check.ayatori-inc.co.jp/
（トップページにお知らせが表示される）
```

---

## 📋 関連ファイル

### スクリプト
- `/var/www/toybox/scripts/create_server_update_announcement.sh`

### Django 管理コマンド
- `/var/www/toybox/backend/frontend/management/commands/create_announcement.py`

### モデル
- `/var/www/toybox/backend/frontend/models.py` → `Announcement` クラス

### ドキュメント参照
- [Articles 見出し画像表示修正](./done/04_ARTICLES_IMAGE_FIX_20261006.md)
- [Articles 全文検索機能追加](./done/05_ARTICLES_SEARCH_FEATURE_20261006.md)

---

## 🔔 お知らせの管理

### 無効にする方法

Django Admin で該当のアナウンスメントを選択し、**Is Active** のチェックを外して保存

### 削除する方法

Django Admin で該当のアナウンスメントを選択し、Delete ボタンをクリック

### 複数のお知らせを表示

1つのアナウンスメントだけでなく、複数同時に表示も可能です

---

## 📌 次のステップ

1. ✅ スクリプト作成完了
2. [ ] サーバーへの転送・実行
3. [ ] ユーザーフロントエンドで確認
4. [ ] DNS 切替え準備（Phase 2 of DNS Switchover Plan）

---

**作成日**: 2026-10-07 17:25 JST  
**ステータス**: 実装待機（スクリプト・コマンド）作成完了、サーバー反映未了
