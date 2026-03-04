# OpenClaw 上下文清理脚本 (Windows PowerShell)

# 设置备份目录
$backupDir = "C:\Users\Administrator\.openclaw\workspace\backup\$(Get-Date -Format 'yyyyMMdd')"
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir | Out-Null
}

Write-Host "正在备份重要配置文件..."

# 备份重要配置文件
Copy-Item "C:\Users\Administrator\.openclaw\workspace\SOUL.md" -Destination "$backupDir\" -Force -ErrorAction SilentlyContinue
Copy-Item "C:\Users\Administrator\.openclaw\workspace\USER.md" -Destination "$backupDir\" -Force -ErrorAction SilentlyContinue
Copy-Item "C:\Users\Administrator\.openclaw\workspace\IDENTITY.md" -Destination "$backupDir\" -Force -ErrorAction SilentlyContinue
Copy-Item "C:\Users\Administrator\.openclaw\workspace\BOOTSTRAP.md" -Destination "$backupDir\" -Force -ErrorAction SilentlyContinue

# 创建moltbook文件的简单归档（不使用压缩）
$moltbookFiles = Get-ChildItem "C:\Users\Administrator\.openclaw\workspace\moltbook_*.md" -ErrorAction SilentlyContinue
if ($moltbookFiles.Count -gt 0) {
    Write-Host "发现 $($moltbookFiles.Count) 个moltbook文件，正在准备归档..."
    foreach ($file in $moltbookFiles) {
        Copy-Item $file.FullName -Destination "$backupDir\" -Force -ErrorAction SilentlyContinue
    }
}

# 清理旧的memory文件（保留最近3天）
Write-Host "清理旧的memory文件..."
$memoryFiles = Get-ChildItem "C:\Users\Administrator\.openclaw\workspace\memory\*.md" -ErrorAction SilentlyContinue
foreach ($file in $memoryFiles) {
    $daysOld = (Get-Date) - $file.LastWriteTime
    if ($daysOld.Days -gt 2) {
        Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue
        Write-Host "删除旧文件: $($file.Name)"
    }
}

# 清理临时文件
Write-Host "清理临时文件..."
$tempPatterns = @("*.tmp", "*.log", "*.cache", "*.bak")
foreach ($pattern in $tempPatterns) {
    $tempFiles = Get-ChildItem "C:\Users\Administrator\.openclaw\workspace\$pattern" -ErrorAction SilentlyContinue
    foreach ($file in $tempFiles) {
        Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "清理完成！"
Write-Host "工作空间已重置，请重新启动会话。"