# OpenClaw 3.0 Startup Script
# Launches the OpenClaw 3.0 Node.js system

param(
    [string]$Action = "start",  # start, status, stop, restart
    [bool]$Verbose = $true
)

$ErrorActionPreference = "Stop"

# Project paths
$projectRoot = "C:\Users\Administrator\.openclaw\workspace"
$openclawDir = Join-Path $projectRoot "openclaw-3.0"
$logFile = Join-Path $projectRoot "automation\openclaw-3.0.log"

# Check if OpenClaw 3.0 exists
if (-not (Test-Path $openclawDir)) {
    Write-Error "OpenClaw 3.0 directory not found: $openclawDir"
    exit 1
}

# Ensure automation directory exists
$pidsDir = Join-Path $projectRoot "automation\pids"
if (-not (Test-Path $pidsDir)) {
    New-Item -Path $pidsDir -ItemType Directory -Force | Out-Null
}

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage
    Add-Content -Path $logFile -Value $logMessage
}

function Start-OpenClaw3 {
    Write-Log "=== Starting OpenClaw 3.0 ==="

    try {
        # Check if already running
        $pidFile = Join-Path $pidsDir "openclaw-3.0.pid"
        if (Test-Path $pidFile) {
            $pid = Get-Content $pidFile | Select-Object -First 1
            $process = Get-Process -Id $pid -ErrorAction SilentlyContinue

            if ($process) {
                Write-Log "OpenClaw 3.0 is already running (PID: $pid)"
                Write-Log "Use -Action restart to restart, or -Action status to check status"
                return $false
            }
        }

        # Start in background
        Write-Log "Starting OpenClaw 3.0..."
        Write-Log "  Directory: $openclawDir"

        # Change to OpenClaw 3.0 directory
        Push-Location $openclawDir

        # Start Node.js process
        $process = Start-Process -FilePath "node.exe" `
            -ArgumentList "index.js" `
            -PassThru `
            -WindowStyle Normal `
            -RedirectStandardOutput "$pidsDir\openclaw-3.0.stdout" `
            -RedirectStandardError "$pidsDir\openclaw-3.0.stderr"

        $pid = $process.Id
        Write-Log "✓ Started OpenClaw 3.0 (PID: $pid)"

        # Save PID
        $pid | Out-File -FilePath $pidFile -Force

        # Wait a moment for it to initialize
        Start-Sleep -Seconds 3

        # Check if process is still running
        $process = Get-Process -Id $pid -ErrorAction SilentlyContinue
        if ($process) {
            Write-Log "✓ OpenClaw 3.0 is running"
            Write-Log ""
            Write-Log "To monitor output:"
            Write-Log "  Get-Content '$pidsDir\openclaw-3.0.stdout' -Wait"
            Write-Log ""
            Write-Log "To stop:"
            Write-Log "  Stop-OpenClaw3"
        } else {
            Write-Log "✗ OpenClaw 3.0 stopped immediately"
            Remove-Item $pidFile -Force
            return $false
        }

        return $true

    } catch {
        Write-Log "✗ Failed to start OpenClaw 3.0: $_"
        return $false
    } finally {
        Pop-Location
    }
}

function Get-Status {
    Write-Log "=== OpenClaw 3.0 Status ==="

    $pidFile = Join-Path $pidsDir "openclaw-3.0.pid"

    if (Test-Path $pidFile) {
        $pid = Get-Content $pidFile | Select-Object -First 1
        $process = Get-Process -Id $pid -ErrorAction SilentlyContinue

        if ($process) {
            $cpu = [math]::Round($process.CPU, 2)
            $memory = [math]::Round($process.WorkingSet64 / 1MB, 2)

            Write-Log "🟢 Running (PID: $pid)"
            Write-Log "  CPU: $cpu%"
            Write-Log "  Memory: $memory MB"
            Write-Log "  Uptime: $([math]::Round((Get-Date) - $process.StartTime, 0)) seconds"
            return $true
        }
    }

    Write-Log "⚪ Stopped"
    return $false
}

function Stop-OpenClaw3 {
    Write-Log "=== Stopping OpenClaw 3.0 ==="

    $pidFile = Join-Path $pidsDir "openclaw-3.0.pid"

    if (Test-Path $pidFile) {
        $pid = Get-Content $pidFile | Select-Object -First 1
        Write-Log "Stopping OpenClaw 3.0 (PID: $pid)..."

        try {
            $process = Get-Process -Id $pid -ErrorAction Stop
            $process.Kill()
            Remove-Item $pidFile -Force
            Write-Log "✓ Stopped successfully"
        } catch {
            Write-Log "⚠ Process not found or already stopped"
        }
    } else {
        Write-Log "No OpenClaw 3.0 process found"
    }
}

function Restart-OpenClaw3 {
    Write-Log "=== Restarting OpenClaw 3.0 ==="

    Stop-OpenClaw3
    Start-Sleep -Seconds 2
    Start-OpenClaw3
}

function Show-Logs {
    $stdoutFile = Join-Path $pidsDir "openclaw-3.0.stdout"
    $stderrFile = Join-Path $pidsDir "openclaw-3.0.stderr"

    Write-Log "=== OpenClaw 3.0 Logs ==="

    if (Test-Path $stdoutFile) {
        Write-Log "STDOUT:"
        Get-Content $stdoutFile -Tail 20
        Write-Log ""
    }

    if (Test-Path $stderrFile) {
        Write-Log "STDERR:"
        Get-Content $stderrFile -Tail 20
        Write-Log ""
    }
}

try {
    if ($Action -eq "start") {
        Start-OpenClaw3

    } elseif ($Action -eq "stop") {
        Stop-OpenClaw3

    } elseif ($Action -eq "restart") {
        Restart-OpenClaw3

    } elseif ($Action -eq "status") {
        Get-Status

    } elseif ($Action -eq "logs") {
        Get-Status
        Write-Log ""
        Show-Logs

    }

} catch {
    Write-Log "ERROR: $_"
    Write-Log $_.ScriptStackTrace
    exit 1
}
