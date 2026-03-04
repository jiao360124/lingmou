<#
.SYNOPSIS
Resource Manager

.DESCRIPTION
资源管理器，实现内存池、连接池

.NOTES
Author: OpenClaw Assistant
Date: 2026-02-16
Version: 1.0.0
#>

# 资源配置
$resourceConfig = @{
    connectionPool = @{
        enabled = $true
        maxSize = 10
        minSize = 2
        timeout = 30000
    }
    memoryPool = @{
        enabled = $true
        maxSize = 100 * 1024 * 1024  # 100MB
        minSize = 10 * 1024 * 1024  # 10MB
    }
    taskPool = @{
        enabled = $true
        maxSize = 1000
        minSize = 100
    }
}

# 连接池
$connectionPool = @{}

# 内存池
$memoryPool = @{}

# 任务池
$taskPool = @{}

# 初始化资源管理器
function Initialize-ResourceManager {
    param(
        [bool]$Force = $false
    )

    if (-not $resourceConfig.connectionPool.enabled) {
        Write-Host "Connection pool is disabled" -ForegroundColor Yellow
    }
    else {
        Write-Host "Connection pool initialized" -ForegroundColor Green
    }

    if (-not $resourceConfig.memoryPool.enabled) {
        Write-Host "Memory pool is disabled" -ForegroundColor Yellow
    }
    else {
        Write-Host "Memory pool initialized" -ForegroundColor Green
    }

    if ($Force) {
        Clear-AllResources
    }
}

# 获取连接
function Get-Connection {
    param(
        [string]$Type,
        [hashtable]$Parameters = @{}
    )

    if (-not $resourceConfig.connectionPool.enabled) {
        return $null
    }

    $poolKey = "$Type:$($Parameters.PSObject.Properties | ForEach-Object { "$($_.Name)=$($_.Value)" } -join ':')"

    # 检查池中是否有可用连接
    if ($connectionPool.ContainsKey($poolKey)) {
        $pool = $connectionPool[$poolKey]

        if ($pool.connections.Count -gt 0) {
            $conn = $pool.connections[0]
            $pool.connections.RemoveAt(0)

            Write-Host "Connection acquired from pool ($Type)" -ForegroundColor Cyan
            return @{
                connection = $conn
                type = $Type
                parameters = $Parameters
                fromPool = $true
            }
        }
    }

    # 创建新连接
    $conn = Create-Connection -Type $Type -Parameters $Parameters

    Write-Host "New connection created ($Type)" -ForegroundColor Green

    return @{
        connection = $conn
        type = $Type
        parameters = $Parameters
        fromPool = $false
    }
}

# 释放连接
function Release-Connection {
    param(
        [string]$Type,
        $Connection,
        [hashtable]$Parameters = @{}
    )

    if (-not $resourceConfig.connectionPool.enabled) {
        return
    }

    $poolKey = "$Type:$($Parameters.PSObject.Properties | ForEach-Object { "$($_.Name)=$($_.Value)" } -join ':')"

    if (-not $connectionPool.ContainsKey($poolKey)) {
        $connectionPool[$poolKey] = @{
            maxSize = $resourceConfig.connectionPool.maxSize
            size = 0
            connections = @()
        }
    }

    $pool = $connectionPool[$poolKey]

    # 检查是否超过最大限制
    if ($pool.size -ge $pool.maxSize) {
        # 销毁最旧的连接
        $oldest = $pool.connections[0]
        Destroy-Connection -Connection $oldest
        $pool.connections.RemoveAt(0)
        $pool.size--
    }

    # 添加连接回池
    $pool.connections += $Connection
    $pool.size++

    Write-Host "Connection released to pool ($Type)" -ForegroundColor Yellow
}

# 创建连接
function Create-Connection {
    param(
        [string]$Type,
        [hashtable]$Parameters = @{}
    )

    $connection = [PSCustomObject]@{
        id = [guid]::NewGuid().ToString()
        type = $Type
        parameters = $Parameters
        created = Get-Date
        lastUsed = Get-Date
        state = "active"
    }

    return $connection
}

# 销毁连接
function Destroy-Connection {
    param($Connection)

    # 这里是连接清理逻辑
    Write-Host "Connection destroyed" -ForegroundColor Red
}

# 获取内存
function Get-Memory {
    param(
        [int]$Size,
        [int]$Timeout = 5000
    )

    if (-not $resourceConfig.memoryPool.enabled) {
        # 直接分配内存
        return New-Object byte[] $Size
    }

    if ($memoryPool.ContainsKey($Size)) {
        $pool = $memoryPool[$Size]

        if ($pool.count -gt 0) {
            $buffer = $pool[0]
            $pool.RemoveAt(0)

            Write-Host "Memory buffer acquired from pool ($Size bytes)" -ForegroundColor Cyan

            return $buffer
        }
    }

    # 创建新内存
    $buffer = New-Object byte[] $Size

    Write-Host "New memory buffer created ($Size bytes)" -ForegroundColor Green

    return $buffer
}

# 释放内存
function Release-Memory {
    param(
        [byte[]]$Buffer,
        [int]$Size
    )

    if (-not $resourceConfig.memoryPool.enabled) {
        return
    }

    if ($Size -gt $resourceConfig.memoryPool.maxSize) {
        return
    }

    if (-not $memoryPool.ContainsKey($Size)) {
        $memoryPool[$Size] = @()
    }

    # 限制内存池大小
    if ($memoryPool[$Size].Count -gt 10) {
        $memoryPool[$Size] = $memoryPool[$Size][0..9]
    }

    $memoryPool[$Size] += $Buffer

    Write-Host "Memory buffer released to pool ($Size bytes)" -ForegroundColor Yellow
}

# 获取任务
function Get-Task {
    param(
        [scriptblock]$ScriptBlock,
        [int]$Priority = 0
    )

    if (-not $resourceConfig.taskPool.enabled) {
        return New-Object PSObject -Property @{
            id = [guid]::NewGuid().ToString()
            scriptBlock = $ScriptBlock
            priority = $Priority
            status = "available"
        }
    }

    if ($taskPool.Count -gt 0) {
        $task = $taskPool[0]
        $taskPool.RemoveAt(0)

        return $task
    }

    return New-Object PSObject -Property @{
        id = [guid]::NewGuid().ToString()
        scriptBlock = $ScriptBlock
        priority = $Priority
        status = "available"
    }
}

# 释放任务
function Release-Task {
    param($Task)

    if (-not $resourceConfig.taskPool.enabled) {
        return
    }

    if ($taskPool.Count -gt $resourceConfig.taskPool.maxSize) {
        return
    }

    $taskPool += $Task
}

# 资源统计
function Get-ResourceStats {
    $stats = [PSCustomObject]@{
        connections = @{}
        memory = @{
            poolSize = $memoryPool.Count
            totalSize = ($memoryPool.Values | Measure-Object -Property Count -Sum).Sum * 1024
            maxSize = $resourceConfig.memoryPool.maxSize
        }
        tasks = @{
            poolSize = $taskPool.Count
            maxSize = $resourceConfig.taskPool.maxSize
        }
    }

    foreach ($key in $connectionPool.Keys) {
        $pool = $connectionPool[$key]
        $stats.connections[$key] = @{
            available = $pool.size
            total = $pool.size + $pool.connections.Count
            maxSize = $pool.maxSize
        }
    }

    return $stats
}

# 清空所有资源
function Clear-AllResources {
    $connectionPool = @{}
    $memoryPool = @{}
    $taskPool = @{}

    Write-Host "All resources cleared" -ForegroundColor Green
}

# 资源泄漏检测
function Test-ResourceLeaks {
    $leaks = @()

    foreach ($key in $connectionPool.Keys) {
        $pool = $connectionPool[$key]

        if ($pool.size -gt 0 -or $pool.connections.Count -gt 0) {
            $leaks += [PSCustomObject]@{
                type = "Connection Pool"
                key = $key
                available = $pool.size
                inUse = $pool.connections.Count
                maxSize = $pool.maxSize
            }
        }
    }

    foreach ($size in $memoryPool.Keys) {
        if ($memoryPool[$size].Count -gt 10) {
            $leaks += [PSCustomObject]@{
                type = "Memory Pool"
                size = $size
                count = $memoryPool[$size].Count
                limit = 10
            }
        }
    }

    return $leaks
}

# 命令行接口
function Show-Usage {
    Write-Host @"
Usage:
  Initialize-ResourceManager -Force

  Get-Connection -Type "database" -Parameters @{host="localhost"}
  Release-Connection -Type "database" -Connection $conn

  Get-Memory -Size 1024
  Release-Memory -Buffer $buffer -Size 1024

  Get-Task -ScriptBlock { ... } -Priority 5
  Release-Task -Task $task

  Get-ResourceStats
  Test-ResourceLeaks

Examples:
  $conn = Get-Connection -Type "database" -Parameters @{host="localhost"}
  # 使用连接
  Release-Connection -Type "database" -Connection $conn.connection
"@
}

# 默认执行
if ($args.Count -gt 0) {
    $cmd = $args[0]

    switch ($cmd) {
        "init" {
            Initialize-ResourceManager -Force:$($args.Contains("-Force"))
        }
        "stats" {
            $stats = Get-ResourceStats
            Write-Host "=== Resource Statistics ===" -ForegroundColor Cyan
            Write-Host "Memory: $($stats.memory.totalSize / 1024 / 1024)MB / $($stats.memory.maxSize / 1024 / 1024)MB" -ForegroundColor White
            Write-Host "Tasks: $($stats.tasks.poolSize)/$($stats.tasks.maxSize)" -ForegroundColor White
            Write-Host "Connections: $($stats.connections.Count) pools" -ForegroundColor White
        }
        "leaks" {
            $leaks = Test-ResourceLeaks
            if ($leaks.Count -gt 0) {
                Write-Host "=== Resource Leaks ===" -ForegroundColor Red
                foreach ($leak in $leaks) {
                    Write-Host "$($leak.type): $($leak)" -ForegroundColor White
                }
            }
            else {
                Write-Host "No resource leaks detected" -ForegroundColor Green
            }
        }
        default {
            Show-Usage
        }
    }
}
