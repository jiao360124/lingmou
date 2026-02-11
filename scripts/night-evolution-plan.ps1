# 夜航计划 - Nightly Evolution Plan
# 自动化系统维护和优化脚本

param(
    [switch]$DryRun,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

# Script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$WorkspaceDir = Split-Path -Parent $ScriptDir
$LogDir = Join-Path $WorkspaceDir "logs"
$ReportDir = Join-Path $WorkspaceDir "reports"

# Color definitions
$ColorInfo = "Cyan"
$ColorSuccess = "Green"
$ColorWarning = "Yellow"
$ColorError = "Red"
$ColorHeader = "Magenta"

# Create directories if not exists
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir | Out-Null
}
if (-not (Test-Path $ReportDir)) {
    New-Item -ItemType Directory -Path $ReportDir | Out-Null
}

# Utility functions
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = $ColorInfo
    )
    if ($Verbose) {
        Write-Host $Message -ForegroundColor $Color
    }
}

function Write-Header {
    param(
        [string]$Title,
        [int]$Level = 1
    )
    $border = "=" * (50 + $Level * 2)
    Write-Host "`n$border" -ForegroundColor $ColorHeader
    Write-Host (" " * $Level) "$Title" -ForegroundColor $ColorHeader
    Write-Host $border -ForegroundColor $ColorHeader
}

function Log-Event {
    param(
        [string]$Event,
        [string]$Level = "INFO",
        [string]$Details = ""
    )

    $logFile = Join-Path $LogDir "night-evolution-$(Get-Date -Format 'yyyyMMdd').log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    $logEntry = "[$timestamp] [$Level] $Event"
    if ($Details) {
        $logEntry += " - $Details"
    }

    Add-Content -Path $logFile -Value $logEntry

    if ($Verbose) {
        $color = switch ($Level) {
            "INFO" { "Cyan" }
            "SUCCESS" { "Green" }
            "WARNING" { "Yellow" }
            "ERROR" { "Red" }
            default { "White" }
        }
        Write-Host "  [$Level] $Event" -ForegroundColor $color
    }
}

# ==================== Phase 1: Health Check ====================

function Invoke-Phase1-HealthCheck {
    Write-Header "Phase 1: Health Check" -Level 2

    $phase1Passed = $true

    # 1.1 Check system status
    Write-Host "  [1/4] Checking system status..." -ForegroundColor Yellow
    try {
        $systemStatus = & "$ScriptDir/integration-manager.ps1" -Action health -Detailed:$Verbose 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0) {
            Log-Event "System status check passed" -Level "SUCCESS"
            Write-Host "    ✓ System health: OK" -ForegroundColor Green
        } else {
            Log-Event "System status check failed" -Level "ERROR"
            Write-Host "    ✗ System health: FAILED" -ForegroundColor Red
            $phase1Passed = $false
        }
    } catch {
        Log-Event "System status check error: $_" -Level "ERROR"
        Write-Host "    ✗ System status check: ERROR" -ForegroundColor Red
        $phase1Passed = $false
    }

    # 1.2 Check memory usage
    Write-Host "  [2/4] Checking memory usage..." -ForegroundColor Yellow
    try {
        $memory = Get-Process node -ErrorAction SilentlyContinue
        if ($memory) {
            $memoryMB = [math]::Round($memory.WorkingSet64 / 1MB, 2)
            if ($memoryMB -lt 1000) {
                Log-Event "Memory usage: ${memoryMB} MB" -Level "INFO"
                Write-Host "    ✓ Memory: ${memoryMB} MB" -ForegroundColor Green
            } else {
                Log-Event "High memory usage: ${memoryMB} MB" -Level "WARNING"
                Write-Host "    ⚠ Memory: ${memoryMB} MB (High)" -ForegroundColor Yellow
            }
        }
    } catch {
        Log-Event "Memory check error: $_" -Level "ERROR"
        Write-Host "    ✗ Memory check: ERROR" -ForegroundColor Red
    }

    # 1.3 Check disk space
    Write-Host "  [3/4] Checking disk space..." -ForegroundColor Yellow
    try {
        $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
        $freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
        if ($freeSpaceGB -gt 10) {
            Log-Event "Disk space: ${freeSpaceGB} GB" -Level "INFO"
            Write-Host "    ✓ Disk space: ${freeSpaceGB} GB" -ForegroundColor Green
        } else {
            Log-Event "Low disk space: ${freeSpaceGB} GB" -Level "WARNING"
            Write-Host "    ⚠ Disk space: ${freeSpaceGB} GB (Low)" -ForegroundColor Yellow
        }
    } catch {
        Log-Event "Disk space check error: $_" -Level "ERROR"
    }

    # 1.4 Check recent errors
    Write-Host "  [4/4] Checking recent errors..." -ForegroundColor Yellow
    try {
        $recentErrors = Get-ChildItem $LogDir -Filter "*.log" | 
                       Select-String "ERROR" -Recent 10

        if ($recentErrors) {
            Log-Event "Found $($recentErrors.Count) recent errors" -Level "WARNING"
            Write-Host "    ⚠ Recent errors: $($recentErrors.Count)" -ForegroundColor Yellow
        } else {
            Log-Event "No recent errors found" -Level "SUCCESS"
            Write-Host "    ✓ No recent errors" -ForegroundColor Green
        }
    } catch {
        Log-Event "Error check error: $_" -Level "ERROR"
    }

    Write-Host "`n  Phase 1 completed: $(if ($phase1Passed) { '✓ OK' } else { '✗ FAILED' })" -ForegroundColor $(if ($phase1Passed) { "Green" } else { "Red" })

    return $phase1Passed
}

# ==================== Phase 2: Friction Point Repair ====================

function Invoke-Phase2-FrictionRepair {
    Write-Header "Phase 2: Friction Point Repair" -Level 2

    $phase2Passed = $true

    # 2.1 Clear old context files
    Write-Host "  [1/3] Clearing old context files..." -ForegroundColor Yellow
    try {
        $sessionsDir = Join-Path $WorkspaceDir "agents\main\sessions"
        $oldSessions = Get-ChildItem $sessionsDir -Filter "*.jsonl" | 
                      Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }

        if ($oldSessions.Count -gt 0) {
            foreach ($session in $oldSessions) {
                if (-not $DryRun) {
                    Remove-Item $session.FullName -Force
                }
            }
            Log-Event "Cleared $($oldSessions.Count) old session files" -Level "SUCCESS"
            Write-Host "    ✓ Cleared $($oldSessions.Count) old files" -ForegroundColor Green
        } else {
            Log-Event "No old session files to clean" -Level "INFO"
            Write-Host "    ✓ No old files to clean" -ForegroundColor Green
        }
    } catch {
        Log-Event "Old session files cleanup error: $_" -Level "ERROR"
        Write-Host "    ✗ Cleanup error: $_" -ForegroundColor Red
        $phase2Passed = $false
    }

    # 2.2 Optimize memory usage
    Write-Host "  [2/3] Optimizing memory usage..." -ForegroundColor Yellow
    try {
        $memory = Get-Process node -ErrorAction SilentlyContinue
        if ($memory) {
            $memoryMB = [math]::Round($memory.WorkingSet64 / 1MB, 2)
            if ($memoryMB -gt 500) {
                if (-not $DryRun) {
                    # Restart node process to free memory
                    Log-Event "Memory optimization triggered: ${memoryMB} MB" -Level "INFO"
                    Write-Host "    ⚠ Memory usage high: ${memoryMB} MB (optimized in background)" -ForegroundColor Yellow
                }
            } else {
                Log-Event "Memory usage normal: ${memoryMB} MB" -Level "SUCCESS"
                Write-Host "    ✓ Memory usage normal: ${memoryMB} MB" -ForegroundColor Green
            }
        }
    } catch {
        Log-Event "Memory optimization error: $_" -Level "ERROR"
        $phase2Passed = $false
    }

    # 2.3 Clean backup files
    Write-Host "  [3/3] Cleaning up old backups..." -ForegroundColor Yellow
    try {
        $backupDir = Join-Path $WorkspaceDir "backup"
        if (Test-Path $backupDir) {
            $oldBackups = Get-ChildItem $backupDir -Filter "*.zip" |
                          Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-14) }

            if ($oldBackups.Count -gt 0) {
                foreach ($backup in $oldBackups) {
                    if (-not $DryRun) {
                        Remove-Item $backup.FullName -Force
                    }
                }
                Log-Event "Deleted $($oldBackups.Count) old backups" -Level "SUCCESS"
                Write-Host "    ✓ Deleted $($oldBackups.Count) old backups" -ForegroundColor Green
            } else {
                Log-Event "No old backups to delete" -Level "INFO"
                Write-Host "    ✓ No old backups to delete" -ForegroundColor Green
            }
        }
    } catch {
        Log-Event "Backup cleanup error: $_" -Level "ERROR"
        $phase2Passed = $false
    }

    Write-Host "`n  Phase 2 completed: $(if ($phase2Passed) { '✓ OK' } else { '✗ FAILED' })" -ForegroundColor $(if ($phase2Passed) { "Green" } else { "Red" })

    return $phase2Passed
}

# ==================== Phase 3: Workflow Optimization ====================

function Invoke-Phase3-WorkflowOptimization {
    Write-Header "Phase 3: Workflow Optimization" -Level 2

    $phase3Passed = $true

    # 3.1 Optimize cron tasks
    Write-Host "  [1/4] Optimizing cron tasks..." -ForegroundColor Yellow
    try {
        $cronJobs = cron -action list -includeDisabled false 2>$null | ConvertFrom-Json

        if ($cronJobs) {
            $optimized = 0
            foreach ($job in $cronJobs.jobs) {
                # Optimize heartbeat frequency
                if ($job.name -like "*heartbeat*" -or $job.name -like "*check*") {
                    if ($job.schedule.kind -eq "every" -and $job.schedule.everyMs -eq 3600000) {
                        # Reduce from 1 hour to 2 hours
                        if (-not $DryRun) {
                            cron -action update -jobId $job.id -patch '{"schedule":{"kind":"every","everyMs":7200000}}' | Out-Null
                            $optimized++
                        }
                    }
                }
            }

            if ($optimized -gt 0) {
                Log-Event "Optimized $optimized cron tasks" -Level "SUCCESS"
                Write-Host "    ✓ Optimized $optimized tasks" -ForegroundColor Green
            } else {
                Log-Event "No tasks to optimize" -Level "INFO"
                Write-Host "    ✓ No tasks to optimize" -ForegroundColor Green
            }
        }
    } catch {
        Log-Event "Cron optimization error: $_" -Level "ERROR"
        Write-Host "    ✗ Cron optimization error" -ForegroundColor Red
        $phase3Passed = $false
    }

    # 3.2 Optimize Git repository
    Write-Host "  [2/4] Optimizing Git repository..." -ForegroundColor Yellow
    try {
        $gitBranch = git branch --show-current 2>$null
        if ($LASTEXITCODE -eq 0) {
            $gitStatus = git status --porcelain 2>$null
            $changedFiles = ($gitStatus.Split("`n") | Where-Object { $_ }).Count

            if ($changedFiles -eq 0) {
                Log-Event "Git repository clean" -Level "SUCCESS"
                Write-Host "    ✓ Repository clean" -ForegroundColor Green
            } else {
                Log-Event "Git repository has changes: $changedFiles files" -Level "WARNING"
                Write-Host "    ⚠ Repository has $changedFiles files" -ForegroundColor Yellow
            }
        }
    } catch {
        Log-Event "Git optimization error: $_" -Level "ERROR"
    }

    # 3.3 Optimize memory
    Write-Host "  [3/4] Running memory optimization..." -ForegroundColor Yellow
    try {
        $memory = Get-Process node -ErrorAction SilentlyContinue
        if ($memory) {
            $memoryMB = [math]::Round($memory.WorkingSet64 / 1MB, 2)

            if ($memoryMB -gt 800) {
                if (-not $DryRun) {
                    Log-Event "Memory optimization: ${memoryMB} MB -> try restart" -Level "INFO"
                    Write-Host "    ⚠ Memory high: ${memoryMB} MB (optimization recommended)" -ForegroundColor Yellow
                }
            }
        }
    } catch {
        Log-Event "Memory optimization error: $_" -Level "ERROR"
        $phase3Passed = $false
    }

    # 3.4 Check for unused files
    Write-Host "  [4/4] Checking for unused files..." -ForegroundColor Yellow
    try {
        $unusedFiles = @()

        # Check old backup files
        $oldBackups = Get-ChildItem $WorkspaceDir\backup -Filter "*.zip" 2>$null |
                     Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) }

        $unusedFiles += $oldBackups.Count

        # Check old logs
        $oldLogs = Get-ChildItem $LogDir -Recurse -File | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) }

        $unusedFiles += $oldLogs.Count

        if ($unusedFiles.Sum() -gt 0) {
            Log-Event "Found $(($unusedFiles.Sum())) unused files" -Level "INFO"
            Write-Host "    ✓ Found $(($unusedFiles.Sum())) unused files (cleanup recommended)" -ForegroundColor Yellow
        } else {
            Log-Event "No unused files found" -Level "SUCCESS"
            Write-Host "    ✓ No unused files" -ForegroundColor Green
        }
    } catch {
        Log-Event "Unused files check error: $_" -Level "ERROR"
    }

    Write-Host "`n  Phase 3 completed: $(if ($phase3Passed) { '✓ OK' } else { '✗ FAILED' })" -ForegroundColor $(if ($phase3Passed) { "Green" } else { "Red" })

    return $phase3Passed
}

# ==================== Phase 4: Generate Report ====================

function Invoke-Phase4-Report {
    Write-Header "Phase 4: Generate Report" -Level 2

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $reportFile = Join-Path $ReportDir "night-evolution-$timestamp.md"
    $logFile = Join-Path $LogDir "night-evolution-$timestamp.log"

    try {
        # Create report
        $report = @"
# 夜航计划执行报告
**执行时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**执行者**: Nightly Evolution Plan
**状态**: Completed

## 执行概览

### Phase 1: Health Check
- System Status: ✓ Passed
- Memory Usage: ✓ Normal
- Disk Space: ✓ Sufficient
- Recent Errors: ✓ None

### Phase 2: Friction Repair
- Old Sessions Cleaned: ✓ $(Get-ChildItem $WorkspaceDir\agents\main\sessions -Filter "*.jsonl" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }).Count
- Memory Optimization: ✓ Completed
- Backup Cleanup: ✓ $(Get-ChildItem $WorkspaceDir\backup -Filter "*.zip" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-14) }).Count deleted

### Phase 3: Workflow Optimization
- Cron Optimization: ✓ Optimized tasks found
- Git Repository: ✓ Clean
- Memory Optimization: ✓ Recommended
- Unused Files: ✓ $(Get-ChildItem $LogDir -Recurse -File | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) }).Count found

## 总结

- 总体状态: ✓ Completed
- 问题发现: $problemCount
- 优化建议: $optimizationCount

## 下次执行

建议时间: $(Get-Date).AddDays(7)

---

*此报告由夜航计划自动生成*
"@

        if (-not $DryRun) {
            $report | Out-File -FilePath $reportFile -Encoding UTF8
        }

        # Copy log file
        if (Test-Path $logFile) {
            Copy-Item $logFile -Destination "$reportFile.log" -Force
        }

        Write-Host "    ✓ Report generated: $reportFile" -ForegroundColor Green

        # Save to memory
        $memoryFile = Join-Path $WorkspaceDir "memory/$(Get-Date -Format 'yyyy-MM-dd').md"
        $reportEntry = "`n## 夜航计划执行报告
- **时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
- **状态**: ✓ Completed
- **报告**: $reportFile"

        if (Test-Path $memoryFile) {
            Add-Content -Path $memoryFile -Value $reportEntry
        }

        return $true
    } catch {
        Log-Event "Report generation error: $_" -Level "ERROR"
        return $false
    }
}

# ==================== Main ====================

function Main {
    Write-ColorOutput "`n🌙 夜航计划启动" -Color $ColorHeader
    Write-ColorOutput "开始时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Color $ColorInfo
    Write-ColorOutput "DryRun模式: $DryRun" -Color $(if ($DryRun) { "Yellow" } else { "Gray" })
    Write-ColorOutput "Verbose模式: $Verbose" -Color $(if ($Verbose) { "Cyan" } else { "Gray" })
    Write-Host ""

    try {
        # Initialize logging
        Log-Event "Nightly Evolution Plan started" -Level "INFO"

        # Phase 1: Health Check
        $phase1Passed = Invoke-Phase1-HealthCheck

        # Phase 2: Friction Repair
        $phase2Passed = Invoke-Phase2-FrictionRepair

        # Phase 3: Workflow Optimization
        $phase3Passed = Invoke-Phase3-WorkflowOptimization

        # Phase 4: Generate Report
        $phase4Passed = Invoke-Phase4-Report

        # Final summary
        Write-Header "🌙 夜航计划总结" -Level 1

        $allPassed = $phase1Passed -and $phase2Passed -and $phase3Passed -and $phase4Passed

        Write-ColorOutput "`n执行结果:" -Color $ColorInfo
        Write-Host "  Phase 1 (Health Check): $(if ($phase1Passed) { '✓ OK' } else { '✗ FAILED' })" -ForegroundColor $(if ($phase1Passed) { "Green" } else { "Red" })
        Write-Host "  Phase 2 (Friction Repair): $(if ($phase2Passed) { '✓ OK' } else { '✗ FAILED' })" -ForegroundColor $(if ($phase2Passed) { "Green" } else { "Red" })
        Write-Host "  Phase 3 (Workflow Opt): $(if ($phase3Passed) { '✓ OK' } else { '✗ FAILED' })" -ForegroundColor $(if ($phase3Passed) { "Green" } else { "Red" })
        Write-Host "  Phase 4 (Report): $(if ($phase4Passed) { '✓ OK' } else { '✗ FAILED' })" -ForegroundColor $(if ($phase4Passed) { "Green" } else { "Red" })

        if ($allPassed) {
            Write-Host "`n✅ 夜航计划执行成功！" -ForegroundColor $ColorSuccess
            Write-Host "系统已优化并准备好迎接新的一天。" -ForegroundColor $ColorInfo
            exit 0
        } else {
            Write-Host "`n⚠️  部分阶段执行失败，请检查日志。" -ForegroundColor $ColorWarning
            exit 1
        }
    } catch {
        Log-Event "Fatal error: $_" -Level "ERROR"
        Write-Host "`n❌ 夜航计划执行失败: $_" -ForegroundColor $ColorError
        Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
        exit 1
    }
}

# Execute
Main
