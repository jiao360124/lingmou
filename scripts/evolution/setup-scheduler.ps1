# Moltbook自动调度任务设置脚本

Write-Host "`n" -NoNewline
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "         Moltbook自动调度任务设置" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

# 脚本路径
$scriptPath = "C:\Users\Administrator\.openclaw\workspace\scripts\evolution\heartbeat-monitor.ps1"
$schedulerName = "OpenClaw Moltbook Heartbeat"
$triggerTime = "03:00:00"

Write-Host "配置信息:" -ForegroundColor Yellow
Write-Host "  任务名称: $schedulerName" -ForegroundColor White
Write-Host "  执行时间: 每天 $triggerTime" -ForegroundColor White
Write-Host "  脚本路径: $scriptPath" -ForegroundColor White
Write-Host ""

# 创建任务触发器
$trigger = New-ScheduledTaskTrigger -Daily -At $triggerTime

# 创建任务操作
$action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`"" `
    -WorkingDirectory "C:\Users\Administrator\.openclaw\workspace"

# 设置任务设置
$settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -DontStopOnIdleEnd `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries

# 任务描述
$description = "OpenClaw Moltbook Heartbeat Monitor - 每天凌晨3点自动检查Moltbook健康状态"

# 创建任务
try {
    Register-ScheduledTask -TaskName $schedulerName `
        -Trigger $trigger `
        -Action $action `
        -Settings $settings `
        -Description $description `
        -RunLevel Highest `
        -Force | Out-Null

    Write-Host "✅ 任务创建成功！" -ForegroundColor Green
    Write-Host ""

    # 显示任务信息
    $task = Get-ScheduledTask -TaskName $schedulerName
    Write-Host "任务详情:" -ForegroundColor Yellow
    Write-Host "  状态: $($task.State)" -ForegroundColor White
    Write-Host "  执行时间: $($trigger.DaysInterval)天后每天 $triggerTime" -ForegroundColor White
    Write-Host "  触发器: $($trigger.TriggerType)" -ForegroundColor White
    Write-Host "  操作: PowerShell脚本" -ForegroundColor White
    Write-Host "  工作目录: C:\Users\Administrator\.openclaw\workspace" -ForegroundColor White
    Write-Host "  优先级: 最高" -ForegroundColor White
    Write-Host ""

    # 检查任务是否立即运行
    $taskRunning = Start-ScheduledTask -TaskName $schedulerName -Action $action
    Write-Host "✅ 任务已启动测试运行！" -ForegroundColor Green
    Write-Host "  任务运行中..." -ForegroundColor Gray
    Start-Sleep -Seconds 2
    Stop-ScheduledTask -TaskName $schedulerName
    Write-Host "  测试运行完成" -ForegroundColor Gray
    Write-Host ""

    # 显示下次运行时间
    $trigger = Get-ScheduledTaskInfo -TaskName $schedulerName
    Write-Host "下次运行时间: $($trigger.NextRunTime)" -ForegroundColor Cyan

    Write-Host "`n" -NoNewline
    Write-Host "=" * 80 -ForegroundColor Green
    Write-Host "         自动调度任务设置完成！" -ForegroundColor Green
    Write-Host "=" * 80 -ForegroundColor Green
    Write-Host ""

    Write-Host "🎯 后续步骤:" -ForegroundColor Cyan
    Write-Host "  1. 验证任务正常运行"
    Write-Host "  2. 检查日志文件"
    Write-Host "  3. 检查Moltbook心跳记录"
    Write-Host "  4. 开始KPI数据收集"
    Write-Host ""

    Write-Host "📁 日志位置:" -ForegroundColor Cyan
    Write-Host "  心跳日志: C:\Users\Administrator\.openclaw\workspace\logs\heartbeat.log" -ForegroundColor White
    Write-Host "  状态文件: C:\Users\Administrator\.openclaw\workspace\data\heartbeat-status.json" -ForegroundColor White
    Write-Host ""

}
catch {
    Write-Host "❌ 任务创建失败: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "错误详情:" -ForegroundColor Yellow
    Write-Host "$($_.ScriptStackTrace)" -ForegroundColor Gray
}

Write-Host "`n按回车退出..."
$null = Read-Host
