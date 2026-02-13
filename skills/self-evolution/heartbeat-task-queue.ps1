# Heartbeat任务队列系统

# @Author: 灵眸
# @Version: 1.0.0
# @Date: 2026-02-14
# @Purpose: 管理Heartbeat周期性任务队列

# 任务队列数据结构
$TaskQueue = @{
    tasks = @()
    stats = @{
        total = 0
        completed = 0
        failed = 0
        pending = 0
        lastUpdate = (Get-Date)
    }
}

# 配置
$Config = @{
    maxQueueSize = 100
    maxRetries = 3
    retryDelaySeconds = 60
    enabled = $true
    notifyOnComplete = $true
    notifyOnError = $true
    notificationChannel = "heartbeat"  # heartbeat, telegram, both
}

# 任务状态定义
$TaskStatus = @{
    pending = "pending"
    running = "running"
    completed = "completed"
    failed = "failed"
    cancelled = "cancelled"
}

# ============ 核心功能 ============

function Add-Task {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,

        [Parameter(Mandatory=$true)]
        [string]$Action,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters = @{},

        [Parameter(Mandatory=$false)]
        [string]$Priority = "normal",  # low, normal, high, critical

        [Parameter(Mandatory=$false)]
        [int]$DelaySeconds = 0,

        [Parameter(Mandatory=$false)]
        [switch]$Async = $false
    )

    try {
        $Task = @{
            id = [guid]::NewGuid().ToString()
            name = $Name
            action = $Action
            parameters = $Parameters
            priority = $Priority
            status = if ($DelaySeconds -gt 0) { "pending" } else { $TaskStatus.pending }
            delayUntil = if ($DelaySeconds -gt 0) { (Get-Date).AddSeconds($DelaySeconds) } else { $null }
            createdAt = (Get-Date)
            updatedAt = (Get-Date)
            retries = 0
            result = $null
            error = $null
        }

        # 按优先级排序
        $PriorityOrder = @{
            "critical" = 4
            "high" = 3
            "normal" = 2
            "low" = 1
        }

        $Queue = $TaskQueue.tasks
        $InsertIndex = $Queue.Count

        for ($i = 0; $i -lt $Queue.Count; $i++) {
            $CurrentPriority = $PriorityOrder[$Queue[$i].priority]
            $NewPriority = $PriorityOrder[$Priority]

            if ($NewPriority -gt $CurrentPriority) {
                $InsertIndex = $i
                break
            }
        }

        $Queue.Insert($InsertIndex, $Task)
        $TaskQueue.stats.total++

        # 限制队列大小
        while ($Queue.Count -gt $Config.maxQueueSize) {
            $Queue.RemoveAt(0)
        }

        $TaskQueue.stats.lastUpdate = (Get-Date)

        Write-Host "✓ 任务已添加: $Name" -ForegroundColor Green
        Write-Host "  ID: $($Task.id)" -ForegroundColor Cyan
        Write-Host "  优先级: $Priority" -ForegroundColor Cyan
        Write-Host "  状态: $($Task.status)" -ForegroundColor Cyan

        return $Task

    } catch {
        Write-Host "✗ 添加任务失败: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Get-QueueStatus {
    return $TaskQueue.stats
}

function Get-QueueTasks {
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet("pending", "running", "completed", "failed", "all")]
        [string]$StatusFilter = "all",

        [Parameter(Mandatory=$false)]
        [int]$Limit = 10
    )

    $Tasks = $TaskQueue.tasks

    if ($StatusFilter -ne "all") {
        $Tasks = $Tasks | Where-Object { $_.status -eq $StatusFilter }
    }

    # 按创建时间倒序
    $Tasks = $Tasks | Sort-Object -Property createdAt -Descending

    return $Tasks | Select-Object -First $Limit
}

function Process-Queue {
    param(
        [Parameter(Mandatory=$false)]
        [switch]$DryRun = $false
    )

    Write-Host "`n========== Heartbeat任务队列处理 ==========" -ForegroundColor Magenta
    Write-Host "Dry Run: $DryRun" -ForegroundColor Cyan

    if (-not $Config.enabled) {
        Write-Host "✗ 队列已禁用" -ForegroundColor Red
        return
    }

    $Tasks = $TaskQueue.tasks | Where-Object { $_.status -eq $TaskStatus.pending }

    if ($Tasks.Count -eq 0) {
        Write-Host "✓ 队列为空，无需处理" -ForegroundColor Green
        return
    }

    Write-Host "待处理任务数: $($Tasks.Count)" -ForegroundColor Cyan

    foreach ($Task in $Tasks) {
        # 检查延迟是否到期
        if ($Task.delayUntil -and (Get-Date) -lt $Task.delayUntil) {
            continue
        }

        Write-Host "`n处理任务: $($Task.name)" -ForegroundColor Yellow
        Write-Host "  ID: $($Task.id)" -ForegroundColor Cyan
        Write-Host "  Action: $($Task.action)" -ForegroundColor Cyan

        if ($DryRun) {
            Write-Host "  [Dry Run] 执行: $($Task.action)" -ForegroundColor DarkGray
            Mark-TaskAsCompleted $Task.id
        } else {
            Execute-Task $Task
        }
    }

    Save-QueueData
}

function Execute-Task {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Task
    )

    try {
        $Task.status = $TaskStatus.running
        $Task.updatedAt = (Get-Date)

        Write-Host "  → 执行: $($Task.action)" -ForegroundColor Green

        # 这里是实际执行任务的逻辑
        # TODO: 实现具体任务执行逻辑
        # 例如:
        # - 调用Heartbeat检查
        # - 更新记忆文件
        # - 生成报告
        # - 发送通知

        # 模拟执行成功
        Start-Sleep -Seconds 1

        Mark-TaskAsCompleted $Task.id

    } catch {
        $Task.status = $TaskStatus.failed
        $Task.error = $_.Exception.Message
        $Task.retries++

        Write-Host "  ✗ 执行失败: $($_.Exception.Message)" -ForegroundColor Red

        if ($Task.retries -lt $Config.maxRetries) {
            Write-Host "  → 重试 $($Task.retries)/$($Config.maxRetries)..." -ForegroundColor Yellow
            Start-Sleep -Seconds $Config.retryDelaySeconds
            $Task.status = $TaskStatus.pending
            $Task.delayUntil = (Get-Date).AddSeconds($Config.retryDelaySeconds)
        } else {
            Write-Host "  ✗ 已达到最大重试次数" -ForegroundColor Red
        }

        $TaskQueue.stats.failed++
    }

    $Task.updatedAt = (Get-Date)
}

function Mark-TaskAsCompleted {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskId
    )

    $Task = $TaskQueue.tasks | Where-Object { $_.id -eq $TaskId }
    if ($Task) {
        $Task.status = $TaskStatus.completed
        $Task.completedAt = (Get-Date)
        $TaskQueue.stats.completed++
        $TaskQueue.stats.pending--
        $TaskQueue.stats.lastUpdate = (Get-Date)

        # 通知
        if ($Config.notifyOnComplete) {
            Notify-TaskCompleted $Task
        }
    }
}

function Mark-TaskAsFailed {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskId,
        [Parameter(Mandatory=$false)]
        [string]$ErrorMessage
    )

    $Task = $TaskQueue.tasks | Where-Object { $_.id -eq $TaskId }
    if ($Task) {
        $Task.status = $TaskStatus.failed
        $Task.error = $ErrorMessage
        $Task.completedAt = (Get-Date)
        $TaskQueue.stats.failed++
        $TaskQueue.stats.pending--
        $TaskQueue.stats.lastUpdate = (Get-Date)

        # 通知
        if ($Config.notifyOnError) {
            Notify-TaskFailed $Task
        }
    }
}

function Remove-Task {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskId,

        [Parameter(Mandatory=$false)]
        [switch]$Force = $false
    )

    $Task = $TaskQueue.tasks | Where-Object { $_.id -eq $TaskId }

    if (-not $Task) {
        Write-Host "✗ 任务不存在" -ForegroundColor Red
        return
    }

    if (-not $Force -and $Task.status -in @($TaskStatus.running, $TaskStatus.completed, $TaskStatus.failed)) {
        Write-Host "✗ 无法删除运行中或已完成的任务" -ForegroundColor Red
        return
    }

    $TaskQueue.tasks = $TaskQueue.tasks | Where-Object { $_.id -ne $TaskId }
    $TaskQueue.stats.total--
    $TaskQueue.stats.pending--
    $TaskQueue.stats.lastUpdate = (Get-Date)

    Write-Host "✓ 任务已删除: $($Task.name)" -ForegroundColor Green
}

function Clear-CompletedTasks {
    $TaskQueue.tasks = $TaskQueue.tasks | Where-Object { $_.status -ne $TaskStatus.completed }
    $TaskQueue.stats.pending = ($TaskQueue.tasks | Where-Object { $_.status -eq $TaskStatus.pending }).Count
    $TaskQueue.stats.lastUpdate = (Get-Date)

    Write-Host "✓ 已清理已完成任务" -ForegroundColor Green
}

function Save-QueueData {
    $QueueFile = "$PSScriptRoot/../data/heartbeat-task-queue.json"

    if (-not (Test-Path (Split-Path $QueueFile))) {
        New-Item -ItemType Directory -Path (Split-Path $QueueFile) -Force | Out-Null
    }

    $TaskQueue | ConvertTo-Json -Depth 10 | Out-File -FilePath $QueueFile -Encoding UTF8
}

function Load-QueueData {
    $QueueFile = "$PSScriptRoot/../data/heartbeat-task-queue.json"

    if (Test-Path $QueueFile) {
        $LoadedData = Get-Content -Path $QueueFile | ConvertFrom-Json
        $TaskQueue.tasks = $LoadedData.tasks
        $TaskQueue.stats = $LoadedData.stats
        $Config = $LoadedData.config
        Write-Host "✓ 任务队列已加载" -ForegroundColor Green
    } else {
        Write-Host "ℹ 无现有队列数据" -ForegroundColor Cyan
    }
}

# ============ 通知系统 ============

function Notify-TaskCompleted {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Task
    )

    Write-Host "  ✓ 通知: 任务完成" -ForegroundColor Green
    # TODO: 实现通知逻辑
    # - Telegram通知
    # - 系统通知
    # - 邮件通知
}

function Notify-TaskFailed {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Task
    )

    Write-Host "  ✓ 通知: 任务失败" -ForegroundColor Red
    # TODO: 实现通知逻辑
    # - Telegram通知
    # - 系统通知
    # - 邮件通知
}

# ============ 预定义任务 ============

function Get-PresetTasks {
    return @{
        "check-memory" = @{
            name = "检查记忆文件"
            action = "memory-check"
            parameters = @{}
            priority = "normal"
            delaySeconds = 0
        }
        "update-daily-log" = @{
            name = "更新每日日志"
            action = "daily-log"
            parameters = @{}
            priority = "normal"
            delaySeconds = 300  # 5分钟后执行
        }
        "sync-moltbook" = @{
            name = "同步Moltbook"
            action = "moltbook-sync"
            parameters = @{}
            priority = "high"
            delaySeconds = 600  # 10分钟后执行
        }
        "generate-report" = @{
            name = "生成每日报告"
            action = "daily-report"
            parameters = @{}
            priority = "normal"
            delaySeconds = 1800  # 30分钟后执行
        }
    }
}

# ============ 初始化 ============

Load-QueueData
Write-Host "`n✓ Heartbeat任务队列系统已启动" -ForegroundColor Green
Write-Host "  队列大小: $($TaskQueue.tasks.Count)" -ForegroundColor Cyan
Write-Host "  已处理: $($TaskQueue.stats.completed)" -ForegroundColor Cyan
Write-Host "  待处理: $($TaskQueue.stats.pending)" -ForegroundColor Cyan
Write-Host "  失败数: $($TaskQueue.stats.failed)" -ForegroundColor Cyan
