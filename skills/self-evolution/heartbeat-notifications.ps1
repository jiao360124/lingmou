# Heartbeat通知系统

# @Author: 灵眸
# @Version: 1.0.0
# @Date: 2026-02-14
# @Purpose: 管理Heartbeat通知发送

# 通知配置
$NotificationConfig = @{
    enabled = $true
    channels = @{
        "heartbeat" = $true    # Heartbeat日志
        "telegram" = $true     # Telegram通知
        "console" = $true      # 控制台输出
    }
    notifications = @{
        "task-completed" = @{
            enabled = $true
            template = "✅ 任务完成: {taskName}"
            priority = "normal"
        }
        "task-failed" = @{
            enabled = $true
            template = "❌ 任务失败: {taskName} - {errorMessage}"
            priority = "high"
        }
        "queue-full" = @{
            enabled = $true
            template = "⚠️ 任务队列已满 ({count}/{max})"
            priority = "high"
        }
        "system-start" = @{
            enabled = $true
            template = "🚀 Heartbeat通知系统启动"
            priority = "normal"
        }
        "system-stop" = @{
            enabled = $true
            template = "🛑 Heartbeat通知系统停止"
            priority = "high"
        }
    }
}

# 通知历史
$NotificationHistory = @()

# ============ 核心功能 ============

function Send-Notification {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Type,

        [Parameter(Mandatory=$false)]
        [hashtable]$Data = @{},

        [Parameter(Mandatory=$false)]
        [string]$Channel = "all",

        [Parameter(Mandatory=$false)]
        [string]$Priority = "normal",

        [Parameter(Mandatory=$false)]
        [switch]$DryRun = $false
    )

    if (-not $NotificationConfig.enabled) {
        return
    }

    # 检查通知类型是否启用
    if (-not $NotificationConfig.notifications.ContainsKey($Type)) {
        Write-Host "⚠️ 未知通知类型: $Type" -ForegroundColor Yellow
        return
    }

    if (-not $NotificationConfig.notifications[$Type].enabled) {
        return
    }

    # 获取通知模板
    $Template = $NotificationConfig.notifications[$Type].template
    $Message = Format-NotificationTemplate -Template $Template -Data $Data

    # 确定发送渠道
    if ($Channel -eq "all") {
        $ChannelsToUse = @(
            "heartbeat",
            "telegram",
            "console"
        )
    } else {
        $ChannelsToUse = @($Channel)
    }

    # 发送通知
    foreach ($Channel in $ChannelsToUse) {
        if ($NotificationConfig.channels[$Channel]) {
            if ($DryRun) {
                Write-Host "[Dry Run] $Channel: $Message" -ForegroundColor DarkGray
            } else {
                Send-NotificationToChannel -Channel $Channel -Message $Message -Priority $Priority
            }
        }
    }

    # 记录历史
    Add-NotificationHistory -Type $Type -Message $Message -Priority $Priority
}

function Send-NotificationToChannel {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Channel,

        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [string]$Priority = "normal"
    )

    switch ($Channel) {
        "console" {
            # 控制台输出
            switch ($Priority) {
                "high"    { Write-Host "$Message" -ForegroundColor Red }
                "normal"  { Write-Host "$Message" -ForegroundColor Green }
                "low"     { Write-Host "$Message" -ForegroundColor Cyan }
            }
        }

        "heartbeat" {
            # Heartbeat日志
            Write-HeartbeatLog -Message $Message -Type "notification" -Priority $Priority
        }

        "telegram" {
            # Telegram通知
            $ChatId = "1520225096"  # 言野的Telegram ID
            $ApiToken = $env:OPENCLAW_TELEGRAM_API_TOKEN

            if ($ApiToken) {
                Send-TelegramNotification -ChatId $ChatId -ApiToken $ApiToken -Message $Message
            } else {
                Write-Host "⚠️  Telegram API Token 未配置" -ForegroundColor Yellow
            }
        }

        default {
            Write-Host "⚠️ 未知渠道: $Channel" -ForegroundColor Yellow
        }
    }
}

function Format-NotificationTemplate {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Template,

        [Parameter(Mandatory=$true)]
        [hashtable]$Data
    )

    $Formatted = $Template

    # 替换模板变量
    foreach ($Key in $Data.Keys) {
        $Formatted = $Formatted -replace "\{$Key\}", $Data[$Key]
    }

    return $Formatted
}

function Add-NotificationHistory {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Type,

        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [string]$Priority = "normal"
    )

    $Notification = @{
        type = $Type
        message = $Message
        priority = $Priority
        timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    $NotificationHistory += $Notification

    # 限制历史记录数量
    while ($NotificationHistory.Count -gt 100) {
        $NotificationHistory.RemoveAt(0)
    }
}

function Get-NotificationHistory {
    param(
        [Parameter(Mandatory=$false)]
        [int]$Limit = 20
    )

    return $NotificationHistory | Select-Object -First $Limit
}

function Clear-NotificationHistory {
    $NotificationHistory = @()
    Write-Host "✓ 通知历史已清除" -ForegroundColor Green
}

function Set-NotificationChannel {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Channel,

        [Parameter(Mandatory=$false)]
        [bool]$Enabled
    )

    if ($NotificationConfig.channels.ContainsKey($Channel)) {
        $NotificationConfig.channels[$Channel] = $Enabled
        Write-Host "✓ 渠道 $Channel: $(if ($Enabled) {'启用'} else {'禁用'})" -ForegroundColor Green
    } else {
        Write-Host "✗ 未知渠道: $Channel" -ForegroundColor Red
    }
}

function Enable-Notification {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Type
    )

    if ($NotificationConfig.notifications.ContainsKey($Type)) {
        $NotificationConfig.notifications[$Type].enabled = $true
        Write-Host "✓ 通知类型 $Type 已启用" -ForegroundColor Green
    } else {
        Write-Host "✗ 未知通知类型: $Type" -ForegroundColor Red
    }
}

function Disable-Notification {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Type
    )

    if ($NotificationConfig.notifications.ContainsKey($Type)) {
        $NotificationConfig.notifications[$Type].enabled = $false
        Write-Host "✓ 通知类型 $Type 已禁用" -ForegroundColor Green
    } else {
        Write-Host "✗ 未知通知类型: $Type" -ForegroundColor Red
    }
}

function Write-HeartbeatLog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [string]$Type = "info",

        [Parameter(Mandatory=$false)]
        [string]$Priority = "normal"
    )

    $LogEntry = @{
        timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        type = $Type
        priority = $Priority
        message = $Message
    }

    # 添加到Heartbeat日志文件
    $LogFile = "$PSScriptRoot/../data/heartbeat-logs.json"

    if (-not (Test-Path (Split-Path $LogFile))) {
        New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null
    }

    if (Test-Path $LogFile) {
        $ExistingLogs = Get-Content -Path $LogFile | ConvertFrom-Json
        $ExistingLogs += $LogEntry
        $ExistingLogs | ConvertTo-Json -Depth 10 | Out-File -FilePath $LogFile -Encoding UTF8
    } else {
        @($LogEntry) | ConvertTo-Json -Depth 10 | Out-File -FilePath $LogFile -Encoding UTF8
    }
}

# ============ 预定义通知 ============

function Send-TaskNotification {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Type,

        [Parameter(Mandatory=$true)]
        [string]$TaskName,

        [Parameter(Mandatory=$false)]
        [string]$ErrorMessage = ""
    )

    $Data = @{
        taskName = $TaskName
        errorMessage = $ErrorMessage
    }

    switch ($Type) {
        "completed" {
            Send-Notification -Type "task-completed" -Data $Data -Priority "normal"
        }
        "failed" {
            Send-Notification -Type "task-failed" -Data $Data -Priority "high"
        }
        default {
            Write-Host "⚠️ 未知任务通知类型: $Type" -ForegroundColor Yellow
        }
    }
}

function Send-QueueNotification {
    param(
        [Parameter(Mandatory=$true)]
        [int]$Count,
        [Parameter(Mandatory=$false)]
        [int]$Max
    )

    $Data = @{
        count = $Count
        max = $Max
    }

    Send-Notification -Type "queue-full" -Data $Data -Priority "high"
}

# ============ 初始化 ============

Write-Host "`n✓ Heartbeat通知系统已启动" -ForegroundColor Green
Write-Host "  通知中心: $NotificationConfig.enabled" -ForegroundColor Cyan
Write-Host "  渠道: $(($NotificationConfig.channels.GetEnumerator() | Where-Object { $_.Value }).Count)/3" -ForegroundColor Cyan
