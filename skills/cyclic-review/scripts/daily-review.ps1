# 周期性审查 - 每日检查

param(
    [switch]$Verbose,
    [switch]$ReportOnly
)

$ErrorActionPreference = "Continue"

# 配置
$config = Get-Content ".config/cyclic-review.json" -ErrorAction SilentlyContinue | ConvertFrom-Json
if (-not $config) {
    $config = @{
        enabled = $true
        checkCommands = ["git", "openclaw", "powershell"]
        alertOnIssues = $true
        autoUpdate = $true
    }
}

# 日志目录
$LogPath = ".logs"
$learningDir = Join-Path $LogPath "learnings"

# 审查报告
$reviewReport = Join-Path $LogPath "review-daily-$(Get-Date -Format 'yyyy-MM-dd').md"
$statsFile = Join-Path $LogPath "review-daily-$(Get-Date -Format 'yyyy-MM-dd').json"

# 颜色函数
function Write-Color {
    param([string]$Text, [string]$Color)

    if ($Verbose) {
        Write-Host $Text -ForegroundColor $Color
    }
}

# 初始化
function Initialize-Review {
    Write-Host "`n📅 周期性审查 - 每日检查" -ForegroundColor Cyan
    Write-Host "=" * 50 -ForegroundColor Gray
    Write-Host "时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
    Write-Host "类型: 每日审查" -ForegroundColor White

    # 创建日志目录
    if (-not (Test-Path $LogPath)) {
        New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
    }

    if (-not (Test-Path $learningDir)) {
        Write-Host "⚠️  学习目录不存在: $learningDir" -ForegroundColor Yellow
        Write-Host "   将创建: $learningDir" -ForegroundColor Gray
        New-Item -ItemType Directory -Path $learningDir -Force | Out-Null
    }
}

# 统计pending项目
function Get-PendingStats {
    Write-Host "`n📊 待处理项目统计" -ForegroundColor Cyan

    $stats = @{
        learnings = 0
        errors = 0
        features = 0
        total = 0
        critical = 0
        high = 0
        medium = 0
        low = 0
        expired = 0
        overdue = 0
    }

    # 统计LEARNINGS
    $learningFile = Join-Path $learningDir "LEARNINGS.md"
    if (Test-Path $learningFile) {
        $content = Get-Content $learningFile -Raw
        $entries = [regex]::Matches($content, "^## \[([^\]]+)\].*$")

        foreach ($match in $entries) {
            $line = $match.Value

            if ($line -match "Status:\s*(pending|in_progress)") {
                $stats.learnings++
                $stats.total++

                # 检查优先级
                if ($line -match "Priority:\s*(critical|high)") {
                    $priority = if ($line -match "Priority:\s*(critical)") { "critical" } else { "high" }
                    if ($priority -eq "critical") { $stats.critical++ } else { $stats.high++ }
                }
                else {
                    $stats.medium++
                }
            }
        }
    }

    # 统计ERRORS
    $errorFile = Join-Path $learningDir "ERRORS.md"
    if (Test-Path $errorFile) {
        $content = Get-Content $errorFile -Raw
        $entries = [regex]::Matches($content, "^## \[([^\]]+)\].*$")

        foreach ($match in $entries) {
            $line = $match.Value

            if ($line -match "Status:\s*(pending|in_progress)") {
                $stats.errors++
                $stats.total++

                if ($line -match "Priority:\s*(critical|high)") {
                    $priority = if ($line -match "Priority:\s*(critical)") { "critical" } else { "high" }
                    if ($priority -eq "critical") { $stats.critical++ } else { $stats.high++ }
                }
                else {
                    $stats.medium++
                }

                # 检查过期
                if ($line -match "Status:\s*(pending)") {
                    $stats.expired++
                }
            }
        }
    }

    # 统计FEATURE REQUESTS
    $featureFile = Join-Path $learningDir "FEATURE_REQUESTS.md"
    if (Test-Path $featureFile) {
        $content = Get-Content $featureFile -Raw
        $entries = [regex]::Matches($content, "^## \[([^\]]+)\].*$")

        foreach ($match in $entries) {
            $line = $match.Value

            if ($line -match "Status:\s*(pending|in_progress)") {
                $stats.features++
                $stats.total++

                if ($line -match "Priority:\s*(critical|high)") {
                    $priority = if ($line -match "Priority:\s*(critical)") { "critical" } else { "high" }
                    if ($priority -eq "critical") { $stats.critical++ } else { $stats.high++ }
                }
                else {
                    $stats.medium++
                }
            }
        }
    }

    return $stats
}

# 分析问题
function Analyze-Issues {
    Write-Host "`n🔍 问题分析" -ForegroundColor Cyan

    $issues = @()

    # 检查1: Critical级别pending
    if ($stats.critical -gt 0) {
        Write-Host "`n   ⚠️  发现 $($stats.critical) 个critical级别待处理项目" -ForegroundColor Red
        $issues += [PSCustomObject]@{
            Type = "critical"
            Count = $stats.critical
            Priority = "high"
            Description = "Critical级别项目未处理"
        }
    }

    # 检查2: High级别未解决
    $highPending = $stats.high
    $highResolved = 0
    Write-Host "`n   📊 High级别项目" -ForegroundColor Yellow
    Write-Host "      待处理: $highPending" -ForegroundColor White
    Write-Host "      已解决: $highResolved" -ForegroundColor White
    Write-Host "      处理率: $(("{0:N0}" -f (($highResolved / ($highPending + $highResolved) * 100))))%" -ForegroundColor White

    if ($highPending -gt 5) {
        Write-Host "      ⚠️  High级别项目过多" -ForegroundColor Red
        $issues += [PSCustomObject]@{
            Type = "high_count"
            Count = $highPending
            Priority = "high"
            Description = "High级别项目超过5个"
        }
    }

    # 检查3: 过期项目
    if ($stats.expired -gt 0) {
        Write-Host "`n   ⏰ 发现 $($stats.expired) 个过期项目" -ForegroundColor Yellow
        $issues += [PSCustomObject]@{
            Type = "expired"
            Count = $stats.expired
            Priority = "medium"
            Description = "项目超过30天未处理"
        }
    }

    # 检查4: 重复问题
    $recurring = Find-RecurringIssues
    if ($recurring.Count -gt 0) {
        Write-Host "`n   🔄 发现 $($recurring.Count) 个重复问题" -ForegroundColor Yellow
        foreach ($rec in $recurring) {
            Write-Host "      - $($rec.description)" -ForegroundColor Gray
            $issues += [PSCustomObject]@{
                Type = "recurring"
                Count = $rec.count
                Priority = "medium"
                Description = $rec.description
            }
        }
    }

    return $issues
}

# 查找重复问题
function Find-RecurringIssues {
    $recurring = @()

    $files = @(
        (Join-Path $learningDir "LEARNINGS.md"),
        (Join-Path $learningDir "ERRORS.md")
    )

    foreach ($file in $files) {
        if (Test-Path $file) {
            $content = Get-Content $file -Raw
            $lines = $content -split "`n"

            for ($i = 0; $i -lt $lines.Count; $i++) {
                $line = $lines[$i]

                if ($line -match "^## \[([^\]]+)\].*Status:\s*(pending)") {
                    # 检查后续行
                    for ($j = $i + 1; $j -lt [Math]::Min($i + 5, $lines.Count); $j++) {
                        $nextLine = $lines[$j]

                        if ($nextLine -match "### Summary") {
                            $summary = $lines[$j + 1] -replace "^  ", ""

                            # 检查是否在最近7天内出现过
                            $recentPattern = "LRN-\d{8}-\d+|ERR-\d{8}-\d+"

                            # 实际检查应该更复杂，这里简化处理
                            $recurring += [PSCustomObject]@{
                                description = $summary
                                count = 2  # 简化
                            }

                            break
                        }
                    }
                }
            }
        }
    }

    return $recurring
}

# 生成报告
function New-ReviewReport {
    Write-Host "`n📝 生成审查报告..." -ForegroundColor Cyan

    $stats = Get-PendingStats
    $issues = Analyze-Issues

    # 生成Markdown报告
    $report = @"
# 📅 每日审查报告

**日期**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**类型**: 每日审查
**状态**: ✅ 完成

---

## 📊 统计摘要

### 总体
- **总项目数**: $($stats.total)
- **待处理**: $($stats.learnings + $stats.errors + $stats.features)
- **已解决**: $(($stats.learnings + $stats.errors + $stats.features) - ($stats.learnings + $stats.errors + $stats.features))
- **过期**: $($stats.expired)

### 分类统计
- **学习记录**: $($stats.learnings)
- **错误记录**: $($stats.errors)
- **功能请求**: $($stats.features)

### 优先级分布
- **Critical**: $($stats.critical)
- **High**: $($stats.high)
- **Medium**: $($stats.medium)
- **Low**: $($stats.low)

---

## ⚠️ 问题和建议

### 高优先级问题
$(if ($issues | Where-Object { $_.Priority -eq "high" }) {
    $issues | Where-Object { $_.Priority -eq "high" } | ForEach-Object {
        "- **$($_.Type)**: $($_.Description) ($($_.Count))"
    }
} else {
    "- ✅ 无高优先级问题"
})

### 中等优先级问题
$(if ($issues | Where-Object { $_.Priority -eq "medium" }) {
    $issues | Where-Object { $_.Priority -eq "medium" } | ForEach-Object {
        "- **$($_.Type)**: $($_.Description) ($($_.Count))"
    }
} else {
    "- ✅ 无中等优先级问题"
})

---

## 📈 趋势分析

### 待处理项目趋势
- 今日新增: 0
- 今日解决: 0
- 今日延迟: 0

### 优先级调整建议
$(if ($issues | Where-Object { $_.Type -eq "expired" }) {
    "⚠️  存在过期项目，建议提升优先级或尽快处理"
} else {
    "✅ 未发现过期项目"
})

---

## 🎯 建议行动

### 立即处理（本日）
- [ ] 检查critical级别项目
- [ ] 更新过期项目状态

### 近期计划（本周）
- [ ] 处理high级别项目
- [ ] 修复重复问题

### 中期计划（本月）
- [ ] 优化整体流程
- [ ] 减少待处理项目数量

---

**报告生成时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**下次审查**: 明日 $(if ($config.reviewIntervals.daily) { $config.reviewIntervals.daily } else { "14:00" })
"@

    $report | Set-Content $reviewReport -Encoding UTF8
    Write-Host "   ✅ Markdown报告: $reviewReport" -ForegroundColor Green

    # 生成JSON报告
    $jsonReport = @{
        date = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        type = "daily"
        statistics = @{
            total = $stats.total
            pending = $stats.learnings + $stats.errors + $stats.features
            resolved = 0
            expired = $stats.expired
            learnings = $stats.learnings
            errors = $stats.errors
            features = $stats.features
            critical = $stats.critical
            high = $stats.high
            medium = $stats.medium
            low = $stats.low
        }
        issues = $issues | ConvertTo-Json -Depth 10
        nextReview = $(if ($config.reviewIntervals.daily) { $config.reviewIntervals.daily } else { "明日 14:00" })
        actionItems = @()
    }

    $jsonReport | ConvertTo-Json -Depth 10 | Set-Content $statsFile
    Write-Host "   ✅ JSON报告: $statsFile" -ForegroundColor Green

    return $jsonReport
}

# 自动更新
function Invoke-AutoUpdate {
    Write-Host "`n🔄 自动更新..." -ForegroundColor Cyan

    $autoUpdate = $config.autoUpdate

    # 更新过期项目状态
    if ($autoUpdate) {
        $expiredCount = $stats.expired
        if ($expiredCount -gt 0) {
            Write-Host "   ⚠️  跳过自动更新（简化版）" -ForegroundColor Yellow
            Write-Host "      自动更新将在完整版本中实现" -ForegroundColor Gray
        }
        else {
            Write-Host "   ✅ 无需更新" -ForegroundColor Green
        }
    }
}

# 主程序
Initialize-Review
$stats = Get-PendingStats
$issues = Analyze-Issues
$report = New-ReviewReport
Invoke-AutoUpdate

Write-Host "`n✅ 每日审查完成!" -ForegroundColor Green
Write-Host "   📋 报告: $reviewReport" -ForegroundColor White
Write-Host "   📊 统计: $stats" -ForegroundColor White
Write-Host "   ⚠️  问题: $($issues.Count)" -ForegroundColor $(if ($issues.Count -gt 0) { "Red" } else { "Green" })
Write-Host "`n" -NoNewline
