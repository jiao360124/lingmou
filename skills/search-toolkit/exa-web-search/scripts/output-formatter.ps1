<#
.SYNOPSIS
输出格式化引擎 - 生成搜索结果的可读格式

.DESCRIPTION
将搜索结果格式化为Markdown、JSON或表格格式，提供清晰的展示。

.PARAMeter Results
搜索结果数组

.PARAMeter Format
输出格式（markdown, json, table）

.PARAMeter Query
原始搜索查询

.EXAMPLE
Format-Results -Results $results -Format "markdown" -Query "React hooks"
#>

param(
    [Parameter(Mandatory=$true)]
    [array]$Results,

    [Parameter(Mandatory=$false)]
    [string]$Format = "markdown",

    [Parameter(Mandatory=$true)]
    [string]$Query
)

function Format-Results {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Results,

        [Parameter(Mandatory=$false)]
        [string]$Format = "markdown",

        [Parameter(Mandatory=$true)]
        [string]$Query
    )

    if ($Results.Count -eq 0) {
        return "# 无搜索结果`n`n查询: $Query`n未找到任何结果。"
    }

    switch ($Format) {
        "markdown" {
            return Format-Markdown -Results $Results -Query $Query
        }
        "json" {
            return Format-Json -Results $Results -Query $Query
        }
        "table" {
            return Format-Table -Results $Results
        }
        default {
            return Format-Markdown -Results $Results -Query $Query
        }
    }
}

function Format-Markdown {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Results,

        [Parameter(Mandatory=$true)]
        [string]$Query
    )

    $markdown = @"
# 智能搜索结果

## 查询
**$Query**

## 统计信息
- **总结果数**: $($Results.Count) 个
- **平均相关度**: $(("{0:N2}" -f ($Results | Measure-Object -Property relevance_score -Average).Average * 100))%
- **最高相关度**: $(("{0:N2}" -f ($Results | Measure-Object -Property relevance_score -Maximum).Maximum * 100))%

## 来源分布
$(Get-SourceDistribution -Results $Results)

---

## 结果列表
"@

    foreach ($result in $Results) {
        $icon = Get-SourceIcon -Source $result.source
        $rank = $result.rank

        $markdown += @"
### $rank. $icon $($result.title) [$($result.source)](https://example.com)

$($result.snippet -replace '\n', ' ')

**相关度**: $(("{0:N2}" -f ($result.relevance_score * 100)))% | **来源权重**: $(("{0:N2}" -f ($result.source_weight * 100)))%

---
"@
    }

    $markdown += @"
**总计**: $($Results.Count) 个去重结果

---
*搜索时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')*
"@

    return $markdown
}

function Format-Json {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Results,

        [Parameter(Mandatory=$true)]
        [string]$Query
    )

    $resultData = @()
    foreach ($result in $Results) {
        $item = @{
            rank = $result.rank
            title = $result.title
            source = $result.source
            source_weight = "{0:N2}" -f ($result.source_weight * 100)
            relevance = "{0:N2}" -f ($result.relevance_score * 100)
            url = $result.url
            snippet = $result.snippet
            cluster_id = $result.cluster_id
            similar_count = $result.similar_count
        }
        $resultData += $item
    }

    $output = @{
        query = $Query
        total_results = $Results.Count
        average_relevance = "{0:N2}" -f (($Results | Measure-Object -Property relevance_score -Average).Average * 100)
        max_relevance = "{0:N2}" -f (($Results | Measure-Object -Property relevance_score -Maximum).Maximum * 100)
        results = $resultData
        search_time = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    }

    return $output | ConvertTo-Json -Depth 10
}

function Format-Table {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Results
    )

    $table = "排名 | 来源 | 标题 | 相关度 | 来源权重"
    $separator = "-----|------|------|--------|------------"

    foreach ($result in $Results) {
        $icon = Get-SourceIcon -Source $result.source
        $title = $result.title
        $relevance = "{0:N2}" -f ($result.relevance_score * 100)
        $weight = "{0:N2}" -f ($result.source_weight * 100)

        $table += "`n$($result.rank) | $icon $($result.source) | $title | $relevance% | $weight%"
    }

    return $table
}

function Get-SourceDistribution {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Results
    )

    $distribution = $Results | Group-Object -Property source | ForEach-Object {
        @{
            source = $_.Name
            count = $_.Count
            icon = Get-SourceIcon -Source $_.Name
        }
    }

    $markdown = ""
    foreach ($item in $distribution) {
        $markdown += "  • $($item.icon) $($item.source): $($item.count) 个结果`n"
    }

    return $markdown
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
Format-Results -Results $Results -Format $Format -Query $Query
