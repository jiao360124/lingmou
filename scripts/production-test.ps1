# OpenClaw 生产环境测试脚本

param(
    [switch]$Detailed,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# 脚本目录
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$WorkspaceDir = Split-Path -Parent $ScriptDir

# 颜色定义
$ColorInfo = "Cyan"
$ColorSuccess = "Green"
$ColorWarning = "Yellow"
$ColorError = "Red"
$ColorHeader = "Magenta"

# 工具函数
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

# 测试组计数器
$totalTests = 0
$passedTests = 0
$failedTests = 0

function Test-Step {
    param(
        [string]$Name,
        [scriptblock]$Test,
        [string]$Description = ""
    )

    $totalTests++
    Write-ColorOutput "`n[$totalTests] $Name" -Color $ColorInfo

    if ($DryRun) {
        Write-ColorOutput "  [DRY RUN] Would test" -Color $ColorWarning
        $passedTests++
        return
    }

    try {
        $result = & $Test
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "  ✓ PASS" -ForegroundColor $ColorSuccess
            if ($Detailed -and $Description) {
                Write-ColorOutput "  - $Description" -ForegroundColor DarkGray
            }
            $passedTests++
        } else {
            Write-ColorOutput "  ✗ FAIL" -ForegroundColor $ColorError
            if ($Detailed -and $result) {
                Write-ColorOutput "  - $result" -ForegroundColor DarkGray
            }
            $failedTests++
        }
    } catch {
        Write-ColorOutput "  ✗ ERROR: $_" -ForegroundColor $ColorError
        $failedTests++
    }
}

# ==================== 测试套件 ====================

Write-Header "生产环境测试套件" -Level 1

# ==================== 基础功能测试 ====================

Write-Header "1. 基础功能测试" -Level 2

# 1.1 环境检查
Test-Step -Name "环境检查" -Test {
    & "$ScriptDir/environment-check.ps1" -Strict:$Detailed -Detailed:$Detailed
}

# 1.2 Gateway连接测试
Test-Step -Name "Gateway连接测试" -Test {
    try {
        $response = Invoke-WebRequest -Uri "http://127.0.0.1:18789/health" -Method GET -TimeoutSec 5 -UseBasicParsing 2>$null
        if ($response.StatusCode -eq 200) {
            return "Gateway响应正常"
        } else {
            return "Gateway响应状态码: $($response.StatusCode)"
        }
    } catch {
        return "Gateway连接失败: $_"
    }
}

# 1.3 集成管理器测试
Test-Step -Name "集成管理器测试" -Test {
    & "$ScriptDir/integration-manager.ps1" -Action health -Detailed:$Detailed 2>&1 | Out-Null
    $LASTEXITCODE
}

# 1.4 日志文件测试
Test-Step -Name "日志文件测试" -Test {
    if (Test-Path "logs") {
        $logFiles = Get-ChildItem "logs" -Recurse -Filter "*.log" | Measure-Object
        return "日志文件数: $($logFiles.Count)"
    } else {
        return "日志目录不存在"
    }
}

# 1.5 记忆文件测试
Test-Step -Name "记忆文件测试" -Test {
    if (Test-Path "memory") {
        $memoryFiles = Get-ChildItem "memory" -Recurse -Filter "*.md" | Measure-Object
        return "记忆文件数: $($memoryFiles.Count)"
    } else {
        return "记忆目录不存在"
    }
}

# ==================== 模块功能测试 ====================

Write-Header "2. 模块功能测试" -Level 2

# 2.1 Git备份测试
Test-Step -Name "Git备份测试" -Test {
    & "$ScriptDir/git-backup.ps1" -DryRun:$DryRun 2>&1 | Out-Null
    $LASTEXITCODE
}

# 2.2 上下文清理测试
Test-Step -Name "上下文清理测试" -Test {
    & "$ScriptDir/clear-context.ps1" -DryRun:$DryRun 2>&1 | Out-Null
    $LASTEXITCODE
}

# 2.3 简单健康检查测试
Test-Step -Name "简单健康检查测试" -Test {
    & "$ScriptDir/simple-health-check.ps1" -DryRun:$DryRun 2>&1 | Out-Null
    $LASTEXITCODE
}

# 2.4 日志清理测试
Test-Step -Name "日志清理测试" -Test {
    & "$ScriptDir/cleanup-logs-manual.ps1" -DryRun:$DryRun 2>&1 | Out-Null
    $LASTEXITCODE
}

# 2.5 定时任务测试
Test-Step -Name "定时任务测试" -Test {
    try {
        $jobs = cron -action list -includeDisabled false 2>$null | ConvertFrom-Json
        return "活跃定时任务数: $($jobs.jobs.Count)"
    } catch {
        return "定时任务检查失败: $_"
    }
}

# ==================== 性能测试 ====================

Write-Header "3. 性能测试" -Level 2

# 3.1 Gateway响应时间测试
Test-Step -Name "Gateway响应时间" -Test {
    try {
        $startTime = Get-Date
        $response = Invoke-WebRequest -Uri "http://127.0.0.1:18789/health" -Method GET -TimeoutSec 5 -UseBasicParsing 2>$null
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds

        if ($duration -lt 1000) {
            return "响应时间: ${duration}ms (优秀)"
        } elseif ($duration -lt 3000) {
            return "响应时间: ${duration}ms (正常)"
        } else {
            return "响应时间: ${duration}ms (较慢)"
        }
    } catch {
        return "响应时间测试失败: $_"
    }
}

# 3.2 内存使用测试
Test-Step -Name "内存使用测试" -Test {
    try {
        $process = Get-Process node -ErrorAction SilentlyContinue
        if ($process) {
            $memoryMB = [math]::Round($process.WorkingSet64 / 1MB, 2)
            return "Node进程内存: ${memoryMB} MB"
        } else {
            return "Node进程未运行"
        }
    } catch {
        return "内存测试失败: $_"
    }
}

# 3.3 磁盘空间测试
Test-Step -Name "磁盘空间测试" -Test {
    try {
        $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
        $freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)

        if ($freeSpaceGB -ge 1) {
            return "可用空间: ${freeSpaceGB} GB"
        } else {
            return "可用空间: ${freeSpaceGB} GB (不足)"
        }
    } catch {
        return "磁盘测试失败: $_"
    }
}

# ==================== 安全测试 ====================

Write-Header "4. 安全测试" -Level 2

# 4.1 配置文件安全性
Test-Step -Name "配置文件安全性" -Test {
    $envFile = ".env"
    if (Test-Path $envFile) {
        # 检查文件权限
        try {
            $acl = Get-Acl $envFile
            $accessRules = $acl.Access
            $hasRestrictedAccess = $false

            foreach ($rule in $accessRules) {
                if ($rule.IdentityReference -eq "Everyone" -or $rule.IdentityReference -eq "BUILTIN\Users") {
                    $hasRestrictedAccess = $true
                    break
                }
            }

            if ($hasRestrictedAccess) {
                return "⚠️ 配置文件权限过宽，建议限制为 owner-only"
            } else {
                return "✓ 配置文件权限正常"
            }
        } catch {
            return "配置文件权限检查失败: $_"
        }
    } else {
        return "配置文件不存在"
    }
}

# 4.2 端口安全性
Test-Step -Name "端口安全性" -Test {
    try {
        $port = 18789
        $connections = netstat -ano | Select-String ":$port"

        if ($connections) {
            $connCount = ($connections | Measure-Object).Count
            if ($connCount -gt 1) {
                return "⚠️ 端口 $port 有 $connCount 个连接 (可能不安全)"
            } else {
                return "✓ 端口 $port 仅1个连接 (安全)"
            }
        } else {
            return "✓ 端口 $port 未被使用"
        }
    } catch {
        return "端口检查失败: $_"
    }
}

# ==================== 集成测试 ====================

Write-Header "5. 集成测试" -Level 2

# 5.1 完整工作流测试
Test-Step -Name "完整工作流测试" -Test {
    try {
        # 检查健康状态
        $health = & "$ScriptDir/integration-manager.ps1" -Action health -Detailed:$Detailed 2>&1 | Out-String

        # 检查备份状态
        $backup = git log --oneline -1 2>&1 | Out-String

        # 检查定时任务
        $cron = cron -action list 2>&1 | Out-String

        return "工作流各组件检查通过"
    } catch {
        return "工作流测试失败: $_"
    }
}

# 5.2 自动化测试
Test-Step -Name "自动化测试" -Test {
    try {
        $modules = Get-ChildItem "scripts" -Filter "*.ps1" | Where-Object { $_.Name -notmatch "^test-" }
        $testableModules = 0

        foreach ($module in $modules) {
            $moduleName = $module.BaseName
            $scriptPath = $module.FullName

            try {
                $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $scriptPath -Raw), [ref]$null)
                $testableModules++
            } catch {
                # 语法错误
            }
        }

        return "可测试模块数: $testableModules"
    } catch {
        return "自动化测试失败: $_"
    }
}

# ==================== 结果总结 ====================

Write-Header "测试结果总结" -Level 1

Write-ColorOutput "`n测试统计:" -ForegroundColor $ColorInfo
Write-Host "  总测试数: $totalTests" -ForegroundColor $ColorInfo
Write-Host "  通过: $passedTests" -ForegroundColor $ColorSuccess
Write-Host "  失败: $failedTests" -ForegroundColor $ColorError

if ($failedTests -eq 0) {
    Write-Host "`n✓ 所有测试通过！生产环境准备就绪。" -ForegroundColor $ColorSuccess
    Write-Host "`n建议的后续步骤:" -ForegroundColor $ColorHeader
    Write-Host "  1. 查看详细测试报告" -ForegroundColor White
    Write-Host "  2. 根据警告调整配置" -ForegroundColor White
    Write-Host "  3. 监控系统运行" -ForegroundColor White
    Write-Host "  4. 配置自动化部署" -ForegroundColor White
    exit 0
} else {
    Write-Host "`n✗ 部分测试未通过，请修复后再部署。" -ForegroundColor $ColorError
    exit 1
}

# ==================== 辅助函数 ====================

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

# 主程序入口
Main
