# Performance Benchmark - 性能基准测试
# 对比优化前后的性能指标

param(
    [Parameter(Mandatory=$false)]
    [string]$Action = "test",
    [Parameter(Mandatory=$false)]
    [string]$BaselineFile = "benchmarks/baseline-results.json",
    [Parameter(Mandatory=$false)]
    [string]$AfterFile = "benchmarks/after-optimization.json"
)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$benchmarkPath = Join-Path $scriptPath "..\benchmarks"
$dataPath = Join-Path $scriptPath "..\data"

# Ensure benchmark directory exists
if (-not (Test-Path $benchmarkPath)) {
    New-Item -ItemType Directory -Path $benchmarkPath -Force | Out-Null
}

# Benchmark configurations
$Benchmarks = @{
    startup = @{
        name = "Startup Time"
        iterations = 10
        operation = {
            $start = [System.Diagnostics.Stopwatch]::StartNew()
            # Simulate startup
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
            $start.Stop()
            return $start.ElapsedMilliseconds
        }
    }
    memoryAllocation = @{
        name = "Memory Allocation"
        iterations = 10000
        operation = {
            [System.Text.StringBuilder]::new(100).Append("test")
            return 0
        }
    }
    stringConcatenation = @{
        name = "String Concatenation"
        iterations = 10000
        operation = {
            $result = ""
            for ($i = 0; $i -lt 10; $i++) {
                $result += "test"
            }
            return 0
        }
    }
    arrayAccess = @{
        name = "Array Access"
        iterations = 100000
        operation = {
            $array = 1..1000
            $sum = 0
            for ($i = 0; $i -lt 1000; $i++) {
                $sum += $array[$i]
            }
            return $sum
        }
    }
    objectCreation = @{
        name = "Object Creation"
        iterations = 10000
        operation = {
            $obj = [PSCustomObject]@{
                Property1 = "Value1"
                Property2 = "Value2"
                Property3 = "Value3"
            }
            return $null
        }
    }
    concurrentTasks = @{
        name = "Concurrent Task Execution"
        iterations = 100
        operation = {
            param($delay)
            Start-Sleep -Milliseconds $delay
            return $delay
        }
    }
}

# Run single benchmark
function Run-Benchmark {
    param(
        [Parameter(Mandatory=$true)]
        [string]$BenchmarkKey,
        [Parameter(Mandatory=$false)]
        [hashtable]$Config = $null
    )

    if ($null -eq $Config) {
        $Config = $Benchmarks[$BenchmarkKey]
    }

    if ($null -eq $Config) {
        Write-Host "Benchmark not found: $BenchmarkKey" -ForegroundColor Red
        return $null
    }

    $name = $Config.name
    $iterations = $Config.iterations

    Write-Host "`nRunning: $name" -ForegroundColor Yellow
    Write-Host "Iterations: $iterations" -ForegroundColor Gray

    # Warmup
    for ($i = 0; $i -lt 10; $i++) {
        & $Config.operation @Config.parameters
    }

    # Actual test
    $times = @()
    for ($i = 0; $i -lt $iterations; $i++) {
        $start = [System.Diagnostics.Stopwatch]::StartNew()
        & $Config.operation @Config.parameters
        $start.Stop()
        $times += $start.ElapsedMilliseconds
    }

    # Calculate statistics
    $total = $times | Measure-Object -Sum
    $average = [math]::Round($total.Sum / $iterations, 2)
    $min = $times | Measure-Object -Minimum
    $max = $times | Measure-Object -Maximum
    $stdDev = [math]::Round((Invoke-Expression "(foreach (\$t in \$times) { (\$t - \$average) * (\$t - \$average) }) | Measure-Object -Sum").Sum / $iterations, 2)
    $median = [math]::Round(($times | Sort-Object)[[Math]::Floor($iterations / 2)], 2)

    $result = @{
        benchmark = $name
        iterations = $iterations
        total = [math]::Round($total.Sum, 2)
        average = $average
        min = $min.Minimum
        $max = $max.Maximum
        median = $median
        stdDev = $stdDev
        times = $times
    }

    Write-Host "  Total: $($result.total) ms" -ForegroundColor Gray
    Write-Host "  Average: $($result.average) ms" -ForegroundColor Green
    Write-Host "  Min: $($result.min) ms" -ForegroundColor Gray
    Write-Host "  Max: $($result.max) ms" -ForegroundColor Gray
    Write-Host "  Median: $($result.median) ms" -ForegroundColor Gray
    Write-Host "  StdDev: $($result.stdDev) ms" -ForegroundColor Gray

    return $result
}

# Compare two benchmark results
function Compare-Results {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Before,
        [Parameter(Mandatory=$true)]
        [hashtable]$After
    )

    Write-Host "`n=== Performance Comparison ===" -ForegroundColor Cyan

    $comparisons = @()

    foreach ($key in $Before.Keys) {
        if ($After.ContainsKey($key)) {
            $beforeTime = $Before[$key].average
            $afterTime = $After[$key].average

            $improvement = [math]::Round(($beforeTime - $afterTime) / $beforeTime * 100, 2)
            $status = if ($improvement -gt 0) { "Improved" } else { "Worse" }

            $comparison = @{
                metric = $key
                before = $beforeTime
                after = $afterTime
                improvement = $improvement
                status = $status
            }

            $comparisons += $comparison

            $statusColor = if ($improvement -gt 10) { "Green" } elseif ($improvement -gt 0) { "Yellow" } else { "Red" }
            Write-Host "$($comparison.metric):" -ForegroundColor Yellow
            Write-Host "  Before: $($comparison.before) ms" -ForegroundColor $(if ($statusColor -eq "Green") { "Gray" } else { "Red" }))
            Write-Host "  After: $($comparison.after) ms" -ForegroundColor $(if ($statusColor -eq "Green") { "Green" } else { "Gray" }))
            Write-Host "  Improvement: $([math]::Round($comparison.improvement, 2))%" -ForegroundColor $statusColor
        }
    }

    return $comparisons
}

# Generate optimization report
function Generate-Report {
    param(
        [Parameter(Mandatory=$false)]
        [string]$BeforeFile = $BaselineFile,
        [Parameter(Mandatory=$false)]
        [string]$AfterFile = $AfterFile
    )

    if (-not (Test-Path $BeforeFile)) {
        Write-Host "Baseline file not found: $BeforeFile" -ForegroundColor Red
        Write-Host "Run 'benchmark -Action baseline' first" -ForegroundColor Yellow
        return
    }

    if (-not (Test-Path $AfterFile)) {
        Write-Host "After file not found: $AfterFile" -ForegroundColor Red
        Write-Host "Run 'benchmark -Action benchmark' first" -ForegroundColor Yellow
        return
    }

    Write-Host "Generating optimization report..." -ForegroundColor Yellow

    $beforeData = Get-Content -Path $BeforeFile -Raw -Encoding utf8 | ConvertFrom-Json
    $afterData = Get-Content -Path $AfterFile -Raw -Encoding utf8 | ConvertFrom-Json

    $report = @{
        timestamp = (Get-Date).ToUnixTimeSeconds()
        before = $beforeData
        after = $afterData
        comparison = Compare-Results -Before $beforeData -After $afterData
        overall = @{
            averageImprovement = 0
            metricsImproved = 0
            metricsWorse = 0
        }
    }

    # Calculate overall improvement
    $totalImprovement = 0
    $improvedCount = 0
    $worseCount = 0

    foreach ($comp in $report.comparison) {
        if ($comp.improvement -gt 0) {
            $totalImprovement += $comp.improvement
            $improvedCount++
        } else {
            $worseCount++
        }
    }

    $report.overall.averageImprovement = [math]::Round($totalImprovement / $report.comparison.Count, 2)
    $report.overall.metricsImproved = $improvedCount
    $report.overall.metricsWorse = $worseCount

    # Save report
    $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $AfterFile -Encoding utf8

    Write-Host "`n=== Optimization Report ===" -ForegroundColor Cyan
    Write-Host "Report saved to: $AfterFile" -ForegroundColor Green

    Write-Host "`nOverall Results:" -ForegroundColor Yellow
    Write-Host "  Average Improvement: $($report.overall.averageImprovement)%" -ForegroundColor $(if ($report.overall.averageImprovement -gt 0) { "Green" } else { "Red" }))
    Write-Host "  Metrics Improved: $($report.overall.metricsImproved)" -ForegroundColor Green
    Write-Host "  Metrics Worse: $($report.overall.metricsWorse)" -ForegroundColor Red

    if ($report.overall.averageImprovement -gt 20) {
        Write-Host "`n✅ Performance optimization successful!" -ForegroundColor Green
    } elseif ($report.overall.averageImprovement -gt 0) {
        Write-Host "`n⚠️  Performance improved, but further optimization possible" -ForegroundColor Yellow
    } else {
        Write-Host "`n❌ Performance did not improve significantly" -ForegroundColor Red
    }

    return $report
}

# Generate baseline
function Generate-Baseline {
    param(
        [Parameter(Mandatory=$false)]
        [hashtable]$BenchmarksToRun = $null
    )

    Write-Host "Generating performance baseline..." -ForegroundColor Yellow

    if ($null -eq $BenchmarksToRun) {
        $BenchmarksToRun = $Benchmarks.Keys
    }

    $baseline = @{}

    foreach ($key in $BenchmarksToRun) {
        if ($Benchmarks.ContainsKey($key)) {
            $result = Run-Benchmark -BenchmarkKey $key
            $baseline[$key] = $result
        }
    }

    # Save baseline
    $baseline | ConvertTo-Json -Depth 10 | Out-File -FilePath $BaselineFile -Encoding utf8

    Write-Host "`nBaseline saved to: $BaselineFile" -ForegroundColor Green
    Write-Host "Run 'benchmark -Action benchmark' to compare" -ForegroundColor Yellow

    return $baseline
}

# Action handlers
switch ($Action) {
    "test" {
        Write-Host "`n=== Performance Benchmark Test ===" -ForegroundColor Cyan

        # Run individual benchmarks
        foreach ($key in $Benchmarks.Keys) {
            Run-Benchmark -BenchmarkKey $key
        }

        Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
    }

    "benchmark" {
        Write-Host "`n=== Running All Benchmarks ===" -ForegroundColor Cyan

        $results = @{}
        foreach ($key in $Benchmarks.Keys) {
            $result = Run-Benchmark -BenchmarkKey $key
            $results[$key] = $result
        }

        $results | ConvertTo-Json -Depth 10 | Out-File -FilePath $AfterFile -Encoding utf8

        Write-Host "`nResults saved to: $AfterFile" -ForegroundColor Green
    }

    "baseline" {
        Generate-Baseline
    }

    "report" {
        Generate-Report
    }

    "help" {
        Write-Host "`n使用方法:" -ForegroundColor Yellow
        Write-Host "  test - 运行测试"
        Write-Host "  benchmark - 运行基准测试"
        Write-Host "  baseline - 生成基准"
        Write-Host "  report - 生成优化报告"
        Write-Host "  help - 显示帮助"
    }

    "default" {
        Write-Host "使用方法: performance-benchmark.ps1 -Action <action>" -ForegroundColor Yellow
        Write-Host "`n可用操作:" -ForegroundColor Cyan
        Write-Host "  test - 测试性能"
        Write-Host "  benchmark - 运行基准测试"
        Write-Host "  baseline - 生成基准"
        Write-Host "  report - 生成报告"
        Write-Host "  help - 显示帮助"
    }
}
