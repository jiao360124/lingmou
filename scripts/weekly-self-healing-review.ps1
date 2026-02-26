# 每周自我修复引擎审查自动执行脚本

# 设置脚本路径
$ScriptPath = "$PSScriptRoot\..\skills\self-healing-engine\scripts\periodic-review.ps1"
$ReportDir = "$PSScriptRoot\..\skills\self-healing-engine\reports"

# 创建报告目录（如果不存在）
if (-not (Test-Path $ReportDir)) {
    New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null
}

# 设置执行策略
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# 获取当前时间
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

# 执行周期性审查
Write-Host "🧹 执行每周自我修复引擎审查..." -ForegroundColor Cyan
Write-Host "  时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "  报告目录: $ReportDir" -ForegroundColor Gray
Write-Host ""

& $ScriptPath -Action weekly

Write-Host ""
Write-Host "✅ 每周审查完成！" -ForegroundColor Green
Write-Host "  时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

# 记录日志
$logFile = "$PSScriptRoot\weekly-review.log"
$logEntry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Weekly review completed. Output to: $ReportDir"
Add-Content -Path $logFile -Value $logEntry

Write-Host "  日志: $logFile" -ForegroundColor Gray
