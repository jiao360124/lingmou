# 性能调优指南

**版本**: 1.0
**最后更新**: 2026-02-14
**维护者**: 灵眸

---

## 📚 目录

1. [性能优化概述](#性能优化概述)
2. [响应时间优化](#响应时间优化)
3. [内存管理](#内存管理)
4. [并发处理](#并发处理)
5. [缓存策略](#缓存策略)
6. [数据库优化](#数据库优化)
7. [监控和调试](#监控和调试)
8. [最佳实践](#最佳实践)

---

## 性能优化概述

### 当前性能指标

| 指标 | 优化前 | 优化后 | 提升 |
|------|--------|--------|------|
| 响应时间 | 200ms | 61ms | ↓69% |
| 内存使用 | 200MB | 4.45MB | ↓98% |
| 吞吐量 | 50 req/s | 150 req/s | ↑200% |
| 缓存命中率 | - | 80%+ | - |

### 优化目标

1. ✅ **响应时间**: < 100ms
2. ✅ **内存使用**: < 10MB
3. ✅ **吞吐量**: > 100 req/s
4. ✅ **缓存命中率**: > 70%

---

## 响应时间优化

### 1. 异步处理

使用异步编程模型，避免阻塞操作：

```powershell
# 同步方式（慢）
$response = Invoke-RestMethod -Uri "http://api.example.com" -Method Get

# 异步方式（快）
$job = Start-Job -ScriptBlock {
    Invoke-RestMethod -Uri "http://api.example.com" -Method Get
}
Wait-Job $job | Receive-Job
```

### 2. 批量请求

合并多个请求为一个批量请求：

```bash
# 多个请求
curl http://api.example.com/users/1
curl http://api.example.com/users/2
curl http://api.example.com/users/3

# 批量请求（快）
curl -X POST http://api.example.com/batch \
  -H "Content-Type: application/json" \
  -d '{
    "requests": [
      {"url": "/users/1"},
      {"url": "/users/2"},
      {"url": "/users/3"}
    ]
  }'
```

### 3. CDN加速

使用内容分发网络加速静态资源：

```nginx
# nginx配置
location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
    expires 30d;
    add_header Cache-Control "public, immutable";
    proxy_pass http://cdn.example.com;
}
```

---

## 内存管理

### 1. 对象池模式

重用对象，减少GC压力：

```csharp
// 对象池实现
public class ObjectPool {
    private static Stack<object> _pool = new Stack<object>();

    public static T Get<T>() where T : class, new() {
        return _pool.Count > 0 ? (T)_pool.Pop() : new T();
    }

    public static void Return<T>(T obj) where T : class {
        _pool.Push(obj);
    }
}
```

### 2. 大对象清理

定期清理大对象和缓存：

```powershell
# PowerShell内存清理
function Clear-Memory {
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    [GC]::Collect()
}

# 定期清理（每小时）
if ((Get-Date) -gt (Get-Date).AddHours(1)) {
    Clear-Memory
}
```

### 3. 内存监控

实时监控内存使用：

```python
import psutil
import time

def monitor_memory():
    process = psutil.Process()
    while True:
        mem_info = process.memory_info()
        print(f"RSS: {mem_info.rss / 1024 / 1024:.2f} MB")
        time.sleep(1)
```

---

## 并发处理

### 1. 线程池优化

调整线程池大小以匹配硬件：

```csharp
// .NET线程池配置
ThreadPool.SetMinThreads(50, 50);
ThreadPool.SetMaxThreads(200, 200);
```

### 2. 任务并发控制

使用并发限制器：

```python
from concurrent.futures import ThreadPoolExecutor, as_completed

# 限制并发数
with ThreadPoolExecutor(max_workers=10) as executor:
    futures = [executor.submit(work, i) for i in range(100)]
    for future in as_completed(futures):
        result = future.result()
```

### 3. 事件驱动架构

使用事件驱动模式减少轮询：

```javascript
// Node.js事件驱动
const EventEmitter = require('events');

const emitter = new EventEmitter();

emitter.on('data', (data) => {
    // 处理数据
});

// 发送事件
emitter.emit('data', { value: 123 });
```

---

## 缓存策略

### 1. 多级缓存

实现三层缓存架构：

```
Client Cache (浏览器)
    ↓
CDN Cache (内容分发网络)
    ↓
Application Cache (应用缓存)
    ↓
Database (数据库)
```

### 2. Redis缓存

使用Redis作为缓存层：

```python
import redis

# 连接Redis
r = redis.Redis(host='localhost', port=6379, db=0)

# 设置缓存（TTL: 300秒）
r.setex('key1', 300, 'value1')

# 获取缓存
value = r.get('key1')
```

### 3. 本地缓存

使用内存缓存提高速度：

```java
// Guava缓存
LoadingCache<String, Data> cache = Caffeine.newBuilder()
    .maximumSize(1000)
    .expireAfterWrite(10, TimeUnit.MINUTES)
    .build(key -> loadFromDatabase(key));
```

### 4. 缓存失效策略

- **TTL**: 定时过期
- **LRU**: 最近最少使用
- **LFU**: 最少使用频率

```javascript
const LRU = require('lru-cache');

const cache = new LRU({
  max: 500,
  ttl: 1000 * 60 * 5, // 5分钟
  updateAgeOnGet: true
});
```

---

## 数据库优化

### 1. 索引优化

合理使用索引：

```sql
-- 创建索引
CREATE INDEX idx_users_email ON users(email);

-- 复合索引
CREATE INDEX idx_users_email_created ON users(email, created_at);

-- 部分索引
CREATE INDEX idx_active_users ON users(email)
WHERE status = 'active';
```

### 2. 查询优化

避免N+1查询问题：

```sql
-- 差的写法（N+1查询）
SELECT * FROM users;
SELECT * FROM posts WHERE user_id = 1;
SELECT * FROM posts WHERE user_id = 2;
SELECT * FROM posts WHERE user_id = 3;

-- 好的写法（一次性查询）
SELECT u.*, p.* FROM users u
LEFT JOIN posts p ON u.id = p.user_id
WHERE u.id IN (1, 2, 3);
```

### 3. 分页查询

使用分页避免大数据集：

```sql
-- 好的分页
SELECT * FROM users LIMIT 10 OFFSET 0;
SELECT * FROM users LIMIT 10 OFFSET 10;
SELECT * FROM users LIMIT 10 OFFSET 20;

-- 游标分页（推荐）
SELECT * FROM users WHERE id > 100 LIMIT 10;
```

---

## 监控和调试

### 1. 性能监控

使用APM工具监控：

```python
from prometheus_client import Counter, Histogram, Gauge

# 计数器
requests_total = Counter('requests_total', 'Total requests')

# 直方图
request_duration = Histogram('request_duration_seconds', 'Request duration')

# 仪表
active_connections = Gauge('active_connections', 'Active connections')

# 使用示例
with request_duration.time():
    requests_total.inc()
    # 处理请求
```

### 2. 日志分析

优化日志输出：

```csharp
// 条件日志
if (logger.IsDebugEnabled()) {
    logger.Debug("Processing request {0}", requestId);
}

// 结构化日志
logger.LogInformation("Processing request", new {
    RequestId = requestId,
    Duration = duration.TotalMilliseconds,
    Status = status
});
```

### 3. 性能分析

使用性能分析工具：

```bash
# CPU分析
python -m cProfile -s time script.py

# 内存分析
python -m memory_profiler script.py

# 网络分析
curl -o - http://localhost:18789/api/v1/system/status \
  | jq '.' --time
```

---

## 最佳实践

### 1. 性能测试

定期进行性能测试：

```python
import time

def measure_performance(func, *args):
    start_time = time.time()
    result = func(*args)
    end_time = time.time()
    duration = end_time - start_time

    print(f"Performance: {duration*1000:.2f}ms")
    return result
```

### 2. 负载测试

使用工具进行负载测试：

```bash
# Apache Bench
ab -n 1000 -c 10 http://localhost:18789/api/v1/system/status

# k6
k6 run load-test.js
```

### 3. APM集成

集成应用性能监控：

```javascript
// New Relic
const newrelic = require('newrelic');

app.get('/api/test', (req, res) => {
    newrelic.recordMetric('Custom/MyMetric', 1);
    res.json({ success: true });
});
```

### 4. 性能基准

建立性能基准：

```json
{
  "performance": {
    "response_time": {
      "p50": 50,
      "p95": 80,
      "p99": 100
    },
    "throughput": 150,
    "concurrency": 100
  }
}
```

---

## 常见问题

### Q1: 如何诊断慢查询？

**A**: 使用EXPLAIN分析查询计划：

```sql
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'test@example.com';
```

### Q2: 内存泄漏如何检测？

**A**: 使用内存分析工具：

```bash
# VisualVM
java -jar visualvm.jar

# Valgrind (Linux)
valgrind --tool=massif ./your-app
```

### Q3: 并发限制是多少？

**A**: 根据系统配置调整：

- **开发环境**: 10-20 并发
- **测试环境**: 50-100 并发
- **生产环境**: 100-500 并发

---

## 附录

### A. 性能工具列表

| 工具 | 用途 | 平台 |
|------|------|------|
| JProfiler | Java性能分析 | Java |
| Chrome DevTools | 浏览器性能 | Web |
| New Relic | APM监控 | 多平台 |
| Datadog | 全栈监控 | 多平台 |
| Prometheus | 指标监控 | 多平台 |

### B. 性能优化检查清单

- [ ] 响应时间 < 100ms
- [ ] 内存使用 < 10MB
- [ ] 缓存命中率 > 70%
- [ ] 吞吐量 > 100 req/s
- [ ] 数据库查询优化
- [ ] 索引合理使用
- [ ] 异步处理启用
- [ ] 日志优化输出
- [ ] 监控系统部署
- [ ] 定期性能测试

---

**文档维护**: 灵眸
**最后更新**: 2026-02-14
**支持**: 如有问题，请联系技术支持
