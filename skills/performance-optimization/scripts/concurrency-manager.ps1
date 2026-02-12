# 并发处理器

## 功能
- 异步任务执行
- 并发控制
- 任务调度
- 负载均衡

## 使用方法

### 异步执行

#### 基础异步任务
```powershell
# 创建异步任务
$task = .\concurrency-manager.ps1 -AsyncTask -Name "process-data" -ScriptBlock {
    param($data)
    # 处理数据
    return Process-Data $data
}

# 等待任务完成
$result = .\concurrency-manager.ps1 -Wait -Task $task

# 获取任务状态
$status = .\concurrency-manager.ps1 -GetTaskStatus -Task $task

# 取消任务
.\concurrency-manager.ps1 -Cancel -Task $task
```

#### 批量异步任务
```powershell
# 创建多个异步任务
$tasks = @(
    @{ name = "task1"; script = { ... } },
    @{ name = "task2"; script = { ... } },
    @{ name = "task3"; script = { ... } }
)

# 并行执行
$results = .\concurrency-manager.ps1 -Parallel -Tasks $tasks

# 顺序执行
$results = .\concurrency-manager.ps1 -Sequential -Tasks $tasks
```

### 并发控制

#### 限制并发数
```powershell
# 限制最大并发数
.\concurrency-manager.ps1 -SetMaxConcurrency -Count 10

# 限制每个任务的并发数
.\concurrency-manager.ps1 -SetTaskConcurrency -Task "process" -Count 5

# 设置并发限制（自动）
.\concurrency-manager.ps1 -UseConcurrencyLimit -MaxConcurrency 10
```

#### 任务优先级
```powershell
# 创建优先级任务
$task1 = .\concurrency-manager.ps1 -CreateTask -Name "high-priority" -Priority "high" -ScriptBlock { ... }
$task2 = .\concurrency-manager.ps1 -CreateTask -Name "normal-priority" -Priority "normal" -ScriptBlock { ... }
$task3 = .\concurrency-manager.ps1 -CreateTask -Name "low-priority" -Priority "low" -ScriptBlock { ... }

# 按优先级执行
.\concurrency-manager.ps1 -ExecuteWithPriority
```

#### 任务依赖
```powershell
# 定义任务依赖
$task1 = .\concurrency-manager.ps1 -CreateTask -Name "task1" -ScriptBlock { ... }
$task2 = .\concurrency-manager.ps1 -CreateTask -Name "task2" -DependsOn @("task1")
$task3 = .\concurrency-manager.ps1 -CreateTask -Name "task3" -DependsOn @("task2")

# 按依赖关系执行
.\concurrency-manager.ps1 -ExecuteWithDependencies
```

### 任务调度

#### 定时调度
```powershell
# 定时执行任务
.\concurrency-manager.ps1 -Schedule -Task "backup" -Cron "0 2 * * *"

# 循环执行（间隔秒数）
.\concurrency-manager.ps1 -Schedule -Task "monitor" -Interval 60

# 延迟执行（秒数）
.\concurrency-manager.ps1 -Schedule -Task "delayed" -Delay 30

# 周期性执行（开始时间、间隔）
.\concurrency-manager.ps1 -Schedule -Task "periodic" -StartTime (Get-Date) -Interval 300
```

#### 条件触发
```powershell
# 基于条件触发
.\concurrency-manager.ps1 -Schedule -Task "auto-backup" -Condition {
    param($trigger)
    return $trigger.Data.Critical > 80
}

# 基于时间窗口触发
.\concurrency-manager.ps1 -Schedule -Task "cleanup" -TimeWindow "00:00-06:00"
```

### 负载均衡

#### 任务分配策略
```powershell
# 轮询（Round-Robin）
.\concurrency-manager.ps1 -SetLoadBalanceStrategy -Strategy "round-robin"

# 随机分配
.\concurrency-manager.ps1 -SetLoadBalanceStrategy -Strategy "random"

# 最少任务优先（Shortest Job First）
.\concurrency-manager.ps1 -SetLoadBalanceStrategy -Strategy "sjf"

# 加权分配（根据资源可用性）
.\concurrency-manager.ps1 -SetLoadBalanceStrategy -Strategy "weighted"
```

#### 资源调度
```powershell
# 调度到特定资源
.\concurrency-manager.ps1 -AssignTo -Task "data-process" -Resource "cpu1"

# 调度到资源池
.\concurrency-manager.ps1 -AssignToPool -Task "data-process" -Pool "high-priority"

# 调度到组
.\concurrency-manager.ps1 -AssignToGroup -Task "data-process" -Group "batch"
```

#### 优先级队列
```powershell
# 创建优先级队列
.\concurrency-manager.ps1 -CreatePriorityQueue -Name "job-queue" -Priorities @("high", "normal", "low")

# 添加任务到队列
.\concurrency-manager.ps1 -Enqueue -Queue "job-queue" -Task $task -Priority "high"

# 从队列取出任务
.\concurrency-manager.ps1 -Dequeue -Queue "job-queue"
```

### 任务队列

#### 任务队列管理
```powershell
# 创建任务队列
.\concurrency-manager.ps1 -CreateQueue -Name "background-jobs"

# 添加任务到队列
.\concurrency-manager.ps1 -Enqueue -Queue "background-jobs" -Task $task

# 执行队列中的任务
.\concurrency-manager.ps1 -ProcessQueue -Queue "background-jobs"

# 停止队列执行
.\concurrency-manager.ps1 -StopQueue -Queue "background-jobs"

# 暂停队列
.\concurrency-manager.ps1 -PauseQueue -Queue "background-jobs"
```

#### 队列配置
```powershell
# 队列容量
.\concurrency-manager.ps1 -SetQueueCapacity -Queue "background-jobs" -Capacity 1000

# 队列超时
.\concurrency-manager.ps1 -SetQueueTimeout -Queue "background-jobs" -Timeout 300

# 队列优先级
.\concurrency-manager.ps1 -SetQueuePriority -Queue "background-jobs" -Priority "high"
```

### 监控和管理

#### 任务监控
```powershell
# 获取所有任务
$tasks = .\concurrency-manager.ps1 -GetTasks

# 获取运行中的任务
$running = .\concurrency-manager.ps1 -GetRunningTasks

# 获取等待中的任务
$waiting = .\concurrency-manager.ps1 -GetWaitingTasks

# 获取已完成任务
$completed = .\concurrency-manager.ps1 -GetCompletedTasks

# 获取失败任务
$failed = .\concurrency-manager.ps1 -GetFailedTasks
```

#### 性能统计
```powershell
# 获取并发统计
$stats = .\concurrency-manager.ps1 -GetConcurrencyStats

# 获取任务统计
$stats = .\concurrency-manager.ps1 -GetTaskStats

# 获取队列统计
$stats = .\concurrency-manager.ps1 -GetQueueStats

# 获取资源使用
$usage = .\concurrency-manager.ps1 -GetResourceUsage
```

#### 错误处理
```powershell
# 任务失败回调
.\concurrency-manager.ps1 -OnError {
    param($task, $error)
    Write-Host "任务失败: $($task.Name)" -ForegroundColor Red
    Write-Host "错误: $($error.Message)"
}

# 重试策略
.\concurrency-manager.ps1 -SetRetryStrategy -MaxRetries 3 -Delay 1000

# 任务超时
.\concurrency-manager.ps1 -SetTaskTimeout -Task "long-process" -Timeout 300
```

### 专用调度器

#### 工作线程池
```powershell
# 创建工作线程池
.\concurrency-manager.ps1 -CreateThreadPool -Name "work-pool" -Threads 10

# 提交任务到线程池
.\concurrency-manager.ps1 -SubmitToPool -Pool "work-pool" -Task $task

# 优雅关闭线程池
.\concurrency-manager.ps1 -ShutdownPool -Pool "work-pool"
```

#### 信号量控制
```powershell
# 创建信号量
.\concurrency-manager.ps1 -CreateSemaphore -Name "resource-sem" -MaxCount 5

# 等待信号量
.\concurrency-manager.ps1 -WaitForSemaphore -Name "resource-sem"

# 释放信号量
.\concurrency-manager.ps1 -ReleaseSemaphore -Name "resource-sem"
```

## 高级功能

### 并发模式
```powershell
# 顺序执行
.\concurrency-manager.ps1 -Execute -Mode "sequential" -Tasks $tasks

# 并行执行（指定并发数）
.\concurrency-manager.ps1 -Execute -Mode "parallel" -Concurrency 5 -Tasks $tasks

# 分批执行
.\concurrency-manager.ps1 -Execute -Mode "batch" -BatchSize 10 -Tasks $tasks

# 条件执行
.\concurrency-manager.ps1 -Execute -Mode "conditional" -Condition { ... } -Tasks $tasks
```

### 任务分组
```powershell
# 创建任务组
$group = .\concurrency-manager.ps1 -CreateGroup -Name "data-processor" -Parallel $true

# 添加任务到组
.\concurrency-manager.ps1 -AddToGroup -Group $group -Task $task1
.\concurrency-manager.ps1 -AddToGroup -Group $group -Task $task2

# 执行组
.\concurrency-manager.ps1 -ExecuteGroup -Group $group
```

### 任务链
```powershell
# 创建任务链
$chain = .\concurrency-manager.ps1 -CreateChain -Name "data-pipeline"

# 添加任务到链
.\concurrency-manager.ps1 -AddToChain -Chain $chain -Step 1 -Task $task1
.\concurrency-manager.ps1 -AddToChain -Chain $chain -Step 2 -Task $task2

# 执行链
.\concurrency-manager.ps1 -ExecuteChain -Chain $chain
```

## 最佳实践

1. **合理控制并发**: 根据系统资源设置合理的并发数
2. **优先级管理**: 重要任务优先执行
3. **任务依赖**: 明确任务之间的依赖关系
4. **错误处理**: 健全的错误处理和重试机制
5. **监控优化**: 实时监控任务状态和性能
6. **资源调度**: 合理分配任务到不同资源
7. **队列管理**: 避免任务堆积，及时清理
