# Heartbeat整合增强系统

# @Author: 灵眸
# @Version: 1.0.0
# @Date: 2026-02-13

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("add", "remove", "list", "start", "stop", "status", "complete")]
    [string]$Action,

    [Parameter(Mandatory=$true)]
    [string]$TaskName,

    [Parameter(Mandatory=$false)]
    [string]$Category = "general",

    [Parameter(Mandatory=$false)]
    [ValidateSet("high", "medium", "low")]
    [string]$Priority = "medium",

    [Parameter(Mandatory=$false)]
    [string]$DueDate = "",

    [Parameter(Mandatory=$false)]
    [string]$Description = "",

    [Parameter(Mandatory=$false)]
    [switch]$Background = $false,

    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false
)

# 获取脚本路径
$ScriptPath = $PSScriptRoot
$TasksFile = "$ScriptPath/data/tasks.json"
$MemoryFile = "$ScriptPath/../../memory/YYYY-MM-DD.md"

# 初始化结果
$Result = @{
    Success = $false
    Action = $Action
    TaskName = $TaskName
    Category = $Category
    Priority = $Priority
    StartTime = Get-Date
    EndTime = $null
    Duration = 0
    Messages = @()
    Errors = @()
    TasksAdded = 0
    TasksCompleted = 0
}

# 日志函数
function Write-Log {
    param([string]$Message, [ValidateSet("INFO", "SUCCESS", "ERROR", "WARNING", "DEBUG")]
    [string]$Level = "INFO")

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Prefix = "[$Timestamp] [$Level]"

    switch ($Level) {
        "INFO"    { Write-Host "$Prefix $Message" -ForegroundColor Cyan }
        "SUCCESS" { Write-Host "$Prefix $Message" -ForegroundColor Green }
        "ERROR"   { Write-Host "$Prefix $Message" -ForegroundColor Red }
        "WARNING" { Write-Host "$Prefix $Message" -ForegroundColor Yellow }
        "DEBUG"   { Write-Host "$Prefix $Message" -ForegroundColor DarkGray }
    }

    $Result.Messages += "$Prefix $Message"
}

try {
    Write-Log "Heartbeat整合增强系统启动" "INFO"
    Write-Log "Action: $Action" "DEBUG"
    Write-Log "Task: $TaskName" "DEBUG"

    # 加载任务队列
    if (-not (Test-Path $TasksFile)) {
        $TaskQueue = @()
    } else {
        $TaskQueue = Get-Content -Path $TasksFile | ConvertFrom-Json
    }

    switch ($Action) {
        "add" {
            Write-Log "添加任务..." "INFO"

            if ($DryRun) {
                Write-Log "Dry Run 模式：不添加任务" "DEBUG"
                $Result.TasksAdded = 1
                $Result.Success = $true
                return $Result
            }

            # 创建任务对象
            $NewTask = @{
                id = [guid]::NewGuid().ToString()
                name = $TaskName
                category = $Category
                priority = $Priority
                description = $Description
                status = "pending"
                createdAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                dueDate = $DueDate
                attempts = 0
                metadata = @{}
            }

            # 添加到队列
            $TaskQueue += $NewTask

            # 保存队列
            $TaskQueue | ConvertTo-Json -Depth 10 | Out-File -FilePath $TasksFile -Encoding UTF8 -Force

            # 同时记录到记忆文件
            $MemoryNote = @"
# Heartbeat主动任务

## 任务详情
- **名称**: $TaskName
- **类别**: $Category
- **优先级**: $Priority
- **状态**: pending
- **创建时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
- **到期时间**: $DueDate
- **描述**: $Description

---

"@

            $MemoryNote | Out-File -FilePath $MemoryFile -Append -Encoding UTF8 -Force

            $Result.TasksAdded = 1
            $Result.Success = $true

            Write-Log "任务添加成功" "SUCCESS"
            Write-Log "任务ID: $($NewTask.id)" "DEBUG"

        }

        "list" {
            Write-Log "列出任务..." "INFO"

            if ($TaskQueue.Count -eq 0) {
                Write-Log "任务队列为空" "WARNING"
            } else {
                # 按优先级排序
                $PriorityOrder = @{ "high" = 1; "medium" = 2; "low" = 3 }
                $SortedTasks = $TaskQueue | Sort-Object { $PriorityOrder[$_.priority] }

                Write-Host "`n========== 任务列表 ==========" "INFO"
                foreach ($Task in $SortedTasks) {
                    $StatusIcon = switch ($Task.status) {
                        "pending" { "⏳" }
                        "in-progress" { "🔄" }
                        "completed" { "✅" }
                        "failed" { "❌" }
                    }

                    $PriorityIcon = switch ($Task.priority) {
                        "high" { "🔴" }
                        "medium" { "🟡" }
                        "low" { "🟢" }
                    }

                    Write-Host "`n$StatusIcon $PriorityIcon $($Task.name)" "INFO"
                    Write-Host "  ID: $($Task.id)" "DEBUG"
                    Write-Host "  状态: $($Task.status)" "DEBUG"
                    Write-Host "  优先级: $($Task.priority)" "DEBUG"
                    Write-Host "  类别: $($Task.category)" "DEBUG"
                    Write-Host "  创建时间: $($Task.createdAt)" "DEBUG"

                    if ($Task.dueDate) {
                        Write-Host "  到期时间: $($Task.dueDate)" "DEBUG"
                    }

                    if ($Task.description) {
                        Write-Host "  描述: $($Task.description)" "DEBUG"
                    }
                }
                Write-Host "`n总计: $($TaskQueue.Count) 个任务" "INFO"
                Write-Host "================================" "INFO"
            }

            $Result.Success = $true
        }

        "start" {
            Write-Log "开始任务..." "INFO"

            if ($DryRun) {
                Write-Log "Dry Run 模式：不启动任务" "DEBUG"
                $Result.Success = $true
                return $Result
            }

            # 查找任务
            $Task = $TaskQueue | Where-Object { $_.name -eq $TaskName }

            if (-not $Task) {
                throw "任务不存在: $TaskName"
            }

            # 更新任务状态
            $Task.status = "in-progress"
            $Task.startedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

            # 更新队列
            $TaskQueue | ConvertTo-Json -Depth 10 | Out-File -FilePath $TasksFile -Encoding UTF8 -Force

            Write-Log "任务启动成功" "SUCCESS"
            Write-Log "任务ID: $($Task.id)" "DEBUG"
            Write-Log "开始时间: $($Task.startedAt)" "DEBUG"

            # 记录到记忆文件
            $MemoryNote = @"
# Heartbeat主动任务执行

## 任务执行
- **名称**: $TaskName
- **状态**: in-progress
- **开始时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
- **任务ID**: $($Task.id)

---

"@

            $MemoryNote | Out-File -FilePath $MemoryFile -Append -Encoding UTF8 -Force

            $Result.Success = $true
        }

        "complete" {
            Write-Log "完成任务..." "INFO"

            if ($DryRun) {
                Write-Log "Dry Run 模式：不完成任务" "DEBUG"
                $Result.Success = $true
                return $Result
            }

            # 查找任务
            $Task = $TaskQueue | Where-Object { $_.name -eq $TaskName }

            if (-not $Task) {
                throw "任务不存在: $TaskName"
            }

            # 更新任务状态
            $Task.status = "completed"
            $Task.completedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

            # 更新队列
            $TaskQueue | ConvertTo-Json -Depth 10 | Out-File -FilePath $TasksFile -Encoding UTF8 -Force

            $Result.TasksCompleted = 1
            $Result.Success = $true

            Write-Log "任务完成成功" "SUCCESS"
            Write-Log "任务ID: $($Task.id)" "DEBUG"
            Write-Log "完成时间: $($Task.completedAt)" "DEBUG"

            # 记录到记忆文件
            $MemoryNote = @"
# Heartbeat主动任务完成

## 任务完成
- **名称**: $TaskName
- **状态**: completed
- **完成时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
- **任务ID**: $($Task.id)

---

"@

            $MemoryNote | Out-File -FilePath $MemoryFile -Append -Encoding UTF8 -Force

        }

        "status" {
            Write-Log "检查任务状态..." "INFO"

            # 查找任务
            $Task = $TaskQueue | Where-Object { $_.name -eq $TaskName }

            if (-not $Task) {
                Write-Log "任务不存在: $TaskName" "ERROR"
                $Result.Success = $false
                return $Result
            }

            Write-Host "`n========== 任务状态 ==========" "INFO"
            Write-Host "名称: $($Task.name)" "INFO"
            Write-Host "ID: $($Task.id)" "DEBUG"
            Write-Host "状态: $($Task.status)" "INFO"
            Write-Host "优先级: $($Task.priority)" "INFO"
            Write-Host "类别: $($Task.category)" "INFO"
            Write-Host "创建时间: $($Task.createdAt)" "DEBUG"

            if ($Task.dueDate) {
                Write-Host "到期时间: $($Task.dueDate)" "DEBUG"
            }

            if ($Task.startedAt) {
                Write-Host "开始时间: $($Task.startedAt)" "DEBUG"
            }

            if ($Task.completedAt) {
                Write-Host "完成时间: $($Task.completedAt)" "DEBUG"
            }

            if ($Task.description) {
                Write-Host "描述: $($Task.description)" "INFO"
            }

            # 检查是否逾期
            if ($Task.dueDate -and $Task.status -ne "completed") {
                $DueDate = [DateTime]::Parse($Task.dueDate)
                if ([DateTime]::Now -gt $DueDate) {
                    Write-Host "`n⚠️ 任务已逾期!" "WARNING"
                } else {
                    $Remaining = ($DueDate - [DateTime]::Now).TotalHours
                    Write-Host "`n⏰ 剩余时间: $([math]::Round($Remaining, 2)) 小时" "INFO"
                }
            }

            Write-Host "================================" "INFO"

            $Result.Success = $true
        }

        "remove" {
            Write-Log "移除任务..." "INFO"

            if ($DryRun) {
                Write-Log "Dry Run 模式：不移除任务" "DEBUG"
                $Result.Success = $true
                return $Result
            }

            # 查找并移除任务
            $TaskQueue = $TaskQueue | Where-Object { $_.name -ne $TaskName }

            # 更新队列
            $TaskQueue | ConvertTo-Json -Depth 10 | Out-File -FilePath $TasksFile -Encoding UTF8 -Force

            Write-Log "任务移除成功" "SUCCESS"
            Write-Log "任务名称: $TaskName" "DEBUG"

            # 记录到记忆文件
            $MemoryNote = @"
# Heartbeat主动任务移除

## 任务移除
- **名称**: $TaskName
- **移除时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

---

"@

            $MemoryNote | Out-File -FilePath $MemoryFile -Append -Encoding UTF8 -Force

            $Result.Success = $true
        }

        "stop" {
            Write-Log "停止任务..." "INFO"

            if ($DryRun) {
                Write-Log "Dry Run 模式：不停止任务" "DEBUG"
                $Result.Success = $true
                return $Result
            }

            # 查找任务
            $Task = $TaskQueue | Where-Object { $_.name -eq $TaskName }

            if (-not $Task) {
                throw "任务不存在: $TaskName"
            }

            # 检查状态
            if ($Task.status -ne "in-progress") {
                throw "任务未在运行中: $TaskName"
            }

            # 更新任务状态
            $Task.status = "pending"
            $Task.attempts++

            # 更新队列
            $TaskQueue | ConvertTo-Json -Depth 10 | Out-File -FilePath $TasksFile -Encoding UTF8 -Force

            Write-Log "任务停止成功" "SUCCESS"
            Write-Log "任务ID: $($Task.id)" "DEBUG"
            Write-Log "重试次数: $($Task.attempts)" "DEBUG"

            $Result.Success = $true
        }
    }

    # 设置最终状态
    $Result.EndTime = Get-Date
    $Result.Duration = ($Result.EndTime - $Result.StartTime).TotalSeconds

    Write-Log "操作完成" "SUCCESS"
    Write-Log "执行时间: $([math]::Round($Result.Duration, 2))秒" "SUCCESS"

} catch {
    $Result.Success = $false
    $Result.Errors += $_.Exception.Message
    $Result.Errors += $_.ScriptStackTrace

    Write-Log "操作失败: $($_.Exception.Message)" "ERROR"

    # 创建错误日志
    $ErrorLog = "$ScriptPath/data/errors/task-error-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    $ErrorLogContent = @"
Heartbeat整合增强系统错误报告
错误时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
操作: $Action
任务: $TaskName
错误信息: $($_.Exception.Message)
堆栈跟踪:
$($_.ScriptStackTrace)

"@

    $ErrorLogContent | Out-File -FilePath $ErrorLog -Encoding UTF8 -Force

    Write-Log "错误日志已保存: $ErrorLog" "WARNING"

} finally {
    return $Result
}
