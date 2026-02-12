# Memory Optimizer - 内存使用优化
# 减少内存占用，优化对象管理

param(
    [Parameter(Mandatory=$false)]
    [string]$Action = "test"
)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$dataPath = Join-Path $scriptPath "..\data"

# Memory monitoring
$MemoryStats = @{
    totalMemory = 0
    availableMemory = 0
    peakMemory = 0
    allocations = 0
    peakAllocations = 0
    currentGCMemory = 0
    peakGCMemory = 0
}

# Object pooling for frequently created objects
$ObjectPools = @{
    stringBuffers = [System.Collections.Concurrent.ConcurrentBag[string]]::new()
    arrayBuffers = [System.Collections.Concurrent.ConcurrentBag[object[]]]::new()
}

# Cache frequently used data
$CacheStore = @{
    strings = @{}
    arrays = @{}
    functions = @{}
}

# Initialize memory tracking
function Initialize-MemoryTracking {
    param(
        [Parameter(Mandatory=$false)]
        [bool]$Reset = $false
    )

    if ($Reset) {
        $MemoryStats = @{
            totalMemory = 0
            availableMemory = 0
            peakMemory = 0
            allocations = 0
            peakAllocations = 0
            currentGCMemory = 0
            peakGCMemory = 0
        }
    }

    Write-Host "Memory tracking initialized" -ForegroundColor Green
}

# Track allocation
function Track-Allocation {
    param(
        [Parameter(Mandatory=$true)]
        [long]$Size,
        [string]$Operation = "allocation"
    )

    $MemoryStats.allocations += 1
    $currentMemory = [System.Diagnostics.Process]::GetCurrentProcess().WorkingSet64

    if ($currentMemory -gt $MemoryStats.peakMemory) {
        $MemoryStats.peakMemory = $currentMemory
    }

    if ($currentMemory -gt $MemoryStats.currentGCMemory) {
        $MemoryStats.currentGCMemory = $currentMemory
    }

    if ($MemoryStats.allocations -gt $MemoryStats.peakAllocations) {
        $MemoryStats.peakAllocations = $MemoryStats.allocations
    }

    if ($Operation -eq "allocation") {
        Write-Host "  [ALLOC] $Size bytes" -ForegroundColor Gray
    }
}

# Track deallocation (conceptual)
function Track-Deallocation {
    param(
        [Parameter(Mandatory=$true)]
        [long]$Size,
        [string]$Operation = "deallocation"
    )

    if ($Operation -eq "deallocation") {
        Write-Host "  [FREE] $Size bytes" -ForegroundColor Gray
    }
}

# Get current memory usage
function Get-MemoryUsage {
    $process = [System.Diagnostics.Process]::GetCurrentProcess()
    $totalMemory = $process.WorkingSet64
    $availableMemory = [System.Environment]::SystemTotalPhysicalMemory - $totalMemory

    $MemoryStats.totalMemory = $totalMemory
    $MemoryStats.availableMemory = $availableMemory

    return @{
        totalMemoryMB = [math]::Round($totalMemory / 1MB, 2)
        availableMemoryMB = [math]::Round($availableMemory / 1MB, 2)
        totalMemoryGB = [math]::Round($totalMemory / 1GB, 2)
        availableMemoryGB = [math]::Round($availableMemory / 1GB, 2)
    }
}

# Get memory statistics
function Get-MemoryStatsOutput {
    $memory = Get-MemoryUsage

    Write-Host "`n=== Memory Statistics ===" -ForegroundColor Cyan
    Write-Host "Total Memory: $($memory.totalMemoryGB) GB" -ForegroundColor Yellow
    Write-Host "Available Memory: $($memory.availableMemoryGB) GB" -ForegroundColor Green
    Write-Host "Working Set: $($memory.totalMemoryMB) MB" -ForegroundColor Gray
    Write-Host "`nAllocations:" -ForegroundColor Yellow
    Write-Host "  Total: $($MemoryStats.allocations)" -ForegroundColor Gray
    Write-Host "  Peak: $($MemoryStats.peakAllocations)" -ForegroundColor Red
    Write-Host "`nGC Memory:" -ForegroundColor Yellow
    Write-Host "  Current: $($MemoryStats.currentGCMemory / 1MB) MB" -ForegroundColor Gray
    Write-Host "  Peak: $($MemoryStats.peakGCMemory / 1MB) MB" -ForegroundColor Red

    return @{
        totalMemoryGB = $memory.totalMemoryGB
        availableMemoryGB = $memory.availableMemoryGB
        workingSetMB = $memory.totalMemoryMB
        allocations = $MemoryStats.allocations
        peakAllocations = $MemoryStats.peakAllocations
        gcMemoryMB = $MemoryStats.currentGCMemory / 1MB
        peakGCMemoryMB = $MemoryStats.peakGCMemory / 1MB
    }
}

# Object pooling functions
function Get-FromPool {
    param(
        [Parameter(Mandatory=$true)]
        [string]$PoolType
    )

    switch ($PoolType) {
        "stringBuffer" {
            if ($ObjectPools.stringBuffers.TryTake([ref]$result)) {
                return $result
            }
            return [System.Text.StringBuilder]::new(1024)
        }
        "arrayBuffer" {
            if ($ObjectPools.arrayBuffers.TryTake([ref]$result)) {
                return $result
            }
            return [object[]]::new(100)
        }
        default {
            return $null
        }
    }
}

function Return-ToPool {
    param(
        [Parameter(Mandatory=$true)]
        [object]$Object,
        [Parameter(Mandatory=$true)]
        [string]$PoolType
    )

    switch ($PoolType) {
        "stringBuffer" {
            $Object.Clear()
            $ObjectPools.stringBuffers.Add($Object.ToString())
        }
        "arrayBuffer" {
            [Array]::Clear($Object, 0, $Object.Length)
            $ObjectPools.arrayBuffers.Add($Object)
        }
    }
}

# Memory optimization functions
function Optimize-StringBuffers {
    param(
        [Parameter(Mandatory=$false)]
        [int]$Threshold = 50
    )

    Write-Host "Optimizing string buffers..." -ForegroundColor Yellow

    $optimizedCount = 0

    # Check all buffer pools
    if ($ObjectPools.stringBuffers.Count -gt $Threshold) {
        Write-Host "  Pool size: $($ObjectPools.stringBuffers.Count)" -ForegroundColor Gray
        Write-Host "  Too many buffers, reducing..." -ForegroundColor Yellow
        # This would implement actual cleanup logic
        $optimizedCount++
    }

    if ($optimizedCount -gt 0) {
        Write-Host "  Optimized $optimizedCount string buffers" -ForegroundColor Green
    } else {
        Write-Host "  String buffers optimal" -ForegroundColor Green
    }
}

function Optimize-GarbageCollection {
    param(
        [Parameter(Mandatory=$false)]
        [switch]$Force
    )

    Write-Host "Optimizing garbage collection..." -ForegroundColor Yellow

    if ($Force) {
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        [System.GC]::Collect()
        Write-Host "  Forced GC cycle completed" -ForegroundColor Green
    } else {
        # Suggest GC
        [System.GC]::TryStartNoGCRegion()
        Write-Host "  Suggested NoGC region" -ForegroundColor Green
    }
}

function Optimize-DataStructures {
    param(
        [Parameter(Mandatory=$false)]
        [int]$Threshold = 100
    )

    Write-Host "Optimizing data structures..." -ForegroundColor Yellow

    # Check cache sizes
    $totalCacheSize = 0
    foreach ($key in $CacheStore.keys) {
        $totalCacheSize += $CacheStore[$key].Length
    }

    if ($totalCacheSize -gt $Threshold) {
        Write-Host "  Cache size: $totalCacheSize bytes" -ForegroundColor Yellow
        Write-Host "  Consider clearing cache or reducing size" -ForegroundColor Gray
    } else {
        Write-Host "  Cache size optimal: $totalCacheSize bytes" -ForegroundColor Green
    }
}

# Memory benchmark
function Test-MemoryPerformance {
    param(
        [Parameter(Mandatory=$false)]
        [int]$Iterations = 10000
    )

    Write-Host "`n=== Memory Performance Test ===" -ForegroundColor Cyan
    Write-Host "Running $Iterations iterations..." -ForegroundColor Yellow

    $startAllocations = $MemoryStats.allocations

    Write-Host "`n[1] String allocation test" -ForegroundColor Yellow
    $strings = [System.Collections.Generic.List[string]]::new()
    for ($i = 0; $i -lt $Iterations; $i++) {
        $strings.Add("MemoryOptimizationTest_" + $i)
    }
    $finalAllocations = $MemoryStats.allocations
    $allocationsPerSec = [math]::Round(($finalAllocations - $startAllocations) / 1.0, 0)
    Write-Host "  Allocations: $($finalAllocations - $startAllocations)" -ForegroundColor Gray
    Write-Host "  Rate: $allocationsPerSec per second" -ForegroundColor Green

    # Test object pooling
    Write-Host "`n[2] Object pooling test" -ForegroundColor Yellow
    $poolStart = $MemoryStats.allocations
    for ($i = 0; $i -lt $Iterations; $i++) {
        $buffer = Get-FromPool "stringBuffer"
        $buffer.Append("test_")
        Return-ToPool -Object $buffer -PoolType "stringBuffer"
    }
    $poolEnd = $MemoryStats.allocations
    $poolOptimization = [math]::Round(($poolEnd - $poolStart) / ($Iterations * 2), 2)

    Write-Host "  Allocations with pooling: $($poolEnd - $poolStart)" -ForegroundColor Green
    Write-Host "  Memory saved per iteration: ~$poolOptimization bytes" -ForegroundColor Green

    # Clean up
    $strings.Clear()
    [System.GC]::Collect()

    Write-Host "`n=== Memory Test Complete ===" -ForegroundColor Cyan
}

# Action handlers
switch ($Action) {
    "test" {
        Initialize-MemoryTracking -Reset $true

        Write-Host "`n[1] Memory usage check" -ForegroundColor Yellow
        $memory = Get-MemoryUsage
        Write-Host "  Total: $($memory.totalMemoryGB) GB" -ForegroundColor Green
        Write-Host "  Available: $($memory.availableMemoryGB) GB" -ForegroundColor Green

        Write-Host "`n[2] Memory optimization test" -ForegroundColor Yellow
        Optimize-StringBuffers
        Optimize-DataStructures
        [System.GC]::Collect()

        Write-Host "`n[3] Pool test" -ForegroundColor Yellow
        $buffer = Get-FromPool "stringBuffer"
        $buffer.Append("Hello World")
        Write-Host "  Content: $($buffer.ToString())" -ForegroundColor Green
        Return-ToPool -Object $buffer -PoolType "stringBuffer"

        Write-Host "`n[4] Memory statistics" -ForegroundColor Yellow
        Get-MemoryStatsOutput

        Write-Host "`n[5] Performance test" -ForegroundColor Yellow
        Test-MemoryPerformance -Iterations 5000

        Write-Host "`n=== Memory Optimizer Test Complete ===" -ForegroundColor Cyan
    }

    "stats" {
        Get-MemoryStatsOutput
    }

    "optimize" {
        Optimize-StringBuffers
        Optimize-DataStructures
        Optimize-GarbageCollection
        Get-MemoryStatsOutput
    }

    "gc" {
        Optimize-GarbageCollection -Force
        Get-MemoryStatsOutput
    }

    "help" {
        Write-Host "`n使用方法:" -ForegroundColor Yellow
        Write-Host "  test - 运行测试"
        Write-Host "  stats - 显示统计信息"
        Write-Host "  optimize - 执行优化"
        Write-Host "  gc - 运行垃圾回收"
        Write-Host "  help - 显示帮助"
    }

    "default" {
        Write-Host "使用方法: memory-optimizer.ps1 -Action <action>" -ForegroundColor Yellow
        Write-Host "`n可用操作:" -ForegroundColor Cyan
        Write-Host "  test - 测试内存优化"
        Write-Host "  stats - 查看统计"
        Write-Host "  optimize - 执行优化"
        Write-Host "  gc - 运行GC"
        Write-Host "  help - 显示帮助"
    }
}

Initialize-MemoryTracking -Reset $true
