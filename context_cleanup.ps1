# OpenClaw 上下文清理脚本 (Windows PowerShell)

# Load environment variables
if (Test-Path -Path ".env-loader.ps1") {
    . .env-loader.ps1
}

# 设置备份目录
$backupDir = "C:\Users\Administrator\.openclaw\workspace\backup\$(Get-Date -Format 'yyyyMMdd')"

# Get ports from environment variables or use defaults
$GATEWAY_PORT = if ($env:GATEWAY_PORT) { $env:GATEWAY_PORT } else { "18789" }
$CANVAS_PORT = if ($env:CANVAS_PORT) { $env:CANVAS_PORT } else { "18789" }
$HEARTBEAT_PORT = if ($env:HEARTBEAT_PORT) { $env:HEARTBEAT_PORT } else { "18789" }
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir | Out-Null
}

# 备份重要配置文件
Copy-Item "C:\Users\Administrator\.openclaw\workspace\SOUL.md" -Destination "$backupDir\" -Force
Copy-Item "C:\Users\Administrator\.openclaw\workspace\USER.md" -Destination "$backupDir\" -Force
Copy-Item "C:\Users\Administrator\.openclaw\workspace\IDENTITY.md" -Destination "$backupDir\" -Force
Copy-Item "C:\Users\Administrator\.openclaw\workspace\BOOTSTRAP.md" -Destination "$backupDir\" -Force

# 创建moltbook文件的压缩包（使用PowerShell内置压缩）
$moltbookFiles = Get-ChildItem "C:\Users\Administrator\.openclaw\workspace\moltbook_*.md"
if ($moltbookFiles.Count -gt 0) {
    $zipPath = "$backupDir\moltbook_archive.zip"
    try {
        # 使用.NET压缩功能
        Add-Type -AssemblyName "System.IO.Compression.FileSystem"
        $zip = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)
        
        foreach ($file in $moltbookFiles) {
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file.FullName, $file.Name) | Out-Null
        }
        $zip.Dispose()
    } catch {
        Write-Host "压缩失败，跳过压缩步骤"
    }
}

# 清理旧的memory文件（保留最近3天）
$memoryFiles = Get-ChildItem "C:\Users\Administrator\.openclaw\workspace\memory\*.md"
foreach ($file in $memoryFiles) {
    $daysOld = (Get-Date) - $file.LastWriteTime
    if ($daysOld.Days -gt 2) {
        Remove-Item $file.FullName -Force
        Write-Host "删除旧文件: $($file.Name)"
    }
}

# 清理临时文件
$tempFiles = Get-ChildItem "C:\Users\Administrator\.openclaw\workspace\*.tmp", "*.log", "*.cache"
foreach ($file in $tempFiles) {
    Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue
}

Write-Host "清理完成！"
Write-Host "工作空间已重置，请重新启动会话。"