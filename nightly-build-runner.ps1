# Nightly Build 自动化系统执行脚本
# 执行第三周架构的4个核心任务
# 运行时间: 2026-02-12 01:04

# ============================================
# 初始化
# ============================================
$Script:StartTime = Get-Date
$Script:Config = @{
    LogLevel = "INFO"
    WorkingDir = "C:\Users\Administrator\.openclaw\workspace"
    OutputFile = "logs/nightly-build/nightly-build-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    MaxRetries = 3
}

# 确保目录存在
$OutputDir = Split-Path $Script:Config.OutputFile -Parent
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# 任务状态跟踪
$TaskQueue = @(
    @{ TaskId = 1; Name = "智能任务调度器"; Script = "skill-integration\smart-task-scheduler.ps1"; Status = "pending" },
    @{ TaskId = 2; Name = "跨技能协作流程"; Script = "skill-integration\skill-collaboration-mechanism.ps1"; Status = "pending" },
    @{ TaskId = 3; Name = "条件触发器"; Script = "skill-integration\trigger-system.ps1"; Status = "pending" },
    @{ TaskId = 4; Name = "集成测试"; Script = "scripts\testing\day6-integration-test.ps1"; Status = "pending" }
)

$CompletedTasks = @()
$CurrentTask = $null

# 日志函数
function Write-Log {
    param(
        [string]$Level,
        [string]$Message
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"

    Write-Host $LogEntry
    Add-Content -Path $Script:Config.OutputFile -Value $LogEntry
}

function Write-TaskLog {
    param(
        [string]$Level,
        [string]$Message
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [TASK] $Message"

    Write-Host $LogEntry
    Add-Content -Path $Script:Config.OutputFile -Value $LogEntry
}

# ============================================
# 环境加载
# ============================================
Write-Log "INFO" "=== Nightly Build 自动化系统启动 ==="
Write-Log "INFO" "启动时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Log "INFO" "工作目录: $($Script:Config.WorkingDir)"

Write-Log "INFO" "`n--- 环境变量加载 ---"
& ".\.env-loader.ps1"
Write-Log "INFO" "✅ 环境变量加载完成"

# ============================================
# 显示任务队列
# ============================================
Write-Log "INFO" "`n=== 当前执行的任务队列 ==="
foreach ($task in $TaskQueue) {
    Write-Log "INFO" "[$($task.TaskId)] $($task.Name) - $($task.Status)"
}

# ============================================
# 任务1: 智能任务调度器
# ============================================
Write-Log "INFO" "`n--- 任务 1/4: 智能任务调度器 ---"
$CurrentTask = $TaskQueue[0]
$CurrentTask.Status = "running"

Write-TaskLog "INFO" "开始执行: $($CurrentTask.Name)"
Write-Log "INFO" "脚本路径: $($CurrentTask.Script)"

$startTime = Get-Date

try {
    # 导入智能任务调度器模块
    . "$($Script:Config.WorkingDir)\skill-integration\smart-task-scheduler.ps1"

    # 创建测试任务
    $task1 = New-SmartTask `
        -TaskId "TASK-001" `
        -TaskName "运行诊断检查" `
        -ScriptBlock {
            Write-Host "运行诊断检查..." -ForegroundColor Cyan
            Start-Sleep -Seconds 2
            return @{ success = $true; message = "诊断检查完成" }
        }
        -Priority 80

    $task2 = New-SmartTask `
        -TaskId "TASK-002" `
        -TaskName "运行备份" `
        -ScriptBlock {
            Write-Host "运行备份..." -ForegroundColor Cyan
            Start-Sleep -Seconds 3
            return @{ success = $true; message = "备份完成" }
        }
        -Priority 90
        -DependsOn "TASK-001"

    $tasks = @($task1, $task2)

    # 执行调度器
    Write-TaskLog "INFO" "执行任务调度..."
    $result = Invoke-SmartTaskScheduler -Tasks $tasks -Concurrency 2

    Write-TaskLog "INFO" "执行时间: $([math]::Round((Get-Date - $startTime).TotalSeconds, 2)) 秒"

    if ($result.success) {
        $CurrentTask.Status = "completed"
        $CompletedTasks += $CurrentTask
        Write-TaskLog "INFO" "✅ 任务完成: 成功 $($result.completed_tasks), 失败 $($result.failed_tasks)"
    } else {
        $CurrentTask.Status = "failed"
        Write-TaskLog "WARN" "⚠️ 任务失败: $($result.error)"
    }
}
catch {
    $CurrentTask.Status = "failed"
    Write-TaskLog "ERROR" "❌ 任务异常: $($_.Exception.Message)"
}

# ============================================
# 任务2: 跨技能协作流程
# ============================================
Write-Log "INFO" "`n--- 任务 2/4: 跨技能协作流程 ---"
$CurrentTask = $TaskQueue[1]
$CurrentTask.Status = "running"

Write-TaskLog "INFO" "开始执行: $($CurrentTask.Name)"
Write-Log "INFO" "脚本路径: $($CurrentTask.Script)"

$startTime = Get-Date

try {
    # 导入跨技能协作模块
    . "$($Script:Config.WorkingDir)\skill-integration\skill-collaboration-mechanism.ps1"

    # 创建技能组合
    $combo1 = New-SkillCombo `
        -ComboId "COMBO-001" `
        -ComboName "科技新闻与分析" `
        -SkillNames @("technews", "code-mentor") `
        -Parameters @{
            topic = "AI"
            count = 5
            action = "review"
            code = "print('AI trends')"
            language = "Python"
        }

    $combo2 = New-SkillCombo `
        -ComboId "COMBO-002" `
        -ComboName "Exa搜索与摘要" `
        -SkillNames @("exa", "technews") `
        -Parameters @{
            query = "Python automation"
            type = "news"
            maxResults = 5
            topic = "automation"
            count = 3
        }

    # 执行协作
    Write-TaskLog "INFO" "执行技能协作..."
    $result = Invoke-SkillCollaboration -SkillCombos @($combo1, $combo2) -MaxParallel 2

    Write-TaskLog "INFO" "执行时间: $([math]::Round((Get-Date - $startTime).TotalSeconds, 2)) 秒"

    if ($result.success) {
        $CurrentTask.Status = "completed"
        $CompletedTasks += $CurrentTask
        Write-TaskLog "INFO" "✅ 任务完成: 成功 $($result.completed_combos), 失败 $($result.failed_combos)"
    } else {
        $CurrentTask.Status = "failed"
        Write-TaskLog "WARN" "⚠️ 任务失败: $($result.error)"
    }
}
catch {
    $CurrentTask.Status = "failed"
    Write-TaskLog "ERROR" "❌ 任务异常: $($_.Exception.Message)"
}

# ============================================
# 任务3: 条件触发器
# ============================================
Write-Log "INFO" "`n--- 任务 3/4: 条件触发器 ---"
$CurrentTask = $TaskQueue[2]
$CurrentTask.Status = "running"

Write-TaskLog "INFO" "开始执行: $($CurrentTask.Name)"
Write-Log "INFO" "脚本路径: $($CurrentTask.Script)"

$startTime = Get-Date

try {
    # 导入条件触发器模块
    . "$($Script:Config.WorkingDir)\skill-integration\trigger-system.ps1"

    # 创建时间触发器
    $timeTrigger = New-TimeTrigger `
        -TriggerId "TRIGGER-001" `
        -TriggerName "每日备份" `
        -TimeSchedule @{
            kind = "daily"
            time = "02:00"
        }

    # 创建状态触发器
    $stateTrigger = New-StateTrigger `
        -TriggerId "TRIGGER-003" `
        -TriggerName "高内存警告" `
        -StateVariable "memory" `
        -Operator "gt" `
        -TargetValue "80" `
        -StateCheckScript {
            param($State, $Trigger)
            return ($State.memory -gt 80)
        }

    # 检查触发器
    $triggerResults = @()
    $triggerResults += Invoke-TimeTrigger -Trigger $timeTrigger
    $triggerResults += Invoke-StateTrigger -Trigger $stateTrigger -CurrentState @{
        memory = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1KB / 1MB
    }

    Write-TaskLog "INFO" "执行时间: $([math]::Round((Get-Date - $startTime).TotalSeconds, 2)) 秒"

    $CurrentTask.Status = "completed"
    $CompletedTasks += $CurrentTask
    Write-TaskLog "INFO" "✅ 任务完成"
}
catch {
    $CurrentTask.Status = "failed"
    Write-TaskLog "ERROR" "❌ 任务异常: $($_.Exception.Message)"
}

# ============================================
# 任务4: 集成测试
# ============================================
Write-Log "INFO" "`n--- 任务 4/4: 集成测试 ---"
$CurrentTask = $TaskQueue[3]
$CurrentTask.Status = "running"

Write-TaskLog "INFO" "开始执行: $($CurrentTask.Name)"
Write-Log "INFO" "脚本路径: $($CurrentTask.Script)"

$startTime = Get-Date

try {
    # 运行集成测试
    Write-TaskLog "INFO" "执行系统集成测试..."
    $result = & "$($Script:Config.WorkingDir)\scripts\testing\day6-integration-test.ps1" -SpecificTest "All" -TestAll

    Write-TaskLog "INFO" "执行时间: $([math]::Round((Get-Date - $startTime).TotalSeconds, 2)) 秒"

    if ($LASTEXITCODE -eq 0) {
        $CurrentTask.Status = "completed"
        $CompletedTasks += $CurrentTask
        Write-TaskLog "INFO" "✅ 任务完成"
    } else {
        $CurrentTask.Status = "failed"
        Write-TaskLog "WARN" "⚠️ 任务失败: EXITCODE=$LASTEXITCODE"
    }
}
catch {
    $CurrentTask.Status = "failed"
    Write-TaskLog "ERROR" "❌ 任务异常: $($_.Exception.Message)"
}

# ============================================
# 最终报告
# ============================================
$EndTime = Get-Date
$TotalDuration = [math]::Round(($EndTime - $Script:StartTime).TotalMinutes, 2)

Write-Log "INFO" "`n=== Nightly Build 自动化系统执行完成 ==="
Write-Log "INFO" "完成时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Log "INFO" "总执行时间: ${TotalDuration} 分钟"

Write-Log "INFO" "`n=== 执行结果摘要 ==="

Write-Log "INFO" "`n📋 已完成的任务列表:"
foreach ($task in $CompletedTasks) {
    $statusIcon = if ($task.Status -eq "completed") { "✅" } else { "❌" }
    Write-Log "INFO" "  $statusIcon [$($task.TaskId)] $($task.Name) - $($task.Status)"
}

Write-Log "INFO" "`n🔧 当前执行的任务状态:"
foreach ($task in $TaskQueue) {
    if ($task.Status -eq "running") {
        $statusIcon = "🔄"
        Write-Log "INFO" "  $statusIcon [$($task.TaskId)] $($task.Name) - $($task.Status)"
    }
}

$PendingTasks = $TaskQueue | Where-Object { $_.Status -eq "pending" }
if ($PendingTasks.Count -gt 0) {
    Write-Log "INFO" "`n⏳ 待处理的任务:"
    foreach ($task in $PendingTasks) {
        Write-Log "INFO" "  ⏸️ [$($task.TaskId)] $($task.Name) - $($task.Status)"
    }
}

Write-Log "INFO" "`n📊 任务完成率: $([math]::Round(($CompletedTasks.Count / $TaskQueue.Count) * 100, 0))%"

# 生成预计完成时间
$EstimatedTime = Get-Date -TimeSpan $TotalDuration
Write-Log "INFO" "`n⏰ 预计完成时间: $EstimatedTime"

Write-Log "INFO" "`n=== Nightly Build 执行结束 ==="

# 返回结果
$output = @{
    TaskQueue = $TaskQueue
    CompletedTasks = $CompletedTasks
    CurrentTask = $CurrentTask
    TotalDuration = $TotalDuration
    StartTime = $Script:StartTime
    EndTime = $EndTime
}

$output
