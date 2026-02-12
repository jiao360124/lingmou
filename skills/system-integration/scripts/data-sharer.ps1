# 数据共享器

## 功能
- 知识库统一接口
- 结果缓存系统
- 上下文传递机制
- 跨技能数据传递

## 核心特性

### 1. 知识库统一接口
- 标准化的知识库访问方式
- 多源数据统一管理
- 智能检索和推荐

### 2. 结果缓存系统
- 自动缓存技能结果
- 缓存失效策略
- 内存缓存 + 持久化缓存

### 3. 上下文传递
- 会话级别上下文
- 任务级别上下文
- 临时数据传递

## 使用方法

### 发布数据到知识库
```powershell
.\data-sharer.ps1 -Action publish -Source "copilot" -Data @{
    type = "code-pattern"
    content = "..."
    tags = @("javascript", "async")
    metadata = @{
        language = "javascript"
        qualityScore = 85
    }
}
```

### 从知识库检索
```powershell
.\data-sharer.ps1 -Action retrieve -Query "async function" -Limit 10
```

### 获取缓存数据
```powershell
# 获取特定技能的缓存
.\data-sharer.ps1 -Action get -Skill "copilot" -Key "code-analysis:example123"

# 获取所有缓存
.\data-sharer.ps1 -Action list -Skill "copilot"
```

### 清除缓存
```powershell
# 清除特定技能缓存
.\data-sharer.ps1 -Action clear -Skill "copilot"

# 清除所有缓存
.\data-sharer.ps1 -Action clear -All $true
```

### 传递上下文
```powershell
# 设置会话上下文
.\data-sharer.ps1 -Action context-set -Session "session-123" -Data @{
    projectName = "my-project"
    currentTask = "refactor"
    preferences = @{
        style = "kubernetes"
        pattern = "factory"
    }
}

# 获取会话上下文
.\data-sharer.ps1 -Action context-get -Session "session-123"

# 临时数据传递（请求级别）
.\data-sharer.ps1 -Action transfer -From "copilot" -To "rag" -Data @{
    query = "最佳实践"
    context = "javascript"
}
```

## 数据结构

### 知识库条目
```json
{
    "id": "unique-id",
    "source": "copilot",
    "type": "code-pattern|faq|document|example",
    "content": "Actual content",
    "tags": ["tag1", "tag2"],
    "metadata": {
        "language": "javascript",
        "createdAt": "2026-02-13T00:00:00Z",
        "qualityScore": 85
    }
}
```

### 缓存条目
```json
{
    "skill": "copilot",
    "key": "cache-key",
    "data": "Cached data",
    "createdAt": "2026-02-13T00:00:00Z",
    "expiresAt": "2026-02-14T00:00:00Z",
    "hitCount": 3
}
```

### 上下文对象
```json
{
    "sessionId": "session-123",
    "data": {
        "projectName": "...",
        "currentTask": "...",
        "preferences": {...}
    },
    "createdAt": "2026-02-13T00:00:00Z"
}
```

## 缓存策略

### 自动缓存
系统会自动缓存以下类型的响应：
- Copilot代码分析结果
- RAG知识库检索结果
- Prompt-Engineering模板结果

### 手动缓存
```powershell
.\data-sharer.ps1 -Action cache -Skill "custom" -Key "my-key" -Data @{ ... }
```

### 缓存失效
- TTL（Time To Live）过期
- 手动清除
- 存储空间达到上限
- 手动强制失效

### 缓存大小限制
- 内存缓存上限：100MB
- 持久化缓存上限：1GB
- 超出后自动清理最少使用项

## 数据存储

### 位置
- **知识库**: `data/knowledge-base.json`
- **缓存**: `data/cache/cache.json`
- **会话上下文**: `data/sessions/session-*.json`

### 文件格式
- JSON格式（易于解析和扩展）
- 结构化存储（支持嵌套和复杂对象）
- 压缩存储（节省空间）

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
