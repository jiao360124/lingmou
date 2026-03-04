# OpenClaw Gateway 启动脚本
Write-Host "🚀 启动 OpenClaw Gateway..." -ForegroundColor Cyan

# 检查Node.js
try {
    $nodeVersion = node -v
    Write-Host "✅ Node.js 版本: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Node.js 未安装" -ForegroundColor Red
    exit 1
}

# 检查OpenClaw
try {
    $openclawVersion = openclaw --version
    Write-Host "✅ OpenClaw 版本: $openclawVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ OpenClaw 命令不可用" -ForegroundColor Red
    exit 1
}

# 检查端口占用
Write-Host "`n🔍 检查端口 18789..."
$portInUse = netstat -ano | Select-String ":18789"

if ($portInUse) {
    Write-Host "⚠️  端口 18789 已被占用，正在释放..." -ForegroundColor Yellow
    # 尝试杀死占用端口的进程
    $processId = ($portInUse -split '\s+') | Select-Object -Last 1
    Write-Host "   杀死进程 $processId..."
    taskkill /PID $processId /F /T
    Start-Sleep -Seconds 2
}

# 启动Gateway
Write-Host "`n🚀 启动 Gateway..." -ForegroundColor Cyan
try {
    Start-Process -FilePath "openclaw" -ArgumentList "gateway", "start" -NoNewWindow -PassThru

    # 等待启动
    Write-Host "⏳ 等待 Gateway 启动 (5秒)..."
    Start-Sleep -Seconds 5

    # 检查状态
    Write-Host "`n📊 检查 Gateway 状态..."
    $status = openclaw gateway status

    if ($status) {
        Write-Host "✅ Gateway 启动成功！" -ForegroundColor Green
        Write-Host $status -ForegroundColor Cyan
    } else {
        Write-Host "⚠️  Gateway 可能正在启动中，请稍后检查" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Gateway 启动失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n✨ 完成！" -ForegroundColor Green
