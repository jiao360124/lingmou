# API调用优化工具 - API Optimizer
# 版本: 1.0.0
# 创建时间: 2026-02-11

<#
.SYNOPSIS
    API调用优化工具 - 减少API调用，提升性能

.DESCRIPTION
    创建API优化系统，包括：
    - API调用统计
    - 缓存机制
    - 批量操作
    - 请求合并

.PARAMETER Action
    执行的操作: Analyze, Cache, Batch, Optimize

.PARAMETER Endpoint
    API端点

.EXAMPLE
    .\api-optimizer.ps1 -Action Analyze
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('Analyze', 'Cache', 'Batch', 'Optimize')]
    [string]$Action,

    [Parameter(Mandatory=$false)]
    [string]$Endpoint = 'all',

    [Parameter(Mandatory=$false)]
    [int]$CacheSizeMB = 500
)

# 配置
$Config = @{
    LogDir = "logs/performance"
    CacheDir = "temp/api-cache"
    DefaultCacheTTLMinutes = 60
    BatchTimeoutMs = 10000
}

# 创建目录
if (-not (Test-Path $Config.LogDir)) {
    New-Item -ItemType Directory -Path $Config.LogDir -Force | Out-Null
}
if (-not (Test-Path $Config.CacheDir)) {
    New-Item -ItemType Directory -Path $Config.CacheDir -Force | Out-Null
}

# 日志函数
function Write-APILog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $Timestamp = Get-Date -Format "HH:mm:ss"
    $Color = switch($Level) {
        'INFO' { 'White' }
        'WARN' { 'Yellow' }
        'ERROR' { 'Red' }
    }

    Write-Host "[$Timestamp] [$Level] $Message" -ForegroundColor $Color
}

# API优化器类
class APIOptimizer {
    [hashtable]$APICalls = @{}
    [hashtable]$Cache = @{}
    [hashtable]$Statistics = @{
        TotalCalls = 0
        CachedCalls = 0
        SavedCalls = 0
        AverageResponseTime = 0
    }
    [int]$CacheSizeMB = $CacheSizeMB

    APIOptimizer() {
        Write-APILog "初始化API优化器" -Level INFO
    }

    # 分析API调用
    Analyze-APIUsage() {
        Write-APILog "开始分析API调用..." -Level INFO

        $APICalls = @()

        # 检查常见的API调用模式
        $commonEndpoints = @(
            'GET', 'POST', 'PUT', 'DELETE',
            '/api/', '/graphql', '/v1/',
            'api/health', 'api/status', 'system/health'
        )

        # 监控系统进程
        $processes = Get-Process
        foreach ($process in $processes) {
            $moduleName = $process.ProcessName

            # 检查网络连接
            $connections = Get-NetTCPConnection | Where-Object {
                $_.OwningProcess -eq $process.Id -and $_.State -eq 'Established'
            }

            foreach ($conn in $connections) {
                $localPort = $conn.LocalPort
                $remoteAddress = $conn.RemoteAddress

                # 简单的API端点检测
                if ($localPort -in @(80, 443, 8080, 8443)) {
                    $APICalls += @{
                        Process = $moduleName
                        PID = $process.Id
                        Endpoint = $remoteAddress
                        Port = $localPort
                        StartTime = Get-Date
                    }
                }
            }
        }

        # 统计API调用
        $endpointCounts = @{}
        foreach ($call in $APICalls) {
            $endpoint = $call.Endpoint
            if (-not $endpointCounts.ContainsKey($endpoint)) {
                $endpointCounts[$endpoint] = 0
            }
            $endpointCounts[$endpoint]++

            # 记录详细调用信息
            if (-not $this.APICalls.ContainsKey($endpoint)) {
                $this.APICalls[$endpoint] = @{
                    Count = 0
                    Processes = @()
                    TotalTime = 0
                    StartTime = Get-Date
                }
            }

            $callInfo = $this.APICalls[$endpoint]
            $callInfo.Count++
            $callInfo.Processes += $call
            $callInfo.TotalTime++
        }

        $this.Statistics.TotalCalls = $APICalls.Count
        $this.Statistics.CachedCalls = 0
        $this.Statistics.SavedCalls = 0

        # 找出热点API
        $hotspots = $endpointCounts.GetEnumerator() |
                    Where-Object { $_.Value -gt 10 } |
                    Sort-Object -Property Value -Descending

        return @{
            TotalCalls = $APICalls.Count
            Hotspots = $hotspots
            APICalls = $this.APICalls
            CacheHits = 0
            CacheMisses = 0
        }
    }

    # 缓存API响应
    Cache-APIResponse($endpoint, $response, $ttlMinutes = $Config.DefaultCacheTTLMinutes) {
        Write-APILog "缓存API响应: $endpoint" -Level INFO

        $cacheKey = $endpoint
        $cacheTime = Get-Date
        $expiryTime = $cacheTime.AddMinutes($ttlMinutes)

        $cacheEntry = @{
            Endpoint = $endpoint
            Response = $response
            CreatedAt = $cacheTime
            ExpiresAt = $expiryTime
            TTLMinutes = $ttlMinutes
        }

        # 保存到缓存
        $cacheFile = Join-Path $Config.CacheDir "$cacheKey.cache"
        $cacheEntry | ConvertTo-Json | Out-File -FilePath $cacheFile -Encoding UTF8 -Force

        $this.Cache[$cacheKey] = $cacheEntry
        $this.Statistics.CachedCalls++

        Write-APILog "API响应已缓存: $cacheKey (TTL: $ttlMinutes 分钟)" -Level INFO
    }

    # 获取缓存的响应
    Get-CachedResponse($endpoint) {
        Write-APILog "检查API缓存: $endpoint" -Level INFO

        $cacheKey = $endpoint

        if ($this.Cache.ContainsKey($cacheKey)) {
            $cacheEntry = $this.Cache[$cacheKey]

            if (Get-Date -lt $cacheEntry.ExpiresAt) {
                $this.Statistics.CacheHits++
                Write-APILog "缓存命中: $endpoint" -Level INFO
                return @{
                    Success = $true
                    Cached = $true
                    Data = $cacheEntry.Response
                    AgeMinutes = [math]::Round(((Get-Date) - $cacheEntry.CreatedAt).TotalMinutes, 2)
                }
            }
            else {
                # 缓存已过期，删除
                Remove-Item -Path (Join-Path $Config.CacheDir "$cacheKey.cache") -ErrorAction SilentlyContinue
                $this.Cache.Remove($cacheKey)
                $this.Statistics.CacheMisses++
                Write-APILog "缓存已过期: $endpoint" -Level WARN
            }
        }

        $this.Statistics.CacheMisses++
        return @{
            Success = $false
            Cached = $false
            Error = "缓存未找到或已过期"
        }
    }

    # 批量API调用优化
    Batch-APICalls($apiRequests) {
        Write-APILog "开始批量API调用优化..." -Level INFO

        if ($apiRequests.Count -eq 0) {
            Write-APILog "没有API请求需要批量处理" -Level WARN
            return @()
        }

        $results = @()
        $batchStartTime = Get-Date

        # 检查是否可以缓存
        foreach ($request in $apiRequests) {
            $cached = $this.Get-CachedResponse($request.Endpoint)

            if ($cached.Success -and $cached.Cached) {
                $results += @{
                    Endpoint = $request.Endpoint
                    Method = $request.Method
                    Cached = $true
                    Response = $cached.Data
                    ResponseTime = 0  # 缓存命中无实际网络请求
                }
                $this.Statistics.SavedCalls++
            }
            else {
                # 模拟API调用
                $responseTime = Get-Random -Minimum 100 -Maximum 500
                Start-Sleep -Milliseconds $responseTime

                $results += @{
                    Endpoint = $request.Endpoint
                    Method = $request.Method
                    Cached = $false
                    ResponseTime = $responseTime
                    Response = @{ Data = "API Response: $($request.Endpoint)" }
                }

                # 缓存响应
                if ($responseTime -lt $Config.BatchTimeoutMs) {
                    $this.Cache-APIResponse($request.Endpoint, @{
                        Data = "API Response: $($request.Endpoint)"
                    })
                }
            }
        }

        $batchDuration = (Get-Date) - $batchStartTime
        $averageTime = [math]::Round($results.ResponseTime / $results.Count, 2)

        return @{
            TotalRequests = $apiRequests.Count
            TotalTime = [math]::Round($batchDuration.TotalSeconds, 2)
            AverageTime = $averageTime
            Results = $results
            SavedTime = [math]::Round($results.SavedCalls * $averageTime, 2)
        }
    }

    # 生成优化报告
    Generate-Report($analysisResult) {
        Write-APILog "生成API优化报告..." -Level INFO

        $report = @"
# API调用优化报告
**生成时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

---

## 📊 API调用统计

### 总体统计
- **总API调用次数**: $($analysisResult.TotalCalls)
- **缓存命中率**: $([math]::Round($analysisResult.CacheHits / 
    ($analysisResult.CacheHits + $analysisResult.CacheMisses) * 100, 2))%
- **缓存命中数**: $($analysisResult.CacheHits)
- **缓存未命中数**: $($analysisResult.CacheMisses)

### 热点API端点
**频繁调用的API端点**:
"@

        foreach ($hotspot in $analysisResult.Hotspots) {
            $report += "- **$($hotspot.Name)**: $($hotspot.Value) 次`n"
        }

        $report += @"

---

## ✅ 优化建议

### 高优先级优化
"@

        if ($analysisResult.CacheHits / ($analysisResult.CacheHits + $analysisResult.CacheMisses) -lt 0.5) {
            $report += "1. **提升缓存命中率** - 检查缓存策略，增加缓存有效期`n"
        }

        if ($analysisResult.TotalCalls -gt 100) {
            $report += "2. **减少API调用频率** - 实现请求合并和批量操作`n"
        }

        if ($analysisResult.TotalCalls -gt 1000) {
            $report += "3. **实现请求节流** - 添加请求限流机制`n"
        }

        $report += @"

### 缓存优化策略
1. **热门端点缓存** - 为频繁调用的端点实现缓存
2. **响应缓存** - 缓存API响应数据，减少重复请求
3. **缓存过期策略** - 根据业务需求设置合理的TTL
4. **缓存预热** - 在低峰期预先加载缓存数据

### 批量操作优化
1. **请求合并** - 将多个小请求合并为一个大请求
2. **并行处理** - 使用并行调用减少总时间
3. **请求节流** - 限制并发请求数量
4. **后台加载** - 使用后台任务加载缓存数据

---

## 📈 性能提升预期

### 缓存优化
- **预期提升**: 30-50%
- **适用场景**: 高频、低变更的API端点

### 批量操作
- **预期提升**: 40-60%
- **适用场景**: 批量数据获取和更新

### 请求合并
- **预期提升**: 50-70%
- **适用场景**: 多个相关请求

---

**优化完成时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**生成者**: 灵眸API优化器
"@

        # 保存报告
        $reportPath = Join-Path $Config.LogDir "api-optimization-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
        $report | Out-File -FilePath $reportPath -Encoding UTF8 -Force

        Write-APILog "报告已保存: $reportPath" -Level INFO

        # 打印摘要
        Write-Host "`n=== API优化摘要 ===" -ForegroundColor Cyan
        Write-Host "总API调用: $($analysisResult.TotalCalls)"
        Write-Host "缓存命中率: $([math]::Round($analysisResult.CacheHits / 
            ($analysisResult.CacheHits + $analysisResult.CacheMisses) * 100, 2))%"
        Write-Host "缓存命中: $($analysisResult.CacheHits)"
        Write-Host "缓存未命中: $($analysisResult.CacheMisses)"
        Write-Host "报告位置: $reportPath"
        Write-Host ""
    }
}

# 主程序
function Main {
    Write-Host "`n==========================================" -ForegroundColor Cyan
    Write-Host "API调用优化工具" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""

    $optimizer = [APIOptimizer]::new()

    switch ($Action) {
        'Analyze' {
            $result = $optimizer.Analyze-APIUsage()
            $optimizer.Generate-Report($result)
        }
        'Cache' {
            # 模拟缓存操作
            Write-APILog "启用API缓存机制" -Level INFO
            Write-APILog "缓存目录: $Config.CacheDir" -Level INFO
            Write-APILog "默认TTL: $Config.DefaultCacheTTLMinutes 分钟" -Level INFO
            $optimizer.Generate-Report(@{
                TotalCalls = 0
                CacheHits = 0
                CacheMisses = 0
                Hotspots = @()
                APICalls = @{}
            })
        }
        'Batch' {
            # 模拟批量操作
            $batchRequests = @(
                @{ Endpoint = '/api/users', Method = 'GET' },
                @{ Endpoint = '/api/posts', Method = 'GET' },
                @{ Endpoint = '/api/comments', Method = 'GET' },
                @{ Endpoint = '/api/tags', Method = 'GET' }
            )

            Write-APILog "批量API调用: $($batchRequests.Count) 个请求" -Level INFO
            $result = $optimizer.Batch-APICalls($batchRequests)
            $optimizer.Generate-Report($result)
        }
        'Optimize' {
            Write-APILog "执行完整API优化流程" -Level INFO
            $result = $optimizer.Analyze-APIUsage()
            $optimizer.Generate-Report($result)
        }
    }
}

Main
