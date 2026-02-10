# Nightly Evolution Plan
# Automated self-optimization and repair system

# Load environment variables
if (Test-Path -Path ".env-loader.ps1") {
    . .env-loader.ps1
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$logFile = "logs/nightly-evolution.log"

# Get ports from environment variables or use defaults
$GATEWAY_PORT = if ($env:GATEWAY_PORT) { $env:GATEWAY_PORT } else { "18789" }
$CANVAS_PORT = if ($env:CANVAS_PORT) { $env:CANVAS_PORT } else { "18789" }
$HEARTBEAT_PORT = if ($env:HEARTBEAT_PORT) { $env:HEARTBEAT_PORT } else { "18789" }

# Create logs directory if it doesn't exist
if (!(Test-Path -Path "logs")) {
    New-Item -ItemType Directory -Path "logs" | Out-Null
}

function Log {
    param([string]$message)
    $logMessage = "[$timestamp] $message"
    Add-Content -Path $logFile -Value $logMessage
    Write-Host $logMessage
}

Log "Nightly Evolution Plan Started"
Log "Step 1: Check System Status"

$psVersion = $PSVersionTable.PSVersion
Log "PowerShell Version: $($psVersion.Major).$($psVersion.Minor)"

# Get disk usage using different method
$disk = Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue
if ($disk) {
    $diskPath = (Get-Location).Path
    $diskPath = $diskPath -replace '\\', ''
    $drive = $diskPath.Substring(0, 1)
    $disk = Get-PSDrive -Name $drive -PSProvider FileSystem -ErrorAction SilentlyContinue

    if ($disk) {
        $diskUsage = [math]::Round(($disk.Used / $disk.Free) * 100, 1)
        Log "Disk Usage: $diskUsage%"
    } else {
        Log "Disk Usage: Unknown"
    }
} else {
    Log "Disk Usage: Unknown"
}

Log "Step 2: Check GitHub Connection"

if (git remote -v | Select-String "github.com") {
    Log "GitHub remote repository configured"
    try {
        git fetch origin 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Log "GitHub connection OK"
        } else {
            Log "Warning: GitHub fetch failed"
        }
    } catch {
        Log "Warning: GitHub connection issue"
    }
} else {
    Log "Warning: GitHub not configured"
}

Log "Step 3: Check Local Backups"

$backupDir = "backup"
if (Test-Path -Path $backupDir) {
    $backupFiles = Get-ChildItem -Path $backupDir -Filter "*.zip" -ErrorAction SilentlyContinue
    $backupCount = $backupFiles.Count
    Log "Backup files: $backupCount"

    if ($backupCount -gt 7) {
        Log "Warning: Too many backups, cleaning..."
        $backupFiles | Sort-Object LastWriteTime -Descending | Select-Object -Skip 7 | Remove-Item -Force
        Log "Cleaned old backups"
    } else {
        Log "Backup files OK"
    }
} else {
    Log "Warning: Backup directory not found"
}

Log "Step 4: Check Skills"

$skillFiles = Get-ChildItem -Path "skills" -Filter "SKILL.md" -ErrorAction SilentlyContinue
$skillsCount = $skillFiles.Count
Log "Installed skills: $skillsCount"

if ($skillsCount -gt 0) {
    Log "Skills system OK"
} else {
    Log "Warning: No skills found"
}

Log "Step 5: Performance Check"

$memory = Get-CimInstance Win32_OperatingSystem
$memoryUsage = [math]::Round(($memory.UsedSpace / $memory.TotalVisibleMemorySize) * 100, 1)
Log "Memory Usage: $memoryUsage%"

if ($memoryUsage -lt 80) {
    Log "Memory usage OK"
} else {
    Log "Warning: High memory usage"
}

Log "Nightly Evolution Plan Completed"

Write-Host "Nightly Evolution Plan Completed!" -ForegroundColor Green
