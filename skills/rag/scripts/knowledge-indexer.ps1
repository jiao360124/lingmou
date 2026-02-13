<#
.SYNOPSIS
RAG Knowledge Base Indexer

.DESCRIPTION
索引和管理知识库中的文档和代码示例

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

# 索引文档
function Index-Document {
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
        size     = (Get-Item $Path).Length
        description = $Description
    }

    $knowledge.categories.$Category.files += $doc

    Save-KnowledgeBase -Data $knowledge

    Write-Host "Document indexed: $Path" -ForegroundColor Green
}

# 索引目录
function Index-Directory {
    param(
        [string]$Path,
        [string]$Category,
        [string[]]$Tags = @()
    )

    if (-not (Test-Path $Path)) {
        throw "Directory not found: $Path"
    }

    $files = Get-ChildItem -Path $Path -Recurse -File

    foreach ($file in $files) {
        $ext = $file.Extension.ToLower()
        if ($ext -in @(".md", ".txt", ".json", ".xml", ".html", ".rst")) {
            Index-Document -Path $file.FullName -Category $Category -Tags $Tags
        }
    }

    Write-Host "Indexed $($files.Count) documents" -ForegroundColor Green
}

# 重建索引
function Rebuild-Index {
    param(
        [string[]]$Categories = @()
    )

    $knowledge = Get-KnowledgeBase

    if ($Categories.Count -eq 0) {
        $Categories = $knowledge.categories.PSObject.Properties.Name
    }

    foreach ($category in $Categories) {
        if ($knowledge.categories.PSObject.Properties.Name -contains $category) {
            $files = @()

            foreach ($doc in $knowledge.categories.$Category.files) {
                if (Test-Path $doc.path) {
                    $files += $doc.path
                }
            }

            $knowledge.categories.$Category.count = $files.Count
            $knowledge.categories.$Category.files = $files

            Write-Host "Rebuilt index for category '$Category': $($files.Count) files" -ForegroundColor Cyan
        }
    }

    Save-KnowledgeBase -Data $knowledge

    Write-Host "Index rebuilt" -ForegroundColor Green
}

# 索引代码示例
function Index-CodeExamples {
    param(
        [string]$Path = "code-examples",
        [string[]]$Languages = @("javascript", "python", "go", "rust")
    )

    $knowledge = Get-KnowledgeBase

    foreach ($lang in $Languages) {
        $langPath = Join-Path $modulePath "..\$Path\$lang"

        if (Test-Path $langPath) {
            $files = Get-ChildItem -Path $langPath -Recurse -Filter "*.md"

            foreach ($file in $files) {
                $tags = @("code", "example", $lang)

                Index-Document -Path $file.FullName -Category "code-examples" -Tags $tags
            }

            Write-Host "Indexed code examples for '$lang': $($files.Count) files" -ForegroundColor Cyan
        }
    }
}

# 索引FAQ
function Index-FAQs {
    param(
        [string]$Path = "faq"
    )

    $knowledge = Get-KnowledgeBase

    $faqPath = Join-Path $modulePath "..\$Path"

    if (Test-Path $faqPath) {
        $categories = Get-ChildItem -Path $faqPath -Directory

        foreach ($cat in $categories) {
            $files = Get-ChildItem -Path $cat.FullName -Filter "*.md"

            foreach ($file in $files) {
                $tags = @("faq", $cat.Name)

                Index-Document -Path $file.FullName -Category "faq" -Tags $tags
            }

            Write-Host "Indexed FAQs from '$($cat.Name)': $($files.Count) files" -ForegroundColor Cyan
        }
    }
}

# 生成索引统计
function Get-IndexStats {
    $knowledge = Get-KnowledgeBase

    $stats = [PSCustomObject]@{
        TotalCategories = $knowledge.categories.PSObject.Properties.Count
        TotalDocuments  = ($knowledge.categories.PSObject.Properties |
            Measure-Object -Property Count -Sum).Sum
        LastUpdated     = $knowledge.lastUpdated
        SearchConfig    = $knowledge.searchConfig
    }

    return $stats
}

# 批量索引
function New-BatchIndex {
    param(
        [hashtable[]]$Documents,
        [string]$Category
    )

    foreach ($doc in $Documents) {
        Index-Document -Path $doc.path -Category $Category -Tags $doc.tags
    }

    Write-Host "Batch indexed $($Documents.Count) documents" -ForegroundColor Green
}

# 清理无效引用
function Clean-InvalidReferences {
    $knowledge = Get-KnowledgeBase

    foreach ($category in $knowledge.categories.PSObject.Properties) {
        $validFiles = @()

        foreach ($doc in $category.Value.files) {
            if (Test-Path $doc.path) {
                $validFiles += $doc
            }
        }

        $category.Value.files = $validFiles
        $category.Value.count = $validFiles.Count
    }

    Save-KnowledgeBase -Data $knowledge

    Write-Host "Cleaned invalid references" -ForegroundColor Green
}

# 导出索引报告
function Export-IndexReport {
    param(
        [string]$OutputPath = "knowledge-index-report.md"
    )

    $knowledge = Get-KnowledgeBase
    $stats = Get-IndexStats

    $report = @"
# Knowledge Base Index Report

## Summary

- **Total Categories**: $($stats.TotalCategories)
- **Total Documents**: $($stats.TotalDocuments)
- **Last Updated**: $($stats.LastUpdated)
- **Search Cache**: $($stats.SearchConfig.enableCaching)

## Categories

@(foreach ($cat in $knowledge.categories.PSObject.Properties) {
    - ### $($cat.Name)
    **Documents**: $($cat.Value.count)
    **Files**:
    @(foreach ($file in $cat.Value.files) {
        - \`$($file.path)\` ($([math]::Round($file.size / 1024, 2)) KB)
    })
})

## Statistics

**Search Configuration**
- Default Limit: $($stats.SearchConfig.defaultLimit)
- Max Limit: $($stats.SearchConfig.maxLimit)
- Cache TTL: $($stats.SearchConfig.cacheTTL) seconds
- Vector Search: $($stats.SearchConfig.enableVectorSearch)

---

Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@

    $report | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "Index report exported to: $OutputPath" -ForegroundColor Green
}

# 命令行接口
function Show-Usage {
    Write-Host @"
Usage:
  Index-Document -Path "docs/api-guide.md" -Category "documentation"
  Index-Document -Path "..." -Category "..." -Tags @("api", "javascript")

  Index-Directory -Path "docs" -Category "documentation" -Tags @("docs")

  Rebuild-Index -Categories "documentation", "code-examples"

  Index-CodeExamples -Languages @("javascript", "python")
  Index-FAQs

  Get-IndexStats
  Clean-InvalidReferences
  Export-IndexReport

Examples:
  Index-Document -Path "docs/api-guide.md" -Category "documentation" -Tags @("api")
  Index-Directory -Path "docs" -Category "documentation"
  Rebuild-Index
  Export-IndexReport
"@
}

# 默认执行
if ($args.Count -gt 0) {
    $cmd = $args[0]

    switch ($cmd) {
        "rebuild" {
            $categories = if ($args -contains "-Categories") {
                @($args[$args.IndexOf("-Categories") + 1 .. ($args.Count - 1)])
            } else { @() }

            Rebuild-Index -Categories $categories
        }
        "stats" {
            $stats = Get-IndexStats

            Write-Host "`n=== Index Statistics ===" -ForegroundColor Cyan
            Write-Host "Total Categories: $($stats.TotalCategories)" -ForegroundColor Yellow
            Write-Host "Total Documents: $($stats.TotalDocuments)" -ForegroundColor White
            Write-Host "Last Updated: $($stats.LastUpdated)" -ForegroundColor Gray
        }
        "clean" {
            Clean-InvalidReferences
        }
        "export" {
            $outputPath = if ($args -contains "-OutputPath") { $args[$args.IndexOf("-OutputPath") + 1] } else { "knowledge-index-report.md" }
            Export-IndexReport -OutputPath $outputPath
        }
        default {
            Show-Usage
        }
    }
}

<#
.EXAMPLE
Index-Document -Path "docs/api-guide.md" -Category "documentation"
Index-Directory -Path "docs" -Category "documentation"
Rebuild-Index
Get-IndexStats
Export-IndexReport
#>
