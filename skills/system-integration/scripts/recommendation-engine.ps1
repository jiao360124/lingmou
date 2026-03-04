<#
.SYNOPSIS
Recommendation Engine

.DESCRIPTION
个性化推荐引擎

.NOTES
Author: OpenClaw Assistant
Date: 2026-02-16
Version: 1.0.0
#>

$modulePath = $PSScriptRoot

# 推荐算法配置
$recommendConfig = @{
    enabled = $true
    behaviorWeight = 0.5
    popularityWeight = 0.3
    timeDecay = $true
    timeDecayFactor = 0.95
}

# 推荐结果缓存
$recommendationCache = @{}

# 推荐类型
$recommendationTypes = @(
    "skill",
    "task",
    "content"
)

# 技能推荐
function Get-SkillRecommendations {
    param(
        [string]$UserId,
        [int]$Limit = 5,
        [string]$Strategy = "behavior",
        [hashtable]$Context = @{}
    )

    if (-not $recommendConfig.enabled) {
        return @{
            success = $false
            error = "Recommendations disabled"
        }
    }

    $recommendations = @()

    switch ($Strategy) {
        "behavior" {
            $recommendations = Get-RecommendationsByBehavior -UserId $UserId `
                                                              -Limit $Limit
        }
        "popularity" {
            $recommendations = Get-RecommendationsByPopularity `
                                        -Limit $Limit
        }
        "context" {
            $recommendations = Get-RecommendationsByContext `
                                        -Context $Context `
                                        -Limit $Limit
        }
        "mixed" {
            $behavior = Get-RecommendationsByBehavior -UserId $UserId -Limit ($Limit / 2)
            $popularity = Get-RecommendationsByPopularity -Limit ($Limit / 2)
            $recommendations = @($behavior + $popularity) | Sort-Object -Property score -Descending |
                               Select-Object -First $Limit
        }
    }

    return @{
        success = $true
        type = "skill"
        recommendations = $recommendations
        strategy = $Strategy
        limit = $Limit
    }
}

# 基于行为的推荐
function Get-RecommendationsByBehavior {
    param(
        [string]$UserId,
        [int]$Limit = 5
    )

    $skills = Get-AllSkills
    $behavior = GetUserBehavior -UserId $UserId

    $recommendations = @()

    foreach ($skill in $skills) {
        $score = 0.0

        # 使用频率
        if ($behavior.skillsUsage.ContainsKey($skill.name)) {
            $usageCount = $behavior.skillsUsage[$skill.name]
            $score += $usageCount * 0.3
        }

        # 最近使用时间
        if ($behavior.skillRecent.ContainsKey($skill.name)) {
            $daysAgo = (Get-Date) - $behavior.skillRecent[$skill.name]
            $score += [math]::Max(0, 1 - $daysAgo.Days * 0.05)
        }

        # 分类匹配
        if ($behavior.categories.Contains($skill.category)) {
            $score += 0.1
        }

        if ($score > 0) {
            $recommendations += [PSCustomObject]@{
                name = $skill.name
                displayName = $skill.displayName
                category = $skill.category
                score = [math]::Round($score, 2)
                reason = "Based on your usage pattern"
            }
        }
    }

    return $recommendations | Sort-Object -Property score -Descending |
           Select-Object -First $Limit
}

# 基于流行度的推荐
function Get-RecommendationsByPopularity {
    param([int]$Limit = 5)

    $skills = Get-AllSkills

    $recommendations = @()

    foreach ($skill in $skills) {
        $score = 0.0

        # 使用次数
        if ($skill.usageCount) {
            $score += $skill.usageCount * 0.5
        }

        # 星标数
        if ($skill.starCount) {
            $score += $skill.starCount * 0.2
        }

        # 分类流行度
        $categoryPopularity = Get-CategoryPopularity -Category $skill.category
        $score += $categoryPopularity * 0.3

        if ($score > 0) {
            $recommendations += [PSCustomObject]@{
                name = $skill.name
                displayName = $skill.displayName
                category = $skill.category
                score = [math]::Round($score, 2)
                reason = "Popular among users"
            }
        }
    }

    return $recommendations | Sort-Object -Property score -Descending |
           Select-Object -First $Limit
}

# 基于上下文的推荐
function Get-RecommendationsByContext {
    param(
        [hashtable]$Context,
        [int]$Limit = 5
    )

    $skills = Get-AllSkills

    $recommendations = @()

    foreach ($skill in $skills) {
        $score = 0.0

        # 分类匹配
        if ($Context.category -and $skill.category -eq $Context.category) {
            $score += 0.5
        }

        # 能力匹配
        if ($Context.capabilities) {
            $matchCount = 0
            foreach ($cap in $Context.capabilities) {
                if ($skill.capabilities -contains $cap) {
                    $matchCount++
                }
            }
            $score += ($matchCount / $Context.capabilities.Count) * 0.4
        }

        # 语言匹配
        if ($Context.language -and $skill.language -and $skill.language -contains $Context.language) {
            $score += 0.3
        }

        # 任务匹配
        if ($Context.task) {
            if ($skill.description -like "*$($Context.task)*") {
                $score += 0.3
            }
        }

        if ($score > 0) {
            $recommendations += [PSCustomObject]@{
                name = $skill.name
                displayName = $skill.displayName
                category = $skill.category
                score = [math]::Round($score, 2)
                reason = "Matches your current context"
            }
        }
    }

    return $recommendations | Sort-Object -Property score -Descending |
           Select-Object -First $Limit
}

# 任务推荐
function Get-TaskRecommendations {
    param(
        [string]$UserId,
        [int]$Limit = 5,
        [string]$Strategy = "behavior"
    )

    $tasks = Get-TaskSuggestions

    $recommendations = @()

    switch ($Strategy) {
        "behavior" {
            $recommendations = Get-TaskRecommendationsByBehavior `
                                        -Tasks $tasks `
                                        -UserId $UserId `
                                        -Limit $Limit
        }
        "priority" {
            $recommendations = Get-TaskRecommendationsByPriority `
                                        -Tasks $tasks `
                                        -Limit $Limit
        }
    }

    return @{
        success = $true
        type = "task"
        recommendations = $recommendations
        strategy = $Strategy
        limit = $Limit
    }
}

# 基于行为的任务推荐
function Get-TaskRecommendationsByBehavior {
    param(
        [hashtable[]]$Tasks,
        [string]$UserId,
        [int]$Limit = 5
    )

    $recommendations = @()

    foreach ($task in $Tasks) {
        $score = 0.0

        # 领域匹配
        if ($task.domain -and GetUserBehavior -UserId $UserId -Categories.Contains($task.domain)) {
            $score += 0.4
        }

        # 频率匹配
        if ($task.frequency -eq "daily" -and GetUserBehavior -UserId $UserId -SkillsFrequency "daily") {
            $score += 0.3
        }

        if ($score > 0) {
            $recommendations += [PSCustomObject]@{
                id = $task.id
                title = $task.title
                domain = $task.domain
                frequency = $task.frequency
                score = [math]::Round($score, 2)
                reason = "Matches your workflow"
            }
        }
    }

    return $recommendations | Sort-Object -Property score -Descending |
           Select-Object -First $Limit
}

# 基于优先级的任务推荐
function Get-TaskRecommendationsByPriority {
    param(
        [hashtable[]]$Tasks,
        [int]$Limit = 5
    )

    return $Tasks | Sort-Object -Property priority -Descending |
           Select-Object -First $Limit
}

# 内容推荐
function Get-ContentRecommendations {
    param(
        [string]$UserId,
        [int]$Limit = 5,
        [string]$Type = "docs"
    )

    $contents = Get-ContentSuggestions -Type $Type

    $recommendations = @()

    foreach ($content in $contents) {
        $score = 0.0

        # 分类匹配
        if ($content.category -and GetUserBehavior -UserId $UserId -Categories.Contains($content.category)) {
            $score += 0.4
        }

        # 标签匹配
        if ($content.tags) {
            $matchCount = 0
            foreach ($tag in $content.tags) {
                if ($GetUserBehavior -UserId $UserId -Tags.Contains($tag)) {
                    $matchCount++
                }
            }
            $score += ($matchCount / $content.tags.Count) * 0.3
        }

        if ($score > 0) {
            $recommendations += [PSCustomObject]@{
                id = $content.id
                title = $content.title
                category = $content.category
                type = $content.type
                score = [math]::Round($score, 2)
                reason = "Relevant to your interests"
            }
        }
    }

    return $recommendations | Sort-Object -Property score -Descending |
           Select-Object -First $Limit
}

# 推荐统计
function Get-RecommendationStats {
    $stats = [PSCustomObject]@{
        totalSkills = (Get-AllSkills).Count
        totalTasks = (Get-TaskSuggestions).Count
        totalContent = (Get-ContentSuggestions).Count
        recommendationCount = 0
    }

    return @{
        success = $true
        data = $stats
    }
}

# 更新用户行为
function Update-UserBehavior {
    param(
        [string]$UserId,
        [string]$SkillName,
        [hashtable]$Context = @{}
    )

    $behaviorPath = Join-Path $modulePath "..\data\user-behavior.json"

    if (-not (Test-Path $behaviorPath)) {
        $behavior = [PSCustomObject]@{
            users = @()
        }
    }
    else {
        $behavior = Get-Content $behaviorPath -Raw | ConvertFrom-Json
    }

    # 查找或创建用户行为
    $userBehavior = $behavior.users | Where-Object { $_.userId -eq $UserId }

    if (-not $userBehavior) {
        $userBehavior = [PSCustomObject]@{
            userId = $UserId
            categories = @()
            tags = @()
            skillsUsage = @{}
            skillRecent = @{}
            tasksCompleted = @{}
            lastActive = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        $behavior.users += $userBehavior
    }

    # 更新使用统计
    if (-not $userBehavior.skillsUsage.ContainsKey($SkillName)) {
        $userBehavior.skillsUsage[$SkillName] = 0
    }
    $userBehavior.skillsUsage[$SkillName]++

    # 更新最近使用时间
    $userBehavior.skillRecent[$SkillName] = Get-Date

    # 更新分类
    $skill = Get-Skill -Name $SkillName
    if ($skill) {
        if (-not $userBehavior.categories.Contains($skill.category)) {
            $userBehavior.categories += $skill.category
        }
    }

    # 保存
    $behavior | ConvertTo-Json -Depth 10 | Set-Content $behaviorPath

    return @{
        success = $true
    }
}

# 获取用户行为
function GetUserBehavior {
    param(
        [string]$UserId
    )

    $behaviorPath = Join-Path $modulePath "..\data\user-behavior.json"

    if (-not (Test-Path $behaviorPath)) {
        return @{
            skillsUsage = @{}
            skillRecent = @{}
            categories = @()
            tags = @()
        }
    }

    $behavior = Get-Content $behaviorPath -Raw | ConvertFrom-Json
    $userBehavior = $behavior.users | Where-Object { $_.userId -eq $UserId }

    if (-not $userBehavior) {
        return @{
            skillsUsage = @{}
            skillRecent = @{}
            categories = @()
            tags = @()
        }
    }

    return @{
        skillsUsage = $userBehavior.skillsUsage
        skillRecent = $userBehavior.skillRecent
        categories = $userBehavior.categories
        tags = $userBehavior.tags
    }
}

# 命令行接口
function Show-Usage {
    Write-Host @"
Usage:
  Get-SkillRecommendations -UserId "123" -Limit 5 -Strategy "mixed"
  Get-TaskRecommendations -UserId "123" -Limit 5
  Get-ContentRecommendations -UserId "123" -Type "docs"

  Update-UserBehavior -UserId "123" -SkillName "copilot"

  Get-RecommendationStats

Examples:
  Get-SkillRecommendations -UserId "user1" -Strategy "behavior"
  Get-TaskRecommendations -UserId "user1" -Limit 3
"@
}
