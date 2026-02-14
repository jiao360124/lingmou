# Integration Test Module
# Comprehensive integration tests for all modules

param(
    [switch]$Detailed
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ReportDir = Join-Path $ScriptDir "..\reports"
if (-not (Test-Path $ReportDir)) { New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null }

$Results = @{
    Total = 0
    Passed = 0
    Failed = 0
    Warnings = @()
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
        [string]$Message = ""
    )

    $Status = if ($Passed) { "✅ PASS" } else { "❌ FAIL" }
    $Color = if ($Passed) { "Green" } else { "Red" }

    if ($Detailed) {
        Write-Host "[$Status] $TestName" -ForegroundColor $Color
        if ($Message) { Write-Host "       $Message" -ForegroundColor DarkGray }
    }

    return $Passed
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

Write-Header "Integration Test v2.0"

# Test 1: Core Modules
Write-Host "`n[Test 1/8] Core Modules..." -ForegroundColor Cyan
$Results.Total++
try {
    $CoreModules = @(
        "clear-context",
        "daily-backup",
        "git-backup",
        "simple-health-check",
        "error-logger"
    )

    $PassedModules = 0
    foreach ($module in $CoreModules) {
        $scriptPath = Join-Path $ScriptDir "$module.ps1"
        if (Test-Path $scriptPath) {
            $PassedModules++
        } else {
            Write-Warning "Missing: $module.ps1"
        }
    }

    $Result = Write-Result "Core Modules" -Passed ($PassedModules -gt 0) -Message "$PassedModules/$($CoreModules.Count) modules available"
    $Results.Passed++
    $Results.Warnings += "Missing: $($CoreModules.Count - $PassedModules) modules"
} catch {
    $Result = Write-Result "Core Modules" -Passed $false -Message $_.Exception.Message
    $Results.Failed++
    $Results.Errors += "Core Modules: $_"
}

# Test 2: Backup Systems
Write-Host "`n[Test 2/8] Backup Systems..." -ForegroundColor Cyan
$Results.Total++
try {
    $BackupModules = @(
        "daily-backup",
        "git-backup",
        "moltbook-introduce",
        "moltbook-post",
        "moltbook-comment"
    )

    $Passed = 0
    foreach ($module in $BackupModules) {
        if (Test-Path (Join-Path $ScriptDir "$module.ps1")) {
            $Passed++
        }
    }

    $Result = Write-Result "Backup Systems" -Passed ($Passed -gt 0) -Message "$Passed/$($BackupModules.Count) backup modules available"
    $Results.Passed++
    $Results.Warnings += "Missing: $($BackupModules.Count - $Passed) modules"
} catch {
    $Result = Write-Result "Backup Systems" -Passed $false -Message $_.Exception.Message
    $Results.Failed++
    $Results.Errors += "Backup Systems: $_"
}

# Test 3: Performance Modules
Write-Host "`n[Test 3/8] Performance Modules..." -ForegroundColor Cyan
$Results.Total++
try {
    $PerfModules = @(
        "performance-benchmark",
        "gradual-degradation",
        "gateway-optimizer"
    )

    $Passed = 0
    foreach ($module in $PerfModules) {
        if (Test-Path (Join-Path $ScriptDir "$module.ps1")) {
            $Passed++
        }
    }

    $Result = Write-Result "Performance Modules" -Passed ($Passed -gt 0) -Message "$Passed/$($PerfModules.Count) performance modules available"
    $Results.Passed++
    $Results.Warnings += "Missing: $($PerfModules.Count - $Passed) modules"
} catch {
    $Result = Write-Result "Performance Modules" -Passed $false -Message $_.Exception.Message
    $Results.Failed++
    $Results.Errors += "Performance Modules: $_"
}

# Test 4: Skill Integration
Write-Host "`n[Test 4/8] Skill Integration..." -ForegroundColor Cyan
$Results.Total++
try {
    $SkillDir = Join-Path $ScriptDir "..\skills"
    if (Test-Path $SkillDir) {
        $Skills = Get-ChildItem $SkillDir -Directory -ErrorAction SilentlyContinue
        $SkillCount = $Skills.Count

        if ($Detailed) {
            Write-Host "       Skills: $($SkillCount)" -ForegroundColor DarkGray
            $SampleSkills = $Skills | Select-Object -First 5 -ExpandProperty Name
            Write-Host "       Sample skills: $($SampleSkills -join ', ')" -ForegroundColor DarkGray
        }

        $Result = Write-Result "Skill Integration" -Passed ($SkillCount -gt 0) -Message "$SkillCount skills available"
        $Results.Passed++
    } else {
        $Result = Write-Result "Skill Integration" -Passed $false -Message "Skills directory not found"
        $Results.Failed++
    }
} catch {
    $Result = Write-Result "Skill Integration" -Passed $false -Message $_.Exception.Message
    $Results.Failed++
    $Results.Errors += "Skill Integration: $_"
}

# Test 5: Documentation
Write-Host "`n[Test 5/8] Documentation..." -ForegroundColor Cyan
$Results.Total++
try {
    $DocFiles = @(
        "README.md",
        "AUTO_BACKUP_README.md",
        "BOOTSTRAP.md",
        "AGENTS.md",
        "SOUL.md",
        "IDENTITY.md",
        "USER.md"
    )

    $DocCount = 0
    foreach ($doc in $DocFiles) {
        if (Test-Path $doc) { $DocCount++ }
    }

    if ($Detailed) {
        Write-Host "       Documents: $DocCount/$($DocFiles.Count)" -ForegroundColor DarkGray
    }

    $Result = Write-Result "Documentation" -Passed ($DocCount -gt 0) -Message "$DocCount/$($DocFiles.Count) key documents present"
    $Results.Passed++
} catch {
    $Result = Write-Result "Documentation" -Passed $false -Message $_.Exception.Message
    $Results.Failed++
    $Results.Errors += "Documentation: $_"
}

# Test 6: Configuration
Write-Host "`n[Test 6/8] Configuration..." -ForegroundColor Cyan
$Results.Total++
try {
    $ConfigFiles = @(
        ".env.example",
        ".ports.env",
        "HEARTBEAT.md"
    )

    $ConfigCount = 0
    foreach ($config in $ConfigFiles) {
        if (Test-Path $config) { $ConfigCount++ }
    }

    if ($Detailed) {
        Write-Host "       Config files: $ConfigCount/$($ConfigFiles.Count)" -ForegroundColor DarkGray
    }

    $Result = Write-Result "Configuration" -Passed ($ConfigCount -gt 0) -Message "$ConfigCount/$($ConfigFiles.Count) config files present"
    $Results.Passed++
} catch {
    $Result = Write-Result "Configuration" -Passed $false -Message $_.Exception.Message
    $Results.Failed++
    $Results.Errors += "Configuration: $_"
}

# Test 7: Data Storage
Write-Host "`n[Test 7/8] Data Storage..." -ForegroundColor Cyan
$Results.Total++
try {
    $StorageDirs = @(
        "logs",
        "memory",
        "reports",
        "backup",
        "tasks",
        "skill-integration"
    )

    $StorageCount = 0
    foreach ($dir in $StorageDirs) {
        if (Test-Path $dir) { $StorageCount++ }
    }

    if ($Detailed) {
        Write-Host "       Storage dirs: $StorageCount/$($StorageDirs.Count)" -ForegroundColor DarkGray
    }

    $Result = Write-Result "Data Storage" -Passed ($StorageCount -gt 0) -Message "$StorageCount/$($StorageDirs.Count) storage directories present"
    $Results.Passed++
} catch {
    $Result = Write-Result "Data Storage" -Passed $false -Message $_.Exception.Message
    $Results.Failed++
    $Results.Errors += "Data Storage: $_"
}

# Test 8: Project Structure
Write-Host "`n[Test 8/8] Project Structure..." -ForegroundColor Cyan
$Results.Total++
try {
    $Structure = @(
        "scripts",
        "skills",
        "memory",
        "reports",
        "tasks"
    )

    $StructureCount = 0
    foreach ($item in $Structure) {
        if (Test-Path $item) { $StructureCount++ }
    }

    if ($Detailed) {
        Write-Host "       Structure items: $StructureCount/$($Structure.Count)" -ForegroundColor DarkGray
    }

    $Result = Write-Result "Project Structure" -Passed ($StructureCount -gt 0) -Message "$StructureCount/$($Structure.Count) structure items present"
    $Results.Passed++
} catch {
    $Result = Write-Result "Project Structure" -Passed $false -Message $_.Exception.Message
    $Results.Failed++
    $Results.Errors += "Project Structure: $_"
}

# Summary
Write-Host "`n====================================================" -ForegroundColor Magenta
Write-Host "         INTEGRATION TEST SUMMARY" -ForegroundColor Magenta
Write-Host "====================================================" -ForegroundColor Magenta
Write-Host "Tests Run:     $($Results.Total)" -ForegroundColor Cyan
Write-Host "Passed:        $($Results.Passed) ✅" -ForegroundColor Green
Write-Host "Failed:        $($Results.Failed) ❌" -ForegroundColor Red
Write-Host "Success Rate:  $([math]::Round(($Results.Passed / $Results.Total) * 100, 2))%" -ForegroundColor Yellow

if ($Results.Warnings.Count -gt 0) {
    Write-Host "`nWarnings:" -ForegroundColor Yellow
    $Results.Warnings | ForEach-Object { Write-Host "  ⚠️  $_" -ForegroundColor DarkGray }
}

if ($Detailed -and $Results.Errors.Count -gt 0) {
    Write-Host "`nErrors:" -ForegroundColor Red
    $Results.Errors | ForEach-Object { Write-Host "  ❌ $_" -ForegroundColor DarkGray }
}

# Save report
$ReportFile = Join-Path $ReportDir "integration-test-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
$ReportContent = @"
# Integration Test Report
**Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Summary
- **Tests Run:** $($Results.Total)
- **Passed:** $($Results.Passed) ✅
- **Failed:** $($Results.Failed) ❌
- **Success Rate:** $([math]::Round(($Results.Passed / $Results.Total) * 100, 2))%

## Test Results
- **Tests Passed:** $($Results.Passed)
- **Tests Failed:** $($Results.Failed)
- **Warnings:** $($Results.Warnings.Count)

$(if ($Detailed) { $Results.Errors | ForEach-Object { "### $($_): Fail" } })

---
"@

$ReportContent | Out-File -FilePath $ReportFile -Encoding UTF8
Write-Host "`nReport saved: $ReportFile" -ForegroundColor Green

if ($Results.Failed -eq 0) {
    exit 0
} else {
    exit 1
}
