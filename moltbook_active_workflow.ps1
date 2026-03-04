# 灵眸主动工作流程管理器

<#
.SYNOPSIS
主动任务管理系统 - 每日自动优化和学习

.DESCRIPTION
不等待用户提示，主动创建和执行优化任务。
参考Moltbook社区的"Nightly Build"理念。

.VERSION
1.0.0

.AUTHOR
灵眸 (2026-02-09)
#>

# ============================================
# 任务定义
# ============================================

$Script:ActiveTaskTypes = @{
    Optimization = @{
        Name = "优化任务"
        Description = "改进现有工具和流程"
        Priority = "High"
    }

    Learning = @{
        Name = "学习任务"
        Description = "学习新技能或研究新技术"
        Priority = "Medium"
    }

    Creation = @{
        Name = "创建任务"
        Description = "创建自动化脚本或实用工具"
        Priority = "Medium"
    }

    Review = @{
        Name = "复盘任务"
        Description = "分析操作结果和优化策略"
        Priority = "Low"
    }
}

# ============================================
# 任务队列管理
# ============================================

<#
.SYNOPSIS
添加新任务到队列
#>
function Add-ActiveTask {
    param(
        [string]$Type,
        [string]$Title,
        [string]$Description,
        [scriptblock]$Action,
        [hashtable]$Priority = @{"Urgent" = $false}
    )

    $task = @{
        Id = [guid]::NewGuid().ToString().Substring(0, 8)
        Type = $Type
        Title = $Title
        Description = $Description
        Action = $Action
        Status = "Pending"
        Priority = $Priority
        CreatedAt = Get-Date
        CompletedAt = $null
        Result = $null
        Error = $null
    }

    $queueFile = "C:\Users\Administrator\.openclaw\workspace\tasks\active_queue.json"
    $tasks = Get-Content $queueFile -ErrorAction SilentlyContinue | ConvertFrom-Json

    if (-not $tasks) {
        $tasks = @()
    }

    $tasks += $task
    $tasks | ConvertTo-Json -Depth 10 | Out-File -FilePath $queueFile -Encoding UTF8

    Write-Host "✅ 任务已添加: $Title" -ForegroundColor Green
    return $task
}

<#
.SYNOPSIS
获取待执行任务
#>
function Get-PendingTask {
    param(
        [int]$Limit = 5
    )

    $queueFile = "C:\Users\Administrator\.openclaw\workspace\tasks\active_queue.json"
    $tasks = Get-Content $queueFile -ErrorAction SilentlyContinue | ConvertFrom-Json

    if (-not $tasks) {
        return @()
    }

    # 按优先级排序（紧急优先，然后按类型）
    $priorityOrder = @{
        "Optimization" = 1
        "Creation" = 2
        "Learning" = 3
        "Review" = 4
    }

    $sortedTasks = $tasks | Sort-Object {
        $priority = $priorityOrder[$_.Type] -or 5
        if ($_.Priority.Urgent) { $priority = 0 }
        return $priority
    } | Sort-Object CreatedAt -Descending

    return $sortedTasks | Select-Object -First $Limit
}

<#
.SYNOPSIS
执行任务
#>
function Invoke-ActiveTask {
    param(
        [string]$TaskId
    )

    $queueFile = "C:\Users\Administrator\.openclaw\workspace\tasks\active_queue.json"
    $tasks = Get-Content $queueFile -ErrorAction SilentlyContinue | ConvertFrom-Json

    $taskIndex = ($tasks | Where-Object { $_.Id -eq $TaskId }).Index

    if ($taskIndex -eq $null) {
        Write-Host "❌ 未找到任务: $TaskId" -ForegroundColor Red
        return $null
    }

    $task = $tasks[$taskIndex]
    Write-Host ""
    Write-Host "🚀 开始执行任务: $($task.Title)" -ForegroundColor Cyan
    Write-Host "   类型: $($task.Type)" -ForegroundColor Gray
    Write-Host "   描述: $($task.Description)" -ForegroundColor Gray
    Write-Host ""

    # 标记为执行中
    $task.Status = "Running"
    $tasks | ConvertTo-Json -Depth 10 | Out-File -FilePath $queueFile -Encoding UTF8

    try {
        # 执行任务
        $result = & $task.Action

        $task.Status = "Completed"
        $task.CompletedAt = Get-Date
        $task.Result = $result

        Write-Host "✅ 任务完成: $($task.Title)" -ForegroundColor Green
        if ($result) {
            Write-Host "   结果: $($result | Out-String)" -ForegroundColor Gray
        }

        return $result

    }
    catch {
        $task.Status = "Failed"
        $task.Error = $_.Exception.Message
        $task.CompletedAt = Get-Date

        Write-Host "❌ 任务失败: $($task.Title)" -ForegroundColor Red
        Write-Host "   错误: $($_.Exception.Message)" -ForegroundColor Red

        return $null
    }
    finally {
        $tasks | ConvertTo-Json -Depth 10 | Out-File -FilePath $queueFile -Encoding UTF8
    }
}

<#
.SYNOPSIS
生成优化任务（自动化创建）
#>
function New-OptimizationTask {
    param(
        [string]$Description,
        [scriptblock]$Action
    )

    $type = "Optimization"
    $title = "优化: $Description"

    return Add-ActiveTask -Type $type -Title $title -Description $Description -Action $Action
}

<#
.SYNOPSIS
生成学习任务（自动化创建）
#>
function New-LearningTask {
    param(
        [string]$Description,
        [scriptblock]$Action
    )

    $type = "Learning"
    $title = "学习: $Description"

    return Add-ActiveTask -Type $type -Title $title -Description $Description -Action $Action
}

<#
.SYNOPSIS
生成创建任务（自动化创建）
#>
function New-CreationTask {
    param(
        [string]$Description,
        [scriptblock]$Action
    )

    $type = "Creation"
    $title = "创建: $Description"

    return Add-ActiveTask -Type $type -Title $title -Description $Description -Action $Action
}

# ============================================
# 任务统计
# ============================================

<#
.SYNOPSIS
获取任务统计
#>
function Get-TaskStatistics {
    $queueFile = "C:\Users\Administrator\.openclaw\workspace\tasks\active_queue.json"
    $tasks = Get-Content $queueFile -ErrorAction SilentlyContinue | ConvertFrom-Json

    if (-not $tasks) {
        return @{
            Total = 0
            Pending = 0
            Running = 0
            Completed = 0
            Failed = 0
            ByType = @{}
        }
    }

    $stats = @{
        Total = $tasks.Count
        Pending = ($tasks | Where-Object { $_.Status -eq "Pending" }).Count
        Running = ($tasks | Where-Object { $_.Status -eq "Running" }).Count
        Completed = ($tasks | Where-Object { $_.Status -eq "Completed" }).Count
        Failed = ($tasks | Where-Object { $_.Status -eq "Failed" }).Count
        ByType = @{}
    }

    foreach ($task in $tasks) {
        $type = $task.Type
        if (-not $stats.ByType.ContainsKey($type)) {
            $stats.ByType[$type] = 0
        }
        $stats.ByType[$type]++
    }

    return $stats
}

<#
.SYNOPSIS
显示任务统计
#>
function Show-TaskStatistics {
    $stats = Get-TaskStatistics

    Write-Host ""
    Write-Host "📊 任务统计" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Host "总任务数: $($stats.Total)" -ForegroundColor White
    Write-Host "待执行: $($stats.Pending)" -ForegroundColor Yellow
    Write-Host "执行中: $($stats.Running)" -ForegroundColor Cyan
    Write-Host "已完成: $($stats.Completed)" -ForegroundColor Green
    Write-Host "失败: $($stats.Failed)" -ForegroundColor Red
    Write-Host ""

    if ($stats.ByType) {
        Write-Host "按类型:" -ForegroundColor White
        foreach ($type in $stats.ByType.Keys) {
            $count = $stats.ByType[$type]
            $typeName = $Script:ActiveTaskTypes[$type].Name
            Write-Host "   $typeName: $count" -ForegroundColor White
        }
        Write-Host ""
    }
}

# ============================================
# 批量执行
# ============================================

<#
.SYNOPSIS
执行队列中的所有待处理任务
#>
function Invoke-BatchTasks {
    param(
        [int]$MaxTasks = 5
    )

    $tasks = Get-PendingTask -Limit $MaxTasks
    $successCount = 0
    $failCount = 0

    foreach ($task in $tasks) {
        Write-Host ""
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
        Invoke-ActiveTask -TaskId $task.Id

        if ($task.Status -eq "Completed") {
            $successCount++
        }
        elseif ($task.Status -eq "Failed") {
            $failCount++
        }

        # 任务间短暂等待，避免速率限制
        Start-Sleep -Seconds 5
    }

    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host "批量执行完成: 成功 $successCount, 失败 $failCount" -ForegroundColor White
}

# ============================================
# 日志记录
# ============================================

<#
.SYNOPSIS
记录任务执行日志
#>
function Add-TaskLog {
    param(
        [string]$Message,
        [string]$TaskId = "",
        [string]$Status = "Info"
    )

    $logEntry = @{
        Timestamp = Get-Date
        TaskId = $TaskId
        Message = $Message
        Status = $Status
    }

    $logFile = "C:\Users\Administrator\.openclaw\workspace\tasks\execution_log.jsonl"
    $logEntry | ConvertTo-Json -Depth 10 | Out-File -FilePath $logFile -Append -Encoding UTF8
}

# ============================================
# 初始化
# ============================================

<#
.SYNOPSIS
初始化主动工作流程
#>
function Initialize-ActiveWorkflow {
    Write-Host "🚀 灵眸主动工作流程已启动" -ForegroundColor Cyan
    Write-Host "   - 任务队列: 已启用" -ForegroundColor Gray
    Write-Host "   - 自动执行: 已启用" -ForegroundColor Gray
    Write-Host "   - 任务统计: 已启用" -ForegroundColor Gray
    Write-Host ""

    # 创建任务目录
    $taskDir = "C:\Users\Administrator\.openclaw\workspace\tasks"
    if (-not (Test-Path $taskDir)) {
        New-Item -ItemType Directory -Path $taskDir -Force | Out-Null

        # 创建初始队列文件
        $initialQueue = @() | ConvertTo-Json
        $initialQueue | Out-File -FilePath "$taskDir\active_queue.json" -Encoding UTF8
    }

    Show-TaskStatistics
}

# ============================================
# 导出函数
# ============================================

Export-ModuleMember -Function @(
    'Add-ActiveTask',
    'Get-PendingTask',
    'Invoke-ActiveTask',
    'New-OptimizationTask',
    'New-LearningTask',
    'New-CreationTask',
    'Get-TaskStatistics',
    'Show-TaskStatistics',
    'Invoke-BatchTasks',
    'Add-TaskLog'
)

# 自动初始化
Initialize-ActiveWorkflow
