# Apply Environment Variables and Restart Gateway
# This script applies the new environment variable configuration

Write-Host "🔄 Applying Environment Variables and Restarting Gateway..." -ForegroundColor Cyan

# Set environment variables in current session
$env:OPENCLAW_WEB_SEARCH_API_KEY = "BSAd4FWdcg5FrJayT__vdMet0vzcKHK"
$env:OPENCLAW_TELEGRAM_BOT_TOKEN = "7590142905:AAEh4pDD2I5THxIT4vsGggMqRc3oIsU-w3Q"
$env:OPENCLAW_GATEWAY_TOKEN = "c69e441e1a6db1d84e1619366248d3c37fdf5b8c740b56cb"

Write-Host "✅ Environment variables set in current session" -ForegroundColor Green

# Verify environment variables
Write-Host "`n📋 Verifying environment variables..." -ForegroundColor Yellow
$value1 = $env:OPENCLAW_WEB_SEARCH_API_KEY
$value2 = $env:OPENCLAW_TELEGRAM_BOT_TOKEN
$value3 = $env:OPENCLAW_GATEWAY_TOKEN

if ($value1 -and $value2 -and $value3) {
    Write-Host "✅ All environment variables are set" -ForegroundColor Green
} else {
    Write-Host "❌ Some environment variables are missing" -ForegroundColor Red
    exit 1
}

# Restart Gateway
Write-Host "`n🚀 Restarting OpenClaw Gateway..." -ForegroundColor Yellow
try {
    & openclaw gateway restart
    Write-Host "✅ Gateway restart command executed" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to restart Gateway" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

# Wait for Gateway to start
Write-Host "`n⏳ Waiting for Gateway to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Check Gateway status
Write-Host "`n📊 Checking Gateway status..." -ForegroundColor Yellow
try {
    & openclaw gateway status
    Write-Host "`n✅ Gateway is running!" -ForegroundColor Green
} catch {
    Write-Host "`n❌ Gateway status check failed" -ForegroundColor Red
}

Write-Host "`n🎉 Application Complete!" -ForegroundColor Green
Write-Host "📝 Next steps:" -ForegroundColor Yellow
Write-Host "  1. Check Gateway is running (see status above)" -ForegroundColor White
Write-Host "  2. Test Brave Search functionality" -ForegroundColor White
Write-Host "  3. Test Telegram bot connection" -ForegroundColor White
Write-Host "  4. Test Gateway API access" -ForegroundColor White
