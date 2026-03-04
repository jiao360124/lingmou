# OpenClaw API 文档

## 版本信息

- **当前版本**: 1.0.0
- **API版本**: v1
- **发布日期**: 2026-02-11

---

## 📚 目录

1. [API概述](#api概述)
2. [认证](#认证)
3. [集成管理器API](#集成管理器api)
4. [模块API](#模块api)
5. [配置API](#配置api)
6. [定时任务API](#定时任务api)
7. [错误代码](#错误代码)

---

## API概述

### 基础URL

```
http://127.0.0.1:18789
```

### 请求格式

- **Content-Type**: `application/json`
- **认证方式**: Bearer Token

### 响应格式

- **Content-Type**: `application/json`
- **编码**: UTF-8

### 响应示例

```json
{
  "success": true,
  "data": {
    "status": "ok",
    "message": "Operation successful"
  }
}
```

---

## 认证

### 获取Token

**请求**:

```http
GET /api/v1/auth/token
Authorization: Bearer YOUR_TOKEN
```

**响应**:

```json
{
  "success": true,
  "data": {
    "token": "your_access_token",
    "expires_in": 3600
  }
}
```

### Token管理

- Token有效期: 1小时
- 刷新Token: 需要重新获取
- 安全建议: 不要在代码中硬编码Token

---

## 集成管理器API

### 概述

集成管理器提供统一的系统管理接口。

### 端点

#### 1. 查看系统状态

**请求**:

```http
GET /api/v1/manager/status
```

**响应**:

```json
{
  "success": true,
  "data": {
    "total_modules": 19,
    "common_modules": 6,
    "performance_modules": 5,
    "testing_modules": 8,
    "modules": [
      {
        "name": "git-backup",
        "exists": true,
        "size_kb": 4.28,
        "last_modified": "2026-02-11T19:27:01Z"
      }
    ],
    "system_info": {
      "workspace": "/path/to/workspace",
      "scripts": "/path/to/scripts",
      "log_directory": "/path/to/logs",
      "memory_directory": "/path/to/memory",
      "backup_directory": "/path/to/backup"
    }
  }
}
```

---

#### 2. 运行健康检查

**请求**:

```http
GET /api/v1/manager/health
```

**响应**:

```json
{
  "success": true,
  "data": {
    "checks": [
      {
        "name": "Scripts Directory",
        "status": "OK",
        "message": "Scripts directory exists"
      },
      {
        "name": "Config: .env",
        "status": "WARNING",
        "message": "Configuration file not found"
      }
    ],
    "summary": {
      "ok": 9,
      "warning": 3,
      "error": 0
    }
  }
}
```

---

#### 3. 生成系统报告

**请求**:

```http
GET /api/v1/manager/report
```

**响应**:

```json
{
  "success": true,
  "data": {
    "overview": {
      "total_modules": 19,
      "common_modules": 6,
      "performance_modules": 5,
      "testing_modules": 8
    },
    "modules": {
      "Common": [...],
      "Performance": [...],
      "Testing": [...]
    },
    "directory_structure": {
      "logs": {
        "path": "./logs",
        "files": 2
      },
      "memory": {
        "path": "./memory",
        "files": 4
      }
    },
    "configuration_files": {
      ".env.example": {
        "path": "./.env.example",
        "size_kb": 0.71
      }
    },
    "script_statistics": {
      "total_scripts": 28,
      "total_size_mb": 0.2,
      "total_lines": 5183
    },
    "git_repository": {
      "branch": "main",
      "status": "Modified",
      "recent_commits": [...]
    }
  }
}
```

---

#### 4. 测试所有模块

**请求**:

```http
GET /api/v1/manager/test
```

**响应**:

```json
{
  "success": true,
  "data": {
    "tested": 19,
    "passed": 13,
    "failed": 6,
    "tested_modules": [
      {
        "name": "git-backup",
        "status": "passed",
        "message": "Syntax valid"
      },
      {
        "name": "response-optimizer",
        "status": "failed",
        "message": "Script not found"
      }
    ],
    "critical_tests": [
      {
        "name": "git-backup",
        "status": "passed"
      },
      {
        "name": "clear-context",
        "status": "passed"
      }
    ]
  }
}
```

---

#### 5. 启动所有模块

**请求**:

```http
POST /api/v1/manager/start
```

**响应**:

```json
{
  "success": true,
  "data": {
    "started": 13,
    "failed": 0,
    "details": [
      {
        "module": "git-backup",
        "status": "started"
      }
    ]
  }
}
```

---

#### 6. 停止所有模块

**请求**:

```http
POST /api/v1/manager/stop
```

**响应**:

```json
{
  "success": true,
  "data": {
    "message": "All modules stopped"
  }
}
```

---

## 模块API

### 概述

模块API用于管理和测试各个脚本模块。

### 端点

#### 1. 获取所有模块列表

**请求**:

```http
GET /api/v1/modules/list
```

**响应**:

```json
{
  "success": true,
  "data": {
    "common": [
      {
        "name": "clear-context",
        "description": "Clear OpenClaw context"
      },
      {
        "name": "git-backup",
        "description": "Git-based backup"
      }
    ],
    "performance": [
      {
        "name": "performance-benchmark",
        "description": "Performance benchmarking"
      }
    ],
    "testing": [
      {
        "name": "test-simple",
        "description": "Simple module test"
      }
    ]
  }
}
```

---

#### 2. 模块健康检查

**请求**:

```http
GET /api/v1/modules/{module_name}/health
```

**参数**:

- `module_name` (path): 模块名称

**响应**:

```json
{
  "success": true,
  "data": {
    "module_name": "git-backup",
    "exists": true,
    "status": "healthy",
    "version": "1.0.0",
    "last_modified": "2026-02-11T19:27:01Z",
    "size_kb": 4.28,
    "dependencies": ["git"]
  }
}
```

---

#### 3. 执行模块

**请求**:

```http
POST /api/v1/modules/{module_name}/execute
```

**参数**:

- `module_name` (path): 模块名称
- `params` (query): 模块参数

**响应**:

```json
{
  "success": true,
  "data": {
    "module_name": "git-backup",
    "status": "success",
    "output": "Git-Based Backup Started\nTime: 2026-02-11 19:27:01\n...",
    "exit_code": 0
  }
}
```

---

#### 4. 获取模块信息

**请求**:

```http
GET /api/v1/modules/{module_name}
```

**参数**:

- `module_name` (path): 模块名称

**响应**:

```json
{
  "success": true,
  "data": {
    "name": "git-backup",
    "description": "Git-based backup system",
    "version": "1.0.0",
    "author": "LingMou",
    "created_at": "2026-02-11T18:50:49Z",
    "last_modified": "2026-02-11T19:27:01Z",
    "category": "Common",
    "size_kb": 4.28,
    "parameters": [
      {
        "name": "DryRun",
        "type": "boolean",
        "default": false,
        "description": "Run in dry run mode"
      }
    ]
  }
}
```

---

## 配置API

### 概述

配置API用于管理和查询系统配置。

### 端点

#### 1. 获取环境变量

**请求**:

```http
GET /api/v1/config/environment
```

**响应**:

```json
{
  "success": true,
  "data": {
    "GATEWAY_PORT": {
      "value": "18789",
      "description": "Gateway port",
      "source": "file"
    },
    "CANVAS_PORT": {
      "value": "18789",
      "description": "Canvas port",
      "source": "file"
    }
  }
}
```

---

#### 2. 更新环境变量

**请求**:

```http
PUT /api/v1/config/environment
Content-Type: application/json

{
  "GATEWAY_PORT": "28089"
}
```

**响应**:

```json
{
  "success": true,
  "data": {
    "message": "Environment variables updated",
    "changes": [
      {
        "key": "GATEWAY_PORT",
        "old_value": "18789",
        "new_value": "28089"
      }
    ]
  }
}
```

---

#### 3. 获取端口配置

**请求**:

```http
GET /api/v1/config/ports
```

**响应**:

```json
{
  "success": true,
  "data": {
    "GATEWAY_PORT": {
      "current": "18789",
      "default": "18789",
      "description": "Gateway port"
    },
    "CANVAS_PORT": {
      "current": "18789",
      "default": "18789",
      "description": "Canvas port"
    }
  }
}
```

---

#### 4. 获取配置文件列表

**请求**:

```http
GET /api/v1/config/files
```

**响应**:

```json
{
  "success": true,
  "data": {
    "files": [
      {
        "path": "./.env",
        "exists": true,
        "size_kb": 0.33
      },
      {
        "path": "./.env.example",
        "exists": true,
        "size_kb": 0.71
      }
    ]
  }
}
```

---

## 定时任务API

### 概述

定时任务API用于管理和查询Cron任务。

### 端点

#### 1. 获取所有任务

**请求**:

```http
GET /api/v1/cron/jobs
```

**响应**:

```json
{
  "success": true,
  "data": {
    "jobs": [
      {
        "id": "4a5c7e41-88dd-46de-bb24-fc7bacc4c932",
        "name": "每日Git自动备份",
        "enabled": true,
        "schedule": {
          "kind": "every",
          "everyMs": 86400000
        },
        "session_target": "main",
        "state": {
          "next_run_at_ms": 1770893514989,
          "last_run_at_ms": 1770807114989,
          "last_status": "ok",
          "last_duration_ms": 5276
        }
      }
    ]
  }
}
```

---

#### 2. 添加任务

**请求**:

```http
POST /api/v1/cron/jobs
Content-Type: application/json

{
  "name": "自定义任务",
  "schedule": {
    "kind": "every",
    "everyMs": 3600000
  },
  "payload": {
    "kind": "systemEvent",
    "text": "Custom task at $(date)"
  },
  "sessionTarget": "main",
  "enabled": true
}
```

**响应**:

```json
{
  "success": true,
  "data": {
    "job_id": "your-job-id",
    "message": "Cron job created"
  }
}
```

---

#### 3. 更新任务

**请求**:

```http
PUT /api/v1/cron/jobs/{job_id}
Content-Type: application/json

{
  "enabled": false
}
```

**响应**:

```json
{
  "success": true,
  "data": {
    "message": "Cron job updated"
  }
}
```

---

#### 4. 删除任务

**请求**:

```http
DELETE /api/v1/cron/jobs/{job_id}
```

**响应**:

```json
{
  "success": true,
  "data": {
    "message": "Cron job deleted"
  }
}
```

---

#### 5. 触发任务

**请求**:

```http
POST /api/v1/cron/jobs/{job_id}/trigger
```

**响应**:

```json
{
  "success": true,
  "data": {
    "message": "Job triggered",
    "status": "running"
  }
}
```

---

## 错误代码

### HTTP状态码

| 状态码 | 说明 |
|--------|------|
| 200 | 请求成功 |
| 201 | 创建成功 |
| 400 | 请求参数错误 |
| 401 | 未授权 |
| 404 | 资源不存在 |
| 422 | 请求格式错误 |
| 500 | 服务器内部错误 |

### 错误响应

```json
{
  "success": false,
  "error": {
    "code": "INVALID_PARAMETER",
    "message": "Invalid parameter value",
    "details": {
      "field": "GATEWAY_PORT",
      "expected": "numeric",
      "received": "string"
    }
  }
}
```

### 常见错误码

| 错误码 | 说明 |
|--------|------|
| `INVALID_PARAMETER` | 请求参数无效 |
| `NOT_FOUND` | 资源不存在 |
| `AUTH_FAILED` | 认证失败 |
| `INTERNAL_ERROR` | 服务器内部错误 |
| `MODULE_NOT_FOUND` | 模块未找到 |
| `CONFIG_ERROR` | 配置错误 |

---

## 速率限制

- **请求限制**: 100次/分钟
- **IP限制**: 10次/分钟
- **Token限制**: 100次/分钟

---

## 版本控制

### 版本历史

| 版本 | 日期 | 更新内容 |
|------|------|----------|
| v1.0.0 | 2026-02-11 | 初始版本 |

---

## 更新日志

### v1.0.0 (2026-02-11)

**新增**:
- ✅ 集成管理器API
- ✅ 模块API
- ✅ 配置API
- ✅ 定时任务API

**改进**:
- 🚀 完整的错误处理
- 🚀 详细的文档
- 🚀 请求验证

---

**文档版本**: 1.0
**最后更新**: 2026-02-11
**维护者**: LingMou
