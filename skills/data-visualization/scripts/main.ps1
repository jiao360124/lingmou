<#
.SYNOPSIS
数据可视化系统 - 主程序入口

.DESCRIPTION
数据可视化系统主程序，提供任务进度、系统状态、搜索结果等数据的可视化展示。

.EXAMPLE
.\main.ps1 -Action progress -Type "task"

.EXAMPLE
.\main.ps1 -Action dashboard -Type "system"
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("progress", "chart", "dashboard", "export")]
    [string]$Action,

    [Parameter(Mandatory=$false)]
    [string]$Type = "task",

    [Parameter(Mandatory=$false)]
    [int]$Days = 7,

    [Parameter(Mandatory=$false)]
    [string]$OutputFile
)

function Run-ProgressView {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Type,

        [Parameter(Mandatory=$false)]
        [int]$Days = 7
    )

    Write-Host "`n🚀 Phase 4 数据可视化系统 - 任务进度" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
    Write-Host "  类型: $Type" -ForegroundColor Yellow
    Write-Host "========================================`n" -ForegroundColor Cyan

    # 收集数据
    $data = & .\scripts\data-collector.ps1 -Type $Type -Days $Days

    if ($null -eq $data) {
        Write-Host "❌ 没有收集到数据" -ForegroundColor Red
        return
    }

    # 生成图表
    if ($Type -eq "task") {
        # 任务进度 - 柱状图
        $chartData = @{
            labels = $data.tasks | ForEach-Object { $_.name }
            values = $data.tasks | ForEach-Object { $_.progress }
            title = "任务进度"
        }

        & .\scripts\chart-generator.ps1 -Type "bar" -Data $chartData -Title "任务进度"

        # 总体进度
        Write-Host "`n📋 总体进度: $([math]::Round($data.overall_progress, 1))%" -ForegroundColor Green
        Write-Host "  完成任务: $($data.completed_tasks)/$($data.total_tasks)" -ForegroundColor Green
    } elseif ($Type -eq "system") {
        # 系统统计 - 雷达图
        $chartData = @{
            labels = @("CPU使用率", "内存使用", "磁盘使用", "网络使用")
            dimensions = @($data.avg_cpu, $data.avg_memory_mb, 60, 25)
            title = "系统性能"
        }

        & .\scripts\chart-generator.ps1 -Type "radar" -Data $chartData -Title "系统性能"
    } elseif ($Type -eq "search") {
        # 搜索统计 - 饼图
        $chartData = @{
            labels = $data.sources.Keys
            values = $data.sources.Values
            title = "搜索结果分布"
        }

        & .\scripts\chart-generator.ps1 -Type "pie" -Data $chartData -Title "搜索结果分布"
    }

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  完成！" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Cyan
}

function Run-Dashboard {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Type
    )

    Write-Host "`n📊 交互式仪表盘" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
    Write-Host "  类型: $Type" -ForegroundColor Yellow
    Write-Host "========================================`n" -ForegroundColor Cyan

    # 收集所有类型数据
    $allData = & .\scripts\data-collector.ps1 -Type "all"

    if ($null -eq $allData) {
        Write-Host "❌ 没有收集到数据" -ForegroundColor Red
        return
    }

    # 生成多个图表
    switch ($Type) {
        "system" {
            # 系统仪表盘
            Write-Host "`n🖥️  系统性能仪表盘" -ForegroundColor Yellow

            # CPU和内存 - 柱状图
            $systemData = $allData.system
            $systemChart = @{
                labels = @("CPU", "内存", "磁盘", "网络")
                values = @($systemData.avg_cpu, $systemData.avg_memory_mb, 60, 25)
                title = "系统资源使用"
            }

            & .\scripts\chart-generator.ps1 -Type "bar" -Data $systemChart -Title "系统资源"

            # 进程统计
            Write-Host "`n📈 进程统计" -ForegroundColor Yellow
            Write-Host "  进程数量: $($systemData.process_count)" -ForegroundColor Green
            Write-Host "  端口: $($systemData.gateway_port)" -ForegroundColor Green
        }
        "task" {
            # 任务仪表盘
            Write-Host "`n📋 任务进度仪表盘" -ForegroundColor Yellow

            $taskData = $allData.task
            $taskChart = @{
                labels = $taskData.tasks | ForEach-Object { $_.name }
                values = $taskData.tasks | ForEach-Object { $_.progress }
                title = "任务进度"
            }

            & .\scripts\chart-generator.ps1 -Type "bar" -Data $taskChart -Title "任务进度"

            Write-Host "`n📊 总体进度: $([math]::Round($taskData.overall_progress, 1))%" -ForegroundColor Green
        }
        "search" {
            # 搜索仪表盘
            Write-Host "`n🔍 搜索结果仪表盘" -ForegroundColor Yellow

            $searchData = $allData.search
            $searchChart = @{
                labels = $searchData.sources.Keys
                values = $searchData.sources.Values
                title = "搜索结果分布"
            }

            & .\scripts\chart-generator.ps1 -Type "pie" -Data $searchChart -Title "搜索结果"

            Write-Host "`n📊 总结果数: $($searchData.total_results)" -ForegroundColor Green
        }
        "all" {
            # 综合仪表盘
            Write-Host "`n📊 综合仪表盘" -ForegroundColor Yellow

            # 任务进度
            Write-Host "`n📋 任务进度" -ForegroundColor Yellow
            $taskChart = @{
                labels = $allData.task.tasks | ForEach-Object { $_.name }
                values = $allData.task.tasks | ForEach-Object { $_.progress }
                title = "任务进度"
            }

            & .\scripts\chart-generator.ps1 -Type "bar" -Data $taskChart -Title "任务进度"

            # 系统性能
            Write-Host "`n💻 系统性能" -ForegroundColor Yellow
            $systemChart = @{
                labels = @("CPU", "内存", "磁盘", "网络")
                values = @($allData.system.avg_cpu, $allData.system.avg_memory_mb, 60, 25)
                title = "系统资源"
            }

            & .\scripts\chart-generator.ps1 -Type "radar" -Data $systemChart -Title "系统资源"

            # 搜索统计
            Write-Host "`n🔍 搜索结果" -ForegroundColor Yellow
            $searchChart = @{
                labels = $allData.search.sources.Keys
                values = $allData.search.sources.Values
                title = "搜索结果分布"
            }

            & .\scripts\chart-generator.ps1 -Type "pie" -Data $searchChart -Title "搜索结果"
        }
    }

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  完成！" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Cyan
}

function Run-Chart {
    param(
        [Parameter(Mandatory=$false)]
        [string]$Type = "bar",

        [Parameter(Mandatory=$false)]
        $Data,

        [Parameter(Mandatory=$false)]
        [string]$Title = "Chart"
    )

    & .\scripts\chart-generator.ps1 -Type $Type -Data $Data -Title $Title
}

function Run-Export {
    param(
        [Parameter(Mandatory=$false)]
        [string]$Format = "json",

        [Parameter(Mandatory=$false)]
        [string]$Type = "task",

        [Parameter(Mandatory=$false)]
        [string]$OutputFile
    )

    Write-Host "`n📤 导出数据" -ForegroundColor Cyan
    Write-Host "  格式: $Format" -ForegroundColor Yellow
    Write-Host "  类型: $Type" -ForegroundColor Yellow

    # 收集数据
    $data = & .\scripts\data-collector.ps1 -Type $Type

    if ($null -eq $data) {
        Write-Host "❌ 没有收集到数据" -ForegroundColor Red
        return
    }

    # 导出
    if ($Format -eq "json") {
        $output = $data | ConvertTo-Json -Depth 10
        if ([string]::IsNullOrEmpty($OutputFile)) {
            $OutputFile = "data-export-$([DateTime]::Now:yyyyMMdd-HHmmss).json"
        }

        $output | Out-File -FilePath $OutputFile -Encoding UTF8
        Write-Host "✅ JSON已导出到: $OutputFile" -ForegroundColor Green
    } elseif ($Format -eq "markdown") {
        $markdown = $data | Format-Markdown-Report
        if ([string]::IsNullOrEmpty($OutputFile)) {
            $OutputFile = "data-export-$([DateTime]::Now:yyyyMMdd-HHmmss).md"
        }

        $markdown | Out-File -FilePath $OutputFile -Encoding UTF8
        Write-Host "✅ Markdown已导出到: $OutputFile" -ForegroundColor Green
    } else {
        Write-Error "不支持的格式: $Format"
    }

    Write-Host "`n完成！" -ForegroundColor Green
}

# 主程序入口
switch ($Action) {
    "progress" {
        Run-ProgressView -Type $Type -Days $Days
    }
    "dashboard" {
        Run-Dashboard -Type $Type
    }
    "chart" {
        Run-Chart -Type $Type -Data $Data -Title "Chart"
    }
    "export" {
        Run-Export -Format $Format -Type $Type -OutputFile $OutputFile
    }
}
