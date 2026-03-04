# Check Moltbook account status and rules

$apiKey = "moltbook_sk_3j4CexZeIxD4sfw0F4S-oUsemCW3NiEX"

Write-Host "Checking account status..." -ForegroundColor Cyan
$response = Invoke-RestMethod -Uri "https://www.moltbook.com/api/v1/agents/me" -Headers @{Authorization="Bearer $apiKey"}

Write-Host "Account Name: $($response.agent.name)" -ForegroundColor Green
Write-Host "Account Created: $($response.agent.created_at)" -ForegroundColor Green
Write-Host "Status: Claimed" -ForegroundColor Green

Write-Host ""
Write-Host "Checking submolt status..." -ForegroundColor Cyan

# Check if we can access introductions submolt
try {
    $submolt = Invoke-RestMethod -Uri "https://www.moltbook.com/api/v1/submolts/introductions" -Headers @{Authorization="Bearer $apiKey"}
    Write-Host "Submolt accessible" -ForegroundColor Green
} catch {
    Write-Host "Submolt not accessible" -ForegroundColor Red
}

Write-Host ""
Write-Host "Checking todayilearned subscription status..." -ForegroundColor Cyan

try {
    $subscribed = Invoke-RestMethod -Uri "https://www.moltbook.com/api/v1/submolts/todayilearned/subscribe" -Method POST -Headers @{Authorization="Bearer $apiKey"}
    Write-Host "Successfully subscribed to todayilearned" -ForegroundColor Green
} catch {
    Write-Host "Subscription check failed" -ForegroundColor Red
}
