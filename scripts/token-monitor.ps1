#!/usr/bin/env powershell
# Token管理监控脚本
# 执行频率: 每30分钟

Write-Host "🔍 Token监控检查 - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan

$workspace = "C:\Users\Administrator\.openclaw\workspace"
$logFile = "$workspace\logs\token-monitor.log"

# 确保logs目录存在
if (!(Test-Path (Split-Path $logFile -Parent))) {
    New-Item -ItemType Directory -Path (Split-Path $logFile -Parent) -Force | Out-Null
}

# 记录开始
$time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Host "[$time] 开始Token监控检查" -ForegroundColor Yellow
Add-Content -Path $logFile -Value "[$time] Token监控检查开始"

# 获取session列表
$activeSessions = sessions_list
$sessionCount = $activeSessions.agents.count

Write-Host "📊 当前活跃Session数: $sessionCount" -ForegroundColor Yellow
Add-Content -Path $logFile -Value "活跃Session数: $sessionCount"

# 获取main session状态
$mainSession = sessions_list | Where-Object { $_.label -eq "main" }

if ($mainSession) {
    Write-Host "`n🔑 Main Session状态:" -ForegroundColor Yellow

    if ($mainSession.usage) {
        $usage = $mainSession.usage

        Write-Host "  - Token使用率: $($usage.percentage)% (当前: $($usage.current) / 最大: $($usage.max))" -ForegroundColor $(if ($usage.percentage -gt 80) { "Red" } elseif ($usage.percentage -gt 70) { "Yellow" } else { "Green" })
        Add-Content -Path $logFile -Value "Main Session Token使用: $($usage.percentage)% (当前: $($usage.current))"

        # 判断是否需要清理
        if ($usage.percentage -gt 90) {
            Write-Host "  ⚠️  警告：Token使用率超过90%！" -ForegroundColor Red
            Write-Host "  → 建议立即清理old sessions" -ForegroundColor Red
            Add-Content -Path $logFile -Value "⚠️  警告：Token使用率超过90%"

            # 清理策略
            $clearedCount = 0
            Write-Host "`n🧹 执行清理策略..." -ForegroundColor Yellow

            try {
                # 清理非活跃sessions
                $inactiveSessions = sessions_list | Where-Object {
                    $_.last_message -lt (Get-Date).AddMinutes(-30)
                }

                foreach ($session in $inactiveSessions) {
                    try {
                        sessions_send `
                            -sessionKey $_.key `
                            -message "Session正在清理以释放token资源..." \
                            -timeoutSeconds 5

                        Write-Host "  ✓ 清理session: $($_.label)" -ForegroundColor Green
                        $clearedCount++
                    } catch {
                        Write-Host "  ✗ 清理失败: $($_.label)" -ForegroundColor Red
                    }
                }

                if ($clearedCount -gt 0) {
                    Write-Host "`n✓ 清理完成，共清理 $clearedCount 个sessions" -ForegroundColor Green
                    Add-Content -Path $logFile -Value "清理完成，共清理 $clearedCount 个sessions"
                }
            } catch {
                Write-Host "  ✗ 清理过程出错: $_" -ForegroundColor Red
            }
        } elseif ($usage.percentage -gt 70) {
            Write-Host "  ⚠️  注意：Token使用率达到70%" -ForegroundColor Yellow
            Add-Content -Path $logFile -Value "注意：Token使用率达到70%"
        } else {
            Write-Host "  ✓ Token使用率健康 (<70%)" -ForegroundColor Green
        }
    } else {
        Write-Host "  ⚠️  无法获取Token使用率信息" -ForegroundColor Yellow
        Add-Content -Path $logFile -Value "无法获取Token使用率"
    }
}

# 生成报告
$report = @"
Token监控报告 - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
========================

总活跃Sessions: $sessionCount
Main Session Token使用率: $($mainSession.usage.percentage)% (如果可用)
监控时间: $time

"@

Write-Host "`n$report" -ForegroundColor Gray
Add-Content -Path $logFile -Value $report

Write-Host "✓ Token监控完成！" -ForegroundColor Green
Add-Content -Path $logFile -Value "`n[$time] Token监控完成"
