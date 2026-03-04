# 系统整合技能 - 使用文档

## 概述

系统整合技能提供统一的API接口、集中配置管理和数据共享机制，确保各技能之间的无缝协作和数据传递。

## 核心模块

### 1. 统一API客户端 (api-client.ps1)

**功能**：
- 统一API请求接口
- 标准化请求/响应格式
- 错误处理和重试机制
- 请求超时管理
- 批量调用支持

**主要端点**：

#### Copilot API
- `copilot/analyze` - 代码质量分析
- `copilot/complement` - 代码补全

#### RAG API
- `rag/search` - 知识库检索
- `rag/index` - 文档索引
- `rag/faq` - FAQ查询

#### Auto-GPT API
- `auto-gpt/run` - 执行任务
- `auto-gpt/stop` - 停止任务
- `auto-gpt/status` - 查询状态

**使用示例**：

```powershell
# 基础调用
.\api-client.ps1 -Action call -Endpoint "copilot/analyze" -Payload @{
    code = "function example() { return 1; }"
    language = "javascript"
}

# 批量调用
.\api-client.ps1 -Action batch -Endpoints @(
    @{ endpoint = "copilot/analyze"; payload = @{ code = "..." } },
    @{ endpoint = "rag/search"; payload = @{ query = "..." } }
)
```

### 2. 集中配置管理器 (config-manager.ps1)

**功能**：
- 统一配置加载
- 配置验证
- 环境变量管理
- 配置热更新

**配置优先级**：
1. 环境变量（最高）
2. 配置文件
3. 默认值

**主要操作**：
- `load` - 加载配置
- `get` - 获取配置值
- `set` - 设置配置值
- `validate` - 验证配置
- `save` - 保存配置
- `reload` - 重载配置

**使用示例**：

```powershell
# 加载配置
.\config-manager.ps1 -Action load -Profile "development"

# 获取技能配置
.\config-manager.ps1 -Action get -Key "skills.copilot.enabled"

# 设置配置
.\config-manager.ps1 -Action set -Key "skills.copilot.timeout" -Value 25

# 验证配置
.\config-manager.ps1 -Action validate
```

**配置文件结构**：

```json
{
  "global": { "environment": "development", "timezone": "Asia/Shanghai" },
  "api": { "timeout": 30, "retry": 3 },
  "skills": {
    "copilot": { "enabled": true, "timeout": 20 },
    "auto-gpt": { "enabled": true, "maxTasks": 10 }
  },
  "storage": { "cachePath": "./data/cache", "maxCacheSize": "1GB" },
  "logging": { "level": "info", "format": "json" }
}
```

### 3. 数据共享器 (data-sharer.ps1)

**功能**：
- 知识库统一接口
- 结果缓存系统
- 上下文传递机制
- 跨技能数据传递

**核心特性**：

#### 知识库
- 标准化的知识库访问方式
- 多源数据统一管理
- 智能检索和推荐

#### 缓存系统
- 自动缓存技能结果
- TTL过期机制
- 内存缓存 + 持久化缓存
- LRU清理策略

#### 上下文传递
- 会话级别上下文
- 任务级别上下文
- 临时数据传递

**主要操作**：

```powershell
# 发布数据到知识库
.\data-sharer.ps1 -Action publish -Source "copilot" -Data @{
    type = "code-pattern"
    content = "function example() { ... }"
    tags = @("javascript", "async")
}

# 从知识库检索
.\data-sharer.ps1 -Action retrieve -Query "async function" -Limit 10

# 设置会话上下文
.\data-sharer.ps1 -Action context-set -Session "session-123" -Data @{
    projectName = "my-project"
    currentTask = "refactor"
}

# 传递数据到其他技能
.\data-sharer.ps1 -Action transfer -From "copilot" -To "rag" -Data @{
    query = "最佳实践"
    context = "javascript"
}

# 缓存结果
.\data-sharer.ps1 -Action cache -Skill "copilot" -Key "analysis-result" -Data $result
```

**数据结构**：

```json
// 知识库条目
{
  "id": "unique-id",
  "source": "copilot",
  "type": "code-pattern",
  "content": "...",
  "tags": ["tag1", "tag2"],
  "metadata": {
    "language": "javascript",
    "qualityScore": 85,
    "createdAt": "2026-02-13T00:00:00Z"
  }
}

// 缓存条目
{
  "skill": "copilot",
  "key": "cache-key",
  "data": "...",
  "createdAt": "...",
  "expiresAt": "...",
  "hitCount": 3
}
```

## 数据存储位置

- **知识库**: `data/knowledge-base.json`
- **缓存**: `data/cache/cache.json`
- **会话上下文**: `data/sessions/session-*.json`
- **配置文件**: `config.json`

## 配置管理

### 配置优先级

```
环境变量 > 配置文件 > 默认值
```

### 环境变量

```bash
# Windows PowerShell
$env:ENV = "production"
$env:COPILLOT_ENABLED = "true"

# Linux/Mac
export ENV=production
export COPILLOT_ENABLED=true
```

### 配置验证

系统会自动验证：
- 必需字段是否存在
- 数据类型是否正确
- 值是否在有效范围内
- 路径是否存在

验证失败会返回详细错误信息。

### 配置热更新

支持热更新的配置：
- 日志级别
- 日志格式
- 缓存大小
- 超时设置

```powershell
.\config-manager.ps1 -Action reload -Section "logging"
```

## 性能优化

### 查询优化
- 索引支持（按标签、类型、时间）
- 智能缓存优先
- 批量查询支持

### 传输优化
- 数据压缩
- 流式传输（大数据量）
- 增量更新

## 使用场景

### 场景1：代码分析后补充RAG

```powershell
# Copilot分析代码
$copilotResult = .\api-client.ps1 -Action call -Endpoint "copilot/analyze" ...

# 发布到知识库
.\data-sharer.ps1 -Action publish -Source "copilot" -Data $copilotResult

# RAG检索相关最佳实践
$bestPractices = .\data-sharer.ps1 -Action retrieve -Query $copilotResult[0].tags[0]
```

### 场景2：多技能协作

```powershell
# 设置任务上下文
.\data-sharer.ps1 -Action context-set -Session "task-123" -Data @{
    task = "code review"
    preferences = @{
        style = "consistent"
        pattern = "detailed"
    }
}

# 多技能并行执行
$workflow = @{
    parallel = $true
    steps = @(
        @{ skill = "copilot"; action = "analyze"; context = "task-123" },
        @{ skill = "rag"; action = "retrieve"; context = "task-123" },
        @{ skill = "code-mentor"; action = "improve"; context = "task-123" }
    )
}
```

### 场景3：结果复用

```powershell
# 第一次分析
$result = .\api-client.ps1 -Action call -Endpoint "copilot/analyze" ...

# 自动缓存
.\data-sharer.ps1 -Action cache -Skill "copilot" -Key "analysis-result" -Data $result

# 第二次使用相同代码
$cached = .\data-sharer.ps1 -Action get -Skill "copilot" -Key "analysis-result"
# 如果缓存有效，直接使用 cached 数据，避免重复计算
```

## API规范

详细API规范请参考：
- `data/api-schema.json` - API端点定义和请求/响应格式

## 配置规范

详细配置规范请参考：
- `data/config-schema.json` - 配置项定义和验证规则

## 最佳实践

1. **使用上下文传递**：在多技能协作时使用上下文传递，避免重复传递相同数据
2. **善用缓存**：频繁使用的结果自动缓存，减少重复计算
3. **配置集中管理**：使用config-manager统一管理配置，避免硬编码
4. **批量操作**：使用批量API调用，减少网络往返
5. **合理设置超时**：根据任务类型设置合理的超时时间

## 故障排除

### 问题：配置加载失败
- 检查配置文件格式是否正确
- 确认所有必需字段都已设置
- 查看config-schema.json了解有效配置项

### 问题：API调用失败
- 检查API端点是否正确
- 验证请求参数格式
- 查看api-schema.json了解请求/响应格式
- 检查网络连接和API密钥

### 问题：缓存失效
- 检查TTL设置是否合理
- 查看缓存大小限制
- 手动清除过期缓存

## 更新日志

### v1.0.0 (2026-02-13)
- 初始版本发布
- 统一API客户端
- 集中配置管理
- 数据共享机制

## 支持

如有问题，请检查：
1. 配置文件是否正确
2. API端点定义是否匹配
3. 数据存储权限是否足够
4. 日志输出是否有错误信息
