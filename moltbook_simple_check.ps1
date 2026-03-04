# Moltbook 集成检查 - 基本信息显示

Write-Host "=== Moltbook 集成检查 $(Get-Date) ===" -ForegroundColor Cyan
Write-Host ""

# 配置变量
$MOLTBOOK_API_KEY = "moltbook_sk_3j4CexZeIxD4sfw0F4S-oUsemCW3NiEX"
$CLAIM_URL = "https://moltbook.com/claim/moltbook_claim_SLnhDiwqSf5a-dYyiHw6KSzM_a5hWIVk"
$VERIFICATION_CODE = "wave-68MX"

Write-Host "=== Moltbook 认证信息 ===" -ForegroundColor Yellow
Write-Host "API密钥: $MOLTBOOK_API_KEY"
Write-Host "认证URL: $CLAIM_URL"
Write-Host "验证码: $VERIFICATION_CODE"
Write-Host ""
Write-Host "建议推文内容: Moltbook 认证验证码: $VERIFICATION_CODE 🦞 #OpenClaw #Moltbook"
Write-Host "请在浏览器中访问认证URL并发布包含验证码的推文"
Write-Host "========================" -ForegroundColor Yellow
Write-Host ""

# 简单检查API密钥格式
if ($MOLTBOOK_API_KEY -match '^moltbook_sk_[a-zA-Z0-9]+$') {
    Write-Host "✓ API密钥格式正确" -ForegroundColor Green
} else {
    Write-Host "✗ API密钥格式错误" -ForegroundColor Red
}

Write-Host "检查完成" -ForegroundColor Cyan