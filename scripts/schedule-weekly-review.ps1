# 配置Windows任务计划程序 - 每周自我修复引擎审查

Write-Host "📋 配置Windows任务计划程序..." -ForegroundColor Cyan

# 脚本路径
$ScriptPath = Join-Path $PSScriptRoot "weekly-self-healing-review.ps1"
$TaskName = "Weekly-Self-Healing-Review"
$LogPath = Join-Path $PSScriptRoot "review-scheduler.log"

# 检查脚本是否存在
if (-not (Test-Path $ScriptPath)) {
    Write-Host "❌ 错误: 脚本文件不存在: $ScriptPath" -ForegroundColor Red
    exit 1
}

# 获取当前用户
$UserName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

# 创建描述
$Description = "每周自动执行自我修复引擎审查，生成优化建议和审查报告"

# 设置触发器（每周日凌晨2点执行）
$Trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 2am

# 设置操作
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`"" -WorkingDirectory $PSScriptRoot

# 设置执行策略
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 5)

# 注册任务
try {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue | Out-Null

    Register-ScheduledTask -TaskName $TaskName `
        -Action $Action `
        -Trigger $Trigger `
        -Settings $Settings `
        -User $UserName `
        -RunLevel Highest `
        -Description $Description `
        -Force | Out-Null

    Write-Host "✅ 任务配置成功！" -ForegroundColor Green
    Write-Host "  任务名称: $TaskName" -ForegroundColor White
    Write-Host "  执行时间: 每周日 02:00" -ForegroundColor White
    Write-Host "  执行用户: $UserName" -ForegroundColor White
    Write-Host "  脚本路径: $ScriptPath" -ForegroundColor White
    Write-Host ""
    Write-Host "📝 日志文件: $LogPath" -ForegroundColor Gray

    # 创建日志文件
    $LogEntry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] 任务配置完成. 脚本: $ScriptPath"
    Add-Content -Path $LogPath -Value $LogEntry

    Write-Host "✅ Windows任务计划程序配置完成！" -ForegroundColor Green
} catch {
    Write-Host "❌ 任务配置失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
