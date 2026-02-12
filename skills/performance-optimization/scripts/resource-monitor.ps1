# Resource Monitor - 资源占用监控
# 实时监控资源使用情况，识别性能瓶颈

param(
    [Parameter(Mandatory=$false)]
    [string]$Action = "test"
)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$dataPath = Join-Path $scriptPath "..\data"
$monitorFile = Join-Path $dataPath "resource-monitor.json"

# Resource tracking
$ResourceData = @{
    cpu = 0
    memory = 0
    diskRead = 0
    diskWrite = 0
    networkRx = 0
    networkTx = 0
    activeProcesses = 0
    maxCpu = 0
    maxMemory = 0
    measurements = @()
}

# Performance baseline
$Baseline = @{
    cpu = @{
        current = 0
        average = 0
        min = 0
        max = 0
        percentile_95 = 0
    }
    memory = @{
        current = 0
        average = 0
        min = 0
        max = 0
        percentile_95 = 0
    }
    disk = @{
        readSpeed = 0
        writeSpeed = 0
        readAvg = 0
        writeAvg = 0
    }
    network = @{
        rxSpeed = 0
        txSpeed = 0
        rxAvg = 0
        txAvg = 0
    }
}

# Initialize
function Initialize-ResourceMonitoring {
    Write-Host "Resource monitoring initialized" -ForegroundColor Green
}

# Measure current resources
function Measure-Resources {
    param(
        [Parameter(Mandatory=$false)]
        [hashtable]$ExtraData = @{}
    )

    $now = Get-Date

    # CPU usage
    $cpuUsage = (Get-Counter "\Processor(_Total)\% Processor Time").CounterSamples.CookedValue
    if ($cpuUsage -gt $ResourceData.maxCpu) {
        $ResourceData.maxCpu = $cpuUsage
    }

    # Memory usage
    $memoryUsage = [System.Diagnostics.Process]::GetCurrentProcess().WorkingSet64
    $memoryMB = [math]::Round($memoryUsage / 1MB, 2)
    if ($memoryMB -gt $ResourceData.maxMemory) {
        $ResourceData.maxMemory = $memoryMB
    }

    # Disk I/O
    $diskRead = (Get-Counter "\PhysicalDisk(_Total)\Disk Read Bytes/sec").CounterSamples.CookedValue
    $diskWrite = (Get-Counter "\PhysicalDisk(_Total)\Disk Write Bytes/sec").CounterSamples.CookedValue

    # Network I/O
    $networkRx = (Get-Counter "\Network Interface(*)\Bytes Received/sec").CounterSamples.CookedValue
    $networkTx = (Get-Counter "\Network Interface(*)\Bytes Sent/sec").CounterSamples.CookedValue

    # Active processes
    $activeProcesses = (Get-Process | Measure-Object).Count

    # Store measurement
    $measurement = @{
        timestamp = $now.ToUnixTimeSeconds()
        cpu = [math]::Round($cpuUsage, 2)
        memoryMB = $memoryMB
        memoryGB = [math]::Round($memoryMB / 1024, 2)
        diskRead = [math]::Round($diskRead / 1KB, 2)
        diskWrite = [math]::Round($diskWrite / 1KB, 2)
        networkRx = [math]::Round($networkRx / 1KB, 2)
        networkTx = [math]::Round($networkTx / 1KB, 2)
        activeProcesses = $activeProcesses
    }

    $ResourceData.measurements += $measurement

    # Store extra data
    foreach ($key in $ExtraData.Keys) {
        $measurement.$key = $ExtraData[$key]
    }

    # Update summary
    $ResourceData.cpu = $cpuUsage
    $ResourceData.memory = $memoryMB

    return $measurement
}

# Calculate baselines
function Calculate-Baselines {
    param(
        [Parameter(Mandatory=$false)]
        [int]$DurationSec = 10
    )

    Write-Host "Calculating performance baselines for $DurationSec seconds..." -ForegroundColor Yellow

    $measurements = @()
    $end = (Get-Date).AddSeconds($DurationSec)

    while ((Get-Date) -lt $end) {
        $measurement = Measure-Resources
        $measurements += $measurement
        Start-Sleep -Milliseconds 1000
    }

    # Calculate baselines
    $cpuValues = $measurements | ForEach-Object { $_.cpu }
    $memoryValues = $measurements | ForEach-Object { $_.memoryMB }

    $Baseline.cpu.current = $cpuValues[-1]
    $Baseline.cpu.average = [math]::Round(($cpuValues | Measure-Object -Average).Average, 2)
    $Baseline.cpu.min = [math]::Round(($cpuValues | Measure-Object -Minimum).Minimum, 2)
    $Baseline.cpu.max = [math]::Round(($cpuValues | Measure-Object -Maximum).Maximum, 2)
    $Baseline.cpu.percentile_95 = [math]::Round(($cpuValues | Sort-Object)[([math]::Floor($cpuValues.Count * 0.95))], 2)

    $Baseline.memory.current = $memoryValues[-1]
    $Baseline.memory.average = [math]::Round(($memoryValues | Measure-Object -Average).Average, 2)
    $Baseline.memory.min = [math]::Round(($memoryValues | Measure-Object -Minimum).Minimum, 2)
    $Baseline.memory.max = [math]::Round(($memoryValues | Measure-Object -Maximum).Maximum, 2)
    $Baseline.memory.percentile_95 = [math]::Round(($memoryValues | Sort-Object)[([math]::Floor($memoryValues.Count * 0.95))], 2)

    Write-Host "Baseline calculated" -ForegroundColor Green
}

# Analyze performance
function Analyze-Performance {
    param(
        [Parameter(Mandatory=$false)]
        [hashtable]$Current = @{}
    )

    if ($Current.Count -eq 0) {
        $Current = $ResourceData
    }

    Write-Host "`n=== Performance Analysis ===" -ForegroundColor Cyan

    # CPU Analysis
    $cpuLoad = ($ResourceData.cpu / $Baseline.cpu.percentile_95) * 100
    $cpuStatus = if ($cpuLoad -lt 70) { "Good" } elseif ($cpuLoad -lt 85) { "Warning" } else { "Critical" }
    $cpuColor = if ($cpuStatus -eq "Good") { "Green" } elseif ($cpuStatus -eq "Warning") { "Yellow" } else { "Red" }

    Write-Host "CPU Usage:" -ForegroundColor Yellow
    Write-Host "  Current: $([math]::Round($ResourceData.cpu, 2))%" -ForegroundColor $(if ($cpuLoad -lt 70) { "Green" } elseif ($cpuLoad -lt 85) { "Yellow" } else { "Red" }))
    Write-Host "  Average: $($Baseline.cpu.average)%" -ForegroundColor Gray
    Write-Host "  Max: $($Baseline.cpu.max)%" -ForegroundColor Gray
    Write-Host "  Status: $cpuStatus" -ForegroundColor $cpuColor

    # Memory Analysis
    $memoryLoad = ($ResourceData.memory / $Baseline.memory.percentile_95) * 100
    $memoryStatus = if ($memoryLoad -lt 70) { "Good" } elseif ($memoryLoad -lt 85) { "Warning" } else { "Critical" }
    $memoryColor = if ($memoryStatus -eq "Good") { "Green" } elseif ($memoryStatus -eq "Warning") { "Yellow" } else { "Red" }

    Write-Host "`nMemory Usage:" -ForegroundColor Yellow
    Write-Host "  Current: $([math]::Round($ResourceData.memory, 2)) MB ($([math]::Round($ResourceData.memory / 1024, 2)) GB)" -ForegroundColor $memoryColor
    Write-Host "  Average: $($Baseline.memory.average) MB" -ForegroundColor Gray
    Write-Host "  Max: $($Baseline.memory.max) MB" -ForegroundColor Gray
    Write-Host "  Status: $memoryStatus" -ForegroundColor $memoryColor

    # Disk Analysis
    Write-Host "`nDisk I/O:" -ForegroundColor Yellow
    $readSpeed = $ResourceData.measurements[-1].diskRead
    $writeSpeed = $ResourceData.measurements[-1].diskWrite

    $lastRead = $ResourceData.measurements[-2].diskRead
    $lastWrite = $ResourceData.measurements[-2].diskWrite

    $readAvg = [math]::Round($readSpeed / ($ResourceData.measurements.Count > 1 ? 1 : 1), 2)
    $writeAvg = [math]::Round($writeSpeed / ($ResourceData.measurements.Count > 1 ? 1 : 1), 2)

    Write-Host "  Current Read: $readSpeed KB/s" -ForegroundColor Gray
    Write-Host "  Current Write: $writeSpeed KB/s" -ForegroundColor Gray
    Write-Host "  Average Read: $readAvg KB/s" -ForegroundColor Gray
    Write-Host "  Average Write: $writeAvg KB/s" -ForegroundColor Gray

    # Network Analysis
    Write-Host "`nNetwork I/O:" -ForegroundColor Yellow
    Write-Host "  Receive: $([math]::Round($ResourceData.measurements[-1].networkRx, 2)) KB/s" -ForegroundColor Gray
    Write-Host "  Transmit: $([math]::Round($ResourceData.measurements[-1].networkTx, 2)) KB/s" -ForegroundColor Gray

    # Overall status
    Write-Host "`n=== Overall Status ===" -ForegroundColor Cyan

    $issues = @()
    if ($cpuLoad -gt 85) {
        $issues += "CPU overload"
    }
    if ($memoryLoad -gt 85) {
        $issues += "Memory overload"
    }
    if ($readSpeed -gt 50000) {
        $issues += "High disk read"
    }
    if ($writeSpeed -gt 50000) {
        $issues += "High disk write"
    }

    if ($issues.Count -eq 0) {
        Write-Host "System performance is optimal" -ForegroundColor Green
    } else {
        Write-Host "Performance issues detected:" -ForegroundColor Yellow
        foreach ($issue in $issues) {
            Write-Host "  - $issue" -ForegroundColor Red
        }
    }

    return @{
        cpuLoad = $cpuLoad
        memoryLoad = $memoryLoad
        status = $issues.Count -eq 0
        issues = $issues
    }
}

# Generate report
function Get-Report {
    param(
        [Parameter(Mandatory=$false)]
        [int]$DurationSec = 60
    )

    Write-Host "Generating performance report..." -ForegroundColor Yellow

    # Run measurements
    Calculate-Baselines -DurationSec $DurationSec

    Write-Host "`n=== Performance Report ===" -ForegroundColor Cyan
    Write-Host "Duration: $DurationSec seconds" -ForegroundColor Yellow

    $analysis = Analyze-Performance

    # Save to file
    $report = @{
        timestamp = (Get-Date).ToUnixTimeSeconds()
        duration = $DurationSec
        baselines = $Baseline
        current = $ResourceData
        analysis = $analysis
    }

    $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $monitorFile -Encoding utf8

    Write-Host "`nReport saved to: $monitorFile" -ForegroundColor Green
}

# Real-time monitoring
function Start-Monitoring {
    param(
        [Parameter(Mandatory=$false)]
        [int]$IntervalMs = 1000
    )

    Write-Host "Starting real-time monitoring (Ctrl+C to stop)..." -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Gray

    $i = 0
    try {
        while ($true) {
            $i++
            $measurement = Measure-Resources
            Clear-Host

            Write-Host "=== Resource Monitor ===" -ForegroundColor Cyan
            Write-Host "Measurement # $i" -ForegroundColor Gray
            Write-Host "Time: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Gray

            Write-Host "`nCPU:" -ForegroundColor Yellow
            Write-Host "  Usage: $([math]::Round($measurement.cpu, 2))%" -ForegroundColor $(if ($measurement.cpu -lt 70) { "Green" } elseif ($measurement.cpu -lt 85) { "Yellow" } else { "Red" }))

            Write-Host "`nMemory:" -ForegroundColor Yellow
            Write-Host "  Usage: $([math]::Round($measurement.memoryMB, 2)) MB ($([math]::Round($measurement.memoryGB, 2)) GB)" -ForegroundColor $(if ($measurement.memoryMB -lt 1024) { "Green" } elseif ($measurement.memoryMB -lt 2048) { "Yellow" } else { "Red" }))

            Write-Host "`nProcesses:" -ForegroundColor Yellow
            Write-Host "  Active: $($measurement.activeProcesses)" -ForegroundColor Gray

            Write-Host "`nPress Ctrl+C to stop" -ForegroundColor Gray

            Start-Sleep -Milliseconds $IntervalMs
        }
    } catch {
        Write-Host "`nMonitoring stopped" -ForegroundColor Yellow
    }
}

# Action handlers
switch ($Action) {
    "test" {
        Initialize-ResourceMonitoring

        Write-Host "`n[1] Measure resources" -ForegroundColor Yellow
        $measurement = Measure-Resources
        Write-Host "  CPU: $($measurement.cpu)%" -ForegroundColor Green
        Write-Host "  Memory: $($measurement.memoryMB) MB" -ForegroundColor Green
        Write-Host "  Disk Read: $($measurement.diskRead) KB/s" -ForegroundColor Green
        Write-Host "  Disk Write: $($measurement.diskWrite) KB/s" -ForegroundColor Green
        Write-Host "  Network Rx: $($measurement.networkRx) KB/s" -ForegroundColor Green
        Write-Host "  Network Tx: $($measurement.networkTx) KB/s" -ForegroundColor Green

        Write-Host "`n[2] Calculate baselines" -ForegroundColor Yellow
        Calculate-Baselines -DurationSec 5

        Write-Host "`n[3] Analyze performance" -ForegroundColor Yellow
        Analyze-Performance

        Write-Host "`n[4] Generate report" -ForegroundColor Yellow
        Get-Report -DurationSec 10

        Write-Host "`n=== Resource Monitor Test Complete ===" -ForegroundColor Cyan
    }

    "analyze" {
        Analyze-Performance
    }

    "report" {
        Get-Report -DurationSec 10
    }

    "monitor" {
        Start-Monitoring -IntervalMs 1000
    }

    "help" {
        Write-Host "`n使用方法:" -ForegroundColor Yellow
        Write-Host "  test - 运行测试"
        Write-Host "  analyze - 分析性能"
        Write-Host "  report - 生成报告"
        Write-Host "  monitor - 实时监控"
        Write-Host "  help - 显示帮助"
    }

    "default" {
        Write-Host "使用方法: resource-monitor.ps1 -Action <action>" -ForegroundColor Yellow
        Write-Host "`n可用操作:" -ForegroundColor Cyan
        Write-Host "  test - 测试资源监控"
        Write-Host "  analyze - 分析性能"
        Write-Host "  report - 生成报告"
        Write-Host "  monitor - 实时监控"
        Write-Host "  help - 显示帮助"
    }
}

Initialize-ResourceMonitoring
