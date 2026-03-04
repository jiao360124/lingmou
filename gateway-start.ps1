# Gateway 启动脚本
Write-Host "Starting OpenClaw Gateway..."
Write-Host "Node.js version: $(node --version)"
Write-Host "npm version: $(npm --version)"

# 启动 Gateway
Write-Host "`nStarting Gateway..."
openclaw gateway start

# 验证启动
Start-Sleep -Seconds 3
Write-Host "`nVerifying Gateway status..."
openclaw gateway status
