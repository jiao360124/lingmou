# Week 5 - Start All Monitoring Systems
# Launches all Week 5 evolution systems

param(
    [string]$Action = "start",  # start, status, stop
    [bool]$Verbose = $true
)

$ErrorActionPreference = "Stop"

# Project paths
$projectRoot = "C:\Users\Administrator\.openclaw\workspace"
$scriptsPath = Join-Path $projectRoot "scripts\evolution"

# System definitions
$systems = @(
    @{
        Name = "Heartbeat Monitor"
        ScriptPath = Join-Path $scriptsPath "heartbeat-monitor.ps1"
        Description = "Monitors Moltbook/network/API health every 30 minutes"
        Background = $true
    },
    @{
        Name = "Rate Limiter"
        ScriptPath = Join-Path $scriptsPath "rate-limiter.ps1"
        Description = "Manages API rate limits and throttling"
        Background = $true
    },
    @{
        Name = "Graceful Degradation"
        ScriptPath = Join-Path $scriptsPath "graceful-degradation.ps1"
        Description = "Automatic state recovery and error handling"
        Background = $true
    },
    @{
        Name = "Monitoring Dashboard"
        ScriptPath = Join-Path $scriptsPath "monitoring-dashboard.ps1"
        Description = "Real-time visualization of system metrics"
        Background = $false  # Interactive
    },
    @{
        Name = "Nightly Plan"
        ScriptPath = Join-Path $scriptsPath "nightly-plan.ps1"
        Description = "Automatic friction point fixes (3-6 AM daily)"
        Background = $true
    },
    @{
        Name = "Launchpad Engine"
        ScriptPath = Join-Path $scriptsPath "launchpad-engine.ps1"
        Description = "6-phase improvement cycle (3-6 AM daily)"
        Background = $true
    }
)

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage
    if ($Verbose) {
        Add-Content -Path "automation/week5-startup.log" -Value $logMessage
    }
}

function Start-System {
    param([hashtable]$System)
    Write-Log "Starting: $($System.Name)"
    Write-Log "  Script: $($System.ScriptPath)"

    try {
        # Run script
        if ($System.Background) {
            # Background execution using Start-Job
            Write-Log "  Starting in background..."
            Start-Job -ScriptBlock {
                param($ScriptPath, $Verbose)
                & $ScriptPath -Action start -Verbose:$Verbose
            } -ArgumentList $System.ScriptPath, $Verbose | Out-Null
            Write-Log "  ✓ Started in background"
        } else {
            # Interactive execution
            & $System.ScriptPath -Action start -Verbose
            Write-Log "  ✓ Started interactively"
        }

    } catch {
        Write-Log "  ✗ Failed: $_"
        return $false
    }

    return $true
}

function Get-SystemStatus {
    param([hashtable]$System)
    $pidFile = Join-Path $projectRoot "automation\pids\$($System.Name).pid"

    if (Test-Path $pidFile) {
        $pid = Get-Content $pidFile
        $process = Get-Process -Id $pid -ErrorAction SilentlyContinue

        if ($process) {
            $cpu = [math]::Round($process.CPU, 2)
            $memory = [math]::Round($process.WorkingSet64 / 1MB, 2)
            return @{
                Running = $true
                PID = $pid
                CPU = $cpu
                Memory = $memory
            }
        }
    }

    return @{
        Running = $false
    }
}

function Show-Status {
    Write-Log "=== Week 5 Systems Status ==="
    Write-Log ""

    $running = 0
    $stopped = 0

    foreach ($system in $systems) {
        Write-Log "$($system.Name):"

        $status = Get-SystemStatus -System $system

        if ($status.Running) {
            Write-Log "  🟢 Running (PID: $($status.PID)) - CPU: $($status.CPU)%, Memory: $($status.Memory)MB"
            $running++
        } else {
            Write-Log "  ⚪ Stopped"
            $stopped++
        }
    }

    Write-Log ""
    Write-Log "Summary: $running running, $stopped stopped"
    Write-Log ""

    if ($running -eq $systems.Count) {
        Write-Log "✅ All systems running successfully!"
    } elseif ($running -gt 0) {
        Write-Log "⚠️  Some systems are running"
    } else {
        Write-Log "❌ No systems are running"
    }
}

function Stop-Systems {
    Write-Log "=== Stopping All Systems ==="

    foreach ($system in $systems) {
        $pidFile = Join-Path $projectRoot "automation\pids\$($System.Name).pid"

        if (Test-Path $pidFile) {
            $pid = Get-Content $pidFile | Select-Object -First 1
            Write-Log "Stopping $($System.Name) (PID: $pid)..."

            try {
                $process = Get-Process -Id $pid -ErrorAction Stop
                $process.Kill()
                Remove-Item $pidFile -Force
                Write-Log "  ✓ Stopped"
            } catch {
                Write-Log "  ⚠ Could not stop (not found or already stopped)"
            }
        }
    }

    Write-Log "=== Stopped Complete ==="
}

try {
    # Create PIDs directory if not exists
    $pidsDir = Join-Path $projectRoot "automation\pids"
    if (-not (Test-Path $pidsDir)) {
        New-Item -Path $pidsDir -ItemType Directory -Force | Out-Null
    }

    if ($Action -eq "start") {
        Write-Log "=== Week 5 Systems Startup ==="
        Write-Log "Starting $($systems.Count) systems..."

        $successCount = 0

        foreach ($system in $systems) {
            if (Start-System -System $system) {
                $successCount++
                Start-Sleep -Milliseconds 500  # Small delay between starts
            }
        }

        Write-Log ""
        Write-Log "=== Startup Complete ==="
        Write-Log "Started $successCount / $($systems.Count) systems"

        # Show status
        Start-Sleep -Seconds 2
        Show-Status

    } elseif ($Action -eq "status") {
        Show-Status

    } elseif ($Action -eq "stop") {
        Stop-Systems

    }

} catch {
    Write-Log "ERROR: $_"
    Write-Log $_.ScriptStackTrace
    exit 1
}
