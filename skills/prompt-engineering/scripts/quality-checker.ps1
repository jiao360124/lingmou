<#
.SYNOPSIS
Prompt Quality Checker

.DESCRIPTION
对提示词进行质量评估，使用5维度评分系统
- 清晰度 (30%)
- 完整性 (25%)
- 结构 (20%)
- 风格 (15%)
- 一致性 (10%)

.NOTES
Author: OpenClaw Assistant
Date: 2026-02-13
Version: 1.0.0
#>

$modulePath = $PSScriptRoot
$rulesPath = Join-Path $modulePath "data/quality-rules.json"

# 加载质量规则
function Get-QualityRules {
    if (Test-Path $rulesPath) {
        $rules = Get-Content $rulesPath -Raw | ConvertFrom-Json
        return $rules.rules
    } else {
        # 默认规则
        return @(
            @{ name = "clarity"; weight = 0.30; criteria = @("明确的目标", "具体的输出") }
            @{ name = "completeness"; weight = 0.25; criteria = @("足够的上下文", "定义的约束") }
            @{ name = "structure"; weight = 0.20; criteria = @("逻辑分段", "清晰组织") }
            @{ name = "style"; weight = 0.15; criteria = @("适当的语气", "合适的格式") }
            @{ name = "consistency"; weight = 0.10; criteria = @("术语统一", "逻辑一致") }
        )
    }
}

# 检查清晰度
function Test-PromptClarity {
    param([string]$Prompt)

    $checks = @(
        "是否包含明确的目标陈述"
        "是否指定了期望的输出格式"
        "是否避免了模糊的语言"
        "是否定义了边界条件"
    )

    $results = foreach ($check in $checks) {
        [PSCustomObject]@{
            Check     = $check
            Result    = if ($Prompt -match $check) { "pass" } else { "fail" }
            Score     = if ($Prompt -match $check) { 1 } else { 0 }
            Explanation = if ($Prompt -match $check) { "✓" } else { "✗" }
        }
    }

    $totalScore = ($results | Where-Object Result -eq "pass").Score | Measure-Object -Sum | Select-Object -ExpandProperty Sum
    $maxScore = $results.Count
    $scorePercent = ($totalScore / $maxScore) * 30

    return @{
        Category = "清晰度"
        Score    = [math]::Round($scorePercent, 1)
        MaxScore = 30
        Details  = $results
    }
}

# 检查完整性
function Test-PromptCompleteness {
    param([string]$Prompt)

    $checks = @(
        "是否提供了足够的背景信息"
        "是否定义了输入约束"
        "是否考虑了可能的特殊情况"
        "是否包含了相关资源链接或引用"
    )

    $results = foreach ($check in $checks) {
        [PSCustomObject]@{
            Check     = $check
            Result    = if ($Prompt -match $check) { "pass" } else { "fail" }
            Score     = if ($Prompt -match $check) { 1 } else { 0 }
            Explanation = if ($Prompt -match $check) { "✓" } else { "✗" }
        }
    }

    $totalScore = ($results | Where-Object Result -eq "pass").Score | Measure-Object -Sum | Select-Object -ExpandProperty Sum
    $maxScore = $results.Count
    $scorePercent = ($totalScore / $maxScore) * 25

    return @{
        Category = "完整性"
        Score    = [math]::Round($scorePercent, 1)
        MaxScore = 25
        Details  = $results
    }
}

# 检查结构
function Test-PromptStructure {
    param([string]$Prompt)

    $checks = @(
        "是否有逻辑分段"
        "是否使用要点或编号"
        "是否遵循因果关系"
        "是否易于阅读理解"
    )

    $results = foreach ($check in $checks) {
        [PSCustomObject]@{
            Check     = $check
            Result    = if ($Prompt -match $check) { "pass" } else { "fail" }
            Score     = if ($Prompt -match $check) { 1 } else { 0 }
            Explanation = if ($Prompt -match $check) { "✓" } else { "✗" }
        }
    }

    $totalScore = ($results | Where-Object Result -eq "pass").Score | Measure-Object -Sum | Select-Object -ExpandProperty Sum
    $maxScore = $results.Count
    $scorePercent = ($totalScore / $maxScore) * 20

    return @{
        Category = "结构"
        Score    = [math]::Round($scorePercent, 1)
        MaxScore = 20
        Details  = $results
    }
}

# 检查风格
function Test-PromptStyle {
    param([string]$Prompt)

    $checks = @(
        "是否使用适合的语气（正式/非正式）"
        "是否使用恰当的语言层次"
        "格式是否整洁"
        "是否易于人机交互"
    )

    $results = foreach ($check in $checks) {
        [PSCustomObject]@{
            Check     = $check
            Result    = if ($Prompt -match $check) { "pass" } else { "fail" }
            Score     = if ($Prompt -match $check) { 1 } else { 0 }
            Explanation = if ($Prompt -match $check) { "✓" } else { "✗" }
        }
    }

    $totalScore = ($results | Where-Object Result -eq "pass").Score | Measure-Object -Sum | Select-Object -ExpandProperty Sum
    $maxScore = $results.Count
    $scorePercent = ($totalScore / $maxScore) * 15

    return @{
        Category = "风格"
        Score    = [math]::Round($scorePercent, 1)
        MaxScore = 15
        Details  = $results
    }
}

# 检查一致性
function Test-PromptConsistency {
    param([string]$Prompt)

    $checks = @(
        "术语使用是否一致"
        "引用格式是否统一"
        "语气风格是否连贯"
        "前后逻辑是否一致"
    )

    $results = foreach ($check in $checks) {
        [PSCustomObject]@{
            Check     = $check
            Result    = if ($Prompt -match $check) { "pass" } else { "fail" }
            Score     = if ($Prompt -match $check) { 1 } else { 0 }
            Explanation = if ($Prompt -match $check) { "✓" } else { "✗" }
        }
    }

    $totalScore = ($results | Where-Object Result -eq "pass").Score | Measure-Object -Sum | Select-Object -ExpandProperty Sum
    $maxScore = $results.Count
    $scorePercent = ($totalScore / $maxScore) * 10

    return @{
        Category = "一致性"
        Score    = [math]::Round($scorePercent, 1)
        MaxScore = 10
        Details  = $results
    }
}

# 完整质量检查
function Invoke-PromptQualityCheck {
    param(
        [string]$Prompt,
        [switch]$Detailed
    )

    Write-Host "`n=== Prompt Quality Check ===" -ForegroundColor Cyan
    Write-Host "`n提示词：" -ForegroundColor Yellow
    Write-Host $Prompt -ForegroundColor White
    Write-Host ""

    $checks = @(
        (Test-PromptClarity -Prompt $Prompt),
        (Test-PromptCompleteness -Prompt $Prompt),
        (Test-PromptStructure -Prompt $Prompt),
        (Test-PromptStyle -Prompt $Prompt),
        (Test-PromptConsistency -Prompt $Prompt)
    )

    $summary = [PSCustomObject]@{
        Clarity    = $checks[0].Score
        Completeness = $checks[1].Score
        Structure   = $checks[2].Score
        Style      = $checks[3].Score
        Consistency = $checks[4].Score
    }

    $totalScore = ($summary | Measure-Object -Property @{Expression = { $_ } } -Sum).Sum
    $maxScore = 100
    $scorePercent = ($totalScore / $maxScore) * 100

    Write-Host "`n--- Scoring ---" -ForegroundColor Gray

    foreach ($check in $checks) {
        $bar = "█" * [math]::Round(($check.Score / $check.MaxScore) * 20)
        Write-Host "$($check.Category): $($check.Score)/$($check.MaxScore) $bar" -ForegroundColor $(if ($check.Score / $check.MaxScore -lt 0.6) { "Red" } elseif ($check.Score / $check.MaxScore -lt 0.8) { "Yellow" } else { "Green" })
    }

    Write-Host "`n--- Summary ---" -ForegroundColor Gray
    Write-Host "Total Score: $scorePercent / 100" -ForegroundColor $(if ($scorePercent -lt 60) { "Red" } elseif ($scorePercent -lt 80) { "Yellow" } else { "Green" })

    if ($Detailed) {
        Write-Host "`n--- Details ---" -ForegroundColor Gray
        foreach ($check in $checks) {
            Write-Host "`n$($check.Category):" -ForegroundColor Cyan
            foreach ($detail in $check.Details) {
                Write-Host "  $($detail.Explanation) $($detail.Check)" -ForegroundColor White
            }
        }
    }

    Write-Host ""

    return @{
        OverallScore = [math]::Round($scorePercent, 1)
        Detailed     = $checks
    }
}

# 导出检查报告
function Export-QualityCheckReport {
    param(
        [string]$Prompt,
        [string]$OutputPath,
        [switch]$Detailed
    )

    $result = Invoke-PromptQualityCheck -Prompt $Prompt -Detailed:$Detailed

    $report = @"
# Prompt Quality Check Report

## Overall Score: $($result.OverallScore)/100

## Detailed Scoring

### Clarity: $($result.Detailed[0].Score)/30
@(foreach ($check in $result.Detailed[0].Details) {
    - $($check.Explanation) $($check.Check)
})

### Completeness: $($result.Detailed[1].Score)/25
@(foreach ($check in $result.Detailed[1].Details) {
    - $($check.Explanation) $($check.Check)
})

### Structure: $($result.Detailed[2].Score)/20
@(foreach ($check in $result.Detailed[2].Details) {
    - $($check.Explanation) $($check.Check)
})

### Style: $($result.Detailed[3].Score)/15
@(foreach ($check in $result.Detailed[3].Details) {
    - $($check.Explanation) $($check.Check)
})

### Consistency: $($result.Detailed[4].Score)/10
@(foreach ($check in $result.Detailed[4].Details) {
    - $($check.Explanation) $($check.Check)
})

## Prompt Text
\`\`\`
$Prompt
\`\`\`
"@

    $report | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "Report saved to: $OutputPath" -ForegroundColor Green
}

# 命令行接口
function Show-Usage {
    Write-Host @"
Usage:
  Invoke-PromptQualityCheck -Prompt "your prompt here"
  Invoke-PromptQualityCheck -Prompt "..." -Detailed

  Export-QualityCheckReport -Prompt "your prompt here" -OutputPath report.md -Detailed

Examples:
  Invoke-PromptQualityCheck -Prompt "写一个Python函数计算斐波那契数列"
  Invoke-PromptQualityCheck -Prompt "..." -Detailed
"@
}

# 如果有参数则执行命令
if ($args.Count -gt 0) {
    $promptParam = $args[0]
    $detailedParam = if ($args -contains "-Detailed") { $true } else { $false }

    if ($promptParam) {
        Invoke-PromptQualityCheck -Prompt $promptParam -Detailed:$detailedParam
    }
}

<#
.EXAMPLE
Invoke-PromptQualityCheck -Prompt "写一个Python函数计算斐波那契数列"
Invoke-PromptQualityCheck -Prompt "写一个Python函数..." -Detailed
Export-QualityCheckReport -Prompt "写一个Python函数..." -OutputPath quality-report.md -Detailed
#>
