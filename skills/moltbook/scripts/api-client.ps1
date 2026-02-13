# Moltbook API客户端

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("register", "verify-identity", "get-agent", "post", "search", "comments", "likes", "feed")]
    [string]$Action,

    [string]$Name,
    [string]$Description,
    [string]$Avatar,
    [string]$Content,
    [string]$Query,
    [int]$Limit = 10
)

$ErrorActionPreference = "Stop"

# 配置
$config = Get-Content "skills/moltbook/config.json" | ConvertFrom-Json

# API基础URL
$baseUrl = if ($config.baseURL) { $config.baseURL } else { "https://www.moltbook.com/api/v1" }

# Header
$headers = @{
    "Content-Type" = "application/json"
}

# 认证header
if ($config.apiKey) {
    $headers["X-Moltbook-App-Key"] = $config.apiKey
}

# API函数
function Invoke-MoltbookAPI {
    param(
        [string]$Endpoint,
        [hashtable]$Body,
        [string]$Method = "POST"
    )

    $url = "$baseUrl$Endpoint"
    $bodyJson = $Body | ConvertTo-Json -Depth 10

    try {
        $response = Invoke-RestMethod -Uri $url -Method $Method -Headers $headers -Body $bodyJson -ErrorAction Stop
        return $response
    }
    catch {
        Write-Error "API请求失败: $_"
        Write-Error "URL: $url"
        Write-Error "Body: $bodyJson"
        throw
    }
}

# 动作处理
switch ($Action) {
    "register" {
        if (-not $Name -or -not $Description) {
            throw "注册需要Name和Description参数"
        }

        Write-Host "正在注册Moltbook Agent: $Name" -ForegroundColor Green

        $body = @{
            name = $Name
            description = $Description
            avatar = $Avatar
        }

        $result = Invoke-MoltbookAPI -Endpoint "/agents/register" -Body $body

        Write-Host "注册成功!" -ForegroundColor Green
        Write-Host "API Key: $($result.apiKey)"
        Write-Host "Identity: $($result.identity)"

        # 更新配置
        $config.apiKey = $result.apiKey
        $config.agentName = $result.name
        $config.identity = $result.identity
        $config | ConvertTo-Json -Depth 10 | Set-Content "skills/moltbook/config.json"

        return $result
    }

    "verify-identity" {
        Write-Host "验证Moltbook身份..." -ForegroundColor Yellow

        if (-not $config.apiKey) {
            throw "未配置API Key，请先注册"
        }

        $body = @{}

        $result = Invoke-MoltbookAPI -Endpoint "/agents/verify-identity" -Body $body

        Write-Host "身份验证成功!" -ForegroundColor Green
        Write-Host "Identity: $($result.identity)"
        Write-Host "Status: $($result.status)"

        return $result
    }

    "get-agent" {
        Write-Host "获取Agent信息..." -ForegroundColor Yellow

        $result = Invoke-MoltbookAPI -Endpoint "/agents/me" -Method "GET"

        Write-Host "获取成功!" -ForegroundColor Green
        Write-Host "Name: $($result.name)"
        Write-Host "Description: $($result.description)"
        Write-Host "Created: $($result.createdAt)"

        return $result
    }

    "post" {
        if (-not $Content) {
            throw "发布消息需要Content参数"
        }

        Write-Host "发布到Moltbook..." -ForegroundColor Yellow

        $body = @{
            content = $Content
        }

        $result = Invoke-MoltbookAPI -Endpoint "/agents/me/messages" -Body $body

        Write-Host "发布成功!" -ForegroundColor Green
        Write-Host "Message ID: $($result.id)"
        Write-Host "Published at: $($result.publishedAt)"

        return $result
    }

    "search" {
        Write-Host "搜索Moltbook内容: $Query" -ForegroundColor Yellow

        $body = @{
            query = $Query
            limit = $Limit
        }

        $result = Invoke-MoltbookAPI -Endpoint "/search" -Method "GET" -Body $body

        Write-Host "搜索完成! 找到 $($result.count) 条结果" -ForegroundColor Green

        return $result
    }

    "comments" {
        Write-Host "获取评论..." -ForegroundColor Yellow

        $body = @{
            limit = $Limit
        }

        $result = Invoke-MoltbookAPI -Endpoint "/agents/me/comments" -Method "GET" -Body $body

        Write-Host "获取评论完成!" -ForegroundColor Green
        Write-Host "评论数: $($result.count)"

        return $result
    }

    "likes" {
        Write-Host "获取点赞..." -ForegroundColor Yellow

        $body = @{
            limit = $Limit
        }

        $result = Invoke-MoltbookAPI -Endpoint "/agents/me/likes" -Method "GET" -Body $body

        Write-Host "获取点赞完成!" -ForegroundColor Green
        Write-Host "点赞数: $($result.count)"

        return $result
    }

    "feed" {
        Write-Host "获取推荐内容..." -ForegroundColor Yellow

        $body = @{
            limit = $Limit
        }

        $result = Invoke-MoltbookAPI -Endpoint "/agents/me/feed" -Method "GET" -Body $body

        Write-Host "获取推荐完成!" -ForegroundColor Green
        Write-Host "内容数: $($result.count)"

        return $result
    }

    default {
        throw "未知的动作: $Action"
    }
}

Write-Host "`nMoltbook API Client - $Action`n" -ForegroundColor Cyan
