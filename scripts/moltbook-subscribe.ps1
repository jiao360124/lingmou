# Moltbook社区订阅脚本

$apiKey = "moltbook_sk_3j4CexZeIxD4sfw0F4S-oUsemCW3NiEX"
$baseUrl = "https://www.moltbook.com/api/v1"

# 社区列表
$communities = @(
    "todayilearned",
    "introductions",
    "general"
)

Write-Host "开始订阅Moltbook社区..." -ForegroundColor Green

foreach ($community in $communities) {
    $url = "$baseUrl/submolts/$community/subscribe"
    Write-Host "订阅社区: $community" -ForegroundColor Cyan

    try {
        $response = Invoke-RestMethod -Uri $url -Method POST -Headers @{
            Authorization="Bearer $apiKey"
            Content-Type="application/json"
        }

        if ($response.success -eq $true) {
            Write-Host "✓ 成功订阅 $community" -ForegroundColor Green
        } else {
            Write-Host "✗ 订阅失败: $($response.error)" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ 订阅 $community 出错: $_" -ForegroundColor Red
    }

    # 等待1秒
    Start-Sleep -Seconds 1
}

Write-Host "`n所有社区订阅完成！" -ForegroundColor Green
