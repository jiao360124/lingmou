# Copilot Completion Engine - 行级代码补全引擎

<#
.SYNOPSIS
    行级代码补全引擎，基于上下文和代码模式库生成补全建议

.DESCRIPTION
    分析当前行和上下文，从模式库匹配相似模式，生成补全候选

.PARAMETER CurrentLine
    用户输入的当前行

.PARAMETER ContextLines
    上下文行数组

.PARAMETER Language
    代码语言（javascript, python等）

.OUTPUTS
    补全候选对象数组

.EXAMPLE
    $completion = Get-LineCompletion "const result = numbers." "numbers.filter(x => x > 0).map(x => x * 2)"
    $completion | ConvertTo-Json -Depth 3
#>

function Get-LineCompletion {
    param(
        [Parameter(Mandatory=$true)]
        [string]$CurrentLine,

        [Parameter(Mandatory=$true)]
        [string[]]$ContextLines,

        [Parameter(Mandatory=$false)]
        [string]$Language = "javascript"
    )

    # 加载模式库
    $patterns = Load-Patterns -Language $Language

    if (-not $patterns) {
        Write-Error "No patterns found for language: $Language"
        return @()
    }

    # 1. 识别行尾状态
    $state = AnalyzeLineEnd -Line $CurrentLine

    # 2. 提取关键词
    $keywords = ExtractKeywords -Line $CurrentLine -ContextLines $ContextLines -Language $Language

    # 3. 搜索模式库
    $matchedPatterns = SearchPatterns -Keywords $keywords -Patterns $patterns -State $state -Language $Language

    # 4. 生成候选补全
    $candidates = GenerateCandidates -Patterns $matchedPatterns -State $state -Language $Language

    # 5. 排序并返回前3个
    $candidates = $candidates | Sort-Object -Property Score -Descending | Select-Object -First 3

    return $candidates
}

<#
.SYNOPSIS
    加载代码模式库

.DESCRIPTION
    从JSON文件加载指定语言的代码模式

.PARAMETER Language
    代码语言

.OUTPUTS
    模式对象数组
#>

function Load-Patterns {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Language
    )

    $patternsDir = Join-Path $PSScriptRoot "..\patterns"
    $languageDir = Join-Path $patternsDir $Language

    if (-not (Test-Path $languageDir)) {
        Write-Warning "Language directory not found: $languageDir"
        return @()
    }

    $patternFiles = Get-ChildItem -Path $languageDir -Filter "*.json" -Recurse

    $allPatterns = @()
    foreach ($file in $patternFiles) {
        try {
            $patterns = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            $allPatterns += $patterns
        } catch {
            Write-Warning "Failed to load patterns from $($file.FullName): $_"
        }
    }

    return $allPatterns
}

<#
.SYNOPSIS
    分析行尾状态

.DESCRIPTION
    识别行尾是在什么上下文中（方法调用、属性访问等）

.PARAMETER Line
    当前行

.OUTPUTS
    状态对象（方法调用、属性访问、语法不完整等）
#>

function AnalyzeLineEnd {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Line
    )

    # 去除末尾空白
    $trimmedLine = $Line.Trim()

    # 识别行尾状态
    $state = @{
        Type = "unknown"
        IsMethodCall = $false
        IsPropertyAccess = $false
        IsFunctionCall = $false
        IsArrayAccess = $false
        IsChained = $false
        EndsWithPunctuation = $false
        EndsWithIdentifier = $false
        EndsWithDot = $false
    }

    # 检查是否以点结尾（可能是属性访问）
    if ($trimmedLine.EndsWith('.')) {
        $state.EndsWithDot = $true
        $state.Type = "property-access"
        return $state
    }

    # 检查括号是否闭合
    $openParentheses = ($trimmedLine -split '\(').Count
    $closeParentheses = ($trimmedLine -split '\)').Count
    $openBrackets = ($trimmedLine -split '\[').Count
    $closeBrackets = ($trimmedLine -split '\]').Count

    # 括号未闭合，可能是函数调用或数组访问
    if ($openParentheses -gt $closeParentheses) {
        $state.IsMethodCall = $true
        $state.IsFunctionCall = $true
        $state.Type = "method-call"
    }

    if ($openBrackets -gt $closeBrackets) {
        $state.IsArrayAccess = $true
        $state.Type = "array-access"
    }

    # 检查是否是方法链的一部分
    if ($trimmedLine.Contains('.') -and (-not $trimmedLine.TrimEnd().EndsWith(')'))) {
        $state.IsChained = $true
        $state.Type = "chained-call"
    }

    return $state
}

<#
.SYNOPSIS
    提取关键词

.DESCRIPTION
    从当前行和上下文行中提取关键词

.PARAMETER Line
    当前行

.PARAMETER ContextLines
    上下文行

.PARAMETER Language
    代码语言

.OUTPUTS
    关键词字符串数组
#>

function ExtractKeywords {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Line,

        [Parameter(Mandatory=$true)]
        [string[]]$ContextLines,

        [Parameter(Mandatory=$false)]
        [string]$Language = "javascript"
    )

    $keywords = [System.Collections.ArrayList]::new()

    # 从当前行提取标识符
    $lineKeywords = $Line -split '[\s\(\)\[\]\.,;]'

    foreach ($keyword in $lineKeywords) {
        $keyword = $keyword.Trim()
        if (-not [string]::IsNullOrWhiteSpace($keyword) -and
            -not $keyword.Contains('const') -and
            -not $keyword.Contains('let') -and
            -not $keyword.Contains('var') -and
            -not $keyword.Contains('function') -and
            -not $keyword.Contains('class') -and
            -not $keyword.Contains('if') -and
            -not $keyword.Contains('else') -and
            -not $keyword.Contains('return')) {

            [void]$keywords.Add($keyword)
        }
    }

    # 从上下文提取关键词
    foreach ($contextLine in $ContextLines) {
        if ($contextLine -match '\b\w+\b') {
            $contextLineKeywords = $contextLine -split '[\s\(\)\[\]\.,;]'
            foreach ($keyword in $contextLineKeywords) {
                $keyword = $keyword.Trim()
                if (-not [string]::IsNullOrWhiteSpace($keyword) -and
                    -not $keyword.Contains('const') -and
                    -not $keyword.Contains('let') -and
                    -not $keyword.Contains('var') -and
                    -not $keyword.Contains('function') -and
                    -not $keyword.Contains('class') -and
                    -not $keyword.Contains('if') -and
                    -not $keyword.Contains('else') -and
                    -not $keyword.Contains('return')) {

                    [void]$keywords.Add($keyword)
                }
            }
        }
    }

    # 去重并返回
    $keywords = $keywords | Select-Object -Unique
    return $keywords
}

<#
.SYNOPSIS
    搜索模式库

.DESCRIPTION
    根据关键词和状态搜索匹配的模式

.PARAMETER Keywords
    关键词数组

.PARAMETER Patterns
    模式数组

.PARAMETER State
    行尾状态

.PARAMETER Language
    代码语言

.OUTPUTS
    匹配的模式对象数组
#>

function SearchPatterns {
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$Keywords,

        [Parameter(Mandatory=$true)]
        $Patterns,

        [Parameter(Mandatory=$true)]
        $State,

        [Parameter(Mandatory=$false)]
        [string]$Language = "javascript"
    )

    $matchedPatterns = [System.Collections.ArrayList]::new()

    foreach ($pattern in $Patterns) {
        # 检查语言是否匹配
        if ($pattern.language -ne $Language) {
            continue
        }

        $matchScore = 0

        # 关键词匹配（使用任意关键词）
        foreach ($keyword in $Keywords) {
            if ($pattern.keywords -contains $keyword) {
                $matchScore += 10
            }
        }

        # 类别匹配
        if ($pattern.category -in @('array-methods', 'async-await', 'object-creation', 'validation', 'error-handling')) {
            $matchScore += 5
        }

        # 状态匹配
        if ($State.IsMethodCall -and $pattern.category -in @('array-methods', 'async-await')) {
            $matchScore += 8
        }

        if ($State.IsPropertyAccess) {
            $matchScore += 5
        }

        if ($State.IsChained) {
            $matchScore += 7
        }

        # 匹配得分超过阈值
        if ($matchScore -ge 10) {
            $pattern.PSObject.Properties.Add('MatchScore', $matchScore)
            [void]$matchedPatterns.Add($pattern)
        }
    }

    return $matchedPatterns
}

<#
.SYNOPSIS
    生成补全候选

.DESCRIPTION
    根据匹配的模式生成补全候选

.PARAMETER Patterns
    匹配的模式

.PARAMETER State
    行尾状态

.PARAMETER Language
    代码语言

.OUTPUTS
    补全候选对象数组
#>

function GenerateCandidates {
    param(
        [Parameter(Mandatory=$true)]
        $Patterns,

        [Parameter(Mandatory=$true)]
        $State,

        [Parameter(Mandatory=$false)]
        [string]$Language = "javascript"
    )

    $candidates = [System.Collections.ArrayList]::new()

    foreach ($pattern in $Patterns) {
        # 生成补全文本
        $completionText = GenerateCompletionText -Pattern $pattern -State $State -Language $Language

        if ([string]::IsNullOrWhiteSpace($completionText)) {
            continue
        }

        # 计算候选得分
        $score = $pattern.score
        $score += $pattern.matchscore * 0.01

        # 确保分数在0-1之间
        $score = [Math]::Max(0, [Math]::Min(1, $score))

        $candidate = [PSCustomObject]@{
            PatternId = $pattern.patternId
            Category = $pattern.category
            Name = $pattern.name
            Template = $pattern.template
            Example = $pattern.example
            Completion = $completionText
            Score = $score
            Language = $Language
            Difficulty = $pattern.difficulty
        }

        [void]$candidates.Add($candidate)
    }

    return $candidates
}

<#
.SYNOPSIS
    生成补全文本

.DESCRIPTION
    根据模式和状态生成最终的补全文本

.PARAMETER Pattern
    模式对象

.PARAMETER State
    行尾状态

.PARAMeter Language
    代码语言

.OUTPUTS
    补全文本字符串
#>

function GenerateCompletionText {
    param(
        [Parameter(Mandatory=$true)]
        $Pattern,

        [Parameter(Mandatory=$true)]
        $State,

        [Parameter(Mandatory=$false)]
        [string]$Language = "javascript"
    )

    $template = $Pattern.template

    # 如果是方法调用，补全点和方法名
    if ($State.IsMethodCall -and $State.IsChained) {
        # 从当前行提取最后一个标识符
        $currentLine = $template
        if ($currentLine.EndsWith('.')) {
            $methodPart = $currentLine.TrimEnd('.')
            return ".($methodPart)"
        }
    }

    # 如果是属性访问，补全点属性名
    if ($State.IsPropertyAccess) {
        # 检查是否有更多上下文
        if ($State.IsChained) {
            $remaining = $template.Substring($currentLine.IndexOf('.') + 1)
            if (-not [string]::IsNullOrWhiteSpace($remaining)) {
                return ".$remaining"
            }
        }
    }

    # 返回模板（替换占位符）
    $completion = $template

    # 如果是代码示例格式
    if ($Pattern.example) {
        $completion = $Pattern.example
    }

    return $completion
}

# 导出函数
Export-ModuleMember -Function @(
    'Get-LineCompletion',
    'Load-Patterns',
    'AnalyzeLineEnd',
    'ExtractKeywords',
    'SearchPatterns',
    'GenerateCandidates',
    'GenerateCompletionText'
)
