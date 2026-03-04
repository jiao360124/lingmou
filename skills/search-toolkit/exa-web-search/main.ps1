<#
.SYNOPSIS
智能搜索系统 - 主程序入口

.DESCRIPTION
全栈智能搜索系统，支持本地文件、Web搜索、内部记忆、外部知识库的多源整合和智能去重。

.EXAMPLE
.\main.ps1 -Action search -Query "React hooks" -Format "markdown"

.EXAMPLE
.\main.ps1 -Action search -Query "性能优化" -Sources "local,memory" -Weights @{"rag"=0.9; "moltbook"=0.8; "memory"=0.7}
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Action = "search",

    [Parameter(Mandatory=$false)]
    [string]$Query = "",

    [Parameter(Mandatory=$false)]
    [string[]]$Sources = @("local", "memory", "web", "rag"),

    [Parameter(Mandatory=$false)]
    [PSCustomObject]$Weights,

    [Parameter(Mandatory=$false)]
    [string]$Format = "markdown",

    [Parameter(Mandatory=$false)]
    [int]$MaxResults = 10
)

function Initialize-Weights {
    $weightsPath = ".\skills\smart-search\weights.json"
    if (Test-Path $weightsPath) {
        $config = Get-Content $weightsPath -Raw | ConvertFrom-Json
        return $config.user_custom.current
    }

    # 默认权重
    return @{
        rag = 0.9
        memory = 0.7
        local = 0.6
        web = 0.5
        moltbook = 0.4
        api = 0.3
    }
}

function Search-LocalFiles {
    return & .\scripts\search-local.ps1 -Query $Query -MaxResults (4 * $MaxResults)
}

function Search-Memory {
    return & .\scripts\search-memory.ps1 -Query $Query -MaxResults (2 * $MaxResults)
}

function Search-Web {
    return & .\scripts\search-web.ps1 -Query $Query -Results (3 * $MaxResults)
}

function Search-RAG {
    # RAG知识库搜索 - 暂时返回空，后续扩展
    Write-Host "📚 RAG知识库搜索: $Query" -ForegroundColor Cyan
    Write-Host "  RAG知识库搜索功能待扩展" -ForegroundColor Yellow
    return @()
}

function Run-Phase4Search {
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$Sources,

        [Parameter(Mandatory=$true)]
        [string]$Query,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Weights,

        [Parameter(Mandatory=$false)]
        [string]$Format = "markdown",

        [Parameter(Mandatory=$false)]
        [int]$MaxResults = 10
    )

    Write-Host "`n🚀 Phase 4: 智能搜索系统" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  查询: $Query" -ForegroundColor Yellow
    Write-Host "  搜索源: $($Sources -join ', ')" -ForegroundColor Yellow
    Write-Host "  格式: $Format" -ForegroundColor Yellow
    Write-Host "========================================`n" -ForegroundColor Cyan

    # 初始化权重
    $finalWeights = Initialize-Weights

    # 合并用户自定义权重
    if ($Weights) {
        $finalWeights = $finalWeights.PSObject.Properties | ForEach-Object {
            $key = $_.Name
            if ($Weights.$key -ne $null) {
                @{ $key = $Weights.$key }
            } else {
                @{ $key = $_.Value }
            }
        } | ForEach-Object { $_ } | ConvertTo-Dictionary

        $finalWeights = @{
            rag = if ($Weights.rag) { $Weights.rag } else { 0.9 }
            memory = if ($Weights.memory) { $Weights.memory } else { 0.7 }
            local = if ($Weights.local) { $Weights.local } else { 0.6 }
            web = if ($Weights.web) { $Weights.web } else { 0.5 }
            moltbook = if ($Weights.moltbook) { $Weights.moltbook } else { 0.4 }
            api = if ($Weights.api) { $Weights.api } else { 0.3 }
        }
    }

    # 创建权重对象
    $weightsObj = [PSCustomObject]$finalWeights

    # 搜索各来源
    $allResults = @()

    Write-Host "`n🔍 开始多源搜索..." -ForegroundColor Cyan

    foreach ($source in $Sources) {
        switch ($source) {
            "local" {
                $results = Search-LocalFiles
                $allResults += $results
            }
            "memory" {
                $results = Search-Memory
                $allResults += $results
            }
            "web" {
                $results = Search-Web
                $allResults += $results
            }
            "rag" {
                $results = Search-RAG
                $allResults += $results
            }
            default {
                Write-Warning "未知搜索源: $source"
            }
        }
    }

    if ($allResults.Count -eq 0) {
        Write-Host "`n❌ 未找到任何结果" -ForegroundColor Red
        return
    }

    Write-Host "`n✅ 搜索完成，开始智能去重..." -ForegroundColor Green

    # 智能去重
    $uniqueResults = & .\scripts\deduplicator.ps1 -Results $allResults -Query $Query -SimilarityThreshold 0.85

    if ($uniqueResults.Count -eq 0) {
        Write-Host "`n❌ 去重后无结果" -ForegroundColor Red
        return
    }

    Write-Host "`n✅ 去重完成，整合结果..." -ForegroundColor Green

    # 整合和排序
    $finalResults = & .\scripts\result-integrator.ps1 -Results $uniqueResults -Weights $weightsObj -Query $Query

    if ($Format -eq "json") {
        # JSON格式直接输出
        $jsonOutput = & .\scripts\output-formatter.ps1 -Results $finalResults -Format "json" -Query $Query
        Write-Output $jsonOutput
    } else {
        # Markdown格式输出
        $markdownOutput = & .\scripts\output-formatter.ps1 -Results $finalResults -Format "markdown" -Query $Query
        Write-Host "`n$markdownOutput" -ForegroundColor Green
    }

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  完成！" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Cyan
}

# 主程序入口
if ($Action -eq "search") {
    if ([string]::IsNullOrEmpty($Query)) {
        Write-Host "❌ 错误: 查询不能为空" -ForegroundColor Red
        Write-Host "用法: .\main.ps1 -Action search -Query '搜索内容'" -ForegroundColor Yellow
        exit 1
    }

    Run-Phase4Search -Sources $Sources -Query $Query -Weights $Weights -Format $Format -MaxResults $MaxResults
} else {
    Write-Host "❌ 未知操作: $Action" -ForegroundColor Red
    Write-Host "可用操作: search" -ForegroundColor Yellow
    exit 1
}
