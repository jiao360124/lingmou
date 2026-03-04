# Skill评分器

# @Author: 灵眸
# @Version: 1.0.0
# @Date: 2026-02-13

param(
    [Parameter(Mandatory=$true)]
    [string]$SkillName,

    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false
)

# 获取脚本路径
$ScriptPath = $PSScriptRoot
$SkillsDir = "$ScriptPath/../../.."
$MetricFile = "$SkillsDir/skills/performance-metrics/data/metrics.json"

# 初始化结果
$Result = @{
    Success = $true
    SkillName = $SkillName
    DryRun = $DryRun
    StartTime = Get-Date
    EndTime = $null
    Duration = 0
    Messages = @()
    Score = 0
    Metrics = @{}
}

# 日志函数
function Write-Log {
    param([string]$Message, [ValidateSet("INFO", "SUCCESS", "ERROR", "WARNING", "DEBUG")]
    [string]$Level = "INFO")

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Prefix = "[$Timestamp] [$Level]"

    switch ($Level) {
        "INFO"    { Write-Host "$Prefix $Message" -ForegroundColor Cyan }
        "SUCCESS" { Write-Host "$Prefix $Message" -ForegroundColor Green }
        "ERROR"   { Write-Host "$Prefix $Message" -ForegroundColor Red }
        "WARNING" { Write-Host "$Prefix $Message" -ForegroundColor Yellow }
        "DEBUG"   { Write-Host "$Prefix $Message" -ForegroundColor DarkGray }
    }

    $Result.Messages += "$Prefix $Message"
}

try {
    Write-Log "Skill评分器启动" "INFO"
    Write-Log "Skill名称: $SkillName" "DEBUG"

    # 检查Skill是否存在
    $SkillPath = "$SkillsDir/$SkillName"
    if (-not (Test-Path $SkillPath)) {
        throw "Skill '$SkillName' 不存在"
    }

    Write-Log "Skill路径: $SkillPath" "DEBUG"

    if ($DryRun) {
        Write-Log "Dry Run 模式：生成模拟评分" "DEBUG"

        $Result.Metrics = @{
            executability = 80
            testCoverage = 75
            performance = 85
            documentation = 90
            codeQuality = 82
        }

        $Result.Score = [math]::Round(($Result.Metrics.executability + $Result.Metrics.testCoverage + $Result.Metrics.performance + $Result.Metrics.documentation + $Result.Metrics.codeQuality) / 5, 2)

        $Result.Success = $true
        return $Result
    }

    # ========== 1. 可执行性评分 ==========
    Write-Log "评分: 可执行性" "DEBUG"

    $ExecScore = 0
    $ConfigFile = "$SkillPath/config.json"

    if (Test-Path $ConfigFile) {
        $SkillConfig = Get-Content -Path $ConfigFile | ConvertFrom-Json

        # 参数定义 (30分)
        if ($SkillConfig.parameters -and ($SkillConfig.parameters -is [System.Collections.Hashtable])) {
            $ExecScore += 30
            Write-Log "  ✓ 参数定义: 30分" "SUCCESS"
        } else {
            $ExecScore += 15
            Write-Log "  ⚠️ 参数定义: 15分" "WARNING"
        }

        # 错误处理 (30分)
        $ScriptFile = "$SkillPath/scripts/$SkillName.ps1"
        if (Test-Path $ScriptFile) {
            $CodeContent = Get-Content -Path $ScriptFile -Raw
            if ($CodeContent -match 'try\s*\{') {
                $ExecScore += 30
                Write-Log "  ✓ 错误处理: 30分" "SUCCESS"
            } else {
                $ExecScore += 10
                Write-Log "  ⚠️ 错误处理: 10分" "WARNING"
            }
        } else {
            $ExecScore += 0
            Write-Log "  ✗ 主脚本: 0分" "ERROR"
        }

        # 执行流程 (40分)
        if ($SkillConfig.actions -and $SkillConfig.actions.Count -gt 0) {
            $ExecScore += 40
            Write-Log "  ✓ 执行流程: 40分" "SUCCESS"
        } else {
            $ExecScore += 20
            Write-Log "  ⚠️ 执行流程: 20分" "WARNING"
        }
    }

    $Result.Metrics.executability = $ExecScore

    # ========== 2. 测试覆盖评分 ==========
    Write-Log "评分: 测试覆盖" "DEBUG"

    $TestScore = 0
    $TestDir = "$SkillPath/tests"

    if (Test-Path $TestDir) {
        $TestFiles = Get-ChildItem -Path $TestDir -Filter "*.ps1" -File
        $TestCount = $TestFiles.Count

        # 测试数量 (20分)
        if ($TestCount -ge 5) {
            $TestScore += 20
            Write-Log "  ✓ 测试数量: 20分" "SUCCESS"
        } elseif ($TestCount -ge 3) {
            $TestScore += 15
            Write-Log "  ⚠️ 测试数量: 15分" "WARNING"
        } else {
            $TestScore += 5
            Write-Log "  ⚠️ 测试数量: 5分" "WARNING"
        }

        # 测试质量 (30分)
        if ($TestCount -ge 3) {
            $TestScore += 30
            Write-Log "  ✓ 测试质量: 30分" "SUCCESS"
        } else {
            $TestScore += 15
            Write-Log "  ⚠️ 测试质量: 15分" "WARNING"
        }
    } else {
        $TestScore += 5
        Write-Log "  ✗ 测试目录: 5分" "ERROR"
    }

    $Result.Metrics.testCoverage = $TestScore

    # ========== 3. 性能基准评分 ==========
    Write-Log "评分: 性能基准" "DEBUG"

    $PerfScore = 0

    if (Test-Path $MetricFile) {
        $Metrics = Get-Content -Path $MetricFile | ConvertFrom-Json
        $SkillMetrics = $Metrics | Where-Object { $_.skillName -eq $SkillName }

        if ($SkillMetrics.Count -gt 0) {
            # 成功率 (30分)
            $SuccessRate = ($SkillMetrics | Where-Object { $_.success -eq $true } | Measure-Object).Count / $SkillMetrics.Count * 100
            if ($SuccessRate -ge 90) {
                $PerfScore += 30
                Write-Log "  ✓ 成功率: 30分" "SUCCESS"
            } elseif ($SuccessRate -ge 70) {
                $PerfScore += 20
                Write-Log "  ⚠️ 成功率: 20分" "WARNING"
            } else {
                $PerfScore += 10
                Write-Log "  ⚠️ 成功率: 10分" "WARNING"
            }

            # 可靠性 (20分)
            $Reliability = ($SkillMetrics | Measure-Object -Property reliability -Average).Average
            if ($Reliability -ge 90) {
                $PerfScore += 20
                Write-Log "  ✓ 可靠性: 20分" "SUCCESS"
            } elseif ($Reliability -ge 70) {
                $PerfScore += 15
                Write-Log "  ⚠️ 可靠性: 15分" "WARNING"
            } else {
                $PerfScore += 10
                Write-Log "  ⚠️ 可靠性: 10分" "WARNING"
            }
        } else {
            $PerfScore += 10
            Write-Log "  ⚠️ 无性能数据: 10分" "WARNING"
        }
    } else {
        $PerfScore += 10
        Write-Log "  ⚠️ 无性能数据: 10分" "WARNING"
    }

    $Result.Metrics.performance = $PerfScore

    # ========== 4. 文档质量评分 ==========
    Write-Log "评分: 文档质量" "DEBUG"

    $DocScore = 0

    # README (25分)
    if (Test-Path "$SkillPath/README.md") {
        $DocScore += 25
        Write-Log "  ✓ README: 25分" "SUCCESS"
    } else {
        $DocScore += 10
        Write-Log "  ⚠️ README: 10分" "WARNING"
    }

    # SKILL.md (25分)
    if (Test-Path "$SkillPath/SKILL.md") {
        $DocScore += 25
        Write-Log "  ✓ SKILL.md: 25分" "SUCCESS"
    } else {
        $DocScore += 10
        Write-Log "  ⚠️ SKILL.md: 10分" "WARNING"
    }

    # 示例 (25分)
    if (Test-Path "$SkillPath/scripts/$SkillName.ps1") {
        $ScriptContent = Get-Content -Path "$SkillPath/scripts/$SkillName.ps1" -Raw
        if ($ScriptContent -match '# @Author' -or $ScriptContent -match '@author') {
            $DocScore += 25
            Write-Log "  ✓ 代码文档: 25分" "SUCCESS"
        } else {
            $DocScore += 10
            Write-Log "  ⚠️ 代码文档: 10分" "WARNING"
        }
    } else {
        $DocScore += 5
        Write-Log "  ⚠️ 代码文档: 5分" "WARNING"
    }

    $Result.Metrics.documentation = $DocScore

    # ========== 5. 代码规范评分 ==========
    Write-Log "评分: 代码规范" "DEBUG"

    $CodeScore = 0

    # 参数定义 (20分)
    if ($SkillConfig.parameters -and ($SkillConfig.parameters -is [System.Collections.Hashtable])) {
        $CodeScore += 20
        Write-Log "  ✓ 参数定义: 20分" "SUCCESS"
    } else {
        $CodeScore += 5
        Write-Log "  ⚠️ 参数定义: 5分" "WARNING"
    }

    # 错误处理 (20分)
    if ($ScriptFile -and (Test-Path $ScriptFile)) {
        $ScriptContent = Get-Content -Path $ScriptFile -Raw
        if ($ScriptContent -match 'try\s*\{') {
            $CodeScore += 20
            Write-Log "  ✓ 错误处理: 20分" "SUCCESS"
        } else {
            $CodeScore += 10
            Write-Log "  ⚠️ 错误处理: 10分" "WARNING"
        }
    }

    # 命名规范 (30分)
    if ($ScriptFile -and (Test-Path $ScriptFile)) {
        $ScriptContent = Get-Content -Path $ScriptFile -Raw
        if ($ScriptContent -match 'param\(') {
            $CodeScore += 30
            Write-Log "  ✓ 参数块: 30分" "SUCCESS"
        } else {
            $CodeScore += 10
            Write-Log "  ⚠️ 参数块: 10分" "WARNING"
        }
    }

    # 格式规范 (30分)
    $Lines = $ScriptContent.Split("`n").Count
    if ($Lines -lt 100) {
        $CodeScore += 30
        Write-Log "  ✓ 代码行数: 30分" "SUCCESS"
    } else {
        $CodeScore += 15
        Write-Log "  ⚠️ 代码行数: 15分" "WARNING"
    }

    $Result.Metrics.codeQuality = $CodeScore

    # ========== 计算总分 ==========
    $TotalScore = ($ExecScore + $TestScore + $PerfScore + $DocScore + $CodeScore) / 5
    $Result.Score = [math]::Round($TotalScore, 2)

    # ========== 输出评分报告 ==========
    Write-Log "`n========== Skill评分报告 ==========" "STANDARD"
    Write-Log "Skill名称: $SkillName" "STANDARD"
    Write-Log "`n评分详情:" "STANDARD"
    Write-Log "  可执行性: $ExecScore/100" "STANDARD"
    Write-Log "  测试覆盖: $TestScore/100" "STANDARD"
    Write-Log "  性能基准: $PerfScore/100" "STANDARD"
    Write-Log "  文档质量: $DocScore/100" "STANDARD"
    Write-Log "  代码规范: $CodeScore/100" "STANDARD"
    Write-Log "`n总分: $Result.Score/100" "STANDARD"

    # 评分等级
    if ($Result.Score -ge 90) {
        Write-Log "  等级: ⭐⭐⭐⭐⭐ 卓越" "SUCCESS"
    } elseif ($Result.Score -ge 80) {
        Write-Log "  等级: ⭐⭐⭐⭐ 优秀" "SUCCESS"
    } elseif ($Result.Score -ge 70) {
        Write-Log "  等级: ⭐⭐⭐ 良好" "SUCCESS"
    } elseif ($Result.Score -ge 60) {
        Write-Log "  等级: ⭐⭐ 中等" "WARNING"
    } else {
        Write-Log "  等级: ⭐ 需改进" "ERROR"
    }
    Write-Log "====================================" "STANDARD"

    # ========== 保存评分报告 ==========
    $ReportFile = "$SkillPath/reports/score-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    if (-not (Test-Path (Split-Path $ReportFile))) {
        New-Item -ItemType Directory -Path (Split-Path $ReportFile) -Force | Out-Null
    }

    $ScoreReport = @{
        timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        skillName = $SkillName
        score = $Result.Score
        maxScore = 100
        metrics = $Result.Metrics
        level = switch ($Result.Score) {
            { $_ -ge 90 } { "卓越" }
            { $_ -ge 80 } { "优秀" }
            { $_ -ge 70 } { "良好" }
            { $_ -ge 60 } { "中等" }
            default { "需改进" }
        }
        recommendations = @()
    }

    # 生成改进建议
    if ($ExecScore -lt 70) {
        $ScoreReport.recommendations += "增强参数定义和错误处理"
    }

    if ($TestScore -lt 70) {
        $ScoreReport.recommendations += "增加单元测试和集成测试"
    }

    if ($PerfScore -lt 70) {
        $ScoreReport.recommendations += "优化性能指标和可靠性"
    }

    if ($DocScore -lt 70) {
        $ScoreReport.recommendations += "完善README和SKILL.md文档"
    }

    if ($CodeScore -lt 70) {
        $ScoreReport.recommendations += "改进代码规范和格式"
    }

    $ScoreReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $ReportFile -Encoding UTF8 -Force
    Write-Log "评分报告已保存: $ReportFile" "SUCCESS"

    # 设置最终状态
    $Result.EndTime = Get-Date
    $Result.Duration = ($Result.EndTime - $Result.StartTime).TotalSeconds

    Write-Log "评分完成" "SUCCESS"
    Write-Log "执行时间: $([math]::Round($Result.Duration, 2))秒" "SUCCESS"

} catch {
    $Result.Success = $false
    $Result.Errors += $_.Exception.Message
    $Result.Errors += $_.ScriptStackTrace

    Write-Log "评分失败: $($_.Exception.Message)" "ERROR"

} finally {
    return $Result
}
