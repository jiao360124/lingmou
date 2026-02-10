$p = Get-Process -Id $PID
$memMB = [math]::Round($p.WorkingSet64 / 1MB, 0)
$memPct = [math]::Round(($memMB / 2048) * 100, 0)
Write-Host "Memory: $memMB MB ($memPct%)"

$drive = Get-PSDrive C
$diskUsage = [math]::Round((($drive.Used / $drive.Total) * 100), 0)
Write-Host "Disk C: $diskUsage%"
