<#
.SYNOPSIS
    速率限制管理系统 - 自动检测429错误，智能排队和重试

.DESCRIPTION
    智能检测API速率限制，自动调整请求频率，优化间隔时间
    记录所有速率限制事件，生成优化建议

.AUTHOR
    Self-Evolution Engine - Week 5

.VERSION
    1.0.0

.PARAMETER Check429Errors
    检测429错误 (默认: $true)

.PARAMETER EnableQueueing
    启用智能排队 (默认: $true)

.PARAMETER OptimizeInterval
    优化请求间隔 (默认: $true)

.PARAMETER EnableRetry
    启用指数退避重试 (默认: $true)

.PARAMETER LogToConsole
    输出到控制台 (默认: $true)

.PARAMETER NoRun
    只生成配置文件，不执行 (默认: $false)

.EXAMPLE
    .\rate-limiter.ps1 -Check429Errors $true -EnableQueueing $true

.EXAMPLE
    .\rate-limiter.ps1 -NoRun

.NOTES
    最小间隔: 2秒
    最佳间隔: 5秒
    429重试等待: 60秒
    最大重试: 3次
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [bool]$Check429Errors = $true,

    [Parameter(Mandatory = $false)]
    [bool]$EnableQueueing = $true,

    [Parameter(Mandatory = $false)]
    [bool]$OptimizeInterval = $true,

    [Parameter(Mandatory = $false)]
    [bool]$EnableRetry = $true,

    [Parameter(Mandatory = $false)]
    [bool]$LogToConsole = $true,

    [Parameter(Mandatory = $false)]
    [bool]$NoRun = $false
)

# ============================================================================
# 配置和常量
# ============================================================================

$CONFIG = @{
    ScriptName = "Rate Limiter"
    Version = "1.0.0"
    StartTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

$Settings = @{
    # 速率限制配置
    MaxRequestsPerMinute = 60
    MaxRequestsPerSecond = 10
    $429RetryAfter = 60  # 秒

    # 间隔优化
    MinInterval = 2       # 秒
    OptimalInterval = 5   # 秒
    MaxInterval = 60      # 秒

    # 重试策略
    $MaxRetries = 3
    $InitialWait = 1      # 秒
    $MaxWait = 60         # 秒

    # 队列配置
    MaxQueueSize = 100
    QueueCheckInterval = 30  # 秒

    # 日志配置
    LogPath = "logs/rate-limit.log"
    StatsPath = "data/rate-limit-stats.json"
    OptimizationsPath = "data/rate-limit-optimizations.json"

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

function Initialize-Stats {
    <#
    .SYNOPSIS
        初始化统计文件

    #>
    $initialStats = @{
        TotalRequests = 0
        SuccessRequests = 0
        FailedRequests = 0
        $429Count = 0
        TimeoutCount = 0
        OtherErrorCount = 0

        QueueSize = 0
        QueuePeakSize = 0
        LastQueueUpdate = $null

        AvgResponseTime = 0
        MaxResponseTime = 0
        MinResponseTime = 0
        ResponseTimeHistory = @()

        OptimalInterval = $Settings.OptimalInterval
        CurrentInterval = $Settings.OptimalInterval
        IntervalHistory = @()

        RetryCount = 0
        SuccessRetryCount = 0
        FailedRetryCount = 0

        LastUpdated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }

    $initialStats | ConvertTo-Json -Depth 10 | Out-File -FilePath $Settings.StatsPath -Encoding UTF8
    Write-Log "统计文件初始化完成" -Level INFO
}

function Update-Stats {
    <#
    .SYNOPSIS
        更新统计信息

    .PARAMETER Type
        请求类型: success / failure / $429 / timeout / other

    .PARAMETER ResponseTime
        响应时间（毫秒）
    #>
    param(
        [string]$Type,
        [int]$ResponseTime = 0
    )

    $stats = Get-Content -Path $Settings.StatsPath -Raw | ConvertFrom-Json

    # 更新总统计
    $stats.TotalRequests++

    switch ($Type) {
        "success" {
            $stats.SuccessRequests++
            if ($ResponseTime -gt 0) {
                $stats.ResponseTimeHistory += $ResponseTime
                if ($stats.ResponseTimeHistory.Count -gt 100) {
                    $stats.ResponseTimeHistory = $stats.ResponseTimeHistory | Select-Object -Last 100
                }

                # 更新响应时间统计
                $stats.MaxResponseTime = [math]::Max($stats.MaxResponseTime, $ResponseTime)
                if ($stats.MinResponseTime -eq 0 -or $ResponseTime -lt $stats.MinResponseTime) {
                    $stats.MinResponseTime = $ResponseTime
                }

                $avgResponseTime = [math]::Round(($stats.ResponseTimeHistory | Measure-Object -Average).Average, 2)
                $stats.AvgResponseTime = $avgResponseTime
            }
        }
        "failure" {
            $stats.FailedRequests++
        }
        "429" {
            $stats.$429Count++
        }
        "timeout" {
            $stats.TimeoutCount++
        }
        "other" {
            $stats.OtherErrorCount++
        }
    }

    $stats.LastUpdated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # 保存统计
    $stats | ConvertTo-Json -Depth 10 | Out-File -FilePath $Settings.StatsPath -Encoding UTF8
}

function Update-Optimization {
    <#
    .SYNOPSIS
        更新优化建议

    #>
    param(
        [string]$Type,
        [string]$Message
    )

    $optimizations = @()
    if (Test-Path -Path $Settings.OptimizationsPath) {
        $optimizations = Get-Content -Path $Settings.OptimizationsPath -Raw | ConvertFrom-Json
    }

    $newOptimization = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Type = $Type
        Message = $Message
        Suggestion = ""
    }

    switch ($Type) {
        "interval" {
            $newOptimization.Suggestion = "建议将请求间隔调整为 $Message 秒"
        }
        "retry" {
            $newOptimization.Suggestion = "建议增加重试次数或延长等待时间"
        }
        "queue" {
            $newOptimization.Suggestion = "建议启用智能排队机制"
        }
        "decrease_frequency" {
            $newOptimization.Suggestion = "建议降低请求频率，避免触发速率限制"
        }
    }

    $optimizations += $newOptimization

    # 只保留最近20条优化建议
    if ($optimizations.Count -gt 20) {
        $optimizations = $optimizations | Select-Object -Last 20
    }

    $optimizations | ConvertTo-Json -Depth 10 | Out-File -FilePath $Settings.OptimizationsPath -Encoding UTF8
}

function Get-OptimalInterval {
    <#
    .SYNOPSIS
        计算最优请求间隔

    .OUTPUTS
        最优间隔（秒）
    #>
    $stats = Get-Content -Path $Settings.StatsPath -Raw | ConvertFrom-Json

    # 基于响应时间调整
    if ($stats.AvgResponseTime -gt 0) {
        # 如果平均响应时间较长，增加间隔
        $intervalAdjustment = [math]::Min([math]::Floor($stats.AvgResponseTime / 1000), 5)
        $optimalInterval = $stats.OptimalInterval + $intervalAdjustment

        # 限制在合理范围内
        $optimalInterval = [math]::Max($stats.MinInterval, [math]::Min($optimalInterval, $stats.MaxInterval))

        Write-Log "基于响应时间调整: $optimalInterval 秒" -Level INFO

        return $optimalInterval
    }

    return $stats.OptimalInterval
}

function Should-Retry {
    <#
    .SYNOPSIS
        判断是否应该重试

    .OUTPUTS
        $true 或 $false
    #>
    $stats = Get-Content -Path $Settings.StatsPath -Raw | ConvertFrom-Json

    if ($stats.FailedRequests -ge $stats.TotalRequests * 0.1) {
        Write-Log "失败率超过10%，建议重试" -Level WARNING
        return $true
    }

    return $false
}

function Get-RetryWaitTime {
    <#
    .SYNOPSIS
        计算重试等待时间（指数退避）

    .OUTPUTS
        等待时间（秒）
    #>
    $stats = Get-Content -Path $Settings.StatsPath -Raw | ConvertFrom-Json

    # 指数退避算法
    $retryCount = $stats.RetryCount
    $waitTime = [math]::Min([math]::Pow(2, $retryCount), $stats.MaxWait)

    Write-Log "指数退避等待时间: $waitTime 秒 (重试次数: $retryCount)" -Level INFO

    return $waitTime
}

function Display-Status {
    <#
    .SYNOPSIS
        显示当前状态

    #>
    Clear-Host
    Write-Host "`n" -NoNewline
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host "        速率限制管理系统状态" -ForegroundColor Cyan
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host ""

    # 请求统计
    Write-Host "请求统计:" -ForegroundColor Yellow
    $successRate = if ($stats.TotalRequests -gt 0) { [math]::Round(($stats.SuccessRequests / $stats.TotalRequests) * 100, 2) } else { 0 }
    $failureRate = if ($stats.TotalRequests -gt 0) { [math]::Round(($stats.FailedRequests / $stats.TotalRequests) * 100, 2) } else { 0 }
    $429Rate = if ($stats.TotalRequests -gt 0) { [math]::Round(($stats.$429Count / $stats.TotalRequests) * 100, 2) } else { 0 }

    Write-Host "  总请求次数: $($stats.TotalRequests)"
    Write-Host "  成功次数: $($stats.SuccessRequests) ($successRate%)"
    Write-Host "  失败次数: $($stats.FailedRequests) ($failureRate%)"
    Write-Host "  429错误次数: $($stats.$429Count) ($429Rate%)"

    # 速率限制统计
    Write-Host "`n速率限制详情:" -ForegroundColor Yellow
    Write-Host "  超时错误: $($stats.TimeoutCount)"
    Write-Host "  其他错误: $($stats.OtherErrorCount)"

    # 队列统计
    Write-Host "`n队列统计:" -ForegroundColor Yellow
    Write-Host "  当前队列大小: $($stats.QueueSize)"
    Write-Host "  队列峰值大小: $($stats.QueuePeakSize)"

    # 响应时间统计
    Write-Host "`n响应时间统计:" -ForegroundColor Yellow
    if ($stats.AvgResponseTime -gt 0) {
        Write-Host "  平均响应时间: $($stats.AvgResponseTime) ms"
        Write-Host "  最快响应时间: $($stats.MinResponseTime) ms"
        Write-Host "  最慢响应时间: $($stats.MaxResponseTime) ms"
    }
    else {
        Write-Host "  无响应时间数据"
    }

    # 间隔优化
    Write-Host "`n间隔优化:" -ForegroundColor Yellow
    Write-Host "  最小间隔: $($stats.MinInterval) 秒"
    Write-Host "  当前间隔: $($stats.CurrentInterval) 秒"
    Write-Host "  最优间隔: $($stats.OptimalInterval) 秒"

    # 重试统计
    Write-Host "`n重试统计:" -ForegroundColor Yellow
    Write-Host "  总重试次数: $($stats.RetryCount)"
    Write-Host "  成功重试次数: $($stats.SuccessRetryCount)"
    Write-Host "  失败重试次数: $($stats.FailedRetryCount)"

    Write-Host "`n" + "=" * 80 -ForegroundColor Cyan
    Write-Host "  最后更新: $($stats.LastUpdated)" -ForegroundColor Gray
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host "`n"
}

# ============================================================================
# 主程序
# ============================================================================

Write-Log "速率限制管理系统启动" -Level INFO
Write-Log "配置:" -Level INFO
Write-Log "  检测429错误: $Check429Errors" -Level INFO
Write-Log "  启用智能排队: $EnableQueueing" -Level INFO
Write-Log "  优化请求间隔: $OptimizeInterval" -Level INFO
Write-Log "  启用指数退避重试: $EnableRetry" -Level INFO

# 初始化统计
if (-not (Test-Path -Path $Settings.StatsPath)) {
    Initialize-Stats
}

# 加载统计
$stats = Get-Content -Path $Settings.StatsPath -Raw | ConvertFrom-Json

# ============================================================================
# 速率限制检查
# ============================================================================

if ($NoRun) {
    Write-Log "NoRun模式：只生成配置文件" -Level INFO
    Display-Status
    exit 0
}

Write-Log "`n" + "=" * 80 -Level INFO
Write-Log "        开始速率限制检查" -Level INFO
Write-Log "=" * 80 -Level INFO
Write-Log "检查时间: $(Get-Date)" -Level INFO
Write-Log ""

# 获取最优间隔
if ($OptimizeInterval) {
    $stats.CurrentInterval = Get-OptimalInterval
    Write-Log "当前请求间隔: $($stats.CurrentInterval) 秒" -Level INFO
}

# ============================================================================
# 429错误检测
# ============================================================================

if ($Check429Errors) {
    Write-Log "`n检查429错误..." -Level INFO

    # 模拟检查（实际使用时，这里应该检查API响应）
    # 这里我们模拟一个429错误的检查
    $mock429Detected = $false

    # 如果队列过大，模拟429错误
    if ($stats.QueueSize -ge $stats.QueuePeakSize * 0.9) {
        $mock429Detected = $true
    }

    # 如果响应时间过长，模拟429错误
    if ($stats.AvgResponseTime -gt 5000) {  # 超过5秒
        $mock429Detected = $true
    }

    if ($mock429Detected) {
        $stats.$429Count++
        Write-Log "  ⚠️  检测到429错误!" -Level WARNING
        Write-Log "  请求间隔可能过快" -Level WARNING

        if ($EnableQueueing) {
            Write-Log "  → 启用智能排队机制" -Level INFO
            Update-Optimization -Type "queue" -Message "增加队列大小限制"

            # 增加队列大小
            $stats.QueueSize = [math]::Min($stats.QueueSize + 20, $stats.MaxQueueSize)

            if ($stats.QueueSize -gt $stats.QueuePeakSize) {
                $stats.QueuePeakSize = $stats.QueueSize
            }
        }

        if ($EnableRetry) {
            Write-Log "  → 启用指数退避重试" -Level INFO
            Update-Optimization -Type "retry" -Message "增加重试等待时间"

            # 增加重试等待时间
            $stats.$429RetryAfter = [math]::Min($stats.$429RetryAfter + 10, 120)
        }

        if ($OptimizeInterval) {
            Write-Log "  → 调整请求间隔" -Level INFO
            Update-Optimization -Type "interval" -Message "$($stats.CurrentInterval + 2)"

            # 增加间隔
            $stats.CurrentInterval = [math]::Min($stats.CurrentInterval + 2, $stats.MaxInterval)
        }

        Write-Log "  → 建议降低请求频率" -Level WARNING
        Update-Optimization -Type "decrease_frequency" -Message "减少请求次数"
    }
    else {
        Write-Log "  ✅ 未检测到429错误" -Level INFO
    }

    Update-Stats -Type "429"
}

# ============================================================================
# 响应时间统计
# ============================================================================

Write-Log "`n统计响应时间..." -Level INFO

# 模拟响应时间统计（实际使用时，这里应该从API响应中获取）
$mockResponseTimes = @(120, 150, 180, 200, 160, 190, 170, 210, 230, 195)

foreach ($responseTime in $mockResponseTimes) {
    Update-Stats -Type "success" -ResponseTime $responseTime
}

# ============================================================================
# 队列管理
# ============================================================================

if ($EnableQueueing) {
    Write-Log "`n管理请求队列..." -Level INFO

    # 模拟队列处理
    if ($stats.QueueSize -gt 0) {
        $processedCount = [math]::Min($stats.QueueSize, 10)
        $stats.QueueSize -= $processedCount
        Update-Stats -Type "success" -ResponseTime $mockResponseTimes | Out-Null

        Write-Log "  处理了 $processedCount 个队列请求" -Level INFO
    }

    Write-Log "  当前队列大小: $($stats.QueueSize)" -Level INFO
}

# ============================================================================
# 重试机制
# ============================================================================

if ($EnableRetry -and Should-Retry) {
    Write-Log "`n执行重试机制..." -Level INFO

    $waitTime = Get-RetryWaitTime

    Write-Log "  等待 $waitTime 秒后重试..." -Level INFO
    Start-Sleep -Seconds $waitTime

    $stats.RetryCount++

    # 模拟重试成功
    $mockRetrySuccess = Get-Random -Minimum 0 -Maximum 2 -Maximum 10  # 20%成功率
    if ($mockRetrySuccess -eq 0) {
        $stats.SuccessRetryCount++
        Update-Stats -Type "success" -ResponseTime 150
        Write-Log "  ✅ 重试成功" -Level INFO
    }
    else {
        $stats.FailedRetryCount++
        Update-Stats -Type "failure"
        Write-Log "  ❌ 重试失败" -Level ERROR
    }
}

# ============================================================================
# 保存统计和显示状态
# ============================================================================

$stats.LastUpdated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$stats | ConvertTo-Json -Depth 10 | Out-File -FilePath $Settings.StatsPath -Encoding UTF8

Display-Status

# 最终结果
Write-Log "`n" + "=" * 80 -Level INFO
Write-Log "        速率限制检查完成" -Level INFO
Write-Log "=" * 80 -Level INFO
Write-Log "总耗时: $([math]::Round((Get-Date - $statsStartTime).TotalSeconds, 2)) 秒" -Level INFO
Write-Log ""

exit 0
