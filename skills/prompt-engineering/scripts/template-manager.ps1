<#
.SYNOPSIS
Prompt-Engineering Template Manager

.DESCRIPTION
管理提示词模板库，包括模板的加载、使用、更新等功能

.NOTES
Author: OpenClaw Assistant
Date: 2026-02-13
Version: 1.0.0
#>

# 模块路径
$modulePath = $PSScriptRoot

# 加载质量规则
function Get-QualityRules {
    param(
        [string]$Category = "all"
    )

    $rulesPath = Join-Path $modulePath "data/quality-rules.json"

    if (-not (Test-Path $rulesPath)) {
        throw "Quality rules file not found: $rulesPath"
    }

    $rules = Get-Content $rulesPath -Raw | ConvertFrom-Json

    if ($Category -eq "all") {
        return $rules.rules
    } else {
        return $rules.rules | Where-Object { $_.name -eq $Category }
    }
}

# 获取所有模板分类
function Get-TemplateCategories {
    $templatePaths = Get-ChildItem -Path (Join-Path $modulePath "templates") -Filter "*.json"

    $categories = @()
    foreach ($path in $templatePaths) {
        $content = Get-Content $path.FullName -Raw | ConvertFrom-Json
        $categories += [PSCustomObject]@{
            Category = $content.category
            Path     = $path.FullName
            Count    = $content.templates.Count
        }
    }

    return $categories | Sort-Object -Property Category
}

# 获取分类下的所有模板
function Get-TemplateByCategory {
    param(
        [string]$Category
    )

    $templatePath = Join-Path $modulePath "templates/${Category}.json"

    if (-not (Test-Path $templatePath)) {
        throw "Template file not found: $templatePath"
    }

    $content = Get-Content $templatePath -Raw | ConvertFrom-Json
    return $content.templates
}

# 获取特定模板
function Get-Template {
    param(
        [string]$Category,
        [string]$Name
    )

    $templates = Get-TemplateByCategory -Category $Category

    $template = $templates | Where-Object { $_.name -eq $Name }

    if (-not $template) {
        throw "Template not found: $Name in category $Category"
    }

    return $template
}

# 列出所有可用模板
function Show-TemplateList {
    param(
        [string]$Category = "all"
    )

    $categories = Get-TemplateCategories

    if ($Category -ne "all") {
        $categories = $categories | Where-Object { $_.Category -eq $Category }
    }

    Write-Host "`n=== Prompt Templates ===" -ForegroundColor Cyan

    foreach ($cat in $categories) {
        Write-Host "`n[$($cat.Category)]" -ForegroundColor Yellow
        Write-Host "Total: $($cat.Count) templates" -ForegroundColor Gray

        $templates = Get-TemplateByCategory -Category $cat.Category
        foreach ($tpl in $templates) {
            Write-Host "  - $($tpl.name): $($tpl.title)" -ForegroundColor White
        }
    }

    Write-Host ""
}

# 使用模板创建提示词
function New-TemplatePrompt {
    param(
        [string]$Category,
        [string]$Name,
        [hashtable]$Parameters = @{}
    )

    $template = Get-Template -Category $Category -Name $Name

    $prompt = $template.template

    # 替换参数占位符
    foreach ($key in $Parameters.Keys) {
        $placeholder = "${$key}"
        $value = $Parameters[$key]
        $prompt = $prompt.Replace($placeholder, $value)
    }

    return [PSCustomObject]@{
        Template = $template
        Prompt   = $prompt
        Context  = $Parameters
    }
}

# 保存自定义模板
function New-PromptTemplate {
    param(
        [string]$Category,
        [string]$Name,
        [string]$Title,
        [string]$Template,
        [string[]]$Examples = @()
    )

    $templatePath = Join-Path $modulePath "templates/${Category}.json"

    if (-not (Test-Path $templatePath)) {
        throw "Category template file not found: $templatePath"
    }

    $content = Get-Content $templatePath -Raw | ConvertFrom-Json

    $newTemplate = [PSCustomObject]@{
        name        = $Name
        title       = $Title
        description = "自定义模板"
        template    = $Template
        parameters  = @{ }
        examples    = $Examples
    }

    $content.templates += $newTemplate

    $content | ConvertTo-Json -Depth 10 | Set-Content $templatePath

    Write-Host "Template saved: $Category/$Name" -ForegroundColor Green
}

# 导出模板为Markdown
function Export-TemplateToMarkdown {
    param(
        [string]$Category,
        [string]$Name,
        [string]$OutputPath
    )

    $template = Get-Template -Category $Category -Name $Name

    $markdown = @"
# $($template.title)

## Description
$($template.description)

## Template
```text
$($template.template)
```

## Parameters
@(foreach ($param in $template.parameters.GetEnumerator()) {
    - " `$($param.Key)`: `$($param.Value)"
})

## Examples
@(foreach ($ex in $template.examples) {
    - ### $($ex.name)
    - $"
    ```
    $($ex.template)
    ```
    $"
    @(foreach ($key in $ex.parameters.Keys) {
        - "• `$($key)`: `$($ex.parameters[$key])"
    })
})

"@

    if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
        $markdown | Out-File -FilePath $OutputPath -Encoding UTF8
    }

    return $markdown
}

# 默认导出到标准输出
Export-TemplateToMarkdown @args

<#
.EXAMPLE
# 列出所有模板
Get-TemplateList

# 列出代码模板
Get-TemplateList -Category code

# 使用模板
$params = @{
    language = "JavaScript"
    task = "处理HTTP请求"
}
New-TemplatePrompt -Category code -Name function-generation -Parameters $params

# 导出模板为Markdown
Export-TemplateToMarkdown -Category code -Name function-generation -OutputPath docs/function-template.md
#>
