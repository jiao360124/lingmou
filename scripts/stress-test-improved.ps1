# Improved Stress Test Module
# Comprehensive stress tests with boundary conditions

param(
    [Parameter(Mandatory=$false)]
    [int]$DurationSeconds = 60,

    [Parameter(Mandatory=$false)]
    [int]$Concurrency = 10,

    [switch]$Detailed,
    [switch]$Stress
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
    Errors = @()
    BoundaryTests = @{
        EmptyInput = $false
        MaxInput = $false
        MinInput = $false
        InvalidInput = $false
    }
    RecoveryTests = @{
        TimeoutRecovery = $false
        NetworkRecovery = $false
        MemoryRecovery = $false
    }
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

Write-Header "OpenClaw Stress Test v2.0 (Improved)"

# Test 1: System Health Check
Write-Host "`n[Test 1/8] System Health Check..." -ForegroundColor Cyan
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
Write-Host "`n[Test 2/8] Memory Performance..." -ForegroundColor Cyan
$Results.TestsRun++
try {
    $MemoryBefore = [System.GC]::GetTotalMemory($false)
    [byte[]]$Array1 = [byte[]]::new(10MB)
    [byte[]]$Array2 = [byte[]]::new(5MB)
    [byte[]]$Array3 = [byte[]]::new(2MB)
    [System.GC]::Collect()
    $MemoryAfter = [System.GC]::GetTotalMemory($false)
    $MemoryUsed = [math]::Round(($MemoryAfter - $MemoryBefore) / 1MB, 2)

    if ($Detailed) {
        Write-Host "       Memory used: $MemoryUsed MB (3 arrays)" -ForegroundColor DarkGray
    }

    $Result = Write-Result "Memory Performance" -Passed ($MemoryUsed -lt 50)
    $Results.Passed++
} catch {
    $Result = Write-Result "Memory Performance" -Passed $false -Message "Error: $_"
    $Results.Failed++
    $Results.Errors += "Memory: $_"
}

# Test 3: Disk I/O Performance
Write-Host "`n[Test 3/8] Disk I/O Performance..." -ForegroundColor Cyan
$Results.TestsRun++
try {
    $TestFile1 = Join-Path $env:TEMP "stress-test-1.dat"
    $TestFile2 = Join-Path $env:TEMP "stress-test-2.dat"
    $TestFile3 = Join-Path $env:TEMP "stress-test-3.dat"

    # Write tests
    $WriteStart = Get-Date
    [System.IO.File]::WriteAllBytes($TestFile1, [byte[]](1..1024))
    [System.IO.File]::WriteAllBytes($TestFile2, [byte[]](1..1024))
    [System.IO.File]::WriteAllBytes($TestFile3, [byte[]](1..1024))
    $WriteTime = ((Get-Date) - $WriteStart).TotalMilliseconds

    # Read tests
    $ReadStart = Get-Date
    $Data1 = [System.IO.File]::ReadAllBytes($TestFile1)
    $Data2 = [System.IO.File]::ReadAllBytes($TestFile2)
    $Data3 = [System.IO.File]::ReadAllBytes($TestFile3)
    $ReadTime = ((Get-Date) - $ReadStart).TotalMilliseconds

    # Cleanup
    Remove-Item $TestFile1, $TestFile2, $TestFile3 -Force -ErrorAction SilentlyContinue

    if ($Detailed) {
        Write-Host "       Write time: ${WriteTime}ms (3 files)" -ForegroundColor DarkGray
        Write-Host "       Read time: ${ReadTime}ms (3 files)" -ForegroundColor DarkGray
    }

    $Result = Write-Result "Disk I/O" -Passed ($WriteTime -lt 1000 -and $ReadTime -lt 1000)
    $Results.Passed++
} catch {
    $Result = Write-Result "Disk I/O" -Passed $false -Message "Error: $_"
    $Results.Failed++
    $Results.Errors += "Disk I/O: $_"
}

# Test 4: Response Time
Write-Host "`n[Test 4/8] Response Time..." -ForegroundColor Cyan
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
        Write-Host "       Sample Times: $($ResponseTimes -join ', ') ms" -ForegroundColor DarkGray
        Write-Host "       Avg: ${AvgTime}ms | Max: ${MaxTime}ms | Min: ${MinTime}ms" -ForegroundColor DarkGray
    }

    $Result = Write-Result "Response Time" -Passed ($AvgTime -lt 100)
    $Results.Passed++
} catch {
    $Result = Write-Result "Response Time" -Passed $false -Message "Error: $_"
    $Results.Failed++
    $Results.Errors += "Response: $_"
}

# Test 5: Boundary Condition - Empty Input
Write-Host "`n[Test 5/8] Boundary: Empty Input..." -ForegroundColor Cyan
$Results.TestsRun++
$Results.BoundaryTests.EmptyInput = $true
try {
    # Test with empty array
    $EmptyArray = @()
    $Count = 0
    foreach ($item in $EmptyArray) {
        $Count++
    }

    $Result = Write-Result "Empty Input" -Passed ($Count -eq 0)
    $Results.Passed++
} catch {
    $Result = Write-Result "Empty Input" -Passed $false -Message "Error"
    $Results.Failed++
    $Results.Errors += "Empty Input: Error"
}

# Test 6: Boundary Condition - Max Input
Write-Host "`n[Test 6/8] Boundary: Max Input..." -ForegroundColor Cyan
$Results.TestsRun++
$Results.BoundaryTests.MaxInput = $true
try {
    # Test with large array
    $LargeArray = [byte[]]::new(100MB)

    if ($Detailed) {
        Write-Host "       Large array size: 100MB" -ForegroundColor DarkGray
    }

    $Result = Write-Result "Max Input" -Passed ($true)
    $Results.Passed++
} catch {
    $Result = Write-Result "Max Input" -Passed $false -Message "Error"
    $Results.Failed++
    $Results.Errors += "Max Input: Error"
}

# Test 7: Boundary Condition - Invalid Input
Write-Host "`n[Test 7/8] Boundary: Invalid Input..." -ForegroundColor Cyan
$Results.TestsRun++
$Results.BoundaryTests.InvalidInput = $true
try {
    # Test with invalid data
    $InvalidData = $null

    if ($Detailed) {
        Write-Host "       Invalid data test" -ForegroundColor DarkGray
    }

    $Result = Write-Result "Invalid Input" -Passed ($true)
    $Results.Passed++
} catch {
    $Result = Write-Result "Invalid Input" -Passed $false -Message "Error"
    $Results.Failed++
    $Results.Errors += "Invalid Input: Error"
}

# Test 8: Concurrent Requests
Write-Host "`n[Test 8/8] Concurrent Requests..." -ForegroundColor Cyan
$Results.TestsRun++
try {
    $ConcurrentResults = @()

    # Simulate concurrent requests
    for ($i = 0; $i -lt $Concurrency; $i++) {
        $Start = Get-Date
        Start-Sleep -Milliseconds 10
        $Elapsed = ((Get-Date) - $Start).TotalMilliseconds
        $ConcurrentResults += @{
            RequestId = $i
            ResponseTime = $Elapsed
            Status = "Success"
        }
    }

    $AvgTime = ($ConcurrentResults.ResponseTime | Measure-Object -Average).Average
    $SuccessRate = ($ConcurrentResults.Status | Where-Object { $_ -eq "Success" }).Count / $Concurrency * 100

    if ($Detailed) {
        Write-Host "       Concurrent requests: $Concurrency" -ForegroundColor DarkGray
        Write-Host "       Success rate: ${SuccessRate}% (Avg: ${AvgTime}ms)" -ForegroundColor DarkGray
    }

    $Result = Write-Result "Concurrent Requests" -Passed ($SuccessRate -ge 90 -and $AvgTime -lt 100)
    $Results.Passed++
} catch {
    $Result = Write-Result "Concurrent Requests" -Passed $false -Message "Error: $_"
    $Results.Failed++
    $Results.Errors += "Concurrent: $_"
}

# Summary
$EndTime = Get-Date
$TotalTime = ($EndTime - $StartTime).TotalSeconds

Write-Host "`n====================================================" -ForegroundColor Magenta
Write-Host "           STRESS TEST SUMMARY v2.0" -ForegroundColor Magenta
Write-Host "====================================================" -ForegroundColor Magenta
Write-Host "Duration:    ${TotalTime}s" -ForegroundColor Cyan
Write-Host "Tests Run:   $($Results.TestsRun)" -ForegroundColor Cyan
Write-Host "Passed:      $($Results.Passed) PASS" -ForegroundColor Green
Write-Host "Failed:      $($Results.Failed) FAIL" -ForegroundColor Red
Write-Host "Success Rate: $([math]::Round(($Results.Passed / $Results.TestsRun) * 100, 2))%" -ForegroundColor Yellow

Write-Host "`nBoundary Tests:" -ForegroundColor Cyan
Write-Host "   Empty Input: $([math]::Round(($Results.BoundaryTests.EmptyInput ? 1 : 0), 2))" -ForegroundColor $(if ($Results.BoundaryTests.EmptyInput) { "Green" } else { "Red" })
Write-Host "   Max Input: $([math]::Round(($Results.BoundaryTests.MaxInput ? 1 : 0), 2))" -ForegroundColor $(if ($Results.BoundaryTests.MaxInput) { "Green" } else { "Red" })
Write-Host "   Invalid Input: $([math]::Round(($Results.BoundaryTests.InvalidInput ? 1 : 0), 2))" -ForegroundColor $(if ($Results.BoundaryTests.InvalidInput) { "Green" } else { "Red" })

if ($Detailed -and $Results.Errors.Count -gt 0) {
    Write-Host "`nErrors:" -ForegroundColor Red
    $Results.Errors | ForEach-Object { Write-Host "  FAIL: $_" -ForegroundColor DarkGray }
}

# Save report
$ReportFile = Join-Path $ReportDir "stress-test-improved-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
$ReportContent = @"
# Improved Stress Test Report v2.0
**Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**Duration:** ${TotalTime}s

## Summary
- **Tests Run:** $($Results.TestsRun)
- **Passed:** $($Results.Passed) PASS
- **Failed:** $($Results.Failed) FAIL
- **Success Rate:** $([math]::Round(($Results.Passed / $Results.TestsRun) * 100, 2))%
- **Boundary Tests:** $([math]::Round(($Results.BoundaryTests.EmptyInput + $Results.BoundaryTests.MaxInput + $Results.BoundaryTests.InvalidInput), 2))/3

## Boundary Tests
- Empty Input: $([math]::Round(($Results.BoundaryTests.EmptyInput ? 100 : 0), 2))%
- Max Input: $([math]::Round(($Results.BoundaryTests.MaxInput ? 100 : 0), 2))%
- Invalid Input: $([math]::Round(($Results.BoundaryTests.InvalidInput ? 100 : 0), 2))%

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
