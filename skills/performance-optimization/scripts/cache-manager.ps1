# 智能缓存管理器

## 功能
- 多级缓存架构
- 智能失效策略
- 缓存预热
- 缓存穿透保护

## 多级缓存架构

### 缓存层级
1. **L1: 内存缓存** (RAM)
   - 速度最快，容量小（100MB）
   - 存储高频访问数据
   - TTL: 5-15分钟

2. **L2: 持久化缓存** (磁盘)
   - 速度中等，容量大（1GB）
   - 存储中等频率数据
   - TTL: 1-24小时

3. **L3: 远程缓存** (可选)
   - 速度较慢，容量最大
   - 存储冷数据
   - TTL: 1-7天

## 使用方法

### 基础缓存操作

#### 缓存读取
```powershell
# 获取缓存
$data = .\cache-manager.ps1 -Get -Key "biography"

# 获取缓存（带默认值）
$data = .\cache-manager.ps1 -Get -Key "biography" -Default $defaultValue

# 检查缓存是否存在
$exists = .\cache-manager.ps1 -Exists -Key "biography"

# 获取缓存统计
$stats = .\cache-manager.ps1 -GetStats
```

#### 缓存写入
```powershell
# 设置缓存（默认TTL 3600秒）
.\cache-manager.ps1 -Set -Key "biography" -Value $data

# 设置缓存（自定义TTL）
.\cache-manager.ps1 -Set -Key "biography" -Value $data -TTL 7200

# 设置缓存（自定义优先级）
.\cache-manager.ps1 -Set -Key "biography" -Value $data -Priority "high"

# 批量设置缓存
.\cache-manager.ps1 -SetBatch @(
    @{ key = "pattern1"; value = $data1 },
    @{ key = "pattern2"; value = $data2 }
)
```

#### 缓存删除
```powershell
# 删除缓存
.\cache-manager.ps1 -Delete -Key "biography"

# 删除模式匹配的缓存
.\cache-manager.ps1 -DeleteByPattern -Pattern "*biography*"

# 删除特定优先级的缓存
.\cache-manager.ps1 -DeleteByPriority -Priority "low"

# 清空所有缓存
.\cache-manager.ps1 -Clear -All

# 清空特定缓存层
.\cache-manager.ps1 -Clear -Level "l1"
```

## 智能失效策略

### 基于时间的失效
```powershell
# 固定TTL
.\cache-manager.ps1 -Set -Key "config" -Value $data -TTL 3600

# 相对TTL（从当前时间计算）
.\cache-manager.ps1 -Set -Key "biography" -Value $data -TTLRelative 7200

# 绝对过期时间
.\cache-manager.ps1 -Set -Key "session" -Value $data -ExpiresAt (Get-Date).AddHours(2)
```

### 基于访问频率的失效
```powershell
# 低频访问自动失效（LRU策略）
.\cache-manager.ps1 -Set -Key "archive" -Value $data -AccessThreshold 10 -TTL 86400

# 频繁访问保持新鲜（LFU策略）
.\cache-manager.ps1 -Set -Key "popular" -Value $data -FrequencySensitive
```

### 基于内容变化的失效
```powershell
# 内容哈希检测
.\cache-manager.ps1 -Set -Key "document" -Value $data -ContentHash $hash

# 依赖检测
.\cache-manager.ps1 -Set -Key "combined" -Value $data -Dependencies @("data1", "data2")
```

## 缓存预热

### 自动预热
```powershell
# 预加载配置文件
.\cache-manager.ps1 -Preload -Pattern "config*"

# 预加载热门资源
.\cache-manager.ps1 -Preload -Pattern "biography*"
.\cache-manager.ps1 -Preload -Pattern "patterns/*"

# 预加载所有高优先级资源
.\cache-manager.ps1 -Preload -Priority "high"
```

### 手动预热
```powershell
# 预热特定资源
.\cache-manager.ps1 -Warmup -Keys @("config", "biography", "patterns")
```

## 缓存穿透保护

### 缓存空值
```powershell
# 缓存不存在的键
.\cache-manager.ps1 -Set -Key "non-existent-key" -Value $null -TTL 300

# 使用布隆过滤器（高级）
.\cache-manager.ps1 -UseBloomFilter -Enabled $true
```

### 请求限流
```powershell
# 限制查询速率
.\cache-manager.ps1 -RateLimit -Key "search" -MaxRequests 10 -TimeWindow 60

# 限流模式
.\cache-manager.ps1 -SetRateLimit -Key "search" -MaxRequests 20 -TimeWindow 60
```

## 缓存监控

### 实时监控
```powershell
# 获取缓存统计
$stats = .\cache-manager.ps1 -GetStats

# 详细统计
$stats = .\cache-manager.ps1 -GetDetailedStats

# 获取缓存命中率
$hitRate = .\cache-manager.ps1 -GetHitRate

# 获取缓存大小
$size = .\cache-manager.ps1 -GetSize

# 获取缓存项
$items = .\cache-manager.ps1 -GetItems -Level "l1"
```

### 性能指标
```powershell
# 获取性能指标
$metrics = .\cache-manager.ps1 -GetMetrics

# 监控缓存性能
.\cache-manager.ps1 -Monitor -Interval 1000

# 保存性能报告
.\cache-manager.ps1 -SaveReport "cache-report.json"
```

## 缓存策略配置

### 策略选择
```powershell
# LRU（最近最少使用）
.\cache-manager.ps1 -SetStrategy -Level "l1" -Strategy "LRU"

# LFU（最不经常使用）
.\cache-manager.ps1 -SetStrategy -Level "l1" -Strategy "LFU"

# FIFO（先进先出）
.\cache-manager.ps1 -SetStrategy -Level "l1" -Strategy "FIFO"

# TTL（过期时间）
.\cache-manager.ps1 -SetStrategy -Level "l1" -Strategy "TTL"
```

### 容量配置
```powershell
# 设置缓存大小
.\cache-manager.ps1 -SetCapacity -Level "l1" -Size 100MB

# 设置缓存大小（L2）
.\cache-manager.ps1 -SetCapacity -Level "l2" -Size 1GB

# 设置缓存条目数
.\cache-manager.ps1 -SetMaxItems -Level "l1" -Count 10000
```

## 高级功能

### 缓存同步
```powershell
# 同步L1到L2
.\cache-manager.ps1 -Sync -From "l1" -To "l2"

# 跨实例同步
.\cache-manager.ps1 -Sync -Remote "192.168.1.100" -Port 8080
```

### 分布式缓存
```powershell
# 集群模式
.\cache-manager.ps1 -ClusterMode -Enabled $true

# 节点配置
.\cache-manager.ps1 -AddNode -Address "192.168.1.101" -Port 8080
```

### 缓存压缩
```powershell
# 启用压缩
.\cache-manager.ps1 -EnableCompression -Level "l1" -Enabled $true

# 设置压缩阈值（字节）
.\cache-manager.ps1 -SetCompressionThreshold -Level "l1" -Threshold 1024
```

## 缓存击穿处理

### 互斥锁
```powershell
# 防止缓存击穿
.\cache-manager.ps1 -EnableMutex -Key "expensive-key" -Enabled $true
```

### 限流器
```powershell
# 单个键的请求限流
.\cache-manager.ps1 -RateLimit -Key "expensive-key" -MaxRequests 100 -TimeWindow 60
```

## 最佳实践

1. **分层缓存**: 合理配置L1、L2、L3缓存
2. **TTL设置**: 根据数据变化频率设置TTL
3. **预热策略**: 系统启动时预热高频访问数据
4. **监控优化**: 定期检查缓存指标并优化
5. **穿透防护**: 缓存空值，防止缓存击穿
6. **压缩优化**: 大数据量启用压缩
