# Skill 分析引擎

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
$SkillPath = "$SkillsDir/$SkillName"

# 初始化结果
$Result = @{
    Success = $true
    SkillName = $SkillName
    DryRun = $DryRun
    StartTime = Get-Date
    EndTime = $null
    Duration = 0
    Messages = @()
    SkillPath = $SkillPath
    Analysis = @{
        FileStructure = @()
        CodeMetrics = @()
        Performance = @()
        Quality = @()
        Recommendations = @()
    }
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
    Write-Log "Skill 分析引擎启动" "INFO"

    # 检查Skill是否存在
    if (-not (Test-Path $SkillPath)) {
        throw "Skill '$SkillName' 不存在"
    }

    Write-Log "Skill 路径: $SkillPath" "DEBUG"

    # 1. 分析文件结构
    Write-Log "分析文件结构..." "DEBUG"

    $Files = Get-ChildItem -Path $SkillPath -Recurse -File
    $Result.Analysis.FileStructure = @()

    foreach ($File in $Files) {
        $SizeKB = [math]::Round($File.Length / 1KB, 2)
        $Path = $File.FullName.Replace($SkillPath + "\", "")

        $Result.Analysis.FileStructure += @{
            Path = $Path
            Size = "$SizeKB KB"
            Modified = $File.LastWriteTime
        }
    }

    Write-Log "发现 $($Files.Count) 个文件" "SUCCESS"

    # 2. 分析代码指标
    Write-Log "分析代码指标..." "DEBUG"

    $ScriptFile = "$SkillPath/scripts/$SkillName.ps1"

    if (Test-Path $ScriptFile) {
        $CodeContent = Get-Content -Path $ScriptFile -Raw

        # 统计行数
        $Lines = $CodeContent.Split("`n").Count
        $Result.Analysis.CodeMetrics += @{
            Type = "lines"
            Value = $Lines
            Description = "总代码行数"
        }

        # 统计函数数量
        $Functions = ($CodeContent -match 'function\s+(\w+)').Count
        $Result.Analysis.CodeMetrics += @{
            Type = "functions"
            Value = $Functions
            Description = "函数数量"
        }

        # 统计参数数量
        $Params = ($CodeContent -match 'param\(').Count
        $Result.Analysis.CodeMetrics += @{
            Type = "parameters"
            Value = $Params
            Description = "参数块数量"
        }

        # 统计注释行数
        $Comments = ($CodeContent -match '^\s*#').Count
        $Result.Analysis.CodeMetrics += @{
            Type = "comments"
            Value = $Comments
            Description = "注释行数"
        }

        # 统计try-catch
        $TryCatch = ($CodeContent -match 'try\s*\{').Count
        $Result.Analysis.CodeMetrics += @{
            Type = "error_handling"
            Value = $TryCatch
            Description = "错误处理块"
        }

        Write-Log "代码分析完成" "SUCCESS"
    }

    # 3. 分析性能指标
    Write-Log "分析性能指标..." "DEBUG"

    if (Test-Path $MetricFile) {
        $Metrics = Get-Content -Path $MetricFile | ConvertFrom-Json
        $SkillMetrics = $Metrics | Where-Object { $_.skillName -eq $SkillName }

        if ($SkillMetrics.Count -gt 0) {
            $Result.Analysis.Performance = @()

            # 执行时间统计
            $ExecutionTimes = $SkillMetrics | Select-Object -ExpandProperty executionTime
            $MinTime = ($ExecutionTimes | Measure-Object -Minimum).Minimum
            $MaxTime = ($ExecutionTimes | Measure-Object -Maximum).Maximum
            $AvgTime = ($ExecutionTimes | Measure-Object -Average).Average
            $MedianTime = ($ExecutionTimes | Sort-Object)[[math]::Floor($ExecutionTimes.Count / 2)]

            $Result.Analysis.Performance += @{
                Type = "execution_time"
                Metric = "执行时间（秒）"
                Min = $MinTime
                Max = $MaxTime
                Avg = $AvgTime
                Median = $MedianTime
                Unit = "秒"
            }

            # 成功率统计
            $SuccessCount = ($SkillMetrics | Where-Object { $_.success -eq $true }).Count
            $TotalCount = $SkillMetrics.Count
            $SuccessRate = ($SuccessCount / $TotalCount) * 100

            $Result.Analysis.Performance += @{
                Type = "success_rate"
                Metric = "成功率"
                Value = $SuccessRate
                Unit = "%"
                SuccessCount = $SuccessCount
                TotalCount = $TotalCount
            }

            # 可靠性评分
            $Reliability = 0
            if ($TotalCount -gt 0) {
                $Reliability = [math]::Round((($SuccessCount / $TotalCount) * 80) + (20 / $TotalCount * $TotalCount), 1)
            }

            $Result.Analysis.Performance += @{
                Type = "reliability"
                Metric = "可靠性评分"
                Value = $Reliability
                Unit = "/100"
            }

            Write-Log "性能分析完成" "SUCCESS"
        } else {
            Write-Log "无性能数据" "WARNING"
        }
    } else {
        Write-Log "性能指标文件不存在" "WARNING"
    }

    # 4. 代码质量分析
    Write-Log "分析代码质量..." "DEBUG"

    $QualityScore = 0
    $QualityCriteria = @()

    if (Test-Path $ScriptFile) {
        $CodeContent = Get-Content -Path $ScriptFile -Raw

        # 1. 文档完整性
        $SkillFile = "$SkillPath/SKILL.md"
        $HasSkillDoc = Test-Path $SkillFile
        if ($HasSkillDoc) {
            $QualityScore += 20
            $QualityCriteria += @{ Type = "skill_doc"; Pass = $true; Score = 20; Reason = "SKILL.md存在" }
        } else {
            $QualityScore += 0
            $QualityCriteria += @{ Type = "skill_doc"; Pass = $false; Score = 0; Reason = "缺少SKILL.md" }
        }

        # 2. 错误处理
        $HasTryCatch = $CodeContent -match 'try\s*\{'
        if ($HasTryCatch) {
            $QualityScore += 20
            $QualityCriteria += @{ Type = "error_handling"; Pass = $true; Score = 20; Reason = "有错误处理" }
        } else {
            $QualityScore += 0
            $QualityCriteria += @{ Type = "error_handling"; Pass = $false; Score = 0; Reason = "缺少错误处理" }
        }

        # 3. 参数定义
        $HasParams = $CodeContent -match 'param\('
        if ($HasParams) {
            $QualityScore += 20
            $QualityCriteria += @{ Type = "parameters"; Pass = $true; Score = 20; Reason = "有参数定义" }
        } else {
            $QualityScore += 0
            $QualityCriteria += @{ Type = "parameters"; Pass = $false; Score = 0; Reason = "缺少参数定义" }
        }

        # 4. 单元测试
        $HasTests = Test-Path "$SkillPath/tests"
        if ($HasTests) {
            $TestCount = (Get-ChildItem -Path "$SkillPath/tests" -Filter "*.ps1" -File).Count
            if ($TestCount -gt 0) {
                $QualityScore += 30
                $QualityCriteria += @{ Type = "testing"; Pass = $true; Score = 30; Reason = "有单元测试" }
            } else {
                $QualityScore += 10
                $QualityCriteria += @{ Type = "testing"; Pass = $true; Score = 10; Reason = "有测试目录" }
            }
        } else {
            $QualityScore += 0
            $QualityCriteria += @{ Type = "testing"; Pass = $false; Score = 0; Reason = "缺少测试目录" }
        }

        # 5. 性能测试
        $HasPerfTest = $CodeContent -match 'performance'
        if ($HasPerfTest) {
            $QualityScore += 10
            $QualityCriteria += @{ Type = "performance"; Pass = $true; Score = 10; Reason = "有性能测试" }
        } else {
            $QualityScore += 0
            $QualityCriteria += @{ Type = "performance"; Pass = $false; Score = 0; Reason = "缺少性能测试" }
        }
    }

    $Result.Analysis.Quality = @{
        Score = $QualityScore
        MaxScore = 100
        Criteria = $QualityCriteria
    }

    Write-Log "代码质量分析完成" "SUCCESS"

    # 5. 生成推荐
    Write-Log "生成改进建议..." "DEBUG"

    $Recommendations = @()

    # 基于质量评分
    if ($QualityScore -lt 50) {
        $Recommendations += @{
            Priority = "high"
            Category = "文档"
            Action = "创建SKILL.md文档"
            Reason = "当前质量评分过低，缺少文档"
        }
    }

    if ($QualityScore -lt 60) {
        $Recommendations += @{
            Priority = "high"
            Category = "测试"
            Action = "创建单元测试"
            Reason = "缺少单元测试，降低代码可靠性"
        }
    }

    # 基于性能
    $AvgTime = ($Result.Analysis.Performance | Where-Object { $_.Type -eq "execution_time" }).Avg
    if ($AvgTime -gt 3) {
        $Recommendations += @{
            Priority = "medium"
            Category = "性能"
            Action = "优化算法性能"
            Reason = "平均执行时间过长（$([math]::Round($AvgTime, 2))秒）"
        }
    }

    # 基于错误处理
    $TryCatch = ($Result.Analysis.CodeMetrics | Where-Object { $_.Type -eq "error_handling" }).Value
    if ($TryCatch -eq 0) {
        $Recommendations += @{
            Priority = "high"
            Category = "健壮性"
            Action = "添加错误处理"
            Reason = "缺少错误处理机制"
        }
    }

    $Result.Analysis.Recommendations = $Recommendations

    Write-Log "建议生成完成" "SUCCESS"

    # 保存分析结果
    $AnalysisFile = "$SkillPath/reports/analysis-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    if (-not (Test-Path (Split-Path $AnalysisFile))) {
        New-Item -ItemType Directory -Path (Split-Path $AnalysisFile) -Force | Out-Null
    }

    $Result.Analysis | ConvertTo-Json -Depth 10 | Out-File -FilePath $AnalysisFile -Encoding UTF8

    Write-Log "分析结果已保存: $AnalysisFile" "SUCCESS"

    # 设置最终状态
    $Result.EndTime = Get-Date
    $Result.Duration = ($Result.EndTime - $Result.StartTime).TotalSeconds

    Write-Log "分析完成" "SUCCESS"
    Write-Log "执行时间: $([math]::Round($Result.Duration, 2))秒" "SUCCESS"

} catch {
    $Result.Success = $false
    $Result.Errors += $_.Exception.Message
    $Result.Errors += $_.ScriptStackTrace

    Write-Log "分析失败: $($_.Exception.Message)" "ERROR"

} finally {
    return $Result
}
