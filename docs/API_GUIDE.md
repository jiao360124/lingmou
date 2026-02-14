# OpenClaw API 使用指南

本文档提供了OpenClaw API的完整使用指南。

---

## 📋 目录

1. [API概述](#api概述)
2. [认证](#认证)
3. [端点](#端点)
4. [示例代码](#示例代码)
5. [错误处理](#错误处理)
6. [速率限制](#速率限制)

---

## API概述

### 基础URL

```
http://localhost:8080
```

### 认证方式

所有API端点需要认证。使用API Token：

```http
Authorization: Bearer YOUR_API_TOKEN
```

### 响应格式

所有响应使用JSON格式：

```json
{
  "status": "success",
  "data": {},
  "message": "Success"
}
```

---

## 认证

### 获取API Token

1. 登录系统
2. 访问设置页面
3. 生成API Token
4. 保存Token到环境变量

### 环境变量配置

```bash
# .env 文件
GATEWAY_TOKEN=your_api_token_here
```

### PowerShell 示例

```powershell
$headers = @{
    "Authorization" = "Bearer $env:GATEWAY_TOKEN"
}
```

### cURL 示例

```bash
curl -X GET http://localhost:8080/api/health \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 端点

### 1. 系统健康检查

**端点**: `GET /api/health`

**描述**: 检查系统健康状态

**响应**:

```json
{
  "status": "healthy",
  "uptime": "123456",
  "memory": {
    "used": 51200000,
    "available": 65536000,
    "percentage": 43.2
  },
  "disk": {
    "used": 251658240,
    "total": 1073741824,
    "percentage": 23.4
  }
}
```

### 2. 集成测试

**端点**: `POST /api/integration/test`

**描述**: 运行集成测试

**响应**:

```json
{
  "total": 8,
  "passed": 8,
  "failed": 0,
  "success_rate": 100.0,
  "results": [
    {
      "name": "Core Modules",
      "status": "pass"
    }
  ]
}
```

### 3. 备份管理

**端点**: `POST /api/backup`

**描述**: 创建备份

**请求体**:

```json
{
  "type": "full",
  "schedule": "daily"
}
```

**响应**:

```json
{
  "status": "success",
  "backup_id": "backup-20260214-001",
  "files_backed_up": 45,
  "size": 10485760
}
```

### 4. 获取备份列表

**端点**: `GET /api/backup/list`

**描述**: 获取备份历史

**响应**:

```json
{
  "backups": [
    {
      "id": "backup-20260214-001",
      "created_at": "2026-02-14T20:00:00Z",
      "size": 10485760,
      "type": "full"
    }
  ],
  "total": 10
}
```

### 5. 技能管理

**端点**: `GET /api/skills`

**描述**: 获取所有技能列表

**响应**:

```json
{
  "skills": [
    {
      "name": "code-mentor",
      "description": "Code programming tutor",
      "status": "enabled"
    }
  ],
  "total": 68
}
```

**端点**: `POST /api/skills/{name}/enable`

**描述**: 启用技能

**端点**: `POST /api/skills/{name}/disable`

**描述**: 禁用技能

---

## 示例代码

### PowerShell

#### 获取系统状态

```powershell
$uri = "http://localhost:8080/api/health"
$headers = @{
    "Authorization" = "Bearer $env:GATEWAY_TOKEN"
}

try {
    $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
    Write-Host "System Status: $($response.status)"
    Write-Host "Uptime: $($response.uptime) seconds"
    Write-Host "Memory Used: $([math]::Round($response.memory.percentage, 2))%"
} catch {
    Write-Host "Error: $_"
}
```

#### 运行集成测试

```powershell
$uri = "http://localhost:8080/api/integration/test"
$headers = @{
    "Authorization" = "Bearer $env:GATEWAY_TOKEN"
}

try {
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers
    Write-Host "Tests Run: $($response.total)"
    Write-Host "Passed: $($response.passed)"
    Write-Host "Failed: $($response.failed)"
    Write-Host "Success Rate: $($response.success_rate)%"
} catch {
    Write-Host "Error: $_"
}
```

### cURL

#### 创建备份

```bash
curl -X POST http://localhost:8080/api/backup \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "full",
    "schedule": "daily"
  }'
```

#### 获取备份列表

```bash
curl -X GET http://localhost:8080/api/backup/list \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Python

#### 安装依赖

```bash
pip install requests
```

#### 获取系统状态

```python
import requests
import os

TOKEN = os.getenv('GATEWAY_TOKEN')
URL = "http://localhost:8080/api/health"
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

---

## 错误处理

### HTTP状态码

| 状态码 | 描述 |
|--------|------|
| 200 | 成功 |
| 400 | 请求错误 |
| 401 | 未授权 |
| 403 | 禁止访问 |
| 404 | 未找到 |
| 500 | 服务器错误 |

### 错误响应格式

```json
{
  "status": "error",
  "error": {
    "code": "INVALID_TOKEN",
    "message": "Invalid API token"
  }
}
```

### 常见错误

#### 401 Unauthorized

**原因**: API Token无效或过期

**解决**:
```bash
# 重新获取Token
# 更新环境变量
export GATEWAY_TOKEN=new_token_here
```

#### 404 Not Found

**原因**: 端点不存在

**解决**: 检查API端点路径是否正确

#### 500 Internal Server Error

**原因**: 服务器内部错误

**解决**:
```bash
# 查看服务器日志
tail -f logs/openclaw.log
```

---

## 速率限制

### 限制规则

- **请求限制**: 1000次/分钟
- **连接限制**: 50个并发连接
- **备份限制**: 1个/小时

### 速率限制响应

```json
{
  "status": "error",
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Too many requests"
  },
  "retry_after": 60
}
```

### 指数退避

建议在遇到速率限制时使用指数退避策略：

```python
import time

def api_call_with_retry(url, headers, max_retries=3):
    for attempt in range(max_retries):
        try:
            response = requests.get(url, headers=headers)
            if response.status_code == 429:
                wait_time = (2 ** attempt) * 60
                time.sleep(wait_time)
                continue
            return response
        except Exception as e:
            time.sleep(2 ** attempt)
    raise Exception("Max retries exceeded")
```

---

## Webhook

### 配置Webhook

**端点**: `POST /api/webhooks`

**请求体**:

```json
{
  "url": "https://example.com/webhook",
  "events": ["backup.completed", "system.error"],
  "secret": "your_webhook_secret"
}
```

### 接收Webhook

```json
{
  "event": "backup.completed",
  "timestamp": "2026-02-14T20:00:00Z",
  "data": {
    "backup_id": "backup-20260214-001",
    "status": "success"
  }
}
```

---

## WebSocket

### 连接

```javascript
const ws = new WebSocket('ws://localhost:8080/ws');

ws.onopen = () => {
    console.log('Connected to OpenClaw');
    ws.send(JSON.stringify({
        type: 'subscribe',
        event: 'system.health'
    }));
};
```

### 接收消息

```json
{
  "type": "system.health",
  "data": {
    "status": "healthy",
    "uptime": 123456,
    "memory": 43.2
  }
}
```

---

## 最佳实践

### 1. 使用环境变量

✅ **推荐**:
```bash
# 从环境变量读取Token
TOKEN=$GATEWAY_TOKEN
```

❌ **不推荐**:
```bash
# 硬编码Token
TOKEN=abc123def456
```

### 2. 错误处理

```python
try:
    response = requests.get(url, headers=headers)
    response.raise_for_status()  # 检查HTTP错误
    return response.json()
except requests.exceptions.HTTPError as e:
    if e.response.status_code == 401:
        print("Invalid token, please renew")
    elif e.response.status_code == 429:
        print("Rate limit exceeded")
    raise
```

### 3. 超时设置

```python
response = requests.get(
    url,
    headers=headers,
    timeout=30  # 30秒超时
)
```

### 4. 日志记录

```python
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

logger = logging.getLogger(__name__)

logger.info("Making API request to %s", url)
```

---

## 故障排除

### API连接失败

**症状**: `Connection refused`

**检查**:
1. Gateway是否运行
2. 端口是否正确 (默认: 8080)
3. 防火墙设置

### 认证失败

**症状**: `401 Unauthorized`

**检查**:
1. Token是否正确
2. Token是否过期
3. Token格式是否正确

### 请求超时

**症状**: `TimeoutError`

**检查**:
1. 服务器是否响应
2. 网络是否正常
3. 是否存在速率限制

---

## 获取帮助

- **文档**: https://docs.openclaw.ai
- **GitHub**: https://github.com/openclaw/openclaw
- **Discord**: https://discord.com/invite/clawd
- **Email**: support@openclaw.ai

---

**版本**: 1.0.0
**最后更新**: 2026-02-14
**维护者**: OpenClaw Team
