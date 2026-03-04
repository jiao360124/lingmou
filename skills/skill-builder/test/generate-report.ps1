# 报告生成器

# @Author: 灵眸
# @Version: 1.0.0
# @Date: 2026-02-13

param(
    [Parameter(Mandatory=$true)]
    [string]$SkillName,

    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false
)

# 获取脚本路径
$ScriptPath = $PSScriptRoot
$SkillsDir = "$ScriptPath/../../.."
$SkillPath = "$SkillsDir/$SkillName"
$MetricFile = "$SkillsDir/skills/performance-metrics/data/metrics.json"

# 初始化结果
$Result = @{
    Success = $true
    SkillName = $SkillName
    DryRun = $DryRun
    StartTime = Get-Date
    EndTime = $null
    Duration = 0
    Messages = @()
    Reports = @()
}

# 日志函数
function Write-Log {
    param([string]$Message, [ValidateSet("INFO", "SUCCESS", "ERROR", "WARNING", "DEBUG")]
    [string]$Level = "INFO")

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Prefix = "[$Timestamp] [$Level]"

    switch ($Level) {
        "INFO"    { Write-Host "$Prefix $Message" -ForegroundColor Cyan }
        "SUCCESS" { Write-Host "$Prefix $Message" -ForegroundColor Green }
        "ERROR"   { Write-Host "$Prefix $Message" -ForegroundColor Red }
        "WARNING" { Write-Host "$Prefix $Message" -ForegroundColor Yellow }
        "DEBUG"   { Write-Host "$Prefix $Message" -ForegroundColor DarkGray }
    }

    $Result.Messages += "$Prefix $Message"
}

try {
    Write-Log "报告生成器启动" "INFO"

    # 加载分析数据
    $AnalysisFile = "$SkillPath/reports/analysis-latest.json"

    if (-not (Test-Path $AnalysisFile)) {
        # 尝试查找最近的文件
        $ReportsDir = "$SkillPath/reports"
        if (Test-Path $ReportsDir) {
            $ReportFiles = Get-ChildItem -Path $ReportsDir -Filter "analysis-*.json" | Sort-Object LastWriteTime -Descending
            if ($ReportFiles.Count -gt 0) {
                $AnalysisFile = $ReportFiles[0].FullName
            }
        }
    }

    if (-not (Test-Path $AnalysisFile)) {
        throw "分析数据文件不存在"
    }

    $Analysis = Get-Content -Path $AnalysisFile | ConvertFrom-Json

    Write-Log "加载分析数据" "SUCCESS"

    if ($DryRun) {
        Write-Log "Dry Run 模式：生成模拟报告" "DEBUG"

        $Analysis.CopyTo([ref]$Result.Analysis)

        $Result.Reports += @{
            Type = "test"
            Format = "markdown"
            Content = @"
# $SkillName 测试报告

**生成时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**Dry Run**: 是

## 测试结果

- **总测试数**: 3
- **通过**: 3
- **失败**: 0
- **跳过**: 0
- **通过率**: 100%

## 测试列表

1. ✓ 基础功能
2. ✓ 错误处理
3. ✓ 性能测试

---
**状态**: Dry Run模式，未实际运行测试
"@
        }

        $Result.Success = $true
        return $Result
    }

    # 1. 生成测试报告
    Write-Log "生成测试报告..." "DEBUG"

    $TestReportFile = "$SkillPath/reports/test-report-latest.md"

    $TestContent = @"
# $SkillName 测试报告

**生成时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## 测试摘要

| 指标 | 数值 |
|------|------|
| 总测试数 | $($Analysis.Tests.Count) |
| 通过 | $($Analysis.Passed) |
| 失败 | $($Analysis.Failed) |
| 跳过 | $($Analysis.Skipped) |
| 通过率 | $([math]::Round(($Analysis.Passed / $Analysis.Tests.Count) * 100, 2))% |

## 测试结果

"@

    if ($Analysis.Tests.Count -gt 0) {
        foreach ($Test in $Analysis.Tests) {
            $StatusIcon = switch ($Test.Status) {
                "passed" { "✓" }
                "failed" { "✗" }
                "skipped" { "⊘" }
            }

            $StatusColor = switch ($Test.Status) {
                "passed" { "Green" }
                "failed" { "Red" }
                "skipped" { "Yellow" }
            }

            $TestContent += "### $StatusIcon $Test.Name
**状态**: `$($Test.Status)`
"@

            if ($Test.Status -eq "passed") {
                if ($Test.Duration -gt 0) {
                    $TestContent += "**耗时**: $([math]::Round($Test.Duration, 2))秒
"@
                }
            } else {
                $TestContent += "**错误**: $($Test.Error)
"@
            }

            $TestContent += "-"

            if ($Test.Output) {
                $TestContent += "**输出**: $($Test.Output.Substring(0, [Math]::Min(100, $Test.Output.Length)))
"@
            }
        }
    }

    $TestContent += "-"

    # 保存测试报告
    $TestContent | Out-File -FilePath $TestReportFile -Encoding UTF8
    $Result.Reports += @{
        Type = "test"
        Format = "markdown"
        Path = $TestReportFile
        Content = $TestContent
    }

    Write-Log "测试报告已保存: $TestReportFile" "SUCCESS"

    # 2. 生成性能报告
    Write-Log "生成性能报告..." "DEBUG"

    $PerfReportFile = "$SkillPath/reports/performance-report-latest.md"

    $PerfContent = "# $SkillName 性能报告

**生成时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## 性能指标

"@

    if ($Analysis.Performance.Count -gt 0) {
        foreach ($Metric in $Analysis.Performance) {
            $PerfContent += "### $($Metric.Metric)
**数值**: $($Metric.Value) $($Metric.Unit)

"@

            if ($Metric.Min -ne $null) {
                $PerfContent += "- 最小: $($Metric.Min)$($Metric.Unit)
"
            }

            if ($Metric.Max -ne $null) {
                $PerfContent += "- 最大: $($Metric.Max)$($Metric.Unit)
"
            }

            if ($Metric.Median -ne $null) {
                $PerfContent += "- 中位数: $($Metric.Median)$($Metric.Unit)
"
            }

            if ($Metric.SuccessRate -ne $null) {
                $PerfContent += "- 成功率: $([math]::Round($Metric.SuccessRate, 2))%
"
            }

            $PerfContent += "-"
        }
    }

    # 3. 生成代码质量报告
    Write-Log "生成代码质量报告..." "DEBUG"

    $QualityReportFile = "$SkillPath/reports/quality-report-latest.md"

    $QualityContent = "# $SkillName 代码质量报告

**生成时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## 代码质量评分

**总分**: $($Analysis.Quality.Score)/$($Analysis.Quality.MaxScore)

"@

    if ($Analysis.Quality.Criteria.Count -gt 0) {
        $QualityContent += "### 评分标准

"@

        foreach ($Criterion in $Analysis.Quality.Criteria) {
            $StatusIcon = switch ($Criterion.Pass) {
                $true { "✓" }
                $false { "✗" }
            }

            $StatusColor = switch ($Criterion.Pass) {
                $true { "Green" }
                $false { "Red" }
            }

            $QualityContent += "### $StatusIcon $($Criterion.Type)
**描述**: $($Criterion.Reason)
**得分**: $($Criterion.Score)/$($Criterion.Score + ($Criterion.Pass ? 0 : $Criterion.Score))
**状态**: `$($Criterion.Pass ? "通过" : "失败")`
"@
        }
    }

    # 4. 生成改进建议报告
    Write-Log "生成改进建议报告..." "DEBUG"

    $RecommendationReportFile = "$SkillPath/reports/recommendation-report-latest.md"

    $RecContent = "# $SkillName 改进建议

**生成时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## 改进建议

"@

    if ($Analysis.Recommendations.Count -gt 0) {
        foreach ($Rec in $Analysis.Recommendations) {
            $PriorityIcon = switch ($Rec.Priority) {
                "high" { "🔴" }
                "medium" { "🟡" }
                "low" { "🟢" }
            }

            $RecContent += "### $PriorityIcon 优先级: $($Rec.Priority)
**分类**: $($Rec.Category)
**建议**: $($Rec.Action)
**原因**: $($Rec.Reason)

"@
        }
    } else {
        $RecContent += "当前未发现明显的改进建议。

"@
    }

    # 保存所有报告
    $PerfContent | Out-File -FilePath $PerfReportFile -Encoding UTF8
    $QualityContent | Out-File -FilePath $QualityReportFile -Encoding UTF8
    $RecContent | Out-File -FilePath $RecommendationReportFile -Encoding UTF8

    $Result.Reports += @{
        Type = "performance"
        Format = "markdown"
        Path = $PerfReportFile
        Content = $PerfContent
    }

    $Result.Reports += @{
        Type = "quality"
        Format = "markdown"
        Path = $QualityReportFile
        Content = $QualityContent
    }

    $Result.Reports += @{
        Type = "recommendation"
        Format = "markdown"
        Path = $RecommendationReportFile
        Content = $RecContent
    }

    Write-Log "性能报告已保存: $PerfReportFile" "SUCCESS"
    Write-Log "质量报告已保存: $QualityReportFile" "SUCCESS"
    Write-Log "建议报告已保存: $RecommendationReportFile" "SUCCESS"

    # 设置最终状态
    $Result.EndTime = Get-Date
    $Result.Duration = ($Result.EndTime - $Result.StartTime).TotalSeconds

    Write-Log "报告生成完成" "SUCCESS"
    Write-Log "生成报告数: $($Result.Reports.Count)" "SUCCESS"
    Write-Log "执行时间: $([math]::Round($Result.Duration, 2))秒" "SUCCESS"

} catch {
    $Result.Success = $false
    $Result.Errors += $_.Exception.Message
    $Result.Errors += $_.ScriptStackTrace

    Write-Log "报告生成失败: $($_.Exception.Message)" "ERROR"

} finally {
    return $Result
}
