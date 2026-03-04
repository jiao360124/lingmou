# Port Configuration Guide

## Overview

OpenClaw services now support unified port configuration using environment variables. All services (Gateway, Canvas, Heartbeat) use the same default port for simplicity.

## Configuration Files

### 1. `.ports.env` (Required)

Primary configuration file containing port settings:

```env
GATEWAY_PORT=18789
CANVAS_PORT=18789
HEARTBEAT_PORT=18789
WS_PORT=18789
```

### 2. `.env.example` (Template)

Template file for custom configuration. Copy to `.env` and modify as needed.

### 3. `.env-loader.ps1` (PowerShell)

Helper script to load environment variables in PowerShell scripts.

### 4. `.env-loader.sh` (Bash)

Helper script to load environment variables in Bash scripts.

## Usage

### In PowerShell Scripts

```powershell
# Add to the top of your script
. .env-loader.ps1

# Use environment variables
Write-Host "Gateway Port: $env:GATEWAY_PORT"
```

### In Bash Scripts

```bash
# Add to the top of your script
source .env-loader.sh

# Use environment variables
echo "Gateway Port: $GATEWAY_PORT"
```

### Direct Access

```bash
# From command line
source .ports.env
echo $GATEWAY_PORT  # Output: 18789
```

## Script Compatibility

All major scripts have been updated to use environment variables:

### Windows PowerShell Scripts
- ✅ `scripts/daily-backup.ps1`
- ✅ `scripts/nightly-evolution.ps1`
- ✅ `context_cleanup.ps1`

### Bash Scripts
- ✅ `scripts/nightly-evolution.sh`

## Updating Port Configuration

1. Edit `.ports.env`:
   ```env
   GATEWAY_PORT=19000  # Change from 18789 to 19000
   ```

2. Scripts will automatically use the new port on next run.

3. Restart gateway if it's currently running:
   ```powershell
   openclaw gateway restart
   ```

## Benefits

- **Unified Management**: Single source of truth for port configuration
- **Easy Migration**: Change ports once, all scripts follow
- **Environment Isolation**: Different environments (dev, prod) can have different ports
- **No Hardcoding**: Port values are stored externally

## Troubleshooting

### Port Already in Use

If you encounter "Address already in use" errors:

1. Check what's using the port:
   ```powershell
   netstat -ano | findstr :18789
   ```

2. Stop the conflicting process or change the port in `.ports.env`.

### Scripts Not Loading Environment Variables

1. Ensure `.env-loader.ps1` is in the workspace root
2. Check that the script is in the correct directory when running
3. Verify PowerShell execution policy allows script execution:
   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

## References

- OpenClaw Configuration: `openclaw.json`
- Gateway Port: Default 18789 (configured in `.ports.env`)
- Canvas Port: Default 18789 (configured in `.ports.env`)
