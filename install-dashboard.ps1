# Dashboard 安装脚本

Write-Host "🚀 正在安装 Dashboard 依赖..." -ForegroundColor Cyan
Write-Host ""

# 检查 Node.js
$nodeVersion = node -v 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Node.js 未安装或未配置到 PATH" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Node.js 版本: $nodeVersion" -ForegroundColor Green

# 检查 npm
$npmVersion = npm -v 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ npm 未安装或未配置到 PATH" -ForegroundColor Red
    exit 1
}
Write-Host "✅ npm 版本: $npmVersion" -ForegroundColor Green

Write-Host ""
Write-Host "📦 安装 express 和 socket.io..." -ForegroundColor Cyan

# 安装依赖
npm install express socket.io --legacy-peer-deps

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "❌ 依赖安装失败" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ 依赖安装成功！" -ForegroundColor Green
Write-Host ""
Write-Host "🎉 准备启动 Dashboard！" -ForegroundColor Green
Write-Host ""
Write-Host "运行以下命令启动服务器：" -ForegroundColor Yellow
Write-Host "  node dashboard-server.js" -ForegroundColor White
Write-Host ""
