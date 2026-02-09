# Daily Backup Script for OpenClaw Workspace
# Runs automatically at scheduled times

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = "backup"
$zipFile = "$backupDir\$timestamp.zip"

# Ensure backup directory exists
if (!(Test-Path -Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir
}

Write-Host "🔄 Starting backup at $timestamp" -ForegroundColor Cyan

# Compress workspace excluding backup directory itself
try {
    # Create temp list of files to exclude backup directory
    $excludeList = @($backupDir)

    # Get all files in workspace excluding backup
    $files = Get-ChildItem -Path . -Recurse -File | Where-Object {
        $relativePath = $_.FullName.Substring((Get-Location).Path.Length + 1)
        $relativePath.Split('\')[0] -ne $backupDir
    }

    # Compress to zip
    if ($files.Count -gt 0) {
        Compress-Archive -Path $files.FullName -DestinationPath $zipFile -Force
        $fileSize = [math]::Round((Get-Item $zipFile).Length / 1MB, 2)

        Write-Host "✅ Backup complete: $zipFile" -ForegroundColor Green
        Write-Host "   Size: $fileSize MB" -ForegroundColor Gray

        # Keep only last 7 backups
        Get-ChildItem -Path $backupDir -Filter "*.zip" | Sort-Object LastWriteTime -Descending | Select-Object -Skip 7 | Remove-Item -Force

        # Update memory
        $memoryFile = "memory/$(Get-Date -Format 'yyyy-MM-dd').md"
        if (Test-Path -Path $memoryFile) {
            $newEntry = "`n## 定时备份`n- **时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm')`n- **备份文件**: $zipFile`n- **文件大小**: $fileSize MB`n- **状态**: ✅ 成功"
            Add-Content -Path $memoryFile -Value $newEntry
        }
    } else {
        Write-Host "⏭️  No changes to backup" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Backup failed: $_" -ForegroundColor Red
    Write-Host $_.Exception.StackTrace -ForegroundColor DarkGray
}
