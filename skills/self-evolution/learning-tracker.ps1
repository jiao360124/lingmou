# 学习日志系统

# @Author: 灵眸
# @Version: 1.0.0
# @Date: 2026-02-13

param(
    [Parameter(Mandatory=$false)]
    [string]$LogType = "daily",

    [Parameter(Mandatory=$false)]
    [string]$Category = "general",

    [Parameter(Mandatory=$false)]
    [string]$Content = "",

    [Parameter(Mandatory=$false)]
    [switch]$RecordLearning = $true,

    [Parameter(Mandatory=$false)]
    [switch]$GenerateSummary = $true
)

# 获取脚本路径
$ScriptPath = $PSScriptRoot
$LearningLog = "$ScriptPath/data/learning-log.md"
$LearningSummary = "$ScriptPath/data/learning-summary.md"
$DailyMemoryFile = "$ScriptPath/../../memory/YYYY-MM-DD.md"

# 初始化结果
$Result = @{
    Success = $true
    StartTime = Get-Date
    EndTime = $null
    Duration = 0
    Messages = @()
    Errors = @{}
    LogEntry = @{
        timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        type = $LogType
        category = $Category
        content = $Content
        aiInsights = @{}
    }
}

# 日志函数
function Write-Log {
    param([string]$Message, [ValidateSet("INFO", "SUCCESS", "ERROR", "WARNING", "DEBUG", "LEARNING")]
    [string]$Level = "INFO")

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Prefix = "[$Timestamp] [$Level]"

    switch ($Level) {
        "INFO"    { Write-Host "$Prefix $Message" -ForegroundColor Cyan }
        "SUCCESS" { Write-Host "$Prefix $Message" -ForegroundColor Green }
        "ERROR"   { Write-Host "$Prefix $Message" -ForegroundColor Red }
        "WARNING" { Write-Host "$Prefix $Message" -ForegroundColor Yellow }
        "DEBUG"   { Write-Host "$Prefix $Message" -ForegroundColor DarkGray }
        "LEARNING" { Write-Host "$Prefix $Message" -ForegroundColor Magenta }
    }

    $Result.Messages += "$Prefix $Message"
}

try {
    Write-Log "学习日志系统启动" "LEARNING"
    Write-Log "记录学习内容..." "LEARNING"

    # ========== 第1步：创建学习条目 ==========
    Write-Log "创建学习条目..." "LEARNING"

    $LogEntry = @{
        timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        type = $LogType
        category = $Category
        content = $Content
        userId = "lingmou"
        skill = "self-evolution"
        status = "completed"
    }

    $Result.LogEntry = $LogEntry

    Write-Log "✓ 学习条目已创建" "SUCCESS"

    # ========== 第2步：记录到日志 ==========
    if ($RecordLearning) {
        Write-Log "记录到学习日志..." "LEARNING"

        if (-not (Test-Path (Split-Path $LearningLog))) {
            New-Item -ItemType Directory -Path (Split-Path $LearningLog) -Force | Out-Null
        }

        # 生成日志格式
        $LogContent = @"

# $LogType 学习记录

## 基本信息
- **时间**: $([datetime]::Now.ToString("yyyy-MM-dd HH:mm:ss"))
- **类别**: $Category
- **用户**: 灵眸
- **Skill**: self-evolution

## 内容
$Content

## 学习要点
$([Environment]::NewLine)

---

"@

        $LogContent | Out-File -FilePath $LearningLog -Append -Encoding UTF8 -Force
        Write-Log "✓ 已记录到学习日志" "SUCCESS"
    }

    # ========== 第3步：生成AI洞察（模拟）==========
    if ($Content -and $Content.Length -gt 10) {
        Write-Log "生成学习洞察..." "LEARNING"

        # 基于内容生成简单洞察
        $Insights = @()

        # 1. 知识点识别
        $KnowledgePoints = @()
        $Content = $Content.ToLower()

        if ($Content -match "性能" -or $Content -match "优化") {
            $KnowledgePoints += "性能优化"
        }

        if ($Content -match "Moltbook" -or $Content -match "自我进化") {
            $KnowledgePoints += "自我进化"
        }

        if ($Content -match "Skill" -or $Content -match "技能") {
            $KnowledgePoints += "技能管理"
        }

        if ($Content -match "自动化" -or $Content -match "auto")) {
            $KnowledgePoints += "自动化"
        }

        if ($KnowledgePoints.Count -gt 0) {
            $Insights += @{
                type = "知识识别"
                points = $KnowledgePoints
                description = "识别到知识领域"
            }
        }

        # 2. 学习效果评估
        $LearningEffectiveness = @()
        if ($Content.Length -gt 50) {
            $LearningEffectiveness += @{
                type = "内容深度"
                score = "高"
                description = "内容较为深入"
            }
        }

        if ($LogType -eq "insight") {
            $LearningEffectiveness += @{
                type = "应用价值"
                score = "高"
                description = "具有实践指导意义"
            }
        }

        # 3. 建议识别
        $Recommendations = @()
        if ($KnowledgePoints.Count -eq 0) {
            $Recommendations += @{
                type = "建议"
                action = "尝试使用更具体的关键词记录学习内容"
                priority = "medium"
            }
        }

        $Result.LogEntry.aiInsights = @{
            knowledgePoints = $KnowledgePoints
            learningEffectiveness = $LearningEffectiveness
            recommendations = $Recommendations
        }

        Write-Log "✓ 已生成AI洞察" "SUCCESS"
    }

    # ========== 第4步：更新记忆文件 ==========
    if ($RecordLearning -and $Content) {
        Write-Log "更新记忆文件..." "LEARNING"

        $MemoryContent = @"

# 自主学习记录 - $([datetime]::Now.ToString("yyyy-MM-dd HH:mm:ss"))

## 学习内容
**类型**: $LogType
**类别**: $Category

**内容**:
$Content

## 学习要点
$([Environment]::NewLine)

---

"@

        $MemoryContent | Out-File -FilePath $DailyMemoryFile -Append -Encoding UTF8 -Force
        Write-Log "✓ 已更新记忆文件" "SUCCESS"
    }

    # ========== 第5步：生成学习摘要 ==========
    if ($GenerateSummary) {
        Write-Log "生成学习摘要..." "LEARNING"

        $Summary = @"

# 学习摘要 - $(Get-Date -Format 'yyyy-MM-dd')

## 今日学习
- **学习类型**: $LogType
- **类别**: $Category
- **内容长度**: $(if($Content){$Content.Length}else{0}) 字符

## 学习统计
- **记录时间**: $([datetime]::Now.ToString("HH:mm:ss"))
- **用户**: 灵眸
- **Skill**: self-evolution

## AI洞察
"@

        if ($Result.LogEntry.aiInsights) {
            if ($Result.LogEntry.aiInsights.knowledgePoints) {
                $Summary += "### 知识点识别" -split "`n"
                foreach ($Point in $Result.LogEntry.aiInsights.knowledgePoints) {
                    $Summary += "- **$Point**" -split "`n"
                }
                $Summary += "" -split "`n"
            }

            if ($Result.LogEntry.aiInsights.learningEffectiveness) {
                $Summary += "### 学习效果" -split "`n"
                foreach ($Effect in $Result.LogEntry.aiInsights.learningEffectiveness) {
                    $Summary += "- **$($Effect.type)**: $($Effect.description)" -split "`n"
                }
                $Summary += "" -split "`n"
            }

            if ($Result.LogEntry.aiInsights.recommendations) {
                $Summary += "### 建议" -split "`n"
                foreach ($Rec in $Result.LogEntry.aiInsights.recommendations) {
                    $Summary += "- **$($Rec.type)**: $($Rec.action)" -split "`n"
                }
            }
        }

        $Summary += "`n---" -split "`n"
        $Summary += "`n## 总体评价" -split "`n"
        $Summary += "- 今日学习内容: " + (if($Content){"有效"}else{"无内容"}) -split "`n"

        $Summary | Out-File -FilePath $LearningSummary -Encoding UTF8 -Force
        Write-Log "✓ 学习摘要已生成" "SUCCESS"
    }

    # ========== 输出学习摘要 ==========
    Write-Log "`n========== 学习日志摘要 ==========" "LEARNING"
    Write-Log "记录时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "LEARNING"
    Write-Log "学习类型: $LogType" "INFO"
    Write-Log "类别: $Category" "INFO"
    Write-Log "内容: " + (if($Content){$Content.Substring(0, [Math]::Min(50, $Content.Length)) + "..."}) "INFO"

    if ($Result.LogEntry.aiInsights.knowledgePoints) {
        Write-Log "`n识别的知识点:" "LEARNING"
        foreach ($Point in $Result.LogEntry.aiInsights.knowledgePoints) {
            Write-Log "  • $Point" "SUCCESS"
        }
    }

    Write-Log "================================" "LEARNING"

    # 设置最终状态
    $Result.EndTime = Get-Date
    $Result.Duration = ($Result.EndTime - $Result.StartTime).TotalSeconds

    Write-Log "学习日志记录完成" "SUCCESS"
    Write-Log "执行时间: $([math]::Round($Result.Duration, 2))秒" "SUCCESS"

} catch {
    $Result.Success = $false
    $Result.Errors = @{
        Exception = $_.Exception.Message
        StackTrace = $_.ScriptStackTrace
    }

    Write-Log "学习日志记录失败: $($_.Exception.Message)" "ERROR"

} finally {
    return $Result
}
