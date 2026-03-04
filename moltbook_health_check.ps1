# 灵眸健康检查系统 V2.0

<#
.SYNOPSIS
综合健康检查 - 监控所有系统和指标

.DESCRIPTION
定期检查系统状态，显示性能指标，提供健康报告

.VERSION
2.0.0

.AUTHOR
灵眸 (2026-02-09)
#>

# ============================================
# 配置参数
# ============================================

$Script:HealthCheckConfig = @{
    # 检查间隔（秒）
    Interval = 30

    # 检查的项目
    Checks = @{
        SystemStatus = $true
        Network = $true
        APIHealth = $true
        Memory = $true
        ErrorRate = $true
        TaskQueue = $true
    }
}

# ============================================
# 系统状态检查
# ============================================

<#
.SYNOPSIS
检查系统状态
#>
function Test-SystemStatus {
    try {
        $os = Get-ComputerInfo
        $uptime = (Get-Date) - $os.WindowsInstallationDate
        $uptimeHours = [math]::Round($uptime.TotalHours, 2)

        return @{
            Status = "Running"
            Uptime = "$uptimeHours 小时"
            Platform = $os.WindowsProductName
            Architecture = $os.OSArchitecture
            Success = $true
        }
    }
    catch {
        return @{
            Status = "Unknown"
            Uptime = "N/A"
            Platform = "N/A"
            Architecture = "N/A"
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# ============================================
# 网络检查
# ============================================

<#
.SYNOPSIS
检查网络状态
#>
function Test-NetworkStatus {
    try {
        $pingResult = Test-Connection -ComputerName "google.com" -Count 1 -Quiet

        if ($pingResult) {
            $ping = Test-Connection -ComputerName "google.com" -Count 1
            $latency = [math]::Round($ping.ResponseTime, 2)

            return @{
                Status = "Connected"
                Latency = "$latency ms"
                PingSuccess = $true
                Success = $true
            }
        }
        else {
            return @{
                Status = "Disconnected"
                Latency = "N/A"
                PingSuccess = $false
                Success = $false
            }
        }
    }
    catch {
        return @{
            Status = "Error"
            Latency = "N/A"
            PingSuccess = $false
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# ============================================
# API健康检查
# ============================================

<#
.SYNOPSIS
检查API健康状态
#>
function Test-APIHealth {
    try {
        $api_key = "moltbook_sk_3j4CexZeIxD4sfw0F4S-oUsemCW3NiEX"

        # 检查Moltbook API
        $url = "https://www.moltbook.com/api/v1/agents/status"
        $headers = @{ "Authorization" = "Bearer $api_key" }

        $response = Invoke-RestMethod -Uri $url -Method GET -Headers $headers -TimeoutSec 10

        if ($response.success -and $response.status -eq "claimed") {
            return @{
                Moltbook = @{
                    Status = "Healthy"
                    ResponseTime = "Ready"
                    Claimed = $true
                    Success = $true
                }
            }
        }
        else {
            return @{
                Moltbook = @{
                    Status = "Unhealthy"
                    ResponseTime = "Error"
                    Claimed = $false
                    Success = $false
                }
            }
        }
    }
    catch {
        return @{
            Moltbook = @{
                Status = "Error"
                ResponseTime = "Timeout"
                Claimed = $false
                Success = $false
                Error = $_.Exception.Message
            }
        }
    }
}

# ============================================
# 内存检查
# ============================================

<#
.SYNOPSIS
检查内存使用
#>
function Test-MemoryStatus {
    try {
        $os = Get-ComputerInfo
        $totalMemory = [math]::Round(($os.WindowsPhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1GB, 2)

        $freeMemory = [math]::Round($os.WindowsPhysicalMemoryAvailable, 2)
        $memoryUsage = [math]::Round($totalMemory - $freeMemory, 2)
        $usagePercent = [math]::Round(($memoryUsage / $totalMemory * 100), 1)

        # 评分
        if ($usagePercent -lt 50) {
            $status = "Good"
            $color = "Green"
        }
        elseif ($usagePercent -lt 75) {
            $status = "Warning"
            $color = "Yellow"
        }
        else {
            $status = "Critical"
            $color = "Red"
        }

        return @{
            Total = "$totalMemory GB"
            Free = "$freeMemory GB"
            Used = "$memoryUsage GB"
            UsagePercent = "$usagePercent%"
            Status = $status
            Success = $true
        }
    }
    catch {
        return @{
            Total = "N/A"
            Free = "N/A"
            Used = "N/A"
            UsagePercent = "N/A"
            Status = "Error"
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# ============================================
# 错误率检查
# ============================================

<#
.SYNOPSIS
检查错误率
#>
function Test-ErrorRate {
    try {
        $logFile = "C:\Users\Administrator\.openclaw\workspace\logs\error_log.jsonl"

        if (-not (Test-Path $logFile)) {
            return @{
                TotalErrors = 0
                ErrorRate = "0%"
                Status = "Healthy"
                Success = $true
            }
        }

        $logs = Get-Content $logFile -ErrorAction SilentlyContinue | ConvertFrom-Json
        $totalLogs = $logs.Count

        if ($totalLogs -gt 0) {
            # 最近24小时的错误
            $cutoffTime = (Get-Date).AddHours(-24)
            $recentLogs = @()
            foreach ($log in $logs) {
                if ($log.Timestamp -ge $cutoffTime) {
                    $recentLogs += $log
                }
            }

            $recentCount = $recentLogs.Count
            $errorRate = [math]::Round(($recentCount / 24 * 100), 2) # 假设每小时一个检查

            if ($errorRate -lt 1) {
                $status = "Healthy"
                $color = "Green"
            }
            elseif ($errorRate -lt 5) {
                $status = "Warning"
                $color = "Yellow"
            }
            else {
                $status = "Critical"
                $color = "Red"
            }

            return @{
                TotalErrors = $recentCount
                ErrorRate = "$errorRate%"
                Status = $status
                Success = $true
            }
        }
        else {
            return @{
                TotalErrors = 0
                ErrorRate = "0%"
                Status = "Healthy"
                Success = $true
            }
        }
    }
    catch {
        return @{
            TotalErrors = 0
            ErrorRate = "N/A"
            Status = "Unknown"
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# ============================================
# 任务队列检查
# ============================================

<#
.SYNOPSIS
检查任务队列状态
#>
function Test-TaskQueueStatus {
    try {
        $queueFile = "C:\Users\Administrator\.openclaw\workspace\tasks\active_queue.json"

        if (-not (Test-Path $queueFile)) {
            return @{
                TotalTasks = 0
                Pending = 0
                Running = 0
                Completed = 0
                Status = "Empty"
                Success = $true
            }
        }

        $tasks = Get-Content $queueFile -ErrorAction SilentlyContinue | ConvertFrom-Json

        if (-not $tasks) {
            return @{
                TotalTasks = 0
                Pending = 0
                Running = 0
                Completed = 0
                Status = "Empty"
                Success = $true
            }
        }

        $pending = ($tasks | Where-Object { $_.Status -eq "Pending" }).Count
        $running = ($tasks | Where-Object { $_.Status -eq "Running" }).Count
        $completed = ($tasks | Where-Object { $_.Status -eq "Completed" }).Count

        if ($pending -eq 0 -and $running -eq 0) {
            $status = "Idle"
        }
        elseif ($running -gt 0) {
            $status = "Active"
        }
        else {
            $status = "Processing"
        }

        return @{
            TotalTasks = $tasks.Count
            Pending = $pending
            Running = $running
            Completed = $completed
            Status = $status
            Success = $true
        }
    }
    catch {
        return @{
            TotalTasks = 0
            Pending = 0
            Running = 0
            Completed = 0
            Status = "Unknown"
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# ============================================
# 综合健康报告
# ============================================

<#
.SYNOPSIS
生成综合健康报告
#>
function Get-HealthReport {
    Write-Host ""
    Write-Host "🏥 灵眸健康检查报告" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

    # 系统状态
    $system = Test-SystemStatus
    Write-Host "`n【系统状态】" -ForegroundColor White
    Write-Host "状态: $($system.Status)" -ForegroundColor $(if ($system.Success) { "Green" } else { "Red" })
    Write-Host "运行时间: $($system.Uptime)"
    Write-Host "平台: $($system.Platform) ($($system.Architecture))"

    # 网络
    $network = Test-NetworkStatus
    Write-Host "`n【网络状态】" -ForegroundColor White
    Write-Host "连接: $($network.Status)" -ForegroundColor $(if ($network.PingSuccess) { "Green" } else { "Red" })
    Write-Host "延迟: $($network.Latency)"

    # API
    $api = Test-APIHealth
    Write-Host "`n【API健康】" -ForegroundColor White
    $apiStatus = $api.Moltbook.Status
    Write-Host "Moltbook: $apiStatus" -ForegroundColor $(if ($api.Moltbook.Success) { "Green" } else { "Red" })
    Write-Host "认证状态: $([bool]$api.Moltbook.Claimed)"

    # 内存
    $memory = Test-MemoryStatus
    Write-Host "`n【内存使用】" -ForegroundColor White
    Write-Host "总计: $($memory.Total)"
    Write-Host "已用: $($memory.Used) ($($memory.UsagePercent))" -ForegroundColor $(if ($memory.Status -eq "Good") { "Green" } elseif ($memory.Status -eq "Critical") { "Red" } else { "Yellow" })
    Write-Host "状态: $($memory.Status)"

    # 错误率
    $error = Test-ErrorRate
    Write-Host "`n【错误率】" -ForegroundColor White
    Write-Host "总错误数: $($error.TotalErrors)" -ForegroundColor $(if ($error.ErrorRate -lt "5%") { "Green" } else { "Yellow" })
    Write-Host "错误率: $($error.ErrorRate)"
    Write-Host "状态: $($error.Status)"

    # 任务队列
    $taskQueue = Test-TaskQueueStatus
    Write-Host "`n【任务队列】" -ForegroundColor White
    Write-Host "总任务: $($taskQueue.TotalTasks)"
    Write-Host "待执行: $($taskQueue.Pending)"
    Write-Host "执行中: $($taskQueue.Running)"
    Write-Host "已完成: $($taskQueue.Completed)"
    Write-Host "状态: $($taskQueue.Status)"

    # 综合评分
    $score = Calculate-HealthScore $system $network $api $memory $error $taskQueue

    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host "`n【健康评分】" -ForegroundColor White
    Write-Host "$score/100" -ForegroundColor $(if ($score -ge 80) { "Green" } elseif ($score -ge 60) { "Yellow" } else { "Red" })
    Write-Host ""

    return @{
        Score = $score
        System = $system
        Network = $network
        API = $api
        Memory = $memory
        Error = $error
        TaskQueue = $taskQueue
    }
}

<#
.SYNopsis
计算健康评分
#>
function Calculate-HealthScore {
    param(
        [hashtable]$System,
        [hashtable]$Network,
        [hashtable]$API,
        [hashtable]$Memory,
        [hashtable]$Error,
        [hashtable]$TaskQueue
    )

    $score = 100
    $details = @()

    # 系统状态
    if ($System.Success) {
        $score -= 5
        $details += "系统状态: 良好"
    }

    # 网络状态
    if ($Network.PingSuccess) {
        $score -= 10
        $details += "网络连接: 良好"
    }

    # API状态
    if ($API.Moltbook.Success) {
        $score -= 10
        $details += "API健康: 良好"
    }

    # 内存状态
    if ($Memory.UsagePercent -lt 50) {
        $score -= 10
        $details += "内存使用: 优"
    }
    elseif ($Memory.UsagePercent -lt 75) {
        $score -= 5
        $details += "内存使用: 正常"
    }

    # 错误率
    if ($Error.ErrorRate -lt "1%") {
        $score -= 15
        $details += "错误率: 优"
    }
    elseif ($Error.ErrorRate -lt "5%") {
        $score -= 10
        $details += "错误率: 正常"
    }

    # 任务队列
    if ($TaskQueue.Status -eq "Empty" -or $TaskQueue.Status -eq "Idle") {
        $score -= 5
        $details += "任务队列: 待处理"
    }

    # 限制范围 0-100
    $score = [math]::Max(0, [math]::Min(100, $score))

    return @{
        Score = $score
        Details = $details
    }
}

# ============================================
# 初始化
# ============================================

<#
.SYNOPSIS
初始化健康检查系统
#>
function Initialize-HealthCheck {
    Write-Host "🚀 灵眸健康检查系统已启动" -ForegroundColor Cyan
    Write-Host "   - 系统状态: 已启用" -ForegroundColor Gray
    Write-Host "   - 网络检查: 已启用" -ForegroundColor Gray
    Write-Host "   - API健康: 已启用" -ForegroundColor Gray
    Write-Host "   - 内存监控: 已启用" -ForegroundColor Gray
    Write-Host "   - 错误率统计: 已启用" -ForegroundColor Gray
    Write-Host "   - 任务队列监控: 已启用" -ForegroundColor Gray
    Write-Host ""

    # 创建日志目录
    $logDir = "C:\Users\Administrator\.openclaw\workspace\logs"
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
}

# 导出函数
Export-ModuleMember -Function @(
    'Get-HealthReport',
    'Test-SystemStatus',
    'Test-NetworkStatus',
    'Test-APIHealth',
    'Test-MemoryStatus',
    'Test-ErrorRate',
    'Test-TaskQueueStatus',
    'Initialize-HealthCheck'
)

# 自动初始化
Initialize-HealthCheck
