# OpenClaw 灵眸 v3.2.5 Integration Script
# Integrate all new v3.3 core modules into v3.2.5

param(
    [switch]$Force = $false
)

$ErrorActionPreference = "Stop"
$workspace = "C:\Users\Administrator\.openclaw\workspace"
$backupDir = "$workspace\backup\v325-integration-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$version = "v3.2.5"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Lingmou v3.2.5 Integration Starting" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan
Write-Host "Time: $timestamp" -ForegroundColor Gray
Write-Host "Workspace: $workspace" -ForegroundColor Gray
Write-Host "Backup: $backupDir" -ForegroundColor Gray

# ==================== Step 1: Create Backup ====================
Write-Host "`n[1/6] Creating backup..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
New-Item -ItemType Directory -Path "$backupDir\backup-core" -Force | Out-Null
New-Item -ItemType Directory -Path "$backupDir\backup-utils" -Force | Out-Null
New-Item -ItemType Directory -Path "$backupDir\backup-economy" -Force | Out-Null
New-Item -ItemType Directory -Path "$backupDir\backup-metrics" -Force | Out-Null

if (Test-Path "$workspace\core") {
    Copy-Item -Path "$workspace\core" -Destination "$backupDir\backup-core" -Recurse -Force
}

if (Test-Path "$workspace\utils") {
    Copy-Item -Path "$workspace\utils" -Destination "$backupDir\backup-utils" -Recurse -Force
}

if (Test-Path "$workspace\economy") {
    Copy-Item -Path "$workspace\economy" -Destination "$backupDir\backup-economy" -Recurse -Force
}

if (Test-Path "$workspace\metrics") {
    Copy-Item -Path "$workspace\metrics" -Destination "$backupDir\backup-metrics" -Recurse -Force
}

Write-Host "[OK] Backup created" -ForegroundColor Green

# ==================== Step 2: Scan All Modules ====================
Write-Host "`n[2/6] Scanning all modules..." -ForegroundColor Yellow

$coreModules = @()
Get-ChildItem -Path "$workspace\core" -Filter "*.js" | ForEach-Object {
    $coreModules += [PSCustomObject]@{
        Name = $_.Name
        Size = $_.Length
        Modified = $_.LastWriteTime
    }
}

$utilsModules = @()
Get-ChildItem -Path "$workspace\utils" -Filter "*.js" | ForEach-Object {
    $utilsModules += [PSCustomObject]@{
        Name = $_.Name
        Size = $_.Length
        Modified = $_.LastWriteTime
    }
}

$economyModules = @()
if (Test-Path "$workspace\economy") {
    Get-ChildItem -Path "$workspace\economy" -Filter "*.js" | ForEach-Object {
        $economyModules += [PSCustomObject]@{
            Name = $_.Name
            Size = $_.Length
            Modified = $_.LastWriteTime
        }
    }
}

$metricsModules = @()
if (Test-Path "$workspace\metrics") {
    Get-ChildItem -Path "$workspace\metrics" -Filter "*.js" | ForEach-Object {
        $metricsModules += [PSCustomObject]@{
            Name = $_.Name
            Size = $_.Length
            Modified = $_.LastWriteTime
        }
    }
}

Write-Host "  Core modules: $($coreModules.Count)" -ForegroundColor White
Write-Host "  Utils modules: $($utilsModules.Count)" -ForegroundColor White
Write-Host "  Economy modules: $($economyModules.Count)" -ForegroundColor White
Write-Host "  Metrics modules: $($metricsModules.Count)" -ForegroundColor White
Write-Host "[OK] Scan completed" -ForegroundColor Green

# ==================== Step 3: Verify Module Integrity ====================
Write-Host "`n[3/6] Verifying module integrity..." -ForegroundColor Yellow

$v33CoreModules = @(
    "adversary-simulator.js",
    "api-tracker.js",
    "benefit-calculator.js",
    "cost-calculator.js",
    "multi-perspective-evaluator.js",
    "risk-adjusted-scorer.js",
    "risk-assessor.js",
    "risk-controller.js",
    "roi-analyzer.js",
    "scenario-evaluator.js",
    "scenario-generator.js",
    "strategy-engine-enhanced.js",
    "watchdog.js",
    "rollback-engine.js",
    "performance-monitor.js",
    "nightly-worker.js",
    "memory-monitor.js"
)

$v33UtilsModules = @(
    "session-compressor.js"
)

$v33EconomyModules = @(
    "token-governor.js"
)

$v33MetricsModules = @(
    "tracker.js"
)

$allValid = $true

Write-Host "`n  Core module verification:" -ForegroundColor Cyan
foreach ($module in $v33CoreModules) {
    $path = "$workspace\core\$module"
    if (Test-Path $path) {
        $size = (Get-Item $path).Length
        $sizeStr = "$size bytes"
        Write-Host "    [OK] $module ($sizeStr)" -ForegroundColor Green
    } else {
        Write-Host "    [MISSING] $module" -ForegroundColor Red
        $allValid = $false
    }
}

Write-Host "`n  Utils module verification:" -ForegroundColor Cyan
foreach ($module in $v33UtilsModules) {
    $path = "$workspace\utils\$module"
    if (Test-Path $path) {
        $size = (Get-Item $path).Length
        $sizeStr = "$size bytes"
        Write-Host "    [OK] $module ($sizeStr)" -ForegroundColor Green
    } else {
        Write-Host "    [MISSING] $module" -ForegroundColor Red
        $allValid = $false
    }
}

Write-Host "`n  Economy module verification:" -ForegroundColor Cyan
foreach ($module in $v33EconomyModules) {
    $path = "$workspace\economy\$module"
    if (Test-Path $path) {
        $size = (Get-Item $path).Length
        $sizeStr = "$size bytes"
        Write-Host "    [OK] $module ($sizeStr)" -ForegroundColor Green
    } else {
        Write-Host "    [MISSING] $module" -ForegroundColor Red
        $allValid = $false
    }
}

Write-Host "`n  Metrics module verification:" -ForegroundColor Cyan
foreach ($module in $v33MetricsModules) {
    $path = "$workspace\metrics\$module"
    if (Test-Path $path) {
        $size = (Get-Item $path).Length
        $sizeStr = "$size bytes"
        Write-Host "    [OK] $module ($sizeStr)" -ForegroundColor Green
    } else {
        Write-Host "    [MISSING] $module" -ForegroundColor Red
        $allValid = $false
    }
}

if (-not $allValid) {
    Write-Host "`n[ERROR] Module verification failed! Please check missing modules." -ForegroundColor Red
    exit 1
}

Write-Host "`n[OK] All modules verified" -ForegroundColor Green

# ==================== Step 4: Create Version Config ====================
Write-Host "`n[4/6] Creating version config..." -ForegroundColor Yellow

$coreTotalSize = ($coreModules | Measure-Object -Property Size -Sum).Sum
$utilsTotalSize = ($utilsModules | Measure-Object -Property Size -Sum).Sum
$economyTotalSize = ($economyModules | Measure-Object -Property Size -Sum).Sum
$metricsTotalSize = ($metricsModules | Measure-Object -Property Size -Sum).Sum
$totalSize = $coreTotalSize + $utilsTotalSize + $economyTotalSize + $metricsTotalSize

$configContent = @"
{
  "version": "$version",
  "releaseDate": "$timestamp",
  "description": "Lingmou v3.2.5 - v3.3 Core Modules Integration",
  "modules": {
    "core": {
      "count": $($coreModules.Count),
      "totalSize": $coreTotalSize
    },
    "utils": {
      "count": $($utilsModules.Count),
      "totalSize": $utilsTotalSize
    },
    "economy": {
      "count": $($economyModules.Count),
      "totalSize": $economyTotalSize
    },
    "metrics": {
      "count": $($metricsModules.Count),
      "totalSize": $metricsTotalSize
    }
  },
  "totalSize": $totalSize,
  "features": [
    "v3.3 Phase 3.3-1: Strategy Engine Enhancement",
    "Scenario Simulator",
    "Cost-Benefit Scorer",
    "Risk Weight Model",
    "Self-Play Mechanism",
    "Multi-Perspective Evaluator",
    "Adversary Simulator",
    "Session Compressor",
    "Token Governor",
    "Performance Monitor",
    "Nightly Worker",
    "Watchdog",
    "Rollback Engine",
    "Architecture Auditor",
    "Unified Index"
  ],
  "integration": {
    "baseVersion": "v3.2",
    "fromVersion": "v3.3-phase1",
    "type": "partial"
  },
  "testing": {
    "status": "pending",
    "coverage": "pending"
  }
}
"@

$configPath = "$workspace\core\version-$version.json"
$configContent | Out-File -FilePath $configPath -Encoding UTF8

Write-Host "[OK] Version config created: version-$version.json" -ForegroundColor Green

# ==================== Step 5: Generate Integration Report ====================
Write-Host "`n[5/6] Generating integration report..." -ForegroundColor Yellow

$reportPath = "$workspace\reports\v325-integration-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"

$reportContent = @"
========================================
Lingmou v3.2.5 Integration Report
========================================

Time: $timestamp
Version: $version
Type: v3.3 Core Modules Integration

========================================
Module Statistics
========================================

Core modules: $($coreModules.Count) modules
Total size: $((($coreTotalSize) / 1KB).ToString('F2')) KB

Utils modules: $($utilsModules.Count) modules
Total size: $((($utilsTotalSize) / 1KB).ToString('F2')) KB

Economy modules: $($economyModules.Count) modules
Total size: $((($economyTotalSize) / 1KB).ToString('F2')) KB

Metrics modules: $($metricsModules.Count) modules
Total size: $((($metricsTotalSize) / 1KB).ToString('F2')) KB

TOTAL SIZE: $((($totalSize) / 1KB).ToString('F2')) KB

========================================
New Features (v3.3 Phase 3.3-1)
========================================

Strategy Engine Enhancement:
  - Scenario Simulator (scenario-generator.js + scenario-evaluator.js)
  - Cost-Benefit Scorer (cost-calculator.js + benefit-calculator.js + roi-analyzer.js)
  - Risk Weight Model (risk-assessor.js + risk-controller.js + risk-adjusted-scorer.js)
  - Self-Play Mechanism (adversary-simulator.js + multi-perspective-evaluator.js)
  - Enhanced Strategy Engine (strategy-engine-enhanced.js)

Monitoring & Optimization:
  - Performance Monitor (performance-monitor.js)
  - Nightly Worker (nightly-worker.js)
  - Memory Monitor (memory-monitor.js)
  - Watchdog (watchdog.js)

System Enhancement:
  - Rollback Engine (rollback-engine.js)
  - Unified Index (unified-index.js)
  - Architecture Auditor (architecture-auditor.js)
  - API Tracker (api-tracker.js)

Economy System:
  - Token Governor (economy/token-governor.js)

Metrics Tracking:
  - Tracker (metrics/tracker.js)
  - Dashboard Data (metrics/dashboard-data.json)

Utils Modules:
  - Session Compressor (utils/session-compressor.js)

========================================
Integration Notes
========================================

Base version: v3.2
Integration source: v3.3 Phase 3.3-1
Integration type: Partial integration

Not integrated (waiting for v3.3):
  - Phase 3.3-2: Cognitive Layer Deepening
  - Phase 3.3-3: Architecture Self-Audit Improvement
  - Phase 3.3-4: Integration and Testing

========================================
Next Steps
========================================

1. Test all core modules
2. Verify module dependencies
3. Update documentation (v3.2.5-README.md)
4. Git commit changes
5. Push to remote repository

========================================
Backup Information
========================================

Backup directory: $backupDir
Backup contents:
  - backup-core/ - Complete core modules
  - backup-utils/ - Complete utils modules
  - backup-economy/ - Complete economy modules
  - backup-metrics/ - Complete metrics modules

Rollback command:
  Copy-Item -Path "$backupDir\backup-core" -Destination "core" -Recurse -Force
  Copy-Item -Path "$backupDir\backup-utils" -Destination "utils" -Recurse -Force
  Copy-Item -Path "$backupDir\backup-economy" -Destination "economy" -Recurse -Force
  Copy-Item -Path "$backupDir\backup-metrics" -Destination "metrics" -Recurse -Force

========================================
Report Generated: $timestamp
========================================
"@

$reportContent | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "[OK] Integration report generated: $reportPath" -ForegroundColor Green

# ==================== Step 6: Prepare Git Commit Message ====================
Write-Host "`n[6/6] Preparing Git commit..." -ForegroundColor Yellow

$commitMsgPath = "$workspace\scripts\commit-v325.txt"

$commitMessage = @"
feat: Lingmou v3.2.5 - v3.3 Core Modules Integration

## Version Info
- Version: v3.2.5
- Time: $timestamp
- Type: Partial integration (v3.3 Phase 3.3-1)

## New Features

### Strategy Engine Enhancement (v3.3 Phase 3.3-1)
- Scenario Simulator (scenario-generator.js, scenario-evaluator.js)
- Cost-Benefit Scorer (cost-calculator.js, benefit-calculator.js, roi-analyzer.js)
- Risk Weight Model (risk-assessor.js, risk-controller.js, risk-adjusted-scorer.js)
- Self-Play Mechanism (adversary-simulator.js, multi-perspective-evaluator.js)
- Enhanced Strategy Engine (strategy-engine-enhanced.js)

### Monitoring & Optimization
- Performance Monitor (performance-monitor.js)
- Nightly Worker (nightly-worker.js)
- Memory Monitor (memory-monitor.js)
- Watchdog (watchdog.js)

### System Enhancement
- Rollback Engine (rollback-engine.js)
- Unified Index (unified-index.js)
- Architecture Auditor (architecture-auditor.js)
- API Tracker (api-tracker.js)

### Economy System
- Token Governor (economy/token-governor.js)

### Metrics Tracking
- Tracker (metrics/tracker.js)
- Dashboard Data (metrics/dashboard-data.json)

### Utils Modules
- Session Compressor (utils/session-compressor.js)

## Module Statistics
- Core modules: $($coreModules.Count) modules
- Utils modules: $($utilsModules.Count) modules
- Economy modules: $($economyModules.Count) modules
- Metrics modules: $($metricsModules.Count) modules
- Total size: $((($totalSize) / 1KB).ToString('F2')) KB

## Integration Notes
- Base version: v3.2
- Integration source: v3.3 Phase 3.3-1
- Integration type: Partial integration

## Backup Information
- Backup directory: $backupDir

## Next Steps
- Test all core modules
- Verify module dependencies
- Update documentation (v3.2.5-README.md)
- Git commit changes

See reports/ and scripts/ for details.
"@

$commitMessage | Out-File -FilePath $commitMsgPath -Encoding UTF8

Write-Host "[OK] Git commit message prepared: $commitMsgPath" -ForegroundColor Green

# ==================== Complete ====================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Lingmou v3.2.5 Integration Complete" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan
Write-Host "Version: $version" -ForegroundColor Green
Write-Host "Backup: $backupDir" -ForegroundColor Green
Write-Host "Report: $reportPath" -ForegroundColor Green
Write-Host "Git commit: $commitMsgPath" -ForegroundColor Green

Write-Host "`nStatistics:" -ForegroundColor Yellow
Write-Host "  Core modules: $($coreModules.Count)" -ForegroundColor White
Write-Host "  Utils modules: $($utilsModules.Count)" -ForegroundColor White
Write-Host "  Economy modules: $($economyModules.Count)" -ForegroundColor White
Write-Host "  Metrics modules: $($metricsModules.Count)" -ForegroundColor White
Write-Host "  Total size: $((($totalSize) / 1KB).ToString('F2')) KB" -ForegroundColor White

Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "  1. View integration report: $reportPath" -ForegroundColor White
Write-Host "  2. Git commit: git commit -F scripts/commit-v325.txt" -ForegroundColor White
Write-Host "  3. Push to remote: git push" -ForegroundColor White

Write-Host "`n" -ForegroundColor White
