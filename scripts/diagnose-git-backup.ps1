#!/usr/bin/env powershell
# Git备份失败诊断脚本

Write-Host "🔍 开始诊断Git备份失败问题..." -ForegroundColor Cyan

# 1. 检查最近6次备份失败记录
Write-Host "`n📊 最近6次Git备份状态:" -ForegroundColor Yellow

$logsPath = "C:\Users\Administrator\.openclaw\workspace\git-backup-logs"
if (Test-Path $logsPath) {
    $recentLogs = Get-ChildItem $logsPath | Sort-Object LastWriteTime -Descending | Select-Object -First 6

    foreach ($log in $recentLogs) {
        $logContent = Get-Content $log.FullName -Raw
        $status = if ($logContent -match '"status":"ok"') { "✓ OK" } else { "✗ Failed" }

        Write-Host "  $($log.Name) - $status" -ForegroundColor $(if ($logContent -match '"status":"ok"') { "Green" } else { "Red" })

        if ($logContent -match '"status":"Failed"') {
            Write-Host "    错误: $($logContent | Select-String -Pattern 'error' -AllMatches | ForEach-Object { $_.Matches.Value } | Select-Object -First 1)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "  ⚠ 日志目录不存在" -ForegroundColor Yellow
}

# 2. 检查当前Git状态
Write-Host "`n📍 当前Git状态:" -ForegroundColor Yellow

$workspace = "C:\Users\Administrator\.openclaw\workspace"
Push-Location $workspace
$currentStatus = git status --short
$hasChanges = $currentStatus -ne ""

if ($hasChanges) {
    Write-Host "  ⚠ 有未提交的更改" -ForegroundColor Red
    Write-Host "  未提交文件:" -ForegroundColor Yellow
    git status --short | Select-Object -First 10
} else {
    Write-Host "  ✓ 没有未提交的更改" -ForegroundColor Green
}
Pop-Location

# 3. 测试Git连接
Write-Host "`n🔗 测试Git远程连接:" -ForegroundColor Yellow

Push-Location $workspace
try {
    $remoteStatus = git remote -v
    Write-Host "  远程仓库: $($remoteStatus -split "`n" | Select-Object -First 1)" -ForegroundColor Green

    $connectionTest = git ls-remote --head origin 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ 远程连接正常" -ForegroundColor Green
    } else {
        Write-Host "  ✗ 远程连接失败" -ForegroundColor Red
        Write-Host "  错误: $connectionTest" -ForegroundColor Red
    }
} catch {
    Write-Host "  ✗ 测试失败: $_" -ForegroundColor Red
}
Pop-Location

# 4. 检查GitHub认证
Write-Host "`n🔐 检查GitHub认证:" -ForegroundColor Yellow

Push-Location $workspace
$gitConfig = git config --list | Where-Object { $_ -match "credential" }
if ($gitConfig) {
    Write-Host "  ✓ 找到认证配置" -ForegroundColor Green
    $gitConfig | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
} else {
    Write-Host "  ⚠ 未找到认证配置" -ForegroundColor Yellow
}
Pop-Location

# 5. 分析失败原因
Write-Host "`n🎯 可能的失败原因分析:" -ForegroundColor Yellow

$potentialIssues = @()

if ($hasChanges) {
    $potentialIssues += "有未提交的更改"
}

$recentFailed = Get-ChildItem $logsPath | Where-Object {
    (Get-Content $_.FullName -Raw) -match '"status":"Failed"'
} | Select-Object -First 1

if ($recentFailed) {
    $logTime = $recentFailed.LastWriteTime
    $now = Get-Date
    $hoursAgo = ($now - $logTime).TotalHours

    if ($hoursAgo -lt 1) {
        $potentialIssues += "最近1小时内失败过"
    }
}

if ($potentialIssues.Count -eq 0) {
    Write-Host "  ✓ 暂未发现明显问题" -ForegroundColor Green
} else {
    Write-Host "  检测到以下潜在问题:" -ForegroundColor Red
    $potentialIssues | ForEach-Object { Write-Host "    - $_" -ForegroundColor Red }
}

Write-Host "`n✓ 诊断完成！" -ForegroundColor Green
