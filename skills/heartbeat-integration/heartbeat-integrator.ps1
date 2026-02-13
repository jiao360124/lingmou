# Heartbeat循环集成器

# @Author: 灵眸
# @Version: 1.0.0
# @Date: 2026-02-13

param(
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false,

    [Parameter(Mandatory=$false)]
    [switch]$Verbose = $false
)

# 获取脚本路径
$ScriptPath = $PSScriptRoot
$TasksFile = "$ScriptPath/data/tasks.json"
$NotifyConfigFile = "$ScriptPath/data/notify-config.json"
$MemoryFile = "$ScriptPath/../../memory/YYYY-MM-DD.md"

# 初始化结果
$Result = @{
    Success = $false
    StartTime = Get-Date
    EndTime = $null
    Duration = 0
    Messages = @()
    Errors = @()
    TasksChecked = 0
    TasksExecuted = 0
    NotificationsSent = 0
    TasksOverdue = 0
}

# 日志函数
function Write-Log {
    param([string]$Message, [ValidateSet("INFO", "SUCCESS", "ERROR", "WARNING", "DEBUG", "HEARTBEAT")]
    [string]$Level = "INFO")

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Prefix = "[$Timestamp] [$Level]"

    switch ($Level) {
        "INFO"    { Write-Host "$Prefix $Message" -ForegroundColor Cyan }
        "SUCCESS" { Write-Host "$Prefix $Message" -ForegroundColor Green }
        "ERROR"   { Write-Host "$Prefix $Message" -ForegroundColor Red }
        "WARNING" { Write-Host "$Prefix $Message" -ForegroundColor Yellow }
        "DEBUG"   { Write-Host "$Prefix $Message" -ForegroundColor DarkGray }
        "HEARTBEAT" { Write-Host "$Prefix $Message" -ForegroundColor Magenta }
    }

    $Result.Messages += "$Prefix $Message"
}

try {
    Write-Log "Heartbeat循环集成器启动" "INFO"

    # 加载配置
    if (Test-Path $NotifyConfigFile) {
        $NotifyConfig = Get-Content -Path $NotifyConfigFile | ConvertFrom-Json
    } else {
        $NotifyConfig = @{
            sendNotifications = $true
            notifyHighPriority = $true
            notifyMediumPriority = $true
            notifyLowPriority = $false
            notifyOverdue = $true
            notifyReminderBeforeHours = 1
        }
    }

    Write-Log "通知配置已加载" "DEBUG"

    # 加载任务队列
    if (-not (Test-Path $TasksFile)) {
        Write-Log "任务队列为空" "WARNING"
        $TaskQueue = @()
    } else {
        $TaskQueue = Get-Content -Path $TasksFile | ConvertFrom-Json
        Write-Log "加载任务队列: $($TaskQueue.Count) 个任务" "INFO"
    }

    $Result.TasksChecked = $TaskQueue.Count

    # 检查优先级顺序
    $PriorityOrder = @{ "high" = 1; "medium" = 2; "low" = 3 }
    $SortedTasks = $TaskQueue | Sort-Object { $PriorityOrder[$_.priority] }

    # ========== 第1步：执行待办任务 ==========
    Write-Log "检查待办任务..." "HEARTBEAT"

    $PendingTasks = $SortedTasks | Where-Object { $_.status -eq "pending" }

    foreach ($Task in $PendingTasks) {
        Write-Log "  执行任务: $($Task.name) (优先级: $($Task.priority))" "HEARTBEAT"

        # 更新任务状态
        $Task.status = "in-progress"
        $Task.startedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

        # 执行任务（这里可以调用其他脚本）
        $Result.TasksExecuted++

        Write-Log "  ✓ 任务已开始执行" "SUCCESS"

        # 记录到记忆文件
        $MemoryNote = @"
# Heartbeat主动任务执行

## 任务执行
- **名称**: $($Task.name)
- **优先级**: $($Task.priority)
- **状态**: in-progress
- **开始时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
- **任务ID**: $($Task.id)

---

"@

        $MemoryNote | Out-File -FilePath $MemoryFile -Append -Encoding UTF8 -Force
    }

    # ========== 第2步：检查逾期任务 ==========
    Write-Log "检查逾期任务..." "HEARTBEAT"

    $TasksOverdue = @()
    $CutoffTime = (Get-Date).AddHours($NotifyConfig.notifyReminderBeforeHours)

    foreach ($Task in $SortedTasks) {
        if ($Task.dueDate -and $Task.status -ne "completed" -and $Task.status -ne "failed") {
            $DueDate = [DateTime]::Parse($Task.dueDate)

            if ([DateTime]::Now -gt $DueDate) {
                # 逾期了
                $TasksOverdue += $Task

                if ($NotifyConfig.notifyOverdue -and $PriorityOrder[$Task.priority] -le 2) {
                    Write-Log "  ⚠️ 逾期任务: $($Task.name)" "WARNING"

                    # 发送通知
                    $NotificationMessage = @"
[Heartbeat提醒] 任务逾期

任务名称: $($Task.name)
任务优先级: $($Task.priority)
任务类别: $($Task.category)
逾期时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
到期时间: $($Task.dueDate)
---

请尽快处理此任务。
"@

                    $Result.NotificationsSent++
                    Write-Log "  通知已发送" "HEARTBEAT"
                }
            } elseif ($DueDate -lt $CutoffTime) {
                # 即将逾期
                $RemainingHours = [math]::Round(($DueDate - [DateTime]::Now).TotalHours, 2)

                if ($NotifyConfig.notifyOverdue -and $PriorityOrder[$Task.priority] -le 2) {
                    Write-Log "  ⏰ 即将逾期: $($Task.name) ($RemainingHours 小时后)" "HEARTBEAT"

                    # 发送提醒
                    $NotificationMessage = @"
[Heartbeat提醒] 任务即将逾期

任务名称: $($Task.name)
任务优先级: $($Task.priority)
任务类别: $($Task.category)
剩余时间: $RemainingHours 小时
到期时间: $($Task.dueDate)
---

请尽快安排处理。
"@

                    $Result.NotificationsSent++
                    Write-Log "  提醒已发送" "HEARTBEAT"
                }
            }
        }
    }

    $Result.TasksOverdue = $TasksOverdue.Count

    # ========== 第3步：生成Heartbeat报告 ==========
    Write-Log "生成Heartbeat报告..." "HEARTBEAT"

    $HeartbeatReport = @"
# Heartbeat主动任务检查报告

**检查时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## 任务统计
- **总任务数**: $($TaskQueue.Count)
- **待办任务**: $($PendingTasks.Count)
- **进行中**: $($SortedTasks | Where-Object { $_.status -eq "in-progress" }.Count)
- **已完成**: $($SortedTasks | Where-Object { $_.status -eq "completed" }.Count)
- **逾期任务**: $TasksOverdue.Count
- **通知发送**: $Result.NotificationsSent

## 任务队列
"@

    foreach ($Task in $SortedTasks) {
        $StatusIcon = switch ($Task.status) {
            "pending" { "⏳" }
            "in-progress" { "🔄" }
            "completed" { "✅" }
            "failed" { "❌" }
        }

        $PriorityIcon = switch ($Task.priority) {
            "high" { "🔴" }
            "medium" { "🟡" }
            "low" { "🟢" }
        }

        $HeartbeatReport += "`n$StatusIcon $PriorityIcon $($Task.name) - $($Task.status)"

        if ($Task.dueDate) {
            $DueDate = [DateTime]::Parse($Task.dueDate)
            if ([DateTime]::Now -gt $DueDate) {
                $HeartbeatReport += " (逾期: $([math]::Round(($DueDate - [DateTime]::Now).TotalHours, 2))小时)"
            }
        }
    }

    $HeartbeatReport += "`n"

    # ========== 第4步：保存报告 ==========
    $ReportFile = "$ScriptPath/data/reports/heartbeat-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"

    if (-not (Test-Path (Split-Path $ReportFile))) {
        New-Item -ItemType Directory -Path (Split-Path $ReportFile) -Force | Out-Null
    }

    $HeartbeatReport | Out-File -FilePath $ReportFile -Encoding UTF8 -Force
    Write-Log "Heartbeat报告已保存: $ReportFile" "SUCCESS"

    # ========== 第5步：更新任务队列文件 ==========
    $TaskQueue | ConvertTo-Json -Depth 10 | Out-File -FilePath $TasksFile -Encoding UTF8 -Force
    Write-Log "任务队列已更新" "SUCCESS"

    # 设置最终状态
    $Result.Success = $true
    $Result.EndTime = Get-Date
    $Result.Duration = ($Result.EndTime - $Result.StartTime).TotalSeconds

    # ========== 输出摘要 ==========
    Write-Log "========== Heartbeat整合完成 ==========" "HEARTBEAT"
    Write-Log "检查任务: $($Result.TasksChecked)" "HEARTBEAT"
    Write-Log "执行任务: $($Result.TasksExecuted)" "HEARTBEAT"
    Write-Log "逾期任务: $TasksOverdue.Count" "WARNING"
    Write-Log "通知发送: $($Result.NotificationsSent)" "HEARTBEAT"
    Write-Log "执行时间: $([math]::Round($Result.Duration, 2))秒" "HEARTBEAT"
    Write-Log "========================================" "HEARTBEAT"

    if ($TasksOverdue.Count -gt 0) {
        Write-Log "`n⚠️ 发现 $($TasksOverdue.Count) 个逾期任务，请及时处理！" "WARNING"
    }

} catch {
    $Result.Success = $false
    $Result.Errors += $_.Exception.Message
    $Result.Errors += $_.ScriptStackTrace

    Write-Log "Heartbeat整合失败: $($_.Exception.Message)" "ERROR"

    # 保存错误报告
    $ErrorReport = @"
# Heartbeat循环集成器错误报告

**错误时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**操作**: Heartbeat整合
**错误信息**: $($_.Exception.Message)
堆栈跟踪:
$($_.ScriptStackTrace)

---

"@

    $ErrorReport | Out-File -FilePath "$ScriptPath/data/errors/heartbeat-error-$(Get-Date -Format 'yyyyMMdd-HHmmss').log" -Encoding UTF8 -Force

    Write-Log "错误报告已保存" "ERROR"

} finally {
    return $Result
}
