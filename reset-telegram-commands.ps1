# Reset Telegram Bot Commands to empty list
$botToken = "7590142905:AAEh4pDD2I5THxIT4vsGggMqRc3oIsU-w3Q"
$url = "https://api.telegram.org/bot$botToken/setMyCommands"

# Set empty command list
Write-Host "Resetting Telegram bot commands to empty list..." -ForegroundColor Yellow
$body = @{
    commands = @()
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json"
    if ($response.ok) {
        Write-Host "Success! Commands have been reset." -ForegroundColor Green
        Write-Host "Response: $($response.description)" -ForegroundColor Gray
    } else {
        Write-Host "Failed: $($response.description)" -ForegroundColor Red
    }
} catch {
    Write-Host "Failed to reset commands: $($_.Exception.Message)" -ForegroundColor Red
}
