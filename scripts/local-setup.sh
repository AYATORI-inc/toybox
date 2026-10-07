#!/bin/bash
# Local Development Setup Script
# Caddy なし、20260930 バックアップ使用
# 
# 使用方法: bash scripts/local-setup.sh

set -e

echo "🚀 ローカル開発環境セットアップ開始..."
echo ""

# Step 1: .env をコピー
echo "📝 Step 1: .env ファイルの準備..."
if [ ! -f .env ]; then
    cp .env.local .env
    echo "✅ .env.local をコピーしました"
else
    echo "⚠️  .env が既に存在します"
fi
echo ""

# Step 2: Docker イメージをビルド & 起動
echo "🐳 Step 2: Docker コンテナを起動..."
docker-compose up -d --build
echo "✅ コンテナ起動完了"
echo ""

# Step 3: DB の準備
echo "📊 Step 3: データベースの初期化..."
echo "  - バックアップをコピー中..."
docker cp 20260930/toybox_20260929_210014.dump toybox-db-1:/tmp/toybox.dump

echo "  - リストア実行中..."
docker exec toybox-db-1 pg_restore -U toybox_user -d toybox /tmp/toybox.dump

echo "  - ユーザー数確認..."
USER_COUNT=$(docker exec toybox-db-1 psql -U toybox_user -d toybox -c "SELECT COUNT(*) FROM auth_user;" | tail -2 | head -1)
echo "✅ DB リストア完了 (ユーザー: $USER_COUNT)"
echo ""

# Step 4: Django マイグレーション
echo "🔄 Step 4: Django マイグレーション..."
docker-compose exec -T web python manage.py migrate
echo "✅ マイグレーション完了"
echo ""

# Step 5: スタティックファイル収集
echo "📦 Step 5: スタティックファイル収集..."
docker-compose exec -T web python manage.py collectstatic --noinput
echo "✅ スタティックファイル収集完了"
echo ""

# Step 6: メディアボリューム展開
echo "🖼️  Step 6: メディアボリューム展開..."
docker exec toybox-web-1 mkdir -p /app/public/uploads
docker cp 20260930/media_volume_20260929_210020.tar.gz toybox-web-1:/tmp/
docker exec toybox-web-1 tar -xzf /tmp/media_volume_20260929_210020.tar.gz -C /app/public/uploads/
echo "✅ メディアボリューム展開完了"
echo ""

# Step 7: ステータス確認
echo "✅ Step 7: ステータス確認..."
docker-compose ps
echo ""

# Step 8: ヘルスチェック
echo "🏥 Step 8: ヘルスチェック..."
sleep 5  # 起動を待つ

if curl -s http://localhost:8000/api/health/ | grep -q "ok"; then
    echo "✅ API ヘルスチェック: OK"
else
    echo "⚠️  API ヘルスチェック: 失敗（ログを確認）"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✨ セットアップ完了!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📍 アクセス可能な URL:"
echo "   API:       http://localhost:8000/api/"
echo "   管理画面:   http://localhost:8000/admin/"
echo "   ヘルス:     http://localhost:8000/api/health/"
echo ""
echo "📋 ログ確認:"
echo "   docker-compose logs -f web"
echo "   docker-compose logs -f worker"
echo ""
echo "🛑 停止:"
echo "   docker-compose down"
echo ""
