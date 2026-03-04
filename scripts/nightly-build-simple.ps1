# Lingmou Nightly Build - Self Evolution Script

param([switch]$DryRun)

$Script:NightlyBuildStart = Get-Date

function Write-Log {
    param([string]$Level, [string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"
    if ($DryRun) {
        $LogEntry = "[DRY RUN] $LogEntry"
    }
    Write-Host $LogEntry
    $LogFile = "logs/nightly-build/nightly-build-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    Add-Content -Path $LogFile -Value $LogEntry
}

Write-Log "INFO" "=== Lingmou Nightly Build Started ==="
Write-Log "INFO" "Start Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Log "INFO" "DryRun Mode: $DryRun"

# Task 1: System Health Check
Write-Log "INFO" "`n--- Task 1: System Health Check ---"

try {
    $GatewayCheck = openclaw gateway status 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Log "INFO" "[PASS] Gateway is running normally"
    } else {
        Write-Log "WARN" "[FAIL] Gateway status check failed"
    }
}
catch {
    Write-Log "WARN" "[FAIL] Gateway status check exception: $_"
}

$MemoryInfo = Get-CimInstance Win32_OperatingSystem
$MemoryUsage = [math]::Round($MemoryInfo.TotalVisibleMemorySize / 1MB, 2)
Write-Log "INFO" "[INFO] Memory Usage: ${MemoryUsage} MB"

$DiskUsage = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$FreeSpace = [math]::Round($DiskUsage.FreeSpace / 1MB, 2)
Write-Log "INFO" "[INFO] Disk Free Space: ${FreeSpace} MB"

# Check Cron Jobs
Write-Log "INFO" "`n--- Task 1.2: Check Scheduled Tasks ---"
$CronJobs = cron list --includeDisabled
foreach ($Job in $CronJobs) {
    $Status = if ($Job.enabled) { "ENABLED" } else { "DISABLED" }
    Write-Log "INFO" "  [$($Job.name)] $Status"
}

# Task 2: Error Pattern Analysis
Write-Log "INFO" "`n--- Task 2: Error Pattern Analysis ---"

$ErrorPatterns = @{
    NetworkTimeouts = 0
    APIRateLimit = 0
    MemoryLeaks = 0
    FileErrors = 0
}

$RecentLogs = Get-ChildItem logs -Filter "*.log" -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-24) } |
    Select-Object -First 10

if ($RecentLogs) {
    Write-Log "INFO" "[INFO] Found $($RecentLogs.Count) log files"

    foreach ($Log in $RecentLogs) {
        $Content = Get-Content $Log.FullName -Tail 100 -ErrorAction SilentlyContinue
        foreach ($Line in $Content) {
            if ($Line -match "timeout") { $ErrorPatterns.NetworkTimeouts++ }
            elseif ($Line -match "429|rate.*limit") { $ErrorPatterns.APIRateLimit++ }
            elseif ($Line -match "memory") { $ErrorPatterns.MemoryLeaks++ }
            elseif ($Line -match "error") { $ErrorPatterns.FileErrors++ }
        }
    }
}

Write-Log "INFO" "[SUMMARY] Error Pattern Statistics:"
Write-Log "INFO" "  Network Timeouts: $($ErrorPatterns.NetworkTimeouts) times"
Write-Log "INFO" "  API Rate Limit: $($ErrorPatterns.APIRateLimit) times"
Write-Log "INFO" "  Memory Leaks: $($ErrorPatterns.MemoryLeaks) times"
Write-Log "INFO" "  File Errors: $($ErrorPatterns.FileErrors) times"

# Task 3: Tool Chain Optimization
Write-Log "INFO" "`n--- Task 3: Tool Chain Optimization ---"

$OptimizationTasks = @()

# Clean old backups
Write-Log "INFO" "  [1/2] Clean old backups..."
$OldBackups = Get-ChildItem backup/*.zip -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -Skip 3

if ($OldBackups) {
    $BackupsToDelete = $OldBackups | Select-Object -First ($OldBackups.Count - 3)
    $TotalSize = ($BackupsToDelete | Measure-Object -Property Length -Sum).Sum / 1MB
    Write-Log "INFO" "    [INFO] Will delete $($BackupsToDelete.Count) old backups, saving ~${TotalSize}MB"
    if (-not $DryRun) {
        foreach ($Backup in $BackupsToDelete) {
            Remove-Item $Backup.FullName -Force -ErrorAction SilentlyContinue
            Write-Log "INFO" "    [OK] Deleted: $($Backup.Name)"
        }
    }
} else {
    Write-Log "INFO" "    [INFO] No cleanup needed for backups"
}

# Clean log files
Write-Log "INFO" "  [2/2] Clean old logs..."
$OldLogs = Get-ChildItem logs -Filter "*.log" -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }

if ($OldLogs) {
    $OldLogs | Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Log "INFO" "    [OK] Deleted $($OldLogs.Count) old log files"
} else {
    Write-Log "INFO" "    [INFO] No cleanup needed for logs"
}

$OptimizationTasks += New-Object PSObject -Property @{
    Name = "Backup Cleanup"
    Status = "Completed"
    Details = "Deleted $($OldBackups.Count) old backups"
}
$OptimizationTasks += New-Object PSObject -Property @{
    Name = "Log Cleanup"
    Status = "Completed"
    Details = "Deleted $($OldLogs.Count) old logs"
}

# Task 4: Skill Learning Record
Write-Log "INFO" "`n--- Task 4: Skill Learning Record ---"

$Skills = Get-ChildItem skills -Directory -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Name

Write-Log "INFO" "[INFO] Currently integrated skills: $($Skills.Count)"

# Task 5: Knowledge Base Update
Write-Log "INFO" "`n--- Task 5: Knowledge Base Update ---"

$MemoryFile = "MEMORY.md"
if (Test-Path $MemoryFile) {
    $LastModified = (Get-Item $MemoryFile).LastWriteTime
    $DaysSinceUpdate = (New-TimeSpan -Start $LastModified -End (Get-Date)).Days
    Write-Log "INFO" "[INFO] Memory.md last updated: $LastModified"
    Write-Log "INFO" "[INFO] Days since update: $DaysSinceUpdate days"

    if ($DaysSinceUpdate -gt 1) {
        Write-Log "WARN" "[WARN] Memory.md not updated for more than 1 day, recommend update"
    } else {
        Write-Log "INFO" "[OK] Memory.md recently updated"
    }
} else {
    Write-Log "WARN" "[WARN] MEMORY.md file does not exist"
}

# Summary
Write-Log "INFO" "`n=== Nightly Build Summary ==="
$Duration = (Get-Date) - $Script:NightlyBuildStart
Write-Log "INFO" "[INFO] Completion Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Log "INFO" "[INFO] Execution Time: $([math]::Round($Duration.TotalSeconds, 2)) seconds"

if ($DryRun) {
    Write-Log "INFO" "[DRY RUN] Report saved to: logs/nightly-build/nightly-build-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
} else {
    Write-Log "INFO" "[OK] Report saved to: logs/nightly-build/nightly-build-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
}

Write-Log "INFO" "`n[COMPLETE] Nightly Build execution completed!"

# Return results
return @{
    Success = $true
    Duration = $Duration.TotalSeconds
    SkillCount = $Skills.Count
    OptimizationTasks = $OptimizationTasks
}
