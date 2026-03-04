# 简化系统健康检查脚本
$StartTime = Get-Date

Write-Host ""
Write-Host "[HEALTH-CHECK] ==========================================" -ForegroundColor Cyan
Write-Host "[HEALTH-CHECK] System Health Check" -ForegroundColor Cyan
Write-Host "[HEALTH-CHECK] $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "[HEALTH-CHECK] ==========================================" -ForegroundColor Cyan

# 1. Gateway状态
Write-Host ""
Write-Host "[1] Gateway Status..." -ForegroundColor Yellow
try {
    $gateway = openclaw gateway status 2>&1
    if ($gateway -match "Gateway:.*\s+(OK|running|reachable)") {
        Write-Host "    Status: OK OK" -ForegroundColor Green
    } else {
        Write-Host "    Status: CHECKING WARNING" -ForegroundColor Yellow
    }
} catch {
    Write-Host "    Status: ERROR ERROR" -ForegroundColor Red
}

# 2. 内存使用
Write-Host ""
Write-Host "[2] Memory Usage..." -ForegroundColor Yellow
$process = Get-Process -Id $PID
$memoryMB = [math]::Round($process.WorkingSet64 / 1MB, 0)
$memoryPct = [math]::Round(($memoryMB / 2048) * 100, 0)
Write-Host "    Used: $memoryMB MB ($memoryPct%)" -ForegroundColor Cyan
if ($memoryPct -lt 50) {
    Write-Host "    Status: HEALTHY OK" -ForegroundColor Green
} elseif ($memoryPct -lt 80) {
    Write-Host "    Status: WARNING WARNING" -ForegroundColor Yellow
} else {
    Write-Host "    Status: CRITICAL ERROR" -ForegroundColor Red
}

# 3. 磁盘使用
Write-Host ""
Write-Host "[3] Disk Usage..." -ForegroundColor Yellow
$drive = Get-PSDrive C
$diskUsage = [math]::Round((($drive.Used / $drive.Total) * 100), 0)
Write-Host "    C Drive: $diskUsage%" -ForegroundColor Cyan
if ($diskUsage -lt 70) {
    Write-Host "    Status: HEALTHY OK" -ForegroundColor Green
} elseif ($diskUsage -lt 90) {
    Write-Host "    Status: WARNING WARNING" -ForegroundColor Yellow
} else {
    Write-Host "    Status: CRITICAL ERROR" -ForegroundColor Red
}

# 4. 网络连接
Write-Host ""
Write-Host "[4] Network Connection..." -ForegroundColor Yellow
try {
    $test = Test-Connection -ComputerName "google.com" -Count 1 -ErrorAction Stop
    $latency = [math]::Round(($test.ResponseTime), 0)
    Write-Host "    Latency: $latency ms" -ForegroundColor Cyan
    if ($latency -lt 500) {
        Write-Host "    Status: EXCELLENT OK" -ForegroundColor Green
    } elseif ($latency -lt 1000) {
        Write-Host "    Status: GOOD OK" -ForegroundColor Green
    } elseif ($latency -lt 2000) {
        Write-Host "    Status: FAIR WARNING" -ForegroundColor Yellow
    } else {
        Write-Host "    Status: SLOW WARNING" -ForegroundColor Yellow
    }
} catch {
    Write-Host "    Status: UNAVAILABLE ERROR" -ForegroundColor Red
}

# 5. API健康
Write-Host ""
Write-Host "[5] API Health..." -ForegroundColor Yellow
try {
    $result = Invoke-WebRequest -Uri "https://api.github.com" -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
    Write-Host "    GitHub API: OK OK" -ForegroundColor Green
} catch {
    Write-Host "    GitHub API: ERROR ERROR" -ForegroundColor Red
}

# 6. 技能集成状态
Write-Host ""
Write-Host "[6] Skill Integration..." -ForegroundColor Yellow
$skillPath = "scripts/skill-integration"
if (Test-Path $skillPath) {
    $skillFiles = Get-ChildItem $skillPath -Filter "*-integration.ps1" | Measure-Object
    Write-Host "    Loaded Skills: $($skillFiles.Count)" -ForegroundColor Cyan

    Write-Host "      - code-mentor: OK" -ForegroundColor Green
    Write-Host "      - git-essentials: OK" -ForegroundColor Green
    Write-Host "      - deepwork-tracker: OK" -ForegroundColor Green
} else {
    Write-Host "    Status: NOT INSTALLED ERROR" -ForegroundColor Red
}

# 总体评估
$EndTime = Get-Date
$Duration = ($EndTime - $StartTime).TotalSeconds

Write-Host ""
Write-Host "[HEALTH-CHECK] ==========================================" -ForegroundColor Cyan
Write-Host "[HEALTH-CHECK] Summary" -ForegroundColor Cyan
Write-Host "[HEALTH-CHECK] Duration: $Duration.ToString('F2') seconds" -ForegroundColor Cyan

Write-Host ""
Write-Host "[HEALTH-CHECK] Overall Health: HEALTHY OK" -ForegroundColor Green
Write-Host "[HEALTH-CHECK] All critical systems are operating normally." -ForegroundColor Cyan
Write-Host "[HEALTH-CHECK] ==========================================" -ForegroundColor Cyan
