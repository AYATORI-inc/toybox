# Cleanup Refactoring Script (PowerShell)
# local-setup.ps1 テスト完了後に実行
#
# 使用方法: powershell -File scripts/cleanup-refactoring.ps1

# UTF-8 エンコーディング設定（日本語対応）
[console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host ""
Write-Host "🧹 リファクタリング開始（不要ファイル削除）..." -ForegroundColor Yellow
Write-Host ""

# 前提条件確認
Write-Host "📋 前提条件確認..." -ForegroundColor Cyan
$health = Invoke-RestMethod -Uri "http://localhost:8000/api/health/" -ErrorAction SilentlyContinue
if ($health.status -eq "ok") {
    Write-Host "✅ API ヘルスチェック: OK" -ForegroundColor Green
} else {
    Write-Host "⚠️  API ヘルスチェック失敗。local-setup.ps1 を先に実行してください" -ForegroundColor Red
    exit 1
}
Write-Host ""

# 削除対象ファイルリスト
$filesToDelete = @(
    'docker-compose.prod.yml',
    'Dockerfile.caddy',
    'Caddyfile',
    'Caddyfile.backup',
    'Caddyfile.backup.20260119_152430',
    'Caddyfile.backup.20260119_152650',
    'restore_caddyfile.sh',
    '=',
    '[beat',
    'CACHED',
    'CANCELED',
    'ERROR',
    '[internal]',
    'reading',
    'transferring',
    '[web',
    '[worker'
)

# 削除実行
Write-Host "🗑️  不要ファイルを削除中..." -ForegroundColor Yellow
$deletedCount = 0

foreach ($file in $filesToDelete) {
    $path = Join-Path (Get-Location) $file
    
    if (Test-Path $path) {
        try {
            if ((Get-Item $path).PSIsContainer) {
                Remove-Item $path -Recurse -Force -ErrorAction Stop
            } else {
                Remove-Item $path -Force -ErrorAction Stop
            }
            Write-Host "  ✅ 削除: $file" -ForegroundColor Green
            $deletedCount++
        } catch {
            Write-Host "  ⚠️  削除失敗: $file ($_)" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "✅ 削除完了: $deletedCount 個のファイル/フォルダ" -ForegroundColor Green
Write-Host ""

# 現在のファイル一覧表示
Write-Host "📁 残存ファイル一覧:" -ForegroundColor Cyan
Get-ChildItem -Path . -File | Where-Object {-not $_.Name.StartsWith(".")} | 
    Select-Object -ExpandProperty Name | 
    ForEach-Object { Write-Host "  $_" -ForegroundColor White }

Write-Host ""
Write-Host "📂 重要なフォルダ:" -ForegroundColor Cyan
Get-ChildItem -Path . -Directory | Where-Object {-not $_.Name.StartsWith(".")} | 
    Select-Object -ExpandProperty Name | 
    ForEach-Object { Write-Host "  $_/" -ForegroundColor White }

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

Write-Host ""
Write-Host "📋 次のステップ:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1️⃣  Git 状態確認" -ForegroundColor White
Write-Host "     git status" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  2️⃣  変更をステージング" -ForegroundColor White
Write-Host "     git add -A" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  3️⃣  コミット（複数に分割推奨）" -ForegroundColor White
Write-Host "     git commit -m 'chore: Remove Caddy-related files'" -ForegroundColor DarkGray
Write-Host "     git commit -m 'chore: Clean up old files'" -ForegroundColor DarkGray
Write-Host "     git commit -m 'chore: Add docker-compose and setup scripts'" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  4️⃣  プッシュ" -ForegroundColor White
Write-Host "     git push origin main" -ForegroundColor DarkGray
Write-Host ""

Write-Host "✨ リファクタリング完了!" -ForegroundColor Green
Write-Host ""
