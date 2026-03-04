# OpenClaw Environment Configuration Check Script

param(
    [switch]$Detailed,
    [switch]$Strict
)

$ErrorActionPreference = "Stop"

# Script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$WorkspaceDir = Split-Path -Parent $ScriptDir

# Color definitions
$ColorInfo = "Cyan"
$ColorSuccess = "Green"
$ColorWarning = "Yellow"
$ColorError = "Red"
$ColorHeader = "Magenta"

# Utility functions
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = $ColorInfo
    )
    if ($Detailed) {
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

# Check system requirements
function Test-SystemRequirements {
    Write-Header "System Requirements Check" -Level 2

    $requirements = @()

    # 1. PowerShell version
    $psVersion = $PSVersionTable.PSVersion
    $psMinVersion = [version]"5.1"

    if ($psVersion -ge $psMinVersion) {
        $requirements += @{
            Name = "PowerShell Version"
            Status = "OK"
            Version = "$psVersion"
            Required = "$psMinVersion"
            Message = "PowerShell version is sufficient"
        }
    } else {
        $requirements += @{
            Name = "PowerShell Version"
            Status = "ERROR"
            Version = "$psVersion"
            Required = "$psMinVersion"
            Message = "PowerShell version is too low, need 5.1+"
        }
    }

    # 2. Git version
    $gitVersion = git --version 2>$null | Out-String
    if ($LASTEXITCODE -eq 0) {
        $requirements += @{
            Name = "Git"
            Status = "OK"
            Version = $gitVersion.Trim()
            Required = "2.0+"
            Message = "Git is installed"
        }
    } else {
        $requirements += @{
            Name = "Git"
            Status = "ERROR"
            Version = "Not installed"
            Required = "2.0+"
            Message = "Git is not installed"
        }
    }

    # 3. Node.js version (optional)
    $nodeVersion = node --version 2>$null | Out-String
    if ($LASTEXITCODE -eq 0) {
        $requirements += @{
            Name = "Node.js"
            Status = "OK"
            Version = $nodeVersion.Trim()
            Required = "18+"
            Message = "Node.js is installed"
        }
    } else {
        $requirements += @{
            Name = "Node.js"
            Status = "WARNING"
            Version = "Not installed"
            Required = "18+"
            Message = "Node.js is not installed (optional)"
        }
    }

    # 4. Disk space
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
    $minSpaceGB = 10

    if ($freeSpaceGB -ge $minSpaceGB) {
        $requirements += @{
            Name = "Disk Space"
            Status = "OK"
            Version = "$freeSpaceGB GB"
            Required = "$minSpaceGB GB"
            Message = "Disk space is sufficient"
        }
    } else {
        $requirements += @{
            Name = "Disk Space"
            Status = "ERROR"
            Version = "$freeSpaceGB GB"
            Required = "$minSpaceGB GB"
            Message = "Disk space is insufficient"
        }
    }

    # Print results
    foreach ($req in $requirements) {
        $statusColor = switch ($req.Status) {
            "OK" { "Green" }
            "WARNING" { "Yellow" }
            "ERROR" { "Red" }
            default { "White" }
        }
        $statusIcon = switch ($req.Status) {
            "OK" { "[OK]" }
            "WARNING" { "[WARN]" }
            "ERROR" { "[ERROR]" }
            default { "[?]" }
        }

        Write-Host "  $statusIcon $($req.Name)" -ForegroundColor $statusColor
        if ($Detailed) {
            Write-Host "      Version: $($req.Version)" -ForegroundColor DarkGray
            Write-Host "      Required: $($req.Required)" -ForegroundColor DarkGray
            Write-Host "      Description: $($req.Message)" -ForegroundColor $(if ($req.Status -eq "ERROR") { "Red" } else { "DarkGray" })
        }
    }

    # Summary
    $okCount = ($requirements | Where-Object { $_.Status -eq "OK" }).Count
    $warningCount = ($requirements | Where-Object { $_.Status -eq "WARNING" }).Count
    $errorCount = ($requirements | Where-Object { $_.Status -eq "ERROR" }).Count

    Write-Host "`nSystem Requirements Summary:" -ForegroundColor $ColorInfo
    Write-Host "  OK: $okCount" -ForegroundColor $ColorSuccess
    Write-Host "  WARNING: $warningCount" -ForegroundColor $ColorWarning
    Write-Host "  ERROR: $errorCount" -ForegroundColor $ColorError

    if ($Strict -and $errorCount -gt 0) {
        Write-Host "`nERROR: System requirements not met" -ForegroundColor $ColorError
        exit 1
    }

    return ($errorCount -eq 0)
}

# Check environment configuration
function Test-EnvironmentConfig {
    Write-Header "Environment Configuration Check" -Level 2

    $checks = @()

    # 1. Check .env file
    if (Test-Path ".env") {
        $checks += @{
            Name = "Environment File (.env)"
            Status = "OK"
            Message = "Config file exists"
            SizeKB = [math]::Round((Get-Item ".env").Length / 1KB, 2)
        }
    } else {
        $checks += @{
            Name = "Environment File (.env)"
            Status = "WARNING"
            Message = "Config file not found (using default config)"
        }
    }

    # 2. Check .env.example
    if (Test-Path ".env.example") {
        $checks += @{
            Name = "Environment Template (.env.example)"
            Status = "OK"
            Message = "Config template exists"
        }
    } else {
        $checks += @{
            Name = "Environment Template (.env.example)"
            Status = "ERROR"
            Message = "Config template not found"
        }
    }

    # 3. Check port configuration
    if (Test-Path ".ports.env") {
        $checks += @{
            Name = "Port Configuration (.ports.env)"
            Status = "OK"
            Message = "Port config file exists"
        }

        # Read port configuration
        Get-Content ".ports.env" | ForEach-Object {
            if ($_ -match "GATEWAY_PORT=(\d+)") {
                $port = $matches[1]
                $checks += @{
                    Name = "Gateway Port"
                    Status = "OK"
                    Message = "Gateway port: $port"
                }
            }
        }
    } else {
        $checks += @{
            Name = "Port Configuration (.ports.env)"
            Status = "WARNING"
            Message = "Port config file not found (using default)"
        }
    }

    # 4. Check directory structure
    $directories = @("logs", "memory", "backup", "reports", "tasks")
    foreach ($dir in $directories) {
        if (Test-Path $dir) {
            $fileCount = (Get-ChildItem -Path $dir -Recurse -File 2>$null | Measure-Object).Count
            $checks += @{
                Name = "Directory: $dir"
                Status = "OK"
                Message = "Directory exists ($fileCount files)"
            }
        } else {
            $checks += @{
                Name = "Directory: $dir"
                Status = "ERROR"
                Message = "Directory not found"
            }
        }
    }

    # 5. Check script directory
    if (Test-Path "scripts") {
        $scriptCount = (Get-ChildItem -Path "scripts" -Recurse -Filter "*.ps1" 2>$null | Measure-Object).Count
        $checks += @{
            Name = "Scripts Directory"
            Status = "OK"
            Message = "Scripts directory exists ($scriptCount scripts)"
        }
    } else {
        $checks += @{
            Name = "Scripts Directory"
            Status = "ERROR"
            Message = "Scripts directory not found"
        }
    }

    # 6. Check Git repository
    $gitDir = ".git"
    if (Test-Path $gitDir) {
        $checks += @{
            Name = "Git Repository"
            Status = "OK"
            Message = "Git repository exists"
        }

        # Check remote repository
        $remote = git remote -v 2>$null | Select-Object -First 1
        if ($remote) {
            $checks += @{
                Name = "Remote Repository"
                Status = "OK"
                Message = "$remote"
            }
        } else {
            $checks += @{
                Name = "Remote Repository"
                Status = "WARNING"
                Message = "No remote repository configured"
            }
        }
    } else {
        $checks += @{
            Name = "Git Repository"
            Status = "ERROR"
            Message = "Git repository not found"
        }
    }

    # Print results
    foreach ($check in $checks) {
        $statusColor = switch ($check.Status) {
            "OK" { "Green" }
            "WARNING" { "Yellow" }
            "ERROR" { "Red" }
            default { "White" }
        }
        $statusIcon = switch ($check.Status) {
            "OK" { "[OK]" }
            "WARNING" { "[WARN]" }
            "ERROR" { "[ERROR]" }
            default { "[?]" }
        }

        Write-Host "  $statusIcon $($check.Name)" -ForegroundColor $statusColor
        if ($Detailed) {
            if ($check.Message) {
                Write-Host "      $($check.Message)" -ForegroundColor $(if ($check.Status -eq "ERROR") { "Red" } else { "DarkGray" })
            }
        }
    }

    # Summary
    $okCount = ($checks | Where-Object { $_.Status -eq "OK" }).Count
    $warningCount = ($checks | Where-Object { $_.Status -eq "WARNING" }).Count
    $errorCount = ($checks | Where-Object { $_.Status -eq "ERROR" }).Count

    Write-Host "`nEnvironment Configuration Summary:" -ForegroundColor $ColorInfo
    Write-Host "  OK: $okCount" -ForegroundColor $ColorSuccess
    Write-Host "  WARNING: $warningCount" -ForegroundColor $ColorWarning
    Write-Host "  ERROR: $errorCount" -ForegroundColor $ColorError

    if ($Strict -and $errorCount -gt 0) {
        Write-Host "`nERROR: Environment configuration has issues" -ForegroundColor $ColorError
        exit 1
    }

    return ($errorCount -eq 0)
}

# Check module integrity
function Test-ModuleIntegrity {
    Write-Header "Module Integrity Check" -Level 2

    $modules = Get-ChildItem -Path "scripts" -Filter "*.ps1" | Where-Object { $_.Name -notmatch "^test-" }

    if ($modules.Count -eq 0) {
        Write-Host "  [ERROR] No script files found" -ForegroundColor $ColorError
        return $false
    }

    $missingDependencies = @()
    $missingFiles = @()

    foreach ($module in $modules) {
        $moduleName = $module.BaseName

        # Check script syntax
        try {
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $module.FullName -Raw), [ref]$null)
            Write-Host "  [OK] $moduleName" -ForegroundColor $ColorSuccess
        } catch {
            Write-Host "  [ERROR] $moduleName - Syntax error" -ForegroundColor $ColorError
            $missingDependencies += "$moduleName (syntax error)"
        }

        # Check required files
        if ($moduleName -eq "git-backup") {
            if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
                Write-Host "  [WARN] $ModuleName - Git not installed" -ForegroundColor $ColorWarning
                $missingDependencies += "$moduleName (Git not installed)"
            }
        }
    }

    # Summary
    if ($missingDependencies.Count -eq 0) {
        Write-Host "`nModule Integrity: OK" -ForegroundColor $ColorSuccess
    } else {
        Write-Host "`nModule Integrity: FAILED" -ForegroundColor $ColorError
        Write-Host "Missing dependencies:" -ForegroundColor $ColorWarning
        foreach ($dep in $missingDependencies) {
            Write-Host "  - $dep" -ForegroundColor DarkGray
        }
    }

    return ($missingDependencies.Count -eq 0)
}

# Main function
function Main {
    Write-ColorOutput "`nOpenClaw Environment Configuration Check" -Color $ColorHeader
    Write-ColorOutput "Start Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Color $ColorInfo

    try {
        # 1. Check system requirements
        $systemOK = Test-SystemRequirements

        # 2. Check environment configuration
        $envOK = Test-EnvironmentConfig

        # 3. Check module integrity
        $moduleOK = Test-ModuleIntegrity

        # Final summary
        Write-Header "Check Summary" -Level 2
        Write-Host "System Requirements: $(if ($systemOK) { '[OK]' } else { '[FAILED]' })" -ForegroundColor $(if ($systemOK) { "Green" } else { "Red" })
        Write-Host "Environment Configuration: $(if ($envOK) { '[OK]' } else { '[FAILED]' })" -ForegroundColor $(if ($envOK) { "Green" } else { "Red" })
        Write-Host "Module Integrity: $(if ($moduleOK) { '[OK]' } else { '[FAILED]' })" -ForegroundColor $(if ($moduleOK) { "Green" } else { "Red" })

        if ($systemOK -and $envOK -and $moduleOK) {
            Write-Host "`n[SUCCESS] All checks passed! System is ready." -ForegroundColor $ColorSuccess
            exit 0
        } else {
            Write-Host "`n[FAILED] Some checks did not pass, please fix before deployment." -ForegroundColor $ColorError
            exit 1
        }
    } catch {
        Write-ColorOutput "`nError: $_" -Color $ColorError
        Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
        exit 1
    }
}

# Execute
Main
