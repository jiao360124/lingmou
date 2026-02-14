<#
.SYNOPSIS
Agent注册和发现系统

.DESCRIPTION
管理Agent的注册、发现和推荐，基于能力声明进行智能匹配。

.PARAMeter Mode
操作模式：list, find, recommend

.PARAMeter Capability
按能力搜索Agent

.PARAMeter RequiredAgents
必需的Agent ID列表

.EXAMPLE
.\agent-registry.ps1 -Mode find -Capability "coding"
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("list", "find", "recommend")]
    [string]$Mode,

    [Parameter(Mandatory=$false)]
    [string]$Capability,

    [Parameter(Mandatory=$false)]
    [string[]]$RequiredAgents
)

function Load-Agents {
    $configPath = ".\skills\agent-collaboration\agents.json"
    if (Test-Path $configPath) {
        return Get-Content $configPath -Raw | ConvertFrom-Json
    }

    # 返回默认Agent
    return [PSCustomObject]@{
        agents = @(
            [PSCustomObject]@{
                id = "coder"
                name = "编码专家"
                capabilities = @("coding","refactoring","debugging","performance")
                weight = 0.9
                icon = "💻"
            }
        )
    }
}

function Find-Agent-by-Capability {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Capability,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]$AgentConfig
    )

    $agents = $AgentConfig.agents | Where-Object {
        $_.capabilities -contains $Capability
    }

    if ($agents.Count -eq 0) {
        Write-Warning "没有找到匹配能力的Agent: $Capability"
        return @()
    }

    return $agents
}

function Recommend-Agents {
    param(
        [Parameter(Mandatory=$false)]
        [string[]]$RequiredAgents,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]$AgentConfig
    )

    # 按权重排序
    $sorted = $AgentConfig.agents | Sort-Object { $_.weight } -Descending

    # 用户指定的Agent
    if ($RequiredAgents) {
        $specified = $sorted | Where-Object { $_.id -in $RequiredAgents }
        $others = $sorted | Where-Object { $_.id -notin $RequiredAgents }
        return $specified + $others
    }

    return $sorted
}

function Show-Agent-List {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$AgentConfig
    )

    Write-Host "`n📋 Agent列表" -ForegroundColor Cyan
    Write-Host "====================" -ForegroundColor Cyan

    foreach ($agent in $AgentConfig.agents) {
        $capabilities = $agent.capabilities -join ", "
        Write-Host "`n[{$($agent.id)}] $($agent.icon) $($agent.name)" -ForegroundColor Yellow
        Write-Host "  能力: $capabilities" -ForegroundColor Gray
        Write-Host "  权重: $([math]::Round($agent.weight * 100, 1)))% | $([math]::Round($agent.weight * 100, 1)))%" -ForegroundColor Gray
    }

    Write-Host "`n====================" -ForegroundColor Cyan
}

function Show-Agent-Recommendations {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Agents,

        [Parameter(Mandatory=$true)]
        [string[]]$RequiredAgents
    )

    Write-Host "`n🎯 Agent推荐" -ForegroundColor Cyan
    Write-Host "====================" -ForegroundColor Cyan

    if ($RequiredAgents.Count -gt 0) {
        Write-Host "`n用户指定: $($RequiredAgents -join ', ')" -ForegroundColor Yellow
    }

    foreach ($agent in $Agents) {
        $capabilities = $agent.capabilities -join ", "
        Write-Host "`n[{$($agent.id)}] $($agent.icon) $($agent.name)" -ForegroundColor Green
        Write-Host "  能力: $capabilities" -ForegroundColor Gray
        Write-Host "  权重: $([math]::Round($agent.weight * 100, 1)))%" -ForegroundColor Gray
    }

    Write-Host "`n====================" -ForegroundColor Cyan
}

# 主程序入口
$AgentConfig = Load-Agents

switch ($Mode) {
    "list" {
        Show-Agent-List -AgentConfig $AgentConfig
    }
    "find" {
        if ([string]::IsNullOrEmpty($Capability)) {
            Write-Error "错误: 必须指定Capability参数"
            exit 1
        }
        $found = Find-Agent-by-Capability -Capability $Capability -AgentConfig $AgentConfig
        return $found
    }
    "recommend" {
        $recommended = Recommend-Agents -RequiredAgents $RequiredAgents -AgentConfig $AgentConfig
        Show-Agent-Recommendations -Agents $recommended -RequiredAgents $RequiredAgents
        return $recommended
    }
}
