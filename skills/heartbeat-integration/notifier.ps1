# Heartbeat通知系统

# @Author: 灵眸
# @Version: 1.0.0
# @Date: 2026-02-13

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("task", "reminder", "completion", "report")]
    [string]$Type,

    [Parameter(Mandatory=$true)]
    [string]$Message,

    [Parameter(Mandatory=$false)]
    [string]$Title = "Heartbeat通知",

    [Parameter(Mandatory=$false)]
    [ValidateSet("info", "success", "warning", "error")]
    [string]$Level = "info",

    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false
)

# 获取脚本路径
$ScriptPath = $PSScriptRoot
$NotifyLogFile = "$ScriptPath/data/notifications.log"

# 初始化结果
$Result = @{
    Success = $false
    Type = $Type
    Title = $Title
    Level = $Level
    StartTime = Get-Date
    EndTime = $null
    Duration = 0
    Messages = @()
    Errors = @{}
    Sent = $false
}

# 日志函数
function Write-Log {
    param([string]$Message, [ValidateSet("INFO", "SUCCESS", "ERROR", "WARNING", "DEBUG")]
    [string]$Level = "INFO")

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Prefix = "[$Timestamp] [$Level]"

    switch ($Level) {
        "INFO"    { Write-Host "$Prefix $Message" -ForegroundColor Cyan }
        "SUCCESS" { Write-Host "$Prefix $Message" -ForegroundColor Green }
        "ERROR"   { Write-Host "$Prefix $Message" -ForegroundColor Red }
        "WARNING" { Write-Host "$Prefix $Message" -ForegroundColor Yellow }
        "DEBUG"   { Write-Host "$Prefix $Message" -ForegroundColor DarkGray }
    }

    $Result.Messages += "$Prefix $Message"
}

try {
    Write-Log "通知系统启动" "INFO"
    Write-Log "通知类型: $Type" "DEBUG"
    Write-Log "通知级别: $Level" "DEBUG"

    # 创建日志条目
    $LogEntry = @{
        timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        type = $Type
        level = $Level
        title = $Title
        message = $Message
    }

    # 添加到日志文件
    $LogEntry | ConvertTo-Json -Depth 10 | Out-File -FilePath $NotifyLogFile -Append -Encoding UTF8 -Force

    Write-Log "日志已记录" "DEBUG"

    # 根据类型发送通知
    switch ($Type) {
        "task" {
            if (-not $DryRun) {
                Write-Log "发送任务通知..." "INFO"
                Write-Host "`n✅ 任务通知" "INFO"
                Write-Host "标题: $Title" "INFO"
                Write-Host "消息: $Message" "INFO"
                Write-Host "`n" "INFO"
                $Result.Sent = $true
            }
        }

        "reminder" {
            if (-not $DryRun) {
                Write-Log "发送提醒通知..." "INFO"
                Write-Host "`n⏰ 提醒通知" "INFO"
                Write-Host "标题: $Title" "INFO"
                Write-Host "消息: $Message" "INFO"
                Write-Host "`n" "INFO"
                $Result.Sent = $true
            }
        }

        "completion" {
            if (-not $DryRun) {
                Write-Log "发送完成通知..." "INFO"
                Write-Host "`n🎉 完成通知" "INFO"
                Write-Host "标题: $Title" "INFO"
                Write-Host "消息: $Message" "INFO"
                Write-Host "`n" "INFO"
                $Result.Sent = $true
            }
        }

        "report" {
            if (-not $DryRun) {
                Write-Log "发送报告通知..." "INFO"
                Write-Host "`n📊 报告通知" "INFO"
                Write-Host "标题: $Title" "INFO"
                Write-Host "消息: $Message" "INFO"
                Write-Host "`n" "INFO"
                $Result.Sent = $true
            }
        }
    }

    # 设置最终状态
    $Result.Success = $true
    $Result.EndTime = Get-Date
    $Result.Duration = ($Result.EndTime - $Result.StartTime).TotalSeconds

    Write-Log "通知完成" "SUCCESS"
    Write-Log "执行时间: $([math]::Round($Result.Duration, 2))秒" "SUCCESS"

} catch {
    $Result.Success = $false
    $Result.Errors = @{ Exception = $_.Exception.Message; StackTrace = $_.ScriptStackTrace }

    Write-Log "通知失败: $($_.Exception.Message)" "ERROR"

} finally {
    return $Result
}
