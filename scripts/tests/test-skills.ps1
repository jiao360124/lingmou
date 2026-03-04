# Skill Unit Tests
# Test individual skill modules

param(
    [switch]$Detailed
)

$ErrorActionPreference = "Stop"
$TestDir = Join-Path $PSScriptRoot "..\..\skills"
$ReportDir = Join-Path $PSScriptRoot "..\..\reports"

$Results = @{
    Total = 0
    Passed = 0
    Failed = 0
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

    $Status = if ($Passed) { "PASS" } else { "FAIL" }
    $Color = if ($Passed) { "Green" } else { "Red" }

    if ($Detailed) {
        Write-Host "[$Status] $TestName" -ForegroundColor $Color
        if ($Message) { Write-Host "       $Message" -ForegroundColor DarkGray }
    }

    return $Passed
}

Write-Header "Skill Unit Tests v1.0"

# Test 1: code-mentor skill
Write-Host "`n[Test 1/6] code-mentor Skill..." -ForegroundColor Cyan
$Results.Total++
try {
    $skillPath = Join-Path $TestDir "code-mentor"
    if (Test-Path $skillPath) {
        $skillFiles = Get-ChildItem $skillPath -Filter "*.md" -ErrorAction SilentlyContinue
        $hasReadme = Test-Path (Join-Path $skillPath "SKILL.md")

        if ($Detailed) {
            Write-Host "       Skill files: $($skillFiles.Count)" -ForegroundColor DarkGray
            Write-Host "       Has SKILL.md: $hasReadme" -ForegroundColor DarkGray
        }

        $Result = Write-Result "code-mentor" -Passed ($skillFiles.Count -gt 0 -and $hasReadme)
        $Results.Passed++
    } else {
        $Result = Write-Result "code-mentor" -Passed $false -Message "Skill not found"
        $Results.Failed++
    }
} catch {
    $Result = Write-Result "code-mentor" -Passed $false -Message "Error"
    $Results.Failed++
    $Results.Errors += "code-mentor: Error"
}

# Test 2: git-essentials skill
Write-Host "`n[Test 2/6] git-essentials Skill..." -ForegroundColor Cyan
$Results.Total++
try {
    $skillPath = Join-Path $TestDir "git-essentials"
    if (Test-Path $skillPath) {
        $skillFiles = Get-ChildItem $skillPath -Filter "*.md" -ErrorAction SilentlyContinue
        $hasReadme = Test-Path (Join-Path $skillPath "SKILL.md")

        if ($Detailed) {
            Write-Host "       Skill files: $($skillFiles.Count)" -ForegroundColor DarkGray
            Write-Host "       Has SKILL.md: $hasReadme" -ForegroundColor DarkGray
        }

        $Result = Write-Result "git-essentials" -Passed ($skillFiles.Count -gt 0 -and $hasReadme)
        $Results.Passed++
    } else {
        $Result = Write-Result "git-essentials" -Passed $false -Message "Skill not found"
        $Results.Failed++
    }
} catch {
    $Result = Write-Result "git-essentials" -Passed $false -Message "Error"
    $Results.Failed++
    $Results.Errors += "git-essentials: Error"
}

# Test 3: deepwork-tracker skill
Write-Host "`n[Test 3/6] deepwork-tracker Skill..." -ForegroundColor Cyan
$Results.Total++
try {
    $skillPath = Join-Path $TestDir "deepwork-tracker"
    if (Test-Path $skillPath) {
        $skillFiles = Get-ChildItem $skillPath -Filter "*.md" -ErrorAction SilentlyContinue
        $hasReadme = Test-Path (Join-Path $skillPath "SKILL.md")

        if ($Detailed) {
            Write-Host "       Skill files: $($skillFiles.Count)" -ForegroundColor DarkGray
            Write-Host "       Has SKILL.md: $hasReadme" -ForegroundColor DarkGray
        }

        $Result = Write-Result "deepwork-tracker" -Passed ($skillFiles.Count -gt 0 -and $hasReadme)
        $Results.Passed++
    } else {
        $Result = Write-Result "deepwork-tracker" -Passed $false -Message "Skill not found"
        $Results.Failed++
    }
} catch {
    $Result = Write-Result "deepwork-tracker" -Passed $false -Message "Error"
    $Results.Failed++
    $Results.Errors += "deepwork-tracker: Error"
}

# Test 4: docker-essentials skill
Write-Host "`n[Test 4/6] docker-essentials Skill..." -ForegroundColor Cyan
$Results.Total++
try {
    $skillPath = Join-Path $TestDir "docker-essentials"
    if (Test-Path $skillPath) {
        $skillFiles = Get-ChildItem $skillPath -Filter "*.md" -ErrorAction SilentlyContinue
        $hasReadme = Test-Path (Join-Path $skillPath "SKILL.md")

        if ($Detailed) {
            Write-Host "       Skill files: $($skillFiles.Count)" -ForegroundColor DarkGray
            Write-Host "       Has SKILL.md: $hasReadme" -ForegroundColor DarkGray
        }

        $Result = Write-Result "docker-essentials" -Passed ($skillFiles.Count -gt 0 -and $hasReadme)
        $Results.Passed++
    } else {
        $Result = Write-Result "docker-essentials" -Passed $false -Message "Skill not found"
        $Results.Failed++
    }
} catch {
    $Result = Write-Result "docker-essentials" -Passed $false -Message "Error"
    $Results.Failed++
    $Results.Errors += "docker-essentials: Error"
}

# Test 5: database skill
Write-Host "`n[Test 5/6] database Skill..." -ForegroundColor Cyan
$Results.Total++
try {
    $skillPath = Join-Path $TestDir "database"
    if (Test-Path $skillPath) {
        $skillFiles = Get-ChildItem $skillPath -Filter "*.md" -ErrorAction SilentlyContinue
        $hasReadme = Test-Path (Join-Path $skillPath "SKILL.md")

        if ($Detailed) {
            Write-Host "       Skill files: $($skillFiles.Count)" -ForegroundColor DarkGray
            Write-Host "       Has SKILL.md: $hasReadme" -ForegroundColor DarkGray
        }

        $Result = Write-Result "database" -Passed ($skillFiles.Count -gt 0 -and $hasReadme)
        $Results.Passed++
    } else {
        $Result = Write-Result "database" -Passed $false -Message "Skill not found"
        $Results.Failed++
    }
} catch {
    $Result = Write-Result "database" -Passed $false -Message "Error"
    $Results.Failed++
    $Results.Errors += "database: Error"
}

# Test 6: total skills count
Write-Host "`n[Test 6/6] Total Skills Count..." -ForegroundColor Cyan
$Results.Total++
try {
    $skillsDir = Join-Path $TestDir
    if (Test-Path $skillsDir) {
        $skills = Get-ChildItem $skillsDir -Directory -ErrorAction SilentlyContinue
        $skillCount = $skills.Count

        if ($Detailed) {
            Write-Host "       Total skills: $skillCount" -ForegroundColor DarkGray
            Write-Host "       Sample skills: $($skills | Select-Object -First 5 -ExpandProperty Name -Join ', ')" -ForegroundColor DarkGray
        }

        $Result = Write-Result "Total Skills" -Passed ($skillCount -ge 50)
        $Results.Passed++
    } else {
        $Result = Write-Result "Total Skills" -Passed $false -Message "Skills directory not found"
        $Results.Failed++
    }
} catch {
    $Result = Write-Result "Total Skills" -Passed $false -Message "Error"
    $Results.Failed++
    $Results.Errors += "Total Skills: Error"
}

# Summary
Write-Host "`n====================================================" -ForegroundColor Magenta
Write-Host "           SKILL UNIT TEST SUMMARY" -ForegroundColor Magenta
Write-Host "====================================================" -ForegroundColor Magenta
Write-Host "Tests Run:   $($Results.Total)" -ForegroundColor Cyan
Write-Host "Passed:      $($Results.Passed) PASS" -ForegroundColor Green
Write-Host "Failed:      $($Results.Failed) FAIL" -ForegroundColor Red
Write-Host "Success Rate: $([math]::Round(($Results.Passed / $Results.Total) * 100, 2))%" -ForegroundColor Yellow

if ($Detailed -and $Results.Errors.Count -gt 0) {
    Write-Host "`nErrors:" -ForegroundColor Red
    $Results.Errors | ForEach-Object { Write-Host "  FAIL: $_" -ForegroundColor DarkGray }
}

# Save report
$ReportFile = Join-Path $ReportDir "skill-unit-test-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
$ReportContent = @"
# Skill Unit Test Report
**Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Summary
- **Tests Run:** $($Results.Total)
- **Passed:** $($Results.Passed) PASS
- **Failed:** $($Results.Failed) FAIL
- **Success Rate:** $([math]::Round(($Results.Passed / $Results.Total) * 100, 2))%

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
