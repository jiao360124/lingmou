# Environment Variable Loader for OpenClaw
# Load ports and other configuration from .env files

function Load-EnvFile {
    param(
        [string]$FilePath = ".env"
    )

    if (Test-Path -Path $FilePath) {
        Get-Content -Path $FilePath | ForEach-Object {
            # Skip empty lines and comments
            if ($_ -match '^\s*$|^\s*#') {
                return
            }

            # Try to parse key=value format
            if ($_ -match '^\s*(\w+)\s*=\s*(.+)\s*$') {
                $name = $matches[1]
                $value = $matches[2].Trim('"', "'")
                # Set as PowerShell variable
                New-Variable -Name $name -Value $value -Scope 0 -Force
            }
        }
        Write-Host "✅ Environment variables loaded from $FilePath" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Environment file not found: $FilePath" -ForegroundColor Yellow
    }
}

# Load from .ports.env
Load-EnvFile -FilePath ".ports.env"

# Set defaults
if (-not $env:GATEWAY_PORT) { $env:GATEWAY_PORT = "18789" }
if (-not $env:CANVAS_PORT) { $env:CANVAS_PORT = "18789" }
if (-not $env:HEARTBEAT_PORT) { $env:HEARTBEAT_PORT = "18789" }
if (-not $env:WS_PORT) { $env:WS_PORT = "18789" }

