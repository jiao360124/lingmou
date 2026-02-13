<#
.SYNOPSIS
Prompt Optimizer

.DESCRIPTION
提供AI驱动的提示词优化建议，改进提示词的质量

.NOTES
Author: OpenClaw Assistant
Date: 2026-02-13
Version: 1.0.0
#>

$modulePath = $PSScriptRoot

# 加载质量规则
function Get-QualityRules {
    $rulesPath = Join-Path $modulePath "data/quality-rules.json"

    if (Test-Path $rulesPath) {
        return Get-Content $rulesPath -Raw | ConvertFrom-Json
    } else {
        return $null
    }
}

# 分析提示词问题
function Get-PromptIssues {
    param([string]$Prompt)

    $issues = @()

    # 清晰度问题
    if ($Prompt -notmatch "明确|目标|输出|结果") {
        $issues += [PSCustomObject]@{
            Category = "清晰度"
            Severity = "medium"
            Issue = "缺少明确的目标陈述"
            Suggestion = "添加：请明确说明你希望AI完成的任务或目标"
            Score = 0.3
        }
    }

    # 完整性问题
    if ($Prompt -notmatch "背景|信息|上下文|约束|要求") {
        $issues += [PSCustomObject]@{
            Category = "完整性"
            Severity = "high"
            Issue = "缺少足够的上下文信息"
            Suggestion = "添加：提供相关的背景信息、约束条件和期望结果"
            Score = 0.25
        }
    }

    # 结构问题
    if ($Prompt -notmatch "首先|其次|第一|第二|然后|最后") {
        $issues += [PSCustomObject]@{
            Category = "结构"
            Severity = "low"
            Issue = "缺少清晰的逻辑结构"
            Suggestion = "使用编号或要点来组织内容，提高可读性"
            Score = 0.2
        }
    }

    # 风格问题
    if ($Prompt -notmatch "使用|采用|请|要求|需要") {
        $issues += [PSCustomObject]@{
            Category = "风格"
            Severity = "medium"
            Issue = "语气不够明确"
            Suggestion = "添加明确的指令词，如：请、需要、要求"
            Score = 0.15
        }
    }

    # 一致性问题
    if ($Prompt -notmatch "一致|统一|相同") {
        $issues += [PSCustomObject]@{
            Category = "一致性"
            Severity = "low"
            Issue = "缺少一致性检查"
            Suggestion = "确保术语使用一致，避免重复或冲突的指令"
            Score = 0.1
        }
    }

    return $issues
}

# 生成优化后的提示词
function New-OptimizedPrompt {
    param(
        [string]$OriginalPrompt,
        [string]$Category = "general"
    )

    $issues = Get-PromptIssues -Prompt $OriginalPrompt

    if ($issues.Count -eq 0) {
        return @{
            Original = $OriginalPrompt
            Optimized = $OriginalPrompt
            Improvements = @()
            OverallScore = 100
        }
    }

    $improvements = @()
    $optimizedPrompt = $OriginalPrompt

    # 1. 添加明确的目标声明
    if ($issues | Where-Object { $_.Category -eq "清晰度" -and $_.Severity -eq "medium" }) {
        $goalStatement = "\n\n**目标**：明确说明你希望AI完成的具体任务和期望结果"
        $optimizedPrompt = $goalStatement + $optimizedPrompt
        $improvements += [PSCustomObject]@{
            Type       = "添加目标声明"
            Before     = ""
            After      = $goalStatement.Trim()
            Explanation = "明确的目标有助于AI理解任务重点"
            Impact     = "High"
        }
    }

    # 2. 添加结构化格式
    if ($issues | Where-Object { $_.Category -eq "结构" }) {
        $structure = @"
**结构要求**：
- 使用清晰的段落组织
- 使用编号或要点列表
- 按逻辑顺序排列内容

"@
        $optimizedPrompt = $optimizedPrompt + $structure
        $improvements += [PSCustomObject]@{
            Type       = "添加结构化格式"
            Before     = ""
            After      = $structure.Trim()
            Explanation = "结构化格式提高可读性和理解效率"
            Impact     = "Medium"
        }
    }

    # 3. 添加语气说明
    if ($issues | Where-Object { $_.Category -eq "风格" }) {
        $tone = "**语气**：保持专业、清晰、简洁" + "`n**格式**：使用Markdown格式"
        $optimizedPrompt = $optimizedPrompt + "`n" + $tone
        $improvements += [PSCustomObject]@{
            Type       = "添加语气说明"
            Before     = ""
            After      = $tone.Trim()
            Explanation = "明确的语气和格式要求提高输出质量"
            Impact     = "Medium"
        }
    }

    # 4. 添加完整性检查项
    if ($issues | Where-Object { $_.Category -eq "完整性" -and $_.Severity -eq "high" }) {
        $completeness = @"
**完整性要求**：
- 提供足够的背景信息
- 定义输入约束和期望结果
- 考虑特殊情况处理

**行动号召**：
请按照以上要求提供详细的回复。

"@
        $optimizedPrompt = $optimizedPrompt + $completeness
        $improvements += [PSCustomObject]@{
            Type       = "添加完整性检查"
            Before     = ""
            After      = $completeness.Trim()
            Explanation = "完整性要求确保AI提供全面的回答"
            Impact     = "High"
        }
    }

    # 计算优化后的分数
    $issueScore = ($issues | Measure-Object -Property Score -Sum).Sum
    $overallScore = [math]::Round(100 - $issueScore, 1)

    return @{
        Original      = $OriginalPrompt
        Optimized     = $optimizedPrompt
        Improvements  = $improvements
        OverallScore  = $overallScore
        IssuesCount   = $issues.Count
        ImprovementRate = [math]::Round(($improvements.Count / $issues.Count) * 100, 1)
    }
}

# 显示优化结果
function Show-OptimizationResult {
    param(
        [hashtable]$Result,
        [switch]$Detailed
    )

    Write-Host "`n=== Prompt Optimization Result ===" -ForegroundColor Cyan

    Write-Host "`n1. 原始提示词：" -ForegroundColor Yellow
    Write-Host $Result.Original -ForegroundColor White

    Write-Host "`n2. 优化后提示词：" -ForegroundColor Green
    Write-Host $Result.Optimized -ForegroundColor White

    Write-Host "`n3. 优化效果：" -ForegroundColor Cyan
    Write-Host "   评分提升: $([math]::Round($Result.OverallScore - 100, 1)) -> $($Result.OverallScore)/100" -ForegroundColor $(if ($Result.OverallScore -ge 80) { "Green" } elseif ($Result.OverallScore -ge 60) { "Yellow" } else { "Red" })
    Write-Host "   改进项数量: $($Result.Improvements.Count)" -ForegroundColor Gray
    Write-Host "   改进率: $($Result.ImprovementRate)%"

    if ($Detailed -and $Result.Improvements.Count -gt 0) {
        Write-Host "`n4. 详细改进：" -ForegroundColor Cyan
        foreach ($i in 0..($Result.Improvements.Count - 1)) {
            $imp = $Result.Improvements[$i]
            Write-Host "`n   [$($i + 1)] $($imp.Type)" -ForegroundColor Yellow
            Write-Host "      说明: $($imp.Explanation)" -ForegroundColor White
            Write-Host "      影响: $($imp.Impact)" -ForegroundColor $(if ($imp.Impact -eq "High") { "Green" } else { "Yellow" })
            if (-not [string]::IsNullOrWhiteSpace($imp.Before)) {
                Write-Host "      之前: $($imp.Before)" -ForegroundColor Gray
            }
            if (-not [string]::IsNullOrWhiteSpace($imp.After)) {
                Write-Host "      之后: $($imp.After)" -ForegroundColor Green
            }
        }
    }

    Write-Host ""
}

# 导出优化报告
function Export-OptimizationReport {
    param(
        [hashtable]$Result,
        [string]$OutputPath
    )

    $report = @"
# Prompt Optimization Report

## Optimization Summary

- **Original Score**: 100
- **Optimized Score**: $($Result.OverallScore)
- **Improvement**: $([math]::Round($Result.OverallScore - 100, 1)) points
- **Improvements Made**: $($Result.Improvements.Count)

## Original Prompt

\`\`\`
$($Result.Original)
\`\`\`

## Optimized Prompt

\`\`\`
$($Result.Optimized)
\`\`\`

## Detailed Improvements

@(foreach ($i in 0..($Result.Improvements.Count - 1)) {
    $imp = $Result.Improvements[$i]
    - ### $($i + 1). $($imp.Type)

    **Impact**: $($imp.Impact)

    **Explanation**: $($imp.Explanation)

    @(if (-not [string]::IsNullOrWhiteSpace($imp.Before)) {
        - **Before**:
        \`\`\`
        $($imp.Before)
        \`\`\`
    })
    @(if (-not [string]::IsNullOrWhiteSpace($imp.After)) {
        - **After**:
        \`\`\`
        $($imp.After)
        \`\`\`
    })
})

## Recommendation

The optimized prompt provides:
- Clearer objectives
- Better structure
- More complete context
- Explicit tone and formatting requirements

This should result in higher quality and more relevant responses from the AI.
"@

    $report | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "Report saved to: $OutputPath" -ForegroundColor Green
}

# 批量优化
function New-BatchOptimizedPrompts {
    param(
        [string[]]$Prompts,
        [string]$Category = "general"
    )

    $results = @()

    foreach ($prompt in $Prompts) {
        $result = New-OptimizedPrompt -OriginalPrompt $prompt -Category $Category
        $results += $result
    }

    return $results
}

# 命令行接口
function Show-Usage {
    Write-Host @"
Usage:
  New-OptimizedPrompt -OriginalPrompt "your prompt here" [-Category "general"]
  New-OptimizedPrompt -OriginalPrompt "..." [-Category "code"]
  Show-OptimizationResult -Result $result [-Detailed]

  Export-OptimizationReport -Result $result -OutputPath report.md

Examples:
  $result = New-OptimizedPrompt -OriginalPrompt "写一个Python函数"
  Show-OptimizationResult -Result $result -Detailed
  Export-OptimizationReport -Result $result -OutputPath optimization-report.md
"@
}

# 默认导出到标准输出
if ($args.Count -gt 0) {
    $promptParam = $args[0]
    $categoryParam = if ($args -contains "-Category") { $args[$args.IndexOf("-Category") + 1] } else { "general" }

    if ($promptParam) {
        $result = New-OptimizedPrompt -OriginalPrompt $promptParam -Category $categoryParam
        Show-OptimizationResult -Result $result -Detailed
    }
}

<#
.EXAMPLE
$result = New-OptimizedPrompt -OriginalPrompt "写一个Python函数"
Show-OptimizationResult -Result $result -Detailed
Export-OptimizationReport -Result $result -OutputPath optimization-report.md
#>
