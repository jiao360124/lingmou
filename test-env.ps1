# Test script to verify environment variable loading

Write-Host "=== Testing Environment Variable Loading ===" -ForegroundColor Cyan

# Test 1: Load environment variables
Write-Host "`n[Test 1] Loading environment variables..." -ForegroundColor Yellow
& ".env-loader.ps1"
Write-Host "✅ Environment variables loaded" -ForegroundColor Green

# Test 2: Check individual variables
Write-Host "`n[Test 2] Checking individual port variables..." -ForegroundColor Yellow
$ports = @{
    "Gateway" = $env:GATEWAY_PORT
    "Canvas" = $env:CANVAS_PORT
    "Heartbeat" = $env:HEARTBEAT_PORT
    "WebSocket" = $env:WS_PORT
}

foreach ($name in $ports.Keys) {
    $value = $ports[$name]
    Write-Host "  $name Port: $value" -ForegroundColor Cyan
}

# Test 3: Run nightly evolution script with environment variables
Write-Host "`n[Test 3] Running nightly evolution script..." -ForegroundColor Yellow
& "scripts\nightly-evolution.ps1" | Select-Object -First 20

Write-Host "`n=== All Tests Completed ===" -ForegroundColor Green
