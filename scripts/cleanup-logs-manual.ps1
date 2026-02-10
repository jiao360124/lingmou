# 手动日志清理
$logPath = "$HOME\.openclaw\logs"
$backupPath = "$HOME\.openclaw\logs\backup"

Write-Host "[CLEANUP] Starting log cleanup..." -ForegroundColor Cyan

# 创建备份目录
if (-not (Test-Path $backupPath)) {
    New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
    Write-Host "[CLEANUP] Created backup directory" -ForegroundColor Green
}

# 移动旧日志到备份
$logs = Get-ChildItem $logPath -Filter "*.log" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(7) }

if ($logs.Count -gt 0) {
    Write-Host "[CLEANUP] Moving $($logs.Count) old logs to backup..." -ForegroundColor Yellow

    foreach ($log in $logs) {
        $backupFile = Join-Path $backupPath "$($log.Name)_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Move-Item -Path $log.FullName -Destination $backupFile -Force
    }

    Write-Host "[CLEANUP] Logs moved to backup" -ForegroundColor Green
} else {
    Write-Host "[CLEANUP] No old logs found (older than 7 days)" -ForegroundColor Green
}

# 删除临时文件
$tempPath = "$HOME\.openclaw"
$tempFiles = Get-ChildItem $tempPath -Filter "*.tmp" -ErrorAction SilentlyContinue

if ($tempFiles.Count -gt 0) {
    Write-Host "[CLEANUP] Deleting $($tempFiles.Count) temp files..." -ForegroundColor Yellow

    foreach ($temp in $tempFiles) {
        Remove-Item -Path $temp.FullName -Force
    }

    Write-Host "[CLEANUP] Temp files deleted" -ForegroundColor Green
} else {
    Write-Host "[CLEANUP] No temp files found" -ForegroundColor Green
}

Write-Host "[CLEANUP] Log cleanup completed!" -ForegroundColor Green
