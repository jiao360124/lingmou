# OpenClaw - Convert to Environment Variables
# This script converts hardcoded secrets to environment variables

Write-Host "🔄 Converting OpenClaw configuration to use environment variables..." -ForegroundColor Cyan

# Read current configuration
$configPath = "$env:USERPROFILE\.openclaw\openclaw.json"
if (-not (Test-Path $configPath)) {
    Write-Host "❌ Configuration file not found: $configPath" -ForegroundColor Red
    exit 1
}

Write-Host "📁 Loading configuration..." -ForegroundColor Yellow
$config = Get-Content -Path $configPath | ConvertFrom-Json

# Create .env file with sensitive values
$envPath = "$env:USERPROFILE\.openclaw\.env"
Write-Host "📝 Creating .env file..." -ForegroundColor Yellow

$envContent = @"
# OpenClaw Environment Variables
# This file contains sensitive configuration that should not be committed to version control

"@

# Add API keys to .env
if ($config.tools.web.search.apiKey) {
    $envContent += "OPENCLAW_WEB_SEARCH_API_KEY=$($config.tools.web.search.apiKey)`n"
}

if ($config.channels.telegram.botToken) {
    $envContent += "OPENCLAW_TELEGRAM_BOT_TOKEN=$($config.channels.telegram.botToken)`n"
}

if ($config.gateway.auth.token) {
    $envContent += "OPENCLAW_GATEWAY_TOKEN=$($config.gateway.auth.token)`n"
}

Set-Content -Path $envPath -Value $envContent -Encoding UTF8 -Force
Write-Host "✅ .env file created: $envPath" -ForegroundColor Green

# Update configuration to use environment variables
Write-Host "🔧 Updating configuration..." -ForegroundColor Yellow

# Update web search API key
$config.tools.web.search.apiKey = "{{env:OPENCLAW_WEB_SEARCH_API_KEY}}"

# Update Telegram bot token
$config.channels.telegram.botToken = "{{env:OPENCLAW_TELEGRAM_BOT_TOKEN}}"

# Update Gateway auth token
$config.gateway.auth.token = "{{env:OPENCLAW_GATEWAY_TOKEN}}"

# Save updated configuration
$config | ConvertTo-Json -Depth 10 | Out-File -Path $configPath -Encoding UTF8 -Force
Write-Host "✅ Configuration updated: $configPath" -ForegroundColor Green

# Create .env.example file (template without actual values)
$envExamplePath = "$env:USERPROFILE\.openclaw\.env.example"
$envExampleContent = @"
# OpenClaw Environment Variables
# Copy this file to .env and fill in your actual values

# Brave Search API Key (get from https://brave.com/search/api/)
OPENCLAW_WEB_SEARCH_API_KEY=your_brave_api_key_here

# Telegram Bot Token (get from @BotFather)
OPENCLAW_TELEGRAM_BOT_TOKEN=your_telegram_bot_token_here

# Gateway Authentication Token (generate a secure random token)
OPENCLAW_GATEWAY_TOKEN=your_gateway_token_here
"@

Set-Content -Path $envExamplePath -Value $envExampleContent -Encoding UTF8 -Force
Write-Host "✅ .env.example created: $envExamplePath" -ForegroundColor Green

# Create .gitignore entry for .env
$gitignorePath = "$env:USERPROFILE\.openclaw\.gitignore"
if (Test-Path $gitignorePath) {
    $gitignoreContent = Get-Content -Path $gitignorePath -Raw -Encoding UTF8
    if (-not ($gitignoreContent -match "\.env")) {
        Add-Content -Path $gitignorePath -Value "`n.env" -Encoding UTF8
        Write-Host "✅ .env added to .gitignore" -ForegroundColor Green
    }
} else {
    "env" | Out-File -FilePath $gitignorePath -Encoding UTF8
    Write-Host "✅ .gitignore created" -ForegroundColor Green
}

# Create README for .env
$envReadmePath = "$env:USERPROFILE\.openclaw\README-ENV.md"
$envReadmeContent = @"
# Environment Variables Configuration

## What is this?

This file contains sensitive credentials used by OpenClaw. These should NOT be committed to version control.

## How to use

1. Copy `.env.example` to `.env`
2. Fill in your actual credentials
3. Restart OpenClaw Gateway to apply changes

## Security Tips

- Never commit `.env` to public repositories
- Use strong, unique tokens for each service
- Rotate credentials regularly
- Monitor usage for unauthorized access

## Getting Credentials

- **Brave Search API**: https://brave.com/search/api/
- **Telegram Bot Token**: Create a bot via @BotFather
- **Gateway Token**: Generate a secure random string
"@

Set-Content -Path $envReadmePath -Value $envReadmeContent -Encoding UTF8 -Force
Write-Host "✅ README-ENV.md created: $envReadmePath" -ForegroundColor Green

Write-Host "`n🎉 Conversion Complete!" -ForegroundColor Green
Write-Host "📝 Summary:" -ForegroundColor Yellow
Write-Host "  - .env file created with your sensitive values" -ForegroundColor White
Write-Host "  - Configuration updated to use environment variables" -ForegroundColor White
Write-Host "  - .env.example template created" -ForegroundColor White
Write-Host "  - .gitignore updated to exclude .env" -ForegroundColor White
Write-Host "  - README-ENV.md created with instructions" -ForegroundColor White
Write-Host "`n⚠️ Important:" -ForegroundColor Yellow
Write-Host "  1. Restart OpenClaw Gateway to apply changes" -ForegroundColor White
Write-Host "  2. Keep .env file secure (don't share it)" -ForegroundColor White
Write-Host "  3. Commit .env.example, not .env" -ForegroundColor White
