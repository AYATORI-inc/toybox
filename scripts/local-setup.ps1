# Local Development Setup Script (PowerShell)
# Caddy なし、20260930 バックアップ使用
# 
# 使用方法: powershell -File scripts/local-setup.ps1

# UTF-8 エンコーディング設定（日本語対応）
[console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host ""
Write-Host "🚀 ローカル開発環境セットアップ開始..." -ForegroundColor Green
Write-Host ""

# Step 1: .env をコピー
Write-Host "📝 Step 1: .env ファイルの準備..." -ForegroundColor Yellow

if (-not (Test-Path ".env")) {
    Copy-Item ".env.local" ".env"
    Write-Host "✅ .env.local をコピーしました" -ForegroundColor Green
} else {
    Write-Host "⚠️  .env が既に存在します" -ForegroundColor Yellow
}
Write-Host ""

# Step 2: Docker イメージをビルド & 起動
Write-Host "🐳 Step 2: Docker コンテナを起動..." -ForegroundColor Yellow
docker-compose up -d --build
Write-Host "✅ コンテナ起動完了" -ForegroundColor Green
Write-Host ""

# Step 3: DB の準備
Write-Host "📊 Step 3: データベースの初期化..." -ForegroundColor Yellow
Write-Host "  - バックアップをコピー中..."
docker cp "20260930/toybox_20260929_210014.dump" "toybox-db-1:/tmp/toybox.dump"

Write-Host "  - リストア実行中..."
docker exec toybox-db-1 pg_restore -U toybox_user -d toybox /tmp/toybox.dump

Write-Host "  - ユーザー数確認..."
$userCount = docker exec toybox-db-1 psql -U toybox_user -d toybox -c "SELECT COUNT(*) FROM auth_user;" | Select-Object -Last 2 | Select-Object -First 1
Write-Host "✅ DB リストア完了 (ユーザー: $userCount)" -ForegroundColor Green
Write-Host ""

# Step 4: Django マイグレーション
Write-Host "🔄 Step 4: Django マイグレーション..." -ForegroundColor Yellow
docker-compose exec -T web python manage.py migrate
Write-Host "✅ マイグレーション完了" -ForegroundColor Green
Write-Host ""

# Step 5: スタティックファイル収集
Write-Host "📦 Step 5: スタティックファイル収集..." -ForegroundColor Yellow
docker-compose exec -T web python manage.py collectstatic --noinput
Write-Host "✅ スタティックファイル収集完了" -ForegroundColor Green
Write-Host ""

# Step 6: メディアボリューム展開
Write-Host "🖼️  Step 6: メディアボリューム展開..." -ForegroundColor Yellow
docker exec toybox-web-1 mkdir -p /app/public/uploads
docker cp "20260930/media_volume_20260929_210020.tar.gz" "toybox-web-1:/tmp/"
docker exec toybox-web-1 tar -xzf /tmp/media_volume_20260929_210020.tar.gz -C /app/public/uploads/
Write-Host "✅ メディアボリューム展開完了" -ForegroundColor Green
Write-Host ""

# Step 7: ステータス確認
Write-Host "✅ Step 7: ステータス確認..." -ForegroundColor Yellow
docker-compose ps
Write-Host ""

# Step 8: ヘルスチェック
Write-Host "🏥 Step 8: ヘルスチェック..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

try {
    $response = Invoke-RestMethod -Uri "http://localhost:8000/api/health/" -ErrorAction SilentlyContinue
    if ($response.status -eq "ok") {
        Write-Host "✅ API ヘルスチェック: OK" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️  API ヘルスチェック: 失敗（ログを確認）" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "✨ セットアップ完了!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

Write-Host "📍 アクセス可能な URL:" -ForegroundColor Yellow
Write-Host "   API:       http://localhost:8000/api/" -ForegroundColor White
Write-Host "   管理画面:   http://localhost:8000/admin/" -ForegroundColor White
Write-Host "   ヘルス:     http://localhost:8000/api/health/" -ForegroundColor White
Write-Host ""

Write-Host "📋 ログ確認:" -ForegroundColor Yellow
Write-Host "   docker-compose logs -f web" -ForegroundColor DarkGray
Write-Host "   docker-compose logs -f worker" -ForegroundColor DarkGray
Write-Host ""

Write-Host "🛑 停止:" -ForegroundColor Yellow
Write-Host "   docker-compose down" -ForegroundColor DarkGray
Write-Host ""
