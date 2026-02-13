# Skill 创建引擎

# @Author: 灵眸
# @Version: 1.0.0
# @Date: 2026-02-13

param(
    [Parameter(Mandatory=$true)]
    [string]$Name,

    [Parameter(Mandatory=$false)]
    [string]$Template = "automation",

    [Parameter(Mandatory=$false)]
    [switch]$Force = $false,

    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false
)

# 获取脚本路径
$ScriptPath = $PSScriptRoot
$TemplatesDir = "$ScriptPath/../templates"
$SkillsDir = "$ScriptPath/../../.."

# 初始化结果
$Result = @{
    Success = $false
    Name = $Name
    Template = $Template
    Force = $Force
    DryRun = $DryRun
    StartTime = Get-Date
    EndTime = $null
    Duration = 0
    Messages = @()
    Errors = @()
    SkillPath = ""
    FilesCreated = @()
}

# 日志函数
function Write-Log {
    param([string]$Message, [ValidateSet("INFO", "SUCCESS", "ERROR", "WARNING", "DEBUG")]
    [string]$Level = "INFO")

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Prefix = "[$Timestamp] [$Level]"

    switch ($Level) {
        "INFO"    { Write-Host "$Prefix $Message" -ForegroundColor Cyan }
        "SUCCESS" { Write-Host "$Prefix $Message" -ForegroundColor Green }
        "ERROR"   { Write-Host "$Prefix $Message" -ForegroundColor Red }
        "WARNING" { Write-Host "$Prefix $Message" -ForegroundColor Yellow }
        "DEBUG"   { Write-Host "$Prefix $Message" -ForegroundColor DarkGray }
    }

    $Result.Messages += "$Prefix $Message"
}

try {
    Write-Log "Skill 创建引擎启动" "INFO"

    # 转换Skill名称为有效路径
    $SkillName = $Name -replace '[^a-zA-Z0-9_-]', '-'
    $SkillName = $SkillName.ToLower()
    $SkillPath = "$SkillsDir/$SkillName"

    # 检查是否已存在
    if (Test-Path $SkillPath) {
        if (-not $Force) {
            throw "Skill '$Name' 已存在"
        } else {
            Write-Log "强制模式：覆盖现有Skill" "WARNING"
        }
    }

    Write-Log "Skill 名称: $SkillName" "DEBUG"
    Write-Log "使用模板: $Template" "DEBUG"

    # 确定模板文件
    $TemplateFile = "$TemplatesDir/$Template.json"
    if (-not (Test-Path $TemplateFile)) {
        # 尝试默认模板
        $TemplateFile = "$TemplatesDir/default.json"
        if (-not (Test-Path $TemplateFile)) {
            $TemplateFile = "$TemplatesDir/automation.json"
        }
    }

    Write-Log "加载模板: $TemplateFile" "DEBUG"

    # 加载模板
    if (-not (Test-Path $TemplateFile)) {
        throw "模板文件不存在: $TemplateFile"
    }

    $Template = Get-Content -Path $TemplateFile -Raw | ConvertFrom-Json

    Write-Log "模板加载成功" "SUCCESS"

    if ($DryRun) {
        Write-Log "Dry Run 模式：不创建文件" "DEBUG"
        $Result.FilesCreated += @{
            Name = "$SkillName/SKILL.md"
            Source = "Template: $TemplateFile"
            DryRun = $true
        }
        $Result.FilesCreated += @{
            Name = "$SkillName/config.json"
            Source = "Template: $TemplateFile"
            DryRun = $true
        }
        $Result.FilesCreated += @{
            Name = "$SkillName/data/"
            Source = "Template: $TemplateFile"
            DryRun = $true
        }
        $Result.FilesCreated += @{
            Name = "$SkillName/scripts/"
            Source = "Template: $TemplateFile"
            DryRun = $true
        }
        $Result.Success = $true
        $Result.SkillPath = $SkillPath
        return $Result
    }

    # 创建目录结构
    $Dirs = @(
        "$SkillPath",
        "$SkillPath/data",
        "$SkillPath/scripts",
        "$SkillPath/templates",
        "$SkillPath/config",
        "$SkillPath/tests",
        "$SkillPath/reports"
    )

    foreach ($Dir in $Dirs) {
        if (-not (Test-Path $Dir)) {
            New-Item -ItemType Directory -Path $Dir -Force | Out-Null
            $Result.FilesCreated += @{
                Type = "directory"
                Path = $Dir
            }
        }
    }

    Write-Log "目录结构创建完成" "SUCCESS"

    # 从模板生成SKILL.md
    $SkillContent = $Template.skillContent -replace "{{NAME}}", $SkillName
    $SkillContent = $SkillContent -replace "{{TEMPLATE}}", $Template.templateName

    $SkillFile = "$SkillPath/SKILL.md"
    $SkillContent | Out-File -FilePath $SkillFile -Encoding UTF8
    $Result.FilesCreated += @{
        Type = "file"
        Path = $SkillFile
        Size = (Get-Item $SkillFile).Length
    }

    Write-Log "SKILL.md 创建成功" "SUCCESS"

    # 从模板生成config.json
    $ConfigContent = $Template.configContent -replace "{{NAME}}", $SkillName
    $ConfigContent = $ConfigContent -replace "{{TEMPLATE}}", $Template.templateName

    $ConfigFile = "$SkillPath/config.json"
    $ConfigContent | Out-File -FilePath $ConfigFile -Encoding UTF8
    $Result.FilesCreated += @{
        Type = "file"
        Path = $ConfigFile
        Size = (Get-Item $ConfigFile).Length
    }

    Write-Log "config.json 创建成功" "SUCCESS"

    # 生成README.md
    $ReadmeContent = @"
# $SkillName

## 简介
$($Template.description)

## 版本
1.0.0

## 作者
灵眸

## 使用方法
\`\`\`powershell
.\$SkillName.ps1 -Action <action> -Name <name>
\`\`\`

## 参数
$($Template.parametersDescription)

## 依赖
$($Template.dependencies)

---

**创建日期**: 2026-02-13
**基于模板**: $Template.templateName
"@

    $ReadmeFile = "$SkillPath/README.md"
    $ReadmeContent | Out-File -FilePath $ReadmeFile -Encoding UTF8
    $Result.FilesCreated += @{
        Type = "file"
        Path = $ReadmeFile
        Size = (Get-Item $ReadmeFile).Length
    }

    Write-Log "README.md 创建成功" "SUCCESS"

    # 创建示例脚本
    $ScriptTemplate = $Template.scriptTemplate -replace "{{NAME}}", $SkillName

    $ScriptFile = "$SkillPath/scripts/$SkillName.ps1"
    $ScriptTemplate | Out-File -FilePath $ScriptFile -Encoding UTF8
    $Result.FilesCreated += @{
        Type = "file"
        Path = $ScriptFile
        Size = (Get-Item $ScriptFile).Length
    }

    Write-Log "示例脚本创建成功" "SUCCESS"

    # 创建示例测试
    $TestTemplate = @"
# 测试 $SkillName

param(
    [Parameter(Mandatory=$true)]
    [string]$TestName
)

Write-Host "测试: $TestName" -ForegroundColor Cyan

# 测试1: 基础功能
try {
    $result = .\$SkillName.ps1 -Action test
    if ($result.Success) {
        Write-Host "✓ 测试通过" -ForegroundColor Green
    } else {
        Write-Host "✗ 测试失败" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ 测试异常: $($_.Exception.Message)" -ForegroundColor Red
}
"@

    $TestFile = "$SkillPath/tests/test-example.ps1"
    $TestTemplate | Out-File -FilePath $TestFile -Encoding UTF8
    $Result.FilesCreated += @{
        Type = "file"
        Path = $TestFile
        Size = (Get-Item $TestFile).Length
    }

    Write-Log "示例测试创建成功" "SUCCESS"

    # 设置最终状态
    $Result.Success = $true
    $Result.SkillPath = $SkillPath
    $Result.EndTime = Get-Date
    $Result.Duration = ($Result.EndTime - $Result.StartTime).TotalSeconds

    Write-Log "Skill 创建完成" "SUCCESS"
    Write-Log "创建文件数: $($Result.FilesCreated.Count)" "SUCCESS"
    Write-Log "执行时间: $([math]::Round($Result.Duration, 2))秒" "SUCCESS"

} catch {
    $Result.Success = $false
    $Result.Errors += $_.Exception.Message
    $Result.Errors += $_.ScriptStackTrace

    Write-Log "创建失败: $($_.Exception.Message)" "ERROR"

    # 尝试清理已创建的文件
    if ($Result.SkillPath -and (Test-Path $Result.SkillPath)) {
        Remove-Item -Path $Result.SkillPath -Recurse -Force -ErrorAction SilentlyContinue
    }

} finally {
    return $Result
}
