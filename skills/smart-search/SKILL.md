# Smart Search Engine

## 概述
全栈智能搜索系统，支持本地文件、Web搜索、内部记忆、外部知识库（RAG + Moltbook）和API结果的多源整合与智能去重。

## 核心功能

### 1. 多源搜索集成
- **本地文件搜索** - 基于file-search（fd + ripgrep）
- **Web搜索** - 基于exa-web-search-free
- **内部记忆** - MEMORY.md + memory/日期文件
- **外部知识库** - RAG知识库 + Moltbook集成
- **API结果** - RESTful API调用

### 2. 智能去重引擎
- 基于关键词相似度合并重复结果
- 智能内容聚类
- 来源优先级排序
- 权重配置系统

### 3. 搜索优先级系统
- 用户可配置的来源权重
- 动态权重调整
- 场景化预设（快速搜索、深度研究、代码搜索）
- 历史行为学习

### 4. 搜索结果整合
- 智能去重和归类
- 相关性评分
- 结果预览和摘要
- 多格式输出（JSON、Markdown、Table）

## 使用方法

### 基础搜索
```powershell
.\skills\smart-search\main.ps1 -Action search -Query "React hooks"
```

### 指定搜索源
```powershell
.\skills\smart-search\main.ps1 -Action search -Query "性能优化" -Sources "local,memory"
```

### 获取加权搜索结果
```powershell
.\skills\smart-search\main.ps1 -Action search -Query "AI技术" -Weights @{"rag"=0.9; "moltbook"=0.8; "memory"=0.7}
```

### 指定输出格式
```powershell
.\skills\smart-search\main.ps1 -Action search -Query "错误恢复" -Format "markdown" -Sources "web,rag"
```

## 搜索源定义

### Sources.json
```json
{
  "local": {
    "name": "本地文件",
    "enabled": true,
    "search_command": "fd -t f {query}",
    "content_command": "rg -C 3 {query}",
    "weight": 0.6,
    "icon": "📁"
  },
  "web": {
    "name": "Web搜索",
    "enabled": true,
    "search_command": "mcporter call 'exa.web_search_exa(query: {query}, numResults: 5)'",
    "weight": 0.5,
    "icon": "🌐"
  },
  "memory": {
    "name": "内部记忆",
    "enabled": true,
    "paths": ["MEMORY.md", "memory/*.md"],
    "weight": 0.7,
    "icon": "🧠"
  },
  "rag": {
    "name": "RAG知识库",
    "enabled": true,
    "weight": 0.9,
    "icon": "📚"
  },
  "moltbook": {
    "name": "Moltbook社区",
    "enabled": false,
    "weight": 0.8,
    "icon": "👥"
  },
  "api": {
    "name": "API结果",
    "enabled": false,
    "weight": 0.4,
    "icon": "🔌"
  }
}
```

## 权重配置

### Weights.json
```json
{
  "defaults": {
    "fast": {"local": 0.8, "memory": 0.7, "web": 0.5},
    "deep": {"rag": 0.9, "moltbook": 0.8, "web": 0.7, "local": 0.6},
    "code": {"local": 0.9, "rag": 0.8, "web": 0.7}
  },
  "user_custom": {
    "current": {
      "rag": 0.9,
      "moltbook": 0.8,
      "memory": 0.7,
      "local": 0.6,
      "web": 0.5,
      "api": 0.4
    }
  }
}
```

## 智能去重引擎

### Deduplicator.ps1
```powershell
# 基于关键词相似度去重
Deduplicate-Results -Results $allResults -SimilarityThreshold 0.85

# 智能内容聚类
Cluster-Results -Results $uniqueResults -Method "semantic"

# 计算相关性评分
Calculate-Relevance -Results $clusteredResults -Query $searchQuery
```

## 搜索结果整合

### Integrator.ps1
```powershell
# 合并多源结果
Merge-Sources -Results $localResults $webResults $memoryResults $ragResults

# 按来源优先级排序
Sort-ByPriority -Results $mergedResults -Weights $weights

# 生成结果摘要
Generate-Summary -Results $sortedResults -Format $format
```

## 输出格式

### JSON格式
```json
{
  "query": "React hooks",
  "total_results": 15,
  "sources": 4,
  "deduplicated": 10,
  "results": [
    {
      "id": "1",
      "source": "local",
      "title": "React Hooks最佳实践",
      "content": "...",
      "relevance": 0.95,
      "priority": 1
    }
  ]
}
```

### Markdown格式
```markdown
## 搜索结果：React hooks

### 📁 本地文件 (3个结果)
1. **React Hooks最佳实践** [src/hooks/react-hooks.md](...)
   - ...摘要...
   - 相关度: 95%

### 🌐 Web搜索 (5个结果)
1. **React Hooks官方文档** [react.dev](...)
   - ...摘要...
   - 相关度: 92%

### 🧠 内部记忆 (2个结果)
1. **React Hooks使用模式** [MEMORY.md](...)
   - ...摘要...
   - 相关度: 88%

### 📚 RAG知识库 (5个结果)
1. **React Hooks性能优化** [rag/knowledge-base.json](...)
   - ...摘要...
   - 相关度: 96%

---

**总计**: 10个去重结果（来源: 本地文件、Web、记忆、RAG）
```

## 输出表格格式
```markdown
| 来源 | 结果数 | 相关度 | 说明 |
|------|--------|--------|------|
| 📁 本地文件 | 3 | 95% | React Hooks最佳实践 |
| 🌐 Web搜索 | 5 | 92% | 官方文档和教程 |
| 🧠 内部记忆 | 2 | 88% | 使用模式记录 |
| 📚 RAG知识库 | 5 | 96% | 性能优化指南 |

**总计**: 15个原始结果 → 10个去重结果
```

## 技术架构

### 模块化设计
- `main.ps1` - 主程序入口
- `search-integrator.ps1` - 搜索源集成
- `deduplicator.ps1` - 智能去重引擎
- `result-integrator.ps1` - 结果整合
- `output-formatter.ps1` - 输出格式化
- `weight-manager.ps1` - 权重管理系统
- `config.json` - 配置文件

### 数据流
```
用户查询
  ↓
[Search Integrator] 多源搜索
  ↓
[Results Pool] 原始结果（15+个）
  ↓
[Deduplicator] 智能去重（10个）
  ↓
[Integrator] 整合和排序
  ↓
[Output Formatter] 格式化输出
  ↓
用户查看结果
```

## 实施状态

### Phase 4: 功能扩展
- [x] Phase 1: 自主学习系统 ✅
- [x] Phase 2: 持续优化系统 ✅
- [x] Phase 3: Moltbook深度集成 ✅
- [ ] **智能搜索系统** 🚧 进行中
- [ ] Agent协作系统
- [ ] 数据可视化系统
- [ ] API网关

## 依赖
- PowerShell 5.1+
- file-search (fd + ripgrep)
- exa-web-search-free
- RAG知识库
- Moltbook集成

## 作者
灵眸
