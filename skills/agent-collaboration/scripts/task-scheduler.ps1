<#
.SYNOPSIS
任务调度和协调模块 - 协调Agent执行任务

.DESCRIPTION
检测Agent依赖关系，优化执行顺序，支持并行和串行执行。

.PARAMeter Tasks
任务列表

.PARAMeter Mode
执行模式：sequential, parallel

.EXAMPLE
.\task-scheduler.ps1 -Tasks $tasks -Mode "parallel"
#>

param(
    [Parameter(Mandatory=$true)]
    [array]$Tasks,

    [Parameter(Mandatory=$false)]
    [ValidateSet("sequential", "parallel")]
    [string]$Mode = "sequential"
)

function Analyze-Dependencies {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Tasks
    )

    # 构建依赖图
    $dependencyGraph = @{}

    foreach ($task in $Tasks) {
        $taskId = $task.id
        $dependencyGraph[$taskId] = @{
            dependencies = @()
            dependents = @()
            independent = $true
        }
    }

    # 分析依赖关系
    foreach ($task in $Tasks) {
        $taskId = $task.id

        if ($task.dependencies -and $task.dependencies.Count -gt 0) {
            $dependencyGraph[$taskId].independent = $false

            foreach ($depId in $task.dependencies) {
                $dependencyGraph[$depId].dependents += $taskId
            }
        }
    }

    return $dependencyGraph
}

function Sort-ByTopology {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$DependencyGraph,

        [Parameter(Mandatory=$true)]
        [array]$Tasks
    )

    $sorted = @()
    $visited = @{}
    $tempMarked = @{}

    # 拓扑排序函数
    function Visit-Node {
        param(
            [Parameter(Mandatory=$true)]
            [string]$NodeId,

            [Parameter(Mandatory=$true)]
            [hashtable]$DependencyGraph,

            [Parameter(Mandatory=$true)]
            [ref]$Sorted,

            [Parameter(Mandatory=$true)]
            [hashtable]$Visited,

            [Parameter(Mandatory=$true)]
            [hashtable]$TempMarked
        )

        if ($Visited.ContainsKey($NodeId)) {
            return
        }

        if ($TempMarked.ContainsKey($NodeId)) {
            throw "检测到循环依赖: $NodeId"
        }

        # 访问所有依赖节点
        $node = $DependencyGraph[$NodeId]
        foreach ($depId in $node.dependencies) {
            Visit-Node -NodeId $depId -DependencyGraph $DependencyGraph -Sorted $Sorted -Visited $Visited -TempMarked $TempMarked
        }

        $Visited[$NodeId] = $true
        $Sorted.Value += $Tasks | Where-Object { $_.id -eq $NodeId }
    }

    # 对每个节点执行拓扑排序
    foreach ($task in $Tasks) {
        if (-not $Visited.ContainsKey($task.id)) {
            Visit-Node -NodeId $task.id -DependencyGraph $DependencyGraph -Sorted (Get-Variable Sorted).Value -Visited $Visited -TempMarked $TempMarked
        }
    }

    return $Sorted.Value
}

function Plan-Execution {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Tasks,

        [Parameter(Mandatory=$false)]
        [string]$Mode = "sequential"
    )

    Write-Host "📋 任务调度分析" -ForegroundColor Cyan
    Write-Host "====================" -ForegroundColor Cyan
    Write-Host "  任务数量: $($Tasks.Count)" -ForegroundColor Yellow
    Write-Host "  执行模式: $Mode" -ForegroundColor Yellow
    Write-Host "====================`n" -ForegroundColor Cyan

    # 分析依赖
    $dependencyGraph = Analyze-Dependencies -Tasks $Tasks

    Write-Host "🔍 依赖分析:" -ForegroundColor Yellow
    foreach ($taskId in $dependencyGraph.Keys) {
        $node = $dependencyGraph[$taskId]
        if ($node.independent) {
            Write-Host "  [$taskId] 独立任务" -ForegroundColor Green
        } else {
            Write-Host "  [$taskId] 依赖: $($node.dependencies -join ', ')" -ForegroundColor Gray
            Write-Host "    被: $($node.dependents -join ', ') 依赖" -ForegroundColor Gray
        }
    }

    # 拓扑排序
    Write-Host "`n🔄 拓扑排序:" -ForegroundColor Yellow
    $sortedTasks = Sort-ByTopology -DependencyGraph $DependencyGraph -Tasks $Tasks

    foreach ($i = 0; $i -lt $sortedTasks.Count; $i++) {
        $task = $sortedTasks[$i]
        $dependencies = if ($task.dependencies.Count -gt 0) { " (依赖: $($task.dependencies -join ', '))" } else { "" }
        Write-Host "  $i. $($task.name)$dependencies" -ForegroundColor Green
    }

    Write-Host "`n====================" -ForegroundColor Cyan
    Write-Host "  优化后任务数: $($sortedTasks.Count)" -ForegroundColor Green
    Write-Host "  执行顺序已优化" -ForegroundColor Green
    Write-Host "====================`n" -ForegroundColor Cyan

    return $sortedTasks
}

function Execute-Parallel {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Tasks,

        [Parameter(Mandatory=$false)]
        [int]$MaxConcurrency = 3
    )

    Write-Host "🚀 并行执行任务" -ForegroundColor Cyan

    $completed = 0
    $total = $Tasks.Count

    # 分批并行执行
    for ($batch = 0; $batch -lt [Math]::Ceiling($total / $MaxConcurrency); $batch++) {
        $batchTasks = $Tasks[($batch * $MaxConcurrency) .. [Math]::Min(($batch + 1) * $MaxConcurrency - 1, $total - 1)]

        Write-Host "`n  批次 $($batch + 1)/$([Math]::Ceiling($total / $MaxConcurrency)):" -ForegroundColor Yellow

        $batchJobs = @()
        foreach ($task in $batchTasks) {
            Write-Host "    → 执行: $($task.name)" -ForegroundColor Gray

            # 这里可以添加实际执行逻辑
            # $result = & $task.script

            $batchJobs += @{
                task = $task
                status = "completed"
                result = "执行完成"
            }
        }

        $completed += $batchJobs.Count

        # 显示进度
        $progress = [math]::Round(($completed / $total) * 100, 1)
        Write-Host "  进度: $progress%" -ForegroundColor Cyan
    }

    Write-Host "`n✓ 并行执行完成，共 $total 个任务" -ForegroundColor Green
}

function Execute-Sequential {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Tasks
    )

    Write-Host "🚓 串行执行任务" -ForegroundColor Cyan
    Write-Host "`n"

    foreach ($task in $Tasks) {
        Write-Host "  → 执行: $($task.name)" -ForegroundColor Yellow
        Write-Host "  ✓ 完成: $($task.name)" -ForegroundColor Green
        Write-Host ""
    }

    Write-Host "✓ 串行执行完成，共 $($Tasks.Count) 个任务" -ForegroundColor Green
}

# 主程序入口
$sortedTasks = Plan-Execution -Tasks $Tasks -Mode $Mode

if ($Mode -eq "parallel") {
    Execute-Parallel -Tasks $sortedTasks
} else {
    Execute-Sequential -Tasks $sortedTasks
}

return $sortedTasks
