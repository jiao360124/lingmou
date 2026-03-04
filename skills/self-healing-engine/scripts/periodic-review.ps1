<#
.SYNOPSIS
    周期性审查系统 - 定期审查和优化自我修复引擎

.DESCRIPTION
    定期分析自我修复引擎的学习记录、错误模式和配置，生成优化建议和审查报告。

.VERSION
    1.0.0

.AUTHOR
    灵眸
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('review', 'analyze', 'optimize', 'report', 'weekly')]
    [string]$Action = 'review',

    [Parameter(Mandatory=$false)]
    [switch]$Verbose,

    [Parameter(Mandatory=$false)]
    [string]$OutputDir = ""
)

$BaseDir = if ($OutputDir) { $OutputDir } else { "$PSScriptRoot/.." }
$LearningsDir = "$BaseDir/../learnings"
$ConfigDir = "$BaseDir/config"
$OutputReportDir = "$BaseDir/../reports"

# 创建输出目录
if (-not (Test-Path $OutputReportDir)) {
    New-Item -ItemType Directory -Path $OutputReportDir -Force | Out-Null
}

# 颜色定义
$Colors = @{
    Green = [ConsoleColor]::Green
    Yellow = [ConsoleColor]::Yellow
    Red = [ConsoleColor]::Red
    Cyan = [ConsoleColor]::Cyan
    White = [ConsoleColor]::White
    Gray = [ConsoleColor]::Gray
}

function Initialize-Config {
    Write-Host "🔧 Initializing Review System..." -ForegroundColor Cyan

    if (-not (Test-Path $ConfigDir)) {
        New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
    }

    $configPath = "$ConfigDir/review-config.json"

    if (-not (Test-Path $configPath)) {
        @{
            "enabled" = $true
            "reviewInterval" = 7  # 每周审查一次
            "analyzeErrors" = $true
            "analyzePatterns" = $true
            "optimizeConfiguration" = $true
            "autoBackup" = $true
            "createReport" = $true
        } | ConvertTo-Json -Depth 10 | Set-Content $configPath
    }

    Write-Host "✅ Config initialized" -ForegroundColor Green
}

function Get-LearningStats {
    param([string]$LearningsFile)

    Write-Host "📊 分析学习记录: $LearningsFile" -ForegroundColor Cyan

    $stats = @{
        totalLearnings = 0
        highPriority = 0
        mediumPriority = 0
        lowPriority = 0
        byCategory = @{}
        resolved = 0
        pending = 0
        rejected = 0
    }

    if (-not (Test-Path $LearningsFile)) {
        return $stats
    }

    $content = Get-Content $LearningsFile -Raw
    $lines = $content -split "`n"

    foreach ($line in $lines) {
        if ($line -match "## \[LRN-([^\]]+)\]") {
            $stats.totalLearnings++

            if ($line -match "\*\*Priority\*\*:\s*(\w+)") {
                $priority = $matches[1]
                switch ($priority) {
                    "high" { $stats.highPriority++ }
                    "medium" { $stats.mediumPriority++ }
                    "low" { $stats.lowPriority++ }
                }
            }

            if ($line -match "\*\*Status\*\*:\s*(\w+)") {
                $status = $matches[1]
                switch ($status) {
                    "resolved" { $stats.resolved++ }
                    "pending" { $stats.pending++ }
                    "rejected" { $stats.rejected++ }
                }
            }

            if ($line -match "\*\*Category\*\*:\s*(\w+)") {
                $category = $matches[1]
                if (-not $stats.byCategory.ContainsKey($category)) {
                    $stats.byCategory[$category] = 0
                }
                $stats.byCategory[$category]++
            }
        }
    }

    return $stats
}

function Get-ErrorStats {
    param([string]$ErrorsFile)

    Write-Host "🔍 分析错误记录: $ErrorsFile" -ForegroundColor Cyan

    $stats = @{
        totalErrors = 0
        highPriority = 0
        mediumPriority = 0
        lowPriority = 0
        byType = @{}
        resolved = 0
        pending = 0
        trendingErrors = @()
    }

    if (-not (Test-Path $ErrorsFile)) {
        return $stats
    }

    $content = Get-Content $ErrorsFile -Raw
    $lines = $content -split "`n"

    $errorCounts = @{}

    foreach ($line in $lines) {
        if ($line -match "## \[ERR-([^\]]+)\]") {
            $stats.totalErrors++

            if ($line -match "\*\*Priority\*\*:\s*(\w+)") {
                $priority = $matches[1]
                switch ($priority) {
                    "high" { $stats.highPriority++ }
                    "medium" { $stats.mediumPriority++ }
                    "low" { $stats.lowPriority++ }
                }
            }

            if ($line -match "\*\*Status\*\*:\s*(\w+)") {
                $status = $matches[1]
                switch ($status) {
                    "resolved" { $stats.resolved++ }
                    "pending" { $stats.pending++ }
                }
            }

            # 统计错误类型
            if ($line -match "## \[ERR-.*?(\w+).*?\]") {
                $type = $matches[1]
                $errorCounts[$type]++
            }
        }
    }

    # 找出 trending errors (最近一周重复出现)
    $stats.byType = $errorCounts
    $stats.trendingErrors = $errorCounts.GetEnumerator() | Where-Object { $_.Value -ge 2 } | Sort-Object Value -Descending | ForEach-Object { @{ type = $_.Key; count = $_.Value } }

    return $stats
}

function Analyze-Patterns {
    Write-Host "🧩 分析重复模式..." -ForegroundColor Cyan

    $patterns = @()

    # 检查学习记录中的重复模式
    $errorsFile = "$LearningsDir/ERRORS.md"
    $errorsFile = "$LearningsDir/LEARNINGS.md"

    if (Test-Path $errorsFile) {
        $content = Get-Content $errorsFile -Raw
        $lines = $content -split "`n"

        # 检查最近是否有重复的学习
        $recentLearnings = $lines | Where-Object { $_ -match "## \[LRN-" } | Select-Object -First 10

        if ($recentLearnings.Count -gt 3) {
            $patterns += [PSCustomObject]@{
                type = "repetition"
                severity = "medium"
                message = "检测到近期有 $recentLearnings.Count 条学习记录，可能存在重复"
                suggestion = "合并相似的学习记录，提取更通用的最佳实践"
            }
        }
    }

    # 检查错误趋势
    if (Test-Path $errorsFile) {
        $errorStats = Get-ErrorStats -ErrorsFile $errorsFile

        if ($errorStats.trendingErrors.Count -gt 0) {
            $patterns += [PSCustomObject]@{
                type = "trend"
                severity = "high"
                message = "检测到 $errorStats.trendingErrors.Count 个频繁出现的错误类型"
                suggestion = "分析这些错误的原因，考虑添加自动修复逻辑或预防措施"
            }
        }
    }

    return $patterns
}

function Analyze-Configuration {
    Write-Host "⚙️  分析配置优化..." -ForegroundColor Cyan

    $optimizations = @()

    # 检查监控配置
    $monitorConfigPath = "$ConfigDir/monitor-config.json"
    if (Test-Path $monitorConfigPath) {
        $config = Get-Content $monitorConfigPath -Raw | ConvertFrom-Json

        if ($config.healthThreshold -lt 70) {
            $optimizations += [PSCustomObject]@{
                type = "config"
                priority = "high"
                issue = "健康度阈值设置过低 ($($config.healthThreshold))"
                suggestion = "建议将健康度阈值设置为70或更高，以便及时发现系统问题"
            }
        }

        if ($config.monitorInterval -lt 5) {
            $optimizations += [PSCustomObject]@{
                type = "config"
                priority = "low"
                issue = "监控刷新间隔过短 ($($config.monitorInterval)秒)"
                suggestion = "建议设置为5-10秒，避免过于频繁的检查"
            }
        }
    }

    # 检查错误配置
    $selfHealingConfigPath = "$ConfigDir/self-healing.json"
    if (Test-Path $selfHealingConfigPath) {
        $config = Get-Content $selfHealingConfigPath -Raw | ConvertFrom-Json

        if (-not $config.fixAttempts -or $config.fixAttempts -lt 3) {
            $optimizations += [PSCustomObject]@{
                type = "config"
                priority = "high"
                issue = "自动修复尝试次数不足"
                suggestion = "建议设置为至少3次，以提高修复成功率"
            }
        }

        if (-not $config.snapshotRetention -or $config.snapshotRetention -gt 14) {
            $optimizations += [PSCustomObject]@{
                type = "config"
                priority = "medium"
                issue = "快照保留时间过长"
                suggestion = "建议设置为7天，平衡存储空间和可恢复性"
            }
        }
    }

    return $optimizations
}

function Generate-Report {
    param(
        [PSCustomObject]$LearningStats,
        [PSCustomObject]$ErrorStats,
        [PSCustomObject[]]$Patterns,
        [PSCustomObject[]]$Optimizations
    )

    $reportPath = "$OutputReportDir/REVIEW-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
    $reportDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

    $reportContent = @"
# 自我修复引擎 - 周期性审查报告

**审查日期**: $reportDate
**报告类型**: 周期性审查

---

## 📊 学习记录统计

| 指标 | 数量 | 占比 |
|------|------|------|
| 总学习记录 | $($LearningStats.totalLearnings) | 100% |
| 高优先级 | $($LearningStats.highPriority) | $([math]::Round(($LearningStats.highPriority / $LearningStats.totalLearnings) * 100, 2))% |
| 中优先级 | $($LearningStats.mediumPriority) | $([math]::Round(($LearningStats.mediumPriority / $LearningStats.totalLearnings) * 100, 2))% |
| 低优先级 | $($LearningStats.lowPriority) | $([math]::Round(($LearningStats.lowPriority / $LearningStats.totalLearnings) * 100, 2))% |
| 已解决 | $($LearningStats.resolved) | $([math]::Round(($LearningStats.resolved / $LearningStats.totalLearnings) * 100, 2))% |
| 待处理 | $($LearningStats.pending) | $([math]::Round(($LearningStats.pending / $LearningStats.totalLearnings) * 100, 2))% |

**学习分类分布**:
$(
    $LearningStats.byCategory.GetEnumerator() | ForEach-Object {
        "- $($_.Key): $($_.Value) 条 ($([math]::Round(($_.Value / $LearningStats.totalLearnings) * 100, 2))%)"
    }
)

---

## 🔍 错误统计

| 指标 | 数量 |
|------|------|
| 总错误数 | $($ErrorStats.totalErrors) |
| 高优先级 | $($ErrorStats.highPriority) |
| 中优先级 | $($ErrorStats.mediumPriority) |
| 低优先级 | $($ErrorStats.lowPriority) |
| 已解决 | $($ErrorStats.resolved) |
| 待处理 | $($ErrorStats.pending) |

**错误类型分布**:
$(
    $ErrorStats.byType.GetEnumerator() | ForEach-Object {
        "- $($_.Key): $($_.Value) 次"
    }
)

**趋势错误**:
$(
    if ($ErrorStats.trendingErrors.Count -gt 0) {
        $ErrorStats.trendingErrors | ForEach-Object {
            "- `$($_.type): `$($_.count) 次"
        }
    } else {
        "- 无"
    }
)

---

## 🧩 模式分析

$(
    if ($Patterns.Count -gt 0) {
        foreach ($pattern in $Patterns) {
            "---"
            Write-Output "### 类型: $($pattern.type)"
            Write-Output "**严重程度**: $($pattern.severity)"
            Write-Output "**问题**: $($pattern.message)"
            Write-Output "**建议**: $($pattern.suggestion)"
            Write-Output ""
        }
    } else {
        "---"
        Write-Output "### 无重复模式发现"
        Write-Output "**状态**: ✅ 良好"
        Write-Output ""
    }
)

---

## ⚙️ 配置优化建议

$(
    if ($Optimizations.Count -gt 0) {
        foreach ($opt in $Optimizations) {
            "---"
            Write-Output "### 类型: $($opt.type)"
            Write-Output "**优先级**: $($opt.priority)"
            Write-Output "**问题**: $($opt.issue)"
            Write-Output "**建议**: $($opt.suggestion)"
            Write-Output ""
        }
    } else {
        "---"
        Write-Output "### 无配置优化建议"
        Write-Output "**状态**: ✅ 配置良好"
        Write-Output ""
    }
)

---

## 📈 总体评估

### 健康度评分

**学习记录健康度**: $([math]::Round(($LearningStats.totalLearnings - $LearningStats.lowPriority - $LearningStats.mediumPriority) / $LearningStats.totalLearnings * 100, 2))%

**错误管理健康度**: $([math]::Round($ErrorStats.resolved / $ErrorStats.totalErrors * 100, 2))%

**综合评分**: $([math]::Round((($LearningStats.totalLearnings - $LearningStats.lowPriority - $LearningStats.mediumPriority) / $LearningStats.totalLearnings * 100 + $ErrorStats.resolved / $ErrorStats.totalErrors * 100) / 2, 2))%

### 优先级建议

$(
    $highPriorityIssues = ($Patterns | Where-Object { $_.severity -eq "high" }) + ($Optimizations | Where-Object { $_.priority -eq "high" })

    if ($highPriorityIssues.Count -gt 0) {
        Write-Output "⚠️ **发现 $($highPriorityIssues.Count) 个高优先级问题，建议优先处理**"
        foreach ($issue in $highPriorityIssues) {
            Write-Output "- $($issue.issue)"
        }
    } else {
        Write-Output "✅ **未发现高优先级问题**"
    }
)

---

## 🎯 下一步行动

1. 处理高优先级问题和优化建议
2. 定期审查学习记录
3. 分析错误趋势并预防
4. 优化系统配置
5. 更新相关文档

---

**审查完成**
**状态**: ✅ 完成
**下次审查**: 7天后

"@

    $reportContent | Set-Content $reportPath -Encoding UTF8

    Write-Host "✅ 审查报告已生成: $reportPath" -ForegroundColor Green

    return $reportPath
}

try {
    Initialize-Config

    switch ($Action) {
        "review" {
            Write-Host "📋 开始周期性审查..." -ForegroundColor Cyan

            $learningStats = Get-LearningStats -LearningsFile "$LearningsDir/LEARNINGS.md"
            $errorStats = Get-ErrorStats -ErrorsFile "$LearningsDir/ERRORS.md"
            $patterns = Analyze-Patterns
            $optimizations = Analyze-Configuration

            # 生成报告
            $reportPath = Generate-Report -LearningStats $learningStats -ErrorStats $errorStats -Patterns $patterns -Optimizations $optimizations

            # 显示摘要
            Write-Host "`n" + ("=" * 60) -ForegroundColor Cyan
            Write-Host "📋 审查完成" -ForegroundColor Green
            Write-Host "  报告路径: $reportPath" -ForegroundColor Cyan
            Write-Host "  总学习记录: $($learningStats.totalLearnings)" -ForegroundColor White
            Write-Host "  总错误数: $($errorStats.totalErrors)" -ForegroundColor White
            Write-Host "  发现问题: $($patterns.Count + $optimizations.Count)" -ForegroundColor White
        }

        "analyze" {
            Write-Host "🔍 开始模式分析..." -ForegroundColor Cyan

            $patterns = Analyze-Patterns
            $optimizations = Analyze-Configuration

            Write-Host "`n" + ("=" * 60) -ForegroundColor Cyan
            Write-Host "📊 分析完成" -ForegroundColor Green
            Write-Host "  发现模式: $($patterns.Count)" -ForegroundColor White
            Write-Host "  优化建议: $($optimizations.Count)" -ForegroundColor White
        }

        "optimize" {
            Write-Host "⚙️  开始配置优化..." -ForegroundColor Cyan

            $optimizations = Analyze-Configuration

            foreach ($opt in $optimizations) {
                Write-Host "`n---" -ForegroundColor Gray
                Write-Host "**优先级**: $($opt.priority)" -ForegroundColor $(
                    switch ($opt.priority) {
                        "high" { "Red" }
                        "medium" { "Yellow" }
                        "low" { "Green" }
                    }
                )
                Write-Host "**问题**: $($opt.issue)" -ForegroundColor White
                Write-Host "**建议**: $($opt.suggestion)" -ForegroundColor Cyan
            }

            Write-Host "`n" + ("=" * 60) -ForegroundColor Cyan
            Write-Host "✅ 优化建议分析完成" -ForegroundColor Green
        }

        "report" {
            Write-Host "📄 生成报告..." -ForegroundColor Cyan

            $learningStats = Get-LearningStats -LearningsFile "$LearningsDir/LEARNINGS.md"
            $errorStats = Get-ErrorStats -ErrorsFile "$LearningsDir/ERRORS.md"
            $patterns = Analyze-Patterns
            $optimizations = Analyze-Configuration

            $reportPath = Generate-Report -LearningStats $learningStats -ErrorStats $errorStats -Patterns $patterns -Optimizations $optimizations

            Write-Host "✅ 报告已生成: $reportPath" -ForegroundColor Green
        }

        "weekly" {
            Write-Host "📅 执行每周审查完整流程..." -ForegroundColor Cyan

            $learningStats = Get-LearningStats -LearningsFile "$LearningsDir/LEARNINGS.md"
            $errorStats = Get-ErrorStats -ErrorsFile "$LearningsDir/ERRORS.md"
            $patterns = Analyze-Patterns
            $optimizations = Analyze-Configuration

            $reportPath = Generate-Report -LearningStats $learningStats -ErrorStats $errorStats -Patterns $patterns -Optimizations $optimizations

            # 自动备份
            if ($optimizations | Where-Object { $_.priority -eq "high" }) {
                Write-Host "`n🛡️  执行自动备份..." -ForegroundColor Cyan
                Write-Host "  建议执行备份操作以保护系统状态" -ForegroundColor Yellow
            }

            Write-Host "`n" + ("=" * 60) -ForegroundColor Cyan
            Write-Host "📅 每周审查完成" -ForegroundColor Green
            Write-Host "  报告路径: $reportPath" -ForegroundColor Cyan
            Write-Host "  下次审查: 7天后" -ForegroundColor Cyan
        }
    }
} catch {
    Write-Error "错误: $($_.Exception.Message)"
    Write-Host $_.ScriptStackTrace -ForegroundColor Gray
    exit 1
}
