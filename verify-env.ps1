# Verify environment variables
Write-Host "✅ Environment Variables Verification:" -ForegroundColor Cyan

$vars = @(
    "OPENCLAW_WEB_SEARCH_API_KEY",
    "OPENCLAW_TELEGRAM_BOT_TOKEN",
    "OPENCLAW_GATEWAY_TOKEN"
)

foreach ($var in $vars) {
    $value = [System.Environment]::GetEnvironmentVariable($var, "User")
    if ($value) {
        Write-Host "$var: " -NoNewline
        $display = if ($value.Length -gt 10) {
            $value.Substring(0, 10) + "..."
        } else {
            $value
        }
        Write-Host $display -ForegroundColor Green
    } else {
        Write-Host "$var: " -NoNewline
        Write-Host "Not set" -ForegroundColor Red
    }
}

# Also check current session
Write-Host "`nCurrent session variables:" -ForegroundColor Cyan
foreach ($var in $vars) {
    if (Get-Variable -Name $var -ErrorAction SilentlyContinue) {
        $value = [System.Environment]::GetEnvironmentVariable($var, "User")
        $display = if ($value.Length -gt 10) {
            $value.Substring(0, 10) + "..."
        } else {
            $value
        }
        Write-Host "$var: $display" -ForegroundColor Green
    } else {
        Write-Host "$var: Not in current session" -ForegroundColor Yellow
    }
}
