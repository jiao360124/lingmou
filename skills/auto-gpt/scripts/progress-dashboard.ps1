# Auto-GPT Progress Dashboard - 可视化进度面板

<#
.SYNOPSIS
- 创建并显示Auto-GPT任务进度面板

.DESCRIPTION
- 任务状态展示、步骤进度条、实时日志、通知系统

.PARAMeter Task
- 任务信息对象

.PARAMeter Mode
- 显示模式（compact/full）

.OUTPUTS
- 进度面板JSON对象
#>

function Show-ProgressDashboard {
    param(
        [Parameter(Mandatory=$false)]
        $Task = $null,

        [Parameter(Mandatory=$false)]
        [string]$Mode = 'compact'
    )

    if (-not $Task) {
        $Task = Get-LastTask
    }

    $dashboard = Build-Dashboard -Task $Task -Mode $Mode

    return $dashboard
}

<#
.SYNOPSIS
- 构建进度面板

.DESCRIPTION
- 构建包含任务状态、进度、步骤的完整面板

.PARAMeter Task
- 任务对象

.PARAMeter Mode
- 显示模式

.OUTPUTS
- 进度面板对象
#>

function Build-Dashboard {
    param(
        [Parameter(Mandatory=$true)]
        $Task,

        [Parameter(Mandatory=$false)]
        [string]$Mode = 'compact'
    )

    $totalSteps = $Task.Steps.Count
    $completedSteps = ($Task.Steps | Where-Object { $_.Status -eq 'completed' }).Count
    $currentStepIndex = ($Task.Steps | Where-Object { $_.Status -eq 'in-progress' }).Index
    $progressPercentage = [math]::Round(($completedSteps / $totalSteps) * 100, 1)

    $dashboard = [PSCustomObject]@{
        taskId = $Task.Id
        taskName = $Task.Name
        status = $Task.Status
        totalSteps = $totalSteps
        completedSteps = $completedSteps
        currentStepIndex = $currentStepIndex
        progressPercentage = $progressPercentage

        # 步骤详情
        steps = @(
            $Task.Steps | ForEach-Object {
                [PSCustomObject]@{
                    id = $_.Id
                    name = $_.Name
                    status = $_.Status
                    index = $_.Index
                    duration = $_.Duration
                    error = $_.Error
                }
            }
        )

        # 实时日志
        logs = $Task.Logs

        # 统计信息
        statistics = [PSCustomObject]@{
            startedAt = $Task.StartedAt
            estimatedEndTime = $Task.EstimatedEndTime
            elapsedTime = $Task.ElapsedTime
            remainingTime = $Task.RemainingTime
            successRate = [math]::Round(($Task.SuccessCount / $Task.TotalExecutions) * 100, 1) -as [double]
        }

        # 通知
        notification = if ($progressPercentage % 20 -eq 0) {
            Generate-Notification -Progress $progressPercentage -Status $Task.Status
        } else {
            $null
        }
    }

    return $dashboard
}

<#
.SYNOPSIS
- 获取上次任务

.DESCRIPTION
- 从历史记录中获取上次执行的任务

.OUTPUTS
- 任务对象
#>

function Get-LastTask {
    $historyFile = "tasks\auto-gpt-history.json"

    if (Test-Path $historyFile) {
        $history = Get-Content $historyFile -Raw | ConvertFrom-Json
        return $history | Sort-Object -Property startedAt -Descending | Select-Object -First 1
    }

    # 创建示例任务
    return [PSCustomObject]@{
        Id = "task-$(Get-Random-Id)"
        Name = "示例任务"
        Status = "in-progress"
        StartedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        ElapsedTime = "00:00:00"
        RemainingTime = "00:00:00"
        SuccessCount = 3
        TotalExecutions = 5
        Steps = @(
            [PSCustomObject]@{
                Id = "step-1"
                Name = "初始化"
                Status = "completed"
                Index = 1
                Duration = "00:00:01"
            },
            [PSCustomObject]@{
                Id = "step-2"
                Name = "配置检查"
                Status = "completed"
                Index = 2
                Duration = "00:00:02"
            },
            [PSCustomObject]@{
                Id = "step-3"
                Name = "执行主任务"
                Status = "in-progress"
                Index = 3
                Duration = "00:00:05"
            },
            [PSCustomObject]@{
                Id = "step-4"
                Name = "验证结果"
                Status = "pending"
                Index = 4
                Duration = "00:00:00"
            },
            [PSCustomObject]@{
                Id = "step-5"
                Name = "清理环境"
                Status = "pending"
                Index = 5
                Duration = "00:00:00"
            }
        )
        Logs = @(
            [PSCustomObject]@{
                Time = Get-Date -Format "HH:mm:ss"
                Level = "info"
                Message = "任务已启动"
            },
            [PSCustomObject]@{
                Time = Get-Date -Format "HH:mm:ss"
                Level = "success"
                Message = "步骤1完成"
            },
            [PSCustomObject]@{
                Time = Get-Date -Format "HH:mm:ss"
                Level = "info"
                Message = "步骤2完成"
            },
            [PSCustomObject]@{
                Time = Get-Date -Format "HH:mm:ss"
                Level = "progress"
                Message = "正在执行步骤3..."
            }
        )
    }
}

<#
.SYNOPSIS
- 生成通知

.DESCRIPTION
- 根据进度生成通知消息

.PARAMeter Progress
- 当前进度百分比

.PARAMeter Status
- 任务状态

.OUTPUTS
- 通知对象
#>

function Generate-Notification {
    param(
        [Parameter(Mandatory=$true)]
        [double]$Progress,

        [Parameter(Mandatory=$true)]
        [string]$Status
    )

    $messages = @()

    switch ($Status) {
        "pending" {
            $messages = @(
                "任务已排队，等待执行..."
            )
        }
        "in-progress" {
            if ($Progress -ge 100) {
                $messages = @(
                    "任务即将完成！"
                )
            }
            else {
                $messages = @(
                    "任务进行中: $Progress% 完成"
                )
            }
        }
        "completed" {
            $messages = @(
                "🎉 任务成功完成！"
            )
        }
        "failed" {
            $messages = @(
                "❌ 任务执行失败"
            )
        }
    }

    return [PSCustomObject]@{
        Progress = $Progress
        Status = $Status
        Messages = $messages
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

<#
.SYNOPSIS
- 更新步骤状态

.DESCRIPTION
- 更新指定步骤的状态

.PARAMeter TaskId
- 任务ID

.PARAMeter StepId
- 步骤ID

.PARAMeter Status
- 新状态

.PARAMeter Error
- 错误信息（可选）

.OUTPUTS
- 更新后的任务
#>

function Update-StepStatus {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskId,

        [Parameter(Mandatory=$true)]
        [string]$StepId,

        [Parameter(Mandatory=$true)]
        [string]$Status,

        [Parameter(Mandatory=$false)]
        [string]$Error = $null
    )

    $historyFile = "tasks\auto-gpt-history.json"

    if (-not (Test-Path $historyFile)) {
        Write-Warning "任务历史文件不存在"
        return $null
    }

    $history = Get-Content $historyFile -Raw | ConvertFrom-Json

    foreach ($task in $history) {
        if ($task.Id -eq $TaskId) {
            foreach ($step in $task.Steps) {
                if ($step.Id -eq $StepId) {
                    $step.Status = $Status
                    $step.StartedAt = if ($Status -eq 'in-progress' -and -not $step.StartedAt) {
                        Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    }
                    $step.CompletedAt = if ($Status -in @('completed', 'failed')) {
                        Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    } else {
                        $step.CompletedAt
                    }
                    $step.Error = $Error

                    # 记录日志
                    $logEntry = [PSCustomObject]@{
                        Time = Get-Date -Format "HH:mm:ss"
                        Level = switch ($Status) {
                            'completed' { 'success' }
                            'failed' { 'error' }
                            'in-progress' { 'info' }
                            default { 'info' }
                        }
                        Message = "步骤 $step.Name 变为 $Status" + if ($Error) { " - $Error" } else { '' }
                    }
                    $task.Logs += $logEntry

                    # 计算耗时
                    if ($step.StartedAt) {
                        $step.Duration = Calculate-Duration $step.StartedAt $step.CompletedAt
                    }

                    # 保存历史
                    $history | ConvertTo-Json -Depth 3 | Set-Content $historyFile
                    return $task
                }
            }
        }
    }

    return $null
}

<#
.SYNOPSIS
- 计算持续时间

.DESCRIPTION
- 计算两个时间戳之间的持续时间

.PARAMeter Start
- 开始时间

.PARAMeter End
- 结束时间

.OUTPUTS
- 时间跨度字符串（HH:mm:ss）
#>

function Calculate-Duration {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Start,

        [Parameter(Mandatory=$true)]
        [string]$End
    )

    $startDateTime = [DateTime]::Parse($Start)
    $endDateTime = [DateTime]::Parse($End)

    $timespan = $endDateTime - $startDateTime

    return $timespan.ToString("HH:mm:ss")
}

<#
.SYNOPSIS
- 获取随机ID

.DESCRIPTION
- 生成随机ID用于任务标识

.OUTPUTS
- 随机ID字符串
#>

function Get-Random-Id {
    return "auto-gpt-$(Get-Random -Maximum 999999)"
}

# 导出函数
Export-ModuleMember -Function @(
    'Show-ProgressDashboard',
    'Build-Dashboard',
    'Get-LastTask',
    'Generate-Notification',
    'Update-StepStatus',
    'Calculate-Duration',
    'Get-Random-Id'
)
