# 技能自动提取器

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("extract", "extract-all", "check", "import")]
    [string]$Action,

    [string]$Category = "general",
    [string]$SourceFile = ".logs/learnings/LEARNINGS.md",
    [int]$MaxSkills = 5,
    [switch]$DryRun,
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"

# 配置
$config = Get-Content ".config/skill-extractor.json" -ErrorAction SilentlyContinue | ConvertFrom-Json
if (-not $config) {
    $config = @{
        extractionPath = ".logs/learnings"
        outputPath = "skills/extracted"
        minRelatedEntries = 2
        maxSkillsPerCategory = 10
        qualityCheck = $true
        autoDeploy = $true
        categories = @("error-handling", "performance", "security", "deployment", "testing")
    }
}

# 目录
$extractionPath = $config.extractionPath
$outputPath = $config.outputPath

if (-not (Test-Path $extractionPath)) {
    Write-Host "❌ 提取路径不存在: $extractionPath" -ForegroundColor Red
    return
}

# 创建输出目录
if (-not (Test-Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
}

# 颜色函数
function Set-Color {
    param([string]$Text, [string]$Color)

    if ($Verbose) {
        Write-Host $Text -ForegroundColor $Color
    }
}

# 提取单个学习条目为skill
function Extract-LearningToSkill {
    param(
        [hashtable]$LearningEntry,
        [string]$SkillName,
        [string]$Category
    )

    Write-Host "🔧 提取学习条目为Skill: $SkillName" -ForegroundColor Cyan
    Write-Color "   分类: $Category" -ForegroundColor Yellow
    Write-Color "   摘要: $($LearningEntry.summary)" -ForegroundColor White

    # 创建skill目录
    $skillDir = Join-Path $outputPath $SkillName
    if (-not (Test-Path $skillDir)) {
        New-Item -ItemType Directory -Path $skillDir -Force | Out-Null
    }

    # 创建SKILL.md
    $skillMd = @"
# $SkillName

## 概述
$(if ($LearningEntry.description) { $LearningEntry.description } else { $LearningEntry.summary })

## 来源
- ID: $($LearningEntry.id)
- 分类: $($LearningEntry.category)
- 创建时间: $($LearningEntry.date)
- 优先级: $($LearningEntry.priority)

## 问题描述
$($LearningEntry.summary)

## 解决方案

### 方法1: 直接修复
$(if ($LearningEntry.fix1) { $LearningEntry.fix1 } else { "参见原始学习记录" })

### 方法2: 替代方案
$(if ($LearningEntry.fix2) { $LearningEntry.fix2 } else { "未提供" })

## 实现示例

### PowerShell示例
\`\`\`powershell
# 伪代码示例
function Fix-{$SkillName} {
    # 提取解决方案代码
    param($Parameter)

    # 实现修复逻辑
    if ($Parameter) {
        # 方法1实现
    } else {
        # 方法2实现
    }
}
\`\`\`

### 使用说明
1. 调用上述函数
2. 传入必要的参数
3. 处理返回结果
4. 验证修复效果

## 最佳实践

### 适用场景
- $($LearningEntry.scenarios -join ", ")

### 不适用场景
- $($LearningEntry.nonScenarios -join ", ")

### 注意事项
- $($LearningEntry.notes -join ", ")

## 相关学习
- $($LearningEntry.related -join ", ")

## 版本历史
- v1.0.0 ($($LearningEntry.date)) - 初始版本

---

**创建时间**: $($LearningEntry.date)
**作者**: 灵眸
**来源**: Moltbook学习记录提取
"@

    Set-Content (Join-Path $skillDir "SKILL.md") $skillMd -Encoding UTF8

    # 创建skill.json
    $skillJson = @{
        name = $SkillName
        version = "1.0.0"
        description = $LearningEntry.summary
        author = "灵眸"
        category = $Category
        tags = @($LearningEntry.tags)
        created = (Get-Date -Format "yyyy-MM-dd")
        sourceId = $LearningEntry.id
        priority = $LearningEntry.priority
        dependencies = @()
        author = "灵眸"
    }

    $skillJson | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $skillDir "skill.json")

    # 创建README
    $readme = @"
# $SkillName

自动化技能提取自Moltbook学习记录。

## 快速开始
\`\`\`powershell
.\\$SkillName\\SKILL.md
.\$SkillName.ps1 -Action use -Parameter value
\`\`\`

## 详细文档
- SKILL.md - 完整文档
- skill.json - 元数据
- README.md - 本文件

## 更新日志
- $((Get-Date -Format "yyyy-MM-dd")) - v1.0.0 初始版本
"@

    Set-Content (Join-Path $skillDir "README.md") $readme -Encoding UTF8

    # 创建示例目录和文件
    $examplesDir = Join-Path $skillDir "examples"
    New-Item -ItemType Directory -Path $examplesDir -Force | Out-Null

    # 创建示例文件
    $example1 = @"
# 示例1: 基本用法

\`\`\`powershell
.\extractor.ps1 -Action extract -Category "$Category" -SkillName "$SkillName"
\`\`\`

## 输出
\`\`\`
✅ Skill创建成功: $SkillName
📁 位置: $skillDir
📄 SKILL.md
📄 skill.json
📄 README.md
\`\`\`
"@

    Set-Content (Join-Path $examplesDir "example-1-basic.ps1") $example1 -Encoding UTF8

    # 创建示例文件2
    $example2 = @"
# 示例2: 高级用法

\`\`\`powershell
# 提取多个相关学习
.\extractor.ps1 -Action extract-all -MaxSkills 10

# 验证技能质量
.\extractor.ps1 -Action check -SkillName "$SkillName"
\`\`\`

## 验证结果
- ✅ SKILL.md格式正确
- ✅ skill.json元数据完整
- ✅ 包含完整文档
- ✅ 提供使用示例
"@

    Set-Content (Join-Path $examplesDir "example-2-advanced.ps1") $example2 -Encoding UTF8

    Write-Host "   ✅ Skill创建成功!" -ForegroundColor Green
    Write-Host "   📁 位置: $skillDir" -ForegroundColor White
    Write-Host "   📄 SKILL.md" -ForegroundColor White
    Write-Host "   📄 skill.json" -ForegroundColor White
    Write-Host "   📄 README.md" -ForegroundColor White
    Write-Host "   📂 examples/" -ForegroundColor White

    return @{
        skillName = $SkillName
        path = $skillDir
        status = "created"
    }
}

# 识别重复学习模式
function Find-RepeatingPatterns {
    $learnings = Get-Content (Join-Path $extractionPath "LEARNINGS.md") -Raw -ErrorAction SilentlyContinue
    $errors = Get-Content (Join-Path $extractionPath "ERRORS.md") -Raw -ErrorAction SilentlyContinue

    $patterns = @{}

    # 查找学习中的重复模式
    if ($learnings) {
        $entries = [regex]::Matches($learnings, "^## \[([^\]]+)\].*$")

        foreach ($match in $entries) {
            $id = $match.Groups[1].Value
            $line = $match.Value

            # 检查summary
            if ($line -match "### Summary\s*\n(.*?)\n") {
                $summary = $matches[1].Trim()

                # 检查是否已经有类似条目
                if ($summary -in $patterns.Keys) {
                    $patterns[$summary]++
                }
                else {
                    $patterns[$summary] = 1
                }
            }
        }
    }

    # 返回可能的重复项
    return $patterns | Where-Object { $_.Value -ge 2 }
}

# 质量检查
function Invoke-QualityCheck {
    param([string]$SkillName)

    $skillDir = Join-Path $outputPath $SkillName
    $checks = @()

    # 检查1: SKILL.md存在
    $skillMdPath = Join-Path $skillDir "SKILL.md"
    $checks += [PSCustomObject]@{
        Name = "SKILL.md存在"
        Status = if (Test-Path $skillMdPath) { "✅" } else { "❌" }
        Message = if (Test-Path $skillMdPath) { "文件存在" } else { "文件缺失" }
    }

    # 检查2: skill.json存在
    $skillJsonPath = Join-Path $skillDir "skill.json"
    $checks += [PSCustomObject]@{
        Name = "skill.json存在"
        Status = if (Test-Path $skillJsonPath) { "✅" } else { "❌" }
        Message = if (Test-Path $skillJsonPath) { "元数据存在" } else { "元数据缺失" }
    }

    # 检查3: README.md存在
    $readmePath = Join-Path $skillDir "README.md"
    $checks += [PSCustomObject]@{
        Name = "README.md存在"
        Status = if (Test-Path $readmePath) { "✅" } else { "❌" }
        Message = if (Test-Path $readmePath) { "说明文档存在" } else { "说明文档缺失" }
    }

    # 检查4: 包含代码示例
    $codePattern = "\`\`\`powershell"
    $skillMdContent = Get-Content $skillMdPath -Raw -ErrorAction SilentlyContinue
    $checks += [PSCustomObject]@{
        Name = "包含代码示例"
        Status = if ($skillMdContent -match $codePattern) { "✅" } else { "⚠️" }
        Message = if ($skillMdContent -match $codePattern) { "包含PowerShell示例" } else { "缺少代码示例" }
    }

    # 检查5: 描述完整
    $checks += [PSCustomObject]@{
        Name = "描述完整"
        Status = if ($skillMdContent -match "## 概述" -and $skillMdContent -match "## 解决方案") { "✅" } else { "⚠️" }
        Message = if ($skillMdContent -match "## 概述" -and $skillMdContent -match "## 解决方案") { "描述完整" } else { "描述不完整" }
    }

    # 显示检查结果
    Write-Host "`n🔍 质量检查: $SkillName" -ForegroundColor Cyan

    $passed = 0
    $failed = 0

    foreach ($check in $checks) {
        Write-Host "   $($check.Status) $($check.Name): $($check.Message)"
        if ($check.Status -eq "✅") { $passed++ }
        else { $failed++ }
    }

    Write-Host "`n   检查结果: $passed 通过, $failed 失败" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Yellow" })

    return $checks
}

# 提取所有相关学习
function Extract-AllSkills {
    Write-Host "`n🔍 自动提取所有Skills..." -ForegroundColor Cyan

    # 识别重复模式
    Write-Host "   识别重复学习模式..." -ForegroundColor Yellow
    $patterns = Find-RepeatingPatterns
    Write-Host "   找到 $($patterns.Count) 个潜在可提取的模式" -ForegroundColor White

    if ($patterns.Count -eq 0) {
        Write-Host "   ❌ 未找到可提取的模式" -ForegroundColor Red
        return
    }

    # 提取每个模式
    $extractedSkills = @()

    $patterns | ForEach-Object {
        $pattern = $_.Key
        $count = $_.Value

        Write-Host "`n   📦 提取模式: $pattern" -ForegroundColor Yellow
        Write-Host "      重复次数: $count" -ForegroundColor White

        # 创建skill名称
        $skillName = $pattern -replace "[^\w\-]", "-" | -replace "-{2,}", "-"
        $skillName = $skillName.ToLower()

        if ($DryRun) {
            Write-Host "      [DRY RUN] 将创建skill: $skillName" -ForegroundColor Gray
        }
        else {
            $result = Extract-LearningToSkill -LearningEntry @{
                summary = $pattern
                date = (Get-Date -Format "yyyy-MM-dd")
                id = "auto-extracted"
                category = "extracted"
                priority = "medium"
                scenarios = @("重复问题", "解决方案优化")
                nonScenarios = @("一次性任务")
                notes = @("需要进一步验证", "建议测试")
            } -SkillName $skillName -Category "extracted"

            if ($result.status -eq "created") {
                $extractedSkills += $result
            }
        }

        # 限制数量
        if ($extractedSkills.Count -ge $MaxSkills) {
            break
        }
    }

    Write-Host "`n✅ 提取完成! 共创建 $($extractedSkills.Count) 个Skills" -ForegroundColor Green
    return $extractedSkills
}

# 导入现有skills
function Import-ExistingSkills {
    Write-Host "`n📂 导入现有skills..." -ForegroundColor Cyan

    $skillsDir = Join-Path $outputPath "*"
    $skills = Get-ChildItem -Path $outputPath -Directory

    Write-Host "   找到 $($skills.Count) 个skills" -ForegroundColor White

    foreach ($skill in $skills) {
        Write-Host "`n   📦 导入skill: $($skill.Name)" -ForegroundColor Yellow
        Write-Host "   路径: $($skill.FullName)" -ForegroundColor White

        # 检查必需文件
        $requiredFiles = @("SKILL.md", "skill.json")
        $allPresent = $true

        foreach ($file in $requiredFiles) {
            $filePath = Join-Path $skill.FullName $file
            if (Test-Path $filePath) {
                Write-Host "      ✅ $file" -ForegroundColor Green
            }
            else {
                Write-Host "      ❌ $file (缺失)" -ForegroundColor Red
                $allPresent = $false
            }
        }

        if ($allPresent) {
            Write-Host "      ✅ Skill可以导入" -ForegroundColor Green
        }
        else {
            Write-Host "      ⚠️  Skill不完整，跳过导入" -ForegroundColor Yellow
        }
    }
}

# 主程序
Write-Host "`n🦞 技能自动提取器" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Gray

switch ($Action) {
    "extract" {
        Write-Host "`n🔍 提取单个学习为Skill" -ForegroundColor Cyan

        # 查找指定分类的学习
        $categoryPattern = "^## \[.*\] $Category"

        # 提取逻辑（简化版）
        Write-Host "   ⚠️  需要指定具体的学习条目ID" -ForegroundColor Yellow
        Write-Host "   用法: ./extractor.ps1 -Action extract -Category <category> -SkillName <skill-name>" -ForegroundColor White
    }

    "extract-all" {
        Extract-AllSkills
    }

    "check" {
        if ([string]::IsNullOrEmpty($SkillName)) {
            Write-Host "❌ 需要指定Skill名称" -ForegroundColor Red
            break
        }

        Invoke-QualityCheck -SkillName $SkillName
    }

    "import" {
        Import-ExistingSkills
    }

    default {
        Write-Host "用法:" -ForegroundColor Yellow
        Write-Host "  ./extractor.ps1 -Action extract -Category <category> -SkillName <name>" -ForegroundColor White
        Write-Host "  ./extractor.ps1 -Action extract-all -MaxSkills 10" -ForegroundColor White
        Write-Host "  ./extractor.ps1 -Action check -SkillName <name>" -ForegroundColor White
        Write-Host "  ./extractor.ps1 -Action import" -ForegroundColor White
    }
}

Write-Host "`n" -NoNewline
