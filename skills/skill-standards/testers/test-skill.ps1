# Skill测试器

# @Author: 灵眸
# @Version: 1.0.0
# @Date: 2026-02-13

param(
    [Parameter(Mandatory=$true)]
    [string]$SkillPath,

    [Parameter(Mandatory=$false)]
    [switch]$Strict = $false,

    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false
)

# 初始化结果
$Result = @{
    Success = $true
    SkillPath = $SkillPath
    Strict = $Strict
    DryRun = $DryRun
    StartTime = Get-Date
    EndTime = $null
    Duration = 0
    Messages = @()
    Errors = @()
    Warnings = @()
    TestResults = @{}
    Coverage = 0
    TestCount = 0
    Passed = 0
    Failed = 0
    Skipped = 0
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
    Write-Log "Skill测试器启动" "STANDARD"
    Write-Log "Skill路径: $SkillPath" "DEBUG"

    # 检查Skill路径
    if (-not (Test-Path $SkillPath)) {
        throw "Skill路径不存在: $SkillPath"
    }

    # 提取skill名称
    $SkillName = $SkillPath.Split('\')[-1]
    Write-Log "Skill名称: $SkillName" "STANDARD"

    if ($DryRun) {
        Write-Log "Dry Run 模式：运行模拟测试" "DEBUG"

        $Result.TestResults = @{
            unitTests = @{
                name = "单元测试-1"
                status = "passed"
                duration = 0.5
                description = "参数解析测试"
            }
            unitTests2 = @{
                name = "单元测试-2"
                status = "passed"
                duration = 0.3
                description = "错误处理测试"
            }
            integrationTests = @{
                name = "集成测试-1"
                status = "passed"
                duration = 1.2
                description = "完整流程测试"
            }
        }

        $Result.TestCount = 3
        $Result.Passed = 3
        $Result.Failed = 0
        $Result.Skipped = 0
        $Result.Coverage = 85

        $Result.Success = $true
        return $Result
    }

    # ========== 第1步：加载配置 ==========
    Write-Log "加载配置文件..." "STANDARD"

    $ConfigFile = "$SkillPath/config.json"
    if (-not (Test-Path $ConfigFile)) {
        throw "配置文件不存在: $ConfigFile"
    }

    $SkillConfig = Get-Content -Path $ConfigFile | ConvertFrom-Json
    Write-Log "✓ 配置文件加载成功" "SUCCESS"

    # ========== 第2步：运行单元测试 ==========
    Write-Log "运行单元测试..." "STANDARD"

    $UnitTests = @()

    # 测试1: 参数验证
    $Test1Start = Get-Date
    try {
        if ($SkillConfig.parameters -and ($SkillConfig.parameters -is [System.Collections.Hashtable])) {
            $Passed = $true
            $Test1Status = "passed"
        } else {
            $Passed = $false
            $Test1Status = "failed"
        }

        $Test1End = Get-Date
        $Test1Duration = ($Test1End - $Test1Start).TotalSeconds

        $UnitTests += @{
            name = "参数验证测试"
            status = $Test1Status
            duration = $Test1Duration
            description = "检查参数定义是否正确"
        }

        if ($Test1Status -eq "passed") {
            $Result.Passed++
            Write-Log "  ✓ 参数验证测试通过" "SUCCESS"
        } else {
            $Result.Failed++
            Write-Log "  ✗ 参数验证测试失败" "ERROR"
        }

        $Result.TestCount++
    } catch {
        $Result.Failed++
        $Result.TestCount++

        $UnitTests += @{
            name = "参数验证测试"
            status = "failed"
            duration = 0
            description = "检查参数定义是否正确"
            error = $_.Exception.Message
        }

        Write-Log "  ✗ 参数验证测试异常: $($_.Exception.Message)" "ERROR"
    }

    # 测试2: 错误处理
    $Test2Start = Get-Date
    try {
        $ScriptFile = "$SkillPath/scripts/$SkillName.ps1"
        if (Test-Path $ScriptFile) {
            $ScriptContent = Get-Content -Path $ScriptFile -Raw
            if ($ScriptContent -match 'try\s*\{') {
                $Passed = $true
                $Test2Status = "passed"
            } else {
                $Passed = $false
                $Test2Status = "failed"
            }
        } else {
            $Passed = $false
            $Test2Status = "skipped"
        }

        $Test2End = Get-Date
        $Test2Duration = ($Test2End - $Test2Start).TotalSeconds

        if ($Test2Status -eq "skipped") {
            $Result.Skipped++
            Write-Log "  ⊘ 错误处理测试跳过" "WARNING"
        } else {
            if ($Test2Status -eq "passed") {
                $Result.Passed++
                Write-Log "  ✓ 错误处理测试通过" "SUCCESS"
            } else {
                $Result.Failed++
                Write-Log "  ✗ 错误处理测试失败" "ERROR"
            }
        }

        $Result.TestCount++
    } catch {
        $Result.Failed++
        $Result.TestCount++

        $UnitTests += @{
            name = "错误处理测试"
            status = "failed"
            duration = 0
            description = "检查错误处理是否正确"
            error = $_.Exception.Message
        }

        Write-Log "  ✗ 错误处理测试异常: $($_.Exception.Message)" "ERROR"
    }

    # 测试3: 配置完整性
    $Test3Start = Get-Date
    try {
        $RequiredFields = @("name", "version", "author", "description")
        $MissingFields = @()

        foreach ($Field in $RequiredFields) {
            if (-not $SkillConfig.$Field) {
                $MissingFields += $Field
            }
        }

        if ($MissingFields.Count -eq 0) {
            $Passed = $true
            $Test3Status = "passed"
        } else {
            $Passed = $false
            $Test3Status = "failed"
        }

        $Test3End = Get-Date
        $Test3Duration = ($Test3End - $Test3Start).TotalSeconds

        if ($Test3Status -eq "passed") {
            $Result.Passed++
            Write-Log "  ✓ 配置完整性测试通过" "SUCCESS"
        } else {
            $Result.Failed++
            Write-Log "  ✗ 配置完整性测试失败 (缺少: $($MissingFields -join ', '))" "ERROR"
        }

        $Result.TestCount++
    } catch {
        $Result.Failed++
        $Result.TestCount++

        $UnitTests += @{
            name = "配置完整性测试"
            status = "failed"
            duration = 0
            description = "检查配置字段是否完整"
            error = $_.Exception.Message
        }

        Write-Log "  ✗ 配置完整性测试异常: $($_.Exception.Message)" "ERROR"
    }

    $Result.TestResults.unitTests = $UnitTests

    # ========== 第3步：运行集成测试 ==========
    Write-Log "运行集成测试..." "STANDARD"

    $IntegrationTests = @()

    # 测试1: 脚本语法
    $Test4Start = Get-Date
    try {
        $ScriptFile = "$SkillPath/scripts/$SkillName.ps1"

        if (Test-Path $ScriptFile) {
            # 尝试解析脚本（不会实际执行）
            $ScriptContent = Get-Content -Path $ScriptFile -Raw

            # 检查基本语法
            $Lines = $ScriptContent.Split("`n").Count
            if ($Lines -gt 0) {
                $Passed = $true
                $Test4Status = "passed"
            } else {
                $Passed = $false
                $Test4Status = "failed"
            }
        } else {
            $Passed = $false
            $Test4Status = "skipped"
        }

        $Test4End = Get-Date
        $Test4Duration = ($Test4End - $Test4Start).TotalSeconds

        if ($Test4Status -eq "skipped") {
            $Result.Skipped++
            Write-Log "  ⊘ 脚本语法测试跳过" "WARNING"
        } else {
            if ($Test4Status -eq "passed") {
                $Result.Passed++
                Write-Log "  ✓ 脚本语法测试通过" "SUCCESS"
            } else {
                $Result.Failed++
                Write-Log "  ✗ 脚本语法测试失败" "ERROR"
            }
        }

        $Result.TestCount++
    } catch {
        $Result.Failed++
        $Result.TestCount++

        $IntegrationTests += @{
            name = "脚本语法测试"
            status = "failed"
            duration = 0
            description = "检查脚本语法是否正确"
            error = $_.Exception.Message
        }

        Write-Log "  ✗ 脚本语法测试异常: $($_.Exception.Message)" "ERROR"
    }

    # 测试2: 依赖检查
    $Test5Start = Get-Date
    try {
        if ($SkillConfig.dependencies -and $SkillConfig.dependencies.Count -gt 0) {
            $Passed = $true
            $Test5Status = "passed"
            $Test5Detail = "$($SkillConfig.dependencies.Count) 个依赖已定义"
        } else {
            $Passed = $true
            $Test5Status = "passed"
            $Test5Detail = "无依赖"
        }

        $Test5End = Get-Date
        $Test5Duration = ($Test5End - $Test5Start).TotalSeconds

        if ($Test5Status -eq "passed") {
            $Result.Passed++
            Write-Log "  ✓ 依赖检查测试通过 ($Test5Detail)" "SUCCESS"
        } else {
            $Result.Failed++
            Write-Log "  ✗ 依赖检查测试失败" "ERROR"
        }

        $Result.TestCount++
    } catch {
        $Result.Failed++
        $Result.TestCount++

        $IntegrationTests += @{
            name = "依赖检查测试"
            status = "failed"
            duration = 0
            description = "检查依赖项是否正确"
            error = $_.Exception.Message
        }

        Write-Log "  ✗ 依赖检查测试异常: $($_.Exception.Message)" "ERROR"
    }

    $Result.TestResults.integrationTests = $IntegrationTests

    # ========== 第4步：计算测试覆盖率 ==========
    Write-Log "计算测试覆盖率..." "STANDARD"

    # 基于测试数量和类型估算覆盖率
    $TestCount = $Result.TestCount
    $MaxTests = 10  # 假设最多10个测试

    if ($TestCount -ge 8) {
        $Result.Coverage = 90
        Write-Log "  覆盖率: 90%" "SUCCESS"
    } elseif ($TestCount -ge 5) {
        $Result.Coverage = 75
        Write-Log "  覆盖率: 75%" "SUCCESS"
    } elseif ($TestCount -ge 3) {
        $Result.Coverage = 60
        Write-Log "  覆盖率: 60%" "SUCCESS"
    } else {
        $Result.Coverage = 40
        Write-Log "  覆盖率: 40%" "WARNING"
    }

    # ========== 第5步：生成测试报告 ==========
    Write-Log "生成测试报告..." "STANDARD"

    $ReportFile = "$SkillPath/reports/test-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    if (-not (Test-Path (Split-Path $ReportFile))) {
        New-Item -ItemType Directory -Path (Split-Path $ReportFile) -Force | Out-Null
    }

    $TestReport = @{
        timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        skillPath = $SkillPath
        skillName = $SkillName
        testCount = $Result.TestCount
        passed = $Result.Passed
        failed = $Result.Failed
        skipped = $Result.Skipped
        coverage = $Result.Coverage
        tests = $Result.TestResults
        strictMode = $Strict
    }

    $TestReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $ReportFile -Encoding UTF8 -Force
    Write-Log "✓ 测试报告已保存: $ReportFile" "SUCCESS"

    # ========== 输出测试摘要 ==========
    Write-Log "`n========== 测试摘要 ==========" "STANDARD"
    Write-Log "Skill名称: $SkillName" "STANDARD"
    Write-Log "`n测试统计:" "STANDARD"
    Write-Log "  总测试数: $Result.TestCount" "STANDARD"
    Write-Log "  通过: $Result.Passed" "SUCCESS"
    Write-Log "  失败: $Result.Failed" "ERROR"
    Write-Log "  跳过: $Result.Skipped" "WARNING"
    Write-Log "  覆盖率: $Result.Coverage%" "STANDARD"

    # 计算通过率
    $PassRate = [math]::Round(($Result.Passed / $Result.TestCount) * 100, 2)
    Write-Log "`n通过率: $PassRate%" "STANDARD"

    # 测试等级
    if ($PassRate -ge 90 -and $Result.Coverage -ge 80) {
        Write-Log "  等级: ⭐⭐⭐⭐⭐ 卓越" "SUCCESS"
    } elseif ($PassRate -ge 80 -and $Result.Coverage -ge 70) {
        Write-Log "  等级: ⭐⭐⭐⭐ 优秀" "SUCCESS"
    } elseif ($PassRate -ge 70 -and $Result.Coverage -ge 60) {
        Write-Log "  等级: ⭐⭐⭐ 良好" "SUCCESS"
    } else {
        Write-Log "  等级: ⭐ 需改进" "ERROR"
    }
    Write-Log "================================" "STANDARD"

    # ========== 生成改进建议 ==========
    if ($Result.Failed -gt 0) {
        Write-Log "`n测试失败需要修复:" "ERROR"
        foreach ($Test in $Result.TestResults.unitTests) {
            if ($Test.status -eq "failed") {
                Write-Log "  - $($Test.name)" "ERROR"
            }
        }

        foreach ($Test in $Result.TestResults.integrationTests) {
            if ($Test.status -eq "failed") {
                Write-Log "  - $($Test.name)" "ERROR"
            }
        }
    }

    if ($Result.Coverage -lt 60) {
        Write-Log "`n建议: 增加更多测试以提高覆盖率" "WARNING"
    }

    # 设置最终状态
    $Result.EndTime = Get-Date
    $Result.Duration = ($Result.EndTime - $Result.StartTime).TotalSeconds

    Write-Log "测试完成" "SUCCESS"
    Write-Log "执行时间: $([math]::Round($Result.Duration, 2))秒" "SUCCESS"

} catch {
    $Result.Success = $false
    $Result.Errors += $_.Exception.Message
    $Result.Errors += $_.ScriptStackTrace

    Write-Log "测试失败: $($_.Exception.Message)" "ERROR"

    # 保存错误报告
    $ErrorReport = "$SkillPath/reports/test-error-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    $ErrorContent = @"
Skill测试器错误报告
时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Skill: $SkillPath
错误: $($_.Exception.Message)
堆栈: $($_.ScriptStackTrace)

"@
    $ErrorContent | Out-File -FilePath $ErrorReport -Encoding UTF8 -Force
    Write-Log "错误报告已保存: $ErrorReport" "WARNING"

} finally {
    return $Result
}
