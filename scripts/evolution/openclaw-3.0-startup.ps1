# OpenClaw 3.0 Startup Script
# 启动OpenClaw 3.0 Node.js系统

param(
    [string]$Action = "start"
)

# Project paths
$projectRoot = "C:\Users\Administrator\.openclaw\workspace"
$openclawDir = Join-Path $projectRoot "openclaw-3.0"
$logFile = Join-Path $projectRoot "automation\openclaw-3.0.log"

# Check if OpenClaw 3.0 exists
if (-not (Test-Path $openclawDir)) {
    Write-Error "OpenClaw 3.0 directory not found: $openclawDir"
    exit 1
}

try {
    switch ($Action) {
        "start" {
            Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host "           OPENCLAW 3.0 STARTUP" -ForegroundColor Cyan
            Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host ""

            Write-Host "Directory: $openclawDir" -ForegroundColor White
            Write-Host ""

            # Change to OpenClaw 3.0 directory
            Push-Location $openclawDir

            # Check Node.js
            Write-Host "Checking Node.js..." -ForegroundColor White
            $nodeVersion = node --version
            Write-Host "✓ Node.js version: $nodeVersion" -ForegroundColor Green

            # Check package.json
            Write-Host "Checking package.json..." -ForegroundColor White
            if (-not (Test-Path "package.json")) {
                Write-Error "package.json not found"
                Pop-Location
                exit 1
            }
            Write-Host "✓ package.json found" -ForegroundColor Green

            # Install dependencies
            Write-Host "Installing dependencies..." -ForegroundColor White
            Write-Host "This may take a few minutes..." -ForegroundColor Yellow
            $installOutput = npm install 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ Dependencies installed" -ForegroundColor Green
            } else {
                Write-Warning "Some dependencies may have issues"
            }

            # Start the application
            Write-Host ""
            Write-Host "Starting OpenClaw 3.0..." -ForegroundColor White
            Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow

            # Start Node.js
            node index.js

        }

        "status" {
            Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host "           OPENCLAW 3.0 STATUS" -ForegroundColor Cyan
            Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host ""

            Write-Host "Directory: $openclawDir" -ForegroundColor White

            if (Test-Path "$openclawDir\package.json") {
                Write-Host "✓ package.json found" -ForegroundColor Green
            } else {
                Write-Host "✗ package.json not found" -ForegroundColor Red
            }

            # Check Node.js
            $nodeVersion = node --version 2>$null
            if ($nodeVersion) {
                Write-Host "✓ Node.js: $nodeVersion" -ForegroundColor Green
            } else {
                Write-Host "✗ Node.js not installed" -ForegroundColor Red
            }

            # Show log file
            if (Test-Path $logFile) {
                Write-Host ""
                Write-Host "Recent logs:" -ForegroundColor White
                $logContent = Get-Content $logFile -Tail 20
                foreach ($line in $logContent) {
                    Write-Host "  $line" -ForegroundColor Gray
                }
            }

            Write-Host ""
            Write-Host "To start OpenClaw 3.0:" -ForegroundColor Yellow
            Write-Host "  .\openclaw-3.0-startup.ps1 -Action start" -ForegroundColor Gray
        }

        "stop" {
            Write-Host "Stopping OpenClaw 3.0..." -ForegroundColor White

            # Check if running
            $process = Get-Process -Name "node" -ErrorAction SilentlyContinue
            if ($process) {
                # Find the process that's running index.js in openclaw-3.0
                $openclawProcess = $process | Where-Object {
                    $_.Path -like "*$openclawDir*" -or $_.CommandLine -like "*index.js*"
                }

                if ($openclawProcess) {
                    Write-Host "Stopping process $($openclawProcess.Id)..." -ForegroundColor Yellow
                    $openclawProcess.Kill()
                    Write-Host "✓ Stopped" -ForegroundColor Green
                } else {
                    Write-Host "OpenClaw 3.0 not running" -ForegroundColor Yellow
                }
            } else {
                Write-Host "No Node.js processes found" -ForegroundColor Yellow
            }
        }

        "logs" {
            Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host "           OPENCLAW 3.0 LOGS" -ForegroundColor Cyan
            Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host ""

            if (Test-Path $logFile) {
                Write-Host "Recent logs:" -ForegroundColor White
                $logContent = Get-Content $logFile -Tail 30
                foreach ($line in $logContent) {
                    Write-Host "  $line" -ForegroundColor Gray
                }
            } else {
                Write-Host "No log file found" -ForegroundColor Yellow
                Write-Host "Log file location: $logFile" -ForegroundColor Gray
            }
        }

        "config" {
            Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host "           OPENCLAW 3.0 CONFIG" -ForegroundColor Cyan
            Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host ""

            if (Test-Path "$openclawDir\config.json") {
                $config = Get-Content "$openclawDir\config.json" -Raw | ConvertFrom-Json
                $config | ConvertTo-Json -Depth 10 | Format-List
            } else {
                Write-Host "config.json not found" -ForegroundColor Red
            }
        }

        default {
            Write-Host "Unknown action: $Action" -ForegroundColor Red
            Write-Host ""
            Write-Host "Available actions:" -ForegroundColor Yellow
            Write-Host "  start    - Start OpenClaw 3.0" -ForegroundColor Gray
            Write-Host "  status   - Show status" -ForegroundColor Gray
            Write-Host "  stop     - Stop OpenClaw 3.0" -ForegroundColor Gray
            Write-Host "  logs     - Show logs" -ForegroundColor Gray
            Write-Host "  config   - Show configuration" -ForegroundColor Gray
            exit 1
        }
    }

} catch {
    Write-Host "✗ Error: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace
    exit 1
} finally {
    Pop-Location
}
