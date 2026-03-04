# 灵眸错误记录脚本
# 用于记录、分类和处理错误

$ErrorLogPath = "error-log.json"
$DatabasePath = "error-database.json"

function Add-Error {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Type,
        [string]$Message,
        [string]$Source,
        [hashtable]$Context = @{},
        [string]$RecoveryAction = "pending",
        [bool]$AutoRecovery = $false
    )

    # 加载数据库
    $database = Get-Content $DatabasePath -Raw | ConvertFrom-Json

    # 创建错误记录
    $errorRecord = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        error_type = $Type
        message = $Message
        source = $Source
        context = $Context
        recovery_status = $RecoveryAction
        auto_recovery = $AutoRecovery
        attempt = 1
        recovered_at = $null
    }

    # 添加到历史记录
    $database.error_history.Add($errorRecord)
    $database.stats.total_errors++

    # 更新统计
    if ($AutoRecovery) {
        $database.stats.recovered_errors++
        $errorRecord.recovered_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    } else {
        $database.stats.failed_recoveries++
    }

    # 保存数据库
    $database | ConvertTo-Json -Depth 10 | Set-Content $DatabasePath

    # 触发错误分类和策略匹配
    Invoke-ErrorClassification -ErrorRecord $errorRecord -Database $database

    # 如果未恢复，尝试自动修复
    if (-not $AutoRecovery) {
        Invoke-RecoveryStrategy -ErrorRecord $errorRecord -Database $database
    }

    # 返回错误记录
    return $errorRecord
}

function Invoke-ErrorClassification {
    param(
        [Parameter(Mandatory=$true)]
        $ErrorRecord,
        [Parameter(Mandatory=$true)]
        $Database
    )

    # 获取错误类型配置
    $typeConfig = $database.error_categories.($ErrorRecord.error_type)

    if ($typeConfig) {
        # 记录检测方法
        foreach ($method in $typeConfig.detection_methods) {
            $ErrorRecord.detected_by = $method
            break
        }

        # 记录学习机制
        $ErrorRecord.learning_mechanism = $typeConfig.learning_mechanism
    }

    # 审计数据库
    $Database.last_audit = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Database | ConvertTo-Json -Depth 10 | Set-Content $DatabasePath
}

function Invoke-RecoveryStrategy {
    param(
        [Parameter(Mandatory=$true)]
        $ErrorRecord,
        [Parameter(Mandatory=$true)]
        $Database
    )

    $typeConfig = $database.error_categories.($ErrorRecord.error_type)

    if ($typeConfig) {
        # 优先级从高到低尝试恢复策略
        foreach ($strategy in $typeConfig.recovery_strategies) {
            switch ($strategy) {
                "retry_3_times" {
                    # 实现重试逻辑
                    $ErrorRecord.recovery_status = "retrying"
                    Write-Host "[ERROR] $($ErrorRecord.error_type): $($ErrorRecord.message) - Retrying..." -ForegroundColor Yellow
                    # 实际重试逻辑需要调用上层函数
                    break
                }
                "fallback_to_caching" {
                    # 缓存降级
                    $ErrorRecord.recovery_status = "fallback"
                    Write-Host "[ERROR] $($ErrorRecord.error_type): $($ErrorRecord.message) - Using cache fallback" -ForegroundColor Yellow
                    break
                }
                "state_compression" {
                    # 状态压缩
                    $ErrorRecord.recovery_status = "compressed"
                    Write-Host "[ERROR] $($ErrorRecord.error_type): $($ErrorRecord.message) - Compressing state" -ForegroundColor Yellow
                    break
                }
                "notify_user" {
                    # 通知用户
                    $ErrorRecord.recovery_status = "user_notification"
                    Write-Host "[ERROR] $($ErrorRecord.error_type): $($ErrorRecord.message) - Notifying user" -ForegroundColor Yellow
                    break
                }
                default {
                    # 其他策略（队列、降级等）
                    $ErrorRecord.recovery_status = "active"
                    break
                }
            }
        }
    }

    # 更新数据库
    $Database | ConvertTo-Json -Depth 10 | Set-Content $DatabasePath
}

function Get-ErrorStats {
    param(
        [Parameter(Mandatory=$true)]
        $Database
    )

    return @{
        total = $Database.stats.total_errors
        recovered = $Database.stats.recovered_errors
        failed = $Database.stats.failed_recoveries
        rate = if ($Database.stats.total_errors -gt 0) {
            [math]::Round(($Database.stats.recovered_errors / $Database.stats.total_errors) * 100, 2)
        } else {
            0
        }
    }
}

function Clear-OldErrors {
    param(
        [int]$DaysToKeep = 7
    )

    $Database = Get-Content $DatabasePath -Raw | ConvertFrom-Json
    $cutoffDate = (Get-Date).AddDays(-$DaysToKeep)

    $Database.error_history = $Database.error_history |
        Where-Object { [DateTime]::Parse($_.timestamp) -gt $cutoffDate }

    $Database | ConvertTo-Json -Depth 10 | Set-Content $DatabasePath

    Write-Host "[CLEANUP] Old errors older than $DaysToKeep days removed"
}

# 导出函数供其他脚本调用
Export-ModuleMember -Function Add-Error, Get-ErrorStats, Clear-OldErrors
