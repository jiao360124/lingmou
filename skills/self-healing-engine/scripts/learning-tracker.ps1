# 自我修复 - 学习记录系统

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("log", "review", "resolve", "stats")]
    [string]$Action,

    [string]$Type = "learning",
    [string]$Category = "general",
    [string]$Message = $null,
    [string]$Resolution = $null
)

$ErrorActionPreference = "Continue"

# 配置
$config = Get-Content ".config/self-healing.json" -ErrorAction SilentlyContinue | ConvertFrom-Json
if (-not $config) {
    $config = @{
        enabled = $true
        logDirs = @(".logs", ".learnings")
        priorityLevels = @("critical", "high", "medium", "low")
        resolveAfter = 7
    }
}

# 目录
$LogPath = ".logs"
$learningDir = Join-Path $LogPath "learnings"

# 创建必要的目录
if (-not (Test-Path $learningDir)) {
    New-Item -ItemType Directory -Path $learningDir -Force | Out-Null
}

# 学习文件
$learningFile = Join-Path $learningDir "LEARNINGS.md"
$errorFile = Join-Path $learningDir "ERRORS.md"
$featureFile = Join-Path $learningDir "FEATURE_REQUESTS.md"

# 初始化文件（如果不存在）
foreach ($file in @($learningFile, $errorFile, $featureFile)) {
    if (-not (Test-Path $file)) {
        @"
# LEARNINGS - 持续改进记录
# 格式: ## [LRN-YYYYMMDD-XXX] category
# 详见: https://github.com/moltbot/moltbot/blob/main/skills/self-improvement
#
# 优先级: critical | high | medium | low
# 状态: pending | in_progress | resolved | promoted | wont_fix
#
---

"@ | Set-Content $file -Encoding UTF8
    }
}

# 生成ID
function New-EntryId {
    param([string]$Type)

    $date = Get-Date -Format "yyyyMMdd"
    $count = 0

    # 检查现有条目数量
    if ($Type -eq "learning") {
        $pattern = "LRN-$date-\d+"
    }
    elseif ($Type -eq "error") {
        $pattern = "ERR-$date-\d+"
    }
    elseif ($Type -eq "feature") {
        $pattern = "FEAT-$date-\d+"
    }

    $existing = Get-ChildItem -Path $learningDir -Filter "$Type-$date-*.md"
    if ($existing) {
        $count = $existing.Count
    }

    $nextNumber = ($count + 1).ToString("000")

    return "$Type-$date-$nextNumber"
}

# 记录学习
function Write-Learning {
    param(
        [string]$Category,
        [string]$Message,
        [string]$Resolution = $null,
        [string]$Priority = "medium",
        [string]$Status = "pending",
        [string]$Area = "general",
        [string]$RelatedFiles = $null,
        [string]$SeeAlso = $null
    )

    $entryId = New-EntryId -Type "learning"
    $timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    $isoTimestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")

    $content = @"

## [$entryId] $Category

**Logged**: $isoTimestamp
**Priority**: $Priority
**Status**: $Status
**Area**: $Area

### Summary
$Message

### Details
$($Message -replace "`n", "`n  ")

$(if ($Resolution) { "
### Resolution
$Resolution
" })

$(if ($RelatedFiles) { "
### Related Files
$RelatedFiles
" })

$(if ($SeeAlso) { "
### See Also
$SeeAlso
" })

---

"@

    Add-Content $learningFile $content -Encoding UTF8

    Write-Host "✅ 学习已记录: $entryId" -ForegroundColor Green
    Write-Host "   类别: $Category" -ForegroundColor White
    Write-Host "   优先级: $Priority" -ForegroundColor $(switch ($Priority) { "critical" { "Red" }; "high" { "Yellow" }; "medium" { "Cyan" }; "low" { "Green" } })
    Write-Host "   状态: $Status" -ForegroundColor Gray

    return $entryId
}

# 记录错误
function Write-Error {
    param(
        [string]$Message,
        [string]$Category = "general",
        [string]$Command = $null,
        [string]$Context = $null,
        [string]$Priority = "high",
        [string]$Status = "pending",
        [string]$Reproducible = "unknown"
    )

    $entryId = New-EntryId -Type "error"
    $timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")

    $content = @"

## [$entryId] error

**Logged**: $timestamp
**Priority**: $Priority
**Status**: $Status

### Summary
$Message

### Error
$(if ($Message -match ".*?`n") {
    $Message -replace "`n", "`n    "
} else {
    $Message
})

### Context
$(if ($Command) { "- Command: $Command`n" })
$(if ($Context) { "- Context: $Context`n" })

### Suggested Fix
$(if ($Message -match ".*?`n") {
    $Message -replace "`n", "`n    "
} else {
    $Message
})

### Metadata
- **Reproducible**: $Reproducible
- **Related Files**: $(if ($Command) { $Command })
---

"@

    Add-Content $errorFile $content -Encoding UTF8

    Write-Host "❌ 错误已记录: $entryId" -ForegroundColor Red
    Write-Host "   优先级: $Priority" -ForegroundColor $(switch ($Priority) { "critical" { "Red" }; "high" { "Yellow" }; "medium" { "Cyan" }; "low" { "Green" } })
    Write-Host "   状态: $Status" -ForegroundColor Gray

    return $entryId
}

# 记录功能请求
function Write-FeatureRequest {
    param(
        [string]$Capability,
        [string]$Description,
        [string]$UserContext,
        [int]$Complexity = 2,
        [string]$Priority = "medium",
        [string]$Status = "pending",
        [string]$Frequency = "first_time"
    )

    $entryId = New-EntryId -Type "feature"
    $timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")

    $content = @"

## [$entryId] $Capability

**Logged**: $timestamp
**Priority**: $Priority
**Status**: $Status

### Requested Capability
$Capability

### User Context
$UserContext

### Complexity Estimate
$Complexity (simple | medium | complex)

### Suggested Implementation
$Description

### Metadata
- **Frequency**: $Frequency
- **Related Features**: $(if ($FeatureRequest) { $FeatureRequest })

---

"@

    Add-Content $featureFile $content -Encoding UTF8

    Write-Host "✅ 功能请求已记录: $entryId" -ForegroundColor Green
    Write-Host "   能力: $Capability" -ForegroundColor White
    Write-Host "   优先级: $Priority" -ForegroundColor $(switch ($Priority) { "critical" { "Red" }; "high" { "Yellow" }; "medium" { "Cyan" }; "low" { "Green" } })

    return $entryId
}

# 审查学习
function Invoke-Review {
    Write-Host "`n📋 学习记录审查" -ForegroundColor Cyan

    if (-not (Test-Path $learningDir)) {
        Write-Host "❌ 学习目录不存在" -ForegroundColor Red
        return
    }

    # 统计pending项目
    $pendingCount = 0
    $resolvedCount = 0
    $priorityHigh = 0

    foreach ($file in @($learningFile, $errorFile, $featureFile)) {
        if (Test-Path $file) {
            $content = Get-Content $file -Raw
            $entries = [regex]::Matches($content, "^## \[([^\]]+)\].*$")

            foreach ($match in $entries) {
                $entryId = $match.Groups[1].Value
                $line = $match.Value
                $status = if ($line -match "Status:\s*(\w+)") { $matches[1] } else { "unknown" }

                if ($status -eq "pending") { $pendingCount++ }
                if ($status -eq "resolved") { $resolvedCount++ }
                if ($line -match "Priority:\s*(critical|high)") { $priorityHigh++ }
            }
        }
    }

    Write-Host "`n📊 审查结果:" -ForegroundColor Yellow
    Write-Host "   待处理项目: $pendingCount" -ForegroundColor $(if ($pendingCount -gt 0) { "Red" } else { "Green" })
    Write-Host "   已解决: $resolvedCount" -ForegroundColor Green
    Write-Host "   高优先级: $priorityHigh" -ForegroundColor $(if ($priorityHigh -gt 0) { "Yellow" } else { "Gray" })

    # 识别需要优先处理的项目
    if ($pendingCount -gt 0 -and $priorityHigh -gt 0) {
        Write-Host "`n⚠️  发现高优先级待处理项目，建议优先解决:" -ForegroundColor Red

        foreach ($file in @($learningFile, $errorFile, $featureFile)) {
            if (Test-Path $file) {
                $content = Get-Content $file -Raw
                $lines = $content -split "`n"

                for ($i = 0; $i -lt $lines.Count; $i++) {
                    if ($lines[$i] -match "^## \[([^\]]+)\].*$") {
                        $entryId = $match.Groups[1].Value

                        # 检查下一行
                        if ($i + 1 -lt $lines.Count) {
                            $line2 = $lines[$i + 1]

                            if ($line2 -match "Status:\s*(pending)" -and $line2 -match "Priority:\s*(critical|high)") {
                                Write-Host "`n   🔴 $($line2 -replace "Status:", "   状态:") $($line2 -replace "Priority:", "   优先级:")" -ForegroundColor Red
                                Write-Host "      ID: $entryId" -ForegroundColor White

                                # 查找Summary
                                for ($j = $i + 2; $j -lt [Math]::Min($i + 10, $lines.Count); $j++) {
                                    if ($lines[$j] -match "^### Summary") {
                                        $summary = $lines[$j + 1] -replace "^  ", ""
                                        Write-Host "      摘要: $summary" -ForegroundColor Gray
                                        break
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    # 检查过期项目
    $daysSinceCreation = (Get-Date -Date "2026-02-13" -ErrorAction SilentlyContinue).Days
    Write-Host "`n⏰ 检查过期项目..." -ForegroundColor Yellow

    foreach ($file in @($learningFile, $errorFile, $featureFile)) {
        if (Test-Path $file) {
            $content = Get-Content $file -Raw
            $entries = [regex]::Matches($content, "^## \[([^\]]+)\].*$")

            foreach ($match in $entries) {
                $entryId = $match.Groups[1].Value
                $line = $match.Value

                if ($line -match "Status:\s*(pending|in_progress)" -and $line -notmatch "Priority:\s*(critical|high)") {
                    # 检查是否超过7天
                    if ($daysSinceCreation -gt $config.resolveAfter) {
                        Write-Host "`n   📅 超过7天未处理: $entryId" -ForegroundColor Yellow
                        Write-Host "      建议: 评估是否需要提升优先级或更新状态" -ForegroundColor Gray
                    }
                }
            }
        }
    }

    Write-Host "`n" -NoNewline
}

# 解析条目
function Resolve-Entry {
    param([string]$EntryId, [string]$Resolution, [string]$Status = "resolved")

    $files = @($learningFile, $errorFile, $featureFile)

    foreach ($file in $files) {
        if (Test-Path $file) {
            $content = Get-Content $file -Raw
            $lines = $content -split "`n"

            $updatedLines = @()
            $found = $false

            for ($i = 0; $i -lt $lines.Count; $i++) {
                $line = $lines[$i]

                if ($line -match "^## \[$EntryId\]") {
                    $found = $true

                    # 找到状态行并更新
                    for ($j = $i + 1; $j -lt $lines.Count; $j++) {
                        if ($lines[$j] -match "^Status:\s*(\w+)") {
                            $lines[$j] = $lines[$j] -replace "Status:\s*\w+", "Status: $Status"

                            # 添加Resolution
                            if ($Resolution) {
                                $lines[$j] += "`n### Resolution`n$Resolution"
                            }

                            break
                        }
                    }
                }

                $updatedLines += $lines[$i]
            }

            if ($found) {
                $updatedContent = $updatedLines -join "`n"
                $updatedContent | Set-Content $file -Encoding UTF8
                Write-Host "✅ 条目已更新: $EntryId -> $Status" -ForegroundColor Green
            }
        }
    }
}

# 统计信息
function Get-Stats {
    Write-Host "`n📊 学习记录统计" -ForegroundColor Cyan

    $stats = @{
        learnings = @{ total = 0; pending = 0; resolved = 0; critical = 0 }
        errors = @{ total = 0; pending = 0; resolved = 0; critical = 0 }
        features = @{ total = 0; pending = 0; resolved = 0 }
    }

    foreach ($file in @($learningFile, $errorFile, $featureFile)) {
        if (Test-Path $file) {
            $content = Get-Content $file -Raw
            $entries = [regex]::Matches($content, "^## \[([^\]]+)\].*$")

            foreach ($match in $entries) {
                $entryId = $match.Groups[1].Value
                $line = $match.Value

                if ($line -match "Status:\s*(\w+)") {
                    $status = $matches[1]
                    $stats.files[$entryId.Split('-')[0]].total++
                }

                if ($line -match "Priority:\s*(critical|high)" -and $line -match "Status:\s*(pending)") {
                    $stats.files[$entryId.Split('-')[0]].pending++
                }

                if ($line -match "Priority:\s*(critical|high)" -and $line -match "Status:\s*(resolved)") {
                    $stats.files[$entryId.Split('-')[0]].resolved++
                }
            }
        }
    }

    Write-Host "`n📈 LEARNINGS:" -ForegroundColor Yellow
    Write-Host "   总数: $($stats.learnings.total)" -ForegroundColor White
    Write-Host "   待处理: $($stats.learnings.pending)" -ForegroundColor $(if ($stats.learnings.pending -gt 0) { "Red" } else { "Green" })
    Write-Host "   已解决: $($stats.learnings.resolved)" -ForegroundColor Green
    Write-Host "   高优先级待处理: $($stats.learnings.critical)" -ForegroundColor $(if ($stats.learnings.critical -gt 0) { "Yellow" } else { "Gray" })

    Write-Host "`n🚨 ERRORS:" -ForegroundColor Yellow
    Write-Host "   总数: $($stats.errors.total)" -ForegroundColor White
    Write-Host "   待处理: $($stats.errors.pending)" -ForegroundColor $(if ($stats.errors.pending -gt 0) { "Red" } else { "Green" })
    Write-Host "   已解决: $($stats.errors.resolved)" -ForegroundColor Green

    Write-Host "`n💡 FEATURE REQUESTS:" -ForegroundColor Yellow
    Write-Host "   总数: $($stats.features.total)" -ForegroundColor White
    Write-Host "   待处理: $($stats.features.pending)" -ForegroundColor $(if ($stats.features.pending -gt 0) { "Yellow" } else { "Green" })

    Write-Host "`n" -NoNewline
}

# 主程序
Write-Host "`n🦞 自我修复 - 学习记录系统" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Gray

switch ($Action) {
    "log" {
        if (-not $Message) {
            Write-Host "❌ 需要指定Message参数" -ForegroundColor Red
            break
        }

        if ($Type -eq "learning") {
            Write-Learning -Category $Category -Message $Message -Status "pending"
        }
        elseif ($Type -eq "error") {
            Write-Error -Message $Message -Category $Category
        }
        elseif ($Type -eq "feature") {
            Write-FeatureRequest -Capability $Category -Description $Message
        }
        else {
            Write-Host "❌ 未知的Type: $Type" -ForegroundColor Red
        }
    }

    "review" {
        Invoke-Review
    }

    "resolve" {
        if (-not $EntryId) {
            Write-Host "❌ 需要指定EntryId参数" -ForegroundColor Red
            break
        }
        Resolve-Entry -EntryId $EntryId -Resolution $Resolution -Status "resolved"
    }

    "stats" {
        Get-Stats
    }

    default {
        Write-Host "用法:" -ForegroundColor Yellow
        Write-Host "  ./learning-tracker.ps1 -Action log -Type <learning|error|feature> -Message <message>" -ForegroundColor White
        Write-Host "  ./learning-tracker.ps1 -Action review                        # 审查学习" -ForegroundColor White
        Write-Host "  ./learning-tracker.ps1 -Action resolve -EntryId <id>        # 解析条目" -ForegroundColor White
        Write-Host "  ./learning-tracker.ps1 -Action stats                         # 统计信息" -ForegroundColor White
    }
}

Write-Host "`n" -NoNewline
