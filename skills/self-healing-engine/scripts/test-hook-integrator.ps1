<#
.SYNOPSIS
    Hook Integration System 测试脚本

.DESCRIPTION
    测试Hook集成系统的各项功能，确保正常运行。

.VERSION
    1.0.0

.AUTHOR
    灵眸
#>

Write-Host "🧪 Testing Hook Integration System..." -ForegroundColor Cyan

$testPassed = 0
$testFailed = 0

function Test-Pass {
    param([string]$Message)
    Write-Host "✅ PASS: $Message" -ForegroundColor Green
    $global:testPassed++
}

function Test-Fail {
    param([string]$Message)
    Write-Host "❌ FAIL: $Message" -ForegroundColor Red
    $global:testFailed++
}

function Test-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Gray
}

try {
    # Test 1: System Initialization
    Write-Host "`n=== System Initialization ===" -ForegroundColor Yellow

    $initOutput = & .\hook-integrator.ps1 -Action init 2>&1
    Write-Host "Output: '$initOutput'" -ForegroundColor Gray
    if ($LASTEXITCODE -eq 0 -and ($initOutput -match "initialized" -or $initOutput -match "System initialized")) {
        Test-Pass "System initialization"
    } else {
        Test-Fail "System initialization"
    }

    # Test 2: Hook Registration
    Write-Host "`n=== Hook Registration ===" -ForegroundColor Yellow

    $registerOutput = & .\hook-integrator.ps1 -Action register -Name "test-hook-1" -Type "script" -Location "Write-Host 'Test hook executed' -ForegroundColor Green" 2>&1
    Write-Host "Output: '$registerOutput'" -ForegroundColor Gray
    if ($registerOutput -match "test-hook-1" -and $registerOutput -match "Hook registered") {
        Test-Pass "Hook registration"
    } else {
        Test-Fail "Hook registration failed"
    }

    # Test 3: Hook Listing
    Write-Host "`n=== Hook Listing ===" -ForegroundColor Yellow

    $listOutput = & .\hook-integrator.ps1 -Action list 2>&1
    Write-Host "Output: '$listOutput'" -ForegroundColor Gray
    if ($listOutput -match "test-hook-1" -and $listOutput -notmatch "Error:") {
        Test-Pass "Hook listing"
    } else {
        Test-Fail "Hook listing failed"
    }

    # Test 4: Statistics
    Write-Host "`n=== Statistics ===" -ForegroundColor Yellow

    $statsOutput = & .\hook-integrator.ps1 -Action list 2>&1
    Write-Host "Output: '$statsOutput'" -ForegroundColor Gray
    $hookCount = ($statsOutput -split "`n" | Where-Object { $_ -match "test-hook" }).Count
    if ($hookCount -ge 1) {
        Test-Pass "Statistics"
    } else {
        Test-Fail "Statistics failed"
    }

    # Test 5: Multiple Hooks
    Write-Host "`n=== Multiple Hooks ===" -ForegroundColor Yellow

    $register2Output = & .\hook-integrator.ps1 -Action register -Name "test-hook-2" -Type "script" -Location "Write-Host 'Another test hook' -ForegroundColor Cyan" 2>&1
    Write-Host "Output: '$register2Output'" -ForegroundColor Gray
    if ($register2Output -match "test-hook-2" -and $register2Output -match "Hook registered") {
        Test-Pass "Multiple hook registration"
    } else {
        Test-Fail "Multiple hook registration failed"
    }

    # Summary
    Write-Host "`n=== Test Summary ===" -ForegroundColor Yellow

    Write-Host "Tests Passed: $testPassed" -ForegroundColor Green
    Write-Host "Tests Failed: $testFailed" -ForegroundColor Red
    Write-Host "Total Tests: $($testPassed + $testFailed)" -ForegroundColor White

    if ($testFailed -eq 0) {
        Write-Host "`n🎉 All tests passed!" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "`n⚠️  Some tests failed" -ForegroundColor Yellow
        exit 1
    }

} catch {
    Write-Error "Test failed: $($_.Exception.Message)"
    Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    exit 1
}
