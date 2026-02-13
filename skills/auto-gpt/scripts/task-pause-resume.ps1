# Auto-GPT Task Pause/Resume - 任务暂停/恢复

<#
.SYNOPSIS
- 暂停执行中的Auto-GPT任务

.DESCRIPTION
- 保存任务状态到文件，从中断点恢复

.PARAMeter TaskId
- 任务ID

.PARAMeter Reason
- 暂停原因（可选）

.OUTPUTS
- 暂停状态
#>

function Stop-AutoTask {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskId,

        [Parameter(Mandatory=$false)]
        [string]$Reason = "手动暂停"
    )

    Write-Host "⏸ 暂停任务: $TaskId" -ForegroundColor Yellow
    Write-Host "  原因: $Reason" -ForegroundColor Gray

    # 获取任务历史
    $history = Get-TaskHistory

    foreach ($task in $history) {
        if ($task.Id -eq $TaskId) {
            # 更新任务状态
            $task.Status = 'paused'
            $task.PausedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $task.PauseReason = $Reason

            # 保存暂停状态
            Save-TaskState -Task $task -SaveType 'paused'

            Write-Host "  ✅ 任务已暂停" -ForegroundColor Green
            Write-Host "  恢复命令: Resume-AutoTask -TaskId $TaskId" -ForegroundColor Cyan

            return @{
                Success = $true
                TaskId = $TaskId
                Status = 'paused'
                Message = '任务已暂停'
            }
        }
    }

    Write-Host "  ❌ 未找到任务: $TaskId" -ForegroundColor Red
    return @{
        Success = $false
        TaskId = $TaskId
        Message = "任务不存在"
    }
}

<#
.SYNOPSIS
- 恢复暂停的Auto-GPT任务

.DESCRIPTION
- 从保存的状态恢复任务执行

.PARAMeter TaskId
- 任务ID

.PARAMeter StepId
- 要从哪个步骤开始（可选，默认从下一个pending步骤开始）

.OUTPUTS
- 恢复状态
#>

function Resume-AutoTask {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskId,

        [Parameter(Mandatory=$false)]
        [string]$StepId = $null
    )

    Write-Host "▶️ 恢复任务: $TaskId" -ForegroundColor Cyan

    # 尝试加载暂停状态
    $pausedTask = Load-TaskState -TaskId $TaskId -SaveType 'paused'

    if (-not $pausedTask) {
        # 没有暂停状态，尝试从历史恢复
        Write-Host "  尝试从历史记录恢复..." -ForegroundColor Yellow
        $history = Get-TaskHistory
        $pausedTask = $history | Where-Object { $_.Id -eq $TaskId }

        if (-not $pausedTask) {
            Write-Host "  ❌ 无法恢复任务: $TaskId" -ForegroundColor Red
            return @{
                Success = $false
                TaskId = $TaskId
                Message = "任务不存在且无暂停状态"
            }
        }
    }

    # 更新任务状态
    $pausedTask.Status = 'in-progress'
    $pausedTask.ResumedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $pausedTask.PauseReason = "自动恢复"

    # 更新步骤状态
    if ($StepId) {
        foreach ($step in $pausedTask.Steps) {
            if ($step.Id -eq $StepId) {
                $step.Status = 'in-progress'
                $step.StartedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
        }
    } else {
        # 找到第一个pending步骤
        $pendingStep = $pausedTask.Steps | Where-Object { $_.Status -eq 'pending' } | Select-Object -First 1
        if ($pendingStep) {
            $pendingStep.Status = 'in-progress'
            $pendingStep.StartedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }

    # 保存恢复状态
    Save-TaskState -Task $pausedTask -SaveType 'resumed'

    Write-Host "  ✅ 任务已恢复" -ForegroundColor Green
    Write-Host "  从步骤: $pendingStep.Name" -ForegroundColor Cyan

    return @{
        Success = $true
        TaskId = $TaskId
        Status = 'in-progress'
        Step = $pendingStep.Name
        Message = '任务已恢复'
    }
}

<#
.SYNOPSIS
- 检查任务是否可以暂停/恢复

.DESCRIPTION
- 检查任务状态和依赖

.PARAMeter TaskId
- 任务ID

.OUTPUTS
- 状态检查结果
#>

function Test-TaskState {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskId
    )

    # 检查任务历史
    $history = Get-TaskHistory
    $task = $history | Where-Object { $_.Id -eq $TaskId }

    if (-not $task) {
        return @{
            CanPause = $false
            CanResume = $false
            Message = "任务不存在"
        }
    }

    # 检查是否可以暂停
    $canPause = $task.Status -in @('in-progress', 'pending')

    # 检查是否可以恢复
    $canResume = $task.Status -eq 'paused' -or ($task.Status -eq 'completed' -and (Test-Path "tasks\$TaskId-paused.json"))

    return @{
        CanPause = $canPause
        CanResume = $canResume
        Status = $task.Status
        Message = "任务当前状态: $($task.Status)"
    }
}

<#
.SYNOPSIS
- 保存任务状态

.DESCRIPTION
- 将任务状态保存到文件

.PARAMeter Task
- 任务对象

.PARAMeter SaveType
- 保存类型（paused/resumed）

.OUTPUTS
- 无
#>

function Save-TaskState {
    param(
        [Parameter(Mandatory=$true)]
        $Task,

        [Parameter(Mandatory=$true)]
        [string]$SaveType
    )

    $taskDir = "tasks"

    if (-not (Test-Path $taskDir)) {
        New-Item -ItemType Directory -Path $taskDir | Out-Null
    }

    # 创建任务特定目录
    $taskDir = "$taskDir\$($Task.Id)"
    if (-not (Test-Path $taskDir)) {
        New-Item -ItemType Directory -Path $taskDir | Out-Null
    }

    # 保存暂停状态
    $pausedFile = "$taskDir\$TaskId-$SaveType.json"
    $Task | ConvertTo-Json -Depth 10 | Set-Content $pausedFile

    # 同时保存到历史
    $history = Get-TaskHistory
    $existingIndex = ($history | Where-Object { $_.Id -eq $Task.Id }).Index

    if ($existingIndex) {
        $history[$existingIndex] = $Task
    } else {
        $history += $Task
    }

    $history | ConvertTo-Json -Depth 3 | Set-Content "tasks\auto-gpt-history.json"
}

<#
.SYNOPSIS
- 加载任务状态

.DESCRIPTION
- 从文件加载任务状态

.PARAMeter TaskId
- 任务ID

.PARAMeter SaveType
- 保存类型（paused/resumed）

.OUTPUTS
- 任务对象
#>

function Load-TaskState {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskId,

        [Parameter(Mandatory=$true)]
        [string]$SaveType
    )

    $pausedFile = "tasks\$TaskId\$TaskId-$SaveType.json"

    if (Test-Path $pausedFile) {
        return Get-Content $pausedFile -Raw | ConvertFrom-Json
    }

    return $null
}

<#
.SYNOPSIS
- 获取任务历史

.DESCRIPTION
- 从文件加载所有任务历史

.OUTPUTS
- 任务历史数组
#>

function Get-TaskHistory {
    $historyFile = "tasks\auto-gpt-history.json"

    if (Test-Path $historyFile) {
        return Get-Content $historyFile -Raw | ConvertFrom-Json
    }

    return @()
}

<#
.SYNOPSIS
- 列出所有任务状态

.DESCRIPTION
- 列出所有任务的当前状态

.OUTPUTS
- 任务状态列表
#>

function Get-TaskList {
    $history = Get-TaskHistory

    if ($history.Count -eq 0) {
        Write-Host "  📋 没有找到任务" -ForegroundColor Gray
        return @()
    }

    Write-Host "  📋 任务列表:" -ForegroundColor Cyan
    Write-Host "  " -NoNewline

    $history | ForEach-Object {
        $statusColor = switch ($_.Status) {
            'in-progress' { 'Green' }
            'completed' { 'Cyan' }
            'failed' { 'Red' }
            'paused' { 'Yellow' }
            'pending' { 'Gray' }
            default { 'White' }
        }

        Write-Host "$($_.Name) [$($_.Status)] " -NoNewline -ForegroundColor $statusColor
    }

    Write-Host ""

    return $history
}

# 导出函数
Export-ModuleMember -Function @(
    'Stop-AutoTask',
    'Resume-AutoTask',
    'Test-TaskState',
    'Save-TaskState',
    'Load-TaskState',
    'Get-TaskHistory',
    'Get-TaskList'
)
