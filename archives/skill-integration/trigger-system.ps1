# 条件触发器系统

**版本**: 1.0
**日期**: 2026-02-11
**作者**: 灵眸

---

## 🎯 系统概述

条件触发器系统基于多种条件类型触发自动化任务，支持时间、事件、状态等多种触发方式。

---

## 📊 触发器类型

### 1. 时间触发器

```powershell
function New-TimeTrigger {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TriggerId,
        [Parameter(Mandatory=$true)]
        [string]$TriggerName,
        [hashtable]$TimeSchedule
    )

    $trigger = @{
        trigger_id = $TriggerId
        trigger_name = $TriggerName
        type = "time"
        schedule = $TimeSchedule
        active = $true
        last_triggered = $null
        next_trigger = $null
        execution_count = 0
        created_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }

    # 计算下次触发时间
    $trigger.next_trigger = CalculateNextTriggerTime -Schedule $TimeSchedule

    return $trigger
}

function Invoke-TimeTrigger {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Trigger
    )

    if (!$Trigger.active) {
        Write-Host "[TIME_TRIGGER] ⏸️ 触发器已禁用" -ForegroundColor Yellow
        return $false
    }

    $now = Get-Date
    $nextTrigger = [DateTime]$Trigger.next_trigger

    if ($now -ge $nextTrigger) {
        Write-Host "[TIME_TRIGGER] ⏰ 时间触发器激活" -ForegroundColor Cyan
        Write-Host "[TIME_TRIGGER]    下次触发: $($nextTrigger.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray

        $Trigger.last_triggered = $now
        $Trigger.next_trigger = CalculateNextTriggerTime -Schedule $Trigger.schedule
        $Trigger.execution_count++

        return $true
    } else {
        Write-Host "[TIME_TRIGGER] ⏳ 等待触发: $($nextTrigger.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
        return $false
    }
}

function CalculateNextTriggerTime {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Schedule
    )

    $now = Get-Date

    # 每日定时
    if ($Schedule.kind -eq "daily") {
        $scheduleTime = $Schedule.time

        # 解析时间
        if ($scheduleTime -match "^(\d{1,2}):(\d{2})$") {
            $hour = [int]$Matches[1]
            $minute = [int]$Matches[2]
            $targetTime = [DateTime]::new($now.Year, $now.Month, $now.Day, $hour, $minute, 0)

            if ($now -gt $targetTime) {
                $targetTime = $targetTime.AddDays(1)
            }
        }
    }

    # 每周定时
    elseif ($Schedule.kind -eq "weekly") {
        $dayOfWeek = $Schedule.day
        $scheduleTime = $Schedule.time

        # 解析时间
        if ($scheduleTime -match "^(\d{1,2}):(\d{2})$") {
            $hour = [int]$Matches[1]
            $minute = [int]$Matches[2]

            # 转换星期几到数字
            $dayMap = @{
                "Sunday" = 0
                "Monday" = 1
                "Tuesday" = 2
                "Wednesday" = 3
                "Thursday" = 4
                "Friday" = 5
                "Saturday" = 6
            }

            $targetDay = $dayMap[$dayOfWeek]
            $targetTime = [DateTime]::new($now.Year, $now.Month, $now.Day, $hour, $minute, 0)

            while ($targetTime.DayOfWeek.Value -ne $targetDay) {
                $targetTime = $targetTime.AddDays(1)
            }

            if ($now -gt $targetTime) {
                $targetTime = $targetTime.AddDays(7)
            }
        }
    }

    # 每月定时
    elseif ($Schedule.kind -eq "monthly") {
        $dayOfMonth = $Schedule.day
        $scheduleTime = $Schedule.time

        # 解析时间
        if ($scheduleTime -match "^(\d{1,2}):(\d{2})$") {
            $hour = [int]$Matches[1]
            $minute = [int]$Matches[2]
            $targetTime = [DateTime]::new($now.Year, $now.Month, $dayOfMonth, $hour, $minute, 0)

            if ($now -gt $targetTime) {
                if ($now.Month -eq 12) {
                    $targetTime = $targetTime.AddYears(1)
                } else {
                    $targetTime = $targetTime.AddMonths(1)
                }
            }
        }
    }

    return $targetTime
}
```

### 2. 事件触发器

```powershell
function New-EventTrigger {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TriggerId,
        [Parameter(Mandatory=$true)]
        [string]$TriggerName,
        [string[]]$Events,
        [scriptblock]$FilterScript
    )

    $trigger = @{
        trigger_id = $TriggerId
        trigger_name = $TriggerName
        type = "event"
        events = $Events
        filter = $FilterScript
        active = $true
        last_triggered = $null
        execution_count = 0
        created_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }

    return $trigger
}

function Invoke-EventTrigger {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Trigger,
        [string]$EventName
    )

    if (!$Trigger.active) {
        Write-Host "[EVENT_TRIGGER] ⏸️ 触发器已禁用" -ForegroundColor Yellow
        return $false
    }

    # 检查事件是否匹配
    if ($Trigger.events -notcontains $EventName) {
        return $false
    }

    # 执行过滤器
    if ($Trigger.filter) {
        try {
            $filterResult = & $Trigger.filter -EventName $EventName -Trigger $Trigger
            if (!$filterResult) {
                return $false
            }
        } catch {
            Write-Host "[EVENT_TRIGGER] ⚠️ 过滤器错误" -ForegroundColor Yellow
            return $false
        }
    }

    Write-Host "[EVENT_TRIGGER] ⚡ 事件触发器激活" -ForegroundColor Cyan
    Write-Host "[EVENT_TRIGGER]    事件: $EventName" -ForegroundColor Cyan
    Write-Host "[EVENT_TRIGGER]    触发器: $($Trigger.trigger_name)" -ForegroundColor Cyan

    $Trigger.last_triggered = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Trigger.execution_count++

    return $true
}
```

### 3. 状态触发器

```powershell
function New-StateTrigger {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TriggerId,
        [Parameter(Mandatory=$true)]
        [string]$TriggerName,
        [string]$StateVariable,
        [string]$Operator = "eq",
        [string]$TargetValue,
        [scriptblock]$StateCheckScript
    )

    $trigger = @{
        trigger_id = $TriggerId
        trigger_name = $TriggerName
        type = "state"
        state_variable = $StateVariable
        operator = $Operator
        target_value = $TargetValue
        check_script = $StateCheckScript
        active = $true
        last_triggered = $null
        execution_count = 0
        last_check = $null
        created_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }

    return $trigger
}

function Invoke-StateTrigger {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Trigger,
        [hashtable]$CurrentState
    )

    if (!$Trigger.active) {
        Write-Host "[STATE_TRIGGER] ⏸️ 触发器已禁用" -ForegroundColor Yellow
        return $false
    }

    $Trigger.last_check = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # 检查状态变量
    $currentValue = if ($Trigger.state_variable -in $CurrentState.Keys) {
        $CurrentState.($Trigger.state_variable)
    } else {
        $null
    }

    # 执行自定义检查脚本
    if ($Trigger.check_script) {
        try {
            $checkResult = & $Trigger.check_script -State $CurrentState -Trigger $Trigger
            if (!$checkResult) {
                return $false
            }
        } catch {
            Write-Host "[STATE_TRIGGER] ⚠️ 状态检查错误" -ForegroundColor Yellow
            return $false
        }
    }

    # 执行比较操作
    $shouldTrigger = $false

    switch ($Trigger.operator) {
        "eq" {
            if ($currentValue -eq $Trigger.target_value) {
                $shouldTrigger = $true
            }
        }
        "ne" {
            if ($currentValue -ne $Trigger.target_value) {
                $shouldTrigger = $true
            }
        }
        "gt" {
            if ($currentValue -gt [int]$Trigger.target_value) {
                $shouldTrigger = $true
            }
        }
        "lt" {
            if ($currentValue -lt [int]$Trigger.target_value) {
                $shouldTrigger = $true
            }
        }
        "contains" {
            if ($currentValue -like "*$($Trigger.target_value)*") {
                $shouldTrigger = $true
            }
        }
    }

    if ($shouldTrigger) {
        Write-Host "[STATE_TRIGGER] 📊 状态触发器激活" -ForegroundColor Cyan
        Write-Host "[STATE_TRIGGER]    状态变量: $($Trigger.state_variable)" -ForegroundColor Cyan
        Write-Host "[STATE_TRIGGER]    当前值: $currentValue" -ForegroundColor Cyan
        Write-Host "[STATE_TRIGGER]    触发器: $($Trigger.trigger_name)" -ForegroundColor Cyan

        $Trigger.last_triggered = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $Trigger.execution_count++

        return $true
    }

    return $false
}
```

### 4. 触发器管理器

```powershell
function Invoke-TriggerManager {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Triggers,
        [string]$TriggerType = "all"
    )

    Write-Host "[TRIGGER_MGR] 🔔 触发器管理器" -ForegroundColor Cyan
    Write-Host "[TRIGGER_MGR]    触发器类型: $TriggerType" -ForegroundColor Cyan

    $activeTriggers = $Triggers | Where-Object { $_.active }

    foreach ($trigger in $activeTriggers) {
        $triggerName = $trigger.trigger_name
        $triggerType = $trigger.type

        if ($TriggerType -eq "all" -or $TriggerType -eq $triggerType) {
            Write-Host "`n[TRIGGER_MGR] 检查触发器: $triggerName" -ForegroundColor Yellow

            $triggered = $false

            switch ($triggerType) {
                "time" {
                    $triggered = Invoke-TimeTrigger -Trigger $trigger
                }
                "event" {
                    # 事件触发器需要外部触发
                    Write-Host "[TRIGGER_MGR]    等待事件触发" -ForegroundColor Gray
                }
                "state" {
                    $triggered = Invoke-StateTrigger -Trigger $trigger -CurrentState @{
                        memory = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1KB / 1MB
                        cpu = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples[0].CookedValue
                    }
                }
            }

            if ($triggered) {
                Write-Host "[TRIGGER_MGR] ✓ 触发器已激活" -ForegroundColor Green
            }
        }
    }
}

function Add-Trigger {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TriggerId,
        [Parameter(Mandatory=$true)]
        [string]$TriggerName,
        [string]$Type,
        [Parameter(Mandatory=$true)]
        [hashtable]$Configuration
    )

    $newTrigger = @{}

    switch ($Type.ToLower()) {
        "time" {
            $newTrigger = New-TimeTrigger `
                -TriggerId $TriggerId `
                -TriggerName $TriggerName `
                -TimeSchedule $Configuration
        }
        "event" {
            $newTrigger = New-EventTrigger `
                -TriggerId $TriggerId `
                -TriggerName $TriggerName `
                -Events $Configuration.events `
                -FilterScript $Configuration.filter
        }
        "state" {
            $newTrigger = New-StateTrigger `
                -TriggerId $TriggerId `
                -TriggerName $TriggerName `
                -StateVariable $Configuration.state_variable `
                -Operator $Configuration.operator `
                -TargetValue $Configuration.target_value `
                -StateCheckScript $Configuration.check_script
        }
    }

    # 保存触发器
    $triggerPath = "logs/triggers/$TriggerId.json"
    if (!(Test-Path "logs/triggers")) {
        New-Item -Path "logs/triggers" -ItemType Directory -Force | Out-Null
    }

    $newTrigger | ConvertTo-Json -Depth 10 | Set-Content $triggerPath -Encoding UTF8

    Write-Host "[TRIGGER_MGR] ✓ 触发器已添加: $TriggerName" -ForegroundColor Green

    return $newTrigger
}
```

---

## 📊 使用示例

```powershell
# 示例1: 时间触发器
$timeTrigger = New-TimeTrigger `
    -TriggerId "TRIGGER-001" `
    -TriggerName "Daily Backup" `
    -TimeSchedule @{
        kind = "daily"
        time = "02:00"
    }

# 检查是否应该触发
if (Invoke-TimeTrigger -Trigger $timeTrigger) {
    Write-Host "执行备份任务..." -ForegroundColor Cyan
}

# 示例2: 事件触发器
$eventTrigger = New-EventTrigger `
    -TriggerId "TRIGGER-002" `
    -TriggerName "Error Alert" `
    -Events @("error", "warning") `
    -FilterScript {
        param($EventName, $Trigger)
        return ($EventName -eq "error")
    }

# 事件发生时触发
if (Invoke-EventTrigger -Trigger $eventTrigger -EventName "error") {
    Write-Host "发送错误警报..." -ForegroundColor Cyan
}

# 示例3: 状态触发器
$stateTrigger = New-StateTrigger `
    -TriggerId "TRIGGER-003" `
    -TriggerName "High Memory Warning" `
    -StateVariable "memory" `
    -Operator "gt" `
    -TargetValue "80" `
    -StateCheckScript {
        param($State, $Trigger)
        # 自定义检查逻辑
        return ($State.memory -gt 80)
    }

# 检查状态触发器
$currentState = @{
    memory = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1KB / 1MB
}

if (Invoke-StateTrigger -Trigger $stateTrigger -CurrentState $currentState) {
    Write-Host "内存使用率过高！" -ForegroundColor Red
}

# 示例4: 触发器管理器
$triggers = @($timeTrigger, $eventTrigger, $stateTrigger)
Invoke-TriggerManager -Triggers $triggers
```

---

## 🎯 技术特性

- **时间触发**: 每日、每周、每月定时触发
- **事件触发**: 基于特定事件触发
- **状态触发**: 基于系统状态触发
- **自定义过滤器**: 支持脚本过滤
- **触发器管理**: 统一管理多个触发器
- **状态持久化**: 触发器配置保存
- **统计信息**: 执行次数和最后触发时间

---

**版本**: 1.0
**状态**: ✅ 开发完成
**完成度**: 90%
