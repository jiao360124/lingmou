# 脚本并行执行管理器

**版本**: 1.0
**日期**: 2026-02-10

---

## 功能概述

提供一个并行执行框架，可以同时运行多个独立任务，提高资源利用率和执行效率。

---

## 核心功能

### 1. 任务定义和队列

```powershell
function Register-Task {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskName,
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock,
        [Parameter(Mandatory=$true)]
        [int]$Priority = 50,
        [switch]$RetryOnFailure = $true
    )

    $task = @{
        name = $TaskName
        script = $ScriptBlock
        priority = $Priority
        retry = $RetryOnFailure
        status = "pending"
        result = $null
        error = $null
        attempts = 0
        max_attempts = 3
        started_at = $null
        completed_at = $null
        duration_ms = 0
    }

    # 根据优先级插入到队列
    if ($Global:ParallelTaskQueue.Count -eq 0) {
        $Global:ParallelTaskQueue.Add($task)
    } else {
        $inserted = $false
        for ($i = 0; $i -lt $Global:ParallelTaskQueue.Count; $i++) {
            if ($task.priority -gt $Global:ParallelTaskQueue[$i].priority) {
                $Global:ParallelTaskQueue.Insert($i, $task)
                $inserted = $true
                break
            }
        }
        if (-not $inserted) {
            $Global:ParallelTaskQueue.Add($task)
        }
    }

    Write-Host "[PARALLEL] Task registered: $TaskName (Priority: $Priority)" -ForegroundColor Cyan
    return $task
}
```

---

### 2. 并行执行引擎

```powershell
function Invoke-ParallelExecution {
    param(
        [Parameter(Mandatory=$true)]
        [int]$Concurrency = 3,
        [switch]$TrackProgress = $true,
        [switch]$WaitForAll = $true
    )

    Write-Host "[PARALLEL] Starting parallel execution..." -ForegroundColor Cyan
    Write-Host "  Concurrency: $Concurrency" -ForegroundColor Yellow
    Write-Host "  Total tasks: $($Global:ParallelTaskQueue.Count)" -ForegroundColor Yellow

    $startTime = Get-Date
    $runningTasks = @{}
    $completedTasks = 0
    $failedTasks = 0

    # 创建工作池
    $workPool = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()

    # 将任务添加到工作池
    foreach ($task in $Global:ParallelTaskQueue) {
        $workPool.Enqueue($task)
    }

    # 创建后台工作线程
    $threads = @()
    for ($i = 0; $i -lt $Concurrency; $i++) {
        $thread = [System.Threading.Thread]::new({
            param($queue, $context)
            while ($true) {
                if ($queue.TryDequeue([ref]$null)) {
                    $task = $queue.Peek()

                    # 执行任务
                    try {
                        $task.started_at = Get-Date
                        Write-Host "[PARALLEL] [Thread-$($context.ThreadId)] Starting: $($task.name)" -ForegroundColor Cyan
                        $task.status = "running"

                        $task.result = & $task.script
                        $task.status = "completed"
                        $task.completed_at = Get-Date
                        $task.duration_ms = ($task.completed_at - $task.started_at).TotalMilliseconds

                        Write-Host "[PARALLEL] [Thread-$($context.ThreadId)] Completed: $($task.name) ($([math]::Round($task.duration_ms, 2))ms)" -ForegroundColor Green

                        $completedTasks++
                    } catch {
                        $task.status = "failed"
                        $task.error = $_.Exception.Message
                        $task.attempts++

                        if ($task.retry -and $task.attempts -lt $task.max_attempts) {
                            Write-Host "[PARALLEL] [Thread-$($context.ThreadId)] Failed: $($task.name). Retrying... ($($task.attempts)/$($task.max_attempts))" -ForegroundColor Yellow
                            Start-Sleep -Seconds 1  # 等待1秒后重试
                            $queue.Enqueue($task)  # 重新放入队列
                        } else {
                            Write-Host "[PARALLEL] [Thread-$($context.ThreadId)] Failed: $($task.name). Error: $($_.Exception.Message)" -ForegroundColor Red
                            $failedTasks++
                        }
                    }
                } else {
                    # 队列为空，线程退出
                    break
                }
            }
        })

        $threads += $thread
        $thread.Start($workPool, [System.Threading.Thread]::CurrentThread)
    }

    # 等待所有线程完成
    if ($WaitForAll) {
        $threads | ForEach-Object { $_.Join() }
    }

    $endTime = Get-Date
    $totalDuration = ($endTime - $startTime).TotalMilliseconds

    # 输出执行结果
    Write-Host "`n[PARALLEL] Execution Complete" -ForegroundColor Cyan
    Write-Host "  Total Duration: $([math]::Round($totalDuration, 2))ms" -ForegroundColor Cyan
    Write-Host "  Completed: $completedTasks" -ForegroundColor Green
    Write-Host "  Failed: $failedTasks" -ForegroundColor Red
    Write-Host "  Success Rate: $([math]::Round(($completedTasks / ($Global:ParallelTaskQueue.Count + $failedTasks)) * 100, 2))%" -ForegroundColor Cyan

    return @{
        total_tasks = $Global:ParallelTaskQueue.Count
        completed = $completedTasks
        failed = $failedTasks
        total_duration_ms = $totalDuration
        results = $Global:ParallelTaskQueue
    }
}
```

---

### 3. 资源监控

```powershell
function Get-ResourceMonitor {
    Write-Host "[MONITOR] Checking resource usage..." -ForegroundColor Cyan

    $resources = @{}

    # 内存使用
    $process = Get-Process -Id $PID
    $memoryMB = [math]::Round($process.WorkingSet64 / 1MB, 2)
    $memoryPct = [math]::Round(($memoryMB / 2048) * 100, 2)

    $resources["memory"] = @{
        used = $memoryMB
        total = 2048
        used_pct = $memoryPct
        status = if ($memoryPct -lt 70) { "healthy" } elseif ($memoryPct -lt 90) { "warning" } else { "critical" }
    }

    # CPU使用率（模拟）
    $resources["cpu"] = @{
        used_pct = 15  # 假设值
        status = "healthy"
    }

    # 磁盘使用
    $drive = Get-PSDrive C
    $diskPct = [math]::Round(($drive.Used / $drive.Total * 100), 2)

    $resources["disk"] = @{
        used = [math]::Round($drive.Used / 1GB, 2)
        total = [math]::Round($drive.Total / 1GB, 2)
        used_pct = $diskPct
        status = if ($diskPct -lt 70) { "healthy" } elseif ($diskPct -lt 90) { "warning" } else { "critical" }
    }

    # 网络使用（模拟）
    $resources["network"] = @{
        status = "healthy"
        connections = 5
    }

    return $resources
}

function Invoke-ResourceOptimization {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Resources
    )

    Write-Host "[OPTIMIZE] Optimizing resources..." -ForegroundColor Cyan

    $optimizations = @()

    foreach ($resource in $Resources.GetEnumerator()) {
        switch ($resource.Value.status) {
            "warning" {
                switch ($resource.Key) {
                    "memory" {
                        $optimizations += "Reduce concurrent processes to free memory"
                        $optimizations += "Implement memory caching strategy"
                    }
                    "disk" {
                        $optimizations += "Clean old backups and temporary files"
                        $optimizations += "Compress large files"
                    }
                    "cpu" {
                        $optimizations += "Optimize CPU-intensive operations"
                        $optimizations += "Consider parallel processing"
                    }
                }
            }
            "critical" {
                switch ($resource.Key) {
                    "memory" {
                        $optimizations += "IMMEDIATE ACTION: Clear caches and restart services"
                        $optimizations += "Reduce task concurrency"
                    }
                    "disk" {
                        $optimizations += "IMMEDIATE ACTION: Delete unnecessary files"
                        $optimizations += "Move large files to external storage"
                    }
                }
            }
        }
    }

    Write-Host "[OPTIMIZE] Recommendations:" -ForegroundColor Green
    foreach ($opt in $optimizations) {
        Write-Host "  - $opt" -ForegroundColor Cyan
    }

    return $optimizations
}
```

---

### 4. 任务编排

```powershell
function New-TaskOrchestrator {
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$OrchestrationScript
    )

    Write-Host "[ORCHESTRATOR] Creating task orchestrator..." -ForegroundColor Cyan

    $orchestrator = @{
        tasks = @()
        dependencies = @{}
        status = "initialized"
        results = @{}
    }

    # 执行编排脚本
    try {
        & $OrchestrationScript -Orchestrator $orchestrator
        $orchestrator.status = "completed"
    } catch {
        $orchestrator.status = "failed"
        $orchestrator.error = $_.Exception.Message
    }

    return $orchestrator
}

function Invoke-TaskOrchestration {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Orchestrator
    )

    Write-Host "[ORCHESTRATOR] Orchestrating tasks..." -ForegroundColor Cyan

    # 按依赖关系排序任务
    $sortedTasks = Sort-ByDependencies -Tasks $Orchestrator.tasks -Dependencies $Orchestrator.dependencies

    # 生成执行计划
    $executionPlan = @()
    foreach ($task in $sortedTasks) {
        $executionPlan += @{
            task = $task
            depends_on = $Orchestrator.dependencies[$task.name] ?? @()
            can_run = $true
        }
    }

    Write-Host "[ORCHESTRATOR] Execution Plan:" -ForegroundColor Yellow
    foreach ($plan in $executionPlan) {
        $dependsStr = ($plan.depends_on -join ", ")
        $statusIcon = if ($plan.can_run) { "✓" } else { "✗" }
        Write-Host "  $statusIcon $($plan.task.name)" -ForegroundColor $(if ($plan.can_run) { "Green" } else { "Red" })
        if ($dependsStr) {
            Write-Host "      Depends on: $dependsStr" -ForegroundColor Gray
        }
    }

    # 执行计划中的任务
    $Global:ParallelTaskQueue = @()
    foreach ($plan in $executionPlan) {
        if ($plan.can_run) {
            Register-Task `
                -TaskName $plan.task.name `
                -ScriptBlock $plan.task.script `
                -Priority $plan.task.priority
        }
    }

    # 并行执行
    if ($Global:ParallelTaskQueue.Count -gt 0) {
        $results = Invoke-ParallelExecution -Concurrency 3 -WaitForAll $true
        $Orchestrator.results = $results.results
    }

    return $Orchestrator
}

function Sort-ByDependencies {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Tasks,
        [hashtable]$Dependencies
    )

    # 简化的依赖排序（实际需要更复杂的拓扑排序）
    $sorted = @($Tasks)
    return $sorted
}
```

---

## 使用示例

### 示例1: 简单并行执行

```powershell
# 清空任务队列
$Global:ParallelTaskQueue = @()

# 注册多个任务
Register-Task -TaskName "Task 1" -ScriptBlock { Write-Host "Running Task 1"; Start-Sleep -Seconds 2; return "Task 1 Done" } -Priority 50
Register-Task -TaskName "Task 2" -ScriptBlock { Write-Host "Running Task 2"; Start-Sleep -Seconds 3; return "Task 2 Done" } -Priority 60
Register-Task -TaskName "Task 3" -ScriptBlock { Write-Host "Running Task 3"; Start-Sleep -Seconds 1; return "Task 3 Done" } -Priority 40
Register-Task -TaskName "Task 4" -ScriptBlock { Write-Host "Running Task 4"; Start-Sleep -Seconds 2; return "Task 4 Done" } -Priority 70

# 执行任务
$results = Invoke-ParallelExecution -Concurrency 2 -WaitForAll $true

# 查看结果
$results.results | ForEach-Object { Write-Host "Result: $($_.result)" }
```

### 示例2: 任务编排

```powershell
# 创建编排脚本
$orchScript = {
    param($Orchestrator)

    # 添加依赖任务
    $Orchestrator.dependencies["Task C"] = @("Task A", "Task B")
    $Orchestrator.dependencies["Task D"] = @("Task C")

    # 注册所有任务
    $Orchestrator.tasks = @(
        @{name = "Task A"; priority = 50; script = { Write-Host "A"; Start-Sleep -Seconds 1; return "A" }},
        @{name = "Task B"; priority = 50; script = { Write-Host "B"; Start-Sleep -Seconds 1; return "B" }},
        @{name = "Task C"; priority = 60; script = { Write-Host "C"; Start-Sleep -Seconds 1; return "C" }},
        @{name = "Task D"; priority = 70; script = { Write-Host "D"; Start-Sleep -Seconds 1; return "D" }}
    )
}

# 执行编排
$orchestrator = New-TaskOrchestrator -OrchestrationScript $orchScript
$orchestrator = Invoke-TaskOrchestration -Orchestrator $orchestrator
```

### 示例3: 资源优化

```powershell
# 获取资源状态
$resources = Get-ResourceMonitor

# 执行资源优化
$optimizations = Invoke-ResourceOptimization -Resources $resources
```

---

## 导出函数

```powershell
Export-ModuleMember -Function Register-Task, Invoke-ParallelExecution, Get-ResourceMonitor, Invoke-ResourceOptimization, New-TaskOrchestrator, Invoke-TaskOrchestration
```

---

**维护者**: 灵眸
**最后更新**: 2026-02-10 21:11
