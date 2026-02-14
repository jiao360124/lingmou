# API Gateway System

## 概述
统一API网关系统，提供RESTful API设计、请求验证、速率限制和API客户端功能。

## 核心功能

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

## 使用方法

### 创建API规范
```powershell
.\skills\api-gateway\main.ps1 -Action spec -Name "api-schema.json" -Endpoints @(...)
```

### 调用API
```powershell
.\skills\api-gateway\main.ps1 -Action call -Endpoint "/search" -Method "POST" -Body $data
```

### 验证请求
```powershell
.\skills\api-gateway\main.ps1 -Action validate -Request $request -Schema $schema
```

### 速率限制
```powershell
.\skills\api-gateway\main.ps1 -Action limit -Check -Limit 100
```

## API规范示例

### api-schema.json
```json
{
  "api_version": "1.0.0",
  "endpoints": [
    {
      "path": "/search",
      "method": "POST",
      "request": {
        "query": {
          "type": "string",
          "required": true
        },
        "sources": {
          "type": "array",
          "default": ["local", "web"]
        }
      },
      "response": {
        "format": "json",
        "schema": "results"
      }
    }
  ]
}
```

## 技术架构

### 模块设计
- `main.ps1` - 主程序入口
- `api-client.ps1` - API客户端
- `api-validator.ps1` - 请求验证
- `rate-limiter.ps1` - 速率限制
- `api-schema.json` - API规范定义

## 依赖
- PowerShell 5.1+
- OpenClaw环境

## 作者
灵眸
