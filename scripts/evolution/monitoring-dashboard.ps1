# Monitoring Dashboard
# 实时监控系统指标和状态

param(
    [string]$Action = "start"
)

# 配置
$projectRoot = "C:\Users\Administrator\.openclaw\workspace"
$dataFile = Join-Path $projectRoot "metrics\dashboard-data.json"

function Initialize-Dashboard {
    $metrics = @{
        Stability = @{
            NormalTime = 0
            WarningCount = 0
            DegradedCount = 0
            RecoveryCount = 0
        }
        Performance = @{
            AvgResponseTime = 0
            MaxResponseTime = 0
            MinResponseTime = 0
            ErrorRate = 0
        }
        Memory = @{
            CurrentMB = 0
            MaxMB = 0
            UsedMB = 0
        }
        Uptime = @{
            TotalSeconds = 0
            ActiveMinutes = 0
        }
        Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }

    $metrics | ConvertTo-Json -Depth 10 | Out-File $dataFile -Force
    return $metrics
}

function Get-Metrics {
    if (-not (Test-Path $dataFile)) {
        return Initialize-Dashboard
    }

    return Get-Content $dataFile -Raw | ConvertFrom-Json
}

function Update-Metric {
    param($Category, $Metric, $Value)

    $metrics = Get-Metrics
    if (-not $metrics.$Category) {
        $metrics.$Category = @{}
    }
    $metrics.$Category.$Metric = $Value
    $metrics.Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

    $metrics | ConvertTo-Json -Depth 10 | Out-File $dataFile -Force
}

function Calculate-StabilityScore {
    $metrics = Get-Metrics

    $warningRatio = if ($metrics.Stability.WarningCount -gt 0) {
        $metrics.Stability.WarningCount / 100
    } else {
        0
    }

    $degradedRatio = if ($metrics.Stability.DegradedCount -gt 0) {
        $metrics.Stability.DegradedCount / 100
    } else {
        0
    }

    $score = 100
    $score -= ($warningRatio * 10)
    $score -= ($degradedRatio * 20)

    return [math]::Round([math]::Max(0, [math]::Min(100, $score)), 1)
}

function Show-Dashboard {
    Clear-Host
    $metrics = Get-Metrics
    $stabilityScore = Calculate-StabilityScore

    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "           OPENCLAW MONITORING DASHBOARD" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Updated: $($metrics.Timestamp)" -ForegroundColor Gray
    Write-Host ""

    # 稳定性评分
    Write-Host "STABILITY SCORE: " -NoNewline
    if ($stabilityScore -ge 90) {
        Write-Host "$stabilityScore% 🟢 EXCELLENT" -ForegroundColor Green
    } elseif ($stabilityScore -ge 70) {
        Write-Host "$stabilityScore% 🟡 GOOD" -ForegroundColor Yellow
    } elseif ($stabilityScore -ge 50) {
        Write-Host "$stabilityScore% 🟠 FAIR" -ForegroundColor Orange
    } else {
        Write-Host "$stabilityScore% 🔴 POOR" -ForegroundColor Red
    }

    # 稳定性指标
    Write-Host ""
    Write-Host "STABILITY METRICS:" -ForegroundColor White
    Write-Host "  ├─ Normal Time: $($metrics.Stability.NormalTime) seconds" -ForegroundColor Gray
    Write-Host "  ├─ Warnings: $($metrics.Stability.WarningCount)" -ForegroundColor Gray
    Write-Host "  ├─ Degradations: $($metrics.Stability.DegradedCount)" -ForegroundColor Gray
    Write-Host "  └─ Recoveries: $($metrics.Stability.RecoveryCount)" -ForegroundColor Gray

    # 性能指标
    Write-Host ""
    Write-Host "PERFORMANCE METRICS:" -ForegroundColor White
    if ($metrics.Performance.AvgResponseTime -gt 0) {
        Write-Host "  ├─ Avg Response Time: $($metrics.Performance.AvgResponseTime)ms" -ForegroundColor Gray
        Write-Host "  ├─ Max Response Time: $($metrics.Performance.MaxResponseTime)ms" -ForegroundColor Gray
        Write-Host "  ├─ Min Response Time: $($metrics.Performance.MinResponseTime)ms" -ForegroundColor Gray
    }
    Write-Host "  └─ Error Rate: $($metrics.Performance.ErrorRate)%" -ForegroundColor Gray

    # 内存使用
    Write-Host ""
    Write-Host "MEMORY USAGE:" -ForegroundColor White
    if ($metrics.Memory.CurrentMB -gt 0) {
        Write-Host "  ├─ Current: $($metrics.Memory.CurrentMB)MB" -ForegroundColor Gray
        Write-Host "  ├─ Used: $($metrics.Memory.UsedMB)MB" -ForegroundColor Gray
        if ($metrics.Memory.MaxMB -gt 0) {
            $percent = [math]::Round(($metrics.Memory.UsedMB / $metrics.Memory.MaxMB) * 100, 1)
            Write-Host "  └─ Usage: $percent%" -ForegroundColor Gray
        }
    }

    # 运行时间
    Write-Host ""
    Write-Host "UPTIME:" -ForegroundColor White
    if ($metrics.Uptime.TotalSeconds -gt 0) {
        $hours = [math]::Floor($metrics.Uptime.TotalSeconds / 3600)
        $minutes = [math]::Floor(($metrics.Uptime.TotalSeconds % 3600) / 60)
        $seconds = [math]::Floor($metrics.Uptime.TotalSeconds % 60)
        Write-Host "  ├─ Total Time: ${hours}h ${minutes}m $secondss" -ForegroundColor Gray
        Write-Host "  └─ Active: $($metrics.Uptime.ActiveMinutes) minutes" -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
}

function Realtime-Monitor {
    Write-Host "Starting realtime monitoring..." -ForegroundColor Green
    Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow

    while ($true) {
        Show-Dashboard
        Start-Sleep -Seconds 5
    }
}

try {
    switch ($Action) {
        "start" {
            Show-Dashboard
        }

        "update" {
            param($Category, $Metric, $Value)
            Update-Metric -Category $Category -Metric $Metric -Value $Value
            Write-Host "✓ Metric updated: $Category.$Metric = $Value" -ForegroundColor Green
        }

        "monitor" {
            Realtime-Monitor
        }

        "reset" {
            Initialize-Dashboard
            Write-Host "✓ Dashboard reset" -ForegroundColor Green
        }

        default {
            Write-Host "Unknown action: $Action"
            exit 1
        }
    }

} catch {
    Write-Host "✗ :  $_" -ForegroundColor Red
    exit 1
}

