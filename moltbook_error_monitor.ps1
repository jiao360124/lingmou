# 灵眸错误监控系统

<#
.SYNOPSIS
实时错误监控和日志分析系统

.DESCRIPTION
检测、记录和分析错误，为自我修复提供数据支持

.VERSION
2.0.0

.AUTHOR
灵眸 (2026-02-09)
#>

# ============================================
# 错误分类定义
# ============================================

$Script:ErrorCategories = @{
    Network = @{
        Name = "网络错误"
        Symptoms = @("timeout", "connection refused", "DNS failure", "network unreachable")
        Priority = "High"
        Recovery = "Retry with exponential backoff, check network connection"
    }

    API = @{
        Name = "API错误"
        Symptoms = @("429", "rate limit", "500", "503", "400", "401")
        Priority = "Medium"
        Recovery = "Wait for cooldown, implement rate limiting, optimize request frequency"
    }

    Memory = @{
        Name = "内存错误"
        Symptoms = @("out of memory", "memory limit", "high memory usage")
        Priority = "High"
        Recovery = "Clear variables, optimize state management, implement pagination"
    }

    Filesystem = @{
        Name = "文件系统错误"
        Symptoms = @("permission denied", "file not found", "disk full")
        Priority = "High"
        Recovery = "Check permissions, verify file paths, free disk space"
    }

    Timeout = @{
        Name = "超时错误"
        Symptoms = @("timeout", "operation timed out", "timeout error")
        Priority = "Medium"
        Recovery = "Increase timeout, optimize query, implement async operations"
    }

    Other = @{
        Name = "其他错误"
        Symptoms = @("*")
        Priority = "Low"
        Recovery = "Generic error handling, log details, notify human if needed"
    }
}

# ============================================
# 错误记录
# ============================================

<#
.SYNOPSIS
记录错误到日志
#>
function Add-ErrorLog {
    param(
        [string]$ErrorType,
        [string]$ErrorMessage,
        [hashtable]$Context = @{},
        [string]$ErrorId = (Get-Date -Format 'yyyyMMddHHmmss')
    )

    $logEntry = @{
        ErrorId = $ErrorId
        Timestamp = Get-Date
        ErrorType = $ErrorType
        ErrorMessage = $ErrorMessage
        Context = $Context
        Severity = $Script:ErrorCategories[$ErrorType].Priority
    }

    $logFile = "C:\Users\Administrator\.openclaw\workspace\logs\error_log.jsonl"

    # 创建日志目录
    $logDir = "C:\Users\Administrator\.openclaw\workspace\logs"
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    $logEntry | ConvertTo-Json -Depth 10 | Out-File -FilePath $logFile -Append -Encoding UTF8

    return $logEntry
}

# ============================================
# 错误分类器
# ============================================

<#
.SYNOPSIS
分类错误类型
#>
function Classify-Error {
    param(
        [string]$ErrorMessage
    )

    foreach ($category in $Script:ErrorCategories.Keys) {
        $symptoms = $Script:ErrorCategories[$category].Symptoms
        foreach ($symptom in $symptoms) {
            if ($ErrorMessage -like "*$symptom*") {
                return @{
                    Category = $category
                    Name = $Script:ErrorCategories[$category].Name
                    Symptoms = $symptoms
                    Priority = $Script:ErrorCategories[$category].Priority
                    Recovery = $Script:ErrorCategories[$category].Recovery
                }
            }
        }
    }

    return $Script:ErrorCategories["Other"]
}

# ============================================
# 错误分析
# ============================================

<#
.SYNOPSIS
分析错误日志
#>
function Analyze-ErrorLogs {
    param(
        [int]$Hours = 24
    )

    $cutoffTime = (Get-Date).AddHours(-$Hours)
    $logFile = "C:\Users\Administrator\.openclaw\workspace\logs\error_log.jsonl"

    if (-not (Test-Path $logFile)) {
        return @{}
    }

    $logs = Get-Content $logFile -ErrorAction SilentlyContinue | ConvertFrom-Json
    $recentErrors = @()

    foreach ($log in $logs) {
        if ($log.Timestamp -ge $cutoffTime) {
            $recentErrors += $log
        }
    }

    # 统计各类错误
    $stats = @{
        Total = $recentErrors.Count
        ByType = @{}
        ByPriority = @{
            High = 0
            Medium = 0
            Low = 0
        }
        RecentErrors = @()
    }

    foreach ($error in $recentErrors) {
        # 按类型统计
        if (-not $stats.ByType.ContainsKey($error.ErrorType)) {
            $stats.ByType[$error.ErrorType] = 0
        }
        $stats.ByType[$error.ErrorType]++

        # 按优先级统计
        switch ($error.Severity) {
            "High" { $stats.ByPriority.High++ }
            "Medium" { $stats.ByPriority.Medium++ }
            "Low" { $stats.ByPriority.Low++ }
        }

        # 最近的错误（最多显示10个）
        if ($stats.RecentErrors.Count -lt 10) {
            $stats.RecentErrors += $error
        }
    }

    return $stats
}

# ============================================
# 监控面板
# ============================================

<#
.SYNOPSIS
显示错误监控面板
#>
function Show-ErrorMonitorPanel {
    param(
        [int]$Hours = 24
    )

    Write-Host ""
    Write-Host "📊 灵眸错误监控面板" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

    $stats = Analyze-ErrorLogs -Hours $Hours

    # 总体统计
    Write-Host "`n【总体统计】" -ForegroundColor White
    Write-Host "总错误数: $($stats.Total)" -ForegroundColor $(if ($stats.Total -eq 0) { "Green" } else { "Yellow" })

    # 按优先级统计
    Write-Host "`n【错误优先级】" -ForegroundColor White
    Write-Host "🔴 高优先级: $($stats.ByPriority.High)" -ForegroundColor Red
    Write-Host "🟡 中优先级: $($stats.ByPriority.Medium)" -ForegroundColor Yellow
    Write-Host "🟢 低优先级: $($stats.ByPriority.Low)" -ForegroundColor Green

    # 按类型统计
    if ($stats.ByType) {
        Write-Host "`n【错误类型】" -ForegroundColor White
        foreach ($type in $stats.ByType.Keys | Sort-Object { $stats.ByType[$_] -gt 0 } -Descending) {
            $count = $stats.ByType[$type]
            $percentage = ($count / $stats.Total * 100).ToString('F1')
            Write-Host "   $type: $count ($percentage%)" -ForegroundColor Gray
        }
    }

    # 最近的错误
    if ($stats.RecentErrors.Count -gt 0) {
        Write-Host "`n【最近错误】" -ForegroundColor White
        foreach ($error in $stats.RecentErrors) {
            Write-Host "   [$($error.Timestamp -Format 'HH:mm:ss')] $($error.ErrorType): $($error.ErrorMessage)" -ForegroundColor Gray
        }
    }

    Write-Host ""

    return $stats
}

# ============================================
# 错误恢复建议
# ============================================

<#
.SYNOPSIS
获取错误恢复建议
#>
function Get-ErrorRecovery {
    param(
        [string]$ErrorType
    )

    $category = $Script:ErrorCategories[$ErrorType]
    return @{
        Type = $category.Name
        Recovery = $category.Recovery
        Priority = $category.Priority
    }
}

# ============================================
# 自动错误通知
# ============================================

<#
.SYNOPSIS
检查是否需要通知人类
#>
function Test-ShouldNotifyHuman {
    param(
        [hashtable]$Stats
    )

    $highErrorCount = $Stats.ByPriority.High
    $criticalErrors = $Stats.ByPriority.High

    if ($criticalErrors -ge 5) {
        return @{
            ShouldNotify = $true
            Reason = "Critical errors reached threshold"
            Count = $criticalErrors
        }
    }

    if ($Stats.Total -gt 50) {
        return @{
            ShouldNotify = $true
            Reason = "High error rate detected"
            Count = $Stats.Total
        }
    }

    return @{
        ShouldNotify = $false
        Reason = "Error level is acceptable"
        Count = $Stats.Total
    }
}

# ============================================
# 初始化
# ============================================

<#
.SYNOPSIS
初始化错误监控系统
#>
function Initialize-ErrorMonitor {
    Write-Host "🚀 灵眸错误监控系统已启动" -ForegroundColor Cyan
    Write-Host "   - 错误分类: 已配置" -ForegroundColor Gray
    Write-Host "   - 日志记录: 已启用" -ForegroundColor Gray
    Write-Host "   - 监控面板: 已启用" -ForegroundColor Gray
    Write-Host "   - 自动通知: 已启用" -ForegroundColor Gray
    Write-Host ""

    # 创建日志目录
    $logDir = "C:\Users\Administrator\.openclaw\workspace\logs"
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
}

# 导出函数
Export-ModuleMember -Function @(
    'Add-ErrorLog',
    'Classify-Error',
    'Analyze-ErrorLogs',
    'Show-ErrorMonitorPanel',
    'Get-ErrorRecovery',
    'Test-ShouldNotifyHuman',
    'Initialize-ErrorMonitor'
)

# 自动初始化
Initialize-ErrorMonitor
