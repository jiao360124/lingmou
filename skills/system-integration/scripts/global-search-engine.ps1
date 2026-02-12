<#
.SYNOPSIS
Global Search Engine

.DESCRIPTION
全局搜索引擎，支持跨技能搜索

.NOTES
Author: OpenClaw Assistant
Date: 2026-02-16
Version: 1.0.0
#>

$modulePath = $PSScriptRoot

# 搜索索引配置
$searchConfig = @{
    enabled = $true
    categories = @("skills", "knowledge", "faq", "docs")
    defaultLimit = 10
    maxLimit = 50
    enableSuggest = $true
    suggestLimit = 5
}

# 搜索结果存储
$searchResults = @{}

# 执行全局搜索
function Search-Global {
    param(
        [string]$Query,
        [int]$Limit = 10,
        [string[]]$Categories = @("all"),
        [string[]]$Sort = @("relevance")
    )

    if (-not $searchConfig.enabled) {
        return @{
            success = $false
            error = "Search is disabled"
        }
    }

    $results = @{}
    $total = 0

    # 按分类搜索
    foreach ($category in $Categories) {
        $categoryResults = @{}

        switch ($category) {
            "skills" {
                $categoryResults = Search-Skills -Query $Query -Limit $Limit
            }
            "knowledge" {
                $categoryResults = Search-Knowledge -Query $Query -Limit $Limit
            }
            "faq" {
                $categoryResults = Search-FAQ -Query $Query -Limit $Limit
            }
            "docs" {
                $categoryResults = Search-Docs -Query $Query -Limit $Limit
            }
            "all" {
                $categoryResults = Search-AllCategories -Query $Query -Limit $Limit
            }
        }

        # 合并结果
        foreach ($key in $categoryResults.Keys) {
            if (-not $results.ContainsKey($key)) {
                $results[$key] = @()
            }
            $results[$key] += $categoryResults[$key]
        }

        $total += ($categoryResults.Values | Measure-Object -Property Count -Sum).Sum
    }

    # 合并所有结果
    $allResults = @()
    foreach ($key in $results.Keys) {
        $allResults += $results[$key]
    }

    # 排序
    $allResults = $allResults | Sort-Object -Property relevance -Descending |
                  Select-Object -First $Limit

    # 返回结果
    return @{
        success = $true
        data = @{
            query = $Query
            results = $allResults
            total = $allResults.Count
            categories = $Categories
            limit = $Limit
        }
    }
}

# 搜索所有分类
function Search-AllCategories {
    param(
        [string]$Query,
        [int]$Limit = 10
    )

    $results = @()

    # 搜索技能
    $skillResults = Search-Skills -Query $Query -Limit ($Limit / 4)
    foreach ($result in $skillResults) {
        $results += [PSCustomObject]@{
            type = "skill"
            name = $result.name
            displayName = $result.displayName
            category = $result.category
            relevance = $result.relevance
            source = "skills"
        }
    }

    # 搜索知识
    $knowledgeResults = Search-Knowledge -Query $Query -Limit ($Limit / 4)
    foreach ($result in $knowledgeResults) {
        $results += [PSCustomObject]@{
            type = "knowledge"
            category = $result.category
            title = $result.title
            path = $result.path
            relevance = $result.relevance
            source = "knowledge"
        }
    }

    # 搜索FAQ
    $faqResults = Search-FAQ -Query $Query -Limit ($Limit / 4)
    foreach ($result in $faqResults) {
        $results += [PSCustomObject]@{
            type = "faq"
            category = $result.category
            question = $result.question
            relevance = $result.relevance
            source = "faq"
        }
    }

    # 搜索文档
    $docResults = Search-Docs -Query $Query -Limit ($Limit / 4)
    foreach ($result in $docResults) {
        $results += [PSCustomObject]@{
            type = "doc"
            title = $result.title
            path = $result.path
            relevance = $result.relevance
            source = "docs"
        }
    }

    return $results
}

# 搜索技能
function Search-Skills {
    param(
        [string]$Query,
        [int]$Limit = 10
    )

    $skills = Get-AllSkills

    $results = @()

    foreach ($skill in $skills) {
        $relevance = 0.0

        # 按名称匹配
        if ($skill.name -like "*$Query*") {
            $relevance += 0.4
        }

        # 按显示名称匹配
        if ($skill.displayName -like "*$Query*") {
            $relevance += 0.3
        }

        # 按描述匹配
        if ($skill.description -like "*$Query*") {
            $relevance += 0.2
        }

        # 按能力匹配
        foreach ($cap in $skill.capabilities) {
            if ($cap -like "*$Query*") {
                $relevance += 0.1
            }
        }

        if ($relevance > 0) {
            $results += [PSCustomObject]@{
                name = $skill.name
                displayName = $skill.displayName
                category = $skill.category
                relevance = [math]::Round($relevance, 2)
            }
        }
    }

    return $results
}

# 搜索知识
function Search-Knowledge {
    param(
        [string]$Query,
        [int]$Limit = 10
    )

    # 使用RAG检索引擎
    $ragResults = Get-Knowledge -Query $Query -Limit $Limit

    $results = @()

    foreach ($result in $ragResults) {
        $results += [PSCustomObject]@{
            category = $result.Category
            path = $result.File
            title = "Document"
            relevance = $result.Relevance
            source = "knowledge"
        }
    }

    return $results
}

# 搜索FAQ
function Search-FAQ {
    param(
        [string]$Query,
        [int]$Limit = 10
    )

    # 使用FAQ管理器
    $faqResults = Search-FAQ -Question $Query -Limit $Limit

    $results = @()

    foreach ($result in $faqResults) {
        $results += [PSCustomObject]@{
            category = $result.Category
            question = $result.Question
            relevance = $result.Relevance
            source = "faq"
        }
    }

    return $results
}

# 搜索文档
function Search-Docs {
    param(
        [string]$Query,
        [int]$Limit = 10
    )

    $docsPath = Join-Path $modulePath "..\..\docs"

    if (-not (Test-Path $docsPath)) {
        return @()
    }

    $results = @()

    $docFiles = Get-ChildItem -Path $docsPath -Recurse -Include "*.md", "*.txt"

    foreach ($file in $docFiles) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue

        if ($content -and $content -match $Query) {
            $relevance = 0.0

            # 标题匹配
            if ($file.BaseName -like "*$Query*") {
                $relevance += 0.5
            }

            # 内容匹配
            if ($content -like "*$Query*") {
                $relevance += 0.5
            }

            $results += [PSCustomObject]@{
                title = $file.BaseName
                path = $file.FullName
                relevance = [math]::Round($relevance, 2)
                source = "docs"
            }
        }
    }

    return $results | Sort-Object -Property relevance -Descending |
           Select-Object -First $Limit
}

# 获取搜索建议
function Get-SearchSuggestions {
    param(
        [string]$Query,
        [int]$Limit = 5
    )

    if (-not $searchConfig.enableSuggest) {
        return @{
            success = $false
            error = "Suggestions disabled"
        }
    }

    if ([string]::IsNullOrWhiteSpace($Query)) {
        return @{
            success = $true
            data = @()
        }
    }

    # 收集所有相关词
    $suggestions = @{}

    # 从技能中收集
    $skills = Get-AllSkills
    foreach ($skill in $skills) {
        if ($skill.name -like "*$Query*") {
            $suggestions[$skill.name] = 1.0
        }
        foreach ($cap in $skill.capabilities) {
            if ($cap -like "*$Query*") {
                $suggestions[$cap] = 0.9
            }
        }
    }

    # 从知识中收集
    $ragResults = Get-Knowledge -Query $Query -Limit 20
    foreach ($result in $ragResults) {
        $words = $result.File.Split([char[]]'\/\-_\. ')
        foreach ($word in $words) {
            if ($word.Length -ge 2 -and $word -like "*$Query*") {
                if (-not $suggestions.ContainsKey($word)) {
                    $suggestions[$word] = 0.8
                }
            }
        }
    }

    # 返回建议
    $suggestionsArray = @()
    foreach ($suggestion in $suggestions.Keys | Sort-Object -Descending) {
        $suggestionsArray += @{
            term = $suggestion
            score = $suggestions[$suggestion]
        }
    }

    return @{
        success = $true
        data = $suggestionsArray[0..($Limit - 1)]
    }
}

# 获取搜索历史
function Get-SearchHistory {
    param([int]$Limit = 20)

    $historyPath = Join-Path $modulePath "..\data\search-history.json"

    if (-not (Test-Path $historyPath)) {
        return @{
            success = $true
            data = @()
        }
    }

    $history = Get-Content $historyPath -Raw | ConvertFrom-Json

    return @{
        success = $true
        data = $history.queryHistory[-$Limit..-1]
    }
}

# 保存搜索历史
function Save-SearchHistory {
    param([string]$Query)

    $historyPath = Join-Path $modulePath "..\data\search-history.json"

    if (-not (Test-Path $historyPath)) {
        $history = [PSCustomObject]@{
            queryHistory = @()
            searchCount = 0
        }
    }
    else {
        $history = Get-Content $historyPath -Raw | ConvertFrom-Json
    }

    # 添加查询
    $history.queryHistory += [PSCustomObject]@{
        query = $Query
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }

    # 限制历史数量
    if ($history.queryHistory.Count -gt 100) {
        $history.queryHistory = $history.queryHistory[-100..-1]
    }

    $history.searchCount++

    $history | ConvertTo-Json -Depth 10 | Set-Content $historyPath
}

# 清理搜索历史
function Clear-SearchHistory {
    $historyPath = Join-Path $modulePath "..\data\search-history.json"

    if (Test-Path $historyPath) {
        Remove-Item $historyPath -Force
    }

    return @{
        success = $true
        message = "Search history cleared"
    }
}

# 命令行接口
function Show-Usage {
    Write-Host @"
Usage:
  Search-Global -Query "python database"
  Search-Global -Query "..." -Limit 10 -Categories @("skills", "knowledge")

  Get-SearchSuggestions -Query "py"

  Get-SearchHistory -Limit 20

  Clear-SearchHistory

Examples:
  Search-Global -Query "API调用"
  Get-SearchSuggestions -Query "py"
"@
}
