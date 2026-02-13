# Linkage Router - 联动路由器
# 识别任务类型并匹配最佳技能

param(
    [Parameter(Mandatory=$false)]
    [string]$Action = "route"
)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$dataPath = Join-Path $scriptPath "..\data"
$metaFile = Join-Path $dataPath "skill-meta.json"

# Load skill metadata
if (Test-Path $metaFile) {
    $metadata = Get-Content -Path $metaFile -Raw -Encoding utf8 | ConvertFrom-Json
} else {
    # Fallback: load built-in skills
    $metadata = @{
        skills = @(
            @{
                id = "copilot"; capabilities = @("code"); inputFormat = @{ type = "code" }
            },
            @{
                id = "auto-gpt"; capabilities = @("task"); inputFormat = @{ type = "task" }
            },
            @{
                id = "rag"; capabilities = @("query"); inputFormat = @{ type = "query" }
            },
            @{
                id = "exa-web-search-free"; capabilities = @("search"); inputFormat = @{ type = "query" }
            }
        )
    }
}

# Task type categorization
function Get-TaskType {
    param(
        [string]$Input
    )

    $input = $Input.ToLower()

    # Code-related tasks
    if ($input -match "(code|function|method|class|script|implementation)" -or
        $Input -match "\.(js|py|ps1|sh|ts|java|c\+\+|c#)" -or
        $Input -match "^(write|create|implement|develop)\s*(a\s+)?(code|function|method|class|script)" -or
        $Input -match "refactor|optimize|debug|test") {
        return @{
            type = "code"
            confidence = "high"
        }
    }

    # Query/research tasks
    if ($input -match "(search|find|lookup|retrieve|get.*information)" -or
        $Input -match "(what|how|why|explain|describe|define)" -or
        $Input -match "news|weather|latest|update|trending") {
        return @{
            type = "query"
            confidence = "high"
        }
    }

    # Task automation
    if ($input -match "(automate|schedule|task|workflow|process)" -or
        $Input -match "execute|run|perform|do" -or
        $Input -match "goal.*achieve|complete.*task") {
        return @{
            type = "task"
            confidence = "high"
        }
    }

    # Analysis/explanation tasks
    if ($input -match "(analyze|explain|breakdown|review|evaluate)" -or
        $Input -match "(understand|interpret|clarify)" -or
        $Input -match "(diagram|visualize|show)" -or
        $Input -match "explain.*code|analyze.*data") {
        return @{
            type = "analysis"
            confidence = "high"
        }
    }

    # Knowledge retrieval
    if ($input -match "(knowledge|memory|remember|recall)" -or
        $Input -match "(learn|study|teach|tutorial|guide)") {
        return @{
            type = "knowledge"
            confidence = "medium"
        }
    }

    # Generic/default
    return @{
        type = "general"
        confidence = "low"
    }
}

# Match skill based on task type
function Find-BestSkill {
    param(
        [string]$Input
    )

    $taskType = Get-TaskType -Input $Input
    Write-Host "`n任务类型: $($taskType.type) (置信度: $($taskType.confidence))" -ForegroundColor Cyan

    # Map task types to skills
    $taskSkillMap = @{
        "code" = @("copilot", "code-mentor", "auto-gpt")
        "query" = @("rag", "exa-web-search-free", "database")
        "task" = @("auto-gpt")
        "analysis" = @("copilot", "prompt-engineering", "rag")
        "knowledge" = @("rag", "exa-web-search-free")
        "general" = @("auto-gpt", "rag", "copilot")
    }

    $candidates = $taskSkillMap[$taskType.type] | ForEach-Object {
        $skill = $metadata.skills | Where-Object { $_.id -eq $_ }
        if ($skill) {
            @{
                skill = $skill
                match = $taskType.type
                score = switch ($taskType.confidence) {
                    "high" { 1.0 }
                    "medium" { 0.7 }
                    "low" { 0.4 }
                    default { 0.5 }
                }
            }
        }
    } | Where-Object { $_ -ne $null }

    # Sort by score
    $candidates = $candidates | Sort-Object -Property score -Descending

    if ($candidates.Count -eq 0) {
        return @{
            skill = $null
            fallback = "auto-gpt"
        }
    }

    # Return top candidate
    $best = $candidates[0]
    Write-Host "`n最佳匹配技能:" -ForegroundColor Green
    Write-Host "  ID: $($best.skill.id)" -ForegroundColor Yellow
    Write-Host "  名称: $($best.skill.name)" -ForegroundColor White
    Write-Host "  匹配得分: $($best.score)" -ForegroundColor Gray

    return $best
}

# Route and transform parameters
function Invoke-Route {
    param(
        [string]$Input,
        [hashtable]$Context = @{}
    )

    Write-Host "`n=== 联动路由 ===" -ForegroundColor Cyan
    Write-Host "输入: $Input" -ForegroundColor White

    $route = Find-BestSkill -Input $Input

    if ($route.skill) {
        Write-Host "`n路由成功!" -ForegroundColor Green
        Write-Host "调用技能: $($route.skill.id)" -ForegroundColor Yellow

        # Check if skill has a registration script
        $regScript = Join-Path $PSScriptRoot "$($route.skill.id).ps1"
        if (Test-Path $regScript) {
            Write-Host "发现注册脚本: $regScript" -ForegroundColor Gray
            # TODO: Load and invoke skill
        }

        return @{
            success = $true
            skillId = $route.skill.id
            skillName = $route.skill.name
            taskType = $route.match
            confidence = $route.score
            input = $Input
        }
    } else {
        Write-Host "`n路由失败，使用回退技能" -ForegroundColor Yellow
        Write-Host "回退到: $($route.fallback)" -ForegroundColor Red

        return @{
            success = $true
            skillId = $route.fallback
            fallback = $true
            input = $Input
        }
    }
}

# Action handlers
switch ($Action) {
    "route" {
        param(
            [Parameter(Mandatory=$false)]
            [string]$Input = ""
        )

        if ([string]::IsNullOrWhiteSpace($Input)) {
            Write-Host "错误: 请提供输入文本" -ForegroundColor Red
            exit 1
        }

        $result = Invoke-Route -Input $Input
        return $result
    }

    "test" {
        param(
            [Parameter(Mandatory=$false)]
            [string[]]$TestCases = @(
                "Write a function to calculate fibonacci"
                "Search for the latest AI news"
                "Analyze this code snippet: var x = 10 * 2 + 3;"
                "Create a workflow to automate deployment"
                "Explain how HTTP works"
            )
        )

        Write-Host "`n=== 联动路由测试 ===" -ForegroundColor Cyan

        foreach ($test in $TestCases) {
            Write-Host "`n--- 测试案例: $test ---" -ForegroundColor Yellow
            $result = Invoke-Route -Input $test
            if ($result.skillId) {
                Write-Host "✓ 路由到: $($result.skillId)" -ForegroundColor Green
            } else {
                Write-Host "✗ 路由失败" -ForegroundColor Red
            }
        }
    }

    "list-task-types" {
        $taskTypes = Get-TaskType -Input "test input"
        Write-Host "`n=== 任务类型分类 ===" -ForegroundColor Cyan

        $taskTypes.GetEnumerator() | ForEach-Object {
            Write-Host "`n类型: $($_.Key)" -ForegroundColor Green
            Write-Host "  描述: $($_.Value)" -ForegroundColor Gray
        }
    }

    "help" {
        Write-Host "`n使用方法:" -ForegroundColor Yellow
        Write-Host "  route -Input '<输入文本>' - 路由输入文本到最佳技能"
        Write-Host "  test - 运行测试案例"
        Write-Host "  list-task-types - 显示任务类型分类"
    }

    "default" {
        Write-Host "使用方法: linkage-router.ps1 -Action <action> [参数]" -ForegroundColor Yellow
        Write-Host "`n可用操作:" -ForegroundColor Cyan
        Write-Host "  route -Input '<输入>' - 路由输入"
        Write-Host "  test - 测试路由"
        Write-Host "  list-task-types - 列出任务类型"
        Write-Host "  help - 显示帮助"
    }
}

# Export main function
Export-ModuleMember -Function "Get-TaskType", "Find-BestSkill", "Invoke-Route"
