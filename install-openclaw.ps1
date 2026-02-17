# OpenClaw 安装脚本
Write-Host "Installing OpenClaw..."
Write-Host "Node.js version: $(node --version)"
Write-Host "npm version: $(npm --version)"

# 安装 OpenClaw
npm install -g openclaw@latest

# 验证安装
Write-Host "`nVerifying OpenClaw installation..."
if (Get-Command openclaw -ErrorAction SilentlyContinue) {
    Write-Host "✅ OpenClaw installed successfully!"
    Write-Host "OpenClaw version: $(openclaw --version)"
} else {
    Write-Host "❌ OpenClaw installation may have failed."
    Write-Host "Please check the error messages above."
}
