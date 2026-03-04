<#
.SYNOPSIS
API客户端模块 - RESTful API调用

.DESCRIPTION
提供统一的API调用接口，支持认证、错误处理、缓存等功能。

.PARAMeter Endpoint
API端点路径

.PARAMeter Method
HTTP方法（GET, POST, PUT, DELETE）

.PARAMeter Body
请求体（POST/PUT时需要）

.PARAMeter Headers
请求头

.PARAMeter Timeout
超时时间（秒）

.EXAMPLE
.\api-client.ps1 -Endpoint "/search" -Method "POST" -Body @{query = "test"}
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Endpoint,

    [Parameter(Mandatory=$true)]
    [ValidateSet("GET", "POST", "PUT", "DELETE")]
    [string]$Method,

    [Parameter(Mandatory=$false)]
    $Body,

    [Parameter(Mandatory=$false)]
    [hashtable]$Headers,

    [Parameter(Mandatory=$false)]
    [int]$Timeout = 30
)

function Invoke-ApiRequest {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Endpoint,

        [Parameter(Mandatory=$true)]
        [string]$Method,

        [Parameter(Mandatory=$false)]
        $Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Headers,

        [Parameter(Mandatory=$false)]
        [int]$Timeout = 30
    )

    try {
        Write-Host "🌐 API调用: $Method $Endpoint" -ForegroundColor Cyan

        # 构建请求URL
        $baseUrl = "http://localhost:18789/api"
        $url = "$baseUrl$Endpoint"

        # 准备请求
        $request = @{
            Method = $Method
            Uri = $url
            TimeoutSec = $Timeout
        }

        # 添加请求体
        if ($Body) {
            $request.Body = $Body | ConvertTo-Json -Depth 10
            $request.ContentType = "application/json"
        }

        # 添加请求头
        if ($Headers) {
            $request.Headers = $Headers
        }

        # 执行请求
        $response = Invoke-RestMethod @request -ErrorAction Stop

        Write-Host "  ✓ 请求成功" -ForegroundColor Green
        Write-Host "  响应时间: $($response.meta.execution_time)秒" -ForegroundColor Green

        return $response

    } catch {
        Write-Error "API调用失败: $_"

        # 返回错误响应
        return @{
            success = $false
            error = @{
                code = "API_ERROR"
                message = $_.Exception.Message
                details = $_.ErrorDetails.Message
            }
        }
    }
}

function Invoke-ApiWithRetry {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Endpoint,

        [Parameter(Mandatory=$true)]
        [string]$Method,

        [Parameter(Mandatory=$false)]
        $Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Headers,

        [Parameter(Mandatory=$false)]
        [int]$MaxRetries = 3,

        [Parameter(Mandatory=$false)]
        [int]$RetryDelay = 1
    )

    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        $result = Invoke-ApiRequest -Endpoint $Endpoint -Method $Method -Body $Body -Headers $Headers -Timeout $RetryDelay

        if ($result.success) {
            return $result
        }

        Write-Warning "尝试 $attempt/$MaxRetries 失败: $($result.error.message)"

        if ($attempt -lt $MaxRetries) {
            Write-Host "等待 $(($RetryDelay * 2))秒后重试..." -ForegroundColor Yellow
            Start-Sleep -Seconds ($RetryDelay * 2)
        }
    }

    return $result
}

# 主程序入口
$result = Invoke-ApiRequest -Endpoint $Endpoint -Method $Method -Body $Body -Headers $Headers -Timeout $Timeout

# 返回结果
return $result
