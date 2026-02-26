<#
.SYNOPSIS
RAG Knowledge Base Retriever

.DESCRIPTION
检索增强生成知识库的核心检索引擎

.NOTES
Author: OpenClaw Assistant
Date: 2026-02-14
Version: 1.0.0
#>

$modulePath = $PSScriptRoot
$knowledgePath = Join-Path $modulePath "..\data\knowledge-base.json"

# 加载知识库
function Get-KnowledgeBase {
    if (-not (Test-Path $knowledgePath)) {
        throw "Knowledge base not found: $knowledgePath"
    }

    $content = Get-Content $knowledgePath -Raw | ConvertFrom-Json
    return $content
}

# 保存知识库
function Save-KnowledgeBase {
    param([hashtable]$Data)

    $content = [PSCustomObject]@{
        version       = "1.0"
        lastUpdated   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        categories    = $Data.categories
        searchConfig  = $Data.searchConfig
        faqConfig     = $Data.faqConfig
        externalSources = $Data.externalSources
    }

    $content | ConvertTo-Json -Depth 10 | Set-Content $knowledgePath
}

# 多维度检索
function Get-Knowledge {
    param(
        [string]$Query,
        [string]$Category = "all",
        [string[]]$Tags = @(),
        [int]$Limit = 5,
        [switch]$IncludeExternal
    )

    $knowledge = Get-KnowledgeBase

    # 应用分类过滤
    if ($Category -ne "all") {
        $knowledge = $knowledge.categories.PSObject.Properties |
            Where-Object { $_.Name -eq $Category } |
            Select-Object -ExpandProperty Value
    }

    # 简单关键词匹配（实际应用中应使用更高级的检索算法）
    $results = @()

    foreach ($category in $knowledge.categories.PSObject.Properties) {
        if ($Category -eq "all" -or $Category -eq $category.Name) {
            foreach ($file in $category.Value.files) {
                $content = Get-Content $file -Raw -ErrorAction SilentlyContinue

                if ($content -and $content -match $Query) {
                    $results += [PSCustomObject]@{
                        Category    = $category.Name
                        File        = $file
                        Content     = $content
                        Relevance   = 1.0
                        Tags        = @()
                        Source      = "local"
                    }
                }
            }
        }
    }

    # 应用标签过滤
    if ($Tags.Count -gt 0) {
        $results = $results | Where-Object {
            $_.Tags | Where-Object { $Tags -contains $_ } | Measure-Object | Select-Object -ExpandProperty Count -Ge 1
        }
    }

    # 限制结果数量
    $results = $results | Sort-Object -Property Relevance -Descending |
        Select-Object -First $Limit

    return $results
}

# 检索FAQ
function Get-FAQ {
    param(
        [string]$Question,
        [string]$Category = "all",
        [int]$Limit = 3
    )

    $faqPath = Join-Path $modulePath "..\data\faq"

    if (-not (Test-Path $faqPath)) {
        return @()
    }

    $results = @()

    # 遍历FAQ目录
    $faqFiles = Get-ChildItem -Path $faqPath -Recurse -Filter "*.md"

    foreach ($file in $faqFiles) {
        $content = Get-Content $file -Raw -ErrorAction SilentlyContinue

        if ($content -and $content -match $Question) {
            $results += [PSCustomObject]@{
                File     = $file.FullName
                Category = $file.Directory.Name
                Question = $Question
                Answer   = $content
                Relevance = 1.0
            }
        }
    }

    $results = $results | Sort-Object -Property Relevance -Descending |
        Select-Object -First $Limit

    return $results
}

# 添加文档
function Add-Document {
    param(
        [string]$Path,
        [string]$Category,
        [string[]]$Tags = @(),
        [string]$Description = ""
    )

    $knowledge = Get-KnowledgeBase

    if (-not $knowledge.categories.PSObject.Properties.Name -contains $Category) {
        throw "Invalid category: $Category"
    }

    if (-not (Test-Path $Path)) {
        throw "File not found: $Path"
    }

    $doc = [PSCustomObject]@{
        path     = $Path
        tags     = $Tags
        addedAt  = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        description = $Description
    }

    $knowledge.categories.$Category.files += $doc

    Save-KnowledgeBase -Data $knowledge

    Write-Host "Document added to category '$Category': $Path" -ForegroundColor Green
}

# 索引文档
function Update-KnowledgeIndex {
    param(
        [switch]$Rebuild
    )

    $knowledge = Get-KnowledgeBase

    foreach ($category in $knowledge.categories.PSObject.Properties) {
        $files = @()

        foreach ($file in $category.Value.files) {
            if (Test-Path $file.path) {
                $files += $file.path
            }
        }

        $category.Value.count = $files.Count
        $category.Value.files = $files
    }

    Save-KnowledgeBase -Data $knowledge

    Write-Host "Knowledge index updated" -ForegroundColor Green
}

# 获取知识统计
function Get-KnowledgeStats {
    $knowledge = Get-KnowledgeBase

    $stats = [PSCustomObject]@{
        TotalCategories = $knowledge.categories.PSObject.Properties.Count
        TotalDocuments  = ($knowledge.categories.PSObject.Properties |
            Measure-Object -Property Count -Sum).Sum
        ExternalSources = $knowledge.externalSources.Count
        SearchCache     = if ($knowledge.searchConfig.enableCaching) {
            "Enabled (TTL: $($knowledge.searchConfig.cacheTTL)s)"
        } else {
            "Disabled"
        }
    }

    return $stats
}

# 批量添加文档
function New-BatchDocuments {
    param(
        [hashtable[]]$Documents,
        [string]$Category
    )

    foreach ($doc in $Documents) {
        Add-Document -Path $doc.path -Category $Category `
                     -Tags $doc.tags -Description $doc.description
    }
}

# 命令行接口
function Show-Usage {
    Write-Host @"
Usage:
  Get-Knowledge -Query "search term"
  Get-Knowledge -Query "..." -Category "code" -Limit 5
  Get-Knowledge -Query "..." -Tags ["javascript", "api"]

  Get-FAQ -Question "how to use api"
  Get-FAQ -Question "..." -Limit 3

  Add-Document -Path "docs/api-guide.md" -Category "documentation"
  Add-Document -Path "..." -Category "..." -Tags @("javascript", "api")

  Update-KnowledgeIndex

  Get-KnowledgeStats

Examples:
  Get-Knowledge -Query "API调用"
  Get-Knowledge -Query "..." -Category code -Limit 3
  Add-Document -Path "docs/..." -Category documentation -Tags @("api", "rest")
"@
}

# 默认执行检索
if ($args.Count -gt 0) {
    $queryParam = $args[0]
    $categoryParam = if ($args -contains "-Category") { $args[$args.IndexOf("-Category") + 1] } else { "all" }
    $limitParam = if ($args -contains "-Limit") { [int]$args[$args.IndexOf("-Limit") + 1] } else { 5 }

    if ($queryParam) {
        $results = Get-Knowledge -Query $queryParam -Category $categoryParam -Limit $limitParam

        Write-Host "`n=== Search Results ===" -ForegroundColor Cyan
        Write-Host "Found $($results.Count) results`n" -ForegroundColor Gray

        foreach ($result in $results) {
            Write-Host "Category: $($result.Category)" -ForegroundColor Yellow
            Write-Host "File: $($result.File)" -ForegroundColor White
            Write-Host "Content: $($result.Content.Substring(0, [Math]::Min(100, $result.Content.Length)))..." -ForegroundColor Gray
            Write-Host ""
        }
    }
}

<#
.EXAMPLE
Get-Knowledge -Query "API调用"
Get-Knowledge -Query "..." -Category code -Limit 3
Add-Document -Path "docs/api-guide.md" -Category "documentation"
Update-KnowledgeIndex
Get-KnowledgeStats
#>
