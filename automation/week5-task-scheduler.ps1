# Week 5 - Windows Task Scheduler Setup
# Creates scheduled tasks for all Week 5 evolution systems

param(
    [string]$Action = "create",  # create, test, remove
    [bool]$Verbose = $true
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage
    if ($Verbose) {
        Add-Content -Path "automation/week5-scheduler-setup.log" -Value $logMessage
    }
}

# Project paths
$projectRoot = "C:\Users\Administrator\.openclaw\workspace"
$schedulerScript = Join-Path $projectRoot "scripts\evolution\heartbeat-monitor.ps1"

# Task definitions
$tasks = @(
    @{
        Name = "OpenClaw-Heartbeat-Monitor"
        ScriptPath = $schedulerScript
        Trigger = "Every 30 minutes"
        Description = "Heartbeat monitor - checks Moltbook/network/API status"
        Enabled = $true
    },
    @{
        Name = "OpenClaw-Rate-Limiter"
        ScriptPath = Join-Path $projectRoot "scripts\evolution\rate-limiter.ps1"
        Trigger = "Every 5 minutes"
        Description = "Rate limiter - manages 429 errors and throttling"
        Enabled = $true
    },
    @{
        Name = "OpenClaw-Monitoring-Dashboard"
        ScriptPath = Join-Path $projectRoot "scripts\evolution\monitoring-dashboard.ps1"
        Trigger = "Every 30 minutes"
        Description = "Monitoring dashboard - displays real-time metrics"
        Enabled = $true
    },
    @{
        Name = "OpenClaw-Nightly-Plan"
        ScriptPath = Join-Path $projectRoot "scripts\evolution\nightly-plan.ps1"
        Trigger = "Daily at 3:00 AM"
        Description = "Nightly plan - friction point fixes and toolchain optimization"
        Enabled = $true
    },
    @{
        Name = "OpenClaw-Launchpad-Engine"
        ScriptPath = Join-Path $projectRoot "scripts\evolution\launchpad-engine.ps1"
        Trigger = "Daily at 4:00 AM"
        Description = "Launchpad engine - 6-phase improvement cycle"
        Enabled = $true
    }
)

function New-ScheduledTask {
    param(
        [hashtable]$Task,
        [int]$IntervalMinutes
    )

    Write-Log "Creating task: $($Task.Name)"

    # Check if task already exists
    $existingTask = Get-ScheduledTask -TaskName $Task.Name -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Log "Task $($Task.Name) already exists. Removing..."
        Unregister-ScheduledTask -TaskName $Task.Name -Confirm:$false -Force
    }

    # Create task action
    $action = New-ScheduledTaskAction `
        -Execute "powershell.exe" `
        -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$($Task.ScriptPath)`" -Verbose" `
        -WorkingDirectory $projectRoot

    # Create task trigger (repeating)
    $duration = [TimeSpan]::MaxValue
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) `
        -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes) `
        -RepetitionDuration $duration

    # Create task settings
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -RestartCount 3 `
        -RestartInterval (New-TimeSpan -Minutes 5)

    # Register task
    Register-ScheduledTask `
        -TaskName $Task.Name `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Description $Task.Description `
        -User "SYSTEM" `
        -RunLevel Highest | Out-Null

    Write-Log "✓ Task $($Task.Name) created successfully"
}

try {
    if ($Action -eq "create") {
        Write-Log "=== Week 5 Task Scheduler Setup ==="
        Write-Log "Creating $($tasks.Count) scheduled tasks..."

        foreach ($task in $tasks) {
            $interval = switch ($task.Trigger) {
                "Every 30 minutes" { 30 }
                "Every 5 minutes" { 5 }
                "Daily at 3:00 AM" { $null }  # Single trigger
                "Daily at 4:00 AM" { $null }  # Single trigger
                Default { 30 }
            }

            if ($interval) {
                New-ScheduledTask -Task $task -IntervalMinutes $interval
            }
        }

        Write-Log "=== Setup Complete ==="
        Write-Log "All scheduled tasks created successfully!"
        Write-Log ""
        Write-Log "View all tasks:"
        Write-Log "  Get-ScheduledTask | Where-Object {$_.TaskName -like 'OpenClaw-*'}"

    } elseif ($Action -eq "test") {
        Write-Log "=== Testing Scheduled Tasks ==="
        foreach ($task in $tasks) {
            Write-Log "Checking task: $($task.Name)"
            $scheduledTask = Get-ScheduledTask -TaskName $task.Name -ErrorAction SilentlyContinue
            if ($scheduledTask) {
                Write-Log "  ✓ Status: $($scheduledTask.State)"
                Write-Log "  ✓ Last Run: $($scheduledTask.LastRunTime)"
                Write-Log "  ✓ Next Run: $($scheduledTask.NextRunTime)"
            } else {
                Write-Log "  ✗ Task not found"
            }
        }

    } elseif ($Action -eq "remove") {
        Write-Log "=== Removing All OpenClaw Tasks ==="
        foreach ($task in $tasks) {
            $scheduledTask = Get-ScheduledTask -TaskName $task.Name -ErrorAction SilentlyContinue
            if ($scheduledTask) {
                Write-Log "Removing task: $($task.Name)"
                Unregister-ScheduledTask -TaskName $task.Name -Confirm:$false -Force
            }
        }
        Write-Log "=== Removal Complete ==="
    }

} catch {
    Write-Log "ERROR: $_"
    exit 1
}
