# 系统整合技能

## Overview
系统整合技能提供统一的API接口、集中配置管理和数据共享机制，确保各技能之间的无缝协作和数据传递。

## 核心模块

### 1. 统一API接口
- RESTful API设计
- 请求/响应格式标准化
- API版本管理
- 错误处理机制

### 2. 集中配置管理
- 统一配置中心
- 环境变量管理
- 配置验证和加载
- 配置热更新

### 3. 数据共享机制
- 知识库统一接口
- 结果缓存系统
- 上下文传递机制
- 跨技能数据传递

## 使用示例

### API调用
```powershell
.\api-client.ps1 -Endpoint "copilot/analyze" -Payload @{ code = "..." }
```

### 配置管理
```powershell
.\config-manager.ps1 -Action load -Profile "development"
```

### 数据共享
```powershell
.\data-sharer.ps1 -Action publish -Source "copilot" -Data @{ ... }
```

## 文件结构
```
skills/system-integration/
├── SKILL.md
├── scripts/
│   ├── api-client.ps1          # 统一API客户端
│   ├── config-manager.ps1      # 配置管理器
│   └── data-sharer.ps1          # 数据共享器
└── data/
    ├── api-schema.json          # API规范定义
    └── config-schema.json       # 配置规范定义
```
