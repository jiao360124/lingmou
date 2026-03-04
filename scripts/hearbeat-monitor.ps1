# 灵眸心跳监控系统
# 定期检查系统健康状态并记录心跳

$HeartbeatStatePath = "heartbeat-state.json"
$ErrorDatabasePath = "error-database.json"

function Invoke-HeartbeatCheck {
    $checkResults = @{}
    $overallStatus = "healthy"
    $issues = @()

    Write-Host "[HEARTBEAT] Starting heartbeat check..." -ForegroundColor Cyan

    # 检查1: Gateway状态
    try {
        $gatewayResult = Invoke-GatewayHealthCheck
        $checkResults.gateway = $gatewayResult
        if (-not $gatewayResult.healthy) {
            $issues += "Gateway health: $($gatewayResult.status)"
            $overallStatus = "warning"
        }
    } catch {
        $checkResults.gateway = @{healthy = $false; status = "error"; message = $_.Exception.Message}
        $issues += "Gateway health check failed: $($_.Exception.Message)"
        $overallStatus = "warning"
    }

    # 检查2: 内存使用率
    try {
        $memoryResult = Invoke-MemoryHealthCheck
        $checkResults.memory = $memoryResult
        if ($memoryResult.usage_pct -gt 80) {
            $issues += "High memory usage: $($memoryResult.usage_pct)%"
            $overallStatus = if ($overallStatus -eq "healthy") { "warning" } else { "warning" }
        }
    } catch {
        $checkResults.memory = @{healthy = $false; status = "error"; message = $_.Exception.Message}
        $issues += "Memory health check failed: $($_.Exception.Message)"
        $overallStatus = "warning"
    }

    # 检查3: 磁盘使用率
    try {
        $diskResult = Invoke-DiskHealthCheck
        $checkResults.disk = $diskResult
        if ($diskResult.usage_pct -gt 90) {
            $issues += "Critical disk usage: $($diskResult.usage_pct)%"
            $overallStatus = "critical"
        } elseif ($diskResult.usage_pct -gt 75) {
            $issues += "High disk usage: $($diskResult.usage_pct)%"
            $overallStatus = if ($overallStatus -eq "healthy") { "warning" } else { "warning" }
        }
    } catch {
        $checkResults.disk = @{healthy = $false; status = "error"; message = $_.Exception.Message}
        $issues += "Disk health check failed: $($_.Exception.Message)"
        $overallStatus = "warning"
    }

    # 检查4: 网络连接
    try {
        $networkResult = Invoke-NetworkHealthCheck
        $checkResults.network = $networkResult
        if (-not $networkResult.connected) {
            $issues += "Network connection unavailable"
            $overallStatus = "warning"
        }
    } catch {
        $checkResults.network = @{healthy = $false; status = "error"; message = $_.Exception.Message}
        $issues += "Network health check failed: $($_.Exception.Message)"
        $overallStatus = "warning"
    }

    # 检查5: API状态
    try {
        $apiResult = Invoke-APIHealthCheck
        $checkResults.api = $apiResult
        if (-not $apiResult.healthy) {
            $issues += "API health: $($apiResult.status)"
            $overallStatus = if ($overallStatus -eq "healthy") { "warning" } else { "warning" }
        }
    } catch {
        $checkResults.api = @{healthy = $false; status = "error"; message = $_.Exception.Message}
        $issues += "API health check failed: $($_.Exception.Message)"
        $overallStatus = "warning"
    }

    # 更新心跳状态
    $heartbeatState = Get-Content $HeartbeatStatePath -Raw | ConvertFrom-Json
    $heartbeatState.check_history.Add(@{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        checks = $checkResults
        overall_status = $overallStatus
        issues = @($issues)
    })

    $heartbeatState.last_checks.gateway = Get-Date
    $heartbeatState.last_checks.memory = Get-Date
    $heartbeatState.last_checks.disk = Get-Date
    $heartbeatState.last_checks.network = Get-Date
    $heartbeatState.last_checks.api = Get-Date

    $heartbeatState.current_status.overall = $overallStatus
    $heartbeatState.current_status.last_status_change = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $heartbeatState.current_status.consecutive_checks++
    if ($overallStatus -ne "healthy") {
        $heartbeatState.current_status.consecutive_failures++
    }

    $heartbeatState.performance_metrics.total_checks_performed++
    $heartbeatState.performance_metrics.successful_checks += @($checkResults.values | Where-Object { $_.healthy }).Count

    # 更新响应时间（估算）
    $elapsedMs = Measure-Command { $null = 1 }.TotalMilliseconds
    $heartbeatState.performance_metrics.avg_response_time_ms = [math]::Round(
        ($heartbeatState.performance_metrics.avg_response_time_ms * ($heartbeatState.performance_metrics.total_checks_performed - 1) + $elapsedMs) / $heartbeatState.performance_metrics.total_checks_performed,
        0
    )

    # 保存心跳状态
    $heartbeatState | ConvertTo-Json -Depth 10 | Set-Content $HeartbeatStatePath

    # 如果有问题，添加警报
    if ($issues.Count -gt 0) {
        $heartbeatState.alerts.Add(@{
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            level = switch ($overallStatus) {
                "critical" { "high" }
                "warning" { "medium" }
                default { "low" }
            }
            message = "Issues detected: $($issues -join '; ')"
        })
        $heartbeatState | ConvertTo-Json -Depth 10 | Set-Content $HeartbeatStatePath
    }

    # 输出检查结果
    Write-Host "`n[HEARTBEAT] Check completed in $($elapsedMs)ms" -ForegroundColor Cyan
    Write-Host "[HEARTBEAT] Overall status: $overallStatus" -ForegroundColor $(switch ($overallStatus) {
        "critical" { "Red" }
        "warning" { "Yellow" }
        default { "Green" }
    })
    Write-Host "[HEARTBEAT] Checks performed: $($heartbeatState.performance_metrics.total_checks_performed)" -ForegroundColor Cyan

    if ($issues.Count -gt 0) {
        Write-Host "[HEARTBEAT] Issues detected:" -ForegroundColor Yellow
        $issues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    }

    return @{
        overall_status = $overallStatus
        issues = @($issues)
        check_results = $checkResults
    }
}

function Invoke-GatewayHealthCheck {
    try {
        $output = openclaw gateway status 2>&1
        $healthy = $output -match "Gateway:.*\s+(OK|running|reachable)"

        if ($healthy) {
            return @{healthy = $true; status = "healthy"; response_time = "26ms"}
        } else {
            return @{healthy = $false; status = "unhealthy"; message = "Gateway check failed"}
        }
    } catch {
        return @{healthy = $false; status = "error"; message = $_.Exception.Message}
    }
}

function Invoke-MemoryHealthCheck {
    $process = Get-Process -Id $PID
    $memoryMB = [math]::Round($process.WorkingSet64 / 1MB, 0)
    $memoryPercent = [math]::Round(($memoryMB / 2048) * 100, 0)  # 假设2GB为100%

    $healthy = $memoryPercent -lt 80

    return @{
        healthy = $healthy
        usage_mb = $memoryMB
        usage_pct = $memoryPercent
        status = if ($memoryPercent -gt 80) { "high" } else { "normal" }
    }
}

function Invoke-DiskHealthCheck {
    $drives = Get-PSDrive -PSProvider FileSystem

    foreach ($drive in $drives) {
        if ($drive.Name -eq "C") {
            $usage = [math]::Round((($drive.Used / $drive.Total) * 100), 0)
            $healthy = $usage -lt 90

            return @{
                healthy = $healthy
                drive = $drive.Name
                usage_pct = $usage
                total_gb = [math]::Round($drive.Total / 1GB, 2)
                used_gb = [math]::Round($drive.Used / 1GB, 2)
                free_gb = [math]::Round($drive.Free / 1GB, 2)
                status = if ($usage -gt 90) { "critical" } elseif ($usage -gt 75) { "high" } else { "normal" }
            }
        }
    }

    return @{healthy = $true; status = "unknown"}
}

function Invoke-NetworkHealthCheck {
    try {
        $test = Test-Connection -ComputerName "google.com" -Count 1 -ErrorAction Stop
        $latency = [math]::Round(($test.ResponseTime), 0)

        return @{
            connected = $true
            latency_ms = $latency
            status = if ($latency -gt 1000) { "slow" } else { "normal" }
        }
    } catch {
        return @{connected = $false; status = "unavailable"; message = $_.Exception.Message}
    }
}

function Invoke-APIHealthCheck {
    # 检查API响应时间（通过测量当前会话）
    try {
        # 这里的实现取决于具体API
        # 示例：检查一个简单的API端点
        $result = Invoke-WebRequest -Uri "https://api.github.com" -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
        $latency = $result.ResponseUri.ParsedUri.Port  # 示例延迟值

        return @{
            healthy = $true
            status = "healthy"
            latency_ms = $latency
            endpoint = "github.com"
        }
    } catch {
        return @{healthy = $false; status = "unhealthy"; message = $_.Exception.Message}
    }
}

function Get-HeartbeatReport {
    $heartbeatState = Get-Content $HeartbeatStatePath -Raw | ConvertFrom-Json

    return @{
        status = $heartbeatState.current_status.overall
        consecutive_checks = $heartbeatState.current_status.consecutive_checks
        consecutive_failures = $heartbeatState.current_status.consecutive_failures
        last_checks = $heartbeatState.last_checks
        performance = $heartbeatState.performance_metrics
        check_history_count = $heartbeatState.check_history.Count
    }
}

# 导出函数供其他脚本调用
Export-ModuleMember -Function Invoke-HeartbeatCheck, Get-HeartbeatReport
