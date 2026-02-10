# Code Mentor 技能集成

**版本**: 1.0
**日期**: 2026-02-10

---

## 功能模块

### 1. Code Review (代码审查)

```powershell
function Invoke-CodeMentorReview {
    param(
        [string]$Code,
        [string]$Mode = "code-review",  # code-review | debugging | refactoring | best-practices
        [string]$Language = "powershell"
    )

    Write-Host "[CODE-MENTOR] Starting code review in $Language mode..." -ForegroundColor Cyan

    # 调用code-mentor逻辑
    $analysis = Analyze-Code $Code $Mode $Language

    # 显示结果
    Display-AnalysisResults $analysis

    return $analysis
}

function Analyze-Code {
    param(
        [string]$Code,
        [string]$Mode,
        [string]$Language
    )

    $issues = @()
    $suggestions = @()
    $complexity = 0

    # 分析代码（简化版，实际使用时会调用code-mentor逻辑）
    $lines = $Code -split "`r`n"

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i].Trim()

        # 检测常见问题
        if ($line -match "^\s*if\s*\(") {
            $issues += @{
                line = $i + 1
                type = "control-flow"
                message = "Control flow detected"
                severity = "info"
            }
        }

        if ($line -match "Write-Host" -and $line -notmatch "#") {
            $issues += @{
                line = $i + 1
                type = "logging"
                message = "Console output detected (consider using logging framework)"
                severity = "info"
            }
        }
    }

    # 计算代码复杂度
    $complexity = [math]::Round($issues.Count / $lines.Count, 2)

    return @{
        mode = $Mode
        language = $Language
        issues = $issues
        suggestions = $suggestions
        complexity = $complexity
        lines_analyzed = $lines.Count
        overall_rating = if ($complexity -lt 1) { "good" } else { "needs improvement" }
    }
}

function Display-AnalysisResults {
    param(
        $Analysis
    )

    Write-Host "`n[CODE-MENTOR] Analysis Results" -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host "Language: $($Analysis.language)" -ForegroundColor Yellow
    Write-Host "Complexity: $($Analysis.complexity)" -ForegroundColor $(switch ($Analysis.complexity) { 0..1 { "Green" }; 1..2 { "Yellow" }; default { "Red" } })
    Write-Host "Overall Rating: $($Analysis.overall_rating)" -ForegroundColor $(switch ($Analysis.overall_rating) { "good" { "Green" }; default { "Yellow" } })
    Write-Host "Lines Analyzed: $($Analysis.lines_analyzed)" -ForegroundColor Cyan

    if ($Analysis.issues.Count -gt 0) {
        Write-Host "`nIssues Found:" -ForegroundColor Yellow
        foreach ($issue in $Analysis.issues) {
            Write-Host "  Line $($issue.line): $($issue.message)" -ForegroundColor Red
        }
    }

    if ($Analysis.suggestions.Count -gt 0) {
        Write-Host "`nSuggestions:" -ForegroundColor Green
        foreach ($suggestion in $Analysis.suggestions) {
            Write-Host "  - $($suggestion)" -ForegroundColor Green
        }
    }
}
```

---

### 2. Debugging Assistance (调试辅助)

```powershell
function Invoke-CodeMentorDebug {
    param(
        [string]$Error,
        [string]$CodeContext,
        [int]$LineNumber = 0
    )

    Write-Host "[CODE-MENTOR] Debugging session started..." -ForegroundColor Cyan
    Write-Host "Error: $Error" -ForegroundColor Red
    Write-Host "Context: Line $LineNumber" -ForegroundColor Yellow

    # 生成调试建议
    $suggestions = Generate-DebugSuggestions $Error $CodeContext $LineNumber

    Display-DebugSuggestions $suggestions
}

function Generate-DebugSuggestions {
    param(
        [string]$Error,
        [string]$CodeContext,
        [int]$LineNumber
    )

    $suggestions = @()

    # 常见错误模式
    if ($Error -match "null reference" -or $Error -match "Object reference not set") {
        $suggestions += "Check if variable is initialized before use"
        $suggestions += "Consider using null coalescing operator: `$var ?? 'default'"
    }

    if ($Error -match "unbound variable" -or $Error -match "'$' was not recognized") {
        $suggestions += "Check variable spelling"
        $suggestions += "Verify variable is defined in scope"
    }

    if ($Error -match "syntax error") {
        $suggestions += "Check for unmatched brackets, quotes, or parentheses"
        $suggestions += "Verify syntax matches PowerShell version"
    }

    if ($Error -match "permission denied") {
        $suggestions += "Run with elevated permissions if needed"
        $suggestions += "Check file/folder permissions"
    }

    return $suggestions
}

function Display-DebugSuggestions {
    param(
        $Suggestions
    )

    Write-Host "`n[CODE-MENTOR] Debugging Suggestions:" -ForegroundColor Green

    if ($Suggestions.Count -gt 0) {
        for ($i = 0; $i -lt $Suggestions.Count; $i++) {
            Write-Host "  $($i + 1). $($Suggestions[$i])" -ForegroundColor Cyan
        }
    } else {
        Write-Host "  No specific suggestions found. Please provide more context." -ForegroundColor Yellow
    }
}
```

---

### 3. Algorithm Practice (算法练习)

```powershell
function Invoke-CodeMentorPractice {
    param(
        [string]$Difficulty = "medium",
        [string]$Topic = "algorithm",
        [int]$TargetTime = 30
    )

    Write-Host "[CODE-MENTOR] Algorithm practice session" -ForegroundColor Cyan
    Write-Host "Difficulty: $Difficulty" -ForegroundColor $(switch ($Difficulty) { "easy" { "Green" }; "medium" { "Yellow" }; "hard" { "Red" } })
    Write-Host "Topic: $Topic" -ForegroundColor Cyan
    Write-Host "Target Time: $TargetTime minutes" -ForegroundColor Cyan

    # 生成算法问题（简化版）
    $problem = Generate-AlgorithmProblem $Difficulty $Topic

    Display-AlgorithmProblem $problem
}

function Generate-AlgorithmProblem {
    param(
        [string]$Difficulty,
        [string]$Topic
    )

    $problems = @{
        "easy" = @{
            title = "Two Sum"
            description = "Given an array of integers, return indices of the two numbers such that they add up to a specific target."
            example = @"
Example:
Input: nums = [2,7,11,15], target = 9
Output: [0,1]
Explanation: nums[0] + nums[1] == 9, so return [0,1].
"@
            time_complexity = "O(n²)"
            space_complexity = "O(1)"
        }
        "medium" = @{
            title = "Longest Substring Without Repeating Characters"
            description = "Given a string, find the length of the longest substring without repeating characters."
            example = @"
Example:
Input: "abcabcbb"
Output: 3
Explanation: "abc" is the longest substring without repeating characters.
"@
            time_complexity = "O(n)"
            space_complexity = "O(min(n, m))"
        }
        "hard" = @{
            title = "Median of Two Sorted Arrays"
            description = "Given two sorted arrays, return the median of the two sorted arrays."
            example = @"
Example:
Input: nums1 = [1,3], nums2 = [2]
Output: 2.0
Explanation: combined array is [1,2,3], median is 2.
"@
            time_complexity = "O(log(min(n,m)))"
            space_complexity = "O(1)"
        }
    }

    return $problems.($Difficulty)
}

function Display-AlgorithmProblem {
    param(
        $Problem
    )

    Write-Host "`n[CODE-MENTOR] Algorithm Problem" -ForegroundColor Cyan
    Write-Host "==================================" -ForegroundColor Cyan
    Write-Host "Title: $($Problem.title)" -ForegroundColor Yellow
    Write-Host "`nDescription:" -ForegroundColor Yellow
    Write-Host $Problem.description -ForegroundColor Cyan
    Write-Host "`nExample:" -ForegroundColor Yellow
    Write-Host $Problem.example -ForegroundColor Gray
    Write-Host "`nComplexity:" -ForegroundColor Yellow
    Write-Host "  Time: $($Problem.time_complexity)" -ForegroundColor Cyan
    Write-Host "  Space: $($Problem.space_complexity)" -ForegroundColor Cyan
    Write-Host "`nHint: Take your time to understand the problem before coding!" -ForegroundColor Green
}
```

---

## 导出函数

```powershell
Export-ModuleMember -Function Invoke-CodeMentorReview, Invoke-CodeMentorDebug, Invoke-CodeMentorPractice
```

---

## 使用示例

```powershell
# 代码审查
Invoke-CodeMentorReview -Code "if (x = 1) { Write-Host 'hello' }" -Mode "code-review" -Language "powershell"

# 调试
Invoke-CodeMentorDebug -Error "Unbound variable 'x'" -CodeContext "if (x = 1)" -LineNumber 1

# 算法练习
Invoke-CodeMentorPractice -Difficulty "medium" -Topic "arrays"
```

---

**维护者**: 灵眸
**最后更新**: 2026-02-10
