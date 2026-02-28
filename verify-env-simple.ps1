# Verify environment variables
Write-Host "✅ Environment Variables Verification:" -ForegroundColor Cyan

$value1 = [System.Environment]::GetEnvironmentVariable("OPENCLAW_WEB_SEARCH_API_KEY", "User")
Write-Host "OPENCLAW_WEB_SEARCH_API_KEY: " -NoNewline
if ($value1) {
    $display1 = $value1.Substring(0, 10) + "..."
    Write-Host $display1 -ForegroundColor Green
} else {
    Write-Host "Not set" -ForegroundColor Red
}

$value2 = [System.Environment]::GetEnvironmentVariable("OPENCLAW_TELEGRAM_BOT_TOKEN", "User")
Write-Host "OPENCLAW_TELEGRAM_BOT_TOKEN: " -NoNewline
if ($value2) {
    $display2 = $value2.Substring(0, 10) + "..."
    Write-Host $display2 -ForegroundColor Green
} else {
    Write-Host "Not set" -ForegroundColor Red
}

$value3 = [System.Environment]::GetEnvironmentVariable("OPENCLAW_GATEWAY_TOKEN", "User")
Write-Host "OPENCLAW_GATEWAY_TOKEN: " -NoNewline
if ($value3) {
    $display3 = $value3.Substring(0, 10) + "..."
    Write-Host $display3 -ForegroundColor Green
} else {
    Write-Host "Not set" -ForegroundColor Red
}

# Check current session
Write-Host "`nCurrent session:" -ForegroundColor Cyan
$session1 = Get-Variable "OPENCLAW_WEB_SEARCH_API_KEY" -ErrorAction SilentlyContinue
if ($session1) {
    Write-Host "OPENCLAW_WEB_SEARCH_API_KEY: " -NoNewline
    Write-Host $session1.Value.Substring(0, 10) + "..." -ForegroundColor Green
} else {
    Write-Host "OPENCLAW_WEB_SEARCH_API_KEY: Not in current session" -ForegroundColor Yellow
}

$session2 = Get-Variable "OPENCLAW_TELEGRAM_BOT_TOKEN" -ErrorAction SilentlyContinue
if ($session2) {
    Write-Host "OPENCLAW_TELEGRAM_BOT_TOKEN: " -NoNewline
    Write-Host $session2.Value.Substring(0, 10) + "..." -ForegroundColor Green
} else {
    Write-Host "OPENCLAW_TELEGRAM_BOT_TOKEN: Not in current session" -ForegroundColor Yellow
}

$session3 = Get-Variable "OPENCLAW_GATEWAY_TOKEN" -ErrorAction SilentlyContinue
if ($session3) {
    Write-Host "OPENCLAW_GATEWAY_TOKEN: " -NoNewline
    Write-Host $session3.Value.Substring(0, 10) + "..." -ForegroundColor Green
} else {
    Write-Host "OPENCLAW_GATEWAY_TOKEN: Not in current session" -ForegroundColor Yellow
}
