# Fix gateway-optimizer.ps1 encoding issue
$content = Get-Content 'C:\Users\Administrator\.openclaw\scripts\gateway-optimizer.ps1' -Raw -Encoding UTF8
$content = $content -replace 'Gateway服务优化完成！', 'Gateway service optimization completed!'
Set-Content 'C:\Users\Administrator\.openclaw\scripts\gateway-optimizer.ps1' -Value $content -Encoding UTF8 -Force
Write-Host "✅ Script fixed successfully" -ForegroundColor Green
