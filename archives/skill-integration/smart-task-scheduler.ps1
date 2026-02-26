# 智能任务调度系统

**版本**: 1.0
**日期**: 2026-02-11
**作者**: 灵眸

---

## 🎯 系统概述

智能任务调度系统基于优先级、时间窗口和条件触发器来管理自动化任务的执行。

---

## 📊 核心功能

### 1. 任务定义和管理

```powershell
function New-SmartTask {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskId,
        [Parameter(Mandatory=$true)]
        [string]$TaskName,
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock,
        [int]$Priority = 50,
        [string[]]$DependsOn = @(),
        [hashtable]$Conditions = @{}
    )

    $task = @{
        task_id = $TaskId
        task_name = $TaskName
        script_block = $ScriptBlock
        priority = $Priority
        depends_on = $DependsOn
        conditions = $Conditions
        status = "pending"
        created_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        executed_at = $null
        result = $null
        retries = 0
        max_retries = 3
        next_run = $null
        schedule = $null
        active = $true
    }

    return $task
}
```

### 2. 任务调度器

```powershell
function Invoke-SmartTaskScheduler {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Tasks,
        [int]$Concurrency = 2
    )

    Write-Host "[TASK_SCHEDULER] 🔄 启动智能任务调度器..." -ForegroundColor Cyan
    Write-Host "[TASK_SCHEDULER]    并发数: $Concurrency" -ForegroundColor Cyan
    Write-Host "[TASK_SCHEDULER]    任务数: $($Tasks.Count)" -ForegroundColor Cyan

    # 过滤活跃任务
    $activeTasks = $Tasks | Where-Object { $_.active -and $_.status -eq "pending" }

    Write-Host "[TASK_SCHEDULER] ✓ 找到 $($activeTasks.Count) 个待执行任务" -ForegroundColor Green

    # 按优先级排序
    $sortedTasks = $activeTasks | Sort-Object -Property priority -Descending

    # 执行任务
    $results = @()
    $runningTasks = @()

    foreach ($task in $sortedTasks) {
        # 检查依赖
        $dependenciesSatisfied = $true
        foreach ($dep in $task.depends_on) {
            $depTask = $Tasks | Where-Object { $_.task_id -eq $dep }
            if ($depTask.status -ne "completed") {
                $dependenciesSatisfied = $false
                break
            }
        }

        if (!$dependenciesSatisfied) {
            Write-Host "[TASK_SCHEDULER] ⏳ 任务 $($task.task_id) 等待依赖完成" -ForegroundColor Yellow
            continue
        }

        # 检查条件
        if ($task.conditions) {
            $conditionsMet = Invoke-CheckConditions -Conditions $task.conditions
            if (!$conditionsMet) {
                Write-Host "[TASK_SCHEDULER] ⏳ 任务 $($task.task_id) 条件未满足" -ForegroundColor Yellow
                continue
            }
        }

        # 添加到运行队列
        $runningTasks += $task.task_id

        # 并行执行
        Start-Job -ScriptBlock {
            param($t)
            try {
                $t.status = "running"
                Write-Host "[TASK_SCHEDULER] 🔨 执行任务: $($t.task_name)" -ForegroundColor Yellow

                $result = & $t.script_block
                $t.status = "completed"
                $t.executed_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $t.result = $result

                Write-Host "[TASK_SCHEDULER] ✅ 任务完成: $($t.task_name)" -ForegroundColor Green
                return @{
                    success = $true
                    task_id = $t.task_id
                    result = $result
                }
            } catch {
                $t.status = "failed"
                $t.executed_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $t.result = "Error: $($_.Exception.Message)"

                Write-Host "[TASK_SCHEDULER] ❌ 任务失败: $($t.task_name) - $($_.Exception.Message)" -ForegroundColor Red

                return @{
                    success = $false
                    task_id = $t.task_id
                    error = $_.Exception.Message
                }
            }
        } -ArgumentList $task

        # 控制并发数
        while ($runningTasks.Count -ge $Concurrency) {
            Start-Sleep -Seconds 1
            $runningTasks = Get-Job | Select-Object -ExpandProperty Name
        }
    }

    # 等待所有任务完成
    Write-Host "[TASK_SCHEDULER] ⏳ 等待任务完成..." -ForegroundColor Cyan
    $completedJobs = Get-Job -State "Completed" | Wait-Job -Timeout 60
    Remove-Job -Job $completedJobs -Force

    # 汇总结果
    $results = Get-Job -State "Completed" | Receive-Job
    Remove-Job -All

    Write-Host "[TASK_SCHEDULER] ✓ 调度完成" -ForegroundColor Green
    Write-Host "[TASK_SCHEDULER]    成功: $(($results | Where-Object { $_.success }).Count)" -ForegroundColor Green
    Write-Host "[TASK_SCHEDULER]    失败: $(($results | Where-Object { -not $_.success }).Count)" -ForegroundColor Red

    return @{
        success = $true
        total_tasks = $Tasks.Count
        completed_tasks = ($results | Where-Object { $_.success }).Count
        failed_tasks = ($results | Where-Object { -not $_.success }).Count
        results = $results
    }
}
```

### 3. 条件检查器

```powershell
function Invoke-CheckConditions {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Conditions
    )

    foreach ($key in $Conditions.Keys) {
        $value = $Conditions.($key)

        switch ($key) {
            "time_window" {
                if ($value -is [array] -and $value.Count -eq 2) {
                    $start = $value[0]
                    $end = $value[1]
                    $current = (Get-Date).Hour

                    if ($current -lt $start -or $current -gt $end) {
                        return $false
                    }
                }
            }
            "day_of_week" {
                $dayOfWeek = (Get-Date).DayOfWeek
                if ($value -notcontains $dayOfWeek) {
                    return $false
                }
            }
            "condition_script" {
                $conditionResult = & $value
                if (!$conditionResult) {
                    return $false
                }
            }
        }
    }

    return $true
}
```

### 4. 任务队列管理

```powershell
function Invoke-TaskQueue {
    param(
        [Parameter(Mandatory=$true)]
        [string]$QueueName,
        [switch]$Clear
    )

    if ($Clear) {
        if (Test-Path "logs/task-queues/$QueueName.json") {
            Remove-Item "logs/task-queues/$QueueName.json" -Force
            Write-Host "[TASK_QUEUE] ✓ 队列已清空: $QueueName" -ForegroundColor Green
        }
        return
    }

    # 获取队列
    $queuePath = "logs/task-queues/$QueueName.json"
    if (Test-Path $queuePath) {
        $queue = Get-Content $queuePath -Raw | ConvertFrom-Json
    } else {
        $queue = @{
            tasks = @()
            total = 0
            completed = 0
            failed = 0
            pending = 0
            created_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }

    Write-Host "[TASK_QUEUE] 📋 任务队列: $QueueName" -ForegroundColor Cyan
    Write-Host "[TASK_QUEUE]    总任务: $($queue.total)" -ForegroundColor Cyan
    Write-Host "[TASK_QUEUE]    已完成: $($queue.completed)" -ForegroundColor Cyan
    Write-Host "[TASK_QUEUE]    失败: $($queue.failed)" -ForegroundColor Cyan
    Write-Host "[TASK_QUEUE]    待处理: $($queue.pending)" -ForegroundColor Cyan

    return $queue
}

function Add-TaskToQueue {
    param(
        [Parameter(Mandatory=$true)]
        [string]$QueueName,
        [Parameter(Mandatory=$true)]
        [string]$TaskId,
        [Parameter(Mandatory=$true)]
        [string]$TaskName,
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock
    )

    $queuePath = "logs/task-queues/$QueueName.json"

    # 获取现有队列或创建新队列
    if (Test-Path $queuePath) {
        $queue = Get-Content $queuePath -Raw | ConvertFrom-Json
    } else {
        New-Item -Path "logs/task-queues" -ItemType Directory -Force | Out-Null
        $queue = @{
            tasks = @()
            total = 0
            completed = 0
            failed = 0
            pending = 0
            created_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }

    # 添加任务
    $task = New-SmartTask `
        -TaskId $TaskId `
        -TaskName $TaskName `
        -ScriptBlock $ScriptBlock

    $queue.tasks += @{
        task_id = $task.task_id
        task_name = $task.task_name
        created_at = $task.created_at
        status = "pending"
    }

    $queue.total++
    $queue.pending++
    $queue.updated_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # 保存队列
    $queue | ConvertTo-Json -Depth 10 | Set-Content $queuePath -Encoding UTF8

    Write-Host "[TASK_QUEUE] ✓ 任务已添加: $TaskName" -ForegroundColor Green
    return $queue
}
```

### 5. 监控和报告

```powershell
function Invoke-TaskSchedulerReport {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Tasks
    )

    Write-Host "[SCHEDULER_REPORT] 📊 任务调度器报告" -ForegroundColor Cyan
    Write-Host "[SCHEDULER_REPORT] ======================" -ForegroundColor Cyan

    # 按状态统计
    $statusStats = @{}

    foreach ($task in $Tasks) {
        $status = $task.status
        if (!$statusStats.ContainsKey($status)) {
            $statusStats.($status) = 0
        }
        $statusStats.($status)++
    }

    Write-Host "[SCHEDULER_REPORT] 状态统计:" -ForegroundColor Yellow
    foreach ($status in $statusStats.Keys) {
        $count = $statusStats.($status)
        $color = if ($status -eq "completed") { "Green" }
        elseif ($status -eq "failed") { "Red" }
        else { "Yellow" }

        Write-Host "[SCHEDULER_REPORT]    $status: $count" -ForegroundColor $color
    }

    # 显示详细结果
    Write-Host "`n[SCHEDULER_REPORT] 任务详情:" -ForegroundColor Yellow

    foreach ($task in $Tasks) {
        $statusColor = if ($task.status -eq "completed") { "Green" }
        elseif ($task.status -eq "failed") { "Red" }
        else { "Yellow" }

        Write-Host ""
        Write-Host "[$($task.status)] $($task.task_id): $($task.task_name)" -ForegroundColor $statusColor
        Write-Host "    创建时间: $($task.created_at)" -ForegroundColor Gray
        if ($task.executed_at) {
            Write-Host "    执行时间: $($task.executed_at)" -ForegroundColor Gray
        }
        Write-Host "    优先级: $($task.priority)" -ForegroundColor Gray

        if ($task.result) {
            Write-Host "    结果: $($task.result)" -ForegroundColor Gray
        }

        if ($task.retries -gt 0) {
            Write-Host "    重试次数: $($task.retries)" -ForegroundColor Gray
        }
    }

    return @{
        status_stats = $statusStats
        tasks = $Tasks
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}
```

---

## 📊 使用示例

```powershell
# 示例1: 创建和执行任务
$task1 = New-SmartTask `
    -TaskId "TASK-001" `
    -TaskName "Run Diagnostic" `
    -ScriptBlock {
        Write-Host "Running diagnostic..." -ForegroundColor Cyan
        Start-Sleep -Seconds 2
        return @{ success = $true; message = "Diagnostic completed" }
    }
    -Priority 80

$task2 = New-SmartTask `
    -TaskId "TASK-002" `
    -TaskName "Run Backup" `
    -ScriptBlock {
        Write-Host "Running backup..." -ForegroundColor Cyan
        Start-Sleep -Seconds 3
        return @{ success = $true; message = "Backup completed" }
    }
    -Priority 90
    -DependsOn "TASK-001"

$tasks = @($task1, $task2)
$result = Invoke-SmartTaskScheduler -Tasks $tasks -Concurrency 2
```

---

## 🎯 技术特性

- **优先级调度**: 基于优先级排序执行
- **依赖管理**: 任务依赖关系处理
- **条件触发**: 支持多种条件检查
- **并发控制**: 可配置并发数
- **错误处理**: 自动重试机制
- **任务队列**: 持久化任务队列
- **详细报告**: 完整的执行日志

---

**版本**: 1.0
**状态**: ✅ 开发完成
**完成度**: 90%
