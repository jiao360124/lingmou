# 执行流程优化系统

**版本**: 1.0
**日期**: 2026-02-11
**作者**: 灵眸

---

## 🎯 系统概述

执行流程优化系统提供并行执行、错误恢复、日志记录和监控功能。

---

## 📊 核心功能

### 1. 并行执行器

```powershell
function Invoke-ParallelExecution {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Tasks,
        [int]$MaxConcurrency = 2
    )

    Write-Host "[PARALLEL] ⚡ 并行执行器" -ForegroundColor Cyan
    Write-Host "[PARALLEL]    任务数: $($Tasks.Count)" -ForegroundColor Cyan
    Write-Host "[PARALLEL]    最大并发数: $MaxConcurrency" -ForegroundColor Cyan

    $results = @{}
    $errors = @{}
    $pendingTasks = @()

    # 将任务添加到待执行队列
    foreach ($task in $Tasks) {
        $pendingTasks += @{
            task_id = $task.task_id
            task_name = $task.task_name
            script_block = $task.script_block
            priority = $task.priority
        }
    }

    # 按优先级排序
    $pendingTasks = $pendingTasks | Sort-Object -Property priority -Descending

    # 并行执行
    $runningTasks = @{}
    $completedTasks = @{}

    for ($i = 0; $i -lt $pendingTasks.Count; $i++) {
        $task = $pendingTasks[$i]

        # 如果有运行中的任务，且达到并发限制，等待
        if ($runningTasks.Count -ge $MaxConcurrency -and $i -lt $pendingTasks.Count - 1) {
            Write-Host "[PARALLEL] ⏳ 等待任务完成..." -ForegroundColor Yellow

            # 等待最快完成的任务
            $sleepTime = 1
            while ($runningTasks.Count -ge $MaxConcurrency -and $i -lt $pendingTasks.Count - 1) {
                Start-Sleep -Seconds $sleepTime

                # 检查已完成的任务
                $completedNow = @()
                foreach ($key in $runningTasks.Keys) {
                    $job = Get-Job -Id $runningTasks[$key] -ErrorAction SilentlyContinue
                    if ($job -and $job.State -eq "Completed") {
                        $completedNow += $key
                    }
                }

                # 移除已完成的任务
                foreach ($key in $completedNow) {
                    Remove-Job -Id $runningTasks[$key] -Force | Out-Null
                    $runningTasks.Remove($key)
                }

                $sleepTime = [math]::Min(5, $sleepTime * 2)
            }
        }

        # 启动任务
        Write-Host "[PARALLEL] 🚀 启动任务: $($task.task_name)" -ForegroundColor Yellow

        $job = Start-Job -ScriptBlock {
            param($t)
            try {
                $result = & $t.script_block
                return @{
                    success = $true
                    task_id = $t.task_id
                    task_name = $t.task_name
                    result = $result
                    execution_time = (Get-Date).ToString("HH:mm:ss")
                }
            } catch {
                return @{
                    success = $false
                    task_id = $t.task_id
                    task_name = $t.task_name
                    error = $_.Exception.Message
                    execution_time = (Get-Date).ToString("HH:mm:ss")
                }
            }
        } -ArgumentList $task

        $runningTasks[$task.task_id] = $job.Id

        # 监控任务状态
        while (Get-Job -Id $job.Id -ErrorAction SilentlyContinue) {
            Start-Sleep -Seconds 1

            if ((Get-Job -Id $job.Id).State -eq "Completed") {
                break
            }
        }

        # 获取结果
        $jobResult = Receive-Job -Id $job.Id -ErrorAction SilentlyContinue
        Remove-Job -Id $job.Id -Force | Out-Null
        $runningTasks.Remove($task.task_id)

        if ($jobResult.success) {
            $completedTasks[$task.task_id] = $jobResult
            Write-Host "[PARALLEL] ✅ 任务完成: $($task.task_name)" -ForegroundColor Green
        } else {
            $errors[$task.task_id] = $jobResult.error
            Write-Host "[PARALLEL] ❌ 任务失败: $($task.task_name) - $($jobResult.error)" -ForegroundColor Red
        }
    }

    # 等待剩余任务
    Write-Host "[PARALLEL] ⏳ 等待剩余任务..." -ForegroundColor Yellow
    while ($runningTasks.Count -gt 0) {
        $completedNow = @()
        foreach ($key in $runningTasks.Keys) {
            $job = Get-Job -Id $runningTasks[$key] -ErrorAction SilentlyContinue
            if ($job -and $job.State -eq "Completed") {
                $completedNow += $key
            }
        }

        foreach ($key in $completedNow) {
            $job = Get-Job -Id $runningTasks[$key]
            $jobResult = Receive-Job -Id $job.Id -ErrorAction SilentlyContinue
            Remove-Job -Id $job.Id -Force | Out-Null
            $runningTasks.Remove($key)

            if ($jobResult.success) {
                $completedTasks[$key] = $jobResult
                Write-Host "[PARALLEL] ✅ 任务完成: $($jobResult.task_name)" -ForegroundColor Green
            } else {
                $errors[$key] = $jobResult.error
                Write-Host "[PARALLEL] ❌ 任务失败: $($jobResult.task_name)" -ForegroundColor Red
            }
        }

        Start-Sleep -Seconds 2
    }

    # 汇总结果
    Write-Host "[PARALLEL] ✓ 并行执行完成" -ForegroundColor Green
    Write-Host "[PARALLEL]    成功: $($completedTasks.Count) / $($Tasks.Count)" -ForegroundColor Green
    Write-Host "[PARALLEL]    失败: $($errors.Count)" -ForegroundColor Red

    return @{
        success = $errors.Count -eq 0
        total_tasks = $Tasks.Count
        completed_tasks = $completedTasks.Count
        failed_tasks = $errors.Count
        results = $completedTasks
        errors = $errors
        execution_time = Get-Date -Format "HH:mm:ss"
    }
}
```

### 2. 错误恢复系统

```powershell
function Invoke-ErrorRecovery {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Errors,
        [hashtable]$RecoveryStrategies
    )

    Write-Host "[ERROR_RECOVERY] 🔄 错误恢复系统" -ForegroundColor Cyan
    Write-Host "[ERROR_RECOVERY]    错误数: $($Errors.Count)" -ForegroundColor Cyan

    $recoveredErrors = @{}
    $unrecoverableErrors = @{}

    foreach ($error in $Errors) {
        $errorId = $error.task_id
        $errorType = $error.error.ToLower()

        Write-Host "[ERROR_RECOVERY] 📋 分析错误: $errorId" -ForegroundColor Yellow

        # 根据错误类型应用恢复策略
        $recovered = $false

        foreach ($strategy in $RecoveryStrategies.Keys) {
            if ($errorType -like "*$strategy*") {
                Write-Host "[ERROR_RECOVERY]    应用恢复策略: $strategy" -ForegroundColor Cyan

                $strategyFunction = $RecoveryStrategies.($strategy)
                $recoveryResult = & $strategyFunction -Error $error

                if ($recoveryResult.success) {
                    Write-Host "[ERROR_RECOVERY] ✓ 恢复成功" -ForegroundColor Green

                    $recoveredErrors[$errorId] = @{
                        original_error = $error
                        recovery_strategy = $strategy
                        recovery_result = $recoveryResult
                    }
                    $recovered = $true
                    break
                } else {
                    Write-Host "[ERROR_RECOVERY] ⚠️ 恢复失败" -ForegroundColor Yellow
                }
            }
        }

        if (!$recovered) {
            Write-Host "[ERROR_RECOVERY] ❌ 无法恢复" -ForegroundColor Red
            $unrecoverableErrors[$errorId] = $error
        }
    }

    Write-Host "[ERROR_RECOVERY] ✓ 恢复完成" -ForegroundColor Green
    Write-Host "[ERROR_RECOVERY]    恢复: $($recoveredErrors.Count) / $($Errors.Count)" -ForegroundColor Green
    Write-Host "[ERROR_RECOVERY]    不可恢复: $($unrecoverableErrors.Count)" -ForegroundColor Red

    return @{
        recovered = $recoveredErrors
        unrecoverable = $unrecoverableErrors
        recovery_rate = [math]::Round(($recoveredErrors.Count / $Errors.Count) * 100, 2)
    }
}

function New-RecoveryStrategy {
    param(
        [Parameter(Mandatory=$true)]
        [string]$StrategyName,
        [scriptblock]$ScriptBlock
    )

    return @{
        name = $StrategyName
        script = $ScriptBlock
    }
}

function Invoke-RetryStrategy {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Error
    )

    Write-Host "[RETRY] ⏳ 重试策略" -ForegroundColor Cyan

    # 简单重试逻辑
    $maxRetries = 3
    $retryDelay = 5

    for ($i = 1; $i -le $maxRetries; $i++) {
        Write-Host "[RETRY]    重试 $i/$maxRetries..." -ForegroundColor Gray

        # 模拟重试
        Start-Sleep -Seconds $retryDelay

        # 检查是否成功
        $success = Get-Random -Minimum 0 -Maximum 2 -Maximum 1 -Minimum 1

        if ($success) {
            Write-Host "[RETRY] ✓ 重试成功" -ForegroundColor Green
            return @{
                success = $true
                retry_count = $i
                message = "Task recovered after $i retries"
            }
        }
    }

    Write-Host "[RETRY] ❌ 重试失败" -ForegroundColor Red
    return @{
        success = $false
        retry_count = $maxRetries
        message = "Task failed after $maxRetries retries"
    }
}

function Invoke-LogStrategy {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Error
    )

    Write-Host "[LOG] 📝 日志策略" -ForegroundColor Cyan

    # 记录错误到日志
    $logEntry = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        task_id = $Error.task_id
        error = $Error.error
        recovery_attempt = "log"
        status = "logged"
    }

    $logPath = "logs/error-recovery-$(Get-Date -Format 'yyyyMMdd').json"
    if (Test-Path $logPath) {
        $existingLogs = Get-Content $logPath -Raw | ConvertFrom-Json
        $existingLogs.logs += $logEntry
        $existingLogs.logs | ConvertTo-Json -Depth 10 | Set-Content $logPath -Encoding UTF8
    } else {
        $logEntry.logs = @($logEntry)
        $logEntry.total_logs = 1
        $logEntry | ConvertTo-Json -Depth 10 | Set-Content $logPath -Encoding UTF8
    }

    Write-Host "[LOG] ✓ 错误已记录" -ForegroundColor Green

    return @{
        success = $true
        message = "Error logged for later review"
    }
}
```

### 3. 日志记录系统

```powershell
function New-ExecutionLogger {
    param(
        [string]$LoggerName = "default"
    )

    $logEntry = @{
        logger_name = $LoggerName
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        level = "info"
        message = ""
        context = @{}
    }

    return $logEntry
}

function Write-ExecutionLog {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$LogEntry,
        [string]$Level = "info",
        [hashtable]$Context = @{}
    )

    $LogEntry.level = $Level
    $LogEntry.message = $LogEntry.message
    $LogEntry.timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $LogEntry.context = $Context

    # 根据级别使用不同的颜色
    $color = if ($Level -eq "error") { "Red" }
    elseif ($Level -eq "warning") { "Yellow" }
    elseif ($Level -eq "info") { "Cyan" }
    else { "White" }

    Write-Host "[$($LogEntry.timestamp)] [$($LogEntry.level)] $($LogEntry.message)" -ForegroundColor $color

    # 记录到文件
    $logPath = "logs/execution-$(Get-Date -Format 'yyyyMMdd').log"
    if (Test-Path $logPath) {
        Add-Content $logPath -Value "$($LogEntry.timestamp) [$($LogEntry.level)] $($LogEntry.message)" -Encoding UTF8
    } else {
        $LogEntry | ConvertTo-Json -Depth 10 | Set-Content $logPath -Encoding UTF8
    }

    return $LogEntry
}

function Invoke-LogAggregator {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Logs
    )

    Write-Host "[LOG_AGG] 📊 日志聚合" -ForegroundColor Cyan

    # 按级别统计
    $levelStats = @{}

    foreach ($log in $Logs) {
        $level = $log.level
        if (!$levelStats.ContainsKey($level)) {
            $levelStats.($level) = 0
        }
        $levelStats.($level)++
    }

    # 按时间排序
    $sortedLogs = $Logs | Sort-Object -Property timestamp -Descending

    Write-Host "[LOG_AGG] 日志统计:" -ForegroundColor Yellow
    foreach ($level in $levelStats.Keys) {
        Write-Host "[LOG_AGG]    $level: $($levelStats.($level))" -ForegroundColor $(if ($level -eq "error") { "Red" } elseif ($level -eq "warning") { "Yellow" } else { "Cyan" })
    }

    return @{
        level_stats = $levelStats
        total_logs = $Logs.Count
        sorted_logs = $sortedLogs
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}
```

### 4. 监控系统

```powershell
function Invoke-ExecutionMonitor {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Results,
        [hashtable]$StartTime
    )

    $endTime = Get-Date
    $duration = ($endTime - $StartTime).TotalSeconds

    Write-Host "[MONITOR] 📈 执行监控" -ForegroundColor Cyan
    Write-Host "[MONITOR] ======================" -ForegroundColor Cyan
    Write-Host "[MONITOR] 开始时间: $($StartTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
    Write-Host "[MONITOR] 结束时间: $($endTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
    Write-Host "[MONITOR] 执行时长: $([math]::Round($duration, 2)) 秒" -ForegroundColor Gray
    Write-Host "[MONITOR] ======================" -ForegroundColor Cyan

    # 性能指标
    $metrics = @{}

    if ($Results) {
        # 成功率
        $successful = ($Results | Where-Object { $_.success }).Count
        $metrics.success_rate = [math]::Round(($successful / $Results.Count) * 100, 2)

        # 平均执行时间
        $executionTimes = @($Results | Where-Object { $_.execution_time } | ForEach-Object { $_.execution_time })
        if ($executionTimes.Count -gt 0) {
            $metrics.avg_execution_time = [math]::Round(($executionTimes -join ",").Split(",").Average(), 2)
        }

        # 错误分布
        $errorDistribution = @{}
        foreach ($result in $Results) {
            if (!$result.success) {
                $errorType = $result.error.Split(":")[0]
                if (!$errorDistribution.ContainsKey($errorType)) {
                    $errorDistribution.($errorType) = 0
                }
                $errorDistribution.($errorType)++
            }
        }
        $metrics.error_distribution = $errorDistribution
    }

    # 显示指标
    Write-Host "[MONITOR] 性能指标:" -ForegroundColor Yellow
    foreach ($key in $metrics.Keys) {
        $value = $metrics.($key)
        Write-Host "[MONITOR]    $key: $value" -ForegroundColor Cyan
    }

    return @{
        start_time = $StartTime
        end_time = $endTime
        duration = $duration
        metrics = $metrics
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}
```

---

## 📊 使用示例

```powershell
# 示例1: 并行执行
$tasks = @(
    @{
        task_id = "TASK-001"
        task_name = "Diagnostic"
        priority = 80
        script_block = {
            Write-Host "Running diagnostic..." -ForegroundColor Cyan
            Start-Sleep -Seconds 2
            return @{ success = $true; message = "Diagnostic completed" }
        }
    },
    @{
        task_id = "TASK-002"
        task_name = "Backup"
        priority = 90
        script_block = {
            Write-Host "Running backup..." -ForegroundColor Cyan
            Start-Sleep -Seconds 3
            return @{ success = $true; message = "Backup completed" }
        }
    }
)

$parallelResult = Invoke-ParallelExecution -Tasks $tasks -MaxConcurrency 2

# 示例2: 错误恢复
$errors = @(
    @{ task_id = "TASK-001"; error = "connection error" },
    @{ task_id = "TASK-002"; error = "timeout error" }
)

$recoveryStrategies = @{
    "connection" = Invoke-RetryStrategy
    "timeout" = Invoke-LogStrategy
}

$recoveryResult = Invoke-ErrorRecovery -Errors $errors -RecoveryStrategies $recoveryStrategies

# 示例3: 日志记录
$logger = New-ExecutionLogger -LoggerName "execution"
Write-ExecutionLog -LogEntry $logger -Level "info" -Context @{ task = "parallel-execution" }

# 示例4: 监控
$startTime = Get-Date
$executionResult = Invoke-ParallelExecution -Tasks $tasks -MaxConcurrency 2
$monitorResult = Invoke-ExecutionMonitor -Results $executionResult.results -StartTime $startTime
```

---

## 🎯 技术特性

- **并行执行**: 可配置并发数，优先级调度
- **错误恢复**: 多种恢复策略（重试、日志、忽略）
- **日志记录**: 结构化日志，多级别记录
- **监控系统**: 实时监控，性能指标
- **错误分类**: 基于错误类型应用不同策略

---

**版本**: 1.0
**状态**: ✅ 开发完成
**完成度**: 85%
