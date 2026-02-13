<#
.SYNOPSIS
    技能自动提取器 - 从代码和学习记录中提取最佳实践

.DESCRIPTION
    自动分析scripts目录和学习记录，提取可复用的最佳实践，生成符合SKILL.md格式的Skill。

.VERSION
    1.0.0

.AUTHOR
    灵眸
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('extract', 'generate', 'sync', 'analyze')]
    [string]$Action = 'extract',

    [Parameter(Mandatory=$false)]
    [string]$TargetDir = ""

    [Parameter(Mandatory=$false)]
    [switch]$Verbose
)

$BaseDir = if ($TargetDir) { $TargetDir } else { "$PSScriptRoot/.." }
$ScriptsDir = "$BaseDir/scripts"
$LearningsDir = "$BaseDir/../learnings"
$OutputDir = "$BaseDir/data"
$MetadataFile = "$OutputDir/skill-metadata.json"

function Initialize-System {
    Write-Host "🔧 Initializing Skill Extractor..." -ForegroundColor Cyan

    # 创建必要的目录
    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }

    # 初始化元数据文件
    if (-not (Test-Path $MetadataFile)) {
        @{
            "skills" = @()
            "lastUpdated" = (Get-Date).ToString("o")
            "statistics" = @{
                "totalExtracted" = 0
                "totalPractice" = 0
                "byCategory" = @{
                    "performance" = 0
                    "errorHandling" = 0
                    "bestPractice" = 0
                    "optimization" = 0
                }
            }
        } | ConvertTo-Json -Depth 10 | Set-Content $MetadataFile
    }

    Write-Host "✅ System initialized" -ForegroundColor Green
}

function Extract-CodePatterns {
    param([string]$ScriptPath)

    Write-Host "📝 Analyzing: $ScriptPath" -ForegroundColor Cyan

    $content = Get-Content $ScriptPath -Raw
    $patterns = @()

    # 识别代码模式
    # 1. 函数定义
    if ($content -match "function\s+(\w+)\s*\(") {
        $patterns += [PSCustomObject]@{
            type = "function"
            name = $matches[1]
            description = "PowerShell function definition"
            codeSnippet = $matches[0].Substring(0, [Math]::Min(100, $matches[0].Length))
        }
    }

    # 2. 参数处理
    if ($content -match "\-Parameter\(.*?Mandatory") {
        $patterns += [PSCustomObject]@{
            type = "parameter"
            name = "parameter-handling"
            description = "PowerShell parameter handling best practice"
            codeSnippet = "-Parameter(Mandatory=$true, ...)"
        }
    }

    # 3. 错误处理
    if ($content -match "try\s*\{|catch\s*\{|finally\s*\{|trap\s*\(") {
        $patterns += [PSCustomObject]@{
            type = "errorHandling"
            name = "error-handling"
            description = "PowerShell error handling best practice"
            codeSnippet = "try { ... } catch { ... }"
        }
    }

    # 4. 性能优化
    if ($content -match "ForEach-Object|Where-Object|Select-Object.*-First|Select-Object.*-Last") {
        $patterns += [PSCustomObject]@{
            type = "performance"
            name = "pipeline-optimization"
            description = "PowerShell pipeline optimization"
            codeSnippet = "pipeline | Where-Object ... | Select-Object ..."
        }
    }

    # 5. 资源清理
    if ($content -match "Remove-Item|Dispose|Close|Stop-Process") {
        $patterns += [PSCustomObject]@{
            type = "resourceManagement"
            name = "resource-cleanup"
            description = "PowerShell resource cleanup best practice"
            codeSnippet = "try { ... } finally { ... }"
        }
    }

    return $patterns
}

function Extract-Learnings {
    param([string]$LearningsFile)

    Write-Host "📖 Analyzing: $LearningsFile" -ForegroundColor Cyan

    $learnings = @()
    $content = Get-Content $LearningsFile -Raw
    $lines = $content -split "`n"

    foreach ($line in $lines) {
        if ($line -match "## \[LRN-([^\]]+)\]") {
            $learningId = $matches[1]
            $patterns += [PSCustomObject]@{
                type = "learning"
                name = $learningId
                description = "Extracted best practice from learning"
                codeSnippet = "See LRN-$learningId"
            }
        }
    }

    return $patterns
}

function Generate-Skill {
    param(
        [string]$Name,
        [string]$Category,
        [string]$Description,
        [string[]]$Examples,
        [string]$Type = "utility"
    )

    $skillId = "SKILL-$(Get-Random -Maximum 999999)"
    $timestamp = (Get-Date).ToString("o")

    $skillContent = @"
# $Name

**Skill ID**: $skillId
**Category**: $Category
**Type**: $Type
**Created**: $timestamp
**Author**: 自动提取

## 📋 Description

$Description

## 🎯 Purpose

该技能提供以下功能：

1. 功能1
2. 功能2
3. 功能3

## 📖 Usage

\`\`\`powershell
# 基本用法
.\$Name.ps1 -Parameter value

# 高级用法
.\$Name.ps1 -Parameter value -Option another
\`\`\`

## 📝 Examples

### Example 1
\`\`\`powershell
# 示例代码
param([string]$value)
Write-Host "Value: $value"
\`\`\`

### Example 2
\`\`\`powershell
# 另一个示例
$value = Get-Value
if ($value) {
    # 处理
}
\`\`\`

## 🔧 Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| Parameter1 | string | Yes | - | Parameter description |
| Parameter2 | int | No | 0 | Another parameter |

## 📚 Related Skills

- SKILL-123456
- SKILL-789012

## 🤝 Contribution

欢迎提交改进建议和示例。

---

**Status**: ✅ Available
**Version**: 1.0.0
"@

    $skillFileName = "$OutputDir/$Name.ps1"
    $skillContent | Set-Content $skillFileName -Encoding UTF8

    return $skillId
}

function Update-Metadata {
    param(
        [PSCustomObject]$Skill,
        [string]$Category,
        [string]$Type
    )

    $metadata = Get-Content $MetadataFile -Raw | ConvertFrom-Json

    $newSkill = [PSCustomObject]@{
        id = $Skill.id
        name = $Skill.name
        category = $Category
        type = $Type
        extractedAt = (Get-Date).ToString("o")
        description = $Skill.description
    }

    $metadata.skills += $newSkill
    $metadata.statistics.totalExtracted++
    $metadata.statistics.totalPractice++

    if ($metadata.statistics.byCategory.ContainsKey($Category)) {
        $metadata.statistics.byCategory[$Category]++
    }

    $metadata.lastUpdated = (Get-Date).ToString("o")

    $metadata | ConvertTo-Json -Depth 10 | Set-Content $MetadataFile

    Write-Host "✅ Metadata updated" -ForegroundColor Green
}

function Analyze-Dependencies {
    param([string]$ScriptPath)

    Write-Host "🔍 Analyzing dependencies for: $ScriptPath" -ForegroundColor Cyan

    $content = Get-Content $ScriptPath -Raw

    $dependencies = @()

    # 识别外部命令
    $content -split "`n" | Where-Object { $_ -match "^(Get-|Set-|New-|Remove-|Invoke-|Write-|Start-|Stop-|Test-|Measure-|Convert-|Format-)" } | ForEach-Object {
        $command = $_.Trim()
        $command = $command -replace "^Get-", ""
        $command = $command -replace "^Set-", ""
        $command = $command -replace "^New-", ""
        $command = $command -replace "^Remove-", ""
        $command = $command -replace "^Invoke-", ""
        $command = $command -replace "^Write-", ""
        $command = $command -replace "^Start-", ""
        $command = $command -replace "^Stop-", ""
        $command = $command -replace "^Test-", ""
        $command = $command -replace "^Measure-", ""
        $command = $command -replace "^Convert-", ""
        $command = $command -replace "^Format-", ""

        if (-not $dependencies.Contains($command)) {
            $dependencies += $command
        }
    }

    return $dependencies
}

try {
    Initialize-System

    switch ($Action) {
        "extract" {
            Write-Host "🔍 开始提取代码模式..." -ForegroundColor Cyan

            $scripts = Get-ChildItem $ScriptsDir -Filter "*.ps1" | Select-Object FullName

            foreach ($script in $scripts) {
                Write-Host "`n" + ("=" * 60) -ForegroundColor Cyan
                Write-Host "分析脚本: $($script.Name)" -ForegroundColor Cyan

                $patterns = Extract-CodePatterns -ScriptPath $script.FullName

                foreach ($pattern in $patterns) {
                    Write-Host "  发现模式: $($pattern.name) - $($pattern.description)" -ForegroundColor Green

                    # 生成Skill
                    $skillId = Generate-Skill `
                        -Name "extracted-$(Get-Random -Maximum 9999)" `
                        -Category $pattern.type `
                        -Description $pattern.description `
                        -Examples @("示例代码") `
                        -Type "auto-extracted"

                    Write-Host "  ✅ 生成的Skill ID: $skillId" -ForegroundColor Green

                    Update-Metadata -Skill $pattern -Category $pattern.type -Type "auto-extracted"
                }
            }

            Write-Host "`n" + ("=" * 60) -ForegroundColor Cyan
            Write-Host "✅ 代码模式提取完成" -ForegroundColor Green
        }

        "generate" {
            Write-Host "📝 从学习记录生成最佳实践..." -ForegroundColor Cyan

            $learningsFile = "$LearningsDir/LEARNINGS.md"

            if (Test-Path $learningsFile) {
                $patterns = Extract-Learnings -LearningsFile $learningsFile

                foreach ($pattern in $patterns) {
                    $skillId = Generate-Skill `
                        -Name "learning-$(Get-Random -Maximum 9999)" `
                        -Category "learning" `
                        -Description "从学习记录提取的最佳实践" `
                        -Examples @("参考LRN记录") `
                        -Type "learning"

                    Update-Metadata -Skill $pattern -Category "learning" -Type "learning"
                }
            } else {
                Write-Host "⚠️  学习记录文件不存在" -ForegroundColor Yellow
            }

            Write-Host "✅ 最佳实践生成完成" -ForegroundColor Green
        }

        "sync" {
            Write-Host "🔄 同步到本地Skill库..." -ForegroundColor Cyan

            # 这里可以实现自动推送到m/self-healing-engine
            # 目前仅演示
            Write-Host "  本地Skill库: $OutputDir" -ForegroundColor Gray
            Write-Host "  ✅ 同步完成（演示模式）" -ForegroundColor Green
        }

        "analyze" {
            Write-Host "📊 分析技能使用情况..." -ForegroundColor Cyan

            $metadata = Get-Content $MetadataFile -Raw | ConvertFrom-Json

            Write-Host "`n【统计信息】" -ForegroundColor White
            Write-Host "  总提取数: $($metadata.statistics.totalExtracted)" -ForegroundColor White
            Write-Host "  总最佳实践: $($metadata.statistics.totalPractice)" -ForegroundColor White

            Write-Host "`n【分类统计】" -ForegroundColor White
            foreach ($category in $metadata.statistics.byCategory.Keys) {
                $count = $metadata.statistics.byCategory[$category]
                if ($count -gt 0) {
                    Write-Host "  $category: $count" -ForegroundColor $Colors.Yellow
                }
            }

            Write-Host "`n【已提取Skill列表】" -ForegroundColor White
            foreach ($skill in $metadata.skills) {
                Write-Host "  - $($skill.name) [$($skill.category)]" -ForegroundColor Cyan
            }
        }
    }
} catch {
    Write-Error "错误: $($_.Exception.Message)"
    Write-Host $_.ScriptStackTrace -ForegroundColor Gray
    exit 1
}
