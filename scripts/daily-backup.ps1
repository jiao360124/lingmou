# Daily Backup Script for OpenClaw Workspace
# Runs automatically at scheduled times

# Load environment variables
if (Test-Path -Path ".env-loader.ps1") {
    . .env-loader.ps1
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = "backup"
$zipFile = "$backupDir\$timestamp.zip"

# Get ports from environment variables or use defaults
$GATEWAY_PORT = if ($env:GATEWAY_PORT) { $env:GATEWAY_PORT } else { "18789" }
$CANVAS_PORT = if ($env:CANVAS_PORT) { $env:CANVAS_PORT } else { "18789" }

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

        # Keep only last 3 backups (GitHub limit: 100MB, so fewer backups = smaller size)
        Get-ChildItem -Path $backupDir -Filter "*.zip" | Sort-Object LastWriteTime -Descending | Select-Object -Skip 3 | Remove-Item -Force

        # Update memory
        $memoryFile = "memory/$(Get-Date -Format 'yyyy-MM-dd').md"
        if (Test-Path -Path $memoryFile) {
            $newEntry = "`n## 定时备份`n- **时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm')`n- **备份文件**: $zipFile`n- **文件大小**: $fileSize MB`n- **状态**: ✅ 成功`n- **GitHub**: 仅本地备份（超过100MB限制）"
            Add-Content -Path $memoryFile -Value $newEntry
        }

        # NOTE: Backup files are NOT pushed to GitHub because they exceed 100MB limit
        Write-Host "💾 Backup saved locally only (GitHub limit: 100MB)" -ForegroundColor Yellow
    } else {
        Write-Host "⏭️  No changes to backup" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Backup failed: $_" -ForegroundColor Red
    Write-Host $_.Exception.StackTrace -ForegroundColor DarkGray
}
