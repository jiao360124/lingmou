# OpenClaw Unified Integration Manager
# Unified Integration Manager for OpenClaw

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("start", "stop", "status", "modules", "test", "health", "report")]
    [string]$Action,

    [switch]$Detailed,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# Script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$WorkspaceDir = Split-Path -Parent $ScriptDir
$ModulesDir = Join-Path $WorkspaceDir "modules"

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

function Get-ModuleStatus {
    param(
        [string]$ModuleName
    )

    $scriptPath = Join-Path $ScriptDir "$ModuleName.ps1"

    if (Test-Path $scriptPath) {
        $scriptInfo = Get-Item $scriptPath
        return @{
            Name = $ModuleName
            Exists = $true
            SizeKB = [math]::Round($scriptInfo.Length / 1KB, 2)
            LastModified = $scriptInfo.LastWriteTime
        }
    }

    return @{
        Name = $ModuleName
        Exists = $false
        SizeKB = 0
        LastModified = $null
    }
}

function Get-AllModules {
    # Common script modules
    $commonModules = @(
        "clear-context",
        "daily-backup",
        "git-backup",
        "simple-health-check",
        "cleanup-logs-manual",
        "cleanup-github-tokens"
    )

    # Performance optimization modules
    $performanceModules = @(
        "performance-benchmark",
        "gradual-degradation",
        "gateway-optimizer",
        "response-optimizer",
        "memory-optimizer"
    )

    # Testing framework modules
    $testingModules = @(
        "test-simple",
        "test-full",
        "test-predictive-maintenance",
        "test-smart-enhanced",
        "stress-test",
        "error-recovery-test",
        "integration-test",
        "final-test"
    )

    return @{
        Common = $commonModules
        Performance = $performanceModules
        Testing = $testingModules
    }
}

# Start all modules
function Start-AllModules {
    Write-Header "Starting All Modules" -Level 2

    $modules = Get-AllModules

    $started = 0
    $failed = 0

    foreach ($category in $modules.Keys) {
        foreach ($moduleName in $modules[$category]) {
            Write-ColorOutput "Starting $category module: $moduleName" -Color $ColorInfo

            $scriptPath = Join-Path $ScriptDir "$moduleName.ps1"

            if (Test-Path $scriptPath) {
                if ($DryRun) {
                    Write-ColorOutput "  [DRY RUN] Would execute" -Color $ColorWarning
                    $started++
                } else {
                    try {
                        & $scriptPath -Verbose:$Detailed
                        $started++
                        Write-ColorOutput "  OK - Started" -Color $ColorSuccess
                    } catch {
                        Write-ColorOutput "  FAIL - Failed: $_" -Color $ColorError
                        $failed++
                    }
                }
            } else {
                Write-ColorOutput "  FAIL - Module not found" -Color $ColorError
                $failed++
            }
        }
    }

    Write-Header "Summary" -Level 2
    Write-Host "Started: $started modules" -ForegroundColor $ColorSuccess
    Write-Host "Failed: $failed modules" -ForegroundColor $ColorError
}

# Stop all modules
function Stop-AllModules {
    Write-Header "Stopping All Modules" -Level 2

    Write-ColorOutput "Stopping all modules... (implementation depends on module design)" -Color $ColorInfo

    if ($Detailed) {
        Write-Host "This is a placeholder. Actual stopping logic should be added to each module." -ForegroundColor $ColorWarning
    }

    Write-ColorOutput "Stopped: All modules (placeholder)" -Color $ColorSuccess
}

# Get status
function Get-Status {
    Write-Header "System Status" -Level 1

    $modules = Get-AllModules
    $totalCount = 0

    # Print statistics
    Write-Host "`nModule Statistics:" -ForegroundColor $ColorInfo
    foreach ($category in $modules.Keys) {
        $count = $modules[$category].Count
        $totalCount += $count
        Write-Host "  $($category): $count modules" -ForegroundColor $ColorInfo
    }
    Write-Host "  Total: $totalCount modules" -ForegroundColor $ColorInfo

    # List all modules
    Write-Host "`nModules List:" -ForegroundColor $ColorInfo
    foreach ($category in $modules.Keys) {
        Write-Host "`n[$category]:" -ForegroundColor $ColorWarning
        foreach ($moduleName in $modules[$category]) {
            $moduleStatus = Get-ModuleStatus -ModuleName $moduleName
            $statusIcon = if ($moduleStatus.Exists) { "[OK]" } else { "[MISS]" }
            $sizeInfo = if ($moduleStatus.Exists) { "(${moduleStatus.SizeKB}KB)" } else { "(not found)" }
            Write-Host "  $statusIcon $moduleName $sizeInfo" -ForegroundColor $(if ($moduleStatus.Exists) { "Green" } else { "Red" })
        }
    }

    # System information
    Write-Host "`nSystem Information:" -ForegroundColor $ColorInfo
    Write-Host "  Workspace: $WorkspaceDir" -ForegroundColor $ColorInfo
    Write-Host "  Scripts: $ScriptDir" -ForegroundColor $ColorInfo
    Write-Host "  Log directory: $(Join-Path $WorkspaceDir "logs")" -ForegroundColor $ColorInfo
    Write-Host "  Memory directory: $(Join-Path $WorkspaceDir "memory")" -ForegroundColor $ColorInfo
    Write-Host "  Backup directory: $(Join-Path $WorkspaceDir "backup")" -ForegroundColor $ColorInfo
}

# Test all modules
function Test-AllModules {
    Write-Header "Testing All Modules" -Level 2

    $modules = Get-AllModules
    $tested = 0
    $passed = 0
    $failed = 0

    foreach ($category in $modules.Keys) {
        foreach ($moduleName in $modules[$category]) {
            Write-ColorOutput "Testing $category module: $moduleName" -Color $ColorInfo
            $tested++

            $scriptPath = Join-Path $ScriptDir "$moduleName.ps1"

            if (Test-Path $scriptPath) {
                if ($DryRun) {
                    Write-ColorOutput "  [DRY RUN] Would test" -Color $ColorWarning
                    $passed++
                } else {
                    try {
                        # Test if script can be parsed
                        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $scriptPath -Raw), [ref]$null)
                        $passed++
                        Write-ColorOutput "  OK - Syntax valid" -Color $ColorSuccess
                    } catch {
                        $failed++
                        Write-ColorOutput "  FAIL - Syntax error: $_" -Color $ColorError
                    }
                }
            } else {
                $failed++
                Write-ColorOutput "  FAIL - Module not found" -Color $ColorError
            }
        }
    }

    Write-Header "Test Summary" -Level 2
    Write-Host "Total tested: $tested modules" -ForegroundColor $ColorInfo
    Write-Host "Passed: $passed modules" -ForegroundColor $ColorSuccess
    Write-Host "Failed: $failed modules" -ForegroundColor $ColorError

    # Test specific critical modules
    Write-Host "`nTesting Critical Modules:" -ForegroundColor $ColorWarning
    $criticalModules = @("git-backup", "clear-context", "simple-health-check")
    foreach ($moduleName in $criticalModules) {
        $scriptPath = Join-Path $ScriptDir "$moduleName.ps1"
        if (Test-Path $scriptPath) {
            try {
                $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $scriptPath -Raw), [ref]$null)
                Write-Host "  ✓ $moduleName" -ForegroundColor $ColorSuccess
            } catch {
                Write-Host "  ✗ $moduleName" -Color $ColorError
            }
        }
    }
}

# Health check
function Get-Health {
    Write-Header "System Health Check" -Level 1

    $checks = @()

    # 1. Check scripts directory
    if (Test-Path $ScriptDir) {
        $checks += @{
            Name = "Scripts Directory"
            Status = "OK"
            Message = "Scripts directory exists"
        }
    } else {
        $checks += @{
            Name = "Scripts Directory"
            Status = "ERROR"
            Message = "Scripts directory not found"
        }
    }

    # 2. Check config files
    $envFiles = @(".env", ".env-loader.ps1", ".env.example", ".ports.env")
    foreach ($envFile in $envFiles) {
        if (Test-Path $envFile) {
            $checks += @{
                Name = "Config: $envFile"
                Status = "OK"
                Message = "Configuration file exists"
            }
        } else {
            $checks += @{
                Name = "Config: $envFile"
                Status = "WARNING"
                Message = "Configuration file not found"
            }
        }
    }

    # 3. Check module integrity
    $modules = Get-AllModules
    $missingModules = @()
    foreach ($category in $modules.Keys) {
        foreach ($moduleName in $modules[$category]) {
            $scriptPath = Join-Path $ScriptDir "$moduleName.ps1"
            if (-not (Test-Path $scriptPath)) {
                $missingModules += "$category/$moduleName"
            }
        }
    }

    if ($missingModules.Count -eq 0) {
        $checks += @{
            Name = "Module Integrity"
            Status = "OK"
            Message = "All modules present"
        }
    } else {
        $checks += @{
            Name = "Module Integrity"
            Status = "WARNING"
            Message = "$($missingModules.Count) modules missing: $($missingModules -join ', ')"
        }
    }

    # 4. Check directory structure
    $directories = @("logs", "memory", "backup", "reports", "tasks")
    foreach ($dir in $directories) {
        if (Test-Path $dir) {
            $checks += @{
                Name = "Directory: $dir"
                Status = "OK"
                Message = "Directory exists"
            }
        } else {
            $checks += @{
                Name = "Directory: $dir"
                Status = "WARNING"
                Message = "Directory not found"
            }
        }
    }

    # 5. Check Git status
    $gitStatus = git status --porcelain 2>$null
    if ($LASTEXITCODE -eq 0) {
        if ($gitStatus -eq "") {
            $checks += @{
                Name = "Git Status"
                Status = "OK"
                Message = "Working tree clean"
            }
        } else {
            $checks += @{
                Name = "Git Status"
                Status = "WARNING"
                Message = "Working tree has changes"
            }
        }
    } else {
        $checks += @{
            Name = "Git Status"
            Status = "ERROR"
            Message = "Git not available"
        }
    }

    # Print check results
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
            Write-Host "      $($check.Message)" -ForegroundColor $(if ($check.Status -eq "ERROR") { "Red" } else { "DarkGray" })
        }
    }

    # Summary
    $okCount = ($checks | Where-Object { $_.Status -eq "OK" }).Count
    $warningCount = ($checks | Where-Object { $_.Status -eq "WARNING" }).Count
    $errorCount = ($checks | Where-Object { $_.Status -eq "ERROR" }).Count

    Write-Host "`nHealth Summary:" -ForegroundColor $ColorInfo
    Write-Host "  OK: $okCount" -ForegroundColor $ColorSuccess
    Write-Host "  WARNING: $warningCount" -ForegroundColor $ColorWarning
    Write-Host "  ERROR: $errorCount" -ForegroundColor $ColorError

    return ($errorCount -eq 0)
}

# Generate report
function Get-Report {
    Write-Header "System Integration Report" -Level 1

    $modules = Get-AllModules

    # System overview
    Write-Host "`n[System Overview]" -ForegroundColor $ColorHeader
    Write-Host "  Total Modules: $($modules.Common.Count + $modules.Performance.Count + $modules.Testing.Count)" -ForegroundColor $ColorInfo
    Write-Host "  Common Modules: $($modules.Common.Count)" -ForegroundColor $ColorInfo
    Write-Host "  Performance Modules: $($modules.Performance.Count)" -ForegroundColor $ColorInfo
    Write-Host "  Testing Modules: $($modules.Testing.Count)" -ForegroundColor $ColorInfo

    # Module categories
    Write-Host "`n[Module Categories]" -ForegroundColor $ColorHeader

    foreach ($category in $modules.Keys) {
        Write-Host "`n  $($category):" -ForegroundColor $ColorWarning
        foreach ($moduleName in $modules[$category]) {
            $moduleStatus = Get-ModuleStatus -ModuleName $moduleName
            if ($moduleStatus.Exists) {
                Write-Host "    - $($moduleName) ($($moduleStatus.SizeKB) KB)" -ForegroundColor $ColorSuccess
            } else {
                Write-Host "    - $($moduleName) (missing)" -ForegroundColor $ColorError
            }
        }
    }

    # Directory structure
    Write-Host "`n[Directory Structure]" -ForegroundColor $ColorHeader
    $directories = @(
        "logs",
        "memory",
        "backup",
        "reports",
        "tasks",
        "backups",
        "skills",
        "skill-integration"
    )

    foreach ($dir in $directories) {
        $exists = Test-Path $dir
        if ($exists) {
            $fileCount = (Get-ChildItem -Path $dir -Recurse -File 2>$null | Measure-Object).Count
            Write-Host "  [OK] $dir/ ($fileCount files)" -ForegroundColor $ColorSuccess
        } else {
            Write-Host "  [FAIL] $dir/ (not found)" -ForegroundColor $ColorError
        }
    }

    # Configuration files
    Write-Host "`n[Configuration Files]" -ForegroundColor $ColorHeader
    $configFiles = @(
        ".env",
        ".env.example",
        ".env-loader.ps1",
        ".ports.env",
        "AUTO_BACKUP_README.md",
        "MIGRATION_GUIDE.md",
        "README.md"
    )

    foreach ($file in $configFiles) {
        if (Test-Path $file) {
            $fileSize = [math]::Round((Get-Item $file).Length / 1KB, 2)
            Write-Host "  [OK] $file ($fileSize KB)" -ForegroundColor $ColorSuccess
        } else {
            Write-Host "  [FAIL] $file (not found)" -ForegroundColor $ColorError
        }
    }

    # Script statistics
    Write-Host "`n[Script Statistics]" -ForegroundColor $ColorHeader
    $allScripts = Get-ChildItem -Path $ScriptDir -Recurse -Filter "*.ps1"
    $totalSize = ($allScripts | Measure-Object -Property Length -Sum).Sum
    $fileCount = $allScripts.Count
    $lineCount = ($allScripts | ForEach-Object { (Get-Content $_.FullName | Measure-Object -Line).Lines } | Measure-Object -Sum).Sum

    Write-Host "  Total Scripts: $fileCount" -ForegroundColor $ColorInfo
    Write-Host "  Total Size: $([math]::Round($totalSize / 1MB, 2)) MB" -ForegroundColor $ColorInfo
    Write-Host "  Total Lines: $lineCount" -ForegroundColor $ColorInfo

    # Cron tasks
    Write-Host "`n[Scheduled Tasks]" -ForegroundColor $ColorHeader
    try {
        $cronJobs = cron -action list -includeDisabled false 2>$null | ConvertFrom-Json
        if ($cronJobs.jobs.Count -gt 0) {
            Write-Host "  Active Cron Jobs: $($cronJobs.jobs.Count)" -ForegroundColor $ColorInfo
            foreach ($job in $cronJobs.jobs) {
                Write-Host "    - $($job.name) (next: $($job.state.nextRunAtMs))" -ForegroundColor $ColorSuccess
            }
        } else {
            Write-Host "  No active cron jobs" -ForegroundColor $ColorWarning
        }
    } catch {
        Write-Host "  Cron status: Unknown" -ForegroundColor $ColorWarning
    }

    # Git info
    Write-Host "`n[Git Repository]" -ForegroundColor $ColorHeader
    try {
        $gitBranch = git branch --show-current 2>$null
        $gitStatus = git status --porcelain 2>$null

        if ($LASTEXITCODE -eq 0) {
            Write-Host "  Branch: $gitBranch" -ForegroundColor $ColorInfo

            if ($gitStatus -eq "") {
                Write-Host "  Status: Clean" -ForegroundColor $ColorSuccess
            } else {
                Write-Host "  Status: Modified" -ForegroundColor $ColorWarning
            }

            $commits = git log --oneline -5 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  Recent Commits:" -ForegroundColor $ColorInfo
                $commits.Split("`n") | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
            }
        }
    } catch {
        Write-Host "  Git status: Not available" -ForegroundColor $ColorWarning
    }

    Write-Host "`n" + ("=" * 50) -ForegroundColor $ColorHeader
}

# Main entry point
function Main {
    Write-ColorOutput "`nOpenClaw Unified Integration Manager v1.0" -Color $ColorHeader
    Write-ColorOutput "Starting at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Color $ColorInfo

    try {
        switch ($Action) {
            "start" {
                Start-AllModules
            }
            "stop" {
                Stop-AllModules
            }
            "status" {
                Get-Status
            }
            "modules" {
                Get-Report
            }
            "test" {
                Test-AllModules
            }
            "health" {
                Get-Health
            }
            "report" {
                Get-Report
            }
        }

        Write-ColorOutput "`nDone!" -Color $ColorSuccess
    } catch {
        Write-ColorOutput "`nError: $_" -Color $ColorError
        Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
        exit 1
    }
}

# Execute
Main
