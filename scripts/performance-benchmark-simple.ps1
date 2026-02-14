# Simple Performance Benchmark
# Quick performance tests

$Results = @{}

# Test 1: Memory Performance
Write-Host "`n[Test 1/3] Memory Performance..." -ForegroundColor Cyan
$MemoryBefore = [System.GC]::GetTotalMemory($false)
[byte[]]$Array = [byte[]]::new(10MB)
[System.GC]::Collect()
$MemoryAfter = [System.GC]::GetTotalMemory($false)
$MemoryUsed = [math]::Round(($MemoryAfter - $MemoryBefore) / 1MB, 2)
$Results.Memory = @{
    BeforeKB = [math]::Round($MemoryBefore / 1KB, 2)
    AfterKB = [math]::Round($MemoryAfter / 1KB, 2)
    ChangeKB = [math]::Round(($MemoryAfter - $MemoryBefore) / 1KB, 2)
    UsedMB = $MemoryUsed
}
Write-Host "   Memory used: $MemoryUsed MB" -ForegroundColor Green

# Test 2: Response Time
Write-Host "`n[Test 2/3] Response Time..." -ForegroundColor Cyan
$Times = @()
for ($i = 1; $i -le 10; $i++) {
    $Start = Get-Date
    Start-Sleep -Milliseconds 50
    $Times += ((Get-Date) - $Start).TotalMilliseconds
}
$AvgTime = ($Times | Measure-Object -Average).Average
$MaxTime = ($Times | Measure-Object -Maximum).Maximum
$MinTime = ($Times | Measure-Object -Minimum).Minimum
$Results.Response = @{
    AvgMS = [math]::Round($AvgTime, 2)
    MaxMS = [math]::Round($MaxTime, 2)
    MinMS = [math]::Round($MinTime, 2)
    ThresholdMS = 100
    Status = if ($AvgTime -lt 100) { "PASS" } else { "FAIL" }
}
Write-Host "   Average: ${AvgTime}ms | Max: ${MaxTime}ms | Min: ${MinTime}ms" -ForegroundColor Green
Write-Host "   Status: $($Results.Response.Status)" -ForegroundColor $(if ($AvgTime -lt 100) { "Green" } else { "Red" })

# Test 3: Disk I/O
Write-Host "`n[Test 3/3] Disk I/O..." -ForegroundColor Cyan
$TestFile = Join-Path $env:TEMP "perf-test.dat"
$WriteStart = Get-Date
[System.IO.File]::WriteAllBytes($TestFile, [byte[]](1..1024))
$WriteTime = ((Get-Date) - $WriteStart).TotalMilliseconds
Remove-Item $TestFile -Force
$Results.DiskIO = @{
    WriteTimeMS = [math]::Round($WriteTime, 2)
    Status = if ($WriteTime -lt 1000) { "PASS" } else { "FAIL" }
}
Write-Host "   Write time: ${WriteTime}ms" -ForegroundColor Green
Write-Host "   Status: $($Results.DiskIO.Status)" -ForegroundColor $(if ($WriteTime -lt 1000) { "Green" } else { "Red" })

# Summary
Write-Host "`n====================================================" -ForegroundColor Magenta
Write-Host "           PERFORMANCE BENCHMARK SUMMARY" -ForegroundColor Magenta
Write-Host "====================================================" -ForegroundColor Magenta

Write-Host "`nMemory Performance:" -ForegroundColor Cyan
Write-Host "   Memory used: $($Results.Memory.UsedMB) MB"

Write-Host "`nResponse Time:" -ForegroundColor Cyan
Write-Host "   Average: $($Results.Response.AvgMS)ms"
Write-Host "   Max: $($Results.Response.MaxMS)ms"
Write-Host "   Status: $($Results.Response.Status)"

Write-Host "`nDisk I/O:" -ForegroundColor Cyan
Write-Host "   Write time: $($Results.DiskIO.WriteTimeMS)ms"
Write-Host "   Status: $($Results.DiskIO.Status)"

# Save report
$ReportDir = "C:\Users\Administrator\.openclaw\workspace\reports"
$ReportFile = Join-Path $ReportDir "performance-benchmark-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
$ReportContent = @"
# Performance Benchmark Report
**Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Summary
- **Memory**: $($Results.Memory.UsedMB) MB
- **Response Time**: $($Results.Response.AvgMS)ms average
- **Disk I/O**: $($Results.DiskIO.WriteTimeMS)ms write time

## Results
$(if ($Results.Response.Status -eq "PASS") { "✓ Response time good!" } else { "✗ Response time needs improvement" })
$(if ($Results.DiskIO.Status -eq "PASS") { "✓ Disk I/O good!" } else { "✗ Disk I/O needs improvement" })

---
"@

$ReportContent | Out-File -FilePath $ReportFile -Encoding UTF8
Write-Host "`nReport saved: $ReportFile" -ForegroundColor Green

exit 0
