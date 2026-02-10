# 灵眸性能基准测试套件
# 测量和监控系统性能指标

$HeartbeatStatePath = "heartbeat-state.json"
$ErrorDatabasePath = "error-database.json"

function Invoke-PerformanceBenchmark {
    param(
        [switch]$AllTests = $false,
        [switch]$Quick = $false
    )

    Write-Host "`n[PERF] Starting performance benchmark suite..." -ForegroundColor Cyan
    $startTime = Get-Date

    $results = @{}

    # 测试1: 基础性能测试
    Write-Host "`n[PERF] Test 1: Basic Performance" -ForegroundColor Cyan
    $results.basic = Invoke-BasicPerformanceTest -Quick:$Quick

    # 测试2: 内存性能
    Write-Host "`n[PERF] Test 2: Memory Performance" -ForegroundColor Cyan
    $results.memory = Invoke-MemoryPerformanceTest -Quick:$Quick

    # 测试3: 磁盘性能
    Write-Host "`n[PERF] Test 3: Disk Performance" -ForegroundColor Cyan
    $results.disk = Invoke-DiskPerformanceTest -Quick:$Quick

    # 测试4: 网络性能
    Write-Host "`n[PERF] Test 4: Network Performance" -ForegroundColor Cyan
    $results.network = Invoke-NetworkPerformanceTest -Quick:$Quick

    # 测试5: API响应时间
    Write-Host "`n[PERF] Test 5: API Response Time" -ForegroundColor Cyan
    $results.api = Invoke-APIResponseTest -Quick:$Quick

    # 如果请求，测试CPU性能
    if ($AllTests) {
        Write-Host "`n[PERF] Test 6: CPU Performance" -ForegroundColor Cyan
        $results.cpu = Invoke-CPUPerformanceTest
    }

    $elapsed = (Get-Date) - $startTime
    Write-Host "`n[PERF] Benchmark suite completed in $(Elapsed $elapsed)" -ForegroundColor Green

    # 保存基准测试结果
    $benchmarkReport = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        duration_ms = [math]::Round($elapsed.TotalMilliseconds, 0)
        results = $results
    }

    $reportPath = "performance-benchmark-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $benchmarkReport | ConvertTo-Json -Depth 10 | Set-Content $reportPath

    Write-Host "[PERF] Results saved to: $reportPath" -ForegroundColor Green

    return $benchmarkReport
}

function Invoke-BasicPerformanceTest {
    param([switch]$Quick = $false)

    $testIterations = if ($Quick) { 1000 } else { 10000 }

    Write-Host "[PERF]  Running $testIterations iterations..."

    $startTime = Get-Date

    # 执行测试循环
    $results = for ($i = 0; $i -lt $testIterations; $i++) {
        # 模拟工作负载
        $null = [System.Math]::Sqrt($i)
    }

    $elapsed = (Get-Date) - $startTime

    return @{
        iterations = $testIterations
        completed = $testIterations
        duration_ms = [math]::Round($elapsed.TotalMilliseconds, 0)
        iterations_per_second = [math]::Round($testIterations / $elapsed.TotalSeconds, 2)
        success = $true
    }
}

function Invoke-MemoryPerformanceTest {
    param([switch]$Quick = $false)

    $testIterations = if ($Quick) { 1000 } else { 10000 }

    Write-Host "[PERF]  Allocating $testIterations test objects..."

    # 测试内存分配
    $memoryBefore = [GC]::GetTotalMemory($true)
    $objects = @()

    $startTime = Get-Date
    for ($i = 0; $i -lt $testIterations; $i++) {
        $objects += [PSCustomObject]@{
            id = $i
            timestamp = Get-Date
            data = "test data $i"
        }
    }
    $elapsed = (Get-Date) - $startTime

    $memoryAfter = [GC]::GetTotalMemory($true)
    $memoryUsed = [math]::Round(($memoryAfter - $memoryBefore) / 1KB, 2)

    [GC]::Collect()

    $results = @{
        iterations = $testIterations
        duration_ms = [math]::Round($elapsed.TotalMilliseconds, 0)
        memory_used_kb = $memoryUsed
        objects_per_second = [math]::Round($testIterations / $elapsed.TotalSeconds, 2)
        success = $true
    }

    Write-Host "[PERF]  Memory test completed: $memoryUsed KB used"

    return $results
}

function Invoke-DiskPerformanceTest {
    param([switch]$Quick = $false)

    $testIterations = if ($Quick) { 100 } else { 1000 }
    $testFile = "$env:TEMP\performance-test-$(Get-Date -Format 'yyyyMMdd-HHmmss').tmp"

    Write-Host "[PERF]  Writing $testIterations test files..."

    $startTime = Get-Date
    for ($i = 0; $i -lt $testIterations; $i++) {
        "Test data $i - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')" | Out-File -FilePath $testFile -Append
    }
    $elapsed = (Get-Date) - $startTime

    # 清理测试文件
    if (Test-Path $testFile) {
        Remove-Item $testFile -Force
    }

    $results = @{
        iterations = $testIterations
        duration_ms = [math]::Round($elapsed.TotalMilliseconds, 0)
        iterations_per_second = [math]::Round($testIterations / $elapsed.TotalSeconds, 2)
        success = $true
    }

    Write-Host "[PERF]  Disk test completed: $($results.iterations_per_second) ops/sec"

    return $results
}

function Invoke-NetworkPerformanceTest {
    param([switch]$Quick = $false)

    Write-Host "[PERF]  Testing network latency..."

    $testTargets = @(
        @{name = "google.com"; url = "https://www.google.com"},
        @{name = "github.com"; url = "https://api.github.com"},
        @{name = "bing.com"; url = "https://www.bing.com"}
    )

    $results = @{}

    foreach ($target in $testTargets) {
        try {
            $startTime = Get-Date
            $null = Invoke-WebRequest -Uri $target.url -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
            $elapsed = (Get-Date) - $startTime
            $latency = [math]::Round($elapsed.TotalMilliseconds, 0)

            $results.$($target.name) = @{
                name = $target.name
                latency_ms = $latency
                success = $true
            }

            Write-Host "[PERF]  $($target.name): $latency ms"
        } catch {
            $results.$($target.name) = @{
                name = $target.name
                latency_ms = 0
                success = $false
                error = $_.Exception.Message
            }

            Write-Host "[PERF]  $($target.name): FAILED - $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    $avgLatency = [math]::Round(($results.values | Where-Object { $_.success }).latency_ms -average, 0)

    return @{
        test_targets = $results
        average_latency_ms = $avgLatency
        success = $results.values.Where({ $_.success }).Count -gt 0
    }
}

function Invoke-APIResponseTest {
    param([switch]$Quick = $false)

    Write-Host "[PERF]  Measuring API response times..."

    $testEndpoints = @(
        @{name = "GitHub", url = "https://api.github.com"},
        @{name = "Moltbook", url = "https://moltbook.com"}
    )

    $results = @{}
    $iterations = if ($Quick) { 5 } else { 20 }

    foreach ($endpoint in $testEndpoints) {
        $latencies = @()

        for ($i = 0; $i -lt $iterations; $i++) {
            try {
                $startTime = Get-Date
                $response = Invoke-WebRequest -Uri $endpoint.url -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
                $elapsed = (Get-Date) - $startTime
                $latencies += [math]::Round($elapsed.TotalMilliseconds, 0)
            } catch {
                $latencies += 0
            }
        }

        $results.$($endpoint.name) = @{
            name = $endpoint.name
            avg_latency_ms = [math]::Round(($latencies | Measure-Object -Average).Average, 0)
            min_latency_ms = [math]::Round(($latencies | Measure-Object -Minimum).Minimum, 0)
            max_latency_ms = [math]::Round(($latencies | Measure-Object -Maximum).Maximum, 0)
            success = $latencies -notcontains 0
        }

        Write-Host "[PERF]  $($endpoint.name): Avg $([math]::Round(($latencies | Measure-Object -Average).Average, 0))ms, Min $($latencies | Measure-Object -Minimum).Minimum ms, Max $($latencies | Measure-Object -Maximum).Maximum ms"
    }

    return @{
        endpoints = $results
        all_success = $results.values.Where({ $_.success }).Count -eq $results.Count
    }
}

function Invoke-CPUPerformanceTest {
    $testDurationSeconds = 5
    $startTime = Get-Date

    Write-Host "[PERF]  Running CPU stress test for $testDurationSeconds seconds..."

    $iterations = 0
    $startTime = Get-Date

    while ((Get-Date) - $startTime -lt [TimeSpan]::FromSeconds($testDurationSeconds)) {
        $iterations++
        # 模拟CPU工作
        $result = 1
        for ($i = 0; $i -lt 1000; $i++) {
            $result = [System.Math]::Sin([double]$result) * [System.Math]::Cos([double]$result)
        }
    }

    $elapsed = (Get-Date) - $startTime

    $results = @{
        duration_seconds = $testDurationSeconds
        iterations_per_second = [math]::Round($iterations / $elapsed.TotalSeconds, 0)
        cpu_usage = (Get-WmiObject Win32_Processor).LoadPercentage
        success = $true
    }

    Write-Host "[PERF]  CPU test completed: $iterations iterations in $([math]::Round($elapsed.TotalSeconds, 2)) seconds ($($results.iterations_per_second) iterations/sec)"

    return $results
}

function Get-PerformanceReport {
    param(
        [switch]$IncludeHistory = $false
    )

    $heartbeatState = Get-Content $HeartbeatStatePath -Raw | ConvertFrom-Json
    $errorDatabase = Get-Content $ErrorDatabasePath -Raw | ConvertFrom-Json

    $report = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        overall_health = $heartbeatState.current_status.overall
        performance = $heartbeatState.performance_metrics
        error_stats = @{
            total_errors = $errorDatabase.stats.total_errors
            recovered_errors = $errorDatabase.stats.recovered_errors
            recovery_rate = $errorDatabase.stats.rate
        }
        recent_activity = @($heartbeatState.check_history[-5..-1])
    }

    if ($IncludeHistory) {
        $report.check_history = @($heartbeatState.check_history)
    }

    return $report
}

function Export-PerformanceHistory {
    param(
        [string]$OutputPath = "performance-history.csv"
    )

    $heartbeatState = Get-Content $HeartbeatStatePath -Raw | ConvertFrom-Json

    $history = @($heartbeatState.check_history) | ForEach-Object {
        $issuesCount = if ($_.issues) { $_.issues.Count } else { 0 }
        @{
            timestamp = $_.timestamp
            overall_status = $_.overall_status
            gateway_healthy = if ($_.checks.gateway) { $_.checks.gateway.healthy } else { $false }
            memory_usage_pct = if ($_.checks.memory) { $_.checks.memory.usage_pct } else { 0 }
            disk_usage_pct = if ($_.checks.disk) { $_.checks.disk.usage_pct } else { 0 }
            network_connected = if ($_.checks.network) { $_.checks.network.connected } else { $false }
            api_healthy = if ($_.checks.api) { $_.checks.api.healthy } else { $false }
            issues_count = $issuesCount
        }
    }

    # 导出CSV
    if ($history.Count -gt 0) {
        $history | Export-Csv -Path $OutputPath -NoTypeInformation
        Write-Host "[PERF] Performance history exported to: $OutputPath" -ForegroundColor Green
    } else {
        Write-Host "[PERF] No performance history available" -ForegroundColor Yellow
    }
}

# 导出函数供其他脚本调用
Export-ModuleMember -Function Invoke-PerformanceBenchmark, Get-PerformanceReport, Export-PerformanceHistory
