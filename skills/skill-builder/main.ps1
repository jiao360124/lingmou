# Skill标准化系统 - 可测量可执行性

# @Author: 灵眸
# @Version: 1.0.0
# @Date: 2026-02-13

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("validate", "compile", "score", "report", "test")]
    [string]$Action = "validate",

    [Parameter(Mandatory=$true)]
    [string]$SkillPath,

    [Parameter(Mandatory=$false)]
    [switch]$Strict = $false,

    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false
)

# 获取脚本路径
$ScriptPath = $PSScriptRoot
$SkillsDir = "$ScriptPath/../../.."

# 初始化结果
$Result = @{
    Success = $false
    Action = $Action
    SkillPath = $SkillPath
    Strict = $Strict
    DryRun = $DryRun
    StartTime = Get-Date
    EndTime = $null
    Duration = 0
    Messages = @()
    Errors = @()
    SkillName = $SkillPath.Split('\')[-1]
    Metrics = @{}
}

# 日志函数
function Write-Log {
    param([string]$Message, [ValidateSet("INFO", "SUCCESS", "ERROR", "WARNING", "DEBUG", "STANDARD")]
    [string]$Level = "INFO")

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Prefix = "[$Timestamp] [$Level]"

    switch ($Level) {
        "INFO"    { Write-Host "$Prefix $Message" -ForegroundColor Cyan }
        "SUCCESS" { Write-Host "$Prefix $Message" -ForegroundColor Green }
        "ERROR"   { Write-Host "$Prefix $Message" -ForegroundColor Red }
        "WARNING" { Write-Host "$Prefix $Message" -ForegroundColor Yellow }
        "DEBUG"   { Write-Host "$Prefix $Message" -ForegroundColor DarkGray }
        "STANDARD" { Write-Host "$Prefix $Message" -ForegroundColor Magenta }
    }

    $Result.Messages += "$Prefix $Message"
}

try {
    Write-Log "Skill标准化系统启动" "INFO"
    Write-Log "Action: $Action" "DEBUG"
    Write-Log "Skill: $SkillPath" "DEBUG"

    # 验证Skill路径
    $FullSkillPath = "$SkillsDir/$SkillPath"

    if (-not (Test-Path $FullSkillPath)) {
        throw "Skill路径不存在: $FullSkillPath"
    }

    Write-Log "Skill路径: $FullSkillPath" "DEBUG"

    # 加载Skill配置
    $ConfigFile = "$FullSkillPath/config.json"

    if (-not (Test-Path $ConfigFile)) {
        throw "配置文件不存在: $ConfigFile"
    }

    $SkillConfig = Get-Content -Path $ConfigFile | ConvertFrom-Json
    $Result.SkillName = $SkillConfig.name

    Write-Log "Skill名称: $($SkillConfig.name)" "STANDARD"

    switch ($Action) {
        "validate" {
            $Result = & "$ScriptPath/validators/validate-skill.ps1" -SkillPath $FullSkillPath -Strict:$Strict -DryRun:$DryRun
        }

        "compile" {
            $Result = & "$ScriptPath/compilers/compile-skill.ps1" -SkillPath $FullSkillPath -Strict:$Strict -DryRun:$DryRun
        }

        "score" {
            $Result = & "$ScriptPath/scorers/score-skill.ps1" -SkillPath $FullSkillPath -Strict:$Strict -DryRun:$DryRun
        }

        "test" {
            $Result = & "$ScriptPath/testers/test-skill.ps1" -SkillPath $FullSkillPath -Strict:$Strict -DryRun:$DryRun
        }

        "report" {
            $Result = & "$ScriptPath/reporters/generate-report.ps1" -SkillPath $FullSkillPath -Strict:$Strict -DryRun:$DryRun
        }
    }

    # 设置最终状态
    $Result.EndTime = Get-Date
    $Result.Duration = ($Result.EndTime - $Result.StartTime).TotalSeconds

    Write-Log "操作完成" "SUCCESS"
    Write-Log "执行时间: $([math]::Round($Result.Duration, 2))秒" "SUCCESS"

} catch {
    $Result.Success = $false
    $Result.Errors += $_.Exception.Message
    $Result.Errors += $_.ScriptStackTrace

    Write-Log "操作失败: $($_.Exception.Message)" "ERROR"

    # 保存错误
    $ErrorFile = "$ScriptPath/data/errors/skill-standard-error-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    $ErrorContent = @"
Skill标准化系统错误
时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
操作: $Action
Skill: $SkillPath
错误: $($_.Exception.Message)
堆栈: $($_.ScriptStackTrace)

"@
    $ErrorContent | Out-File -FilePath $ErrorFile -Encoding UTF8 -Force
    Write-Log "错误已记录: $ErrorFile" "WARNING"

} finally {
    return $Result
}
