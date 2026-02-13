# Copilot集成测试

<#
.SYNOPSIS
    测试Copilot各模块功能

.DESCRIPTION
    测试补全引擎、质量评分系统、性能分析模块

.PARAMeter Language
    代码语言

.OUTPUTS
    测试结果报告
#>

function Test-CopilotIntegration {
    param(
        [Parameter(Mandatory=$false)]
        [string]$Language = "javascript"
    )

    Write-Host "=== Copilot集成测试 ===" -ForegroundColor Cyan
    Write-Host "语言: $Language`n" -ForegroundColor Yellow

    $results = @{}

    # 测试1：补全引擎
    Write-Host "测试1: 补全引擎" -ForegroundColor Green
    try {
        $currentLine = "const result = numbers."
        $contextLines = "numbers.filter(x => x > 0).map(x => x * 2)", "const numbers = [1, 2, 3, 4, 5];"

        $completions = Get-LineCompletion -CurrentLine $currentLine -ContextLines $contextLines -Language $Language

        if ($completions.Count -gt 0) {
            Write-Host "✓ 补全引擎正常" -ForegroundColor Green
            Write-Host "  返回了 $($completions.Count) 个候选" -ForegroundColor White
            Write-Host "  最佳候选: $($completions[0].Completion)" -ForegroundColor White
            $results['Completion'] = 'PASSED'
        } else {
            Write-Host "✗ 补全引擎无结果" -ForegroundColor Red
            $results['Completion'] = 'FAILED'
        }
    } catch {
        Write-Host "✗ 补全引擎错误: $_" -ForegroundColor Red
        $results['Completion'] = 'ERROR'
    }
    Write-Host ""

    # 测试2：质量评分
    Write-Host "测试2: 质量评分系统" -ForegroundColor Green
    try {
        if ($completions.Count -gt 0) {
            $quality = Evaluate-Quality -Candidate $completions[0]

            Write-Host "✓ 质量评分正常" -ForegroundColor Green
            Write-Host "  总分: $($quality.TotalScore)/100" -ForegroundColor White
            Write-Host "  评级: $($quality.Rating)" -ForegroundColor White
            Write-Host "  语法: $($quality.Syntax)" -ForegroundColor White
            Write-Host "  模式匹配: $($quality.PatternMatch)" -ForegroundColor White
            Write-Host "  可读性: $($quality.Readability)" -ForegroundColor White
            Write-Host "  性能: $($quality.Performance)" -ForegroundColor White
            Write-Host "  可维护性: $($quality.Maintainability)" -ForegroundColor White
            $results['Quality'] = 'PASSED'
        } else {
            Write-Host "⚠ 没有补全结果，跳过质量评分测试" -ForegroundColor Yellow
            $results['Quality'] = 'SKIPPED'
        }
    } catch {
        Write-Host "✗ 质量评分错误: $_" -ForegroundColor Red
        $results['Quality'] = 'ERROR'
    }
    Write-Host ""

    # 测试3：性能分析
    Write-Host "测试3: 性能分析模块" -ForegroundColor Green
    try {
        $code = "for (let i = 0; i < users.length; i++) { const data = await fetch('/api/user/' + users[i].id); }"

        $suggestions = Analyze-Performance -Code $code -Language $Language

        if ($suggestions.Count -gt 0) {
            Write-Host "✓ 性能分析正常" -ForegroundColor Green
            Write-Host "  检测到 $($suggestions.Count) 个问题" -ForegroundColor White
            foreach ($s in $suggestions) {
                Write-Host "  - $($s.Issue) [$($s.Severity)]" -ForegroundColor White
            }
            $results['Performance'] = 'PASSED'
        } else {
            Write-Host "✗ 性能分析无结果" -ForegroundColor Red
            $results['Performance'] = 'FAILED'
        }
    } catch {
        Write-Host "✗ 性能分析错误: $_" -ForegroundColor Red
        $results['Performance'] = 'ERROR'
    }
    Write-Host ""

    # 测试4：批量评估
    Write-Host "测试4: 批量评估" -ForegroundColor Green
    try {
        if ($completions.Count -ge 3) {
            $batchResults = Evaluate-CandidatesQuality -Candidates $completions

            Write-Host "✓ 批量评估正常" -ForegroundColor Green
            Write-Host "  评估了 $($batchResults.Count) 个候选" -ForegroundColor White
            foreach ($br in $batchResults) {
                Write-Host "  - $($br.Candidate) [$($br.TotalScore)/100, $($br.Rating)]" -ForegroundColor White
            }
            $results['Batch'] = 'PASSED'
        } else {
            Write-Host "⚠ 候选数量不足，跳过批量评估" -ForegroundColor Yellow
            $results['Batch'] = 'SKIPPED'
        }
    } catch {
        Write-Host "✗ 批量评估错误: $_" -ForegroundColor Red
        $results['Batch'] = 'ERROR'
    }
    Write-Host ""

    # 测试5：性能报告
    Write-Host "测试5: 性能报告生成" -ForegroundColor Green
    try {
        if ($suggestions.Count -gt 0) {
            $report = Format-PerformanceReport -Suggestions $suggestions
            Write-Host "✓ 报告生成正常" -ForegroundColor Green
            Write-Host "  报告长度: $($report.Length) 字符" -ForegroundColor White
            $results['Report'] = 'PASSED'
        } else {
            Write-Host "⚠ 没有问题需要报告" -ForegroundColor Yellow
            $results['Report'] = 'SKIPPED'
        }
    } catch {
        Write-Host "✗ 报告生成错误: $_" -ForegroundColor Red
        $results['Report'] = 'ERROR'
    }
    Write-Host ""

    # 测试6：模式库加载
    Write-Host "测试6: 模式库加载" -ForegroundColor Green
    try {
        $patterns = Load-Patterns -Language $Language

        if ($patterns.Count -gt 0) {
            Write-Host "✓ 模式库加载正常" -ForegroundColor Green
            Write-Host "  加载了 $($patterns.Count) 个模式" -ForegroundColor White
            Write-Host "  语言分布:" -ForegroundColor White
            foreach ($lang in $patterns.language | Group-Object | Sort-Object -Property Count -Descending) {
                Write-Host "    - $($lang.Name): $($lang.Count)" -ForegroundColor White
            }
            $results['Patterns'] = 'PASSED'
        } else {
            Write-Host "✗ 模式库加载失败" -ForegroundColor Red
            $results['Patterns'] = 'FAILED'
        }
    } catch {
        Write-Host "✗ 模式库加载错误: $_" -ForegroundColor Red
        $results['Patterns'] = 'ERROR'
    }
    Write-Host ""

    # 总结
    Write-Host "=== 测试总结 ===" -ForegroundColor Cyan
    $passed = 0
    $failed = 0
    $skipped = 0
    $error = 0

    foreach ($key in $results.Keys) {
        switch ($results[$key]) {
            'PASSED' { $passed++; }
            'FAILED' { $failed++; }
            'SKIPPED' { $skipped++; }
            'ERROR' { $error++; }
        }
    }

    Write-Host "通过: $passed" -ForegroundColor Green
    Write-Host "失败: $failed" -ForegroundColor Red
    Write-Host "跳过: $skipped" -ForegroundColor Yellow
    Write-Host "错误: $error" -ForegroundColor Yellow

    $total = $passed + $failed + $skipped + $error
    $rate = 0
    if ($total -gt 0) {
        $rate = ($passed / $total) * 100
    }

    Write-Host "`n通过率: $rate%" -ForegroundColor $(if ($rate -ge 80) { 'Green' } elseif ($rate -ge 60) { 'Yellow' } else { 'Red' })

    return $results
}

Export-ModuleMember -Function @(
    'Test-CopilotIntegration'
)
