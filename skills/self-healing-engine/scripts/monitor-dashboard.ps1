<#
.SYNOPSIS
    可视化监控面板 - 自我修复引擎实时监控

.DESCRIPTION
    提供自我修复引擎的实时可视化监控面板，包括错误监控、修复统计、健康度评分等。

.VERSION
    2.0.0

.AUTHOR
    灵眸
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('start', 'stop', 'check')]
    [string]$Action = 'check',

    [Parameter(Mandatory=$false)]
    [int]$RefreshInterval = 5
)

$ConfigPath = "$PSScriptRoot/../config/monitor-config.json"
$DashboardPath = "$PSScriptRoot/../dashboard.html"

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
    if (-not (Test-Path $ConfigPath)) {
        @{
            "enabled" = $true
            "monitorInterval" = 5
            "telegramEnabled" = $false
            "telegramToken" = ""
            "telegramChatId" = ""
            "healthThreshold" = 70
            "maxHistory" = 100
        } | ConvertTo-Json -Depth 10 | Set-Content $ConfigPath
    }
}

function Get-MonitorData {
    param(
        [int]$Days = 7
    )

    $output = @{
        timestamp = (Get-Date).ToString("o")
        healthScore = 0
        errorCount = 0
        fixSuccessRate = 0
        snapshotCount = 0
        learningCount = 0
        errorsByType = @{
            timeout = 0
            network = 0
            permission = 0
            not_found = 0
            general = 0
        }
        recentErrors = @()
        recentFixes = @()
    }

    # 读取错误记录
    $errorFile = "..\learnings\ERRORS.md"
    if (Test-Path $errorFile) {
        $content = Get-Content $errorFile -Raw
        $lines = $content -split "`n"

        # 统计错误数量
        $output.errorCount = ($lines | Where-Object { $_ -match "## \[ERR-" }).Count

        # 按类型分类错误
        $lines | Where-Object { $_ -match "## \[ERR-" } | ForEach-Object {
            if ($_ -match "## \[ERR-.*?(\w+).*?\]") {
                $type = $matches[1]
                if ($output.errorsByType.ContainsKey($type)) {
                    $output.errorsByType[$type]++
                }
            }
        }

        # 获取最近错误
        $recentErrors = $lines | Where-Object { $_ -match "## \[ERR-" } | Select-Object -First 10
        $output.recentErrors = $recentErrors
    }

    # 读取学习记录
    $learningFile = "..\learnings\LEARNINGS.md"
    if (Test-Path $learningFile) {
        $content = Get-Content $learningFile -Raw
        $output.learningCount = ($content -split "## \[LRN-").Count
    }

    # 读取快照管理器数据
    $snapshotFile = "..\data\snapshots.json"
    if (Test-Path $snapshotFile) {
        try {
            $snapshots = Get-Content $snapshotFile -Raw | ConvertFrom-Json
            $output.snapshotCount = $snapshots.snapshots.Count
        } catch {
            $output.snapshotCount = 0
        }
    }

    # 计算健康度评分 (0-100)
    $healthScore = 100 - ($output.errorCount * 5)
    if ($healthScore < 0) { $healthScore = 0 }

    # 如果错误太多，扣分
    foreach ($type in $output.errorsByType.Keys) {
        $count = $output.errorsByType[$type]
        if ($count -gt 5) {
            $healthScore -= ($count - 5) * 2
        }
    }

    $output.healthScore = $healthScore

    return $output
}

function Show-Dashboard {
    param(
        [int]$RefreshInterval
    )

    while ($true) {
        Clear-Host

        Write-Host "======================================" -ForegroundColor Cyan
        Write-Host "  自我修复引擎 - 实时监控面板" -ForegroundColor Cyan
        Write-Host "======================================" -ForegroundColor Cyan
        Write-Host "  更新时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
        Write-Host "  刷新间隔: $RefreshInterval 秒" -ForegroundColor Gray
        Write-Host ""

        # 获取监控数据
        $data = Get-MonitorData

        # 显示健康度评分
        Write-Host "【系统健康度评分】" -ForegroundColor White
        $healthColor = if ($data.healthScore -ge 80) { $Colors.Green }
        elseif ($data.healthScore -ge 60) { $Colors.Yellow }
        else { $Colors.Red }

        $healthBar = $healthColor
        $healthText = "健康度: $healthBar $($data.healthScore)/100"

        Write-Host $healthText -ForegroundColor $healthColor

        # 显示错误统计
        Write-Host "`n【错误统计】" -ForegroundColor White
        Write-Host "  总错误数: $($data.errorCount)" -ForegroundColor White

        Write-Host "  错误类型分布:" -ForegroundColor White
        foreach ($type in $data.errorsByType.Keys) {
            $count = $data.errorsByType[$type]
            if ($count -gt 0) {
                $bar = "=" * ($count / 2)
                Write-Host "    $($type): $bar $count" -ForegroundColor $healthColor
            }
        }

        # 显示学习记录
        Write-Host "`n【学习记录】" -ForegroundColor White
        Write-Host "  已记录: $($data.learningCount) 条" -ForegroundColor White

        # 显示快照
        Write-Host "`n【快照管理】" -ForegroundColor White
        Write-Host "  快照数量: $($data.snapshotCount)" -ForegroundColor White

        # 显示最近错误
        if ($data.recentErrors.Count -gt 0) {
            Write-Host "`n【最近错误】" -ForegroundColor White
            $data.recentErrors | ForEach-Object {
                $line = $_.Trim()
                if ($line -match "## \[ERR-([^\]]+)\]") {
                    $errorId = $matches[1]
                    if ($line -match "\*\*Priority\*\*:\s*(\w+)") {
                        $priority = $matches[1]
                        $priorityColor = switch ($priority) {
                            "high" { "🔴" }
                            "medium" { "🟡" }
                            "low" { "🟢" }
                            default { "⚪" }
                        }
                        Write-Host "    $priorityColor [$errorId]" -ForegroundColor $healthColor
                    }
                }
            }
        }

        Write-Host "`n======================================" -ForegroundColor Cyan
        Write-Host "  按 Ctrl+C 停止监控" -ForegroundColor Gray
        Write-Host ""

        # 休眠
        Start-Sleep -Seconds $RefreshInterval
    }
}

try {
    Initialize-Config

    switch ($Action) {
        "check" {
            $data = Get-MonitorData

            Write-Host "📊 自我修复引擎 - 监控数据" -ForegroundColor Cyan
            Write-Host ""

            Write-Host "【健康度评分】" -ForegroundColor White
            $healthColor = if ($data.healthScore -ge 80) { $Colors.Green }
            elseif ($data.healthScore -ge 60) { $Colors.Yellow }
            else { $Colors.Red }

            Write-Host "  评分: $($data.healthScore)/100" -ForegroundColor $healthColor

            Write-Host "`n【统计信息】" -ForegroundColor White
            Write-Host "  错误总数: $($data.errorCount)" -ForegroundColor White
            Write-Host "  学习记录: $($data.learningCount)" -ForegroundColor White
            Write-Host "  快照数量: $($data.snapshotCount)" -ForegroundColor White

            Write-Host "`n【错误类型】" -ForegroundColor White
            foreach ($type in $data.errorsByType.Keys) {
                $count = $data.errorsByType[$type]
                if ($count -gt 0) {
                    Write-Host "  $type: $count" -ForegroundColor $Colors.Yellow
                }
            }

            Write-Host "`n======================================" -ForegroundColor Cyan
            Write-Host "  检查完成" -ForegroundColor Green
        }

        "start" {
            Write-Host "🚀 启动实时监控面板..." -ForegroundColor Cyan
            Show-Dashboard -RefreshInterval $RefreshInterval
        }

        "stop" {
            Write-Host "⏹️  停止监控" -ForegroundColor Yellow
            exit 0
        }
    }
} catch {
    Write-Error "错误: $($_.Exception.Message)"
    Write-Host $_.ScriptStackTrace -ForegroundColor Gray
    exit 1
}
