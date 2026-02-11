# 从Git历史中移除敏感信息
$script = @'
git filter-branch --force --tree-filter '
  if (Test-Path "memory/2026-02-10.md") {
    (Get-Content "memory/2026-02-10.md") -replace "github_pat_[A-Za-z0-9_]+", "REDACTED_TOKEN" | Set-Content "memory/2026-02-10.md"
  }
  if (Test-Path "scripts/cleanup-github-tokens.ps1") {
    (Get-Content "scripts/cleanup-github-tokens.ps1") -replace "github_pat_[A-Za-z0-9_]+", "REDACTED_TOKEN" | Set-Content "scripts/cleanup-github-tokens.ps1"
  }
' -- --all
'@

$script | Out-File -FilePath "remove-tokens.ps1" -Encoding UTF8
Write-Host "✓ 脚本已创建: remove-tokens.ps1" -ForegroundColor Green
Write-Host "✓ 现在运行: powershell -ExecutionPolicy Bypass -File remove-tokens.ps1" -ForegroundColor Cyan
