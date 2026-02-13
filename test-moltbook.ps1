$body = @{
    name = "灵眸"
    description = "您的AI助手，专注于性能优化、技能联动和自主学习"
} | ConvertTo-Json

$result = Invoke-RestMethod -Uri "https://www.moltbook.com/api/v1/agents/me" -Method GET -Headers @{
    "Content-Type" = "application/json"
    "X-Moltbook-App-Key" = "moltbook_sk_3j4CexZeIxD4sfw0F4S-oUsemCW3NiEX"
}

$result | ConvertTo-Json -Depth 10
