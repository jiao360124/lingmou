# Concurrency Optimizer - 并发处理优化
# 优化并发性能，提高任务处理效率

param(
    [Parameter(Mandatory=$false)]
    [string]$Action = "test"
)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$dataPath = Join-Path $scriptPath "..\data"

# Concurrency statistics
$ConcurrencyStats = @{
    totalTasks = 0
    completedTasks = 0
    failedTasks = 0
    queuedTasks = 0
    parallelBatches = 0
    averageQueueTime = 0
    maxQueueTime = 0
    averageProcessTime = 0
    throughput = 0
}

# Task queue
$TaskQueue = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
$TaskQueueLock = [System.Object]::new()
$ActiveTasks = [System.Collections.Concurrent.ConcurrentBag[string]]::new()
$TaskResults = [System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()

# Concurrency configuration
$ConcurrencyConfig = @{
    maxConcurrency = 4        # Maximum concurrent tasks
    batchProcessor = 5        # Batch processing size
    queueTimeout = 30000      # Queue timeout in ms
    backoffStrategy = "exponential"  # Backoff strategy
}

# Performance metrics
$PerformanceMetrics = @{
    totalTaskTime = 0
    totalQueueTime = 0
    startTimestamp = $null
    peakConcurrentTasks = 0
}

# Initialize
function Initialize-ConcurrencyOptimization {
    param(
        [Parameter(Mandatory=$false)]
        [bool]$Reset = $false
    )

    if ($Reset) {
        $ConcurrencyStats = @{
            totalTasks = 0
            completedTasks = 0
            failedTasks = 0
            queuedTasks = 0
            parallelBatches = 0
            averageQueueTime = 0
            maxQueueTime = 0
            averageProcessTime = 0
            throughput = 0
        }
        $PerformanceMetrics = @{
            totalTaskTime = 0
            totalQueueTime = 0
            startTimestamp = $null
            peakConcurrentTasks = 0
        }
    }

    Write-Host "Concurrency optimization initialized" -ForegroundColor Green
}

# Submit task to queue
function Submit-Task {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskId,
        [Parameter(Mandatory=$true)]
        [scriptblock]$Task,
        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters = @{}
    )

    $queuedTime = (Get-Date)

    $taskWrapper = @{
        id = $TaskId
        task = $Task
        parameters = $Parameters
        queuedTime = $queuedTime
        startTime = $null
        endTime = $null
        status = "queued"
    }

    $TaskQueue.Enqueue($taskWrapper)
    $ConcurrencyStats.queuedTasks++
    $ConcurrencyStats.totalTasks++
    $ConcurrencyStats.startTimestamp = (Get-Date) -?? $ConcurrencyStats.startTimestamp

    Write-Host "Task submitted: $TaskId" -ForegroundColor Green

    return $TaskId
}

# Execute single task
function Invoke-SingleTask {
    param(
        [Parameter(Mandatory=$true)]
        [object]$TaskWrapper
    )

    $TaskWrapper.status = "running"
    $TaskWrapper.startTime = Get-Date

    try {
        Write-Host "  Executing: $($TaskWrapper.id)" -ForegroundColor Yellow

        # Execute task
        $result = & $TaskWrapper.task @TaskWrapper.parameters
        $TaskWrapper.result = $result
        $TaskWrapper.status = "completed"
        $ConcurrencyStats.completedTasks++
    } catch {
        Write-Host "  Failed: $($TaskWrapper.id) - $($_.Exception.Message)" -ForegroundColor Red
        $TaskWrapper.status = "failed"
        $TaskWrapper.error = $_.Exception.Message
        $ConcurrencyStats.failedTasks++
    } finally {
        $TaskWrapper.endTime = Get-Date
    }

    return $TaskWrapper
}

# Process batch of tasks
function Process-Batch {
    param(
        [Parameter(Mandatory=$true)]
        [int]$BatchSize = $ConcurrencyConfig.batchProcessor
    )

    $batch = [System.Collections.Generic.List[object]]::new()

    # Get tasks from queue
    for ($i = 0; $i -lt $BatchSize; $i++) {
        if ($TaskQueue.TryDequeue([ref]$task)) {
            $batch.Add($task)
            $ConcurrencyStats.queuedTasks--
        } else {
            break
        }
    }

    if ($batch.Count -eq 0) {
        return
    }

    $ConcurrencyStats.parallelBatches++
    $startTime = Get-Date

    Write-Host "`n  Processing batch of $($batch.Count) tasks..." -ForegroundColor Cyan

    # Execute batch
    $results = @()
    foreach ($taskWrapper in $batch) {
        Invoke-SingleTask -TaskWrapper $taskWrapper
        $results += $taskWrapper
    }

    # Calculate performance metrics
    $elapsed = (Get-Date) - $startTime
    $ProcessingTime = [math]::Round($elapsed.TotalMilliseconds, 2)

    # Store results
    foreach ($result in $results) {
        $TaskResults.TryAdd($result.id, $result)
        $PerformanceMetrics.totalTaskTime += $elapsed.TotalMilliseconds
    }

    Write-Host "  Batch completed in $ProcessingTime ms" -ForegroundColor Green
}

# Worker thread
function Start-WorkerThread {
    param(
        [Parameter(Mandatory=$false)]
        [int]$WorkerId
    )

    while ($true) {
        if ($TaskQueue.Count -eq 0) {
            Start-Sleep -Milliseconds 10
            continue
        }

        # Check max concurrency
        if ($ActiveTasks.Count -ge $ConcurrencyConfig.maxConcurrency) {
            Start-Sleep -Milliseconds 100
            continue
        }

        # Process batch
        Process-Batch -BatchSize 1
    }
}

# Start worker threads
$WorkerThreads = [System.Collections.Generic.List[object]]::new()

function Start-WorkerPool {
    param(
        [Parameter(Mandatory=$false)]
        [int]$PoolSize = $ConcurrencyConfig.maxConcurrency
    )

    for ($i = 0; $i -lt $PoolSize; $i++) {
        $thread = New-Thread -ThreadStart {
            param($workerId)
            while ($true) {
                Start-Sleep -Milliseconds 10

                if ($TaskQueue.Count -eq 0) {
                    continue
                }

                if ($ActiveTasks.Count -ge $ConcurrencyConfig.maxConcurrency) {
                    continue
                }

                Process-Batch -BatchSize 1
            }
        }
        $thread.Start($i)
        $WorkerThreads.Add($thread)
        Write-Host "Worker thread started: $i" -ForegroundColor Green
    }
}

# Wait for all tasks to complete
function Wait-AllTasks {
    param(
        [Parameter(Mandatory=$false)]
        [int]$TimeoutMs = 60000
    )

    Write-Host "Waiting for all tasks to complete..." -ForegroundColor Yellow

    $startTime = Get-Date
    while ($TaskQueue.Count -gt 0 -or $ActiveTasks.Count -gt 0) {
        $elapsed = (Get-Date) - $startTime
        if ($elapsed.TotalMilliseconds -gt $TimeoutMs) {
            Write-Host "Timeout waiting for tasks" -ForegroundColor Red
            break
        }
        Start-Sleep -Milliseconds 100
    }

    Write-Host "All tasks completed" -ForegroundColor Green
}

# Get concurrency statistics
function Get-ConcurrencyStats {
    $totalTasks = $ConcurrencyStats.totalTasks
    $completed = $ConcurrencyStats.completedTasks
    $failed = $ConcurrencyStats.failedTasks
    $queued = $ConcurrencyStats.queuedTasks
    $throughput = 0

    if ($ConcurrencyStats.totalTasks -gt 0) {
        $throughput = [math]::Round(($completed / $ConcurrencyStats.totalTasks) * 100, 2)
    }

    $avgProcessTime = 0
    if ($ConcurrencyStats.completedTasks -gt 0) {
        $avgProcessTime = [math]::Round($PerformanceMetrics.totalTaskTime / $ConcurrencyStats.completedTasks, 2)
    }

    Write-Host "`n=== Concurrency Statistics ===" -ForegroundColor Cyan
    Write-Host "Total Tasks: $totalTasks" -ForegroundColor Yellow
    Write-Host "Completed: $completed ($throughput%)" -ForegroundColor Green
    Write-Host "Failed: $failed" -ForegroundColor Red
    Write-Host "Queued: $queued" -ForegroundColor Gray
    Write-Host "Active Tasks: $($ActiveTasks.Count)" -ForegroundColor Yellow
    Write-Host "Parallel Batches: $($ConcurrencyStats.parallelBatches)" -ForegroundColor Gray
    Write-Host "Average Process Time: $avgProcessTime ms" -ForegroundColor Gray
    Write-Host "Worker Threads: $($WorkerThreads.Count)" -ForegroundColor Green

    return @{
        totalTasks = $totalTasks
        completed = $completed
        failed = $failed
        queued = $queued
        throughput = $throughput
        activeTasks = $ActiveTasks.Count
        batches = $ConcurrencyStats.parallelBatches
        avgProcessTime = $avgProcessTime
        workerThreads = $WorkerThreads.Count
    }
}

# Task generator for testing
function Get-TestTask {
    param(
        [Parameter(Mandatory=$true)]
        [int]$DelayMs
    )

    return {
        param($taskDelay)
        Start-Sleep -Milliseconds $taskDelay
        return @{
            task = "Test Task"
            completed = $true
            duration = $taskDelay
        }
    }
}

# Action handlers
switch ($Action) {
    "test" {
        Initialize-ConcurrencyOptimization -Reset $true

        Write-Host "`n[1] Initialize worker pool" -ForegroundColor Yellow
        Start-WorkerPool -PoolSize 2

        Write-Host "`n[2] Submit test tasks" -ForegroundColor Yellow
        $taskIds = @()
        for ($i = 0; $i -lt 10; $i++) {
            $taskId = "test-task-$i"
            $taskIds += Submit-Task -TaskId $taskId -Task {
                param($delay)
                Start-Sleep -Milliseconds $delay
                Write-Host "    Task $taskId completed" -ForegroundColor Green
                return @{ id = $taskId; status = "success" }
            } -Parameters @{ delay = ($i * 100) }

            Start-Sleep -Milliseconds 10
        }

        Write-Host "`n[3] Wait for tasks" -ForegroundColor Yellow
        Wait-AllTasks -TimeoutMs 5000

        Write-Host "`n[4] Get statistics" -ForegroundColor Yellow
        Get-ConcurrencyStats

        Write-Host "`n[5] Performance metrics" -ForegroundColor Yellow
        $stats = Get-ConcurrencyStats
        Write-Host "  Throughput: $([math]::Round($stats.throughput, 2))%" -ForegroundColor Green
        Write-Host "  Avg Process Time: $($stats.avgProcessTime) ms" -ForegroundColor Gray

        Write-Host "`n=== Concurrency Optimizer Test Complete ===" -ForegroundColor Cyan
    }

    "stats" {
        Get-ConcurrencyStats
    }

    "benchmark" {
        Initialize-ConcurrencyOptimization -Reset $true
        Start-WorkerPool -PoolSize 3

        Write-Host "`n=== Concurrency Benchmark ===" -ForegroundColor Cyan
        Write-Host "Testing with 100 tasks..." -ForegroundColor Yellow

        $testTasks = 100
        $totalDelay = 0
        $startTime = Get-Date

        for ($i = 0; $i -lt $testTasks; $i++) {
            $delay = (Get-Random -Minimum 10 -Maximum 100)
            $totalDelay += $delay

            Submit-Task -TaskId "benchmark-task-$i" -Task {
                param($taskDelay)
                Start-Sleep -Milliseconds $taskDelay
                return @{ status = "success", duration = $taskDelay }
            } -Parameters @{ delay = $delay }
        }

        Wait-AllTasks -TimeoutMs 30000
        $endTime = Get-Date

        $elapsed = $endTime - $startTime
        $completed = $ConcurrencyStats.completedTasks
        $throughput = [math]::Round($completed / $elapsed.TotalSeconds, 2)

        Write-Host "`n=== Benchmark Results ===" -ForegroundColor Cyan
        Write-Host "Total Tasks: $testTasks" -ForegroundColor Yellow
        Write-Host "Completed: $completed" -ForegroundColor Green
        Write-Host "Throughput: $throughput tasks/sec" -ForegroundColor Green
        Write-Host "Total Time: $([math]::Round($elapsed.TotalSeconds, 2)) seconds" -ForegroundColor Gray
        Write-Host "Average Delay: $([math]::Round($totalDelay / $testTasks, 2)) ms" -ForegroundColor Gray

        Get-ConcurrencyStats
    }

    "help" {
        Write-Host "`n使用方法:" -ForegroundColor Yellow
        Write-Host "  test - 运行测试"
        Write-Host "  stats - 显示统计信息"
        Write-Host "  benchmark - 性能基准测试"
        Write-Host "  help - 显示帮助"
    }

    "default" {
        Write-Host "使用方法: concurrency-optimizer.ps1 -Action <action>" -ForegroundColor Yellow
        Write-Host "`n可用操作:" -ForegroundColor Cyan
        Write-Host "  test - 测试并发功能"
        Write-Host "  stats - 查看统计"
        Write-Host "  benchmark - 基准测试"
        Write-Host "  help - 显示帮助"
    }
}

Initialize-ConcurrencyOptimization -Reset $true
