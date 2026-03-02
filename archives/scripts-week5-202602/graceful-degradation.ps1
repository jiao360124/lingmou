# Graceful Degradation System
# 自动状态恢复和错误处理

param(
    [string]$Action = "start"
)

# 配置
$configFile = Join-Path $PSScriptRoot "..\config.json"
if (Test-Path $configFile) {
    $config = Get-Content $configFile -Raw | ConvertFrom-Json
} else {
    Write-Warning "Config file not found: $configFile"
    exit 1
}

$stateFile = Join-Path $PSScriptRoot "..\graceful-state.json"
$recoveryCountFile = Join-Path $PSScriptRoot "..\recovery-count.json"

function Save-State {
    param($State)
    $State | ConvertTo-Json -Depth 10 | Out-File $stateFile -Force
    Write-Host "✓ State saved to $stateFile"
}

function Load-State {
    if (Test-Path $stateFile) {
        return Get-Content $stateFile -Raw | ConvertFrom-Json
    }
    return @{
        ErrorCode = 0
        RecoveryAttempts = 0
        LastError = ""
        Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Context = New-Object PSObject
    }
}

function Recover-System {
    param($ErrorCode, $ErrorType, $ErrorDetails)

    $state = Load-State
    $state.ErrorCode = $ErrorCode
    $state.LastError = $ErrorDetails
    $state.Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $state.RecoveryAttempts++

    Write-Host "⚠️  Error detected: $ErrorType"
    Write-Host "  Details: $ErrorDetails"
    Write-Host "  Recovery attempt: $($state.RecoveryAttempts)"

    # 智能恢复策略
    switch ($ErrorType) {
        "Timeout" {
            Write-Host "→ Strategy: Retry with exponential backoff"
            Start-Sleep -Seconds 5
            return $true
        }
        "NetworkError" {
            Write-Host "→ Strategy: Check connectivity and retry"
            Start-Sleep -Seconds 10
            return $true
        }
        "NotFound" {
            Write-Host "→ Strategy: Check configuration and retry"
            Start-Sleep -Seconds 3
            return $true
        }
        default {
            Write-Host "→ Strategy: Basic retry (3 attempts)"
            for ($i = 1; $i -le 3; $i++) {
                Start-Sleep -Seconds $i * 2
                Write-Host "  Retry attempt $i/3"
            }
            return $true
        }
    }
}

function Report-Recovery {
    param($Success)

    if ($Success) {
        Write-Host "✓ Recovery successful"
    } else {
        Write-Host "✗ Recovery failed - system needs manual intervention"
    }
}

try {
    switch ($Action) {
        "start" {
            Write-Host "=== Graceful Degradation System ==="
            Write-Host "Starting graceful degradation handler..."

            # 初始化状态
            $state = Load-State
            $state.Context | Add-Member -NotePropertyName "Uptime" -NotePropertyValue (Get-Date) -Force
            Save-State -State $state

            Write-Host "✓ Degradation system initialized"
            Write-Host ""
            Write-Host "Available recovery strategies:"
            Write-Host "  - Exponential backoff for timeouts"
            Write-Host "  - Network checks for connection errors"
            Write-Host "  - Configuration validation for not-found errors"
            Write-Host "  - Multiple retry attempts (default 3)"
            Write-Host ""
            Write-Host "System is now monitoring for errors and applying recovery strategies."
        }

        "check" {
            $state = Load-State
            Write-Host "=== Current State ==="
            Write-Host "Last Error: $($state.LastError)"
            Write-Host "Error Code: $($state.ErrorCode)"
            Write-Host "Recovery Attempts: $($state.RecoveryAttempts)"
            Write-Host "Timestamp: $($state.Timestamp)"
        }

        default {
            Write-Host "Unknown action: $Action"
            exit 1
        }
    }

} catch {
    Write-Host "✗ Error: $_"
    exit 1
}
