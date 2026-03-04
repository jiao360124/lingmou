# Skill 测试框架

# @Author: 灵眸
# @Version: 1.0.0
# @Date: 2026-02-13

param(
    [Parameter(Mandatory=$true)]
    [string]$SkillName,

    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false
)

# 获取脚本路径
$ScriptPath = $PSScriptRoot
$SkillsDir = "$ScriptPath/../../.."
$SkillPath = "$SkillsDir/$SkillName"
$SkillScript = "$SkillPath/scripts/$SkillName.ps1"

# 初始化结果
$Result = @{
    Success = $true
    SkillName = $SkillName
    DryRun = $DryRun
    StartTime = Get-Date
    EndTime = $null
    Duration = 0
    Messages = @()
    Tests = @()
    Passed = 0
    Failed = 0
    Skipped = 0
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
    Write-Log "测试框架启动" "INFO"

    # 检查Skill是否存在
    if (-not (Test-Path $SkillPath)) {
        throw "Skill '$SkillName' 不存在"
    }

    # 检查测试脚本是否存在
    $TestScript = "$SkillPath/tests/test-example.ps1"

    if (-not (Test-Path $TestScript)) {
        throw "测试脚本不存在: $TestScript"
    }

    Write-Log "测试脚本: $TestScript" "DEBUG"

    if ($DryRun) {
        Write-Log "Dry Run 模式：跳过实际测试" "DEBUG"

        $Result.Tests += @{
            Name = "test-1: 基础功能"
            Status = "skipped"
            Reason = "Dry Run模式"
            Duration = 0
        }

        $Result.Tests += @{
            Name = "test-2: 错误处理"
            Status = "skipped"
            Reason = "Dry Run模式"
            Duration = 0
        }

        $Result.Tests += @{
            Name = "test-3: 性能测试"
            Status = "skipped"
            Reason = "Dry Run模式"
            Duration = 0
        }

        $Result.Passed = 0
        $Result.Failed = 0
        $Result.Skipped = 3

        $Result.Success = $true
        $Result.EndTime = Get-Date
        $Result.Duration = ($Result.EndTime - $Result.StartTime).TotalSeconds

        return $Result
    }

    # 运行测试
    Write-Log "开始运行测试..." "INFO"

    # 测试1: 基础功能
    $Test1Start = Get-Date

    try {
        $Test1Output = & $TestScript -Action run -TestName "test-1: 基础功能"

        $Test1End = Get-Date
        $Test1Duration = ($Test1End - $Test1Start).TotalSeconds

        $Test1Result = @{
            Name = "test-1: 基础功能"
            Status = "passed"
            Output = $Test1Output
            Duration = $Test1Duration
        }

        $Result.Tests += $Test1Result
        $Result.Passed++

        Write-Log "✓ 测试通过: 基础功能" "SUCCESS"
    } catch {
        $Test1End = Get-Date
        $Test1Duration = ($Test1End - $Test1Start).TotalSeconds

        $Test1Result = @{
            Name = "test-1: 基础功能"
            Status = "failed"
            Error = $_.Exception.Message
            Duration = $Test1Duration
        }

        $Result.Tests += $Test1Result
        $Result.Failed++
        $Result.Success = $false

        Write-Log "✗ 测试失败: 基础功能 - $($_.Exception.Message)" "ERROR"
    }

    # 测试2: 错误处理
    $Test2Start = Get-Date

    try {
        $Test2Output = & $TestScript -Action run -TestName "test-2: 错误处理"

        $Test2End = Get-Date
        $Test2Duration = ($Test2End - $Test2Start).TotalSeconds

        $Test2Result = @{
            Name = "test-2: 错误处理"
            Status = "passed"
            Output = $Test2Output
            Duration = $Test2Duration
        }

        $Result.Tests += $Test2Result
        $Result.Passed++

        Write-Log "✓ 测试通过: 错误处理" "SUCCESS"
    } catch {
        $Test2End = Get-Date
        $Test2Duration = ($Test2End - $Test2Start).TotalSeconds

        $Test2Result = @{
            Name = "test-2: 错误处理"
            Status = "failed"
            Error = $_.Exception.Message
            Duration = $Test2Duration
        }

        $Result.Tests += $Test2Result
        $Result.Failed++
        $Result.Success = $false

        Write-Log "✗ 测试失败: 错误处理 - $($_.Exception.Message)" "ERROR"
    }

    # 测试3: 性能测试
    $Test3Start = Get-Date

    try {
        $Test3Output = & $TestScript -Action run -TestName "test-3: 性能测试"

        $Test3End = Get-Date
        $Test3Duration = ($Test3End - $Test3Start).TotalSeconds

        $Test3Result = @{
            Name = "test-3: 性能测试"
            Status = "passed"
            Output = $Test3Output
            Duration = $Test3Duration
        }

        $Result.Tests += $Test3Result
        $Result.Passed++

        Write-Log "✓ 测试通过: 性能测试" "SUCCESS"
    } catch {
        $Test3End = Get-Date
        $Test3Duration = ($Test3End - $Test3Start).TotalSeconds

        $Test3Result = @{
            Name = "test-3: 性能测试"
            Status = "failed"
            Error = $_.Exception.Message
            Duration = $Test3Duration
        }

        $Result.Tests += $Test3Result
        $Result.Failed++
        $Result.Success = $false

        Write-Log "✗ 测试失败: 性能测试 - $($_.Exception.Message)" "ERROR"
    }

    # 测试4: 集成测试
    $Test4Start = Get-Date

    try {
        # TODO: 添加集成测试
        $Test4Output = "集成测试跳过（待实现）"

        $Test4End = Get-Date
        $Test4Duration = ($Test4End - $Test4Start).TotalSeconds

        $Test4Result = @{
            Name = "test-4: 集成测试"
            Status = "skipped"
            Reason = "待实现"
            Duration = $Test4Duration
        }

        $Result.Tests += $Test4Result
        $Result.Skipped++

        Write-Log "⊘ 测试跳过: 集成测试" "WARNING"
    } catch {
        $Test4End = Get-Date
        $Test4Duration = ($Test4End - $Test4Start).TotalSeconds

        $Test4Result = @{
            Name = "test-4: 集成测试"
            Status = "failed"
            Error = $_.Exception.Message
            Duration = $Test4Duration
        }

        $Result.Tests += $Test4Result
        $Result.Failed++
        $Result.Success = $false

        Write-Log "✗ 测试失败: 集成测试 - $($_.Exception.Message)" "ERROR"
    }

    # 保存测试结果
    $TestReportFile = "$SkillPath/reports/test-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    if (-not (Test-Path (Split-Path $TestReportFile))) {
        New-Item -ItemType Directory -Path (Split-Path $TestReportFile) -Force | Out-Null
    }

    $Result | ConvertTo-Json -Depth 10 | Out-File -FilePath $TestReportFile -Encoding UTF8

    Write-Log "测试结果已保存: $TestReportFile" "SUCCESS"

    # 打印测试摘要
    Write-Log "" "INFO"
    Write-Log "========== 测试摘要 ==========" "INFO"
    Write-Log "总测试数: $($Result.Tests.Count)" "INFO"
    Write-Log "通过: $($Result.Passed)" "SUCCESS"
    Write-Log "失败: $($Result.Failed)" "ERROR"
    Write-Log "跳过: $($Result.Skipped)" "WARNING"
    Write-Log "通过率: $([math]::Round(($Result.Passed / $Result.Tests.Count) * 100, 2))%" "INFO"
    Write-Log "===============================" "INFO"

    # 设置最终状态
    $Result.EndTime = Get-Date
    $Result.Duration = ($Result.EndTime - $Result.StartTime).TotalSeconds

    Write-Log "测试完成" "INFO"
    Write-Log "执行时间: $([math]::Round($Result.Duration, 2))秒" "INFO"

} catch {
    $Result.Success = $false
    $Result.Errors += $_.Exception.Message
    $Result.Errors += $_.ScriptStackTrace

    Write-Log "测试失败: $($_.Exception.Message)" "ERROR"

} finally {
    return $Result
}
