# Copilot Quality Scorer - 质量评分系统

<#
.SYNOPSIS
    质量评分系统，对代码补全建议进行多维度评分

.DESCRIPTION
    对补全建议进行语法正确性、模式匹配度、可读性、性能影响、可维护性五个维度的评分

.PARAMETER Candidate
    补全候选对象

.OUTPUTS
    评分结果对象
#>

function Evaluate-Quality {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Candidate
    )

    # 评分维度
    $scores = [ordered]@{
        Syntax = 0
        PatternMatch = 0
        Readability = 0
        Performance = 0
        Maintainability = 0
    }

    # 1. 语法正确性评分（0-100）
    $scores.Syntax = Analyze-Syntax -Candidate $Candidate

    # 2. 模式匹配度评分（0-100）
    $scores.PatternMatch = Calculate-PatternSimilarity -Candidate $Candidate

    # 3. 可读性评分（0-100）
    $scores.Readability = Assess-Readability -Candidate $Candidate

    # 4. 性能影响评分（0-100）
    $scores.Performance = Evaluate-Performance -Candidate $Candidate

    # 5. 可维护性评分（0-100）
    $scores.Maintainability = Assess-Maintainability -Candidate $Candidate

    # 计算加权总分
    $totalScore = (
        $scores.Syntax * 0.60 +
        $scores.PatternMatch * 0.20 +
        $scores.Readability * 0.10 +
        $scores.Performance * 0.05 +
        $scores.Maintainability * 0.05
    )

    # 确保分数在0-100之间
    $totalScore = [Math]::Max(0, [Math]::Min(100, $totalScore))

    # 评级
    $rating = Get-QualityRating -Score $totalScore

    # 返回结果
    $result = [PSCustomObject]@{
        Syntax = $scores.Syntax
        PatternMatch = $scores.PatternMatch
        Readability = $scores.Readability
        Performance = $scores.Performance
        Maintainability = $scores.Maintainability
        TotalScore = $totalScore
        Rating = $rating
        Threshold = Get-QualityThreshold -Rating $rating
    }

    return $result
}

<#
.SYNOPSIS
    分析语法正确性

.DESCRIPTION
    基于模式模板和示例评估代码语法正确性

.PARAMETER Candidate
    补全候选对象

.OUTPUTS
    语法评分（0-100）
#>

function Analyze-Syntax {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Candidate
    )

    $template = $Candidate.Template
    $example = $Candidate.Example

    # 简单评分逻辑
    $score = 100

    # 检查模板是否包含占位符
    if ($template -match '\{[a-zA-Z]+\}') {
        $score -= 20
    }

    # 检查模板是否是有效的代码片段
    if ($template -match '^\s*$' -or $template -match '^[\s\{\}]*$') {
        $score -= 30
    }

    # 检查示例是否比模板好
    if (-not [string]::IsNullOrWhiteSpace($example) -and $example.Length -gt $template.Length) {
        $score -= 10
    }

    # 检查模板中的特殊字符
    if ($template -match '[{}[\]();,].*') {
        $score -= 5
    }

    return [Math]::Max(0, $score)
}

<#
.SYNOPSIS
    计算模式相似度

.DESCRIPTION
    基于候选模板与模式库模板的相似度评分

.PARAMETER Candidate
    补全候选对象

.OUTPUTS
    模式匹配度评分（0-100）
#>

function Calculate-PatternSimilarity {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Candidate
    )

    # 使用模板长度作为相似度代理
    # 短模板通常更通用
    $templateLength = $Candidate.Template.Length
    $exampleLength = if ($Candidate.Example) { $Candidate.Example.Length } else { $templateLength }

    $minLength = [Math]::Min($templateLength, $exampleLength)

    # 相似度随长度增加而降低
    $similarity = [Math]::Max(0, 100 - $minLength * 0.5)

    # 基础分数
    $baseScore = [Math]::Max(0, $Candidate.Score * 100)

    # 最终分数
    $finalScore = ($baseScore + $similarity) / 2

    return [Math]::Max(0, [Math]::Min(100, $finalScore))
}

<#
.SYNOPSIS
    评估可读性

.DESCRIPTION
    基于命名、结构清晰度等评估代码可读性

.PARAMETER Candidate
    补全候选对象

.OUTPUTS
    可读性评分（0-100）
#>

function Assess-Readability {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Candidate
    )

    $template = $Candidate.Template
    $example = $Candidate.Example

    $score = 0

    # 检查是否使用有意义的占位符
    if ($template -match '\{[a-zA-Z]+\}') {
        $score += 10
    }

    # 检查是否有清晰的示例
    if (-not [string]::IsNullOrWhiteSpace($example)) {
        $score += 20
    }

    # 检查模板复杂度（避免过于复杂的模板）
    $complexity = ($template -split '\.').Length + ($template -split '\{').Length
    if ($complexity -le 3) {
        $score += 20
    } elseif ($complexity -le 5) {
        $score += 10
    }

    # 检查是否有注释或说明
    if ($Candidate.Name) {
        $score += 10
    }

    return [Math]::Min(100, $score)
}

<#
.SYNOPSIS
    评估性能影响

.DESCRIPTION
    评估补全建议的性能影响

.PARAMETER Candidate
    补全候选对象

.OUTPUTS
    性能评分（0-100）
#>

function Evaluate-Performance {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Candidate
    )

    $template = $Candidate.Template
    $category = $Candidate.Category

    $score = 100

    # 根据类别调整分数
    switch ($category) {
        'array-methods' {
            # 数组方法通常是高效的
            $score += 10
        }
        'async-await' {
            # 异步操作可能引入性能开销
            $score -= 10
        }
        'validation' {
            # 验证操作可能影响性能
            $score -= 5
        }
        'error-handling' {
            # 错误处理通常不直接影响性能
            $score += 5
        }
        default {
            $score += 0
        }
    }

    # 检查是否包含可能影响性能的代码
    if ($template -match '\.map\(|\.filter\(|\.reduce\(|\.forEach\(') {
        $score -= 5
    }

    return [Math]::Max(0, [Math]::Min(100, $score))
}

<#
.SYNOPSIS
    评估可维护性

.DESCRIPTION
    评估代码的可维护性

.PARAMETER Candidate
    补全候选对象

.OUTPUTS
    可维护性评分（0-100）
#>

function Assess-Maintainability {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Candidate
    )

    $template = $Candidate.Template
    $difficulty = $Candidate.Difficulty

    $score = 100 - ($difficulty * 20)

    # 简单的模板更易维护
    if ($template.Length -lt 20) {
        $score += 15
    }

    # 有示例的模板更易理解
    if (-not [string]::IsNullOrWhiteSpace($Candidate.Example)) {
        $score += 10
    }

    # 有明确命名的模板更易维护
    if (-not [string]::IsNullOrWhiteSpace($Candidate.Name)) {
        $score += 5
    }

    return [Math]::Max(0, [Math]::Min(100, $score))
}

<#
.SYNOPSIS
    获取质量评级

.DESCRIPTION
    根据总分返回质量评级

.PARAMETER Score
    总分（0-100）

.OUTPUTS
    评级字符串（High/Medium/Low）
#>

function Get-QualityRating {
    param(
        [Parameter(Mandatory=$true)]
        [double]$Score
    )

    if ($Score -ge 85) {
        return 'High'
    } elseif ($Score -ge 70) {
        return 'Medium'
    } else {
        return 'Low'
    }
}

<#
.SYNOPSIS
    获取质量阈值

.DESCRIPTION
    根据评级返回推荐阈值

.PARAMeter Rating
    评级字符串

.OUTPUTS
    阈值分数
#>

function Get-QualityThreshold {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Rating
    )

    switch ($Rating) {
        'High' { return 85 }
        'Medium' { return 70 }
        'Low' { return 0 }
        default { return 0 }
    }
}

<#
.SYNOPSIS
    批量评估质量

.DESCRIPTION
    对多个候选进行质量评估并返回结果

.PARAMeter Candidates
    候选数组

.OUTPUTS
    评估结果对象数组
#>

function Evaluate-CandidatesQuality {
    param(
        [Parameter(Mandatory=$true)]
        $Candidates
    )

    $results = foreach ($candidate in $Candidates) {
        $quality = Evaluate-Quality -Candidate $candidate
        [PSCustomObject]@{
            Candidate = $candidate.Completion
            TotalScore = $quality.TotalScore
            Rating = $quality.Rating
            Syntax = $quality.Syntax
            PatternMatch = $quality.PatternMatch
            Readability = $quality.Readability
            Performance = $quality.Performance
            Maintainability = $quality.Maintainability
        }
    }

    return $results
}

# 导出函数
Export-ModuleMember -Function @(
    'Evaluate-Quality',
    'Analyze-Syntax',
    'Calculate-PatternSimilarity',
    'Assess-Readability',
    'Evaluate-Performance',
    'Assess-Maintainability',
    'Get-QualityRating',
    'Get-QualityThreshold',
    'Evaluate-CandidatesQuality'
)
