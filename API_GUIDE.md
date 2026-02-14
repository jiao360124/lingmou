# API 使用指南

**版本**: 1.0
**最后更新**: 2026-02-14
**维护者**: 灵眸

---

## 📚 目录

1. [简介](#简介)
2. [认证方式](#认证方式)
3. [核心端点](#核心端点)
4. [请求格式](#请求格式)
5. [响应格式](#响应格式)
6. [错误处理](#错误处理)
7. [速率限制](#速率限制)
8. [示例代码](#示例代码)

---

## 简介

本指南提供了OpenClaw Gateway的API完整说明。API基于RESTful设计，支持JSON格式的请求和响应。

### 基础URL

- **开发环境**: `http://localhost:18789`
- **生产环境**: `https://api.openclaw.ai`

### 版本控制

当前版本: **v1.0**
API版本包含在请求头中: `OpenClaw-Version: 1.0`

---

## 认证方式

### API Key认证

所有API请求需要在Header中包含API Key:

```
Authorization: Bearer YOUR_API_KEY
```

**获取API Key**:
1. 登录 OpenClaw Dashboard
2. 进入 Settings → API Keys
3. 点击 "Generate New Key"

### 私有Token（内部）

用于内部服务间通信的私有Token，存储在 `.env` 文件中。

---

## 核心端点

### 1. 会话管理

#### 2.1 创建会话

```http
POST /api/v1/sessions
Content-Type: application/json
Authorization: Bearer YOUR_API_KEY

{
  "model": "zai/glm-4.7-flash",
  "messages": [
    {"role": "user", "content": "Hello"}
  ],
  "context": {
    "sessionId": "optional-session-id"
  }
}
```

**响应**:
```json
{
  "sessionId": "session-123",
  "status": "active",
  "createdAt": "2026-02-14T22:00:00Z"
}
```

#### 2.2 发送消息

```http
POST /api/v1/sessions/{sessionId}/messages
Content-Type: application/json
Authorization: Bearer YOUR_API_KEY

{
  "message": {
    "role": "user",
    "content": "Your message here"
  }
}
```

**响应**:
```json
{
  "message": {
    "role": "assistant",
    "content": "Response here"
  },
  "usage": {
    "promptTokens": 100,
    "completionTokens": 50
  }
}
```

### 2. Cron任务管理

#### 2.3 创建Cron任务

```http
POST /api/v1/cron/jobs
Content-Type: application/json
Authorization: Bearer YOUR_API_KEY

{
  "name": "daily-backup",
  "schedule": {
    "kind": "every",
    "everyMs": 86400000
  },
  "payload": {
    "kind": "systemEvent",
    "text": "Running daily backup"
  }
}
```

#### 2.4 列出Cron任务

```http
GET /api/v1/cron/jobs
Authorization: Bearer YOUR_API_KEY
```

**响应**:
```json
{
  "jobs": [
    {
      "id": "job-123",
      "name": "daily-backup",
      "status": "enabled",
      "nextRun": "2026-02-15T00:00:00Z"
    }
  ]
}
```

### 3. 系统管理

#### 2.5 获取系统状态

```http
GET /api/v1/system/status
Authorization: Bearer YOUR_API_KEY
```

**响应**:
```json
{
  "gateway": "running",
  "version": "2026.2.13",
  "uptime": "3600s",
  "resources": {
    "tokenUsage": 250000,
    "contextUsage": 43000,
    "queueDepth": 0
  }
}
```

---

## 请求格式

### Headers

```http
Content-Type: application/json
Authorization: Bearer YOUR_API_KEY
OpenClaw-Version: 1.0
X-Request-ID: unique-request-id
```

### Body示例

```json
{
  "model": "zai/glm-4.7-flash",
  "messages": [
    {"role": "system", "content": "You are a helpful assistant"},
    {"role": "user", "content": "Hello"}
  ],
  "temperature": 0.7,
  "maxTokens": 1000
}
```

---

## 响应格式

### 成功响应

```json
{
  "success": true,
  "data": {
    // 实际数据
  },
  "timestamp": "2026-02-14T22:00:00Z"
}
```

### 错误响应

```json
{
  "success": false,
  "error": {
    "code": "INVALID_REQUEST",
    "message": "Invalid API key",
    "details": "Please provide a valid API key in Authorization header"
  },
  "timestamp": "2026-02-14T22:00:00Z"
}
```

---

## 错误处理

### 错误码

| 错误码 | 说明 | 解决方案 |
|--------|------|----------|
| `UNAUTHORIZED` | API Key无效 | 检查Authorization header |
| `INVALID_REQUEST` | 请求格式错误 | 查看错误details |
| `NOT_FOUND` | 资源不存在 | 检查resource ID |
| `RATE_LIMIT_EXCEEDED` | 速率限制 | 降低请求频率 |
| `INTERNAL_ERROR` | 服务器错误 | 稍后重试 |

### 错误处理示例

```json
{
  "error": {
    "code": "INVALID_REQUEST",
    "message": "Missing required field",
    "details": "The field 'model' is required"
  }
}
```

---

## 速率限制

### 限制规则

| 资源 | 限制 | 重置周期 |
|------|------|----------|
| Token | 1,000,000/周期 | 1分钟 |
| Context | 200,000 tokens | 1分钟 |
| Requests | 60/min | 1分钟 |

### 速率限制响应

```json
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Rate limit exceeded",
    "details": "Try again in 30 seconds",
    "retryAfter": 30
  }
}
```

---

## 示例代码

### cURL 示例

```bash
# 发送消息
curl -X POST http://localhost:18789/api/v1/sessions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "model": "zai/glm-4.7-flash",
    "messages": [
      {"role": "user", "content": "Hello"}
    ]
  }'

# 检查系统状态
curl -X GET http://localhost:18789/api/v1/system/status \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### Python 示例

```python
import requests
import json

# 配置
API_URL = "http://localhost:18789/api/v1"
API_KEY = "YOUR_API_KEY"

# 发送消息
def send_message(messages):
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {API_KEY}"
    }

    payload = {
        "model": "zai/glm-4.7-flash",
        "messages": messages
    }

    response = requests.post(
        f"{API_URL}/sessions",
        headers=headers,
        data=json.dumps(payload)
    )

    return response.json()

# 使用示例
messages = [
    {"role": "user", "content": "Hello"}
]

result = send_message(messages)
print(json.dumps(result, indent=2))
```

### JavaScript (Node.js) 示例

```javascript
const axios = require('axios');

const API_URL = 'http://localhost:18789/api/v1';
const API_KEY = 'YOUR_API_KEY';

async function sendMessage(messages) {
  const response = await axios.post(`${API_URL}/sessions`, {
    model: 'zai/glm-4.7-flash',
    messages: messages
  }, {
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${API_KEY}`
    }
  });

  return response.data;
}

// 使用示例
sendMessage([
  { role: 'user', content: 'Hello' }
]).then(result => console.log(result));
```

---

## 附录

### A. 支持的模型

| 模型ID | 模型名称 | 说明 |
|--------|----------|------|
| zai/glm-4.7-flash | GLM-4.7 Flash | 默认模型，快速响应 |
| zai/glm-4.5-flash | GLM-4.5 Flash | 平衡性能和成本 |
| zai/glm-4-flash-250414 | GLM-4 Flash | 最新版本 |

### B. 变更历史

| 版本 | 日期 | 变更 |
|------|------|------|
| 1.0 | 2026-02-14 | 初始版本 |

---

**文档维护**: 灵眸
**最后更新**: 2026-02-14
**支持**: 如有问题，请联系技术支持
