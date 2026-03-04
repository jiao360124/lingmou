<#
.SYNOPSIS
Cache Manager

.DESCRIPTION
缓存管理器，实现多级缓存和缓存失效策略

.NOTES
Author: OpenClaw Assistant
Date: 2026-02-16
Version: 1.0.0
#>

# 缓存配置
$cacheConfig = @{
    enabled = $true
    level1 = @{
        enabled = $true
        ttl = 60  # 60秒
        maxSize = 1000
        memory = @{}
    }
    level2 = @{
        enabled = $true
        ttl = 600  # 600秒
        maxSize = 10000
        file = $true
        path = ".cache"
    }
    level3 = @{
        enabled = $true
        ttl = 3600  # 3600秒
        maxSize = 100000
        disk = $true
        path = ".cache/level3"
    }
    prefix = "cache"
}

# 缓存存储
$cacheStore = @{
    level1 = @{}
    level2 = @{}
    level3 = @{}
}

# 初始化缓存
function Initialize-Cache {
    param(
        [bool]$Force = $false
    )

    if (-not $cacheConfig.enabled) {
        Write-Host "Cache is disabled" -ForegroundColor Yellow
        return
    }

    # 创建缓存目录
    if ($cacheConfig.level2.file) {
        $cachePath = Join-Path $PWD $cacheConfig.level2.path
        if (-not (Test-Path $cachePath)) {
            New-Item -ItemType Directory -Path $cachePath -Force | Out-Null
        }
    }

    if ($cacheConfig.level3.disk) {
        $cachePath = Join-Path $PWD $cacheConfig.level3.path
        if (-not (Test-Path $cachePath)) {
            New-Item -ItemType Directory -Path $cachePath -Force | Out-Null
        }
    }

    if ($Force) {
        Clear-Cache -Level "all"
    }

    Write-Host "Cache initialized" -ForegroundColor Green
}

# 获取缓存键
function Get-CacheKey {
    param(
        [string]$Key,
        [string[]]$Args = @()
    )

    $cacheKey = "$($cacheConfig.prefix):$Key"

    if ($Args.Count -gt 0) {
        $cacheKey += ":" + ($Args -join ":")
    }

    return $cacheKey
}

# 获取缓存值
function Get-Cache {
    param(
        [string]$Key,
        [string[]]$Args = @()
    )

    if (-not $cacheConfig.enabled) {
        return $null
    }

    $cacheKey = Get-CacheKey -Key $Key -Args $Args

    # L1缓存（内存）
    if ($cacheConfig.level1.enabled -and $cacheStore.level1.ContainsKey($cacheKey)) {
        $value = $cacheStore.level1[$cacheKey]

        if ((Get-Date) -lt $value.expiry) {
            $value.hits++
            $value.lastAccess = Get-Date
            return @{
                value = $value.data
                level = "L1"
                hits = $value.hits
            }
        }
        else {
            $cacheStore.level1.Remove($cacheKey)
        }
    }

    # L2缓存（文件）
    if ($cacheConfig.level2.enabled) {
        $cacheFile = Join-Path $PWD $cacheConfig.level2.path "${cacheKey}.json"

        if (Test-Path $cacheFile) {
            $data = Get-Content $cacheFile -Raw | ConvertFrom-Json

            if ((Get-Date) -lt $data.expiry) {
                $data.hits++
                $data.lastAccess = Get-Date

                if ($cacheConfig.level1.enabled) {
                    $cacheStore.level1[$cacheKey] = @{
                        data = $data.value
                        expiry = $data.expiry
                        hits = 0
                        lastAccess = $data.lastAccess
                    }
                }

                return @{
                    value = $data.value
                    level = "L2"
                    hits = $data.hits
                }
            }
            else {
                Remove-Item $cacheFile -Force
            }
        }
    }

    # L3缓存（磁盘）
    if ($cacheConfig.level3.enabled) {
        $cacheFile = Join-Path $PWD $cacheConfig.level3.path "${cacheKey}.json"

        if (Test-Path $cacheFile) {
            $data = Get-Content $cacheFile -Raw | ConvertFrom-Json

            if ((Get-Date) -lt $data.expiry) {
                $data.hits++
                $data.lastAccess = Get-Date

                if ($cacheConfig.level1.enabled) {
                    $cacheStore.level1[$cacheKey] = @{
                        data = $data.value
                        expiry = $data.expiry
                        hits = 0
                        lastAccess = $data.lastAccess
                    }
                }

                return @{
                    value = $data.value
                    level = "L3"
                    hits = $data.hits
                }
            }
            else {
                Remove-Item $cacheFile -Force
            }
        }
    }

    return $null
}

# 设置缓存
function Set-Cache {
    param(
        [string]$Key,
        $Value,
        [int]$TTL = 0,
        [string[]]$Args = @()
    )

    if (-not $cacheConfig.enabled) {
        return
    }

    $cacheKey = Get-CacheKey -Key $Key -Args $Args

    if ($TTL -le 0) {
        $TTL = $cacheConfig.level1.ttl
    }

    $expiry = (Get-Date).AddSeconds($TTL)

    # L1缓存
    if ($cacheConfig.level1.enabled) {
        if ($cacheStore.level1.ContainsKey($cacheKey)) {
            $cacheStore.level1[$cacheKey].value = $Value
            $cacheStore.level1[$cacheKey].expiry = $expiry
        }
        else {
            $cacheStore.level1[$cacheKey] = @{
                data = $Value
                expiry = $expiry
                hits = 0
                lastAccess = Get-Date
            }

            if ($cacheStore.level1.Count -gt $cacheConfig.level1.maxSize) {
                $oldest = $cacheStore.level1.GetEnumerator() |
                          Sort-Object -Property Value.expiry |
                          Select-Object -First 1
                $oldest.Key | Remove-Variable -Scope 0
            }
        }
    }

    # L2缓存
    if ($cacheConfig.level2.enabled) {
        $cacheFile = Join-Path $PWD $cacheConfig.level2.path "${cacheKey}.json"

        $data = @{
            value = $Value
            expiry = $expiry
            created = Get-Date
            lastAccess = Get-Date
            hits = 0
        }

        $data | ConvertTo-Json -Depth 10 | Set-Content $cacheFile -Encoding UTF8
    }

    # L3缓存
    if ($cacheConfig.level3.enabled) {
        $cacheFile = Join-Path $PWD $cacheConfig.level3.path "${cacheKey}.json"

        $data = @{
            value = $Value
            expiry = $expiry
            created = Get-Date
            lastAccess = Get-Date
            hits = 0
        }

        $data | ConvertTo-Json -Depth 10 | Set-Content $cacheFile -Encoding UTF8
    }
}

# 删除缓存
function Remove-Cache {
    param(
        [string]$Key,
        [string[]]$Args = @()
    )

    $cacheKey = Get-CacheKey -Key $Key -Args $Args

    # L1
    if ($cacheStore.level1.ContainsKey($cacheKey)) {
        $cacheStore.level1.Remove($cacheKey)
    }

    # L2
    if ($cacheConfig.level2.enabled) {
        $cacheFile = Join-Path $PWD $cacheConfig.level2.path "${cacheKey}.json"
        if (Test-Path $cacheFile) {
            Remove-Item $cacheFile -Force
        }
    }

    # L3
    if ($cacheConfig.level3.enabled) {
        $cacheFile = Join-Path $PWD $cacheConfig.level3.path "${cacheKey}.json"
        if (Test-Path $cacheFile) {
            Remove-Item $cacheFile -Force
        }
    }
}

# 清理过期缓存
function Clear-ExpiredCache {
    $now = Get-Date

    # L1
    foreach ($key in $cacheStore.level1.Keys) {
        if ($cacheStore.level1[$key].expiry -lt $now) {
            $cacheStore.level1.Remove($key)
        }
    }

    # L2
    if ($cacheConfig.level2.enabled) {
        $cachePath = Join-Path $PWD $cacheConfig.level2.path
        $files = Get-ChildItem -Path $cachePath -Filter "*.json"

        foreach ($file in $files) {
            $data = Get-Content $file.FullName -Raw | ConvertFrom-Json
            if ($data.expiry -lt $now) {
                Remove-Item $file.FullName -Force
            }
        }
    }

    # L3
    if ($cacheConfig.level3.enabled) {
        $cachePath = Join-Path $PWD $cacheConfig.level3.path
        $files = Get-ChildItem -Path $cachePath -Filter "*.json"

        foreach ($file in $files) {
            $data = Get-Content $file.FullName -Raw | ConvertFrom-Json
            if ($data.expiry -lt $now) {
                Remove-Item $file.FullName -Force
            }
        }
    }

    Write-Host "Expired cache cleared" -ForegroundColor Green
}

# 清空所有缓存
function Clear-Cache {
    param(
        [string]$Level = "all"
    )

    if ($Level -eq "all" -or $Level -eq "L1") {
        $cacheStore.level1 = @{}
    }

    if ($Level -eq "all" -or $Level -eq "L2") {
        if ($cacheConfig.level2.enabled) {
            $cachePath = Join-Path $PWD $cacheConfig.level2.path
            if (Test-Path $cachePath) {
                Remove-Item $cachePath -Recurse -Force
                New-Item -ItemType Directory -Path $cachePath -Force | Out-Null
            }
        }
    }

    if ($Level -eq "all" -or $Level -eq "L3") {
        if ($cacheConfig.level3.enabled) {
            $cachePath = Join-Path $PWD $cacheConfig.level3.path
            if (Test-Path $cachePath) {
                Remove-Item $cachePath -Recurse -Force
                New-Item -ItemType Directory -Path $cachePath -Force | Out-Null
            }
        }
    }

    Write-Host "Cache cleared" -ForegroundColor Green
}

# 获取缓存统计
function Get-CacheStats {
    $stats = [PSCustomObject]@{
        level1 = @{
            enabled = $cacheConfig.level1.enabled
            size = $cacheStore.level1.Count
            maxSize = $cacheConfig.level1.maxSize
            hits = ($cacheStore.level1.Values | Measure-Object -Property hits -Sum).Sum
        }
        level2 = @{
            enabled = $cacheConfig.level2.enabled
            size = 0
            maxSize = $cacheConfig.level2.maxSize
        }
        level3 = @{
            enabled = $cacheConfig.level3.enabled
            size = 0
            maxSize = $cacheConfig.level3.maxSize
        }
        totalHits = 0
    }

    $stats.level2.size = (Get-ChildItem -Path (Join-Path $PWD $cacheConfig.level2.path) -Filter "*.json" |
                          Measure-Object).Count

    $stats.level3.size = (Get-ChildItem -Path (Join-Path $PWD $cacheConfig.level3.path) -Filter "*.json" |
                          Measure-Object).Count

    $stats.totalHits = $stats.level1.hits

    return $stats
}

# 缓存预热
function Warm-Cache {
    param(
        [scriptblock]$Provider,
        [int]$Count = 10,
        [string[]]$Keys = @()
    )

    if ($Keys.Count -gt 0) {
        foreach ($key in $Keys) {
            $value = & $Provider $key
            Set-Cache -Key $key -Value $value
        }
    }
    else {
        for ($i = 0; $i -lt $Count; $i++) {
            $key = "warm-key-$i"
            $value = & $Provider $key
            Set-Cache -Key $key -Value $value
        }
    }

    Write-Host "Cache warmed" -ForegroundColor Green
}

# 命令行接口
function Show-Usage {
    Write-Host @"
Usage:
  Initialize-Cache -Force

  Get-Cache -Key "skills" -Args @("all", "code")

  Set-Cache -Key "skills" -Value @(...) -TTL 300

  Remove-Cache -Key "skills"

  Clear-Cache -Level "L1"
  Clear-Cache

  Get-CacheStats

  Warm-Cache -Provider { param($k) return @{test = $k} }

Examples:
  Get-Cache -Key "skills"
  Set-Cache -Key "test" -Value @{data = 123}
  Clear-Cache
"@
}

# 默认执行
if ($args.Count -gt 0) {
    $cmd = $args[0]

    switch ($cmd) {
        "init" {
            Initialize-Cache -Force:$($args.Contains("-Force"))
        }
        "get" {
            $key = $args[1]
            $args = @($args[2 .. ($args.Count - 1)])
            $result = Get-Cache -Key $key -Args $args
            if ($result) {
                Write-Host "Level: $($result.level), Hits: $($result.hits)" -ForegroundColor Cyan
                Write-Host "Value: $($result.value)" -ForegroundColor White
            }
        }
        "set" {
            # 简化示例
            Write-Host "Use PowerShell directly for set operations"
        }
        "clear" {
            $level = if ($args.Count -gt 1) { $args[1] } else { "all" }
            Clear-Cache -Level $level
        }
        "stats" {
            $stats = Get-CacheStats
            Write-Host "=== Cache Statistics ===" -ForegroundColor Cyan
            Write-Host "Level 1: $($stats.level1.size)/$($stats.level1.maxSize) items" -ForegroundColor White
            Write-Host "Level 2: $($stats.level2.size)/$($stats.level2.maxSize) items" -ForegroundColor White
            Write-Host "Level 3: $($stats.level3.size)/$($stats.level3.maxSize) items" -ForegroundColor White
            Write-Host "Total Hits: $($stats.totalHits)" -ForegroundColor Gray
        }
        default {
            Show-Usage
        }
    }
}
