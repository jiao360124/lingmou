<#
.SYNOPSIS
结果聚合模块 - 聚合多个Agent的结果

.DESCRIPTION
对多个Agent的执行结果进行合并、评分和格式化。

.PARAMeter Results
Agent执行结果列表

.PARAMeter Mode
聚合模式：merge, average, best

.EXAMPLE
.\result-aggregator.ps1 -Results $results -Mode "average"
#>

param(
    [Parameter(Mandatory=$true)]
    [array]$Results,

    [Parameter(Mandatory=$false)]
    [ValidateSet("merge", "average", "best", "consensus")]
    [string]$Mode = "merge"
)

function Calculate-Quality-Score {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Result,

        [Parameter(Mandatory=$true)]
        [string]$Criteria
    )

    $score = 0.5 # 基础分数

    # 根据标准评分
    switch ($Criteria) {
        "accuracy" {
            # 准确性评分
            if ($Result.accuracy -ge 0.9) { $score = 0.9 }
            elseif ($Result.accuracy -ge 0.7) { $score = 0.7 }
            elseif ($Result.accuracy -ge 0.5) { $score = 0.5 }
            else { $score = 0.3 }
        }
        "completeness" {
            # 完整性评分
            if ($Result.completeness -ge 0.9) { $score = 0.9 }
            elseif ($Result.completeness -ge 0.7) { $score = 0.7 }
            elseif ($Result.completeness -ge 0.5) { $score = 0.5 }
            else { $score = 0.3 }
        }
        "efficiency" {
            # 效率评分
            if ($Result.efficiency -ge 0.9) { $score = 0.9 }
            elseif ($Result.efficiency -ge 0.7) { $score = 0.7 }
            elseif ($Result.efficiency -ge 0.5) { $score = 0.5 }
            else { $score = 0.3 }
        }
    }

    return $score
}

function Aggregate-Merge {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Results
    )

    Write-Host "🔄 合并结果" -ForegroundColor Cyan

    $merged = @()
    $totalAccuracy = 0
    $totalCompleteness = 0
    $totalEfficiency = 0

    foreach ($result in $Results) {
        $totalAccuracy += $result.accuracy
        $totalCompleteness += $result.completeness
        $totalEfficiency += $result.efficiency

        $merged += $result
    }

    $averageAccuracy = if ($Results.Count -gt 0) { $totalAccuracy / $Results.Count } else { 0 }
    $averageCompleteness = if ($Results.Count -gt 0) { $totalCompleteness / $Results.Count } else { 0 }
    $averageEfficiency = if ($Results.Count -gt 0) { $totalEfficiency / $Results.Count } else { 0 }

    $aggregated = @{
        results = $merged
        total_results = $Results.Count
        average_accuracy = [math]::Round($averageAccuracy, 2)
        average_completeness = [math]::Round($averageCompleteness, 2)
        average_efficiency = [math]::Round($averageEfficiency, 2)
        quality_score = [math]::Round(($averageAccuracy + $averageCompleteness + $averageEfficiency) / 3, 2)
    }

    Write-Host "  合并结果数: $($Results.Count)" -ForegroundColor Green
    Write-Host "  平均准确率: $([math]::Round($averageAccuracy * 100, 1)))%" -ForegroundColor Green
    Write-Host "  平均完整度: $([math]::Round($averageCompleteness * 100, 1)))%" -ForegroundColor Green
    Write-Host "  平均效率: $([math]::Round($averageEfficiency * 100, 1)))%" -ForegroundColor Green
    Write-Host "  综合质量: $([math]::Round($aggregated.quality_score * 100, 1)))%" -ForegroundColor Green

    return $aggregated
}

function Aggregate-Average {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Results
    )

    Write-Host "📊 平均聚合" -ForegroundColor Cyan

    $averageAccuracy = ($Results | ForEach-Object { $_.accuracy } | Measure-Object -Average).Average
    $averageCompleteness = ($Results | ForEach-Object { $_.completeness } | Measure-Object -Average).Average
    $averageEfficiency = ($Results | ForEach-Object { $_.efficiency } | Measure-Object -Average).Average
    $qualityScore = [math]::Round(($averageAccuracy + $averageCompleteness + $averageEfficiency) / 3, 2)

    $aggregated = @{
        results = @()
        total_results = $Results.Count
        average_accuracy = [math]::Round($averageAccuracy, 2)
        average_completeness = [math]::Round($averageCompleteness, 2)
        average_efficiency = [math]::Round($averageEfficiency, 2)
        quality_score = $qualityScore
    }

    Write-Host "  结果数量: $($Results.Count)" -ForegroundColor Green
    Write-Host "  平均准确率: $([math]::Round($averageAccuracy * 100, 1)))%" -ForegroundColor Green
    Write-Host "  平均完整度: $([math]::Round($averageCompleteness * 100, 1)))%" -ForegroundColor Green
    Write-Host "  平均效率: $([math]::Round($averageEfficiency * 100, 1)))%" -ForegroundColor Green
    Write-Host "  综合质量: $([math]::Round($qualityScore * 100, 1)))%" -ForegroundColor Green

    return $aggregated
}

function Aggregate-Best {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Results,
        [Parameter(Mandatory=$false)]
        [string]$Criteria = "accuracy"
    )

    Write-Host "⭐ 最佳结果聚合" -ForegroundColor Cyan

    # 计算每个结果的评分
    foreach ($result in $Results) {
        $result.qualityScore = Calculate-Quality-Score -Result $result -Criteria $Criteria
    }

    # 选择最佳结果
    $bestResult = $Results | Sort-Object { $_.qualityScore } -Descending | Select-Object -First 1

    $aggregated = @{
        result = $bestResult
        total_results = $Results.Count
        selected_criteria = $Criteria
        best_quality_score = $bestResult.qualityScore
    }

    Write-Host "  选择标准: $Criteria" -ForegroundColor Yellow
    Write-Host "  结果数量: $($Results.Count)" -ForegroundColor Green
    Write-Host "  最佳质量: $([math]::Round($bestResult.qualityScore * 100, 1)))%" -ForegroundColor Green
    Write-Host "  最佳结果: $($bestResult.name)" -ForegroundColor Green

    return $aggregated
}

function Aggregate-Consensus {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Results
    )

    Write-Host "🤝 一致性聚合" -ForegroundColor Cyan

    # 检查结果一致性
    $accuracies = $Results | ForEach-Object { $_.accuracy }
    $completeness = $Results | ForEach-Object { $_.completeness }

    $accuracyRange = ($accuracies | Measure-Object -Maximum).Maximum - ($accuracies | Measure-Object -Minimum).Minimum
    $completenessRange = ($completeness | Measure-Object -Maximum).Maximum - ($completeness | Measure-Object -Minimum).Minimum

    $consistency = if (($accuracyRange + $completenessRange) -lt 0.2) { "高" } else { "中" }

    $aggregated = @{
        results = $Results
        total_results = $Results.Count
        consistency = $consistency
        accuracy_range = [math]::Round($accuracyRange, 2)
        completeness_range = [math]::Round($completenessRange, 2)
        consensus = if ($consistency -eq "高") { "所有结果一致" } else { "结果有一定差异" }
    }

    Write-Host "  结果一致性: $consistency" -ForegroundColor Green
    Write-Host "  准确率范围: ±$([math]::Round($accuracyRange * 100, 1)))%" -ForegroundColor Green
    Write-Host "  完整度范围: ±$([math]::Round($completenessRange * 100, 1)))%" -ForegroundColor Green
    Write-Host "  聚合结论: $($aggregated.consensus)" -ForegroundColor Green

    return $aggregated
}

function Format-Result-Report {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Aggregated
    )

    $report = "# Agent协作结果报告`n`n"

    switch ($Aggregated.PSObject.Properties.Name) {
        "results" {
            # 合并模式
            $report += "## 合并结果`n`n"
            $report += "- **结果数量**: $($Aggregated.total_results)`n"
            $report += "- **平均准确率**: $([math]::Round($Aggregated.average_accuracy * 100, 1)))%`n"
            $report += "- **平均完整度**: $([math]::Round($Aggregated.average_completeness * 100, 1)))%`n"
            $report += "- **平均效率**: $([math]::Round($Aggregated.average_efficiency * 100, 1)))%`n"
            $report += "- **综合质量**: $([math]::Round($Aggregated.quality_score * 100, 1)))%`n`n"

            $report += "## 详细结果`n`n"
            $report += "| 排名 | Agent | 准确率 | 完整度 | 效率 | 质量 |`n"
            $report += "|------|-------|--------|--------|------|------|`n"

            foreach ($result in $Aggregated.results) {
                $report += "| - | $($result.name) | $([math]::Round($result.accuracy * 100, 1)))% | $([math]::Round($result.completeness * 100, 1)))% | $([math]::Round($result.efficiency * 100, 1)))% | $([math]::Round($result.quality_score * 100, 1)))% |`n"
            }
        }
        "result" {
            # 最佳模式
            $report += "## 最佳结果`n`n"
            $report += "- **选择标准**: $($Aggregated.selected_criteria)`n"
            $report += "- **结果数量**: $($Aggregated.total_results)`n"
            $report += "- **最佳质量**: $([math]::Round($Aggregated.best_quality_score * 100, 1)))%`n`n"

            $report += "## Agent: $($Aggregated.result.name)`n`n"
            $report += "- **准确率**: $([math]::Round($Aggregated.result.accuracy * 100, 1)))%`n"
            $report += "- **完整度**: $([math]::Round($Aggregated.result.completeness * 100, 1)))%`n"
            $report += "- **效率**: $([math]::Round($Aggregated.result.efficiency * 100, 1)))%`n"
        }
        "consistency" {
            # 一致性模式
            $report += "## 一致性分析`n`n"
            $report += "- **结果一致性**: $($Aggregated.consistency)`n"
            $report += "- **准确率范围**: ±$([math]::Round($Aggregated.accuracy_range * 100, 1)))%`n"
            $report += "- **完整度范围**: ±$([math]::Round($Aggregated.completeness_range * 100, 1)))%`n`n"

            $report += "## 聚合结论`n`n"
            $report += "**$($Aggregated.consensus)**`n`n"

            $report += "## 详细结果`n`n"
            $report += "| 排名 | Agent | 准确率 | 完整度 |`n"
            $report += "|------|-------|--------|--------|`n"

            foreach ($result in $Aggregated.results) {
                $report += "| - | $($result.name) | $([math]::Round($result.accuracy * 100, 1)))% | $([math]::Round($result.completeness * 100, 1)))% |`n"
            }
        }
    }

    return $report
}

# 主程序入口
$aggregated = switch ($Mode) {
    "merge" { Aggregate-Merge -Results $Results }
    "average" { Aggregate-Average -Results $Results }
    "best" { Aggregate-Best -Results $Results }
    "consensus" { Aggregate-Consensus -Results $Results }
}

# 格式化报告
$report = Format-Result-Report -Aggregated $aggregated

Write-Host "`n✓ 结果聚合完成" -ForegroundColor Green
Write-Host "`n$report" -ForegroundColor Cyan

return $aggregated
