# Auto-GPT Task Dependencies - 任务依赖管理

<#
.SYNOPSIS
- 构建任务依赖图

.DESCRIPTION
- 分析任务之间的依赖关系，构建依赖图

.PARAMeter TaskGraph
- 任务关系映射（TaskId -> [Dependencies]）

.OUTPUTS
- 依赖图对象
#>

function Initialize-TaskDependencyGraph {
    param(
        [Parameter(Mandatory=$false)]
        [hashtable]$TaskGraph = @{}
    )

    Write-Host "🏗️ 初始化任务依赖图..." -ForegroundColor Cyan

    # 创建依赖图
    $dependencyGraph = [PSCustomObject]@{
        Tasks = @{}
        Edges = @()
        Nodes = @()
        CycleCheck = $false
        TopologicalSort = @()
    }

    # 分析依赖关系
    foreach ($taskId in $TaskGraph.Keys) {
        $dependencies = $TaskGraph[$taskId]

        foreach ($dep in $dependencies) {
            $dependencyGraph.Edges += @{
                From = $dep
                To = $taskId
            }
        }

        # 节点
        $dependencyGraph.Nodes += @{
            Id = $taskId
            Dependencies = @($dependencies)
            DependentTasks = @()
        }
    }

    # 填充依赖任务
    foreach ($edge in $dependencyGraph.Edges) {
        $node = $dependencyGraph.Nodes | Where-Object { $_.Id -eq $edge.To }
        if ($node) {
            $node.DependentTasks += $edge.From
        }
    }

    # 检测循环依赖
    $dependencyGraph.CycleCheck = Detect-Cycle -Graph $dependencyGraph

    # 执行拓扑排序
    $dependencyGraph.TopologicalSort = Perform-TopologicalSort -Graph $dependencyGraph

    Write-Host "  ✅ 依赖图初始化完成" -ForegroundColor Green
    Write-Host "  节点数: $($dependencyGraph.Nodes.Count)" -ForegroundColor White
    Write-Host "  边数: $($dependencyGraph.Edges.Count)" -ForegroundColor White
    Write-Host "  循环依赖: $($dependencyGraph.CycleCheck)" -ForegroundColor $(if ($dependencyGraph.CycleCheck) { 'Red' } else { 'Green' })

    return $dependencyGraph
}

<#
.SYNOPSIS
- 检测循环依赖

.DESCRIPTION
- 检查依赖图中是否存在循环依赖

.PARAMeter Graph
- 依赖图对象

.OUTPUTS
- 是否有循环依赖
#>

function Detect-Cycle {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Graph
    )

    $visited = @{}
    $recursionStack = @{}

    function Test-DFS {
        param(
            [Parameter(Mandatory=$true)]
            [string]$NodeId
        )

        $visited[$NodeId] = $true
        $recursionStack[$NodeId] = $true

        # 获取依赖此节点的任务（反向边）
        $dependents = $Graph.Edges | Where-Object { $_.From -eq $NodeId } | ForEach-Object { $_.To }

        foreach ($dep in $dependents) {
            if (-not $visited.ContainsKey($dep)) {
                if (Test-DFS -NodeId $dep) {
                    return $true
                }
            } elseif ($recursionStack.ContainsKey($dep)) {
                return $true
            }
        }

        $recursionStack[$NodeId] = $false
        return $false
    }

    foreach ($node in $Graph.Nodes) {
        if (-not $visited.ContainsKey($node.Id)) {
            if (Test-DFS -NodeId $node.Id) {
                return $true
            }
        }
    }

    return $false
}

<#
.SYNOPSIS
- 执行拓扑排序

.DESCRIPTION
- 对任务进行拓扑排序，确保依赖任务先执行

.PARAMeter Graph
- 依赖图对象

.OUTPUTS
- 排序后的任务ID列表
#>

function Perform-TopologicalSort {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Graph
    )

    # 统计入度
    $inDegree = @{}
    foreach ($node in $Graph.Nodes) {
        $inDegree[$node.Id] = $node.Dependencies.Count
    }

    # 初始化队列
    $queue = New-Object System.Collections.Generic.Queue[string]
    foreach ($node in $Graph.Nodes) {
        if ($inDegree[$node.Id] -eq 0) {
            [void]$queue.Enqueue($node.Id)
        }
    }

    $sortedTasks = @()

    # 拓扑排序
    while ($queue.Count -gt 0) {
        $currentTask = $queue.Dequeue()
        [void]$sortedTasks.Add($currentTask)

        # 减少依赖任务的入度
        foreach ($edge in $Graph.Edges) {
            if ($edge.From -eq $currentTask) {
                $inDegree[$edge.To]--
                if ($inDegree[$edge.To] -eq 0) {
                    [void]$queue.Enqueue($edge.To)
                }
            }
        }
    }

    # 检查是否有循环依赖
    if ($sortedTasks.Count -ne $Graph.Nodes.Count) {
        Write-Warning "检测到循环依赖，无法完成拓扑排序"
        return @()
    }

    return $sortedTasks
}

<#
.SYNOPSIS
- 识别可并行执行的任务

.DESCRIPTION
- 基于依赖关系识别可以并行执行的任务组

.PARAMeter Graph
- 依赖图对象

.OUTPUTS
- 并行任务组数组
#>

function Get-ParallelTasks {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Graph
    )

    $parallelGroups = @()
    $processedNodes = @{}

    foreach ($task in $Graph.TopologicalSort) {
        # 找出当前任务可以执行的所有任务（没有依赖关系的）
        $parallelGroup = @($Graph.Edges | Where-Object { $_.To -eq $task } | ForEach-Object { $_.From })

        # 添加当前任务
        [void]$parallelGroup.Add($task)

        # 过滤已经处理的节点
        $parallelGroup = @($parallelGroup | Where-Object { -not $processedNodes.ContainsKey($_) })

        if ($parallelGroup.Count -gt 0) {
            # 添加到并行组
            [void]$parallelGroups.Add($parallelGroup)

            # 标记为已处理
            foreach ($node in $parallelGroup) {
                $processedNodes[$node] = $true
            }
        }
    }

    return $parallelGroups
}

<#
.SYNOPSIS
- 优化任务执行顺序

.DESCRIPTION
- 根据依赖关系和优先级优化任务执行顺序

.PARAMeter Tasks
- 任务对象数组

.PARAMeter Dependencies
- 任务依赖映射

.PARAMeter Priorities
- 任务优先级映射（可选）

.OUTPUTS
- 优化后的任务数组
#>

function Optimize-TaskExecution {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Tasks,

        [Parameter(Mandatory=$false)]
        [hashtable]$Dependencies = @{},

        [Parameter(Mandatory=$false)]
        [hashtable]$Priorities = @{}
    )

    Write-Host "⚡ 优化任务执行顺序..." -ForegroundColor Cyan

    # 1. 构建依赖图
    $graph = Initialize-TaskDependencyGraph -TaskGraph $Dependencies

    # 2. 应用优先级
    if ($Priorities.Count -gt 0) {
        # 将高优先级任务移动到排序结果的前面
        $highPriorityTasks = @($Tasks | Where-Object { $Priorities.ContainsKey($_.Id) } | Sort-Object { $Priorities[$_.Id] } -Descending)
        $normalTasks = @($Tasks | Where-Object { -not $Priorities.ContainsKey($_.Id) })

        # 重新排序：高优先级任务优先
        $optimizedTasks = @()
        foreach ($priority in $Priorities.Values) {
            foreach ($task in $normalTasks) {
                if ($Priorities[$task.Id] -eq $priority) {
                    [void]$optimizedTasks.Add($task)
                }
            }
        }
        foreach ($task in $normalTasks) {
            if (-not $Priorities.ContainsKey($task.Id)) {
                [void]$optimizedTasks.Add($task)
            }
        }

        $Tasks = @($optimizedTasks)
    }

    # 3. 按依赖顺序排序
    $orderedTasks = @($Tasks | Sort-Object {
        $task = $_
        $graph.TopologicalSort.IndexOf($task.Id)
    })

    Write-Host "  ✅ 优化完成，共 $($orderedTasks.Count) 个任务" -ForegroundColor Green

    return $orderedTasks
}

<#
.SYNOPSIS
- 生成依赖关系可视化

.DESCRIPTION
- 生成依赖关系的可视化描述

.PARAMeter Graph
- 依赖图对象

.OUTPUTS
- 可视化描述字符串
#>

function Show-DependencyGraph {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Graph
    )

    Write-Host "📊 任务依赖关系:" -ForegroundColor Cyan
    Write-Host ""

    # 按顺序显示
    foreach ($taskId in $Graph.TopologicalSort) {
        $task = $Graph.Nodes | Where-Object { $_.Id -eq $taskId }
        Write-Host "  $taskId" -ForegroundColor White
        Write-Host "    ├─ 依赖: $($task.Dependencies -join ', ')" -ForegroundColor Gray

        if ($task.DependentTasks.Count -gt 0) {
            Write-Host "    └─ 被依赖: $($task.DependentTasks -join ', ')" -ForegroundColor Gray
        } else {
            Write-Host "    └─ 被依赖: 无" -ForegroundColor Gray
        }
        Write-Host ""
    }

    # 显示循环依赖警告
    if ($Graph.CycleCheck) {
        Write-Host "  ⚠️  警告: 检测到循环依赖！" -ForegroundColor Red
    }
}

# 导出函数
Export-ModuleMember -Function @(
    'Initialize-TaskDependencyGraph',
    'Detect-Cycle',
    'Perform-TopologicalSort',
    'Get-ParallelTasks',
    'Optimize-TaskExecution',
    'Show-DependencyGraph'
)
