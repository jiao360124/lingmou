<#
.SYNOPSIS
数据收集模块 - 从各系统收集数据

.DESCRIPTION
从self-evolution、smart-search、system-integration等系统收集数据，
用于可视化展示。

.PARAMeter Type
数据类型：task, system, search

.PARAMeter Days
获取最近N天的数据（仅task类型）

.EXAMPLE
.\data-collector.ps1 -Type "task" -Days 7
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("task", "system", "search", "all")]
    [string]$Type,

    [Parameter(Mandatory=$false)]
    [int]$Days = 7
)

function Collect-TaskProgress {
    param([int]$Days)

    Write-Host "📊 收集任务进度数据..." -ForegroundColor Cyan

    # 从self-evolution系统收集
    $taskFiles = Get-ChildItem -Path "skills\self-evolution\data" -Filter "*task*.json" -ErrorAction SilentlyContinue

    $tasks = @()
    $totalProgress = 0

    foreach ($file in $taskFiles) {
        if (Test-Path $file.FullName) {
            $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
            if ($content) {
                try {
                    $data = $content | ConvertFrom-Json
                    foreach ($item in $data.tasks) {
                        $tasks += [PSCustomObject]@{
                            name = $item.name
                            progress = $item.progress
                            status = $item.status
                            date = $item.date
                        }
                        $totalProgress += $item.progress
                    }
                } catch {
                    # 跳过无效JSON
                }
            }
        }
    }

    # 计算总体进度
    $overallProgress = 0
    if ($tasks.Count -gt 0) {
        $overallProgress = ($totalProgress / $tasks.Count)
    }

    $output = @{
        date = Get-Date -Format "yyyy-MM-dd"
        total_tasks = $tasks.Count
        completed_tasks = ($tasks | Where-Object { $_.status -eq "完成" }).Count
        overall_progress = [math]::Round($overallProgress, 1)
        tasks = $tasks
    }

    Write-Host "  找到 $($tasks.Count) 个任务" -ForegroundColor Green
    Write-Host "  总体进度: $([math]::Round($overallProgress, 1))%" -ForegroundColor Green

    return $output
}

function Collect-SystemStats {
    param()

    Write-Host "💻 收集系统统计数据..." -ForegroundColor Cyan

    # 收集Gateway状态
    $gatewayStatus = & openclaw gateway status 2>&1

    # 收集进程信息
    $nodeProcesses = Get-Process node -ErrorAction SilentlyContinue

    $cpuUsage = 0
    $memoryUsage = 0

    foreach ($process in $nodeProcesses) {
        $cpuUsage += $process.CPU
        $memoryUsage += $process.WorkingSet
    }

    $avgCpu = 0
    $avgMemory = 0

    if ($nodeProcesses.Count -gt 0) {
        $avgCpu = [math]::Round($cpuUsage / $nodeProcesses.Count, 2)
        $avgMemory = [math]::Round($memoryUsage / $nodeProcesses.Count / 1MB, 2)
    }

    $output = @{
        date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        gateway_status = "Running"
        gateway_port = 18789
        process_count = $nodeProcesses.Count
        avg_cpu = $avgCpu
        avg_memory_mb = $avgMemory
    }

    Write-Host "  进程数量: $($nodeProcesses.Count)" -ForegroundColor Green
    Write-Host "  平均CPU: $avgCpu%" -ForegroundColor Green
    Write-Host "  平均内存: $avgMemory MB" -ForegroundColor Green

    return $output
}

function Collect-SearchStats {
    param()

    Write-Host "🔍 收集搜索统计数据..." -ForegroundColor Cyan

    # 从smart-search系统收集
    $searchLogPath = "skills\smart-search\data\"

    $results = @{}

    if (Test-Path $searchLogPath) {
        $logFiles = Get-ChildItem -Path $searchLogPath -Filter "*.json" -ErrorAction SilentlyContinue

        foreach ($file in $logFiles) {
            if (Test-Path $file.FullName) {
                $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
                if ($content) {
                    try {
                        $data = $content | ConvertFrom-Json

                        foreach ($result in $data.results) {
                            if ($results.ContainsKey($result.source)) {
                                $results[$result.source]++
                            } else {
                                $results[$result.source] = 1
                            }
                        }
                    } catch {
                        # 跳过无效JSON
                    }
                }
            }
        }
    }

    $output = @{
        date = Get-Date -Format "yyyy-MM-dd"
        total_results = ($results.Values | Measure-Object -Sum).Sum
        sources = $results
    }

    Write-Host "  总结果数: $($output.total_results)" -ForegroundColor Green
    foreach ($source in $results.Keys) {
        Write-Host "  - $source: $($results[$source])" -ForegroundColor Gray
    }

    return $output
}

# 主程序入口
switch ($Type) {
    "task" {
        return Collect-TaskProgress -Days $Days
    }
    "system" {
        return Collect-SystemStats
    }
    "search" {
        return Collect-SearchStats
    }
    "all" {
        $taskData = Collect-TaskProgress -Days $Days
        $systemData = Collect-SystemStats
        $searchData = Collect-SearchStats
        return @{
            task = $taskData
            system = $systemData
            search = $searchData
        }
    }
}
