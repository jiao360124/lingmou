# Quick heartbeat test
$HeartbeatStatePath = "heartbeat-state.json"

Write-Host "[HEARTBEAT] Starting quick heartbeat check..." -ForegroundColor Cyan

# 测试1: Gateway状态
try {
    $output = openclaw gateway status 2>&1
    if ($output -match "Gateway:.*\s+(OK|running|reachable)") {
        Write-Host "[HEARTBEAT] Gateway: OK (healthy)" -ForegroundColor Green
    } else {
        Write-Host "[HEARTBEAT] Gateway: CHECKING (wait...)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[HEARTBEAT] Gateway: ERROR" -ForegroundColor Red
}

# 测试2: 内存使用率
$process = Get-Process -Id $PID
$memoryMB = [math]::Round($process.WorkingSet64 / 1MB, 0)
$memoryPercent = [math]::Round(($memoryMB / 2048) * 100, 0)
Write-Host "[HEARTBEAT] Memory: $memoryMB MB ($memoryPercent%)" -ForegroundColor Cyan

# 测试3: 磁盘使用率
$drive = Get-PSDrive C
$diskUsage = [math]::Round((($drive.Used / $drive.Total) * 100), 0)
Write-Host "[HEARTBEAT] Disk C: $diskUsage%" -ForegroundColor Cyan

# 测试4: 网络连接
try {
    $test = Test-Connection -ComputerName "google.com" -Count 1 -ErrorAction Stop
    $latency = [math]::Round(($test.ResponseTime), 0)
    Write-Host "[HEARTBEAT] Network: $latency ms to google.com" -ForegroundColor Green
} catch {
    Write-Host "[HEARTBEAT] Network: ERROR" -ForegroundColor Red
}

# 测试5: API状态
try {
    $result = Invoke-WebRequest -Uri "https://api.github.com" -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
    Write-Host "[HEARTBEAT] API GitHub: OK" -ForegroundColor Green
} catch {
    Write-Host "[HEARTBEAT] API GitHub: ERROR" -ForegroundColor Red
}

Write-Host "[HEARTBEAT] Quick check completed!" -ForegroundColor Green
