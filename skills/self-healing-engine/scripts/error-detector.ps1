# 自我修复 - 错误检测器

param(
    [string]$LogPath = ".logs",
    [int]$Interval = 60,
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"

# 配置
$config = Get-Content ".config/self-healing.json" -ErrorAction SilentlyContinue | ConvertFrom-Json
if (-not $config) {
    $config = @{
        enabled = $true
        checkCommands = @("git", "npm", "powershell")
        alertOnErrors = $true
        autoRetry = $true
        retryAttempts = 3
        retryDelay = 5000
    }
}

# 日志目录
if (-not (Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}

# 错误记录文件
$errorLogFile = Join-Path $LogPath "errors-$(Get-Date -Format 'yyyy-MM-dd').log"
$snapshotDir = Join-Path $LogPath "snapshots"
$learningDir = Join-Path $LogPath "learnings"

if (-not (Test-Path $snapshotDir)) {
    New-Item -ItemType Directory -Path $snapshotDir -Force | Out-Null
}

if (-not (Test-Path $learningDir)) {
    New-Item -ItemType Directory -Path $learningDir -Force | Out-Null
}

# 错误分类
function Get-ErrorCategory {
    param([string]$errorMessage)

    if ($errorMessage -match "timeout|timed out|超时") {
        return "timeout"
    }
    elseif ($errorMessage -match "network|connection|连接") {
        return "network"
    }
    elseif ($errorMessage -match "permission|access|权限") {
        return "permission"
    }
    elseif ($errorMessage -match "not found|404|未找到") {
        return "not-found"
    }
    elseif ($errorMessage -match "failed|失败") {
        return "general"
    }
    else {
        return "unknown"
    }
}

# 记录错误
function Write-ErrorLog {
    param(
        [string]$Message,
        [string]$Category = "general",
        [string]$Command = $null,
        [string]$Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    )

    $errorEntry = @{
        timestamp = $Timestamp
        message = $Message
        category = $Category
        command = $Command
        status = "pending"
        attempts = 0
    }

    $errors = @()
    if (Test-Path $errorLogFile) {
        $errors = Get-Content $errorLogFile | ConvertFrom-Json
    }

    $errors += $errorEntry
    $errors | ConvertTo-Json -Depth 10 | Set-Content $errorLogFile

    Write-Host "❌ [ERROR] $($Timestamp) - $Message" -ForegroundColor Red

    # 智能分类和响应
    if ($config.alertOnErrors) {
        $categoryName = switch ($Category) {
            "timeout" { "⏱️ 超时错误" }
            "network" { "🌐 网络错误" }
            "permission" { "🔒 权限错误" }
            "not-found" { "❓ 未找到" }
            default { "❌ 通用错误" }
        }
        Write-Host "   分类: $categoryName" -ForegroundColor Yellow

        # 自动记录到学习系统
        if ($config.autoRetry) {
            Write-Host "   自动重试: $($config.retryAttempts) 次" -ForegroundColor Gray
        }
    }

    return $errorEntry
}

# 检测命令执行错误
function Invoke-CommandWithDetection {
    param(
        [string]$Command,
        [string]$Description
    )

    Write-Host "🔍 检测命令: $Description" -ForegroundColor Cyan
    Write-Host "   命令: $Command" -ForegroundColor Gray

    try {
        $result = Invoke-Expression $Command 2>&1
        if ($LASTEXITCODE -ne 0 -or $result -match "error|Error|失败|失败") {
            Write-ErrorLog -Message "命令执行失败: $Description" -Command $Command
            return $false
        }
        else {
            Write-Host "   ✅ 命令成功" -ForegroundColor Green
            return $true
        }
    }
    catch {
        Write-ErrorLog -Message "异常: $($_.Exception.Message)" -Command $Command
        return $false
    }
}

# 检查学习记录（避免重复）
function Test-DuplicateError {
    param([string]$Message)

    if (Test-Path $errorLogFile) {
        $errors = Get-Content $errorLogFile | ConvertFrom-Json -ErrorAction SilentlyContinue
        foreach ($error in $errors) {
            if ($error.message -like "*$Message*" -and $error.status -eq "pending") {
                Write-Host "⚠️  检测到重复错误: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
                return $true
            }
        }
    }
    return $false
}

# 智能检测 - 主循环
function Start-ErrorDetection {
    Write-Host "`n🔍 自我修复 - 错误检测器启动" -ForegroundColor Cyan
    Write-Host "   监控间隔: $Interval 秒" -ForegroundColor Gray
    Write-Host "   日志目录: $LogPath`n" -ForegroundColor Gray

    $checkCount = 0

    while ($true) {
        $checkCount++

        # 1. 检查Gateway状态
        $checkCount++
        if (Test-Command "openclaw status") {
            Invoke-CommandWithDetection `
                -Command "openclaw status" `
                -Description "Gateway状态检查"

            # 检查Token使用
            $status = Invoke-Expression "openclaw status" 2>&1
            if ($status -match "Tokens.*100%") {
                Write-Host "⚠️  警告: Token使用率达到100%" -ForegroundColor Red
                Write-ErrorLog -Message "Token使用率达到100%，建议重启会话" -Category "warning"
            }
        }

        # 2. 检查Git状态
        if (Test-Command "git status") {
            $checkCount++
            $gitStatus = git status --short 2>&1
            if ($gitStatus -and -not $gitStatus -match "nothing to commit") {
                Write-Host "📝 检测到Git变更" -ForegroundColor Yellow
                Write-ErrorLog -Message "检测到Git未提交的变更" -Category "warning"
            }
        }

        # 3. 检查日志文件大小
        $checkCount++
        $logFiles = Get-ChildItem -Path $LogPath -Filter "*.log" -ErrorAction SilentlyContinue
        foreach ($log in $logFiles) {
            if ($log.Length -gt 10MB) {
                Write-Host "💾 警告: 日志文件过大 ($($log.Length / 1MB) MB)" -ForegroundColor Yellow
                Write-ErrorLog -Message "日志文件过大: $($log.Name)" -Category "warning"
            }
        }

        # 4. 检查学习记录中的pending项目
        $checkCount++
        $pendingErrors = @()
        if (Test-Path $errorLogFile) {
            $errors = Get-Content $errorLogFile | ConvertFrom-Json -ErrorAction SilentlyContinue
            foreach ($error in $errors) {
                if ($error.status -eq "pending") {
                    $pendingErrors += $error
                }
            }

            if ($pendingErrors.Count -gt 0) {
                Write-Host "⏳ 发现 $pendingErrors.Count 个待处理错误" -ForegroundColor Yellow
                Write-ErrorLog -Message "发现 $($pendingErrors.Count) 个待处理错误" -Category "warning"

                # 自动触发修复
                foreach ($error in $pendingErrors) {
                    Write-Host "`n🔧 尝试修复错误: $($error.category)" -ForegroundColor Cyan
                    .\auto-fix.ps1 -ErrorId $error.timestamp

                    # 更新状态
                    $error.status = "fixing"
                    Get-Content $errorLogFile | ConvertFrom-Json | ConvertTo-Json -Depth 10 | Set-Content $errorLogFile
                }
            }
        }

        # 5. 定期维护
        if ($checkCount % $Interval -eq 0) {
            Write-Host "`n🔄 定期维护检查" -ForegroundColor Cyan

            # 清理旧快照
            $oldSnapshots = Get-ChildItem -Path $snapshotDir -Filter "*.snapshot.*" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$config.snapshotRetention) }
            foreach ($snap in $oldSnapshots) {
                Remove-Item $snap.FullName -Force
                Write-Host "   🗑️  清理旧快照: $($snap.Name)" -ForegroundColor Gray
            }
        }

        # 等待下次检查
        Start-Sleep -Seconds $Interval
    }
}

# 停止检测
function Stop-ErrorDetection {
    Write-Host "`n🛑 错误检测器停止" -ForegroundColor Yellow
    exit
}

# 主程序
if ($Verbose) {
    $VerbosePreference = "Continue"
}

Write-Host "`n🦞 自我修复引擎 - 错误检测器" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Gray

switch ($Action) {
    "start" {
        Start-ErrorDetection
    }
    "stop" {
        Stop-ErrorDetection
    }
    "check" {
        Write-Host "`n🔍 快速检查..." -ForegroundColor Cyan

        # 检查Gateway
        Invoke-CommandWithDetection -Command "openclaw status" -Description "Gateway状态"

        # 检查Token
        $status = Invoke-Expression "openclaw status" 2>&1
        if ($status -match "Tokens.*100%") {
            Write-Host "⚠️  Token使用率达到100%" -ForegroundColor Red
        }

        # 统计pending错误
        $pendingCount = 0
        if (Test-Path $errorLogFile) {
            $errors = Get-Content $errorLogFile | ConvertFrom-Json -ErrorAction SilentlyContinue
            foreach ($error in $errors) {
                if ($error.status -eq "pending") { $pendingCount++ }
            }
        }

        Write-Host "   待处理错误: $pendingCount" -ForegroundColor $(if ($pendingCount -gt 0) { "Yellow" } else { "Green" })
    }
    default {
        Write-Host "用法:" -ForegroundColor Yellow
        Write-Host "  ./error-detector.ps1 -Action start       # 启动监控" -ForegroundColor White
        Write-Host "  ./error-detector.ps1 -Action stop        # 停止监控" -ForegroundColor White
        Write-Host "  ./error-detector.ps1 -Action check        # 快速检查" -ForegroundColor White
        Write-Host "  ./error-detector.ps1 -Action check -Verbose  # 详细检查" -ForegroundColor White
    }
}

Write-Host "`n" -NoNewline
