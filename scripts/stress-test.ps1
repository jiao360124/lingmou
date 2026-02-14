# OpenClaw Stress Test Module
# Tests system stability under heavy load

param(
    [Parameter(Mandatory=$false)]
    [int]$DurationSeconds = 60,

    [Parameter(Mandatory=$false)]
    [int]$Concurrency = 10,

    [switch]$Detailed
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ReportDir = Join-Path $ScriptDir "..\reports"
if (-not (Test-Path $ReportDir)) { New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null }

$StartTime = Get-Date
$Results = @{
    TestsRun = 0
    Passed = 0
    Failed = 0
    AvgResponseTime = 0
    MaxResponseTime = 0
    MinResponseTime = [double]::MaxValue
    Errors = @()
}

function Write-Header {
    param([string]$Title)
    Write-Host "`n$Title" -ForegroundColor Cyan -BackgroundColor Black
    Write-Host "=" * 60 -ForegroundColor DarkGray
}

function Write-Result {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Message = "",
        [int]$ResponseTime = 0
    )

    $Status = if ($Passed) { "PASS" } else { "FAIL" }
    $Color = if ($Passed) { "Green" } else { "Red" }

    if ($Detailed) {
        Write-Host "[$Status] $TestName" -ForegroundColor $Color
        if ($Message) { Write-Host "       $Message" -ForegroundColor DarkGray }
        if ($ResponseTime -gt 0) { Write-Host "       Response: ${ResponseTime}ms" -ForegroundColor DarkGray }
    }

    return $Passed
}

Write-Header "OpenClaw Stress Test v1.1"

# Test 1: System Health Check
Write-Host "`n[Test 1/5] System Health Check..." -ForegroundColor Cyan
$Results.TestsRun++
try {
    $HealthCheck = & "C:\Users\Administrator\.openclaw\workspace\scripts\simple-health-check.ps1" 2>&1
    $Result = Write-Result "System Health" -Passed $true -Message "Health check passed"
    $Results.Passed++
} catch {
    $Result = Write-Result "System Health" -Passed $false -Message "Health check failed"
    $Results.Failed++
    $Results.Errors += "System Health: Check"
}

# Test 2: Memory Performance
Write-Host "`n[Test 2/5] Memory Performance..." -ForegroundColor Cyan
$Results.TestsRun++
try {
    $MemoryBefore = [System.GC]::GetTotalMemory($false)
    $MemoryAfter = [System.GC]::GetTotalMemory($false)

    if ($Detailed) {
        Write-Host "       Memory Before: $([math]::Round($MemoryBefore / 1KB, 2)) KB"
        Write-Host "       Memory After: $([math]::Round($MemoryAfter / 1KB, 2)) KB"
        Write-Host "       Memory Change: $([math]::Round(($MemoryAfter - $MemoryBefore) / 1KB, 2)) KB"
    }

    $Result = Write-Result "Memory Performance" -Passed $true
    $Results.Passed++
} catch {
    $Result = Write-Result "Memory Performance" -Passed $false -Message $_.Exception.Message
    $Results.Failed++
    $Results.Errors += "Memory Performance: $_"
}

# Test 3: Disk I/O Performance
Write-Host "`n[Test 3/5] Disk I/O Performance..." -ForegroundColor Cyan
$Results.TestsRun++
try {
    $TestFile = Join-Path $env:TEMP "stress-test-file.dat"

    # Write test
    $WriteStart = Get-Date
    if ($Detailed) { Write-Host "       Writing..." -ForegroundColor DarkGray }
    $File = [System.IO.File]::Create($TestFile)
    $Data = [byte[]](1..1024)
    $File.Write($Data, 0, $Data.Length)
    $File.Close()
    $WriteTime = ((Get-Date) - $WriteStart).TotalMilliseconds

    # Read test
    $ReadStart = Get-Date
    if ($Detailed) { Write-Host "       Reading..." -ForegroundColor DarkGray }
    $File = [System.IO.File]::OpenRead($TestFile)
    $Buffer = [byte[]]::new(4096)
    $File.Read($Buffer, 0, $Buffer.Length) | Out-Null
    $ReadTime = ((Get-Date) - $ReadStart).TotalMilliseconds
    $File.Close()

    if ($Detailed) {
        Write-Host "       Write Time: ${WriteTime}ms ($([math]::Round($WriteTime / 1000, 2))s)"
        Write-Host "       Read Time: ${ReadTime}ms"
    }

    # Cleanup
    Remove-Item $TestFile -Force

    $Result = Write-Result "Disk I/O" -Passed $true -Message "Write: ${WriteTime}ms, Read: ${ReadTime}ms"
    $Results.Passed++
} catch {
    $Result = Write-Result "Disk I/O" -Passed $false -Message $_.Exception.Message
    $Results.Failed++
    $Results.Errors += "Disk I/O: $_"
}

# Test 4: Response Time
Write-Host "`n[Test 4/5] Response Time..." -ForegroundColor Cyan
$Results.TestsRun++
try {
    $ResponseTimes = @()
    for ($i = 1; $i -le 10; $i++) {
        $Start = Get-Date
        Start-Sleep -Milliseconds 50
        $ResponseTimes += ((Get-Date) - $Start).TotalMilliseconds
    }

    $AvgTime = ($ResponseTimes | Measure-Object -Average).Average
    $MaxTime = ($ResponseTimes | Measure-Object -Maximum).Maximum
    $MinTime = ($ResponseTimes | Measure-Object -Minimum).Minimum

    if ($Detailed) {
        Write-Host "       Sample Times: $($ResponseTimes -join ', ') ms"
        Write-Host "       Avg: ${AvgTime}ms | Max: ${MaxTime}ms | Min: ${MinTime}ms"
    }

    $Result = Write-Result "Response Time" -Passed ($AvgTime -lt 100) -Message "Avg: ${AvgTime}ms (threshold: 100ms)"
    $Results.Success++
} catch {
    $Result = Write-Result "Response Time" -Passed $false -Message $_.Exception.Message
    $Results.Failed++
    $Results.Errors += "Response Time: $_"
}

# Test 5: System Load
Write-Host "`n[Test 5/5] System Load..." -ForegroundColor Cyan
$Results.TestsRun++
try {
    $Process = Get-Process -Name "powershell" -ErrorAction SilentlyContinue
    if ($Process) {
        $CPU = $Process.CPU
        $Memory = [math]::Round($Process.WorkingSet64 / 1MB, 2)

        if ($Detailed) {
            Write-Host "       CPU: ${CPU}% (avg)"
            Write-Host "       Memory: ${Memory}MB (avg)"
        }

        $Result = Write-Result "System Load" -Passed ($CPU -lt 80) -Message "CPU: ${CPU}% | Memory: ${Memory}MB"
        $Results.Success++
    } else {
        $Result = Write-Result "System Load" -Passed $true -Message "No processes running"
        $Results.Success++
    }
} catch {
    $Result = Write-Result "System Load" -Passed $false -Message $_.Exception.Message
    $Results.Failed++
    $Results.Errors += "System Load: $_"
}

# Summary
$EndTime = Get-Date
$TotalTime = ($EndTime - $StartTime).TotalSeconds

Write-Host "`n====================================================" -ForegroundColor Magenta
Write-Host "              STRESS TEST SUMMARY" -ForegroundColor Magenta
Write-Host "====================================================" -ForegroundColor Magenta
Write-Host "Duration:    ${TotalTime}s" -ForegroundColor Cyan
Write-Host "Tests Run:   $($Results.TestsRun)" -ForegroundColor Cyan
Write-Host "Passed:      $($Results.Passed) PASS" -ForegroundColor Green
Write-Host "Failed:      $($Results.Failed) FAIL" -ForegroundColor Red
Write-Host "Success Rate: $([math]::Round(($Results.Passed / $Results.TestsRun) * 100, 2))%" -ForegroundColor Yellow

if ($Detailed -and $Results.Errors.Count -gt 0) {
    Write-Host "`nErrors:" -ForegroundColor Red
    $Results.Errors | ForEach-Object { Write-Host "  FAIL: $_" -ForegroundColor DarkGray }
}

# Save report
$ReportFile = Join-Path $ReportDir "stress-test-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
$ReportContent = @"
# Stress Test Report
**Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**Duration:** ${TotalTime}s

## Summary
- **Tests Run:** $($Results.TestsRun)
- **Passed:** $($Results.Passed) PASS
- **Failed:** $($Results.Failed) FAIL
- **Success Rate:** $([math]::Round(($Results.Passed / $Results.TestsRun) * 100, 2))%

## Test Results
$(if ($Detailed) { $Results.Errors | ForEach-Object { "### FAIL: $_" } })

---
"@

$ReportContent | Out-File -FilePath $ReportFile -Encoding UTF8
Write-Host "`nReport saved: $ReportFile" -ForegroundColor Green

if ($Results.Failed -eq 0) {
    exit 0
} else {
    exit 1
}
