# Auto Backup System
# Automatically creates local backups and pushes to GitHub

param(
    [switch]$PushToGitHub,
    [switch]$DryRun
)

# Load environment variables
if (Test-Path -Path ".env-loader.ps1") {
    . .env-loader.ps1
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = "backup"
$zipFile = "$backupDir\$timestamp.zip"
$memoryFile = "memory/$(Get-Date -Format 'yyyy-MM-dd').md"

# Configuration
$MAX_BACKUPS = 7
$MAX_ZIP_SIZE_MB = 100

Write-Host "Auto Backup System Started" -ForegroundColor Cyan
Write-Host "  Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "  Push to GitHub: $PushToGitHub" -ForegroundColor $(if ($PushToGitHub) { "Green" } else { "Yellow" })
Write-Host "  DryRun: $DryRun" -ForegroundColor $(if ($DryRun) { "Magenta" } else { "Gray" })
Write-Host ""

# Ensure backup directory exists
if (!(Test-Path -Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir | Out-Null
    Write-Host "Backup directory created" -ForegroundColor Cyan
}

# 1. Create local backup
Write-Host "Creating local backup..." -ForegroundColor Cyan

$files = Get-ChildItem -Path . -Recurse -File | Where-Object {
    $relativePath = $_.FullName.Substring((Get-Location).Path.Length + 1)
    $relativePath.Split('\')[0] -ne $backupDir
}

if ($files.Count -eq 0) {
    Write-Host "No files to backup" -ForegroundColor Yellow
    exit 0
}

$zipSize = 0

try {
    if (-not $DryRun) {
        Compress-Archive -Path $files.FullName -DestinationPath $zipFile -Force
        $zipSize = [math]::Round((Get-Item $zipFile).Length / 1MB, 2)
    }

    Write-Host "Backup created successfully" -ForegroundColor Green
    Write-Host "  File: $zipFile" -ForegroundColor White
    Write-Host "  Size: $zipSize MB" -ForegroundColor White
} catch {
    Write-Host "Backup creation failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# 2. Clean up old backups
Write-Host "Cleaning up old backups..." -ForegroundColor Cyan

$zipFiles = Get-ChildItem -Path $backupDir -Filter "*.zip" |
             Sort-Object LastWriteTime -Descending

if ($zipFiles.Count -gt $MAX_BACKUPS) {
    $toDelete = $zipFiles | Select-Object -Skip $MAX_BACKUPS
    foreach ($file in $toDelete) {
        if (-not $DryRun) {
            Remove-Item -Path $file.FullName -Force
        }
        Write-Host "  Deleted: $($file.Name)" -ForegroundColor DarkGray
    }
    Write-Host "Kept last $MAX_BACKUPS backups" -ForegroundColor Green
} else {
    Write-Host "Backup count within limit" -ForegroundColor Green
}

Write-Host ""

# 3. Push to GitHub (if requested)
$githubPushed = $false

if ($PushToGitHub) {
    Write-Host "Pushing to GitHub..." -ForegroundColor Cyan

    if ($DryRun) {
        Write-Host "  [DRY RUN] Would push to GitHub" -ForegroundColor Magenta
    } else {
        try {
            $env:GIT_AUTHOR_NAME = "LingMou"
            $env:GIT_AUTHOR_EMAIL = "lingmou@openclaw.local"
            $env:GIT_COMMITTER_NAME = "LingMou"
            $env:GIT_COMMITTER_EMAIL = "lingmou@openclaw.local"

            git add "$backupDir/$timestamp.zip"
            git commit -m "Auto backup: $timestamp ($zipSize MB)" --author="LingMou <lingmou@openclaw.local>"

            if ($LASTEXITCODE -eq 0) {
                git push origin main
                if ($LASTEXITCODE -eq 0) {
                    $githubPushed = $true
                    Write-Host "Successfully pushed to GitHub" -ForegroundColor Green
                } else {
                    Write-Host "Git push failed" -ForegroundColor Red
                }
            } else {
                Write-Host "Git commit failed" -ForegroundColor Red
            }
        } catch {
            Write-Host "Push failed: $_" -ForegroundColor Red
        }
    }
} else {
    Write-Host "Skipping GitHub push" -ForegroundColor Yellow
}

Write-Host ""

# 4. Update memory file
if (-not $DryRun) {
    Write-Host "Updating memory file..." -ForegroundColor Cyan

    $backupEntry = "## Auto Backup Log`n`n### $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n- File: $zipFile`n- Size: $zipSize MB`n- Local: OK`n- GitHub: $(if ($githubPushed) { "OK" } else { "Skipped" })`n- Backups kept: $MAX_BACKUPS"

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

    Write-Host "Memory file updated" -ForegroundColor Green
}

Write-Host ""
Write-Host "Backup completed!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor DarkGray
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  - Local backup: OK ($zipFile, $zipSize MB)" -ForegroundColor White
Write-Host "  - GitHub push: $(if ($githubPushed) { "OK" } else { "Skipped" })" -ForegroundColor $(if ($githubPushed) { "Green" } else { "Yellow" })
Write-Host "  - Backups kept: $MAX_BACKUPS" -ForegroundColor White
Write-Host "========================================" -ForegroundColor DarkGray
