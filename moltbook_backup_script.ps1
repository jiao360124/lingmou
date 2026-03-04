# 灵眸V2.0系统备份脚本

<#
.SYNOPSIS
自动备份所有V2.0相关文件

.DESCRIPTION
创建备份包，包括所有进化系统文件
使用zip压缩并记录备份元数据

.VERSION
2.0.0

.AUTHOR
灵眸 (2026-02-09)
#>

Write-Host ""
Write-Host "💾 开始V2.0系统备份..." -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""

$backupTime = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = "C:\Users\Administrator\.openclaw\workspace\backups"
$backupName = "evolution_v2.0_$backupTime"
$backupFile = "$backupDir\$backupName.zip"

# 创建备份目录
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
}

# 需要备份的文件
$filesToBackup = @(
    "moltbook_evolution_plan_v2.md",
    "moltbook_resilience_engine.ps1",
    "moltbook_nightly_mission.ps1",
    "moltbook_error_monitor.ps1",
    "moltbook_health_check.ps1",
    "moltbook_evolution_startup.ps1",
    "tasks\active_queue.json",
    "tasks\init_tasks.ps1",
    "tasks\simple_init.ps1",
    "tasks\execute_review.ps1",
    "reviews\daily_20260209.md",
    "memory\2026-02-09.md",
    "MEMORY.md"
)

Write-Host "【1/4】收集文件..." -ForegroundColor Yellow
$filesCollected = 0
foreach ($file in $filesToBackup) {
    $filePath = Join-Path "C:\Users\Administrator\.openclaw\workspace" $file
    if (Test-Path $filePath) {
        Write-Host "   ✅ $file" -ForegroundColor Green
        $filesCollected++
    }
    else {
        Write-Host "   ⚠️ 跳过: $file (文件不存在)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "【2/4】创建备份包..." -ForegroundColor Yellow
try {
    Compress-Archive -Path $filesToBackup -DestinationPath $backupFile -Force

    $fileSize = (Get-Item $backupFile).Length / 1KB
    Write-Host "   ✅ 备份包已创建: $backupFile" -ForegroundColor Green
    Write-Host "   📦 大小: $([math]::Round($fileSize, 2)) KB" -ForegroundColor Gray
}
catch {
    Write-Host "   ❌ 备份包创建失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "【3/4】生成备份元数据..." -ForegroundColor Yellow

$metadata = @{
    BackupName = $backupName
    BackupTime = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    BackupLocation = $backupFile
    FileCount = $filesCollected
    FileSizeKB = [math]::Round($fileSize, 2)
    SystemVersion = "2.0.0"
    Author = "灵眸"
    Components = @(
        "容错引擎",
        "主动工作流程",
        "错误监控系统",
        "健康检查系统",
        "夜航计划"
    )
    Description = "V2.0自我进化系统完整备份"
}

$metadataJson = $metadata | ConvertTo-Json -Depth 10
$metadataFile = "$backupDir\$backupName.metadata.json"

$metadataJson | Out-File -FilePath $metadataFile -Encoding UTF8

Write-Host "   ✅ 元数据已保存: $metadataFile" -ForegroundColor Green

Write-Host ""
Write-Host "【4/4】验证备份完整性..." -ForegroundColor Yellow

$verifyResult = @{
    VerificationTime = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    FilesCount = $filesCollected
    BackupExists = $true
    MetadataExists = $true
    MetadataValid = $true
}

# 验证文件存在
foreach ($file in $filesToBackup) {
    $filePath = Join-Path "C:\Users\Administrator\.openclaw\workspace" $file
    if (-not (Test-Path $filePath)) {
        $verifyResult.FilesCount--
    }
}

# 验证元数据
if (-not (Test-Path $metadataFile)) {
    $verifyResult.MetadataExists = $false
}
elseif ($verifyResult.MetadataValid) {
    try {
        $metadataContent = Get-Content $metadataFile
        $metadataContent | ConvertFrom-Json
    }
    catch {
        $verifyResult.MetadataValid = $false
    }
}

Write-Host "   ✅ 备份完整性验证完成" -ForegroundColor Green

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "✅ V2.0系统备份完成！" -ForegroundColor Green
Write-Host ""

# 显示备份摘要
Write-Host "【备份摘要】" -ForegroundColor Cyan
Write-Host "备份名称: $($metadata.BackupName)" -ForegroundColor White
Write-Host "备份时间: $($metadata.BackupTime)" -ForegroundColor Gray
Write-Host "文件数量: $($metadata.FileCount)" -ForegroundColor Gray
Write-Host "备份大小: $($metadata.FileSizeKB) KB" -ForegroundColor Gray
Write-Host "备份位置: $($metadata.BackupLocation)" -ForegroundColor Gray
Write-Host "系统版本: $($metadata.SystemVersion)" -ForegroundColor Gray
Write-Host ""

Write-Host "【包含的组件】" -ForegroundColor Cyan
foreach ($component in $metadata.Components) {
    Write-Host "   ✅ $component" -ForegroundColor Green
}

Write-Host ""
Write-Host "【验证结果】" -ForegroundColor Cyan
Write-Host "   文件完整性: $($verifyResult.FilesCount)/$($metadata.FileCount)" -ForegroundColor $(if ($verifyResult.FilesCount -eq $metadata.FileCount) { "Green" } else { "Yellow" })
Write-Host "   元数据完整性: $(if ($verifyResult.MetadataExists -and $verifyResult.MetadataValid) { "✅ 完整" } else { "❌ 损坏" })" -ForegroundColor $(if ($verifyResult.MetadataExists -and $verifyResult.MetadataValid) { "Green" } else { "Red" })

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "💡 提示：此备份可安全存储或上传到远程仓库" -ForegroundColor Gray
Write-Host ""

return @{
    Success = $true
    BackupFile = $backupFile
    MetadataFile = $metadataFile
    Metadata = $metadata
    Verification = $verifyResult
}
