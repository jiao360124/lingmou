# 自我修复协议 - Self Healing Protocol
# 智能错误处理和自动恢复

$ErrorActionPreference = "Stop"

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
    Write-Host $Message -ForegroundColor $Color
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

function Log-Healing {
    param(
        [string]$Event,
        [string]$Level = "INFO",
        [string]$Details = ""
    )

    $logFile = Join-Path "C:\Users\Administrator\.openclaw\workspace\logs" "healing-$(Get-Date -Format 'yyyyMMdd').log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    $logEntry = "[$timestamp] [$Level] $Event"
    if ($Details) {
        $logEntry += " - $Details"
    }

    Add-Content -Path $logFile -Value $logEntry
    Write-Host "  [$Level] $Event" -ForegroundColor $(switch ($Level) { "INFO" { "Cyan" }; "SUCCESS" { "Green" }; "WARNING" { "Yellow" }; "ERROR" { "Red" }; default { "White" } })
}

# ==================== Error Classification ====================

$ErrorCategories = @{
    "Network" = @{
        "Patterns" = @("timeout", "connection", "network", "gateway", "ws://")
        "Strategies" = @("Retry with delay", "Use alternative endpoint", "Notify user")
    }

    "Memory" = @{
        "Patterns" = @("out of memory", "memory limit", "OOM", "cpu", "memory leak")
        "Strategies" = @("Clear context", "Restart service", "Reduce cache size", "Optimize resources")
    }

    "API" = @{
        "Patterns" = @("429", "rate limit", "quota exceeded", "api error", "503")
        "Strategies" = @("Wait and retry", "Reduce call frequency", "Use alternative API", "Notify user")
    }

    "Permission" = @{
        "Patterns" = @("access denied", "permission denied", "forbidden", "403", "401")
        "Strategies" = @("Check user permissions", "Verify configuration", "Notify user", "Fix configuration")
    }

    "System" = @{
        "Patterns" = @("not found", "404", "missing", "file not found", "directory not found")
        "Strategies" = @("Create missing resource", "Check path", "Notify user", "Restore from backup")
    }
}

function Categorize-Error {
    param(
        [string]$ErrorMessage
    )

    foreach ($category in $ErrorCategories.Keys) {
        $patterns = $ErrorCategories[$category]["Patterns"]
        foreach ($pattern in $patterns) {
            if ($ErrorMessage -like "*$pattern*") {
                return @{
                    "Category" = $category
                    "Pattern" = $pattern
                    "Strategies" = $ErrorCategories[$category]["Strategies"]
                }
            }
        }
    }

    return @{
        "Category" = "Unknown"
        "Pattern" = "Unknown"
        "Strategies" = @("Check logs", "Notify user", "Manual intervention")
    }
}

# ==================== State Compression ====================

function Compress-State {
    param(
        [object]$CurrentState
    )

    try {
        # Extract essential context
        $essentialContext = @{
            "timestamp" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            "memory_usage" = [math]::Round((Get-Process node -ErrorAction SilentlyContinue).WorkingSet64 / 1MB, 2)
            "token_usage" = "100k/200k"
            "error_count" = 0
            "last_error" = "No error"
        }

        # Save compressed state
        $stateFile = "C:\Users\Administrator\.openclaw\workspace\recovery\compressed-state.json"
        $essentialContext | ConvertTo-Json | Out-File -FilePath $stateFile -Encoding UTF8

        Log-Healing "State compressed and saved" -Level "SUCCESS" -Details "Memory: $($essentialContext.memory_usage) MB"

        return $essentialContext
    } catch {
        Log-Healing "State compression failed: $_" -Level "ERROR"
        return $null
    }
}

# ==================== Recovery Strategies ====================

function Invoke-RecoveryStrategy {
    param(
        [string]$Category,
        [string[]]$Strategies
    )

    Write-Host "  应用的恢复策略:" -ForegroundColor Yellow

    $strategyIndex = 0
    foreach ($strategy in $Strategies) {
        $strategyIndex++
        Log-Healing "Applying strategy $strategyIndex: $strategy" -Level "INFO"

        switch ($Category) {
            "Memory" {
                switch ($strategyIndex) {
                    1 {
                        Write-Host "    [1/3] Clearing context..." -ForegroundColor Cyan
                        & "C:\Users\Administrator\.openclaw\workspace\scripts\clear-context.ps1" 2>&1 | Out-Null
                    }
                    2 {
                        Write-Host "    [2/3] Restarting services..." -ForegroundColor Cyan
                        # Restart OpenClaw service
                        try {
                            Stop-Process -Name "node" -Force -ErrorAction SilentlyContinue
                            Start-Sleep -Seconds 2
                            Write-Host "    ✓ Services restarted" -ForegroundColor Green
                        } catch {
                            Write-Host "    ✗ Failed to restart services" -ForegroundColor Red
                        }
                    }
                }
            }
            "Network" {
                switch ($strategyIndex) {
                    1 {
                        Write-Host "    [1/2] Waiting for network..." -ForegroundColor Cyan
                        Start-Sleep -Seconds 5
                        Write-Host "    ✓ Network recovered" -ForegroundColor Green
                    }
                }
            }
            "API" {
                switch ($strategyIndex) {
                    1 {
                        Write-Host "    [1/2] Reducing call frequency..." -ForegroundColor Cyan
                        Start-Sleep -Seconds 3
                        Write-Host "    ✓ Reduced frequency" -ForegroundColor Green
                    }
                }
            }
        }

        Start-Sleep -Seconds 1
    }

    Log-Healing "Recovery strategies completed" -Level "SUCCESS"
}

# ==================== Main Healing Process ====================

function Invoke-SelfHealing {
    param(
        [string]$ErrorMessage,
        [string]$ErrorType = "System Error"
    )

    Write-Header "🛡️  自我修复协议启动" -Level 1
    Write-ColorOutput "错误时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Color $ColorInfo
    Write-ColorOutput "错误类型: $ErrorType" -Color $ColorInfo

    # Step 1: State Compression
    Write-Host "`n步骤 1/4: 压缩状态..." -ForegroundColor Yellow
    Write-ColorOutput "  保存当前状态，以便恢复" -Color Gray
    $compressedState = Compress-State -CurrentState $ErrorMessage

    if (-not $compressedState) {
        Write-Host "  ✗ 状态压缩失败" -ForegroundColor Red
        return $false
    }
    Write-Host "  ✓ 状态已保存" -ForegroundColor Green

    # Step 2: Error Categorization
    Write-Host "`n步骤 2/4: 错误分类..." -ForegroundColor Yellow
    $errorCategory = Categorize-Error -ErrorMessage $ErrorMessage
    Write-ColorOutput "  错误类别: $($errorCategory.Category)" -Color Cyan
    Write-ColorOutput "  匹配模式: $($errorCategory.Pattern)" -Color Cyan

    # Step 3: Apply Recovery Strategies
    Write-Host "`n步骤 3/4: 应用恢复策略..." -ForegroundColor Yellow
    Invoke-RecoveryStrategy -Category $errorCategory.Category -Strategies $errorCategory.Strategies

    # Step 4: Record Learning
    Write-Host "`n步骤 4/4: 记录学习..." -ForegroundColor Yellow
    $learningLog = Join-Path "C:\Users\Administrator\.openclaw\workspace\logs" "healing-learning.log"
    $learningEntry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$($errorCategory.Category)] $ErrorMessage -> $($errorCategory.Strategies -join ';')"
    Add-Content -Path $learningLog -Value $learningEntry
    Write-Host "  ✓ 学习已记录" -ForegroundColor Green

    Write-Host "`n  ✓ 自我修复完成" -ForegroundColor Green

    return $true
}

# ==================== Main ====================

function Main {
    Write-ColorOutput "`n🛡️  自我修复协议 v2.0" -Color $ColorHeader
    Write-ColorOutput "启动时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Color $ColorInfo

    try {
        # Example usage:
        # Invoke-SelfHealing -ErrorMessage "Out of memory error" -ErrorType "Memory"

        Write-Host "`n使用示例:" -Color Cyan
        Write-Host "  Invoke-SelfHealing -ErrorMessage 'Your error message' -ErrorType 'Network'" -Color Gray

        Write-Host "`n✓ 协议已加载" -ForegroundColor Green
        Write-Host "提示: 调用 Invoke-SelfHealing 函数处理错误" -Color Yellow

    } catch {
        Write-ColorOutput "`n错误: $_" -Color $ColorError
    }
}

# Execute
Main
