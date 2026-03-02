# 第三周 Day 5 - 性能极致优化集成测试
# 第三周 Day 5 - Performance Optimization Integration Test
# 版本: 1.0.0
# 创建时间: 2026-02-11

<#
.SYNOPSIS
    Day 5 性能优化集成测试 - 测试所有性能优化工具

.DESCRIPTION
    对性能监控、内存优化、API优化、响应优化进行全面测试

.PARAMETER TestAll
    是否运行所有测试

.PARAMETER SpecificTest
    运行特定测试: All, Benchmark, Memory, API, Response

.EXAMPLE
    .\day5-integration-test.ps1 -SpecificTest All
#>

param(
    [switch]$TestAll,
    [Parameter(Mandatory=$false)]
    [ValidateSet('All', 'Benchmark', 'Memory', 'API', 'Response')]
    [string]$SpecificTest = 'All'
)

# 配置
$Config = @{
    TestResultsDir = "reports/day5-perf-tests"
    LogDir = "logs/performance"
}

# 创建测试结果目录
if (-not (Test-Path $Config.TestResultsDir)) {
    New-Item -ItemType Directory -Path $Config.TestResultsDir -Force | Out-Null
}

# 测试结果记录
$Day5TestResults = @{
    Tests = @{}
    StartTime = Get-Date
    Status = 'running'
}

# 日志函数
function Write-Day5Log {
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

# 测试1: 性能基准测试
function Test-Benchmark {
    Write-Day5Log "测试1: 性能基准测试" -Status 'INFO'

    $testName = 'benchmark-test'
    $result = @{
        Test = $testName
        Status = 'running'
        Details = @{}
    }

    try {
        # 运行性能监控（测试30秒）
        $output = powershell -ExecutionPolicy Bypass -File "scripts/performance/system-benchmark.ps1" -TestDuration 30 -TestType Memory -OutputFile "reports/day5-perf-tests/benchmark-report.md" 2>&1

        if ($LASTEXITCODE -eq 0) {
            $result.Status = 'PASS'
            $result.Details['Description'] = '性能基准测试完成'
            $result.Details['Output'] = $output
        }
        else {
            $result.Status = 'FAIL'
            $result.Details['Error'] = $output
        }
    }
    catch {
        $result.Status = 'FAIL'
        $result.Details['Error'] = $_.Exception.Message
    }

    $Day5TestResults.Tests[$testName] = $result
    Write-Day5Log "测试1: 性能基准测试 - $(if ($result.Status -eq 'PASS') { '✅ 通过' } else { '❌ 失败' })" -Status $result.Status

    return $result.Status -eq 'PASS'
}

# 测试2: 内存优化测试
function Test-Memory {
    Write-Day5Log "测试2: 内存优化测试" -Status 'INFO'

    $testName = 'memory-test'
    $result = @{
        Test = $testName
        Status = 'running'
        Details = @{}
    }

    try {
        # 运行内存优化器测试
        $output = powershell -ExecutionPolicy Bypass -File "scripts/performance/memory-optimizer.ps1" -Action Test -ScanType All 2>&1

        if ($LASTEXITCODE -eq 0) {
            $result.Status = 'PASS'
            $result.Details['Description'] = '内存优化测试完成'
            $result.Details['Output'] = $output
        }
        else {
            $result.Status = 'FAIL'
            $result.Details['Error'] = $output
        }
    }
    catch {
        $result.Status = 'FAIL'
        $result.Details['Error'] = $_.Exception.Message
    }

    $Day5TestResults.Tests[$testName] = $result
    Write-Day5Log "测试2: 内存优化测试 - $(if ($result.Status -eq 'PASS') { '✅ 通过' } else { '❌ 失败' })" -Status $result.Status

    return $result.Status -eq 'PASS'
}

# 测试3: API优化测试
function Test-API {
    Write-Day5Log "测试3: API优化测试" -Status 'INFO'

    $testName = 'api-test'
    $result = @{
        Test = $testName
        Status = 'running'
        Details = @{}
    }

    try {
        # 运行API优化器测试
        $output = powershell -ExecutionPolicy Bypass -File "scripts/performance/api-optimizer.ps1" -Action Optimize 2>&1

        if ($LASTEXITCODE -eq 0) {
            $result.Status = 'PASS'
            $result.Details['Description'] = 'API优化测试完成'
            $result.Details['Output'] = $output
        }
        else {
            $result.Status = 'FAIL'
            $result.Details['Error'] = $output
        }
    }
    catch {
        $result.Status = 'FAIL'
        $result.Details['Error'] = $_.Exception.Message
    }

    $Day5TestResults.Tests[$testName] = $result
    Write-Day5Log "测试3: API优化测试 - $(if ($result.Status -eq 'PASS') { '✅ 通过' } else { '❌ 失败' })" -Status $result.Status

    return $result.Status -eq 'PASS'
}

# 测试4: 响应优化测试
function Test-Response {
    Write-Day5Log "测试4: 响应优化测试" -Status 'INFO'

    $testName = 'response-test'
    $result = @{
        Test = $testName
        Status = 'running'
        Details = @{}
    }

    try {
        # 运行响应优化器测试
        $output = powershell -ExecutionPolicy Bypass -File "scripts/performance/response-optimizer.ps1" -Action Optimize 2>&1

        if ($LASTEXITCODE -eq 0) {
            $result.Status = 'PASS'
            $result.Details['Description'] = '响应优化测试完成'
            $result.Details['Output'] = $output
        }
        else {
            $result.Status = 'FAIL'
            $result.Details['Error'] = $output
        }
    }
    catch {
        $result.Status = 'FAIL'
        $result.Details['Error'] = $_.Exception.Message
    }

    $Day5TestResults.Tests[$testName] = $result
    Write-Day5Log "测试4: 响应优化测试 - $(if ($result.Status -eq 'PASS') { '✅ 通过' } else { '❌ 失败' })" -Status $result.Status

    return $result.Status -eq 'PASS'
}

# 生成测试报告
function Generate-Day5Report {
    Write-Day5Log "生成Day 5测试报告" -Status 'INFO'

    $endTime = Get-Date
    $duration = ($endTime - $Day5TestResults.StartTime).TotalSeconds

    $Report = @"
# 第三周 Day 5 - 性能极致优化测试报告
**生成时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**测试时长**: $duration 秒

---

## 📊 测试概览
**总测试数**: $($Day5TestResults.Tests.Count)
**通过数**: $($Day5TestResults.Tests.Values | Where-Object { $_.Status -eq 'PASS' } | Measure-Object).Count
**失败数**: $($Day5TestResults.Tests.Values | Where-Object { $_.Status -eq 'FAIL' } | Measure-Object).Count
**成功率**: $([math]::Round(($Day5TestResults.Tests.Values | Where-Object { $_.Status -eq 'PASS' } | Measure-Object).Count / $Day5TestResults.Tests.Count * 100, 2))%

---

## 📋 测试详情

"@

    foreach ($test in $Day5TestResults.Tests.Values) {
        $Report += @"
### $($test.Test)
**状态**: $(if ($test.Status -eq 'PASS') { '✅ 通过' } else { '❌ 失败' })
**描述**: $($test.Details['Description'] ?? '无')

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

    $passed = $Day5TestResults.Tests.Values | Where-Object { $_.Status -eq 'PASS' }
    $failed = $Day5TestResults.Tests.Values | Where-Object { $_.Status -eq 'FAIL' }

    if ($failed.Count -eq 0) {
        $Report += "🎉 所有性能优化测试通过！系统性能达到极致优化状态。"
    }
    else {
        $Report += "⚠️ 有 $($failed.Count) 个测试失败，需要关注和修复。"
    }

    # 保存报告
    $ReportPath = Join-Path $Config.TestResultsDir "day5-perf-test-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
    $Report | Out-File -FilePath $ReportPath -Encoding UTF8 -Force

    Write-Host "`n📊 测试报告已生成: $ReportPath" -ForegroundColor Cyan
    Write-Host $Report
}

# 主程序
function Main {
    Write-Host "`n==========================================" -ForegroundColor Cyan
    Write-Host "第三周 Day 5 - 性能极致优化测试" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""

    $passedTests = 0
    $totalTests = 0

    if ($SpecificTest -eq 'All' -or $SpecificTest -eq 'Benchmark') {
        $totalTests++
        if (Test-Benchmark) { $passedTests++ }
    }

    if ($SpecificTest -eq 'All' -or $SpecificTest -eq 'Memory') {
        $totalTests++
        if (Test-Memory) { $passedTests++ }
    }

    if ($SpecificTest -eq 'All' -or $SpecificTest -eq 'API') {
        $totalTests++
        if (Test-API) { $passedTests++ }
    }

    if ($SpecificTest -eq 'All' -or $SpecificTest -eq 'Response') {
        $totalTests++
        if (Test-Response) { $passedTests++ }
    }

    Generate-Day5Report

    Write-Host "`n==========================================" -ForegroundColor Cyan
    Write-Host "测试完成！" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
}

Main
