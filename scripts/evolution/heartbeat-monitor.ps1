<#
.SYNOPSIS
    心跳监控系统 - 监控Moltbook、网络和API的健康状态

.DESCRIPTION
    每30分钟检查一次Moltbook、网络和API的连通性
    超过阈值时触发预警和降级
    记录所有心跳事件到日志和历史文件

.AUTHOR
    Self-Evolution Engine - Week 5

.VERSION
    1.0.0

.PARAMETER CheckMoltbook
    检查Moltbook心跳 (默认: $true)

.PARAMETER CheckNetwork
    检查网络连接 (默认: $true)

.PARAMETER CheckAPI
    检查API连通性 (默认: $true)

.PARAMETER LogToConsole
    输出到控制台 (默认: $true)

.PARAMETER NoRun
    只生成配置文件，不执行 (默认: $false)

.EXAMPLE
    .\heartbeat-monitor.ps1 -CheckMoltbook $true -CheckNetwork $true -CheckAPI $true

.EXAMPLE
    .\heartbeat-monitor.ps1 -NoRun

.NOTES
    心跳间隔: 每30分钟
    警告阈值: 2次失败
    降级阈值: 3次失败
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [bool]$CheckMoltbook = $true,

    [Parameter(Mandatory = $false)]
    [bool]$CheckNetwork = $true,

    [Parameter(Mandatory = $false)]
    [bool]$CheckAPI = $true,

    [Parameter(Mandatory = $false)]
    [bool]$LogToConsole = $true,

    [Parameter(Mandatory = $false)]
    [bool]$NoRun = $false
)

# ============================================================================
# 配置和常量
# ============================================================================

$CONFIG = @{
    ScriptName = "Heartbeat Monitor"
    Version = "1.0.0"
    StartTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

$Settings = @{
    # 心跳配置
    HeartbeatInterval = 30  # 分钟
    MoltbookURL = "https://api.moltbook.com/heartbeat"
    NetworkCheckURL = "https://www.google.com"
    APICheckURL = "https://api.openai.com"

    # 阈值配置
    WarningThreshold = 2    # 次数
    DowngradeThreshold = 3  # 次数

    # 日志配置
    LogPath = "logs/heartbeat.log"
    HistoryPath = "data/heartbeat-history.json"
    StatusPath = "data/heartbeat-status.json"

    # 重试配置
    MaxRetries = 3
    RetryDelay = 30  # 秒

    # 日志格式
    LogFormat = "yyyy-MM-dd HH:mm:ss.fff"
}

# 创建必要的目录
$directories = @(
    "logs",
    "data"
)

foreach ($dir in $directories) {
    if (-not (Test-Path -Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
    }
}

# ============================================================================
# 函数定义
# ============================================================================

function Write-Log {
    <#
    .SYNOPSIS
        写入日志文件和（可选）控制台

    .PARAMETER Message
        日志消息

    .PARAMETER Level
        日志级别: INFO / WARNING / ERROR / CRITICAL
    #>
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR", "CRITICAL")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format $Settings.LogFormat
    $logMessage = "[$timestamp] [$Level] $Message"

    # 写入文件
    $logMessage | Out-File -FilePath $Settings.LogPath -Append -Encoding UTF8

    # 写入控制台
    if ($LogToConsole) {
        $foregroundColor = switch ($Level) {
            "INFO" { "White" }
            "WARNING" { "Yellow" }
            "ERROR" { "Red" }
            "CRITICAL" { "DarkRed" }
        }
        Write-Host $logMessage -ForegroundColor $foregroundColor
    }

    return $logMessage
}

function Test-Connection {
    <#
    .SYNOPSIS
        测试连接性

    .PARAMETER URL
        要测试的URL

    .PARAMETER MaxTimeout
        最大超时时间（秒）
    #>
    param(
        [string]$URL,
        [int]$MaxTimeout = 10
    )

    try {
        $response = Invoke-WebRequest -Uri $URL -Method Get -TimeoutSec $MaxTimeout -UseBasicParsing -ErrorAction Stop
        return @{
            Success = $true
            StatusCode = $response.StatusCode
            ResponseTime = $response.ResponseUri.AbsoluteUri
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            StatusCode = $null
        }
    }
}

function Initialize-State {
    <#
    .SYNOPSIS
        初始化状态文件

    #>
    $initialState = @{
        Checks = @{
            Moltbook = @{
                TotalChecks = 0
                SuccessCount = 0
                FailureCount = 0
                LastCheck = $null
                CurrentStatus = "unknown"
            }
            Network = @{
                TotalChecks = 0
                SuccessCount = 0
                FailureCount = 0
                LastCheck = $null
                CurrentStatus = "unknown"
            }
            API = @{
                TotalChecks = 0
                SuccessCount = 0
                FailureCount = 0
                LastCheck = $null
                CurrentStatus = "unknown"
            }
        }
        Warnings = 0
        Downgrades = 0
        LastUpdated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }

    $initialState | ConvertTo-Json -Depth 10 | Out-File -FilePath $Settings.StatusPath -Encoding UTF8
    Write-Log "状态文件初始化完成" -Level INFO
}

function Update-State {
    <#
    .SYNOPSIS
        更新状态文件

    .PARAMETER CheckType
        检查类型: Moltbook / Network / API

    .PARAMETER Success
        是否成功

    .PARAMETER Message
        消息
    #>
    param(
        [string]$CheckType,
        [bool]$Success,
        [string]$Message
    )

    $stateFile = Get-Content -Path $Settings.StatusPath -Raw | ConvertFrom-Json

    # 更新统计
    $stateFile.Checks.$CheckType.TotalChecks++
    if ($Success) {
        $stateFile.Checks.$CheckType.SuccessCount++
    }
    else {
        $stateFile.Checks.$CheckType.FailureCount++
    }

    $stateFile.Checks.$CheckType.LastCheck = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # 确定当前状态
    $failureCount = $stateFile.Checks.$CheckType.FailureCount
    if ($failureCount -ge $Settings.DowngradeThreshold) {
        $stateFile.Checks.$CheckType.CurrentStatus = "downgrade"
        $stateFile.Downgrades++
        Write-Log "$CheckType 当前状态: 降级 (失败 $failureCount 次)" -Level WARNING
    }
    elseif ($failureCount -ge $Settings.WarningThreshold) {
        $stateFile.Checks.$CheckType.CurrentStatus = "warning"
        $stateFile.Warnings++
        Write-Log "$CheckType 当前状态: 警告 (失败 $failureCount 次)" -Level WARNING
    }
    else {
        $stateFile.Checks.$CheckType.CurrentStatus = "healthy"
    }

    $stateFile.LastUpdated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # 保存状态
    $stateFile | ConvertTo-Json -Depth 10 | Out-File -FilePath $Settings.StatusPath -Encoding UTF8

    Write-Log "$CheckType 检查: $Message" -Level INFO
}

function Save-History {
    <#
    .SYNOPSIS
        保存心跳历史到历史文件

    #>
    $heartbeatRecord = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        MoltbookStatus = $state.Checks.Moltbook.CurrentStatus
        MoltbookFailureCount = $state.Checks.Moltbook.FailureCount
        NetworkStatus = $state.Checks.Network.CurrentStatus
        NetworkFailureCount = $state.Checks.Network.FailureCount
        APIStatus = $state.Checks.API.CurrentStatus
        APIFailureCount = $state.Checks.API.FailureCount
        Warnings = $state.Warnings
        Downgrades = $state.Downgrades
    }

    $history = @()
    if (Test-Path -Path $Settings.HistoryPath) {
        $history = Get-Content -Path $Settings.HistoryPath -Raw | ConvertFrom-Json
    }
    $history += $heartbeatRecord

    # 只保留最近100条记录
    if ($history.Count -gt 100) {
        $history = $history | Select-Object -Last 100
    }

    $history | ConvertTo-Json -Depth 10 | Out-File -FilePath $Settings.HistoryPath -Encoding UTF8
}

function Calculate-HealthScore {
    <#
    .SYNOPSIS
        计算健康评分

    .OUTPUTS
        健康评分 (0-100)
    #>
    $totalChecks = $state.Checks.Moltbook.TotalChecks +
                   $state.Checks.Network.TotalChecks +
                   $state.Checks.API.TotalChecks

    if ($totalChecks -eq 0) {
        return 100
    }

    $totalSuccess = $state.Checks.Moltbook.SuccessCount +
                    $state.Checks.Network.SuccessCount +
                    $state.Checks.API.SuccessCount

    $healthScore = [math]::Round(($totalSuccess / $totalChecks) * 100, 2)

    return $healthScore
}

function Display-Status {
    <#
    .SYNOPSIS
        显示当前状态

    #>
    Clear-Host
    Write-Host "`n" -NoNewline
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host "          心跳监控系统状态" -ForegroundColor Cyan
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host ""

    # 状态条形图
    Write-Host "网络连接状态:" -ForegroundColor Yellow
    $moltbookBar = [math]::Round(($state.Checks.Moltbook.SuccessCount / $state.Checks.Moltbook.TotalChecks) * 100, 0)
    Write-Host "  Moltbook: " -NoNewline
    Write-Host ("█" * $moltbookBar) -ForegroundColor $(if ($state.Checks.Moltbook.CurrentStatus -eq "healthy") { "Green" } else { "Red" })
    Write-Host "  " + ("$moltbookBar%") + "`n"

    $networkBar = [math]::Round(($state.Checks.Network.SuccessCount / $state.Checks.Network.TotalChecks) * 100, 0)
    Write-Host "  网络: " -NoNewline
    Write-Host ("█" * $networkBar) -ForegroundColor $(if ($state.Checks.Network.CurrentStatus -eq "healthy") { "Green" } else { "Red" })
    Write-Host "  " + ("$networkBar%") + "`n"

    $apiBar = [math]::Round(($state.Checks.API.SuccessCount / $state.Checks.API.TotalChecks) * 100, 0)
    Write-Host "  API: " -NoNewline
    Write-Host ("█" * $apiBar) -ForegroundColor $(if ($state.Checks.API.CurrentStatus -eq "healthy") { "Green" } else { "Red" })
    Write-Host "  " + ("$apiBar%") + "`n"

    # 详细统计
    Write-Host "`n详细统计:" -ForegroundColor Yellow
    Write-Host "  Moltbook: "
    Write-Host "    总检查次数: $($state.Checks.Moltbook.TotalChecks)"
    Write-Host "    成功次数: $($state.Checks.Moltbook.SuccessCount)"
    Write-Host "    失败次数: $($state.Checks.Moltbook.FailureCount)"
    Write-Host "    状态: $($state.Checks.Moltbook.CurrentStatus) $($state.Checks.Moltbook.LastCheck)"

    Write-Host "  网络: "
    Write-Host "    总检查次数: $($state.Checks.Network.TotalChecks)"
    Write-Host "    成功次数: $($state.Checks.Network.SuccessCount)"
    Write-Host "    失败次数: $($state.Checks.Network.FailureCount)"
    Write-Host "    状态: $($state.Checks.Network.CurrentStatus) $($state.Checks.Network.LastCheck)"

    Write-Host "  API: "
    Write-Host "    总检查次数: $($state.Checks.API.TotalChecks)"
    Write-Host "    成功次数: $($state.Checks.API.SuccessCount)"
    Write-Host "    失败次数: $($state.Checks.API.FailureCount)"
    Write-Host "    状态: $($state.Checks.API.CurrentStatus) $($state.Checks.API.LastCheck)"

    Write-Host "`n警告和降级: "
    Write-Host "  警告次数: $($state.Warnings)"
    Write-Host "  降级次数: $($state.Downgrades)"

    # 健康评分
    $healthScore = Calculate-HealthScore
    Write-Host "`n健康评分: " -NoNewline
    Write-Host ("█" * $healthScore) -ForegroundColor $(if ($healthScore -ge 80) { "Green" } elseif ($healthScore -ge 60) { "Yellow" } else { "Red" })
    Write-Host " " + ("$healthScore%")

    Write-Host "`n" + "=" * 80 -ForegroundColor Cyan
    Write-Host "  最后更新: $($state.LastUpdated)" -ForegroundColor Gray
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host "`n"
}

# ============================================================================
# 主程序
# ============================================================================

Write-Log "心跳监控系统启动" -Level INFO
Write-Log "配置:" -Level INFO
Write-Log "  心跳间隔: $($Settings.HeartbeatInterval) 分钟" -Level INFO
Write-Log "  警告阈值: $($Settings.WarningThreshold) 次失败" -Level INFO
Write-Log "  降级阈值: $($Settings.DowngradeThreshold) 次失败" -Level INFO

# 初始化状态
if (-not (Test-Path -Path $Settings.StatusPath)) {
    Initialize-State
}

# 加载状态
$state = Get-Content -Path $Settings.StatusPath -Raw | ConvertFrom-Json

# ============================================================================
# 心跳检查
# ============================================================================

if ($NoRun) {
    Write-Log "NoRun模式：只生成配置文件" -Level INFO
    exit 0
}

$heartbeatStartTime = Get-Date
Write-Log "`n" + "=" * 80 -Level INFO
Write-Log "      开始心跳检查" -Level INFO
Write-Log "=" * 80 -Level INFO
Write-Log "检查时间: $($heartbeatStartTime)" -Level INFO
Write-Log ""

# Moltbook检查
if ($CheckMoltbook) {
    Write-Log "`n检查 Moltbook..." -Level INFO
    Write-Log "URL: $($Settings.MoltbookURL)" -Level INFO

    $retryCount = 0
    $moltbookSuccess = $false

    while ($retryCount -lt $Settings.MaxRetries) {
        $result = Test-Connection -URL $Settings.MoltbookURL

        if ($result.Success) {
            $moltbookSuccess = $true
            Write-Log "  ✅ Moltbook 检查成功" -Level INFO
            Write-Log "  状态码: $($result.StatusCode)" -Level INFO
            break
        }
        else {
            $retryCount++
            if ($retryCount -lt $Settings.MaxRetries) {
                Write-Log "  ⚠️  Moltbook 检查失败，重试 ($retryCount/$($Settings.MaxRetries))..." -Level WARNING
                Write-Log "  错误: $($result.Error)" -Level WARNING
                Start-Sleep -Seconds $Settings.RetryDelay
            }
            else {
                Write-Log "  ❌ Moltbook 检查失败，已达到最大重试次数" -Level ERROR
                Write-Log "  错误: $($result.Error)" -Level ERROR
            }
        }
    }

    Update-State -CheckType "Moltbook" -Success $moltbookSuccess -Message "Moltbook 检查 $(if ($moltbookSuccess) { '成功' } else { '失败' })"
}

# 网络检查
if ($CheckNetwork) {
    Write-Log "`n检查网络连接..." -Level INFO
    Write-Log "URL: $($Settings.NetworkCheckURL)" -Level INFO

    $retryCount = 0
    $networkSuccess = $false

    while ($retryCount -lt $Settings.MaxRetries) {
        $result = Test-Connection -URL $Settings.NetworkCheckURL

        if ($result.Success) {
            $networkSuccess = $true
            Write-Log "  ✅ 网络连接检查成功" -Level INFO
            Write-Log "  状态码: $($result.StatusCode)" -Level INFO
            break
        }
        else {
            $retryCount++
            if ($retryCount -lt $Settings.MaxRetries) {
                Write-Log "  ⚠️  网络连接检查失败，重试 ($retryCount/$($Settings.MaxRetries))..." -Level WARNING
                Write-Log "  错误: $($result.Error)" -Level WARNING
                Start-Sleep -Seconds $Settings.RetryDelay
            }
            else {
                Write-Log "  ❌ 网络连接检查失败，已达到最大重试次数" -Level ERROR
                Write-Log "  错误: $($result.Error)" -Level ERROR
            }
        }
    }

    Update-State -CheckType "Network" -Success $networkSuccess -Message "网络检查 $(if ($networkSuccess) { '成功' } else { '失败' })"
}

# API检查
if ($CheckAPI) {
    Write-Log "`n检查 API 连通性..." -Level INFO
    Write-Log "URL: $($Settings.APICheckURL)" -Level INFO

    $retryCount = 0
    $apiSuccess = $false

    while ($retryCount -lt $Settings.MaxRetries) {
        $result = Test-Connection -URL $Settings.APICheckURL

        if ($result.Success) {
            $apiSuccess = $true
            Write-Log "  ✅ API 连通性检查成功" -Level INFO
            Write-Log "  状态码: $($result.StatusCode)" -Level INFO
            break
        }
        else {
            $retryCount++
            if ($retryCount -lt $Settings.MaxRetries) {
                Write-Log "  ⚠️  API 连通性检查失败，重试 ($retryCount/$($Settings.MaxRetries))..." -Level WARNING
                Write-Log "  错误: $($result.Error)" -Level WARNING
                Start-Sleep -Seconds $Settings.RetryDelay
            }
            else {
                Write-Log "  ❌ API 连通性检查失败，已达到最大重试次数" -Level ERROR
                Write-Log "  错误: $($result.Error)" -Level ERROR
            }
        }
    }

    Update-State -CheckType "API" -Success $apiSuccess -Message "API 检查 $(if ($apiSuccess) { '成功' } else { '失败' })"
}

# 保存历史
Save-History

# 显示状态
Display-Status

# 计算健康评分
$healthScore = Calculate-HealthScore
$healthStatus = switch ($healthScore) {
    { $_ -ge 80 } { "healthy" }
    { $_ -ge 60 } { "warning" }
    default { "critical" }
}

Write-Log "`n健康评分: $healthScore% ($healthStatus)" -Level $(switch ($healthStatus) {
    "healthy" { "INFO" }
    "warning" { "WARNING" }
    default { "ERROR" }
})

# 最终结果
Write-Log "`n" + "=" * 80 -Level INFO
Write-Log "      心跳检查完成" -Level INFO
Write-Log "=" * 80 -Level INFO
Write-Log "总耗时: $([math]::Round((Get-Date - $heartbeatStartTime).TotalSeconds, 2)) 秒" -Level INFO
Write-Log ""

exit 0
