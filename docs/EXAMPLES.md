# OpenClaw 示例代码

本文档提供了OpenClaw系统的使用示例代码。

---

## 📋 目录

1. [PowerShell示例](#powershell示例)
2. [cURL示例](#curl示例)
3. [Python示例](#python示例)
4. [JavaScript示例](#javascript示例)
5. [SQL示例](#sql示例)
6. [YAML示例](#yaml示例)

---

## PowerShell示例

### 1. 获取系统状态

```powershell
# 获取系统状态
$response = Invoke-RestMethod -Uri "http://localhost:18789/api/health" -Method Get

Write-Host "System Status: $($response.status)"
Write-Host "Uptime: $($response.uptime) seconds"
Write-Host "Memory Used: $([math]::Round($response.memory.percentage, 2))%"
```

### 2. 运行集成测试

```powershell
# 运行集成测试
$response = Invoke-RestMethod -Uri "http://localhost:18789/api/integration/test" -Method Post

Write-Host "Tests Run: $($response.total)"
Write-Host "Passed: $($response.passed)"
Write-Host "Failed: $($response.failed)"
Write-Host "Success Rate: $($response.success_rate)%"
```

### 3. 创建备份

```powershell
# 创建备份
$body = @{
    type = "full"
    schedule = "daily"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "http://localhost:18789/api/backup" -Method Post -Body $body -ContentType "application/json"

Write-Host "Backup ID: $($response.backup_id)"
Write-Host "Files backed up: $($response.files_backed_up)"
```

### 4. 启用技能

```powershell
# 启用技能
$skillName = "code-mentor"
$headers = @{
    "Authorization" = "Bearer $env:GATEWAY_TOKEN"
}

try {
    Invoke-RestMethod -Uri "http://localhost:18789/api/skills/$skillName/enable" `
                      -Method Post -Headers $headers
    Write-Host "Skill enabled: $skillName"
} catch {
    Write-Host "Error enabling skill: $_"
}
```

### 5. 查看日志

```powershell
# 查看日志
$logPath = "C:\Users\Administrator\.openclaw\workspace\logs"
$logFiles = Get-ChildItem -Path $logPath -Filter "*.log"

foreach ($log in $logFiles) {
    Write-Host "Log: $($log.Name)"
    $lines = (Get-Content $log.FullName | Measure-Object -Line).Lines
    Write-Host "  Lines: $lines"
    Write-Host "  Size: $([math]::Round($log.Length / 1KB, 2)) KB"
}
```

### 6. 执行优化

```powershell
# 运行性能优化
.\scripts\response-optimizer.ps1 -Detailed
.\scripts\memory-optimizer.ps1 -Detailed

Write-Host "Optimizations completed successfully!"
```

---

## cURL示例

### 1. 系统健康检查

```bash
# 健康检查
curl -X GET http://localhost:18789/api/health \
  -H "Authorization: Bearer YOUR_TOKEN"

# 示例响应
# {
#   "status": "healthy",
#   "uptime": "123456",
#   "memory": {
#     "used": 51200000,
#     "available": 65536000,
#     "percentage": 43.2
#   }
# }
```

### 2. 运行测试

```bash
# 集成测试
curl -X POST http://localhost:18789/api/integration/test \
  -H "Authorization: Bearer YOUR_TOKEN"

# 压力测试
curl -X POST http://localhost:18789/api/stress/test \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "duration_seconds": 30,
    "concurrency": 10
  }'
```

### 3. 备份管理

```bash
# 创建备份
curl -X POST http://localhost:18789/api/backup \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "full",
    "schedule": "daily"
  }'

# 获取备份列表
curl -X GET http://localhost:18789/api/backup/list \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 4. 技能管理

```bash
# 获取所有技能
curl -X GET http://localhost:18789/api/skills \
  -H "Authorization: Bearer YOUR_TOKEN"

# 启用技能
curl -X POST http://localhost:18789/api/skills/code-mentor/enable \
  -H "Authorization: Bearer YOUR_TOKEN"

# 禁用技能
curl -X POST http://localhost:18789/api/skills/code-mentor/disable \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 5. 性能优化

```bash
# 运行性能优化
curl -X POST http://localhost:18789/api/optimization/response \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "logging": true,
    "cache": true,
    "concurrency": true
  }'

# 清理缓存
curl -X POST http://localhost:18789/api/cache/clear \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## Python示例

### 1. 安装依赖

```bash
pip install requests
```

### 2. 获取系统状态

```python
import requests
import os

# 配置
URL = "http://localhost:18789/api/health"
TOKEN = os.getenv('GATEWAY_TOKEN')
HEADERS = {
    "Authorization": f"Bearer {TOKEN}"
}

try:
    response = requests.get(URL, headers=HEADERS)
    data = response.json()

    print(f"System Status: {data['status']}")
    print(f"Uptime: {data['uptime']} seconds")
    print(f"Memory Used: {data['memory']['percentage']}%")

except Exception as e:
    print(f"Error: {e}")
```

### 3. 运行测试

```python
import requests
import os
import json

# 配置
URL = "http://localhost:18789/api/integration/test"
TOKEN = os.getenv('GATEWAY_TOKEN')
HEADERS = {
    "Authorization": f"Bearer {TOKEN}",
    "Content-Type": "application/json"
}

try:
    response = requests.post(URL, headers=HEADERS)
    data = response.json()

    print(f"Tests Run: {data['total']}")
    print(f"Passed: {data['passed']}")
    print(f"Failed: {data['failed']}")
    print(f"Success Rate: {data['success_rate']}%")

except Exception as e:
    print(f"Error: {e}")
```

### 4. 创建备份

```python
import requests
import os
import json
from datetime import datetime

# 配置
URL = "http://localhost:18789/api/backup"
TOKEN = os.getenv('GATEWAY_TOKEN')
HEADERS = {
    "Authorization": f"Bearer {TOKEN}",
    "Content-Type": "application/json"
}

try:
    body = {
        "type": "full",
        "schedule": "daily"
    }

    response = requests.post(URL, headers=HEADERS, json=body)
    data = response.json()

    print(f"Backup ID: {data['backup_id']}")
    print(f"Files backed up: {data['files_backed_up']}")

except Exception as e:
    print(f"Error: {e}")
```

### 5. 启用技能

```python
import requests
import os

# 配置
URL = "http://localhost:18789/api/skills/code-mentor/enable"
TOKEN = os.getenv('GATEWAY_TOKEN')
HEADERS = {
    "Authorization": f"Bearer {TOKEN}"
}

try:
    response = requests.post(URL, headers=HEADERS)
    print("Skill enabled successfully!")

except Exception as e:
    print(f"Error: {e}")
```

### 6. 日志监控

```python
import time
import os

# 配置
LOG_PATH = "C:\\Users\\Administrator\\.openclaw\\workspace\\logs"
TOKEN = os.getenv('GATEWAY_TOKEN')

try:
    while True:
        # 获取最新的日志文件
        log_files = os.listdir(LOG_PATH)
        if log_files:
            latest_log = os.path.join(LOG_PATH, max(log_files))

            # 读取最后100行
            with open(latest_log, 'r', encoding='utf-8') as f:
                lines = f.readlines()
                print("\n".join(lines[-100:]))

        print("\n" + "="*50 + "\n")
        time.sleep(10)

except KeyboardInterrupt:
    print("\nMonitoring stopped.")
```

---

## JavaScript示例

### 1. 获取系统状态

```javascript
// 获取系统状态
async function getSystemStatus() {
    try {
        const response = await fetch('http://localhost:18789/api/health', {
            headers: {
                'Authorization': `Bearer ${process.env.GATEWAY_TOKEN}`
            }
        });

        const data = await response.json();
        console.log(`System Status: ${data.status}`);
        console.log(`Uptime: ${data.uptime} seconds`);
        console.log(`Memory Used: ${data.memory.percentage}%`);
        return data;
    } catch (error) {
        console.error('Error:', error);
    }
}

// 执行
getSystemStatus();
```

### 2. 运行测试

```javascript
// 运行集成测试
async function runIntegrationTest() {
    try {
        const response = await fetch('http://localhost:18789/api/integration/test', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${process.env.GATEWAY_TOKEN}`,
                'Content-Type': 'application/json'
            }
        });

        const data = await response.json();
        console.log(`Tests Run: ${data.total}`);
        console.log(`Passed: ${data.passed}`);
        console.log(`Failed: ${data.failed}`);
        console.log(`Success Rate: ${data.success_rate}%`);

        return data;
    } catch (error) {
        console.error('Error:', error);
    }
}

// 执行
runIntegrationTest();
```

### 3. 创建备份

```javascript
// 创建备份
async function createBackup() {
    try {
        const response = await fetch('http://localhost:18789/api/backup', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${process.env.GATEWAY_TOKEN}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                type: 'full',
                schedule: 'daily'
            })
        });

        const data = await response.json();
        console.log(`Backup ID: ${data.backup_id}`);
        console.log(`Files backed up: ${data.files_backed_up}`);

        return data;
    } catch (error) {
        console.error('Error:', error);
    }
}

// 执行
createBackup();
```

### 4. 启用技能

```javascript
// 启用技能
async function enableSkill(skillName) {
    try {
        const response = await fetch(`http://localhost:18789/api/skills/${skillName}/enable`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${process.env.GATEWAY_TOKEN}`
            }
        });

        console.log(`Skill ${skillName} enabled successfully!`);

    } catch (error) {
        console.error('Error:', error);
    }
}

// 执行
enableSkill('code-mentor');
```

### 5. WebSocket监控

```javascript
// WebSocket监控
const ws = new WebSocket('ws://localhost:18789/ws');

ws.onopen = () => {
    console.log('Connected to OpenClaw WebSocket');
    ws.send(JSON.stringify({
        type: 'subscribe',
        event: 'system.health'
    }));
};

ws.onmessage = (event) => {
    const data = JSON.parse(event.data);
    if (data.type === 'system.health') {
        console.log('Health:', data.data);
    }
};

ws.onerror = (error) => {
    console.error('WebSocket Error:', error);
};

ws.onclose = () => {
    console.log('Disconnected');
};
```

---

## SQL示例

### 1. 查询日志

```sql
-- 查询最近的错误
SELECT * FROM logs
WHERE level = 'ERROR'
ORDER BY timestamp DESC
LIMIT 100;

-- 查询慢查询
SELECT query, mean_exec_time, calls
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;

-- 统计错误数量
SELECT level, COUNT(*) as count
FROM logs
GROUP BY level
ORDER BY count DESC;

-- 查询备份历史
SELECT backup_id, created_at, status, size
FROM backups
ORDER BY created_at DESC
LIMIT 10;
```

### 2. 优化查询

```sql
-- 添加索引
CREATE INDEX idx_logs_level_timestamp ON logs(level, timestamp DESC);
CREATE INDEX idx_backups_created_at ON backups(created_at DESC);

-- 分析查询性能
EXPLAIN ANALYZE
SELECT * FROM logs
WHERE created_at > '2026-01-01'
ORDER BY timestamp DESC;

-- 清理旧数据
DELETE FROM logs
WHERE timestamp < NOW() - INTERVAL '30 days';
```

---

## YAML示例

### 1. 配置文件

```yaml
# openclaw-config.yml
gateway:
  port: 18789
  bind: loopback
  trusted_proxies: []

api:
  enabled: true
  rate_limit:
    requests_per_minute: 1000
    connections_per_minute: 50

cache:
  enabled: true
  backend: redis
  ttl: 300
  max_size_mb: 100

logging:
  level: INFO
  rotation_size_mb: 10
  retention_days: 30

backup:
  enabled: true
  schedule: "0 2 * * *"
  retention_days: 7
```

### 2. 备份任务

```yaml
# backup-tasks.yml
tasks:
  - name: daily-backup
    schedule: "0 2 * * *"
    type: "full"
    destination: "local"
    retention: 7

  - name: incremental-backup
    schedule: "0 6 * * *"
    type: "incremental"
    destination: "remote"
    retention: 30
```

### 3. 监控配置

```yaml
# monitoring.yml
prometheus:
  enabled: true
  port: 9090
  scrape_interval: 15s

graffana:
  enabled: true
  dashboard_id: 12345

alerts:
  - name: high_memory_usage
    condition: memory_usage_percentage > 90
    severity: critical
    notification: email

  - name: slow_response
    condition: response_time_ms > 1000
    severity: warning
    notification: webhook
```

---

## 最佳实践示例

### 1. 错误处理

```python
import requests
import time

def api_call_with_retry(url, headers, max_retries=3):
    """带重试机制的API调用"""
    for attempt in range(max_retries):
        try:
            response = requests.get(url, headers=headers)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 429:
                wait_time = (2 ** attempt) * 60
                print(f"Rate limited. Waiting {wait_time}s...")
                time.sleep(wait_time)
                continue
            else:
                print(f"HTTP Error: {e}")
                return None
        except Exception as e:
            print(f"Error: {e}")
            return None

    return None
```

### 2. 批量操作

```python
import requests
import json

def batch_operations(operations):
    """批量执行操作"""
    results = []
    for operation in operations:
        try:
            response = requests.post(
                operation['url'],
                headers=operation.get('headers', {}),
                json=operation.get('body', {})
            )
            results.append({
                'success': response.status_code == 200,
                'data': response.json() if response.content else None,
                'error': None if response.status_code == 200 else str(response.content)
            })
        except Exception as e:
            results.append({
                'success': False,
                'data': None,
                'error': str(e)
            })

    return results
```

### 3. 缓存策略

```python
import requests
import time
from functools import wraps

def cache_result(ttl=300):
    """缓存装饰器"""
    cache = {}

    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            cache_key = f"{func.__name__}:{str(args)}:{str(kwargs)}"

            # 检查缓存
            if cache_key in cache:
                cached_time, cached_result = cache[cache_key]
                if time.time() - cached_time < ttl:
                    return cached_result

            # 执行函数
            result = func(*args, **kwargs)

            # 更新缓存
            cache[cache_key] = (time.time(), result)

            return result

        return wrapper
    return decorator
```

---

## 故障排除示例

### 1. 验证配置

```python
def validate_config():
    """验证配置完整性"""
    required = {
        'GATEWAY_URL': 'http://localhost:18789',
        'GATEWAY_TOKEN': os.getenv('GATEWAY_TOKEN'),
        'BACKUP_RETENTION_DAYS': '7',
        'LOG_LEVEL': 'INFO'
    }

    missing = []
    for key, default in required.items():
        if not os.getenv(key):
            missing.append(key)
            os.environ[key] = default
            print(f"Missing {key}, using default: {default}")

    if missing:
        print(f"Config validated with {len(missing)} defaults set")
    else:
        print("All config validated!")

    return missing
```

### 2. 性能监控

```python
import time
import psutil

def monitor_performance():
    """性能监控"""
    process = psutil.Process()

    while True:
        cpu = process.cpu_percent()
        memory = process.memory_info().rss / 1024 / 1024  # MB
        disk = process.memory_info().rss / 1024 / 1024 / 1024  # GB

        print(f"CPU: {cpu}% | Memory: {memory:.2f}MB | Disk: {disk:.2f}GB")

        if cpu > 80:
            print("WARNING: High CPU usage!")
        if memory > 512:
            print("WARNING: High memory usage!")

        time.sleep(10)

if __name__ == "__main__":
    monitor_performance()
```

---

**版本**: 1.0.0
**最后更新**: 2026-02-14
**维护者**: OpenClaw Team
