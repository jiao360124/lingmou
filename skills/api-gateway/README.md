# API Gateway System - API网关系统

## 📊 概述
统一API网关系统，提供RESTful API设计、请求验证、速率限制和API客户端功能。

---

## ✨ 核心功能

### 1. RESTful API设计
- 统一的请求/响应格式
- API规范定义
- 错误处理和重试机制
- 批量调用支持

### 2. API客户端
- RESTful API调用
- 自动认证
- 错误处理
- 缓存支持

### 3. 请求验证
- 请求参数验证
- 数据类型检查
- 业务规则验证
- 安全检查

### 4. 速率限制
- 请求频率限制
- 并发限制
- IP限制
- 配置化限制

---

## 🚀 快速开始

### 创建API规范
```powershell
$schema = @{
    api_version = "1.0.0"
    endpoints = @(
        @{
            path = "/search"
            method = "POST"
            request = @{
                query = @{
                    type = "string"
                    required = $true
                }
            }
        }
    )
}

.\skills\api-gateway\main.ps1 -Action spec -Schema $schema -Output "api-schema.json"
```

### 调用API
```powershell
$data = @{
    query = "React hooks"
    sources = @("local", "web", "memory")
}

.\skills\api-gateway\main.ps1 -Action call -Endpoint "/search" -Method "POST" -Body $data
```

### 验证请求
```powershell
$request = @{
    query = "test"
    sources = @("local", "web")
}

.\skills\api-gateway\main.ps1 -Action validate -Request $request -Schema $schema
```

### 检查速率限制
```powershell
.\skills\api-gateway\main.ps1 -Action limit -Check -Limit 100
```

---

## 📁 文件结构

```
skills/api-gateway/
├── SKILL.md              # 技能文档
├── README.md             # 本文档
├── api-schema.json       # API规范定义
└── scripts/
    ├── main.ps1          # 主程序入口
    ├── api-client.ps1    # API客户端
    ├── api-validator.ps1 # 请求验证
    └── rate-limiter.ps1  # 速率限制
```

---

## 📋 API规范示例

### 完整API规范
```json
{
  "api_version": "1.0.0",
  "name": "Smart Search API",
  "endpoints": [
    {
      "path": "/search",
      "method": "POST",
      "description": "多源智能搜索",
      "request": {
        "query": {
          "type": "string",
          "required": true,
          "min_length": 2
        },
        "sources": {
          "type": "array",
          "items": {
            "type": "string",
            "enum": ["local", "web", "memory", "rag"]
          },
          "default": ["local", "web", "memory"]
        },
        "weights": {
          "type": "object",
          "default": {
            "rag": 0.9,
            "memory": 0.7,
            "local": 0.6,
            "web": 0.5
          }
        }
      },
      "response": {
        "format": "json",
        "schema": "results"
      }
    },
    {
      "path": "/dashboard",
      "method": "GET",
      "description": "获取仪表盘数据",
      "response": {
        "format": "json",
        "schema": "dashboard"
      }
    }
  ]
}
```

---

## 🔧 API客户端使用

### 基础调用
```powershell
$body = @{
    query = "React hooks"
    sources = @("local", "web")
}

.\scripts\api-client.ps1 -Endpoint "/search" -Method "POST" -Body $body
```

### 带认证的调用
```powershell
$headers = @{
    "Authorization" = "Bearer $token"
}

.\scripts\api-client.ps1 -Endpoint "/search" -Method "POST" -Body $body -Headers $headers
```

### 批量调用
```powershell
$queries = @("React hooks", "性能优化", "AI技术")

foreach ($q in $queries) {
    $body = @{ query = $q }
    \.scripts\api-client.ps1 -Endpoint "/search" -Method "POST" -Body $body
}
```

---

## ✅ 请求验证

### 验证流程
1. 检查请求格式
2. 验证必填参数
3. 验证数据类型
4. 检查业务规则
5. 返回验证结果

### 示例
```powershell
$request = @{
    query = ""  # 空字符串
    sources = @("invalid")
}

$result = & .\scripts\api-validator.ps1 -Request $request -Schema $schema

if ($result.valid) {
    Write-Host "验证通过"
} else {
    Write-Host "验证失败: $($result.errors -join ', ')"
}
```

---

## ⚡ 速率限制

### 配置限制
```powershell
$limits = @{
    requests_per_minute = 100
    requests_per_hour = 1000
    concurrent_requests = 10
}
```

### 检查限制
```powershell
$limitCheck = & .\scripts\rate-limiter.ps1 -Check -Limit $limits

if ($limitCheck.allowed) {
    # 执行API调用
} else {
    Write-Warning "超出速率限制: $($limitCheck.message)"
}
```

---

## 📊 输出格式

### JSON格式
```json
{
  "success": true,
  "data": {
    "results": [...]
  },
  "meta": {
    "query": "React hooks",
    "sources": ["local", "web", "memory"],
    "execution_time": 1.23
  }
}
```

### 错误格式
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Query is required",
    "details": [...]
  }
}
```

---

## 🔒 安全特性

- **请求验证** - 防止无效请求
- **速率限制** - 防止滥用
- **认证支持** - API密钥、Bearer Token
- **错误处理** - 标准化错误响应

---

## 📝 更新日志

### 2026-02-14
- ✅ 创建基础架构
- ✅ 实现API规范定义
- ✅ 实现API客户端
- ✅ 实现请求验证
- ✅ 实现速率限制
- ✅ 完成文档

---

## 👤 作者
**灵眸** - 自我进化引擎的一部分

---

## 📄 许可证
MIT License
