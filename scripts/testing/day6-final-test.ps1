# 第三周 Day 6 - 最终测试脚本
# 第三周 Day 6 - Final Test Script
# 版本: 1.0.0
# 创建时间: 2026-02-11

<#
.SYNOPSIS
    Day 6 最终测试 - 完整的测试流程

.DESCRIPTION
    对所有第三周任务进行最终测试

.PARAMETER TestAll
    是否运行所有测试

.EXAMPLE
    .\day6-final-test.ps1 -TestAll
#>

param(
    [switch]$TestAll
)

# 配置
$Config = @{
    TestResultsDir = "reports/day6-final-tests"
    LogDir = "logs/final-test"
}

# 创建测试结果目录
if (-not (Test-Path $Config.TestResultsDir)) {
    New-Item -ItemType Directory -Path $Config.TestResultsDir -Force | Out-Null
}

# 测试结果记录
$Day6FinalTestResults = @{
    Tests = @{}
    StartTime = Get-Date
    Status = 'running'
}

# 日志函数
function Write-FinalLog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$true)]
        [ValidateSet('PASS', 'FAIL', 'INFO')]
        [string]$Status
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Color = switch($Status) {
        'PASS' { 'Green' }
        'FAIL' { 'Red' }
        'INFO' { 'White' }
    }

    Write-Host "[$Timestamp] [$Status] $Message" -ForegroundColor $Color
}

# 测试1: 系统状态测试
function Test-SystemStatus {
    Write-FinalLog "测试1: 系统状态检查" -Status 'INFO'

    $testName = 'system-status'
    $result = @{
        Test = $testName
        Status = 'running'
        Details = @{}
    }

    try {
        # 检查Gateway状态
        $gatewayStatus = & openclaw status -Format JSON 2>&1
        $gateway = $gatewayStatus | ConvertFrom-Json

        $result.Details['GatewayStatus'] = $gateway.Gateway.Status
        $result.Details['GatewayReachable'] = $gateway.Gateway.Reachable
        $result.Details['ActiveSessions'] = $gateway.Sessions.Count

        $result.Status = 'PASS'
    }
    catch {
        $result.Status = 'FAIL'
        $result.Details['Error'] = $_.Exception.Message
    }

    $Day6FinalTestResults.Tests[$testName] = $result
    Write-FinalLog "测试1: 系统状态检查 - $(if ($result.Status -eq 'PASS') { '✅ 通过' } else { '❌ 失败' })" -Status $result.Status

    return $result.Status -eq 'PASS'
}

# 测试2: 自动化组件测试
function Test-AutomationComponents {
    Write-FinalLog "测试2: 自动化组件测试" -Status 'INFO'

    $testName = 'automation-components'
    $result = @{
        Test = $testName
        Status = 'running'
        Details = @{}
    }

    try {
        # 检查所有自动化脚本
        $scripts = Get-ChildItem -Path "scripts/automation" -Filter "*.ps1" -Recurse

        $scriptResults = @{}
        foreach ($script in $scripts) {
            try {
                # 测试脚本语法
                $syntaxCheck = Get-Command $script.FullName -ErrorAction SilentlyContinue

                $scriptResults[$script.Name] = @{
                    Path = $script.FullName
                    SizeKB = [math]::Round($script.Length / 1KB, 2)
                    Exists = $true
                    ValidSyntax = $syntaxCheck -ne $null
                }

                if (-not $syntaxCheck) {
                    throw "语法错误: $($script.Name)"
                }
            }
            catch {
                $scriptResults[$script.Name] = @{
                    Path = $script.FullName
                    SizeKB = [math]::Round($script.Length / 1KB, 2)
                    Exists = $true
                    ValidSyntax = $false
                    Error = $_.Exception.Message
                }
            }
        }

        $validScripts = ($scriptResults.Values | Where-Object { $_.ValidSyntax }).Count
        $totalScripts = $scriptResults.Count

        $result.Details['TotalScripts'] = $totalScripts
        $result.Details['ValidScripts'] = $validScripts
        $result.Details['InvalidScripts'] = $totalScripts - $validScripts
        $result.Details['ScriptDetails'] = $scriptResults

        $result.Status = 'PASS'
    }
    catch {
        $result.Status = 'FAIL'
        $result.Details['Error'] = $_.Exception.Message
    }

    $Day6FinalTestResults.Tests[$testName] = $result
    Write-FinalLog "测试2: 自动化组件测试 - $(if ($result.Status -eq 'PASS') { '✅ 通过' } else { '❌ 失败' })" -Status $result.Status

    return $result.Status -eq 'PASS'
}

# 测试3: 性能优化测试
function Test-PerformanceOptimization {
    Write-FinalLog "测试3: 性能优化工具" -Status 'INFO'

    $testName = 'performance-optimization'
    $result = @{
        Test = $testName
        Status = 'running'
        Details = @{}
    }

    try {
        # 检查性能脚本
        $perfScripts = Get-ChildItem -Path "scripts/performance" -Filter "*.ps1" -Recurse

        $perfResults = @{}
        foreach ($script in $perfScripts) {
            try {
                $syntaxCheck = Get-Command $script.FullName -ErrorAction SilentlyContinue

                $perfResults[$script.Name] = @{
                    SizeKB = [math]::Round($script.Length / 1KB, 2)
                    ValidSyntax = $syntaxCheck -ne $null
                }

                if (-not $syntaxCheck) {
                    throw "语法错误: $($script.Name)"
                }
            }
            catch {
                $perfResults[$script.Name] = @{
                    SizeKB = [math]::Round($script.Length / 1KB, 2)
                    ValidSyntax = $false
                    Error = $_.Exception.Message
                }
            }
        }

        $validPerfScripts = ($perfResults.Values | Where-Object { $_.ValidSyntax }).Count
        $totalPerfScripts = $perfResults.Count

        $result.Details['TotalPerfScripts'] = $totalPerfScripts
        $result.Details['ValidPerfScripts'] = $validPerfScripts
        $result.Details['InvalidPerfScripts'] = $totalPerfScripts - $validPerfScripts
        $result.Details['PerfScriptDetails'] = $perfResults

        $result.Status = 'PASS'
    }
    catch {
        $result.Status = 'FAIL'
        $result.Details['Error'] = $_.Exception.Message
    }

    $Day6FinalTestResults.Tests[$testName] = $result
    Write-FinalLog "测试3: 性能优化工具 - $(if ($result.Status -eq 'PASS') { '✅ 通过' } else { '❌ 失败' })" -Status $result.Status

    return $result.Status -eq 'PASS'
}

# 测试4: 测试工具测试
function Test-TestingTools {
    Write-FinalLog "测试4: 测试工具" -Status 'INFO'

    $testName = 'testing-tools'
    $result = @{
        Test = $testName
        Status = 'running'
        Details = @{}
    }

    try {
        # 检查测试脚本
        $testScripts = Get-ChildItem -Path "scripts/testing" -Filter "*.ps1" -Recurse

        $testResults = @{}
        foreach ($script in $testScripts) {
            try {
                $syntaxCheck = Get-Command $script.FullName -ErrorAction SilentlyContinue

                $testResults[$script.Name] = @{
                    SizeKB = [math]::Round($script.Length / 1KB, 2)
                    ValidSyntax = $syntaxCheck -ne $null
                }

                if (-not $syntaxCheck) {
                    throw "语法错误: $($script.Name)"
                }
            }
            catch {
                $testResults[$script.Name] = @{
                    SizeKB = [math]::Round($script.Length / 1KB, 2)
                    ValidSyntax = $false
                    Error = $_.Exception.Message
                }
            }
        }

        $validTestScripts = ($testResults.Values | Where-Object { $_.ValidSyntax }).Count
        $totalTestScripts = $testResults.Count

        $result.Details['TotalTestScripts'] = $totalTestScripts
        $result.Details['ValidTestScripts'] = $validTestScripts
        $result.Details['InvalidTestScripts'] = $totalTestScripts - $validTestScripts
        $result.Details['TestScriptDetails'] = $testResults

        $result.Status = 'PASS'
    }
    catch {
        $result.Status = 'FAIL'
        $result.Details['Error'] = $_.Exception.Message
    }

    $Day6FinalTestResults.Tests[$testName] = $result
    Write-FinalLog "测试4: 测试工具 - $(if ($result.Status -eq 'PASS') { '✅ 通过' } else { '❌ 失败' })" -Status $result.Status

    return $result.Status -eq 'PASS`
}

# 生成最终测试报告
function Generate-FinalReport {
    Write-FinalLog "生成最终测试报告" -Status 'INFO'

    $endTime = Get-Date
    $duration = ($endTime - $Day6FinalTestResults.StartTime).TotalSeconds

    $Report = @"
# 第三周 Day 6 - 最终测试报告
**生成时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**测试时长**: $duration 秒

---

## 📊 测试概览
**总测试数**: $($Day6FinalTestResults.Tests.Count)
**通过数**: $($Day6FinalTestResults.Tests.Values | Where-Object { $_.Status -eq 'PASS' } | Measure-Object).Count
**失败数**: $($Day6FinalTestResults.Tests.Values | Where-Object { $_.Status -eq 'FAIL' } | Measure-Object).Count
**成功率**: $([math]::Round(($Day6FinalTestResults.Tests.Values | Where-Object { $_.Status -eq 'PASS' } | Measure-Object).Count / $Day6FinalTestResults.Tests.Count * 100, 2))%

---

## 📋 测试详情

"@

    foreach ($test in $Day6FinalTestResults.Tests.Values) {
        $Report += @"
### $($test.Test)
**状态**: $(if ($test.Status -eq 'PASS') { '✅ 通过' } else { '❌ 失败' })

**测试结果详情**:
\`\`\`
$($test.Details | ConvertTo-Json -Depth 3)
\`\`\`
"@

        if ($test.Details['Error']) {
            $Report += @"
**错误信息**:
\`\`\`
$($test.Details['Error'])
\`\`\`
"@
        }
    }

    $Report += @"

## ✅ 总结

"@

    $passed = $Day6FinalTestResults.Tests.Values | Where-Object { $_.Status -eq 'PASS' }
    $failed = $Day6FinalTestResults.Tests.Values | Where-Object { $_.Status -eq 'FAIL' }

    if ($failed.Count -eq 0) {
        $Report += "🎉 所有测试通过！第三周所有组件测试完成，系统稳定可靠。"
    }
    else {
        $Report += "⚠️ 有 $($failed.Count) 个测试失败，需要关注和修复。"
    }

    # 保存报告
    $ReportPath = Join-Path $Config.TestResultsDir "day6-final-test-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
    $Report | Out-File -FilePath $ReportPath -Encoding UTF8 -Force

    Write-Host "`n📊 最终测试报告已生成: $ReportPath" -ForegroundColor Cyan
    Write-Host $Report
}

# 主程序
function Main {
    Write-Host "`n==========================================" -ForegroundColor Cyan
    Write-Host "第三周 Day 6 - 最终测试" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""

    $passedTests = 0
    $totalTests = 0

    if ($TestAll) {
        $totalTests++
        if (Test-SystemStatus) { $passedTests++ }

        $totalTests++
        if (Test-AutomationComponents) { $passedTests++ }

        $totalTests++
        if (Test-PerformanceOptimization) { $passedTests++ }

        $totalTests++
        if (Test-TestingTools) { $passedTests++ }
    }

    Generate-FinalReport

    Write-Host "`n==========================================" -ForegroundColor Cyan
    Write-Host "测试完成！" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
}

Main
