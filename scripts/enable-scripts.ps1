# PowerShell Execution Policy Setup
# 管理者として実行してください
#
# 使用方法: 管理者 PowerShell で実行
#   powershell -File scripts/enable-scripts.ps1

# UTF-8 エンコーディング設定（日本語対応）
[console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host ""
Write-Host "🔧 PowerShell 実行ポリシーを設定中..." -ForegroundColor Cyan
Write-Host ""

# 現在のポリシーを確認
$currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
Write-Host "現在のポリシー: $currentPolicy" -ForegroundColor Yellow

# ポリシーを変更
Write-Host ""
Write-Host "設定中: RemoteSigned に変更..." -ForegroundColor Green
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# 確認
$newPolicy = Get-ExecutionPolicy -Scope CurrentUser
Write-Host "新しいポリシー: $newPolicy" -ForegroundColor Green
Write-Host ""

if ($newPolicy -eq "RemoteSigned") {
    Write-Host "✅ PowerShell スクリプト実行が有効になりました!" -ForegroundColor Green
    Write-Host ""
    Write-Host "次のステップ:" -ForegroundColor Yellow
    Write-Host "  cd C:\github\toybox" -ForegroundColor White
    Write-Host "  powershell -File scripts/local-setup.ps1" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "⚠️  ポリシー変更に失敗しました。管理者として実行してください。" -ForegroundColor Red
    Write-Host ""
}
