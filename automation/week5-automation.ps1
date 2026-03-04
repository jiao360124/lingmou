# Week 5 Complete Automation Script
# Automates the entire Week 5 implementation

param(
    [switch]$SkipTaskScheduler,
    [switch]$SkipStartup,
    [switch]$SkipOpenClaw3,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

# Project paths
$projectRoot = "C:\Users\Administrator\.openclaw\workspace"
$schedulerScript = Join-Path $projectRoot "automation\week5-task-scheduler.ps1"
$startupScript = Join-Path $projectRoot "automation\week5-startup-script.ps1"
$openclawScript = Join-Path $projectRoot "automation\openclaw-3.0-startup.ps1"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage -ForegroundColor Cyan
    Add-Content -Path "$projectRoot\automation\week5-automation.log" -Value $logMessage
}

function Write-Step {
    param([string]$Step)
    Write-Host ""
    Write-Host "═" * 60 -ForegroundColor Yellow
    Write-Host "  $Step" -ForegroundColor Yellow
    Write-Host "═" * 60 -ForegroundColor Yellow
}

try {
    Write-Log "=== Week 5 Complete Automation ==="
    Write-Log "Starting automation at $(Get-Date)"

    # Step 1: Windows Task Scheduler Setup
    if (-not $SkipTaskScheduler) {
        Write-Step "Step 1: Setting up Windows Task Scheduler"

        Write-Log "Creating scheduled tasks..."
        & $schedulerScript -Action create -Verbose:$Verbose

        Write-Log "Testing scheduled tasks..."
        & $schedulerScript -Action test -Verbose:$Verbose

        Write-Log "✓ Step 1 Complete: Windows Task Scheduler configured"
    } else {
        Write-Log "⏭️  Step 1 Skipped: Windows Task Scheduler"
    }

    # Step 2: Start Monitoring Systems
    if (-not $SkipStartup) {
        Write-Step "Step 2: Starting Monitoring Systems"

        Write-Log "Starting all Week 5 monitoring systems..."
        & $startupScript -Action start -Verbose:$Verbose

        Write-Log "Checking system status..."
        & $startupScript -Action status -Verbose:$Verbose

        Write-Log "✓ Step 2 Complete: Monitoring systems started"
    } else {
        Write-Log "⏭️  Step 2 Skipped: Monitoring Systems"
    }

    # Step 3: Start OpenClaw 3.0
    if (-not $SkipOpenClaw3) {
        Write-Step "Step 3: Starting OpenClaw 3.0"

        Write-Log "Starting OpenClaw 3.0..."
        $openclawSuccess = & $openclawScript -Action start -Verbose:$Verbose

        Write-Log "Checking OpenClaw 3.0 status..."
        & $openclawScript -Action status -Verbose:$Verbose

        if ($openclawSuccess) {
            Write-Log "✓ Step 3 Complete: OpenClaw 3.0 started"
        } else {
            Write-Log "⚠️  Step 3 Incomplete: OpenClaw 3.0 failed to start"
        }
    } else {
        Write-Log "⏭️  Step 3 Skipped: OpenClaw 3.0"
    }

    # Summary
    Write-Step "Automation Complete"

    Write-Log ""
    Write-Log "=== Summary ===" -ForegroundColor Green
    Write-Log "Week 5 Complete Automation executed at $(Get-Date)"
    Write-Log ""
    Write-Log "What was done:"
    if (-not $SkipTaskScheduler) {
        Write-Log "  ✓ Windows Task Scheduler configured (5 scheduled tasks)"
    }
    if (-not $SkipStartup) {
        Write-Log "  ✓ All monitoring systems started (6 systems)"
    }
    if (-not $SkipOpenClaw3) {
        Write-Log "  ✓ OpenClaw 3.0 started (if successful)"
    }
    Write-Log ""
    Write-Log "Next steps:"
    Write-Log "  1. Monitor logs for any errors"
    Write-Log "  2. Check scheduled tasks are running"
    Write-Log "  3. Verify monitoring dashboard is accessible"
    Write-Log "  4. Test Moltbook heartbeat monitor"
    Write-Log ""
    Write-Log "Log files:"
    Write-Log "  - $projectRoot\automation\week5-scheduler-setup.log"
    Write-Log "  - $projectRoot\automation\week5-startup.log"
    Write-Log "  - $projectRoot\automation\openclaw-3.0.log"
    Write-Log "  - $projectRoot\automation\week5-automation.log"
    Write-Log ""

    Write-Host "🎉 Week 5 Complete Automation Complete!" -ForegroundColor Green

} catch {
    Write-Log "ERROR: $_" -ForegroundColor Red
    Write-Log $_.ScriptStackTrace
    Write-Log ""
    Write-Host "❌ Automation Failed" -ForegroundColor Red
    exit 1
}
