# Skill Builder - 核心引擎

# @Author: 灵眸
# @Version: 1.0.0
# @Date: 2026-02-13
# @Purpose: 自动创建和优化Skills，实现自我进化

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("create", "optimize", "compile", "test", "analyze", "improve", "report")]
    [string]$Action = "analyze",

    [Parameter(Mandatory=$true)]
    [string]$Name,

    [Parameter(Mandatory=$false)]
    [string]$Template = "default",

    [Parameter(Mandatory=$false)]
    [string]$Path = "",

    [Parameter(Mandatory=$false)]
    [string]$Output = "",

    [Parameter(Mandatory=$false)]
    [switch]$Force = $false,

    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false
)

# 获取脚本路径
$ScriptPath = $PSScriptRoot
$SkillsDir = "$ScriptPath/../.."
$TemplatesDir = "$ScriptPath/templates"
$CompilerDir = "$ScriptPath/compiler"
$TestDir = "$ScriptPath/test"
$DataDir = "$ScriptPath/data"

# 初始化
$StartTime = Get-Date
$Result = @{
    Success = $false
    Action = $Action
    SkillName = $Name
    Template = $Template
    Path = $Path
    Output = $Output
    Force = $Force
    DryRun = $DryRun
    StartTime = $StartTime
    EndTime = $null
    Duration = 0
    Messages = @()
    Errors = @()
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
    Write-Log "Skill Builder 启动" "INFO"
    Write-Log "Action: $Action" "DEBUG"
    Write-Log "Skill Name: $Name" "DEBUG"

    # 验证参数
    if ([string]::IsNullOrWhiteSpace($Name)) {
        throw "Skill name is required"
    }

    # 转换为小写并移除特殊字符
    $SkillName = $Name -replace '[^a-zA-Z0-9_-]', '-'
    $SkillName = $SkillName.ToLower()

    # 确定目标目录
    $TargetDir = "$SkillsDir/$SkillName"

    # 根据Action执行不同操作
    switch ($Action) {
        "create" {
            $Result = & "$CompilerDir/create-skill.ps1" -Name $SkillName -Template $Template -Force:$Force -DryRun:$DryRun
        }

        "optimize" {
            $Result = & "$CompilerDir/optimize-skill.ps1" -SkillName $SkillName -Force:$Force -DryRun:$DryRun
        }

        "compile" {
            $Result = & "$CompilerDir/analyze-skill.ps1" -SkillName $SkillName -DryRun:$DryRun
        }

        "test" {
            $Result = & "$TestDir/run-tests.ps1" -SkillName $SkillName -DryRun:$DryRun
        }

        "analyze" {
            $Result = & "$CompilerDir/analyze-skill.ps1" -SkillName $SkillName -DryRun:$DryRun
        }

        "improve" {
            $Result = & "$CompilerDir/optimize-skill.ps1" -SkillName $SkillName -Force:$Force -DryRun:$DryRun
            if ($Result.Success) {
                $Result = & "$TestDir/run-tests.ps1" -SkillName $SkillName -DryRun:$DryRun
            }
        }

        "report" {
            $Result = & "$TestDir/generate-report.ps1" -SkillName $SkillName -DryRun:$DryRun
        }
    }

    # 计算执行时间
    $EndTime = Get-Date
    $Result.Duration = ($EndTime - $StartTime).TotalSeconds
    $Result.EndTime = $EndTime

    # 设置最终状态
    if ($Result.Errors.Count -gt 0) {
        $Result.Success = $false
        Write-Log "操作失败" "ERROR"
        Write-Log "错误数量: $($Result.Errors.Count)" "ERROR"
        foreach ($Error in $Result.Errors) {
            Write-Log "  - $Error" "ERROR"
        }
    } else {
        $Result.Success = $true
        Write-Log "操作成功" "SUCCESS"
        Write-Log "执行时间: $([math]::Round($Result.Duration, 2))秒" "SUCCESS"
    }

    # 保存结果
    $ResultFile = "$DataDir/results/skill-builder-$SkillName-$Action.json"
    if (-not (Test-Path (Split-Path $ResultFile))) {
        New-Item -ItemType Directory -Path (Split-Path $ResultFile) -Force | Out-Null
    }

    $Result | ConvertTo-Json -Depth 10 | Out-File -FilePath $ResultFile -Encoding UTF8

    return $Result

} catch {
    $Result.Success = $false
    $Result.Errors += $_.Exception.Message
    $Result.Errors += $_.ScriptStackTrace

    Write-Log "错误: $($_.Exception.Message)" "ERROR"
    Write-Log "堆栈跟踪: $($_.ScriptStackTrace)" "ERROR"

    # 保存错误结果
    $ResultFile = "$DataDir/errors/skill-builder-$SkillName-$Action.json"
    if (-not (Test-Path (Split-Path $ResultFile))) {
        New-Item -ItemType Directory -Path (Split-Path $ResultFile) -Force | Out-Null
    }

    $Result | ConvertTo-Json -Depth 10 | Out-File -FilePath $ResultFile -Encoding UTF8

    return $Result
} finally {
    Write-Log "Skill Builder 完成" "INFO"
}
