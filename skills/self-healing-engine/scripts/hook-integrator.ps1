<#
.SYNOPSIS
    Hook集成系统 - 简化版本

.DESCRIPTION
    提供Hook检测、注册、执行和管理的简化框架。

.VERSION
    1.0.0

.AUTHOR
    灵眸
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('init', 'register', 'list', 'test')]
    [string]$Action,

    [Parameter(Mandatory=$false)]
    [string]$Name,

    [Parameter(Mandatory=$false)]
    [string]$Type = "script",

    [Parameter(Mandatory=$false)]
    [string]$Location = ""
)

$ConfigPath = "$PSScriptRoot/../config/hook-config.json"
$HooksPath = "$PSScriptRoot/../data/hooks.json"

function Initialize-System {
    Write-Host "🔧 Initializing Hook System..." -ForegroundColor Cyan

    if (-not (Test-Path $ConfigPath)) {
        @{
            "enabled" = $true
            "maxHooks" = 100
        } | ConvertTo-Json -Depth 10 | Set-Content $ConfigPath
    }

    if (-not (Test-Path $HooksPath)) {
        @{
            "hooks" = @()
            "lastUpdated" = (Get-Date).ToString("o")
        } | ConvertTo-Json -Depth 10 | Set-Content $HooksPath
    }

    Write-Host "✅ System initialized" -ForegroundColor Green
    return "initialized"
}

function Register-Hook {
    param([string]$Name, [string]$Type = "script", [string]$Location = "")

    Write-Host "📝 Registering hook: $Name" -ForegroundColor Green

    $hooks = Get-Content $HooksPath -Raw | ConvertFrom-Json

    $newHook = [PSCustomObject]@{
        id = "HOOK-$(Get-Random -Maximum 999999)"
        name = $Name
        type = $Type
        location = $Location
        enabled = $true
        createdAt = (Get-Date).ToString("o")
    }

    $hooks.hooks += $newHook
    $hooks | ConvertTo-Json -Depth 10 | Set-Content $HooksPath

    Write-Host "✅ Hook registered: $Name" -ForegroundColor Green
    return $newHook
}

function List-Hooks {
    $hooks = Get-Content $HooksPath -Raw | ConvertFrom-Json

    # Convert to table format string
    $output = "`nHook ID              | Name        | Type        | Location"
    $output += "`n---------------------|-------------|-------------|--------------"

    foreach ($hook in $hooks.hooks) {
        $hookId = if ($hook.id) { $hook.id.Substring(0, [Math]::Min(20, $hook.id.Length)) } else { "" }
        $hookName = if ($hook.name) { $hook.name.PadRight(11) } else { "".PadRight(11) }
        $hookType = if ($hook.type) { $hook.type.PadRight(11) } else { "".PadRight(11) }
        $hookLocation = if ($hook.location) { $hook.location.Substring(0, [Math]::Min(40, $hook.location.Length)) } else { "".PadRight(40) }

        $output += "`n$hookId | $hookName | $hookType | $hookLocation"
    }

    Write-Host $output
    return $output
}

try {
    Initialize-System

    switch ($Action) {
        "register" {
            if (-not $Name) {
                throw "Name parameter is required for registration"
            }

            $hook = Register-Hook -Name $Name -Type $Type -Location $Location
            return $hook
        }

        "list" {
            return List-Hooks
        }

        "test" {
            Write-Host "🧪 Testing Hook System..." -ForegroundColor Cyan

            # Create test hook
            $testHook = Register-Hook -Name "test-hook" -Type "script" -Location "Write-Host 'Test hook executed!' -ForegroundColor Green"

            Write-Host "`n✅ Test completed" -ForegroundColor Green
            return "test completed"
        }
    }
} catch {
    Write-Error "Error: $($_.Exception.Message)"
    exit 1
}

Write-Host "`n✅ Operation completed" -ForegroundColor Green
