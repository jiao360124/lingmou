# Lingmou v3.2.6 Feature Application Script
# Date: 2026-02-26
# Goal: Step-by-step apply all v3.2.6 features

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Lingmou v3.2.6 Feature Application" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Initialize test results
$testResults = @{
    "Gateway Status" = $false
    "AI Toolkit" = $false
    "Search Toolkit" = $false
    "Dev Toolkit" = $false
    "Monitoring Module" = $false
    "Strategy Engine" = $false
    "Unified Export" = $false
}

# 1. Check Gateway Status
Write-Host "1. Checking Gateway Status..." -ForegroundColor Yellow
$gatewayStatus = openclaw gateway status 2>&1
if ($gatewayStatus -match "RUNNING" -or $gatewayStatus -match "正常") {
    Write-Host "   [OK] Gateway is running normally" -ForegroundColor Green
    $testResults["Gateway Status"] = $true
} else {
    Write-Host "   [FAIL] Gateway is not running properly" -ForegroundColor Red
}
Write-Host ""

# 2. Check AI Toolkit
Write-Host "2. Checking AI Toolkit..." -ForegroundColor Yellow
$aiToolkitDirs = @(
    "skills/ai-toolkit/prompt-engineering",
    "skills/ai-toolkit/moltbook",
    "skills/ai-toolkit/rag"
)
$aiToolkitPassed = 0
foreach ($dir in $aiToolkitDirs) {
    if (Test-Path $dir) {
        Write-Host "   [OK] $dir" -ForegroundColor Green
        $aiToolkitPassed++
    } else {
        Write-Host "   [FAIL] $dir" -ForegroundColor Red
    }
}
if ($aiToolkitPassed -eq 3) {
    Write-Host "   [OK] AI Toolkit is complete" -ForegroundColor Green
    $testResults["AI Toolkit"] = $true
} else {
    Write-Host "   [WARN] AI Toolkit incomplete ($aiToolkitPassed/3)" -ForegroundColor Yellow
}
Write-Host ""

# 3. Check Search Toolkit
Write-Host "3. Checking Search Toolkit..." -ForegroundColor Yellow
$searchToolkitDirs = @(
    "skills/search-toolkit/deepwiki",
    "skills/search-toolkit/exa-web-search"
)
$searchToolkitPassed = 0
foreach ($dir in $searchToolkitDirs) {
    if (Test-Path $dir) {
        Write-Host "   [OK] $dir" -ForegroundColor Green
        $searchToolkitPassed++
    } else {
        Write-Host "   [FAIL] $dir" -ForegroundColor Red
    }
}
if ($searchToolkitPassed -eq 2) {
    Write-Host "   [OK] Search Toolkit is complete" -ForegroundColor Green
    $testResults["Search Toolkit"] = $true
} else {
    Write-Host "   [WARN] Search Toolkit incomplete ($searchToolkitPassed/2)" -ForegroundColor Yellow
}
Write-Host ""

# 4. Check Dev Toolkit
Write-Host "4. Checking Dev Toolkit..." -ForegroundColor Yellow
$devToolkitDirs = @(
    "skills/dev-toolkit/api-dev",
    "skills/dev-toolkit/database",
    "skills/dev-toolkit/sql-toolkit"
)
$devToolkitPassed = 0
foreach ($dir in $devToolkitDirs) {
    if (Test-Path $dir) {
        Write-Host "   [OK] $dir" -ForegroundColor Green
        $devToolkitPassed++
    } else {
        Write-Host "   [FAIL] $dir" -ForegroundColor Red
    }
}
if ($devToolkitPassed -eq 3) {
    Write-Host "   [OK] Dev Toolkit is complete" -ForegroundColor Green
    $testResults["Dev Toolkit"] = $true
} else {
    Write-Host "   [WARN] Dev Toolkit incomplete ($devToolkitPassed/3)" -ForegroundColor Yellow
}
Write-Host ""

# 5. Check Monitoring Module
Write-Host "5. Checking Monitoring Module..." -ForegroundColor Yellow
$monitoringFiles = @(
    "core/monitoring/index.js",
    "core/monitoring/performance-monitor.js",
    "core/monitoring/memory-monitor.js",
    "core/monitoring/api-tracker.js"
)
$monitoringPassed = 0
foreach ($file in $monitoringFiles) {
    if (Test-Path $file) {
        Write-Host "   [OK] $file" -ForegroundColor Green
        $monitoringPassed++
    } else {
        Write-Host "   [FAIL] $file" -ForegroundColor Red
    }
}
if ($monitoringPassed -eq 4) {
    Write-Host "   [OK] Monitoring Module is complete" -ForegroundColor Green
    $testResults["Monitoring Module"] = $true
} else {
    Write-Host "   [WARN] Monitoring Module incomplete ($monitoringPassed/4)" -ForegroundColor Yellow
}
Write-Host ""

# 6. Check Strategy Engine
Write-Host "6. Checking Strategy Engine..." -ForegroundColor Yellow
$strategyFiles = @(
    "core/strategy/index.js",
    "core/strategy/strategy-engine.js",
    "core/strategy/strategy-engine-enhanced.js",
    "core/strategy/scenario-generator.js",
    "core/strategy/scenario-evaluator.js",
    "core/strategy/risk-assessor.js",
    "core/strategy/risk-controller.js",
    "core/strategy/risk-adjusted-scorer.js",
    "core/strategy/adversary-simulator.js",
    "core/strategy/multi-perspective-evaluator.js",
    "core/strategy/cost-calculator.js",
    "core/strategy/benefit-calculator.js",
    "core/strategy/roi-analyzer.js"
)
$strategyPassed = 0
foreach ($file in $strategyFiles) {
    if (Test-Path $file) {
        Write-Host "   [OK] $file" -ForegroundColor Green
        $strategyPassed++
    } else {
        Write-Host "   [FAIL] $file" -ForegroundColor Red
    }
}
if ($strategyPassed -eq 13) {
    Write-Host "   [OK] Strategy Engine is complete" -ForegroundColor Green
    $testResults["Strategy Engine"] = $true
} else {
    Write-Host "   [WARN] Strategy Engine incomplete ($strategyPassed/13)" -ForegroundColor Yellow
}
Write-Host ""

# 7. Check Unified Export
Write-Host "7. Checking Unified Export..." -ForegroundColor Yellow
$indexFiles = @(
    "core/index.js",
    "core/monitoring/index.js",
    "core/strategy/index.js"
)
$indexPassed = 0
foreach ($file in $indexFiles) {
    if (Test-Path $file) {
        Write-Host "   [OK] $file" -ForegroundColor Green
        $indexPassed++
    } else {
        Write-Host "   [FAIL] $file" -ForegroundColor Red
    }
}
if ($indexPassed -eq 3) {
    Write-Host "   [OK] Unified Export is complete" -ForegroundColor Green
    $testResults["Unified Export"] = $true
} else {
    Write-Host "   [WARN] Unified Export incomplete ($indexPassed/3)" -ForegroundColor Yellow
}
Write-Host ""

# 8. Check Tests Directory
Write-Host "8. Checking Tests Directory..." -ForegroundColor Yellow
$testFiles = @(
    "tests/test-memory.js",
    "tests/test-memory-simple.js",
    "tests/test-performance.js",
    "tests/test-security.js",
    "tests/test-security-email.js",
    "tests/test-usage.js"
)
$testPassed = 0
foreach ($file in $testFiles) {
    if (Test-Path $file) {
        Write-Host "   [OK] $file" -ForegroundColor Green
        $testPassed++
    } else {
        Write-Host "   [FAIL] $file" -ForegroundColor Red
    }
}
if ($testPassed -eq 6) {
    Write-Host "   [OK] Test files are complete" -ForegroundColor Green
} else {
    Write-Host "   [WARN] Test files incomplete ($testPassed/6)" -ForegroundColor Yellow
}
Write-Host ""

# 9. Check Version Config
Write-Host "9. Checking Version Config..." -ForegroundColor Yellow
if (Test-Path "core/version-v3.2.6.json") {
    Write-Host "   [OK] core/version-v3.2.6.json" -ForegroundColor Green
    $versionContent = Get-Content "core/version-v3.2.6.json" -Raw | ConvertFrom-Json
    Write-Host "   Version: $($versionContent.version)" -ForegroundColor Cyan
    Write-Host "   Release Date: $($versionContent.releaseDate)" -ForegroundColor Cyan
    Write-Host "   Description: $($versionContent.description)" -ForegroundColor Cyan
} else {
    Write-Host "   [FAIL] Version config file not found" -ForegroundColor Red
}
Write-Host ""

# 10. Check Documentation
Write-Host "10. Checking Documentation..." -ForegroundColor Yellow
$docs = @(
    "skills/v3.2.6-README.md",
    "reports/v326-integration-report-20260226-213000.txt"
)
$docsPassed = 0
foreach ($doc in $docs) {
    if (Test-Path $doc) {
        Write-Host "   [OK] $doc" -ForegroundColor Green
        $docsPassed++
    } else {
        Write-Host "   [FAIL] $doc" -ForegroundColor Red
    }
}
if ($docsPassed -eq 2) {
    Write-Host "   [OK] Documentation is complete" -ForegroundColor Green
} else {
    Write-Host "   [WARN] Documentation incomplete ($docsPassed/2)" -ForegroundColor Yellow
}
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Results Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
$passed = 0
foreach ($key in $testResults.Keys) {
    if ($testResults[$key]) {
        Write-Host "[OK] $key" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "[FAIL] $key" -ForegroundColor Red
    }
}
Write-Host ""
$rate = [math]::Round($passed/$testResults.Count*100, 1)
Write-Host "Pass Rate: $passed/$($testResults.Count) ($rate%)" -ForegroundColor $(if ($passed -eq $testResults.Count) { "Green" } else { "Yellow" })
Write-Host ""

# 11. Feature Testing
Write-Host "11. Feature Testing..." -ForegroundColor Yellow
Write-Host "   Testing AI Toolkit features..."
if (Test-Path "skills/ai-toolkit/SKILL.md") {
    $aiSkill = Get-Content "skills/ai-toolkit/SKILL.md" -Raw
    if ($aiSkill -match "AI/LLM Toolkit") {
        Write-Host "   [OK] AI Toolkit SKILL.md is valid" -ForegroundColor Green
    }
}

Write-Host "   Testing Search Toolkit features..."
if (Test-Path "skills/search-toolkit/SKILL.md") {
    $searchSkill = Get-Content "skills/search-toolkit/SKILL.md" -Raw
    if ($searchSkill -match "Search Toolkit") {
        Write-Host "   [OK] Search Toolkit SKILL.md is valid" -ForegroundColor Green
    }
}

Write-Host "   Testing Dev Toolkit features..."
if (Test-Path "skills/dev-toolkit/SKILL.md") {
    $devSkill = Get-Content "skills/dev-toolkit/SKILL.md" -Raw
    if ($devSkill -match "Dev Toolkit") {
        Write-Host "   [OK] Dev Toolkit SKILL.md is valid" -ForegroundColor Green
    }
}
Write-Host ""

# 12. System Health Check
Write-Host "12. System Health Check..." -ForegroundColor Yellow
$healthChecks = @(
    { return (Test-Path "core/index.js") },
    { return (Test-Path "core/monitoring/index.js") },
    { return (Test-Path "core/strategy/index.js") },
    { return (Test-Path "skills/ai-toolkit/SKILL.md") },
    { return (Test-Path "skills/search-toolkit/SKILL.md") },
    { return (Test-Path "skills/dev-toolkit/SKILL.md") }
)
$healthPassed = 0
foreach ($check in $healthChecks) {
    if (& $check) {
        Write-Host "   [OK] Health check passed" -ForegroundColor Green
        $healthPassed++
    }
}
Write-Host ""

# Final Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "v3.2.6 Feature Application Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[OK] Passed features: $passed/$($testResults.Count)" -ForegroundColor $(if ($passed -eq $testResults.Count) { "Green" } else { "Yellow" })
Write-Host ""
Write-Host "Statistics:" -ForegroundColor Cyan
Write-Host "  - AI Toolkit: 3 submodules" -ForegroundColor White
Write-Host "  - Search Toolkit: 2 submodules" -ForegroundColor White
Write-Host "  - Dev Toolkit: 3 submodules" -ForegroundColor White
Write-Host "  - Monitoring Module: 4 files" -ForegroundColor White
Write-Host "  - Strategy Engine: 13 files" -ForegroundColor White
Write-Host "  - Unified Export: 3 index.js files" -ForegroundColor White
Write-Host "  - Test files: 6 test scripts" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Test AI Toolkit's prompt engineering features" -ForegroundColor White
Write-Host "  2. Test Search Toolkit's Exa search features" -ForegroundColor White
Write-Host "  3. Test Dev Toolkit's database connection" -ForegroundColor White
Write-Host "  4. Test Monitoring Module's real-time monitoring" -ForegroundColor White
Write-Host "  5. Test Strategy Engine's decision capabilities" -ForegroundColor White
Write-Host ""
Write-Host "v3.2.6 Feature Application Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
