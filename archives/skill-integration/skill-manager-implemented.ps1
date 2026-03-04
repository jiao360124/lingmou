# 灵眸技能集成管理器

**版本**: 1.0
**日期**: 2026-02-10

---

# 实现代码

# 技能状态管理
$skillsEnabled = @(
    "code-mentor",
    "git-essentials",
    "deepwork-tracker"
)

$skillStatus = @{
    code-mentor = @{enabled = $true; loaded = $false; last_used = $null}
    git-essentials = @{enabled = $true; loaded = $false; last_used = $null}
    deepwork-tracker = @{enabled = $true; loaded = $false; last_used = $null}
}

$skillUsageStats = @{
    code-mentor = @{count = 0; total_time_ms = 0}
    git-essentials = @{count = 0; total_time_ms = 0}
    deepwork-tracker = @{count = 0; total_time_ms = 0}
}

# 获取所有可用技能
function Get-AvailableSkills {
    Write-Host "`n[GIT-ESSENTIALS] Available Skills:" -ForegroundColor Cyan
    Write-Host "=============================" -ForegroundColor Cyan

    foreach ($skill in $skillsEnabled) {
        $status = $skillStatus[$skill]
        $statusIcon = if ($status.enabled -and $status.loaded) { "✓" } elseif ($status.enabled) { "⏳" } else { "✗" }
        $lastUsed = if ($status.last_used) { "Last: $($status.last_used)" } else { "Never" }

        Write-Host "  $statusIcon $skill - $lastUsed" -ForegroundColor $(switch ($status.enabled) {
            $true { "Green" }
            default { "Red" }
        })
    }

    Write-Host ""
    return $skillsEnabled
}

# 调用技能
function Invoke-Skill {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SkillName,
        [Parameter(Mandatory=$true)]
        [string]$Action,
        [hashtable]$Params = @{}
    )

    Write-Host "`n[GIT-ESSENTIALS] Invoking skill: $SkillName" -ForegroundColor Cyan
    Write-Host "Action: $Action" -ForegroundColor Yellow

    # 检查技能是否启用
    if (-not $skillsEnabled.Contains($SkillName)) {
        Write-Host "[GIT-ESSENTIALS] ✗ Skill not found: $SkillName" -ForegroundColor Red
        return @{success = $false; error = "Skill not found"}
    }

    $status = $skillStatus[$SkillName]
    if (-not $status.enabled) {
        Write-Host "[GIT-ESSENTIALS] ✗ Skill is disabled: $SkillName" -ForegroundColor Red
        return @{success = $false; error = "Skill disabled"}
    }

    # 加载技能模块
    $scriptPath = "scripts/skill-integration/${SkillName}-integration.ps1"

    if (-not (Test-Path $scriptPath)) {
        Write-Host "[GIT-ESSENTIALS] ✗ Skill module not found: $scriptPath" -ForegroundColor Red
        return @{success = $false; error = "Module not found"}
    }

    # 加载技能模块
    try {
        . $scriptPath

        # 检查是否有对应的函数
        $functionName = "Invoke-$SkillName"

        if (-not (Get-Command -Name $functionName -ErrorAction SilentlyContinue)) {
            Write-Host "[GIT-ESSENTIALS] ✗ No function found: $functionName" -ForegroundColor Red
            return @{success = $false; error = "Function not found"}
        }

        # 记录开始时间
        $startTime = Get-Date

        # 调用技能函数
        $result = & $functionName @Params -ErrorAction Stop

        # 计算执行时间
        $endTime = Get-Date
        $elapsed = ($endTime - $startTime).TotalMilliseconds
        $skillUsageStats[$SkillName].count++
        $skillUsageStats[$SkillName].total_time_ms += [math]::Round($elapsed, 0)
        $status.last_used = $endTime.ToString("yyyy-MM-dd HH:mm:ss")

        Write-Host "[GIT-ESSENTIALS] ✓ Skill executed successfully in $([math]::Round($elapsed, 2))ms" -ForegroundColor Green

        return @{success = $true; result = $result; execution_time_ms = $elapsed}

    } catch {
        Write-Host "[GIT-ESSENTIALS] ✗ Skill execution failed: $($_.Exception.Message)" -ForegroundColor Red
        return @{success = $false; error = $_.Exception.Message}
    }
}

# 批量调用技能
function Invoke-SkillBatch {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Skills,
        [Parameter(Mandatory=$true)]
        [string]$Action,
        [hashtable]$Params = @{}
    )

    Write-Host "`n[GIT-ESSENTIALS] Batch invoking skills..." -ForegroundColor Cyan
    Write-Host "Skills: $($Skills -join ', ')" -ForegroundColor Yellow
    Write-Host "Action: $Action" -ForegroundColor Yellow

    $results = @()

    foreach ($skill in $Skills) {
        Write-Host "`n[GIT-ESSENTIALS] Processing: $skill" -ForegroundColor Cyan
        $result = Invoke-Skill -SkillName $skill -Action $Action -Params $Params
        $results += @{
            skill = $skill
            success = $result.success
            result = $result.result
            error = $result.error
            execution_time_ms = $result.execution_time_ms
        }
    }

    Write-Host "`n[GIT-ESSENTIALS] Batch execution completed" -ForegroundColor Green

    return $results
}

# 检查技能状态
function Get-SkillStatus {
    param(
        [string]$SkillName
    )

    if (-not $SkillName) {
        # 返回所有技能状态
        Write-Host "`n[GIT-ESSENTIALS] Skill Status:" -ForegroundColor Cyan
        Write-Host "================================" -ForegroundColor Cyan

        foreach ($skill in $skillsEnabled) {
            $status = $skillStatus[$skill]
            Write-Host "`n$skill:" -ForegroundColor Yellow
            Write-Host "  Enabled: $($status.enabled)" -ForegroundColor Cyan
            Write-Host "  Loaded: $($status.loaded)" -ForegroundColor Cyan
            Write-Host "  Last Used: $($status.last_used)" -ForegroundColor Cyan
        }

        return $skillStatus
    } else {
        # 返回特定技能状态
        if ($skillsEnabled.Contains($SkillName)) {
            return $skillStatus[$SkillName]
        } else {
            Write-Host "[GIT-ESSENTIALS] ✗ Skill not found: $SkillName" -ForegroundColor Red
            return $null
        }
    }
}

# 查看技能使用统计
function Get-SkillUsageStats {
    Write-Host "`n[GIT-ESSENTIALS] Skill Usage Statistics:" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan

    foreach ($skill in $skillsEnabled) {
        $stats = $skillUsageStats[$skill]

        if ($stats.count -gt 0) {
            $avgTime = [math]::Round($stats.total_time_ms / $stats.count, 2)
            Write-Host "`n$skill:" -ForegroundColor Yellow
            Write-Host "  Total Uses: $($stats.count)" -ForegroundColor Cyan
            Write-Host "  Total Time: $($stats.total_time_ms)ms" -ForegroundColor Cyan
            Write-Host "  Avg Time: $avgTime ms" -ForegroundColor Cyan
        } else {
            Write-Host "`n$skill:" -ForegroundColor Yellow
            Write-Host "  Total Uses: 0" -ForegroundColor Gray
            Write-Host "  Not yet used" -ForegroundColor Gray
        }
    }

    Write-Host ""
}

# 启用/禁用技能
function Set-SkillEnabled {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SkillName,
        [Parameter(Mandatory=$true)]
        [bool]$Enabled
    )

    if ($skillsEnabled.Contains($SkillName)) {
        $skillStatus[$SkillName].enabled = $Enabled
        $action = if ($Enabled) { "enabled" } else { "disabled" }
        Write-Host "[GIT-ESSENTIALS] ✓ Skill $SkillName $action" -ForegroundColor Green
        return $true
    } else {
        Write-Host "[GIT-ESSENTIALS] ✗ Skill not found: $SkillName" -ForegroundColor Red
        return $false
    }
}

# 导出函数
Export-ModuleMember -Function Get-AvailableSkills, Invoke-Skill, Invoke-SkillBatch, Get-SkillStatus, Get-SkillUsageStats, Set-SkillEnabled
