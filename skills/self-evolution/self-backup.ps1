# Self-Backup - Self-Evolution Backup System
# Provides automated backup and recovery capabilities

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Full", "Incremental")]
    [string]$Type = "Full",

    [Parameter(Mandatory=$false)]
    [switch]$Restore,

    [Parameter(Mandatory=$false)]
    [switch]$List,

    [Parameter(Mandatory=$false)]
    [switch]$Validate,

    [Parameter(Mandatory=$false)]
    [string]$BackupID = $null,

    [Parameter(Mandatory=$false)]
    [string]$Description = "Auto backup"

)

# Configuration
$Config = @{
    BackupDir = "backups/self-backup"
    MaxBackups = 10
    BackupLocation = "C:\Users\Administrator\.openclaw\workspace"
    IncludePatterns = @("*.md", "*.ps1", "*.json", "*.txt", "scripts", "skills", "memory")
    ExcludePatterns = @("node_modules", "dist", "build", "*.log")
}

# Ensure backup directory exists
if (-not (Test-Path $Config.BackupDir)) {
    New-Item -ItemType Directory -Path $Config.BackupDir -Force | Out-Null
}

# Backup function
function Invoke-SelfBackup {
    param([string]$Description)

    $Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $BackupID = "self-backup-$Timestamp"

    Write-Host "=== Self-Backup Started ===" -ForegroundColor Cyan
    Write-Host "Backup ID: $BackupID"
    Write-Host "Type: $Type"
    Write-Host "Description: $Description"
    Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host ""

    # Create backup subdirectory
    $BackupPath = Join-Path $Config.BackupDir $BackupID
    New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null

    # Backup files
    $Files = Get-ChildItem -Path $Config.BackupLocation -Recurse -Include $Config.IncludePatterns -Exclude $Config.ExcludePatterns

    foreach ($File in $Files) {
        $RelativePath = $File.FullName.Substring($Config.BackupLocation.Length + 1)
        $DestPath = Join-Path $BackupPath $RelativePath

        $DestDir = Split-Path $DestPath -Parent
        if (-not (Test-Path $DestDir)) {
            New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
        }

        Copy-Item -Path $File.FullName -Destination $DestPath -Force
    }

    # Create backup manifest
    $Manifest = @{
        BackupID = $BackupID
        Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Type = $Type
        Description = $Description
        Files = $Files.Count
        Location = $Config.BackupLocation
    }

    $ManifestPath = Join-Path $BackupPath "manifest.json"
    $Manifest | ConvertTo-Json -Depth 10 | Out-File -FilePath $ManifestPath -Encoding UTF8

    Write-Host "Backup complete!" -ForegroundColor Green
    Write-Host "Files backed up: $($Files.Count)"
    Write-Host "Location: $BackupPath"
    Write-Host "Manifest: $ManifestPath"
    Write-Host ""

    return $BackupID
}

# Restore function
function Invoke-SelfBackupRestore {
    param([string]$BackupID)

    Write-Host "=== Self-Backup Restore Started ===" -ForegroundColor Cyan
    Write-Host "Backup ID: $BackupID"
    Write-Host ""

    $BackupPath = Join-Path $Config.BackupDir $BackupID

    if (-not (Test-Path $BackupPath)) {
        Write-Host "ERROR: Backup not found: $BackupID" -ForegroundColor Red
        return $false
    }

    # Read manifest
    $ManifestPath = Join-Path $BackupPath "manifest.json"
    if (Test-Path $ManifestPath) {
        $Manifest = Get-Content $ManifestPath | ConvertFrom-Json
        Write-Host "Backup Info:" -ForegroundColor Yellow
        Write-Host "  Type: $($Manifest.Type)"
        Write-Host "  Description: $($Manifest.Description)"
        Write-Host "  Files: $($Manifest.Files)"
        Write-Host "  Time: $($Manifest.Timestamp)"
        Write-Host ""
    }

    # Restore files
    $Files = Get-ChildItem -Path $BackupPath -Recurse -File
    $Restored = 0
    $Errors = 0

    foreach ($File in $Files) {
        if ($File.Name -eq "manifest.json") { continue }

        $SourcePath = $File.FullName
        $DestPath = Join-Path $Config.BackupLocation $File.FullName.Substring($BackupPath.Length + 1)

        $DestDir = Split-Path $DestPath -Parent
        if (-not (Test-Path $DestDir)) {
            New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
        }

        try {
            Copy-Item -Path $SourcePath -Destination $DestPath -Force
            $Restored++
        }
        catch {
            $Errors++
            Write-Host "ERROR restoring: $File.Name" -ForegroundColor Red
        }
    }

    Write-Host "Restore complete!" -ForegroundColor Green
    Write-Host "Files restored: $Restored"
    Write-Host "Errors: $Errors"
    Write-Host "Location: $Config.BackupLocation"
    Write-Host ""

    return $true
}

# List backups function
function Get-SelfBackupList {
    Write-Host "=== Self-Backup List ===" -ForegroundColor Cyan
    Write-Host ""

    if (-not (Test-Path $Config.BackupDir)) {
        Write-Host "No backups found." -ForegroundColor Yellow
        return
    }

    $Backups = Get-ChildItem -Path $Config.BackupDir -Directory | Sort-Object LastWriteTime -Descending

    if ($Backups.Count -eq 0) {
        Write-Host "No backups found." -ForegroundColor Yellow
        return
    }

    foreach ($Backup in $Backups) {
        $ManifestPath = Join-Path $Backup.FullName "manifest.json"
        if (Test-Path $ManifestPath) {
            $Manifest = Get-Content $ManifestPath | ConvertFrom-Json
            $Age = (Get-Date) - $Backup.LastWriteTime
            $Days = [math]::Round($Age.TotalDays, 2)

            Write-Host "Backup ID: $($Manifest.BackupID)" -ForegroundColor White
            Write-Host "  Type: $($Manifest.Type)"
            Write-Host "  Description: $($Manifest.Description)"
            Write-Host "  Files: $($Manifest.Files)"
            Write-Host "  Time: $($Manifest.Timestamp)"
            Write-Host "  Age: $Days days ago"
            Write-Host "  Path: $($Backup.FullName)"
            Write-Host ""
        }
        else {
            Write-Host "Backup ID: $($Backup.Name)" -ForegroundColor White
            Write-Host "  Age: $(New-TimeSpan -Start $Backup.LastWriteTime -End (Get-Date)).Days days ago"
            Write-Host ""
        }
    }

    # Cleanup old backups
    if ($Backups.Count -gt $Config.MaxBackups) {
        $ToKeep = $Backups | Select-Object -First $Config.MaxBackups
        $ToDelete = $Backups | Where-Object { $ToKeep -notcontains $_ }

        Write-Host "=== Cleanup ===" -ForegroundColor Yellow
        Write-Host "Keeping last $Config.MaxBackups backups"
        Write-Host "Deleting $($ToDelete.Count) old backups" -ForegroundColor Red

        foreach ($Backup in $ToDelete) {
            Remove-Item -Path $Backup.FullName -Recurse -Force
            Write-Host "  Deleted: $($Backup.Name)" -ForegroundColor Gray
        }
        Write-Host ""
    }
}

# Validate function
function Invoke-SelfBackupValidate {
    Write-Host "=== Self-Backup Validation ===" -ForegroundColor Cyan
    Write-Host ""

    if (-not (Test-Path $Config.BackupDir)) {
        Write-Host "No backups found." -ForegroundColor Yellow
        return
    }

    $Backups = Get-ChildItem -Path $Config.BackupDir -Directory | Sort-Object LastWriteTime -Descending
    $Valid = 0
    $Invalid = 0
    $TotalFiles = 0

    foreach ($Backup in $Backups) {
        $ManifestPath = Join-Path $Backup.FullName "manifest.json"
        if (Test-Path $ManifestPath) {
            $Manifest = Get-Content $ManifestPath | ConvertFrom-Json
            $Files = Get-ChildItem -Path $Backup.FullName -Recurse -File

            if ($Manifest.Files -eq $Files.Count) {
                Write-Host "✓ Valid: $($Manifest.BackupID)" -ForegroundColor Green
                $Valid++
            }
            else {
                Write-Host "✗ Invalid: $($Manifest.BackupID)" -ForegroundColor Red
                Write-Host "  Expected: $($Manifest.Files) files" -ForegroundColor Red
                Write-Host "  Found: $($Files.Count) files" -ForegroundColor Red
                $Invalid++
            }
            $TotalFiles += $Files.Count
        }
        else {
            Write-Host "✗ Missing: $($Backup.Name)" -ForegroundColor Red
            $Invalid++
        }
    }

    Write-Host ""
    Write-Host "Validation Summary:" -ForegroundColor Cyan
    Write-Host "  Total Backups: $($Backups.Count)"
    Write-Host "  Valid: $Valid"
    Write-Host "  Invalid: $Invalid"
    Write-Host "  Total Files: $TotalFiles"
    Write-Host ""
}

# Main execution
if ($List) {
    Get-SelfBackupList
}
elseif ($Validate) {
    Invoke-SelfBackupValidate
}
elseif ($Restore -and $BackupID) {
    Invoke-SelfBackupRestore -BackupID $BackupID
}
elseif ($Restore) {
    Write-Host "ERROR: BackupID required for restore" -ForegroundColor Red
    exit 1
}
else {
    $BackupID = Invoke-SelfBackup -Description $Description
    Write-Host ""
    Write-Host "Backup ID: $BackupID" -ForegroundColor Green
    Write-Host ""
    Write-Host "Use this ID to restore: Self-Backup -Restore -BackupID '$BackupID'" -ForegroundColor Yellow
}

exit 0
