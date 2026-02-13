<#
.SYNOPSIS
Concurrency Manager

.DESCRIPTION
并发管理器，实现线程池、任务队列

.NOTES
Author: OpenClaw Assistant
Date: 2026-02-16
Version: 1.0.0
#>

# 并发配置
$concurrencyConfig = @{
    threadPoolSize = 10
    maxConcurrent = 50
    queueSize = 1000
    queueTimeout = 30000
    priorityLevels = @("low", "normal", "high", "urgent")
}

# 任务队列
$taskQueue = @()
$completedTasks = @()
$runningTasks = @{}

# 线程池
function Initialize-ThreadPool {
    param(
        [int]$Size = $concurrencyConfig.threadPoolSize
    )

    $concurrencyConfig.threadPoolSize = $Size

    Write-Host "Thread pool initialized with $Size threads" -ForegroundColor Green
}

# 创建任务
function New-Task {
    param(
        [scriptblock]$ScriptBlock,
        [string]$Name,
        [string]$Priority = "normal",
        [hashtable]$Parameters = @{},
        [int]$Timeout = 0
    )

    $task = [PSCustomObject]@{
        id = [guid]::NewGuid().ToString()
        name = $Name
        scriptBlock = $ScriptBlock
        parameters = $Parameters
        priority = $Priority
        status = "queued"
        startTime = $null
        endTime = $null
        result = $null
        error = $null
        timeout = $Timeout
        retryCount = 0
    }

    return $task
}

# 添加任务到队列
function Add-TaskToQueue {
    param(
        [PSCustomObject]$Task
    )

    # 优先级排序
    $priorityOrder = @("urgent", "high", "normal", "low")

    $taskQueue += $Task
    $taskQueue = $taskQueue | Sort-Object {
        $priorityOrder.IndexOf($_.priority)
    }

    Write-Host "Task added to queue: $($Task.name) (Priority: $($Task.priority))" -ForegroundColor Yellow
}

# 获取可用任务
function Get-NextTask {
    param(
        [int]$MaxConcurrent = $concurrencyConfig.maxConcurrent
    )

    $runningCount = ($runningTasks.Values | Where-Object { $_.status -eq "running" }).Count

    if ($runningCount -ge $MaxConcurrent) {
        return $null
    }

    foreach ($task in $taskQueue) {
        if ($task.status -eq "queued") {
            $task.status = "running"
            $task.startTime = Get-Date
            $runningTasks[$task.id] = $task
            return $task
        }
    }

    return $null
}

# 执行任务
function Invoke-Task {
    param(
        [PSCustomObject]$Task
    )

    $taskId = $Task.id

    try {
        $result = & $Task.scriptBlock @Task.parameters
        $Task.result = $result
        $Task.status = "completed"
        $Task.endTime = Get-Date

        $runningTasks.Remove($taskId)
        $completedTasks += $Task

        Write-Host "Task completed: $($Task.name)" -ForegroundColor Green

        return @{
            success = $true
            result = $result
            task = $Task
        }
    }
    catch {
        $Task.error = $_.Exception.Message
        $Task.status = "failed"

        $runningTasks.Remove($taskId)

        Write-Host "Task failed: $($Task.name) - $($_.Exception.Message)" -ForegroundColor Red

        return @{
            success = $false
            error = $_.Exception.Message
            task = $Task
        }
    }
}

# 并发执行任务
function Invoke-TasksInParallel {
    param(
        [PSCustomObject[]]$Tasks,
        [int]$MaxConcurrent = $concurrencyConfig.maxConcurrent
    )

    $results = @()

    foreach ($task in $Tasks) {
        Add-TaskToQueue -Task $Task
    }

    # 并发执行
    while ($taskQueue.Count -gt 0 -or ($runningTasks.Values | Where-Object { $_.status -eq "running" }).Count -gt 0) {
        $task = Get-NextTask -MaxConcurrent $MaxConcurrent

        if ($task) {
            $result = Invoke-Task -Task $task
            $results += $result
        }

        Start-Sleep -Milliseconds 10
    }

    return @{
        results = $results
        total = $results.Count
        successful = ($results | Where-Object { $_.success }).Count
        failed = ($results | Where-Object { -not $_.success }).Count
    }
}

# 定时执行任务
function Start-TaskScheduler {
    param(
        [scriptblock]$TaskProvider,
        [int]$Interval = 60000  # 1 minute
    )

    Write-Host "Task scheduler started (Interval: $Interval ms)" -ForegroundColor Green

    while ($true) {
        $tasks = & $TaskProvider

        if ($tasks) {
            foreach ($task in $tasks) {
                Add-TaskToQueue -Task $task
            }
        }

        Start-Sleep -Milliseconds $Interval
    }
}

# 取消任务
function Cancel-Task {
    param([string]$TaskId)

    $task = $taskQueue | Where-Object { $_.id -eq $TaskId }

    if ($task) {
        $task.status = "cancelled"
        $taskQueue = $taskQueue | Where-Object { $_.id -ne $TaskId }

        $runningTask = $runningTasks.Values | Where-Object { $_.id -eq $TaskId }
        if ($runningTask) {
            $runningTask.status = "cancelled"
        }

        Write-Host "Task cancelled: $TaskId" -ForegroundColor Yellow
    }
}

# 清空队列
function Clear-TaskQueue {
    $taskQueue = @()
    $runningTasks = @{}
    $completedTasks = @{}

    Write-Host "Task queue cleared" -ForegroundColor Green
}

# 获取队列统计
function Get-QueueStats {
    $stats = [PSCustomObject]@{
        queued = $taskQueue.Count
        running = ($runningTasks.Values | Where-Object { $_.status -eq "running" }).Count
        completed = $completedTasks.Count
        failed = ($completedTasks | Where-Object { $_.error }).Count
        total = $taskQueue.Count + $runningTasks.Count + $completedTasks.Count
    }

    return $stats
}

# 任务结果统计
function Get-TaskStats {
    $stats = [PSCustomObject]@{
        totalCompleted = $completedTasks.Count
        totalFailed = ($completedTasks | Where-Object { $_.error }).Count
        totalRunning = ($runningTasks.Values | Where-Object { $_.status -eq "running" }).Count
        totalQueued = $taskQueue.Count

        byStatus = @{
            queued = $taskQueue.Count
            running = ($runningTasks.Values | Where-Object { $_.status -eq "running" }).Count
            completed = ($completedTasks | Where-Object { $_.error -eq $null }).Count
            failed = ($completedTasks | Where-Object { $_.error }).Count
            cancelled = ($completedTasks | Where-Object { $_.status -eq "cancelled" }).Count
        }

        byPriority = @{}
    }

    foreach ($priority in $concurrencyConfig.priorityLevels) {
        $stats.byPriority[$priority] = $taskQueue | Where-Object { $_.priority -eq $priority } | Measure-Object | Select-Object -ExpandProperty Count
    }

    return $stats
}

# 命令行接口
function Show-Usage {
    Write-Host @"
Usage:
  Initialize-ThreadPool -Size 10

  New-Task -ScriptBlock { ... } -Name "task1" -Priority "high"
  New-Task -ScriptBlock { ... } -Name "task2"

  Add-TaskToQueue -Task $task

  Get-NextTask -MaxConcurrent 10

  Invoke-TasksInParallel -Tasks @($tasks) -MaxConcurrent 5

  Start-TaskScheduler -TaskProvider { ... } -Interval 60000

  Cancel-Task -TaskId "guid"

  Get-QueueStats
  Get-TaskStats

Examples:
  $task = New-Task -ScriptBlock { param($x) return $x * 2 } -Name "double" -Priority "high"
  $task.Parameters = @{x = 5}
  Invoke-TaskInParallel -Tasks @($task)
"@
}

# 默认执行
if ($args.Count -gt 0) {
    $cmd = $args[0]

    switch ($cmd) {
        "init" {
            $size = if ($args.Count -gt 1) { [int]$args[1] } else { 10 }
            Initialize-ThreadPool -Size $size
        }
        "new" {
            Write-Host "Create task with: New-Task -ScriptBlock { ... } -Name ..."
        }
        "queue" {
            Write-Host "Tasks in queue: $(Get-QueueStats.queued)"
        }
        "stats" {
            $stats = Get-TaskStats
            Write-Host "=== Task Statistics ===" -ForegroundColor Cyan
            Write-Host "Queued: $($stats.totalQueued)" -ForegroundColor White
            Write-Host "Running: $($stats.totalRunning)" -ForegroundColor White
            Write-Host "Completed: $($stats.totalCompleted)" -ForegroundColor White
            Write-Host "Failed: $($stats.totalFailed)" -ForegroundColor Red
        }
        default {
            Show-Usage
        }
    }
}
