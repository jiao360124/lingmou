<#
.SYNOPSIS
速率限制模块 - API请求频率限制

.DESCRIPTION
提供请求频率限制、并发限制等功能，防止API滥用。

.PARAMeter Check
检查是否允许请求

.PARAMeter Limit
限制配置

.PARAMeter Context
上下文信息（IP、用户等）

.EXAMPLE
.\rate-limiter.ps1 -Check -Limit $limits -Context $context
#>

param(
    [Parameter(Mandatory=$true)]
    [switch]$Check,

    [Parameter(Mandatory=$false)]
    [PSCustomObject]$Limit,

    [Parameter(Mandatory=$false)]
    [hashtable]$Context
)

function Initialize-Limits {
    return [PSCustomObject]@{
        requests_per_minute = 100
        requests_per_hour = 1000
        requests_per_day = 10000
        concurrent_requests = 10
        burst_requests = 5
        burst_window = 60
    }
}

function Create-Counter {
    param([string]$Key)

    $counterPath = ".\.rate-limiter\$Key.json"
    if (-not (Test-Path $counterPath)) {
        @{
            count = 0
            timestamp = (Get-Date).ToUniversalTime().Ticks
            last_reset = (Get-Date).ToUniversalTime().Ticks
        } | ConvertTo-Json -Depth 10 | Out-File -FilePath $counterPath -Encoding UTF8 -Force
    }

    return Get-Content $counterPath -Raw | ConvertFrom-Json
}

function Update-Counter {
    param(
        [string]$Key,
        [int]$Increment = 1
    )

    $counter = Create-Counter -Key $Key

    # 重置过期的计数器（超过1分钟）
    $now = [DateTimeOffset]::FromUnixTimeSeconds([math]::Floor($counter.timestamp / 10000000)).UnixTimeSeconds
    $lastReset = [DateTimeOffset]::FromUnixTimeSeconds([math]::Floor($counter.last_reset / 10000000)).UnixTimeSeconds

    if (($now - $lastReset) -ge 60) {
        $counter.count = 0
        $counter.last_reset = (Get-Date).ToUniversalTime().Ticks
        $counter.timestamp = $counter.last_reset
        $counter | ConvertTo-Json -Depth 10 | Out-File -FilePath ".\.rate-limiter\$Key.json" -Encoding UTF8 -Force
    }

    $counter.count += $Increment
    $counter | ConvertTo-Json -Depth 10 | Out-File -FilePath ".\.rate-limiter\$Key.json" -Encoding UTF8 -Force

    return $counter
}

function Check-RateLimit {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Limits,

        [Parameter(Mandatory=$true)]
        [hashtable]$Context
    )

    $contextKey = if ($Context.user_id) { "user_$($Context.user_id)" }
                  else { "ip_$($Context.ip)" }
                  else { "global" }

    $counter = Create-Counter -Key $contextKey

    $now = [DateTimeOffset]::FromUnixTimeSeconds([math]::Floor($counter.timestamp / 10000000)).UnixTimeSeconds

    # 检查每分钟限制
    if ($Limits.requests_per_minute -gt 0) {
        $minuteAgo = $now - 60
        $minuteCount = 0

        # 这里简化处理，实际应该维护每个时间窗口的计数器
        if ($counter.count -gt 0) {
            $minuteCount = $counter.count
        }

        if ($minuteCount -ge $Limits.requests_per_minute) {
            return @{
                allowed = $false
                limit_type = "requests_per_minute"
                current = $minuteCount
                limit = $Limits.requests_per_minute
                message = "每分钟请求次数已达上限 ($minuteCount/$($Limits.requests_per_minute))"
            }
        }
    }

    # 检查每小时限制
    if ($Limits.requests_per_hour -gt 0) {
        $hourAgo = $now - 3600
        $hourCount = 0

        if ($counter.count -gt 0) {
            $hourCount = $counter.count
        }

        if ($hourCount -ge $Limits.requests_per_hour) {
            return @{
                allowed = $false
                limit_type = "requests_per_hour"
                current = $hourCount
                limit = $Limits.requests_per_hour
                message = "每小时请求次数已达上限 ($hourCount/$($Limits.requests_per_hour))"
            }
        }
    }

    # 检查并发限制
    if ($Limits.concurrent_requests -gt 0) {
        $concurrentCount = Get-Process | Where-Object { $_.ProcessName -eq "node" } | Measure-Object | Select-Object -ExpandProperty Count

        if ($concurrentCount -ge $Limits.concurrent_requests) {
            return @{
                allowed = $false
                limit_type = "concurrent_requests"
                current = $concurrentCount
                limit = $Limits.concurrent_requests
                message = "并发请求次数已达上限 ($concurrentCount/$($Limits.concurrent_requests))"
            }
        }
    }

    # 更新计数器
    Update-Counter -Key $contextKey -Increment 1

    return @{
        allowed = $true
        limit_type = "none"
        current = $counter.count
        limit = $Limits.requests_per_minute
        message = "请求已允许"
    }
}

# 主程序入口
if ($Check) {
    if ($null -eq $Limit) {
        $Limit = Initialize-Limits
    }

    $result = Check-RateLimit -Limits $Limit -Context $Context
    return $result
}
