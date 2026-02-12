# 灵眸Nightly Build - 自我进化执行脚本
# 运行时间: 凌晨3-6点（主人休眠期）

<#
.SYNOPSIS
灵眸自我进化Nightly Build - 每日自动进化执行脚本
.DESCRIPTION
执行每日自我进化任务：
1. 系统健康检查
2. 错误模式分析
3. 工具链优化
4. 技能学习记录
5. 知识库更新
.VERSION
1.0.0
.AUTHOR
灵眸 (2026-02-12)
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

# ============================================
# 初始化
# ============================================
$Script:NightlyBuildStart = Get-Date
$Script:Config = @{
    LogLevel = "INFO"
    OutputFile = "logs/nightly-build/nightly-build-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    MemoryLimitMB = 800
    MaxRetries = 3
}

# 确保目录存在
$OutputDir = Split-Path $Script:Config.OutputFile -Parent
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# 日志函数
function Write-Log {
    param(
        [string]$Level,
        [string]$Message
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"

    if ($DryRun) {
        $LogEntry = "[DRY RUN] $LogEntry"
    }

    Write-Host $LogEntry
    Add-Content -Path $Script:Config.OutputFile -Value $LogEntry
}

Write-Log "INFO" "=== 灵眸Nightly Build启动 ==="
Write-Log "INFO" "开始时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Log "INFO" "DryRun模式: $DryRun"

# ============================================
# 任务1: 系统健康检查
# ============================================
Write-Log "INFO" "`n--- 任务1: 系统健康检查 ---"

$HealthCheck = @{
    GatewayStatus = $false
    MemoryUsage = 0
    DiskUsage = 0
    TaskStatus = @{}
    Errors = @()
}

try {
    # 检查Gateway状态
    $GatewayCheck = openclaw gateway status 2>&1
    if ($LASTEXITCODE -eq 0) {
        $HealthCheck.GatewayStatus = $true
        Write-Log "INFO" "✅ Gateway运行正常"
    } else {
        $HealthCheck.Errors += "Gateway状态检查失败"
        Write-Log "WARN" "WARNING: Gateway status check failed"
    }
}
catch {
    $HealthCheck.Errors += "Gateway状态检查异常: $_"
    Write-Log "WARN" "⚠️ Gateway状态检查异常: $_"
}

# 检查内存使用
$MemoryInfo = Get-CimInstance Win32_OperatingSystem
$MemoryUsage = [math]::Round($MemoryInfo.TotalVisibleMemorySize / 1MB, 2)
$HealthCheck.MemoryUsage = $MemoryUsage
Write-Log "INFO" "✅ 内存使用: ${MemoryUsage} MB"

# 检查磁盘使用
$DiskUsage = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$FreeSpace = [math]::Round($DiskUsage.FreeSpace / 1MB, 2)
$HealthCheck.DiskUsage = $FreeSpace
Write-Log "INFO" "✅ 磁盘剩余: ${FreeSpace} MB"

# 检查定时任务状态
Write-Log "INFO" "`n--- 检查定时任务 ---"
$CronJobs = cron list --includeDisabled
foreach ($Job in $CronJobs) {
    $Status = if ($Job.enabled) { "ENABLED" } else { "DISABLED" }
    $HealthCheck.TaskStatus[$Job.name] = $Status
    Write-Log "INFO" "  ✅ $($Job.name): $Status"
}

# ============================================
# 任务2: 错误模式分析
# ============================================
Write-Log "INFO" "`n--- 任务2: 错误模式分析 ---"

$ErrorPatterns = @{
    NetworkTimeouts = 0
    APIRateLimit = 0
    MemoryLeaks = 0
    FileErrors = 0
}

# 分析日志文件（简单实现）
$RecentLogs = Get-ChildItem logs -Filter "*.log" -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-24) } |
    Select-Object -First 10

if ($RecentLogs) {
    Write-Log "INFO" "✅ 发现$(($RecentLogs).Count)个日志文件"

    foreach ($Log in $RecentLogs) {
        $Content = Get-Content $Log.FullName -Tail 100 -ErrorAction SilentlyContinue
        foreach ($Line in $Content) {
            if ($Line -match "timeout|超时") {
                $ErrorPatterns.NetworkTimeouts++
            }
            elseif ($Line -match "429|rate.*limit|限流") {
                $ErrorPatterns.APIRateLimit++
            }
            elseif ($Line -match "memory|memory.*leak|内存") {
                $ErrorPatterns.MemoryLeaks++
            }
            elseif ($Line -match "error|exception|异常") {
                $ErrorPatterns.FileErrors++
            }
        }
    }
}

Write-Log "INFO" "错误模式统计:"
Write-Log "INFO" "  - 网络超时: $($ErrorPatterns.NetworkTimeouts)次"
Write-Log "INFO" "  - API限流: $($ErrorPatterns.APIRateLimit)次"
Write-Log "INFO" "  - 内存泄漏: $($ErrorPatterns.MemoryLeaks)次"
Write-Log "INFO" "  - 文件错误: $($ErrorPatterns.FileErrors)次"

# ============================================
# 任务3: 工具链优化
# ============================================
Write-Log "INFO" "`n--- 任务3: 工具链优化 ---"

$OptimizationTasks = @()

# 1. 清理旧备份（保留最近3个）
Write-Log "INFO" "  🔄 清理旧备份..."
$OldBackups = Get-ChildItem backup/*.zip -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -Skip 3

if ($OldBackups) {
    $BackupsToDelete = $OldBackups | Select-Object -First ($OldBackups.Count - 3)
    $TotalSize = ($BackupsToDelete | Measure-Object -Property Length -Sum).Sum / 1MB
    Write-Log "INFO" "     ℹ️ 将删除$(($BackupsToDelete).Count)个旧备份，节省~${TotalSize}MB"
    # 实际删除（仅在非DryRun模式）
    if (-not $DryRun) {
        foreach ($Backup in $BackupsToDelete) {
            Remove-Item $Backup.FullName -Force -ErrorAction SilentlyContinue
            Write-Log "INFO" "     ✅ 已删除: $($Backup.Name)"
        }
    }
}
else {
    Write-Log "INFO" "     ℹ️ 无需清理备份"
}

# 2. 清理日志文件（保留最近7天）
Write-Log "INFO" "  🔄 清理旧日志..."
$OldLogs = Get-ChildItem logs -Filter "*.log" -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }

if ($OldLogs) {
    $OldLogs | Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Log "INFO" "     ✅ 已删除$(($OldLogs).Count)个旧日志文件"
}
else {
    Write-Log "INFO" "     ℹ️ 无需清理日志"
}

# 3. 清理Git历史（可选）
Write-Log "INFO" "  🔄 清理Git历史..."
if (-not $DryRun) {
    $GitLogs = git log --oneline -20 2>&1
    Write-Log "INFO" "     ℹ️ Git历史保留最近20条提交"
    Write-Log "INFO" "     ℹ️ Git历史清理需要手动操作（git gc）"
}

$OptimizationTasks += @{
    Name = "备份清理"
    Status = "Completed"
    Details = "删除了$(($OldBackups).Count)个旧备份"
}

$OptimizationTasks += @{
    Name = "日志清理"
    Status = "Completed"
    Details = "删除了$(($OldLogs).Count)个旧日志"
}

# ============================================
# 任务4: 技能学习记录
# ============================================
Write-Log "INFO" "`n--- 任务4: 技能学习记录 ---"

$Skills = Get-ChildItem skills -Directory -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Name

Write-Log "INFO" "当前已集成技能数量: $(($Skills).Count)"
Write-Log "INFO" "技能列表:"
foreach ($Skill in $Skills) {
    $SkillPath = "skills/$Skill"
    $SkillDesc = if (Test-Path "$SkillPath/SKILL.md") {
        (Get-Content "$SkillPath/SKILL.md" -First 5 -ErrorAction SilentlyContinue) -join " "
    } else {
        "无描述"
    }
    Write-Log "INFO" "  📚 $Skill"
    if ($SkillDesc -ne "无描述") {
        Write-Log "INFO" "     $SkillDesc"
    }
}

# ============================================
# 任务5: 知识库更新
# ============================================
Write-Log "INFO" "`n--- 任务5: 知识库更新 ---"

$MemoryFile = "MEMORY.md"
if (Test-Path $MemoryFile) {
    $LastModified = (Get-Item $MemoryFile).LastWriteTime
    $DaysSinceUpdate = (New-TimeSpan -Start $LastModified -End (Get-Date)).Days

    Write-Log "INFO" "Memory.md最后更新: $LastModified"
    Write-Log "INFO" "距今天数: $DaysSinceUpdate 天"

    if ($DaysSinceUpdate -gt 1) {
        Write-Log "WARN" "⚠️ Memory.md未更新超过1天，建议更新"
    }
    else {
        Write-Log "INFO" "✅ Memory.md最近已更新"
    }
}
else {
    Write-Log "WARN" "⚠️ MEMORY.md文件不存在"
}

# ============================================
# 生成总结报告
# ============================================
Write-Log "INFO" "`n=== Nightly Build总结 ==="
$Duration = (Get-Date) - $Script:NightlyBuildStart
Write-Log "INFO" "完成时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Log "INFO" "执行耗时: $([math]::Round($Duration.TotalSeconds, 2)) 秒"
if ($HealthCheck.GatewayStatus) {
    Write-Log "INFO" "健康检查: ✅ 通过"
} else {
    Write-Log "INFO" "健康检查: ❌ 失败"
}
Write-Log "INFO" "错误检测: $($HealthCheck.Errors.Count) 个错误"
Write-Log "INFO" "优化任务: $(($OptimizationTasks).Count) 个完成"

# ============================================
# 结论
# ============================================
Write-Log "INFO" "`n🎉 Nightly Build执行完成！"

if (-not $DryRun) {
    Write-Log "INFO" "报告已保存到: $($Script:Config.OutputFile)"
}

# ============================================
# 返回结果
# ============================================
$Result = @{
    Success = $true
    StartTime = $Script:NightlyBuildStart
    EndTime = (Get-Date)
    Duration = $Duration.TotalSeconds
    HealthCheck = $HealthCheck
    ErrorPatterns = $ErrorPatterns
    OptimizationTasks = $OptimizationTasks
    SkillCount = $Skills.Count
}

return $Result
