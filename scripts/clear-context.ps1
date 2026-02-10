# 清理上下文脚本
$StartTime = Get-Date

Write-Host "[CLEANUP] Starting context cleanup..." -ForegroundColor Cyan
Write-Host "[CLEANUP] $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan

# 1. 清理临时脚本
Write-Host "`n[1] Cleaning temporary scripts..." -ForegroundColor Yellow

$tempScripts = Get-ChildItem . -Filter "temp-*.ps1" -ErrorAction SilentlyContinue

if ($tempScripts.Count -gt 0) {
    Write-Host "    Found $($tempScripts.Count) temporary scripts" -ForegroundColor Gray
    foreach ($script in $tempScripts) {
        Remove-Item -Path $script.FullName -Force
        Write-Host "      Removed: $($script.Name)" -ForegroundColor Green
    }
} else {
    Write-Host "    No temporary scripts found" -ForegroundColor Green
}

# 2. 清理测试文件
Write-Host "`n[2] Cleaning test files..." -ForegroundColor Yellow

$testFiles = Get-ChildItem . -Filter "*test*.ps1" -ErrorAction SilentlyComplete

if ($testFiles.Count -gt 0) {
    Write-Host "    Found $($testFiles.Count) test files" -ForegroundColor Gray
    foreach ($file in $testFiles) {
        Remove-Item -Path $file.FullName -Force
        Write-Host "      Removed: $($file.Name)" -ForegroundColor Green
    }
} else {
    Write-Host "    No test files found" -ForegroundColor Green
}

# 3. 清理日志缓存
Write-Host "`n[3] Cleaning log caches..." -ForegroundColor Yellow

$logCache = "$HOME\.openclaw\logs\cache"

if (Test-Path $logCache) {
    $cacheFiles = Get-ChildItem $logCache -ErrorAction SilentlyContinue
    if ($cacheFiles.Count -gt 0) {
        Remove-Item -Path $logCache -Recurse -Force
        Write-Host "    Removed log cache ($($cacheFiles.Count) files)" -ForegroundColor Green
    } else {
        Remove-Item -Path $logCache -Force
        Write-Host "    Removed empty log cache" -ForegroundColor Green
    }
} else {
    Write-Host "    No log cache found" -ForegroundColor Green
}

# 4. 清理临时数据文件
Write-Host "`n[4] Cleaning temporary data files..." -ForegroundColor Yellow

$tempData = Get-ChildItem . -Filter "*.tmp" -ErrorAction SilentlyContinue

if ($tempData.Count -gt 0) {
    Write-Host "    Found $($tempData.Count) temporary data files" -ForegroundColor Gray
    foreach ($file in $tempData) {
        Remove-Item -Path $file.FullName -Force
        Write-Host "      Removed: $($file.Name)" -ForegroundColor Green
    }
} else {
    Write-Host "    No temporary data files found" -ForegroundColor Green
}

# 5. 清理旧的备份（保留最近7个）
Write-Host "`n[5] Cleaning old backups..." -ForegroundColor Yellow

$backupDir = ".\backup"
if (Test-Path $backupDir) {
    $backups = Get-ChildItem $backupDir -Filter "*.zip" -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTime -Descending |
                Select-Object -Skip 7

    if ($backups.Count -gt 0) {
        Write-Host "    Found $($backups.Count) old backups (keeping last 7)" -ForegroundColor Gray
        foreach ($backup in $backups) {
            Remove-Item -Path $backup.FullName -Force
            Write-Host "      Removed: $($backup.Name)" -ForegroundColor Green
        }
    } else {
        Write-Host "    No old backups to clean" -ForegroundColor Green
    }
} else {
    Write-Host "    Backup directory not found" -ForegroundColor Gray
}

# 6. 清理会话缓存（如果需要）
Write-Host "`n[6] Cleaning session caches..." -ForegroundColor Yellow

$sessionCache = "$HOME\.openclaw\agents\main\sessions"

if (Test-Path $sessionCache) {
    $sessionFiles = Get-ChildItem $sessionCache -Filter "*cache*" -ErrorAction SilentlyContinue
    if ($sessionFiles.Count -gt 0) {
        Remove-Item -Path $sessionFiles.FullName -Force
        Write-Host "    Removed $($sessionFiles.Count) cache files" -ForegroundColor Green
    }
} else {
    Write-Host "    No session cache found" -ForegroundColor Green
}

# 7. 检查磁盘空间
Write-Host "`n[7] Checking disk space..." -ForegroundColor Yellow

$drive = Get-PSDrive C
$freeGB = [math]::Round(($drive.Free / 1GB), 2)
$usedGB = [math]::Round(($drive.Used / 1GB), 2)
$totalGB = [math]::Round(($drive.Total / 1GB), 2)
$usagePct = [math]::Round(($usedGB / $totalGB * 100), 1)

Write-Host "    C Drive: $usedGB GB used / $totalGB GB total ($usagePct%)" -ForegroundColor Cyan
Write-Host "    Free Space: $freeGB GB" -ForegroundColor Cyan

# 总体评估
$EndTime = Get-Date
$Duration = ($EndTime - $StartTime).TotalSeconds

Write-Host "`n[CLEARUP] ==========================================" -ForegroundColor Cyan
Write-Host "[CLEARUP] Cleanup Complete" -ForegroundColor Cyan
Write-Host "[CLEARUP] Duration: $(Duration.ToString('F2')) seconds" -ForegroundColor Cyan
Write-Host "[CLEARUP] Context cleared successfully" -ForegroundColor Green
Write-Host "[CLEARUP] ==========================================" -ForegroundColor Cyan
