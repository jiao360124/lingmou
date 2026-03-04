<#
.SYNOPSIS
API网关系统 - 主程序入口

.DESCRIPTION
统一API网关系统主程序，提供API规范定义、调用、验证、速率限制等功能。

.EXAMPLE
.\main.ps1 -Action spec -Schema $schema -Output "api-schema.json"

.EXAMPLE
.\main.ps1 -Action call -Endpoint "/search" -Method "POST" -Body $body

.EXAMPLE
.\main.ps1 -Action validate -Request $request -Schema $schema -Endpoint "/search"
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("spec", "call", "validate", "limit")]
    [string]$Action,

    [Parameter(Mandatory=$false)]
    [string]$Endpoint = "/search",

    [Parameter(Mandatory=$false)]
    [string]$Method = "POST",

    [Parameter(Mandatory=$false)]
    $Body,

    [Parameter(Mandatory=$false)]
    $Schema,

    [Parameter(Mandatory=$false)]
    [string]$Output,

    [Parameter(Mandatory=$false)]
    $Request,

    [Parameter(Mandatory=$false)]
    [PSCustomObject]$Limit,

    [Parameter(Mandatory=$false)]
    [hashtable]$Context
)

function Load-ApiSchema {
    $schemaPath = ".\skills\api-gateway\api-schema.json"
    if (Test-Path $schemaPath) {
        return Get-Content $schemaPath -Raw | ConvertFrom-Json
    }

    return [PSCustomObject]@{
        api_version = "1.0.0"
        endpoints = @()
    }
}

function Run-SpecAction {
    param(
        [Parameter(Mandatory=$false)]
        $Schema,

        [Parameter(Mandatory=$false)]
        [string]$Output
    )

    Write-Host "📝 生成API规范" -ForegroundColor Cyan

    if ($null -eq $Schema) {
        $Schema = Load-ApiSchema
    }

    if ([string]::IsNullOrEmpty($Output)) {
        $Output = "api-schema.json"
    }

    $Schema | ConvertTo-Json -Depth 10 | Out-File -FilePath $Output -Encoding UTF8
    Write-Host "  ✓ 已保存到: $Output" -ForegroundColor Green

    return $Schema
}

function Run-CallAction {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Endpoint,

        [Parameter(Mandatory=$true)]
        [string]$Method,

        [Parameter(Mandatory=$false)]
        $Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Headers
    )

    Write-Host "🌐 调用API: $Method $Endpoint" -ForegroundColor Cyan

    # 调用API客户端
    $result = & .\scripts\api-client.ps1 -Endpoint $Endpoint -Method $Method -Body $Body -Headers $Headers

    return $result
}

function Run-ValidateAction {
    param(
        [Parameter(Mandatory=$true)]
        $Request,

        [Parameter(Mandatory=$false)]
        $Schema,

        [Parameter(Mandatory=$false)]
        [string]$Endpoint = "/search"
    )

    Write-Host "✅ 验证请求" -ForegroundColor Cyan

    if ($null -eq $Schema) {
        $Schema = Load-ApiSchema
    }

    $result = & .\scripts\api-validator.ps1 -Request $Request -Schema $Schema -Endpoint $Endpoint

    if ($result.valid) {
        Write-Host "  ✓ 验证通过" -ForegroundColor Green
    } else {
        Write-Host "  ✗ 验证失败" -ForegroundColor Red
        foreach ($error in $result.errors) {
            Write-Host "    - $error" -ForegroundColor Yellow
        }
    }

    return $result
}

function Run-LimitAction {
    param(
        [Parameter(Mandatory=$false)]
        [PSCustomObject]$Limit,

        [Parameter(Mandatory=$false)]
        [hashtable]$Context
    )

    Write-Host "⚡ 检查速率限制" -ForegroundColor Cyan

    if ($null -eq $Limit) {
        $Limit = [PSCustomObject]@{
            requests_per_minute = 100
            requests_per_hour = 1000
            concurrent_requests = 10
        }
    }

    $result = & .\scripts\rate-limiter.ps1 -Check -Limit $Limit -Context $Context

    if ($result.allowed) {
        Write-Host "  ✓ 允许请求" -ForegroundColor Green
        Write-Host "  当前计数: $($result.current)" -ForegroundColor Green
    } else {
        Write-Host "  ✗ 被拒绝" -ForegroundColor Red
        Write-Host "  原因: $($result.message)" -ForegroundColor Red
    }

    return $result
}

# 主程序入口
switch ($Action) {
    "spec" {
        Run-SpecAction -Schema $Schema -Output $Output
    }
    "call" {
        Run-CallAction -Endpoint $Endpoint -Method $Method -Body $Body
    }
    "validate" {
        Run-ValidateAction -Request $Request -Schema $Schema -Endpoint $Endpoint
    }
    "limit" {
        Run-LimitAction -Limit $Limit -Context $Context
    }
}
