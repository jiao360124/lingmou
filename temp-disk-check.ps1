$drive = Get-PSDrive C
Write-Host "Disk C: $drive.Used / $drive.Total = $([math]::Round((($drive.Used / $drive.Total) * 100), 0))%"
