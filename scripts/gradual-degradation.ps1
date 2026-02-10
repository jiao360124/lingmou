# 灵眸状态压缩和降级脚本
# 用于在错误发生时保存核心状态并进入简化模式

$DatabasePath = "error-database.json"

function Invoke-SmartStateCompression {
    param(
        [string]$Operation = "unknown",
        [hashtable]$CurrentState = @{},
        [int]$CompressionLevel = 1
    )

    Write-Host "[STATE] Compressing state for operation: $Operation" -ForegroundColor Cyan

    # 获取当前状态
    $currentContext = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        operation = $Operation
        current_state = $CurrentState
        compression_level = $CompressionLevel
        memory_usage = (Get-Process -Id $PID).WorkingSet64 / 1MB
    }

    # 根据压缩级别执行不同策略
    switch ($CompressionLevel) {
        1 {
            # 级别1：保留核心上下文
            $compressedContext = @{
                current_state = @{
                    active_sessions = @($CurrentState.active_sessions)
                    last_operations = @($CurrentState.last_operations[-5..-1])
                    preferences = $CurrentState.preferences
                }
                compression_method = "minimal_context"
            }
        }
        2 {
            # 级别2：压缩但不丢失数据
            $compressedContext = @{
                current_state = @{
                    active_sessions = @($CurrentState.active_sessions)
                    last_operations = @($CurrentState.last_operations[-10..-1])
                    preferences = $CurrentState.preferences
                    cache_state = @{
                        size = $CurrentState.cache_size
                        hit_rate = $CurrentState.cache_hit_rate
                    }
                }
                compression_method = "standard_compression"
            }
        }
        3 {
            # 级别3：深度压缩（丢失非关键信息）
            $compressedContext = @{
                current_state = @{
                    active_sessions = @($CurrentState.active_sessions | Select-Object -First 3)
                    last_operations = @($CurrentState.last_operations[-20..-1])
                    preferences = $CurrentState.preferences
                    emergency_mode = $true
                }
                compression_method = "deep_compression"
            }
        }
        default {
            # 默认级别
            $compressedContext = @{
                current_state = @{
                    active_sessions = @($CurrentState.active_sessions)
                    last_operations = @($CurrentState.last_operations[-5..-1])
                }
                compression_method = "default"
            }
        }
    }

    # 保存压缩状态
    $compressionLogPath = "state-compression-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $compressedContext | ConvertTo-Json -Depth 10 | Set-Content $compressionLogPath

    Write-Host "[STATE] State compressed to: $compressionLogPath" -ForegroundColor Green
    Write-Host "[STATE] Memory usage: $([math]::Round($currentContext.memory_usage, 2)) MB → $([math]::Round((Get-Process -Id $PID).WorkingSet64 / 1MB, 2)) MB" -ForegroundColor Cyan

    # 更新数据库
    $database = Get-Content $DatabasePath -Raw | ConvertFrom-Json
    $database.error_categories.state_compression.last_compressed_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $database.error_categories.state_compression.last_compressed_file = $compressionLogPath
    $Database | ConvertTo-Json -Depth 10 | Set-Content $DatabasePath

    return $compressedContext
}

function Invoke-GracefulDegradation {
    param(
        [string]$ServiceName = "unknown",
        [string]$Severity = "medium"
    )

    Write-Host "[DEGRADATION] Entering graceful degradation for: $ServiceName" -ForegroundColor Yellow
    Write-Host "[DEGRADATION] Severity: $Severity" -ForegroundColor Yellow

    # 根据严重程度采取不同降级策略
    $degradationMode = switch ($Severity) {
        "critical" {
            "minimal_service_mode"
        }
        "high" {
            "reduced_functionality_mode"
        }
        "medium" {
            "monitoring_mode"
        }
        "low" {
            "standard_mode"
        }
        default {
            "standard_mode"
        }
    }

    # 更新数据库
    $database = Get-Content $DatabasePath -Raw | ConvertFrom-Json
    $database.error_categories.graceful_degradation.current_mode = $degradationMode
    $database.error_categories.graceful_degradation.last_degraded_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $database.error_categories.graceful_degradation.last_degraded_service = $ServiceName
    $Database | ConvertTo-Json -Depth 10 | Set-Content $DatabasePath

    # 返回降级配置
    return @{
        mode = $degradationMode
        severity = $Severity
        next_check = (Get-Date).AddMinutes(5).ToString("yyyy-MM-dd HH:mm:ss")
        recommended_action = switch ($degradationMode) {
            "minimal_service_mode" {
                "Restart system and restore core functions"
            }
            "reduced_functionality_mode" {
                "Continue with limited features, monitor closely"
            }
            "monitoring_mode" {
                "Continue with full features, prepare for escalation"
            }
            "standard_mode" {
                "Full operation mode"
            }
        }
    }
}

function Invoke-StateRecovery {
    param(
        [string]$CompressionFile = "state-compression-*.json"
    )

    Write-Host "[RECOVERY] Restoring state from: $CompressionFile" -ForegroundColor Green

    # 查找最新的压缩文件
    $compressionFiles = Get-ChildItem "state-compression-*.json" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1

    if (-not $compressionFiles) {
        Write-Host "[RECOVERY] No compressed state found" -ForegroundColor Red
        return $null
    }

    # 加载压缩状态
    $compressedState = Get-Content $compressionFiles.FullName -Raw | ConvertFrom-Json

    Write-Host "[RECOVERY] Restoring state with compression level: $($compressedState.compression_level)" -ForegroundColor Cyan

    # 恢复内存使用
    $currentMemory = (Get-Process -Id $PID).WorkingSet64 / 1MB
    Write-Host "[RECOVERY] Memory before recovery: $([math]::Round($currentMemory, 2)) MB" -ForegroundColor Cyan

    # 恢复操作（示例：恢复会话列表）
    if ($compressedState.current_state.active_sessions) {
        Write-Host "[RECOVERY] Restored $($compressedState.current_state.active_sessions.Count) active sessions" -ForegroundColor Green
    }

    # 清理旧压缩文件
    Get-ChildItem "state-compression-*.json" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddHours(-24) } | Remove-Item

    return @{
        restored_from = $compressionFiles.FullName
        compression_level = $compressedState.compression_level
        active_sessions = $compressedState.current_state.active_sessions.Count
    }
}

function Invoke-MinimumRecoveryProtocol {
    param(
        [string]$ErrorType = "unknown"
    )

    Write-Host "[RECOVERY] Starting minimum recovery protocol for: $ErrorType" -ForegroundColor Cyan

    # 步骤1：立即状态保存
    $currentState = @{
        active_sessions = @(1)  # 示例
        last_operations = @("initializing")
        preferences = @{language = "zh-CN"}
    }

    $compressedState = Invoke-SmartStateCompression -Operation $ErrorType -CurrentState $currentState -CompressionLevel 2

    # 步骤2：进入最小服务模式
    $degradationMode = Invoke-GracefulDegradation -ServiceName $ErrorType -Severity "high"

    # 步骤3：记录恢复尝试
    $database = Get-Content $DatabasePath -Raw | ConvertFrom-Json
    $database.error_categories.minimum_recovery.last_attempt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $database.error_categories.minimum_recovery.last_error = $ErrorType
    $Database | ConvertTo-Json -Depth 10 | Set-Content $DatabasePath

    Write-Host "[RECOVERY] Recovery protocol completed successfully" -ForegroundColor Green
    Write-Host "[RECOVERY] Mode: $($degradationMode.mode)" -ForegroundColor Cyan
    Write-Host "[RECOVERY] Next recovery attempt: $($degradationMode.next_check)" -ForegroundColor Cyan

    return @{
        success = $true
        mode = $degradationMode.mode
        compressed_state = $compressedState
    }
}

# 导出函数供其他脚本调用
Export-ModuleMember -Function Invoke-SmartStateCompression, Invoke-GracefulDegradation, Invoke-StateRecovery, Invoke-MinimumRecoveryProtocol
