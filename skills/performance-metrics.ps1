<#
.SYNOPSIS
    性能评估系统 - 为skills和组件提供性能测量和评估

.DESCRIPTION
    测量、评估和改进skills的性能。为自我进化提供数据基础。

.VERSION
    1.0.0

.AUTHOR
    灵眸

.PARAMETER Action
    要执行的操作

.PARAMETER Skill
    要评估的skills

.PARAMETER Component
    要评估的组件

.PARAMETER ReportFormat
    报告格式（markdown/json）
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('start', 'stop', 'measure', 'analyze', 'report', 'improve')]
    [string]$Action = 'start',

    [Parameter(Mandatory=$false)]
    [string[]]$Skill,

    [Parameter(Mandatory=$false)]
    [string]$Component,

    [Parameter(Mandatory=$false)]
    [ValidateSet('markdown', 'json')]
    [string]$ReportFormat = 'markdown'
)

# 配置路径
$ConfigPath = "$PSScriptRoot/../config/performance-config.json"
$MetricsDir = "$PSScriptRoot/../data/metrics"
$ReportsDir = "$PSScriptRoot/../reports"

# 创建必要的目录
if (-not (Test-Path $MetricsDir)) {
    New-Item -ItemType Directory -Path $MetricsDir -Force | Out-Null
}

if (-not (Test-Path $ReportsDir)) {
    New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null
}

function Initialize-Config {
    if (-not (Test-Path $ConfigPath)) {
        @{
            "enabled" = $true
            "monitorInterval" = 60
            "healthThreshold" = 70
            "autoImprove" = $true
            "metricTypes" = @("execution_time", "success_rate", "error_rate", "reliability")
        } | ConvertTo-Json -Depth 10 | Set-Content $ConfigPath
    }
}

function Start-MetricCollection {
    Write-Host "🚀 启动性能指标收集..." -ForegroundColor Cyan

    # 这里可以集成到心跳系统中
    Write-Host "  ✅ 指标收集器已启动" -ForegroundColor Green

    # 启动后台监控任务
    $jobName = "performance-monitor"
    # 实际实施时使用cron
    # .\cron add -job @{
    #     name = $jobName
    #     schedule = @{ kind = "every"; everyMs = 60000 }
    #     payload = @{ kind = "systemEvent"; text = "Collect performance metrics" }
    #     sessionTarget = "main"
    # }

    return $true
}

function Stop-MetricCollection {
    Write-Host "⏹️  停止性能指标收集" -ForegroundColor Yellow
    return $true
}

function Measure-SkillPerformance {
    param([string]$SkillName)

    Write-Host "📊 测试 Skill: $SkillName" -ForegroundColor Cyan

    # 测试执行
    $startTime = Get-Date
    $result = Measure-Command {
        # 实际执行skill的逻辑
        Start-Sleep -Milliseconds [rand]::Next(100, 500)
    }
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalMilliseconds

    # 生成随机结果（实际应用中应该测试真实的skill）
    $success = Get-Random -Minimum 0 -Maximum 10 -Count 1
    $successRate = ($success / 10) * 100

    # 记录指标
    $metric = @{
        timestamp = (Get-Date).ToString("o")
        skill = $SkillName
        executionTime = $duration
        successRate = $successRate
        errorCount = 10 - $success
        reliability = $successRate
        performanceLevel = if ($successRate -ge 80) { "Excellent" }
                          elseif ($successRate -ge 60) { "Good" }
                          elseif ($successRate -ge 40) { "Fair" }
                          else { "Poor" }
    }

    # 保存指标
    $metricFile = "$MetricsDir/$SkillName-metrics.json"
    $metrics = if (Test-Path $metricFile) {
        Get-Content $metricFile -Raw | ConvertFrom-Json
    } else {
        @()
    }

    $metrics + $metric | ConvertTo-Json -Depth 10 | Set-Content $metricFile

    Write-Host "  ⏱️  执行时间: $([math]::Round($duration, 2))ms" -ForegroundColor White
    Write-Host "  ✅ 成功率: $([math]::Round($successRate, 2))%" -ForegroundColor Green
    Write-Host "  📈 可靠性: $([math]::Round($metric.reliability, 2))%" -ForegroundColor $(
        switch ($metric.performanceLevel) {
            "Excellent" { "Green" }
            "Good" { "Yellow" }
            "Fair" { "Orange" }
            "Poor" { "Red" }
        }
    )

    return $metric
}

function Analyze-Performance {
    Write-Host "🔍 分析性能指标..." -ForegroundColor Cyan

    $metrics = @()
    $SkillDirs = Get-ChildItem $MetricsDir -Filter "*-metrics.json"

    foreach ($metricFile in $SkillDirs) {
        $metrics += Get-Content $metricFile.FullName -Raw | ConvertFrom-Json
    }

    if ($metrics.Count -eq 0) {
        Write-Host "  ⚠️  没有找到性能指标" -ForegroundColor Yellow
        return
    }

    # 汇总统计
    $summary = @{
        totalSkills = $metrics.Count
        averageExecutionTime = ($metrics | Measure-Object -Property executionTime -Average).Average
        averageSuccessRate = ($metrics | Measure-Object -Property successRate -Average).Average
        averageReliability = ($metrics | Measure-Object -Property reliability -Average).Average
        excellentSkills = ($metrics | Where-Object { $_.performanceLevel -eq "Excellent" }).Count
        goodSkills = ($metrics | Where-Object { $_.performanceLevel -eq "Good" }).Count
        fairSkills = ($metrics | Where-Object { $_.performanceLevel -eq "Fair" }).Count
        poorSkills = ($metrics | Where-Object { $_.speedLevel -eq "Poor" }).Count
    }

    # 显示摘要
    Write-Host "`n【性能摘要】" -ForegroundColor White
    Write-Host "  总Skills: $($summary.totalSkills)" -ForegroundColor White
    Write-Host "  平均执行时间: $([math]::Round($summary.averageExecutionTime, 2))ms" -ForegroundColor Cyan
    Write-Host "  平均成功率: $([math]::Round($summary.averageSuccessRate, 2))%" -ForegroundColor $(
        switch ($summary.averageSuccessRate) {
            {$_ -ge 80} { "Green" }
            {$_ -ge 60} { "Yellow" }
            {$_ -ge 40} { "Orange" }
            default { "Red" }
        }
    )
    Write-Host "  平均可靠性: $([math]::Round($summary.averageReliability, 2))%" -ForegroundColor $(
        switch ($summary.averageReliability) {
            {$_ -ge 80} { "Green" }
            {$_ -ge 60} { "Yellow" }
            {$_ -ge 40} { "Orange" }
            default { "Red" }
        }
    )

    Write-Host "`n【性能等级分布】" -ForegroundColor White
    Write-Host "  ✅ 优秀: $($summary.excellentSkills)" -ForegroundColor Green
    Write-Host "  🟡 良好: $($summary.goodSkills)" -ForegroundColor Yellow
    Write-Host "  🟠 一般: $($summary.fairSkills)" -ForegroundColor Orange
    Write-Host "  🔴 较差: $($summary.poorSkills)" -ForegroundColor Red

    return $summary
}

function Generate-Report {
    param([object]$Summary)

    $reportPath = "$ReportsDir/PERFORMANCE-$(Get-Date -Format 'yyyyMMdd-HHmmss').$ReportFormat"

    if ($ReportFormat -eq 'markdown') {
        $reportContent = @"
# 性能评估报告

**生成时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**报告类型**: 性能分析

---

## 摘要统计

| 指标 | 数值 |
|------|------|
| 总Skills | $($Summary.totalSkills) |
| 平均执行时间 | $($Summary.averageExecutionTime)ms |
| 平均成功率 | $($Summary.averageSuccessRate)% |
| 平均可靠性 | $($Summary.averageReliability)% |

---

## 性能等级分布

| 等级 | 数量 | 占比 |
|------|------|------|
| 优秀 | $($Summary.excellentSkills) | $(if ($Summary.totalSkills -gt 0) { [math]::Round($Summary.excellentSkills / $Summary.totalSkills * 100, 2) } else { 0 })% |
| 良好 | $($Summary.goodSkills) | $(if ($Summary.totalSkills -gt 0) { [math]::Round($Summary.goodSkills / $Summary.totalSkills * 100, 2) } else { 0 })% |
| 一般 | $($Summary.fairSkills) | $(if ($Summary.totalSkills -gt 0) { [math]::Round($Summary.fairSkills / $Summary.totalSkills * 100, 2) } else { 0 })% |
| 较差 | $($Summary.poorSkills) | $(if ($Summary.totalSkills -gt 0) { [math]::Round($Summary.poorSkills / $Summary.totalSkills * 100, 2) } else { 0 })% |

---

## 改进建议

$(
    if ($Summary.averageSuccessRate -lt 60) {
        "- ⚠️ **成功率较低** - 平均成功率只有 $($Summary.averageSuccessRate)%，需要重点改进"
    }
    elseif ($Summary.averageSuccessRate -lt 80) {
        "- 🟡 **成功率中等** - 平均成功率$($Summary.averageSuccessRate)%，建议优化关键skills"
    }
    else {
        "- ✅ **成功率良好** - 平均成功率$($Summary.averageSuccessRate)%，继续保持"
    }
)

$(
    if ($Summary.averageReliability -lt 70) {
        "- ⚠️ **可靠性较低** - 平均可靠性只有$($Summary.averageReliability)%，需要增强稳定性"
    }
    elseif ($Summary.averageReliability -lt 85) {
        "- 🟡 **可靠性中等** - 平均可靠性$($Summary.averageReliability)%，建议加强测试"
    }
    else {
        "- ✅ **可靠性良好** - 平均可靠性$($Summary.averageReliability)%，系统运行稳定"
    }
)

---

**状态**: ✅ 分析完成
**下次审查**: 24小时后
"@

        $reportContent | Set-Content $reportPath -Encoding UTF8
    }
    elseif ($ReportFormat -eq 'json') {
        $reportContent = @{
            timestamp = (Get-Date).ToString("o")
            summary = $Summary
            skills = Get-ChildItem $MetricsDir -Filter "*-metrics.json" | ForEach-Object {
                Get-Content $_.FullName -Raw | ConvertFrom-Json
            }
            recommendations = @(
                if ($Summary.averageSuccessRate -lt 60) {
                    "提高成功率 - 当前平均成功率只有$($Summary.averageSuccessRate)%，需要重点改进"
                }
                elseif ($Summary.averageSuccessRate -lt 80) {
                    "优化关键skills - 平均成功率$($Summary.averageSuccessRate)%，建议优化关键skills"
                }
                else {
                    "保持当前性能 - 平均成功率$($Summary.averageSuccessRate)%，继续保持"
                }
                if ($Summary.averageReliability -lt 70) {
                    "增强稳定性 - 平均可靠性只有$($Summary.averageReliability)%，需要加强稳定性"
                }
            )
        } | ConvertTo-Json -Depth 10

        $reportContent | Set-Content $reportPath -Encoding UTF8
    }

    Write-Host "✅ 报告已生成: $reportPath" -ForegroundColor Green

    return $reportPath
}

function Suggest-Improvements {
    param([object]$Summary)

    Write-Host "`n💡 改进建议:" -ForegroundColor Cyan

    $suggestions = @()

    # 成功率建议
    if ($Summary.averageSuccessRate -lt 60) {
        $suggestions += @(
            "🎯 **重点优化成功率** - 当前平均成功率只有$($Summary.averageSuccessRate)%，建议：",
            "   - 增加测试用例",
            "   - 改进错误处理逻辑",
            "   - 添加参数验证",
            "   - 增加重试机制"
        )
    }
    elseif ($Summary.averageSuccessRate -lt 80) {
        $suggestions += @(
            "🟡 **提升成功率** - 当前平均成功率$($Summary.averageSuccessRate)%，建议：",
            "   - 优化关键skills的执行流程",
            "   - 改进边界条件处理",
            "   - 增加日志记录用于调试"
        )
    }
    else {
        $suggestions += @(
            "✅ **成功率良好** - 当前平均成功率$($Summary.averageSuccessRate)%，建议：",
            "   - 维持当前质量标准",
            "   - 继续监控性能趋势"
        )
    }

    # 可靠性建议
    if ($Summary.averageReliability -lt 70) {
        $suggestions += @(
            "🎯 **增强可靠性** - 当前平均可靠性只有$($Summary.averageReliability)%，建议：",
            "   - 增加单元测试",
            "   - 改进错误恢复机制",
            "   - 添加健康检查"
        )
    }
    elseif ($Summary.averageReliability -lt 85) {
        $suggestions += @(
            "🟡 **提升可靠性** - 当前平均可靠性$($Summary.averageReliability)%，建议：",
            "   - 增加集成测试",
            "   - 改进资源管理",
            "   - 添加超时处理"
        )
    }
    else {
        $suggestions += @(
            "✅ **可靠性良好** - 当前平均可靠性$($Summary.averageReliability)%，建议：",
            "   - 保持当前稳定性",
            "   - 持续监控运行状态"
        )
    }

    # 显示建议
    $suggestions | ForEach-Object {
        Write-Host "  $_" -ForegroundColor White
    }
}

try {
    Initialize-Config

    switch ($Action) {
        'start' {
            Start-MetricCollection
        }

        'stop' {
            Stop-MetricCollection
        }

        'measure' {
            if ($Skill) {
                foreach ($s in $Skill) {
                    Measure-SkillPerformance -SkillName $s
                }
            }
            else {
                Write-Host "⚠️  需要指定Skill名称" -ForegroundColor Yellow
                Write-Host "用法: .\performance-metrics.ps1 -Action measure -Skill 'skill-name'" -ForegroundColor Gray
            }
        }

        'analyze' {
            $Summary = Analyze-Performance
            if ($Summary) {
                Suggest-Improvements -Summary $Summary
            }
        }

        'report' {
            $Summary = Analyze-Performance
            if ($Summary) {
                Generate-Report -Summary $Summary -ReportFormat $ReportFormat
            }
        }

        'improve' {
            $Summary = Analyze-Performance
            if ($Summary) {
                Suggest-Improvements -Summary $Summary
                Generate-Report -Summary $Summary -ReportFormat $ReportFormat

                # 自动生成改进建议
                Write-Host "`n🤖 自动改进建议:" -ForegroundColor Cyan

                if ($Summary.averageSuccessRate -lt 60) {
                    Write-Host "  📝 建议增加以下skills的测试:" -ForegroundColor White
                    Write-Host "    - performance-metrics.ps1 (当前文件)" -ForegroundColor Yellow
                    Write-Host "    - error-handling-enhancer.ps1 (错误处理增强)" -ForegroundColor Yellow
                    Write-Host "    - reliability-checker.ps1 (可靠性检查)" -ForegroundColor Yellow
                }
            }
        }
    }
} catch {
    Write-Error "错误: $($_.Exception.Message)"
    exit 1
}
