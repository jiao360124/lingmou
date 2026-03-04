# 灵眸容错引擎 - 防止传输阻塞卡死

<#
.SYNOPSIS
智能请求处理引擎，防止网络和API阻塞

.DESCRIPTION
当遇到网络问题、API限制、超时等阻塞情况时，能够优雅处理并自动恢复。
主要功能：
1. 速率限制管理
2. 智能重试（带退避）
3. 上下文保存和恢复
4. 优雅降级

.VERSION
1.0.0

.AUTHOR
灵眸 (2026-02-09)

#>

# ============================================
# 配置参数
# ============================================

$Script:RateLimitConfig = @{
    # Moltbook API限制
    Moltbook = @{
        Rate = 100          # 每分钟请求数
        PostRate = 1        # 每30分钟1个帖子
        CommentRate = 1     # 每20秒1个评论
        DailyCommentLimit = 50
        BlockPostMin = 30   # 帖子冷却时间（分钟）
        BlockCommentSec = 20 # 评论冷却时间（秒）
        DailyCommentRemain = 50
    }

    # 默认超时设置
    Timeout = 30000       # 30秒
    MaxRetries = 3        # 最大重试次数
    InitialBackoff = 1000 # 初始退避（毫秒）
    MaxBackoff = 30000    # 最大退避（毫秒）
}

$Script:RetryCount = 0
$Script:LastRetryTime = $null

# ============================================
# 上下文管理
# ============================================

<#
.SYNOPSIS
保存当前操作上下文
#>
function Save-Context {
    param(
        [string]$Operation,
        [hashtable]$Data = @{}
    )

    $context = @{
        Timestamp = Get-Date
        Operation = $Operation
        Data = $Data
        Retries = $Script:RetryCount
    }

    $path = "C:\Users\Administrator\.openclaw\workspace\context\`$(Get-Date -Format 'yyyyMMddHHmmss').json"
    $context | ConvertTo-Json -Depth 10 | Out-File -FilePath $path -Encoding UTF8

    Write-Host "✅ 上下文已保存: $Operation" -ForegroundColor Green
    return $context
}

<#
.SYNOPSIS
加载保存的上下文
#>
function Load-Context {
    param(
        [string]$Operation
    )

    $contextFiles = Get-ChildItem -Path "C:\Users\Administrator\.openclaw\workspace\context" `
        -Filter "*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

    if ($contextFiles) {
        $context = Get-Content $contextFiles.FullName | ConvertFrom-Json
        if ($context.Operation -eq $Operation) {
            Write-Host "✅ 上下文已加载: $Operation" -ForegroundColor Green
            return $context
        }
    }

    Write-Host "⚠️ 未找到保存的上下文: $Operation" -ForegroundColor Yellow
    return $null
}

# ============================================
# 速率限制检查
# ============================================

<#
.SYNOPSIS
检查API速率限制
#>
function Test-RateLimit {
    param(
        [string]$Service = "Moltbook"
    )

    $config = $Script:RateLimitConfig.$Service

    if ($config.PostRate -gt 0) {
        $now = Get-Date
        $lastRetry = $Script:LastRetryTime

        # 计算冷却时间
        if ($lastRetry) {
            $timeSinceLast = ($now - $lastRetry).TotalMinutes

            if ($Service -eq "Moltbook") {
                if ($timeSinceLast -lt $config.BlockPostMin) {
                    $waitMin = $config.BlockPostMin - $timeSinceLast
                    Write-Host "⏳ 帖子冷却中，还需等待 $waitMin 分钟" -ForegroundColor Yellow
                    return $false
                }

                # 检查每日评论限制
                if ($config.DailyCommentRemain -lt 1) {
                    Write-Host "⚠️ 每日评论次数已用尽" -ForegroundColor Yellow
                    return $false
                }
            }
        }
    }

    return $true
}

<#
.SYNOPSIS
更新速率限制状态
#>
function Update-RateLimit {
    param(
        [string]$Service = "Moltbook"
    )

    $config = $Script:RateLimitConfig.$Service
    $Script:LastRetryTime = Get-Date

    if ($Service -eq "Moltbook") {
        # 帖子操作不减少配额
        # 评论操作减少每日配额
        $config.DailyCommentRemain = [math]::Max(0, $config.DailyCommentRemain - 1)
    }
}

# ============================================
# 智能重试引擎
# ============================================

<#
.SYNOPSIS
带退避的重试机制
#>
function Invoke-WithRetry {
    param(
        [scriptblock]$ScriptBlock,
        [string]$OperationName = "操作",
        [hashtable]$Headers = @{},
        [hashtable]$Body = @{},
        [string]$Url = "",
        [string]$Method = "GET"
    )

    $retryCount = 0
    $backoff = $Script:RateLimitConfig.InitialBackoff

    while ($retryCount -lt $Script:RateLimitConfig.MaxRetries) {
        # 检查速率限制
        if (-not (Test-RateLimit)) {
            Write-Host "⏳ 速率限制，跳过本次请求" -ForegroundColor Yellow
            break
        }

        try {
            Write-Host "🔄 请求 $OperationName... (尝试 $retryCount+1/$($Script:RateLimitConfig.MaxRetries))" -ForegroundColor Cyan

            # 保存上下文
            Save-Context -Operation $OperationName -Data @{
                Url = $Url
                Method = $Method
                RetryCount = $retryCount
            }

            # 执行请求
            $result = & $ScriptBlock @Headers @Body @Url @Method

            # 成功
            Update-RateLimit
            Write-Host "✅ $OperationName 完成" -ForegroundColor Green
            return $result

        }
        catch {
            $error = $_.Exception
            $statusCode = $null

            if ($error.Response) {
                $statusCode = $error.Response.StatusCode.value__
            }

            $retryCount++
            Write-Host "❌ $OperationName 失败: $($error.Message)" -ForegroundColor Red

            # 处理429速率限制错误
            if ($statusCode -eq 429 -or $error.Message -like "*429*" -or $error.Message -like "*rate limit*") {
                Write-Host "⏳ 遇到速率限制，等待 $backoff 毫秒后重试..." -ForegroundColor Yellow

                # 计算重试等待时间
                if ($Script:RateLimitConfig.Moltbook.BlockPostMin) {
                    # 帖子限制：返回分钟数
                    if ($retryCount -lt $Script:RateLimitConfig.MaxRetries) {
                        $waitMin = $Script:RateLimitConfig.Moltbook.BlockPostMin
                        Write-Host "⏳ 需等待 $waitMin 分钟后重试" -ForegroundColor Yellow
                        Start-Sleep -Seconds ($waitMin * 60)
                    }
                }
                elseif ($Script:RateLimitConfig.Moltbook.BlockCommentSec) {
                    # 评论限制：返回秒数
                    $waitSec = $Script:RateLimitConfig.Moltbook.BlockCommentSec
                    Write-Host "⏳ 需等待 $waitSec 秒后重试" -ForegroundColor Yellow
                    Start-Sleep -Seconds $waitSec
                }
                else {
                    # 默认退避
                    Write-Host "⏳ 等待 $backoff 毫秒后重试..." -ForegroundColor Yellow
                    Start-Sleep -Milliseconds $backoff
                }

                # 指数退避
                $backoff = [math]::Min([math]::Min($backoff * 2, $Script:RateLimitConfig.MaxBackoff), $Script:RateLimitConfig.InitialBackoff * 16)
                continue
            }

            # 5xx服务器错误
            if ($statusCode -ge 500 -and $statusCode -lt 600) {
                if ($retryCount -lt $Script:RateLimitConfig.MaxRetries) {
                    Write-Host "⏳ 服务器错误，等待 $backoff 毫秒后重试..." -ForegroundColor Yellow
                    Start-Sleep -Milliseconds $backoff
                    $backoff = [math]::Min($backoff * 2, $Script:RateLimitConfig.MaxBackoff)
                    continue
                }
            }

            # 超时错误
            if ($error.Message -like "*timeout*" -or $error.Message -like "*连接超时*") {
                if ($retryCount -lt $Script:RateLimitConfig.MaxRetries) {
                    Write-Host "⏳ 请求超时，等待 $backoff 毫秒后重试..." -ForegroundColor Yellow
                    Start-Sleep -Milliseconds $backoff
                    $backoff = [math]::Min($backoff * 2, $Script:RateLimitConfig.MaxBackoff)
                    continue
                }
            }

            # 其他错误：不重试
            break
        }
    }

    Write-Host "❌ $OperationName 失败，已达到最大重试次数" -ForegroundColor Red
    return $null
}

# ============================================
# 优雅降级函数
# ============================================

<#
.SYNOPSIS
提供优雅降级选项
#>
function Invoke-WithFallback {
    param(
        [scriptblock]$PrimaryScriptBlock,
        [scriptblock]$FallbackScriptBlock = {},
        [string]$OperationName = "操作",
        [string]$FallbackReason = "主方案失败"
    )

    try {
        $result = Invoke-WithRetry -ScriptBlock $PrimaryScriptBlock -OperationName $OperationName
        return $result
    }
    catch {
        Write-Host "⚠️ $FallbackReason" -ForegroundColor Yellow

        if ($FallbackScriptBlock) {
            try {
                Write-Host "🔄 尝试降级方案..." -ForegroundColor Cyan
                $result = & $FallbackScriptBlock
                Write-Host "✅ 降级方案成功" -ForegroundColor Green
                return $result
            }
            catch {
                Write-Host "❌ 降级方案也失败" -ForegroundColor Red
                return $null
            }
        }

        return $null
    }
}

# ============================================
# 初始化
# ============================================

<#
.SYNOPSIS
初始化容错引擎
#>
function Initialize-ResilienceEngine {
    Write-Host "🚀 灵眸容错引擎已启动" -ForegroundColor Cyan
    Write-Host "   - 智能重试: $($Script:RateLimitConfig.MaxRetries) 次" -ForegroundColor Gray
    Write-Host "   - 速率限制: 已配置" -ForegroundColor Gray
    Write-Host "   - 上下文保存: 已启用" -ForegroundColor Gray
    Write-Host "   - 优雅降级: 已启用" -ForegroundColor Gray
    Write-Host ""

    # 创建上下文目录
    $contextDir = "C:\Users\Administrator\.openclaw\workspace\context"
    if (-not (Test-Path $contextDir)) {
        New-Item -ItemType Directory -Path $contextDir -Force | Out-Null
    }
}

# ============================================
# 导出函数
# ============================================

Export-ModuleMember -Function @(
    'Initialize-ResilienceEngine',
    'Save-Context',
    'Load-Context',
    'Test-RateLimit',
    'Update-RateLimit',
    'Invoke-WithRetry',
    'Invoke-WithFallback'
)

# 自动初始化
Initialize-ResilienceEngine
