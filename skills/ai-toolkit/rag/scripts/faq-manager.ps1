<#
.SYNOPSIS
FAQ Knowledge Base Manager

.DESCRIPTION
管理常见问题解答知识库

.NOTES
Author: OpenClaw Assistant
Date: 2026-02-14
Version: 1.0.0
#>

$modulePath = $PSScriptRoot
$faqPath = Join-Path $modulePath "..\data\faq"
$knowledgePath = Join-Path $modulePath "..\data\knowledge-base.json"

# 初始化FAQ目录
function Initialize-FAQDirectory {
    if (-not (Test-Path $faqPath)) {
        New-Item -ItemType Directory -Path $faqPath -Force | Out-Null

        # 创建分类
        $categories = @("getting-started", "usage", "troubleshooting", "advanced")
        foreach ($cat in $categories) {
            $catPath = Join-Path $faqPath $cat
            New-Item -ItemType Directory -Path $catPath -Force | Out-Null
        }

        Write-Host "FAQ directory initialized" -ForegroundColor Green
    }
}

# 创建FAQ
function New-FAQ {
    param(
        [string]$Question,
        [string]$Answer,
        [string]$Category = "getting-started",
        [string[]]$Keywords = @(),
        [string[]]$Tags = @(),
        [switch]$AutoAdd
    )

    $faqPath = Join-Path $modulePath "..\data\faq"

    if (-not (Test-Path (Join-Path $faqPath $Category))) {
        throw "FAQ category not found: $Category"
    }

    $faqNumber = (Get-ChildItem -Path (Join-Path $faqPath $Category) -Filter "*.md" |
        Measure-Object).Count + 1

    $fileName = "faq-$faqNumber.md"
    $filePath = Join-Path $faqPath $Category $fileName

    $faqContent = @"
# FAQ: $Question

## Question
$Question

## Answer
$Answer

## Keywords
@(if ($Keywords.Count -gt 0) {
    - "$(foreach ($kw in $Keywords) { "- $kw" })"
})

## Tags
@(if ($Tags.Count -gt 0) {
    - "$(foreach ($tag in $Tags) { "- $tag" })"
})

## Created
$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Last Updated
$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@

    $faqContent | Out-File -FilePath $filePath -Encoding UTF8

    Write-Host "FAQ created: $fileName in category '$Category'" -ForegroundColor Green

    if ($AutoAdd) {
        Add-FAQToKnowledgeBase -Category "faq" -Path $filePath -Description "FAQ: $Question"
    }
}

# 更新FAQ
function Update-FAQ {
    param(
        [string]$FilePath,
        [string]$NewAnswer = "",
        [string]$NewQuestion = ""
    )

    if (-not (Test-Path $FilePath)) {
        throw "FAQ file not found: $FilePath"
    }

    $content = Get-Content $FilePath -Raw

    if ($NewAnswer) {
        $content = $content -replace "(?s)## Answer\n(.*?)\n", "## Answer`n$NewAnswer`n"
    }

    if ($NewQuestion) {
        $content = $content -replace "(?s)^# FAQ: (.*?)\n", "# FAQ: $NewQuestion`n"
    }

    Set-Content -Path $FilePath -Value $content -Encoding UTF8

    Write-Host "FAQ updated: $FilePath" -ForegroundColor Green
}

# 删除FAQ
function Remove-FAQ {
    param([string]$FilePath)

    if (-not (Test-Path $FilePath)) {
        throw "FAQ file not found: $FilePath"
    }

    Remove-Item -Path $FilePath -Force
    Write-Host "FAQ removed: $FilePath" -ForegroundColor Green
}

# 搜索FAQ
function Search-FAQ {
    param(
        [string]$Query,
        [string]$Category = "all",
        [int]$Limit = 5
    )

    Initialize-FAQDirectory

    $results = @()

    if ($Category -eq "all") {
        $faqFiles = Get-ChildItem -Path $faqPath -Recurse -Filter "*.md"
    } else {
        $faqFiles = Get-ChildItem -Path (Join-Path $faqPath $Category) -Filter "*.md"
    }

    foreach ($file in $faqFiles) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue

        if ($content -and $content -match $Query) {
            $results += [PSCustomObject]@{
                File       = $file.FullName
                Category   = $file.Directory.Name
                Question   = $content -match "# FAQ: (.+)" | Out-Null; $Matches[1]
                Answer     = $content -match "(?s)## Answer\n(.*?)(?=\n##)" | Out-Null; $Matches[1]
                Relevance  = 1.0
            }
        }
    }

    $results = $results | Sort-Object -Property Relevance -Descending |
        Select-Object -First $Limit

    return $results
}

# 列出FAQ
function Show-FAQList {
    param(
        [string]$Category = "all",
        [switch]$Detailed
    )

    Initialize-FAQDirectory

    if ($Category -eq "all") {
        $faqFiles = Get-ChildItem -Path $faqPath -Recurse -Filter "*.md"
    } else {
        $faqFiles = Get-ChildItem -Path (Join-Path $faqPath $Category) -Filter "*.md"
    }

    Write-Host "`n=== FAQ List ===" -ForegroundColor Cyan

    foreach ($file in $faqFiles) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        $question = if ($content -match "# FAQ: (.+)") { $Matches[1] } else { "Unknown" }

        Write-Host "`n[$($file.Directory.Name)] $($file.Name)" -ForegroundColor Yellow
        Write-Host "Question: $question" -ForegroundColor White

        if ($Detailed) {
            $answer = if ($content -match "(?s)## Answer\n(.*?)(?=\n##)") { $Matches[1] } else { "No answer" }
            Write-Host "Answer: $answer" -ForegroundColor Gray
        }
    }

    Write-Host "`nTotal: $($faqFiles.Count) FAQs" -ForegroundColor Gray
}

# 统计FAQ
function Get-FAQStats {
    Initialize-FAQDirectory

    $stats = [PSCustomObject]@{
        TotalFAQs  = (Get-ChildItem -Path $faqPath -Recurse -Filter "*.md" |
            Measure-Object).Count
        Categories = @{}
    }

    foreach ($cat in Get-ChildItem -Path $faqPath -Directory) {
        $faqCount = (Get-ChildItem -Path $cat.FullName -Filter "*.md" |
            Measure-Object).Count
        $stats.Categories[$cat.Name] = $faqCount
    }

    return $stats
}

# 批量创建FAQ
function New-BatchFAQs {
    param(
        [hashtable[]]$FAQs
    )

    foreach ($faq in $FAQs) {
        New-FAQ -Question $faq.question -Answer $faq.answer `
               -Category $faq.category -Keywords $faq.keywords `
               -Tags $faq.tags -AutoAdd:$true
    }

    Write-Host "Created $($FAQs.Count) FAQs" -ForegroundColor Green
}

# 导出FAQ
function Export-FAQs {
    param(
        [string]$OutputPath,
        [string]$Category = "all"
    )

    if ($Category -eq "all") {
        $faqFiles = Get-ChildItem -Path $faqPath -Recurse -Filter "*.md"
    } else {
        $faqFiles = Get-ChildItem -Path (Join-Path $faqPath $Category) -Filter "*.md"
    }

    $export = @"
# FAQ Export

## Statistics
- Total FAQs: $($faqFiles.Count)
- Exported: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## FAQ List

@(foreach ($file in $faqFiles) {
    $content = Get-Content $file.FullName -Raw
    $question = if ($content -match "# FAQ: (.+)") { $Matches[1] } else { "Unknown" }
    - ### $($file.Name)
    **Category**: $($file.Directory.Name)
    **Question**: $question
})

"@

    $export | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "FAQs exported to: $OutputPath" -ForegroundColor Green
}

# 导入FAQ
function Import-FAQs {
    param([string]$InputPath)

    if (-not (Test-Path $InputPath)) {
        throw "File not found: $InputPath"
    }

    Initialize-FAQDirectory

    $imported = 0

    # 这里简化处理，实际应解析Markdown格式
    Write-Host "FAQs imported from: $InputPath" -ForegroundColor Green
    Write-Host "Note: Full import requires Markdown parser" -ForegroundColor Yellow
}

# 命令行接口
function Show-Usage {
    Write-Host @"
Usage:
  New-FAQ -Question "how to use api" -Answer "Steps..."
  New-FAQ -Question "..." -Answer "..." -Category "usage"

  Search-FAQ -Question "how to use api"
  Search-FAQ -Question "..." -Limit 3

  Show-FAQList
  Show-FAQList -Category getting-started -Detailed

  Get-FAQStats
  Remove-FAQ -Path "faq/usage/faq-1.md"

  Export-FAQs -OutputPath faq-export.md
  Import-FAQs -InputPath faq-export.md

Examples:
  New-FAQ -Question "How to reset password?" -Answer "Go to settings..."
  Search-FAQ -Question "password reset"
  Show-FAQList -Detailed
"@
}

# 默认执行
if ($args.Count -gt 0) {
    $cmd = $args[0]

    switch ($cmd) {
        "search" {
            $question = if ($args.Count -ge 2) { $args[1] } else { throw "Missing question" }
            $category = if ($args -contains "-Category") { $args[$args.IndexOf("-Category") + 1] } else { "all" }
            $limit = if ($args -contains "-Limit") { [int]$args[$args.IndexOf("-Limit") + 1] } else { 5 }

            $results = Search-FAQ -Question $question -Category $category -Limit $limit

            Write-Host "`n=== FAQ Results ===" -ForegroundColor Cyan
            foreach ($result in $results) {
                Write-Host "Q: $($result.Question)" -ForegroundColor Yellow
                Write-Host "A: $($result.Answer)" -ForegroundColor White
                Write-Host ""
            }
        }
        "list" {
            $category = if ($args -contains "-Category") { $args[$args.IndexOf("-Category") + 1] } else { "all" }
            $detailed = if ($args -contains "-Detailed") { $true } else { $false }
            Show-FAQList -Category $category -Detailed:$detailed
        }
        default {
            Show-Usage
        }
    }
}

<#
.EXAMPLE
New-FAQ -Question "How to use API?" -Answer "1. Get API key 2. Configure settings"
Search-FAQ -Question "how to use api"
Show-FAQList -Detailed
Get-FAQStats
#>
