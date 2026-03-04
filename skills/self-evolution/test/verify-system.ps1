# System Verification Script

# @Author: LingMou
# @Version: 1.0.0
# @Date: 2026-02-13

$ScriptPath = $PSScriptRoot
$Workspace = "$ScriptPath/../../.."
$Results = @{}

Write-Host "`n========== System Verification ==========" -ForegroundColor Magenta

# Test 1: Check Phase 1 - Learning Analysis
Write-Host "`n[Test 1] Learning Analysis System..." -ForegroundColor Yellow
try {
    if (Test-Path "$ScriptPath/../main.ps1") {
        Write-Host "[PASS] main.ps1 exists" -ForegroundColor Green
        $Results.phase1 = "PASS"
    } else {
        Write-Host "[FAIL] main.ps1 not found" -ForegroundColor Red
        $Results.phase1 = "FAIL"
    }
} catch {
    Write-Host "[FAIL] Error checking main.ps1" -ForegroundColor Red
    $Results.phase1 = "FAIL"
}

# Test 2: Check Phase 2 - Continuous Optimization
Write-Host "`n[Test 2] Continuous Optimization System..." -ForegroundColor Yellow
try {
    if (Test-Path "$ScriptPath/../continuous-optimizer.ps1") {
        Write-Host "[PASS] continuous-optimizer.ps1 exists" -ForegroundColor Green
        $Results.phase2 = "PASS"
    } else {
        Write-Host "[FAIL] continuous-optimizer.ps1 not found" -ForegroundColor Red
        $Results.phase2 = "FAIL"
    }
} catch {
    Write-Host "[FAIL] Error checking continuous-optimizer.ps1" -ForegroundColor Red
    $Results.phase2 = "FAIL"
}

# Test 3: Check Phase 3 - Moltbook Integration
Write-Host "`n[Test 3] Moltbook Integration System..." -ForegroundColor Yellow
try {
    if (Test-Path "$ScriptPath/../moltbook-integrator.ps1") {
        Write-Host "[PASS] moltbook-integrator.ps1 exists" -ForegroundColor Green
        $Results.phase3 = "PASS"
    } else {
        Write-Host "[FAIL] moltbook-integrator.ps1 not found" -ForegroundColor Red
        $Results.phase3 = "FAIL"
    }
} catch {
    Write-Host "[FAIL] Error checking moltbook-integrator.ps1" -ForegroundColor Red
    $Results.phase3 = "FAIL"
}

# Test 4: Check Configuration
Write-Host "`n[Test 4] Configuration File..." -ForegroundColor Yellow
try {
    if (Test-Path "$ScriptPath/../config.json") {
        $Config = Get-Content "$ScriptPath/../config.json" | ConvertFrom-Json
        Write-Host "[PASS] config.json exists" -ForegroundColor Green
        Write-Host "  API Endpoint: $($Config.moltbook.apiEndpoint)" -ForegroundColor Cyan
        Write-Host "  Auto Sync: $($Config.moltbook.autoSync)" -ForegroundColor Cyan
        $Results.config = "PASS"
    } else {
        Write-Host "[FAIL] config.json not found" -ForegroundColor Red
        $Results.config = "FAIL"
    }
} catch {
    Write-Host "[FAIL] Error checking config.json" -ForegroundColor Red
    $Results.config = "FAIL"
}

# Test 5: Check Data Files
Write-Host "`n[Test 5] Data Files..." -ForegroundColor Yellow
$DataFiles = @(
    "learning-log.md",
    "pattern-database.json",
    "recommendations.json",
    "patterns.json"
)

$AllDataFilesPresent = $true
foreach ($File in $DataFiles) {
    if (Test-Path "$ScriptPath/../data/$File") {
        Write-Host "[PASS] data/$File exists" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] data/$File not found" -ForegroundColor Red
        $AllDataFilesPresent = $false
    }
}
$Results.dataFiles = if ($AllDataFilesPresent) { "PASS" } else { "FAIL" }

# Test 6: Check Documentation
Write-Host "`n[Test 6] Documentation..." -ForegroundColor Yellow
try {
    if (Test-Path "$ScriptPath/../SKILL.md") {
        Write-Host "[PASS] SKILL.md exists" -ForegroundColor Green
        $Results.documentation = "PASS"
    } else {
        Write-Host "[FAIL] SKILL.md not found" -ForegroundColor Red
        $Results.documentation = "FAIL"
    }
} catch {
    Write-Host "[FAIL] Error checking SKILL.md" -ForegroundColor Red
    $Results.documentation = "FAIL"
}

# Test 7: Run Integration Test
Write-Host "`n[Test 7] Integration Test..." -ForegroundColor Yellow
try {
    $MainScript = "$ScriptPath/../main.ps1"
    $Output = & $MainScript -Action analyze 2>&1

    if ($Output -match "SUCCESS" -or $Output -match "Analysis completed") {
        Write-Host "[PASS] Integration test passed" -ForegroundColor Green
        $Results.integration = "PASS"
    } else {
        Write-Host "[WARN] Integration test has warnings" -ForegroundColor Yellow
        $Results.integration = "WARN"
    }
} catch {
    Write-Host "[WARN] Integration test has errors" -ForegroundColor Yellow
    $Results.integration = "WARN"
}

# Summary
Write-Host "`n========== Test Summary ==========" -ForegroundColor Magenta
$TotalTests = ($Results.Keys.Count)
$PassedTests = ($Results.Values | Where-Object { $_ -eq "PASS" }).Count

Write-Host "Total Tests: $TotalTests" -ForegroundColor Cyan
Write-Host "Passed: $PassedTests" -ForegroundColor Green
Write-Host "Failed: $($TotalTests - $PassedTests)" -ForegroundColor Red

if ($PassedTests -eq $TotalTests) {
    Write-Host "`n[SUCCESS] All tests passed!`n" -ForegroundColor Green
    $Results.overall = "PASS"
} else {
    Write-Host "`n[FAIL] Some tests failed`n" -ForegroundColor Red
    $Results.overall = "FAIL"
}

$Results
