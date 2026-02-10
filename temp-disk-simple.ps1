$drive = Get-PSDrive C
$usage = [math]::Round((($drive.Used / $drive.Total) * 100), 0)
Write-Host "Disk usage: $usage%"
