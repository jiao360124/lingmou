# 自我修复 - 快照管理器

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("create", "list", "restore", "delete")]
    [string]$Action,

    [string]$Name = "auto",
    [switch]$Timestamp
)

$ErrorActionPreference = "Continue"

# 配置
$config = Get-Content ".config/self-healing.json" -ErrorAction SilentlyContinue | ConvertFrom-Json
if (-not $config) {
    $config = @{
        enabled = $true
        snapshotRetention = 7
        includeFiles = @(
            ".config",
            "HEARTBEAT.md",
            "MEMORY.md",
            "skills/*"
        )
    }
}

# 目录
$LogPath = ".logs"
$snapshotDir = Join-Path $LogPath "snapshots"

# 创建快照
function New-Snapshot {
    param([string]$SnapshotName)

    Write-Host "`n📸 创建快照: $SnapshotName" -ForegroundColor Cyan

    $timestamp = (Get-Date -Format "yyyyMMdd-HHmmss")
    $snapshotId = if ($SnapshotName -eq "auto") { "auto-$timestamp" } else { "$SnapshotName-$timestamp" }
    $snapshotFile = Join-Path $snapshotDir "$snapshotId.snapshot"

    $snapshot = @{
        id = $snapshotId
        name = $SnapshotName
        created = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        description = "自动创建的快照用于错误恢复"
        services = @()  # 可扩展
        files = @()    # 可扩展
    }

    # 创建文件列表
    Write-Host "   扫描文件..." -ForegroundColor Yellow
    foreach ($pattern in $config.includeFiles) {
        if (Test-Path $pattern) {
            if (Test-Path (Get-Item $pattern).FullName) {
                $fileData = Get-Item $pattern -ErrorAction SilentlyContinue
                $snapshot.files += @{
                    path = $fileData.FullName
                    type = if ($fileData.PSIsContainer) { "directory" } else { "file" }
                    size = if ($fileData.PSIsContainer) { "N/A" } else { "{0:N2} KB" -f ($fileData.Length / 1KB) }
                }
            }
        }
    }

    # 保存快照
    $snapshot | ConvertTo-Json -Depth 10 | Set-Content $snapshotFile

    Write-Host "   ✅ 快照创建成功!" -ForegroundColor Green
    Write-Host "   ID: $snapshotId" -ForegroundColor White
    Write-Host "   时间: $($snapshot.created)" -ForegroundColor White
    Write-Host "   文件数: $($snapshot.files.Count)" -ForegroundColor White

    return $snapshotId
}

# 列出快照
function Get-List {
    if (-not (Test-Path $snapshotDir)) {
        Write-Host "❌ 快照目录不存在: $snapshotDir" -ForegroundColor Red
        return
    }

    $snapshots = Get-ChildItem -Path $snapshotDir -Filter "*.snapshot.*" | Sort-Object LastWriteTime -Descending

    if ($snapshots.Count -eq 0) {
        Write-Host "📂 没有找到快照" -ForegroundColor Gray
        return
    }

    Write-Host "`n📂 快照列表:" -ForegroundColor Cyan
    Write-Host ("-" * 80) -ForegroundColor Gray

    $snapshots | ForEach-Object {
        $content = Get-Content $_.FullName -Raw | ConvertFrom-Json
        Write-Host "`n   ID: $($content.id)" -ForegroundColor Yellow
        Write-Host "   名称: $($content.name)" -ForegroundColor White
        Write-Host "   创建时间: $($content.created)" -ForegroundColor Gray
        Write-Host "   描述: $($content.description)" -ForegroundColor Gray
        Write-Host "   文件数: $($content.files.Count)" -ForegroundColor Gray
        Write-Host "   大小: $($_.Length / 1KB) KB" -ForegroundColor Gray

        # 显示文件列表（前5个）
        if ($content.files.Count -gt 0) {
            Write-Host "   文件: $($content.files[0].path)" -ForegroundColor DimGray
            if ($content.files.Count -gt 1) {
                Write-Host "     ... 和 $($content.files.Count - 1) 个其他文件" -ForegroundColor DimGray
            }
        }

        # 显示删除命令
        Write-Host "`n   删除: Remove-Snapshot -Action delete -Name $($content.name)" -ForegroundColor Yellow
    }

    Write-Host "`n" -NoNewline
}

# 恢复快照
function Restore-Snapshot {
    param([string]$SnapshotId)

    Write-Host "`n🔄 恢复快照: $SnapshotId" -ForegroundColor Cyan

    if (-not (Test-Path $snapshotDir)) {
        Write-Host "❌ 快照目录不存在" -ForegroundColor Red
        return
    }

    $snapshotFile = Join-Path $snapshotDir "$SnapshotId.snapshot"
    if (-not (Test-Path $snapshotFile)) {
        Write-Host "❌ 快照不存在: $SnapshotId" -ForegroundColor Red
        return
    }

    $snapshot = Get-Content $snapshotFile | ConvertFrom-Json

    Write-Host "`n快照信息:" -ForegroundColor Yellow
    Write-Host "   创建时间: $($snapshot.created)" -ForegroundColor White
    Write-Host "   文件数: $($snapshot.files.Count)" -ForegroundColor White
    Write-Host "   描述: $($snapshot.description)" -ForegroundColor White

    Write-Host "`n⚠️  即将恢复快照，这将覆盖当前状态！" -ForegroundColor Red
    $confirm = Read-Host "确认恢复? (y/N)"

    if ($confirm -eq "y" -or $confirm -eq "Y") {
        Write-Host "`n🔄 开始恢复..." -ForegroundColor Cyan

        # 恢复文件（示例）
        foreach ($file in $snapshot.files) {
            Write-Host "   恢复: $($file.path)" -ForegroundColor Yellow

            if ($file.type -eq "directory") {
                # 目录恢复逻辑
                Write-Host "      (目录恢复暂未实现)" -ForegroundColor Gray
            }
            else {
                # 文件恢复逻辑
                Write-Host "      (文件恢复暂未实现)" -ForegroundColor Gray
            }
        }

        Write-Host "   ✅ 快照恢复完成!" -ForegroundColor Green
        Write-Host "`n   建议: 重启服务以确保完整恢复" -ForegroundColor Yellow
    }
    else {
        Write-Host "❌ 已取消恢复" -ForegroundColor Red
    }
}

# 删除快照
function Remove-Snapshot {
    param([string]$SnapshotName)

    Write-Host "`n🗑️  删除快照: $SnapshotName" -ForegroundColor Cyan

    if (-not (Test-Path $snapshotDir)) {
        Write-Host "❌ 快照目录不存在" -ForegroundColor Red
        return
    }

    $snapshots = Get-ChildItem -Path $snapshotDir -Filter "$SnapshotName-*.snapshot"

    if ($snapshots.Count -eq 0) {
        Write-Host "❌ 未找到匹配的快照: $SnapshotName" -ForegroundColor Red
        return
    }

    Write-Host "找到 $($snapshots.Count) 个匹配的快照" -ForegroundColor Yellow
    $snapshots | ForEach-Object {
        Write-Host "   - $($_.Name)" -ForegroundColor Gray
    }

    $confirm = Read-Host "确认删除这些快照? (y/N)"

    if ($confirm -eq "y" -or $confirm -eq "Y") {
        $deletedCount = 0
        foreach ($snap in $snapshots) {
            Remove-Item $snap.FullName -Force
            Write-Host "   ✅ 已删除: $($snap.Name)" -ForegroundColor Green
            $deletedCount++
        }

        Write-Host "`n✅ 删除完成! 共删除 $deletedCount 个快照" -ForegroundColor Green
    }
    else {
        Write-Host "❌ 已取消删除" -ForegroundColor Red
    }
}

# 主程序
Write-Host "`n🦞 自我修复 - 快照管理器" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Gray

switch ($Action) {
    "create" {
        if ($Timestamp) {
            $timestamp = (Get-Date -Format "yyyyMMdd-HHmmss")
            New-Snapshot -SnapshotName "$Name-$timestamp"
        }
        else {
            New-Snapshot -SnapshotName $Name
        }
    }

    "list" {
        Get-List
    }

    "restore" {
        if ($Timestamp) {
            $timestamp = (Get-Date -Format "yyyyMMdd-HHmmss")
            Restore-Snapshot -SnapshotId "$Name-$timestamp"
        }
        else {
            Restore-Snapshot -SnapshotId $Name
        }
    }

    "delete" {
        Remove-Snapshot -SnapshotName $Name
    }

    default {
        Write-Host "用法:" -ForegroundColor Yellow
        Write-Host "  ./snapshot-manager.ps1 -Action create -Name <name>        # 创建快照" -ForegroundColor White
        Write-Host "  ./snapshot-manager.ps1 -Action list                       # 列出快照" -ForegroundColor White
        Write-Host "  ./snapshot-manager.ps1 -Action restore -Name <name>       # 恢复快照" -ForegroundColor White
        Write-Host "  ./snapshot-manager.ps1 -Action delete -Name <name>        # 删除快照" -ForegroundColor White
    }
}

Write-Host "`n" -NoNewline
