# 延迟加载管理器

## 功能
- 按需加载资源
- 加载状态跟踪
- 自动回收未使用资源
- 加载性能监控

## 使用方法

### 加载资源
```powershell
# 基础加载
$resource = .\lazy-loader.ps1 -Load "data/biography.json"

# 指定超时
$resource = .\lazy-loader.ps1 -Load "data/biography.json" -Timeout 30

# 异步加载
$resource = .\lazy-loader.ps1 -Load "data/biography.json" -Async

# 获取加载状态
$status = .\lazy-loader.ps1 -GetStatus "data/biography.json"

# 检查是否已加载
$loaded = .\lazy-loader.ps1 -IsLoaded "data/biography.json"
```

### 资源管理
```powershell
# 释放资源
.\lazy-loader.ps1 -Release "data/biography.json"

# 释放所有资源
.\lazy-loader.ps1 -ReleaseAll

# 检查资源使用情况
.\lazy-loader.ps1 -GetUsage

# 清空缓存
.\lazy-loader.ps1 -ClearCache
```

### 加载统计
```powershell
# 获取加载统计
.\lazy-loader.ps1 -GetStats

# 获取详细统计（包含时间、大小等）
.\lazy-loader.ps1 -GetDetailedStats

# 重置统计
.\lazy-loader.ps1 -ResetStats
```

## 内置资源

### 按类型定义资源
```powershell
# 文本文件
lazy_load_register "config.json" -Type "json" -Loader {
    param($path)
    return Get-Content $path -Raw | ConvertFrom-Json
}

# 二进制文件
lazy_load_register "icon.png" -Type "image" -Loader {
    param($path)
    return [System.IO.File]::ReadAllBytes($path)
}
```

### 预定义资源列表
```powershell
$resources = @{
    "biography" = @{ path = "data/biography.json"; type = "json"; priority = "high" }
    "patterns" = @{ path = "skills/copilot/patterns"; type = "directory"; priority = "medium" }
    "docs" = @{ path = "docs"; type = "directory"; priority = "low" }
}
```

## 加载策略

### 策略选项
- **lazy**: 延迟加载（默认）
- **eager**: 立即加载
- **preload**: 预加载到缓存
- **on-demand**: 按需加载后缓存

```powershell
.\lazy-loader.ps1 -Load "biography" -Strategy "eager"
.\lazy-loader.ps1 -Load "biography" -Strategy "preload"
```

## 性能监控

### 监控指标
- **加载时间**: 首次加载耗时
- **缓存命中率**: 从缓存读取的次数
- **内存占用**: 资源占用的内存
- **使用频率**: 资源被访问的次数

### 监控方法
```powershell
# 实时监控
.\lazy-loader.ps1 -Monitor -Interval 1000

# 保存监控报告
.\lazy-loader.ps1 -SaveReport "performance-report.json"
```

## 内存回收

### 自动回收
```powershell
# 设置空闲超时（秒）
.\lazy-loader.ps1 -SetIdleTimeout -Seconds 300

# 标记为不活跃
.\lazy-loader.ps1 -MarkInactive "biography"

# 强制回收所有不活跃资源
.\lazy-loader.ps1 -CollectIdle
```

### 手动回收
```powershell
# 回收特定资源
.\lazy-loader.ps1 -Free "biography"

# 回收低优先级资源
.\lazy-loader.ps1 -FreeLowPriority
```

## 错误处理

### 加载失败
```powershell
.\lazy-loader.ps1 -Load "non-existent.json" -OnError {
    param($error)
    Write-Host "加载失败: $($error.Message)"
    return $null
}
```

### 并发加载
```powershell
# 多个资源并发加载
$tasks = @(
    { Load "data/biography.json" },
    { Load "data/achievements.json" },
    { Load "data/photos.json" }
)
$results = .\lazy-loader.ps1 -ParallelLoad $tasks
```

## 最佳实践

1. **优先级分类**: 将资源分为高、中、低优先级
2. **大小管理**: 大文件使用延迟加载，小文件预加载
3. **按需释放**: 不再需要的资源及时释放
4. **监控优化**: 定期检查性能指标并优化
5. **缓存策略**: 根据访问频率选择合适的缓存策略
