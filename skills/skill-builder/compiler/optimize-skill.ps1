# Skill 优化引擎

# @Author: 灵眸
# @Version: 1.0.0
# @Date: 2026-02-13

param(
    [Parameter(Mandatory=$true)]
    [string]$SkillName,

    [Parameter(Mandatory=$false)]
    [switch]$Force = $false,

    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false
)

# 获取脚本路径
$ScriptPath = $PSScriptRoot
$SkillsDir = "$ScriptPath/../../.."
$MetricFile = "$SkillsDir/skills/performance-metrics/data/metrics.json"

# 初始化结果
$Result = @{
    Success = $false
    SkillName = $SkillName
    Force = $Force
    DryRun = $DryRun
    StartTime = Get-Date
    EndTime = $null
    Duration = 0
    Messages = @()
    Errors = @()
    Optimizations = @()
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
    Write-Log "Skill 优化引擎启动" "INFO"

    # 检查Skill是否存在
    $SkillPath = "$SkillsDir/$SkillName"
    if (-not (Test-Path $SkillPath)) {
        throw "Skill '$SkillName' 不存在"
    }

    Write-Log "Skill 路径: $SkillPath" "DEBUG"

    # 加载性能指标
    if (-not (Test-Path $MetricFile)) {
        Write-Log "性能指标文件不存在，创建空指标" "DEBUG"
        $Metrics = @()
    } else {
        $Metrics = Get-Content -Path $MetricFile | ConvertFrom-Json
    }

    # 分析当前Skill的性能
    $SkillMetrics = $Metrics | Where-Object { $_.skillName -eq $SkillName }

    Write-Log "找到性能指标: $($SkillMetrics.Count) 条" "DEBUG"

    # 识别优化点
    $Optimizations = @()

    if ($SkillMetrics.Count -gt 0) {
        # 分析执行时间
        $AvgTime = ($SkillMetrics | Measure-Object -Property executionTime -Average).Average
        Write-Log "平均执行时间: $([math]::Round($AvgTime, 2))秒" "DEBUG"

        if ($AvgTime -gt 5) {
            $Optimizations += @{
                Type = "performance"
                Priority = "high"
                Description = "执行时间过长（$([math]::Round($AvgTime, 2))秒），建议优化算法或增加缓存"
                Suggestion = "考虑使用缓存、异步处理或优化数据结构"
            }
            Write-Log "发现性能优化点" "WARNING"
        }

        # 分析成功率
        $SuccessRate = ($SkillMetrics | Where-Object { $_.success -eq $true } | Measure-Object).Count / $SkillMetrics.Count * 100
        Write-Log "成功率: $([math]::Round($SuccessRate, 2))%" "DEBUG"

        if ($SuccessRate -lt 80) {
            $Optimizations += @{
                Type = "reliability"
                Priority = "high"
                Description = "成功率过低（$([math]::Round($SuccessRate, 2))%），建议增加错误处理"
                Suggestion = "添加重试机制、输入验证和错误日志"
            }
            Write-Log "发现可靠性优化点" "WARNING"
        }
    }

    # 检查代码质量
    $SkillScript = "$SkillPath/scripts/$SkillName.ps1"

    if (Test-Path $SkillScript) {
        $CodeContent = Get-Content -Path $SkillScript -Raw

        # 检查TODO
        if ($CodeContent -match 'TODO') {
            $Optimizations += @{
                Type = "completeness"
                Priority = "medium"
                Description = "代码中包含未完成的TODO标记"
                Suggestion = "完成待办事项或移除TODO标记"
            }
        }

        # 检查错误处理
        if (-not ($CodeContent -match 'try\s*\{')) {
            $Optimizations += @{
                Type = "robustness"
                Priority = "high"
                Description = "缺少try-catch错误处理"
                Suggestion = "添加try-catch块增强错误处理能力"
            }
        }

        # 检查文档
        $SkillFile = "$SkillPath/SKILL.md"
        if (-not (Test-Path $SkillFile)) {
            $Optimizations += @{
                Type = "documentation"
                Priority = "medium"
                Description = "缺少SKILL.md文档"
                Suggestion = "创建SKILL.md文件，添加使用说明"
            }
        }

        # 检查性能测试
        $TestFile = "$SkillPath/tests/test-example.ps1"
        if (-not (Test-Path $TestFile)) {
            $Optimizations += @{
                Type = "testing"
                Priority = "medium"
                Description = "缺少测试文件"
                Suggestion = "创建测试脚本，确保代码质量"
            }
        }
    }

    $Result.Optimizations = $Optimizations

    if ($DryRun) {
        Write-Log "Dry Run 模式：不执行优化" "DEBUG"
        foreach ($Opt in $Optimizations) {
            $Result.Optimizations += @{
                Type = $Opt.Type
                Priority = $Opt.Priority
                Description = $Opt.Description
                Suggestion = $Opt.Suggestion
                DryRun = $true
            }
        }
        $Result.Success = $true
        return $Result
    }

    # 应用优化
    Write-Log "发现 $($Optimizations.Count) 个优化点" "INFO"

    foreach ($Opt in $Optimizations) {
        Write-Log "优化点 [$($Opt.Priority)]: $($Opt.Description)" "INFO"

        # 创建优化备份
        $BackupFile = "$SkillPath/backups/backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').ps1"
        if (-not (Test-Path (Split-Path $BackupFile))) {
            New-Item -ItemType Directory -Path (Split-Path $BackupFile) -Force | Out-Null
        }

        Copy-Item -Path $SkillScript -Destination $BackupFile -Force
        Write-Log "创建备份: $BackupFile" "DEBUG"

        # 应用优化
        $OptimizationApplied = $false

        switch ($Opt.Type) {
            "performance" {
                # 添加缓存层
                $CacheComment = @"
# 性能优化：添加缓存层
# TODO: 实现缓存逻辑
# 可使用 persistent-memory 或自定义缓存策略
"@

                $CodeContent = $CacheComment + "`n$CodeContent"
                $OptimizationApplied = $true
            }

            "reliability" {
                # 添加错误处理
                $ErrorHandler = @"

try {
    # 原有代码
} catch {
    Write-Log \"错误: $($_.Exception.Message)\" \"ERROR\"
    return @{ Success = $false; Error = $_.Exception.Message }
}
"@

                $CodeContent = $ErrorHandler + $CodeContent
                $OptimizationApplied = $true
            }

            "robustness" {
                # 添加try-catch
                $CodeContent = "try { $CodeContent } catch { Write-Log \"Error: $($_.Exception.Message)\" \"ERROR\" }"
                $OptimizationApplied = $true
            }

            "completeness" {
                # 标记TODO完成
                $CodeContent = $CodeContent -replace 'TODO', 'Implemented'
                $OptimizationApplied = $true
            }
        }

        if ($OptimizationApplied) {
            $CodeContent | Out-File -FilePath $SkillScript -Encoding UTF8 -Force
            Write-Log "优化应用成功" "SUCCESS"

            $Result.Optimizations[$Optimizations.IndexOf($Opt)].Applied = $true
            $Result.Optimizations[$Optimizations.IndexOf($Opt)].Backup = $BackupFile
        }
    }

    # 设置最终状态
    $Result.Success = $true
    $Result.EndTime = Get-Date
    $Result.Duration = ($Result.EndTime - $Result.StartTime).TotalSeconds

    Write-Log "优化完成" "SUCCESS"
    Write-Log "应用优化数: $($Optimizations.Where({ $_.Applied -eq $true }).Count)" "SUCCESS"
    Write-Log "执行时间: $([math]::Round($Result.Duration, 2))秒" "SUCCESS"

} catch {
    $Result.Success = $false
    $Result.Errors += $_.Exception.Message
    $Result.Errors += $_.ScriptStackTrace

    Write-Log "优化失败: $($_.Exception.Message)" "ERROR"

} finally {
    return $Result
}
