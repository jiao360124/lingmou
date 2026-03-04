# Clear Telegram Bot Commands
$botToken = "7590142905:AAEh4pDD2I5THxIT4vsGggMqRc3oIsU-w3Q"
$url = "https://api.telegram.org/bot$botToken/getMyCommands"

# Get current commands
Write-Host "Getting current command list..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri $url -Method Post
    if ($response.ok -and $response.result.Count -gt 0) {
        Write-Host "Current commands:" -ForegroundColor Cyan
        $response.result | ForEach-Object {
            Write-Host "  - $($_.command) (description: $($_.description))" -ForegroundColor Gray
        }
        Write-Host "`nCurrent command count: $($response.result.Count)" -ForegroundColor Yellow
    } else {
        Write-Host "No commands found" -ForegroundColor Green
    }
} catch {
    Write-Host "Failed to get commands: $($_.Exception.Message)" -ForegroundColor Red
}
