# Git-Based Auto Backup
# Fast backup by committing to Git repository

param(
    [switch]$DryRun
)

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$memoryFile = "memory/$(Get-Date -Format 'yyyy-MM-dd').md"

Write-Host "Git-Based Backup Started" -ForegroundColor Cyan
Write-Host "  Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# 1. Check Git status
Write-Host "Checking Git status..." -ForegroundColor Cyan

$gitStatus = git status --porcelain
$hasChanges = $gitStatus -ne ""

if ($gitStatus) {
    Write-Host "  Files changed:" -ForegroundColor Yellow
    $gitStatus.Split("`n") | ForEach-Object {
        if ($_) {
            $parts = $_ -split " "
            $status = $parts[0]
            $file = $parts[1]
            $color = switch ($status) {
                "M" { "Green" }
                "A" { "Cyan" }
                "D" { "Red" }
                default { "White" }
            }
            Write-Host "    [$status] $file" -ForegroundColor $color
        }
    }
} else {
    Write-Host "  No changes detected" -ForegroundColor Green
}

Write-Host ""

# 2. Stash changes if needed
$stashed = $false
if ($hasChanges -and -not $DryRun) {
    Write-Host "Stashing changes..." -ForegroundColor Cyan
    git stash push -m "Backup stash: $timestamp" --include-untracked
    $stashed = $LASTEXITCODE -eq 0
    if ($stashed) {
        Write-Host "  Changes stashed" -ForegroundColor Green
    } else {
        Write-Host "  Failed to stash" -ForegroundColor Red
    }
}

Write-Host ""

# 3. Commit backup
Write-Host "Creating backup commit..." -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "  [DRY RUN] Would commit" -ForegroundColor Magenta
    $commitHash = "test123"
} else {
    git add .
    git commit -m "Auto backup: $timestamp" --author="LingMou <lingmou@openclaw.local>" --quiet
    $commitHash = git rev-parse HEAD
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "  Commit created: $commitHash" -ForegroundColor Green
} else {
    Write-Host "  Commit failed" -ForegroundColor Red
}

Write-Host ""

# 4. Push to GitHub
$pushed = $false

if ($hasChanges -and -not $DryRun) {
    Write-Host "Pushing to GitHub..." -ForegroundColor Cyan
    git push origin main
    $pushed = $LASTEXITCODE -eq 0
    if ($pushed) {
        Write-Host "  Successfully pushed" -ForegroundColor Green
    } else {
        Write-Host "  Push failed" -ForegroundColor Red
    }
} else {
    Write-Host "  No changes to push" -ForegroundColor Yellow
}

Write-Host ""

# 5. Restore stashed changes
if ($stashed -and -not $DryRun) {
    Write-Host "Restoring stashed changes..." -ForegroundColor Cyan
    git stash pop --quiet
    Write-Host "  Changes restored" -ForegroundColor Green
}

Write-Host ""

# 6. Update memory file
if (-not $DryRun) {
    Write-Host "Updating memory file..." -ForegroundColor Cyan

    $backupEntry = "## Git-Based Auto Backup Log`n`n### $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n- Commit: $commitHash`n- Status: $(if ($pushed) { "OK" } else { "Failed" })`n- Files changed: $(if ($hasChanges) { "Yes" } else { "None" })"

    if (Test-Path -Path $memoryFile) {
        Add-Content -Path $memoryFile -Value $backupEntry
    } else {
        # Create new memory file
        $memoryDir = "memory"
        if (!(Test-Path -Path $memoryDir)) {
            New-Item -ItemType Directory -Path $memoryDir | Out-Null
        }
        Add-Content -Path $memoryFile -Value "# LingMou's Daily Memory`n" -Encoding UTF8
        Add-Content -Path $memoryFile -Value $backupEntry
    }

    Write-Host "  Memory file updated" -ForegroundColor Green
}

Write-Host ""
Write-Host "Backup completed!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor DarkGray
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  - Backup method: Git commit" -ForegroundColor White
Write-Host "  - Commit hash: $commitHash" -ForegroundColor White
Write-Host "  - Pushed to GitHub: $(if ($pushed) { "Yes" } else { "No" })" -ForegroundColor $(if ($pushed) { "Green" } else { "Yellow" })
Write-Host "  - Files changed: $(if ($hasChanges) { "Yes" } else { "None" })" -ForegroundColor White
Write-Host "========================================" -ForegroundColor DarkGray
