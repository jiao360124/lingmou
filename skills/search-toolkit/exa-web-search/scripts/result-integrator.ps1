<#
.SYNOPSIS
搜索结果整合引擎 - 多源结果整合和排序

.DESCRIPTION
整合来自多个搜索源的结果，按权重和相关性排序，生成最终结果集。

.PARAMETER Results
各搜索源的结果数组

.PARAMeter Weights
来源权重配置

.PARAMeter Query
原始搜索查询

.EXAMPLE
$result = @(
    @{id="1"; title="React Hooks"; content="..."; source="local"; relevance=0.9},
    @{id="2"; title="React Hooks指南"; content="..."; source="web"; relevance=0.85}
)
Merge-Sources -Results $result -Weights $weights -Query "React Hooks"
#>

param(
    [Parameter(Mandatory=$true)]
    [array]$Results,

    [Parameter(Mandatory=$true)]
    [PSCustomObject]$Weights,

    [Parameter(Mandatory=$true)]
    [string]$Query
)

function Calculate-SourceWeight {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SourceName,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Weights
    )

    $sourceConfig = $Weights."$SourceName"
    if ($sourceConfig -and $sourceConfig.weight -ne $null) {
        return $sourceConfig.weight
    }

    # 默认权重
    switch ($SourceName) {
        "rag" { return 0.9 }
        "memory" { return 0.7 }
        "local" { return 0.6 }
        "web" { return 0.5 }
        "moltbook" { return 0.8 }
        "api" { return 0.4 }
        default { return 0.5 }
    }
}

function Merge-Sources {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Results,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Weights,

        [Parameter(Mandatory=$true)]
        [string]$Query
    )

    Write-Host "🔀 搜索结果整合" -ForegroundColor Cyan
    Write-Host "  查询: $Query" -ForegroundColor Yellow

    # 添加来源元数据
    foreach ($result in $Results) {
        $result | Add-Member -NotePropertyName 'source_weight' -NotePropertyValue (Calculate-SourceWeight -SourceName $result.source -Weights $Weights)

        # 计算综合评分
        if ($result.relevance -eq $null) {
            $result.relevance = 0.5
        }

        $result.relevance_score = ($result.relevance + $result.source_weight) / 2
    }

    # 统计各来源结果数
    $sourceStats = $Results | Group-Object -Property source | ForEach-Object {
        @{
            source = $_.Name
            count = $_.Count
        }
    }

    Write-Host "  来源统计:" -ForegroundColor Gray
    foreach ($stat in $sourceStats) {
        $icon = Get-SourceIcon -Source $stat.source
        Write-Host "    $icon $($stat.source): $($stat.count) 个结果" -ForegroundColor Gray
    }

    return $Results
}

function Sort-ByPriority {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Results
    )

    # 按综合评分排序
    $sorted = $Results | Sort-Object { $_.relevance_score } -Descending

    # 添加排名
    $ranked = @()
    $sorted | ForEach-Object { $i = 1 } | ForEach-Object {
        $item = $sorted[$ranked.Count]
        $item | Add-Member -NotePropertyName 'rank' -NotePropertyValue ($ranked.Count + 1)
        $ranked += $item
        $i++
    }

    return $ranked
}

function Generate-Summary {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Results,

        [Parameter(Mandatory=$true)]
        [string]$Format = "markdown"
    )

    $totalResults = $Results.Count
    $uniqueSources = ($Results | Select-Object -Unique -ExpandProperty source).Count
    $avgRelevance = ($Results | Measure-Object -Property relevance_score -Average).Average
    $maxRelevance = ($Results | Measure-Object -Property relevance_score -Maximum).Maximum

    if ($Format -eq "markdown") {
        $summary = @"
## 搜索结果汇总

**查询**: $(Split-Path -Leaf $Query)

**统计信息**:
- 总结果数: $totalResults
- 唯一来源: $uniqueSources
- 平均相关度: $(("{0:N2}" -f $avgRelevance * 100))%
- 最高相关度: $(("{0:N2}" -f $maxRelevance * 100))%

**来源分布**:
$(Generate-SourceDistribution -Results $Results)

**总计**: $($Results.Count) 个去重结果
"@

        return $summary
    } elseif ($Format -eq "json") {
        return @{
            summary = @{
                query = $Query
                total_results = $totalResults
                unique_sources = $uniqueSources
                avg_relevance = "{0:N2}" -f ($avgRelevance * 100)
                max_relevance = "{0:N2}" -f ($maxRelevance * 100)
                source_distribution = Generate-SourceDistribution -Results $Results -Format "json"
            }
        }
    }
}

function Generate-SourceDistribution {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Results,

        [Parameter(Mandatory=$false)]
        [string]$Format = "markdown"
    )

    $distribution = $Results | Group-Object -Property source | ForEach-Object {
        @{
            source = $_.Name
            count = $_.Count
            icon = Get-SourceIcon -Source $_.Name
        }
    }

    if ($Format -eq "markdown") {
        $markdown = ""
        foreach ($item in $distribution) {
            $markdown += "  • $($item.icon) $($item.source): $($item.count) 个结果`n"
        }
        return $markdown
    } elseif ($Format -eq "json") {
        return $distribution | ConvertTo-Json -Depth 10
    }
}

function Get-SourceIcon {
    param([string]$Source)

    $iconMap = @{
        "local" = "📁"
        "web" = "🌐"
        "memory" = "🧠"
        "rag" = "📚"
        "moltbook" = "👥"
        "api" = "🔌"
    }

    return $iconMap[$Source] -?? "📋"
}

function Merge-Sources {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Results,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Weights,

        [Parameter(Mandatory=$true)]
        [string]$Query
    )

    Write-Host "🔀 搜索结果整合" -ForegroundColor Cyan
    Write-Host "  查询: $Query" -ForegroundColor Yellow

    # 添加来源元数据
    foreach ($result in $Results) {
        $result | Add-Member -NotePropertyName 'source_weight' -NotePropertyValue (Calculate-SourceWeight -SourceName $result.source -Weights $Weights)

        # 计算综合评分
        if ($result.relevance -eq $null) {
            $result.relevance = 0.5
        }

        $result.relevance_score = ($result.relevance + $result.source_weight) / 2
    }

    # 统计各来源结果数
    $sourceStats = $Results | Group-Object -Property source | ForEach-Object {
        @{
            source = $_.Name
            count = $_.Count
        }
    }

    Write-Host "  来源统计:" -ForegroundColor Gray
    foreach ($stat in $sourceStats) {
        $icon = Get-SourceIcon -Source $stat.source
        Write-Host "    $icon $($stat.source): $($stat.count) 个结果" -ForegroundColor Gray
    }

    return $Results
}

function Sort-ByPriority {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Results
    )

    # 按综合评分排序
    $sorted = $Results | Sort-Object { $_.relevance_score } -Descending

    # 添加排名
    $ranked = @()
    $sorted | ForEach-Object { $i = 1 } | ForEach-Object {
        $item = $sorted[$ranked.Count]
        $item | Add-Member -NotePropertyName 'rank' -NotePropertyValue ($ranked.Count + 1)
        $ranked += $item
        $i++
    }

    return $ranked
}

function Generate-Summary {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Results,

        [Parameter(Mandatory=$true)]
        [string]$Format = "markdown"
    )

    $totalResults = $Results.Count
    $uniqueSources = ($Results | Select-Object -Unique -ExpandProperty source).Count
    $avgRelevance = ($Results | Measure-Object -Property relevance_score -Average).Average
    $maxRelevance = ($Results | Measure-Object -Property relevance_score -Maximum).Maximum

    if ($Format -eq "markdown") {
        $summary = @"
## 搜索结果汇总

**查询**: $(Split-Path -Leaf $Query)

**统计信息**:
- 总结果数: $totalResults
- 唯一来源: $uniqueSources
- 平均相关度: $(("{0:N2}" -f $avgRelevance * 100))%
- 最高相关度: $(("{0:N2}" -f $maxRelevance * 100))%

**来源分布**:
$(Generate-SourceDistribution -Results $Results)

**总计**: $($Results.Count) 个去重结果
"@

        return $summary
    } elseif ($Format -eq "json") {
        return @{
            summary = @{
                query = $Query
                total_results = $totalResults
                unique_sources = $uniqueSources
                avg_relevance = "{0:N2}" -f ($avgRelevance * 100)
                max_relevance = "{0:N2}" -f ($maxRelevance * 100)
                source_distribution = Generate-SourceDistribution -Results $Results -Format "json"
            }
        }
    }
}

function Generate-SourceDistribution {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Results,

        [Parameter(Mandatory=$false)]
        [string]$Format = "markdown"
    )

    $distribution = $Results | Group-Object -Property source | ForEach-Object {
        @{
            source = $_.Name
            count = $_.Count
            icon = Get-SourceIcon -Source $_.Name
        }
    }

    if ($Format -eq "markdown") {
        $markdown = ""
        foreach ($item in $distribution) {
            $markdown += "  • $($item.icon) $($item.source): $($item.count) 个结果`n"
        }
        return $markdown
    } elseif ($Format -eq "json") {
        return $distribution | ConvertTo-Json -Depth 10
    }
}

function Get-SourceIcon {
    param([string]$Source)

    $iconMap = @{
        "local" = "📁"
        "web" = "🌐"
        "memory" = "🧠"
        "rag" = "📚"
        "moltbook" = "👥"
        "api" = "🔌"
    }

    return $iconMap[$Source] -?? "📋"
}

# 主程序入口
if ($Results.Count -gt 0) {
    Merge-Sources -Results $Results -Weights $Weights -Query $Query
    $sorted = Sort-ByPriority -Results $Results
    $summary = Generate-Summary -Results $sorted -Format "markdown"

    Write-Host "`n$summary" -ForegroundColor Green

    return $sorted
} else {
    Write-Warning "没有搜索结果可整合"
    return @()
}
