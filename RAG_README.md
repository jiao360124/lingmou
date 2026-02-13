# RAG Knowledge Base

检索增强生成知识库，支持项目文档、代码示例、FAQ和在线知识源。

## 🎯 核心功能

### 1. 项目文档索引
- 结构化项目信息存储
- 文档分类和标签系统
- 文档版本管理

### 2. 代码示例库
- 常见代码模式存储
- 代码片段索引
- 用法示例和最佳实践

### 3. FAQ知识库
- 常见问题解答
- 问题分类和搜索
- 用户反馈收集

### 4. 在线知识源
- 实时知识检索
- 多源知识聚合
- GitHub、Stack Overflow集成

---

## 📁 文件结构

```
skills/rag/
├── SKILL.md                          # 技能文档
├── data/
│   ├── knowledge-base.json           # 主知识库索引
│   ├── code-examples/                # 代码示例
│   │   ├── javascript/
│   │   │   └── async-api.md
│   │   └── python/
│   │       └── database-connection.md
│   └── faq/                          # FAQ
│       └── getting-started/
│           └── api-key.md
└── scripts/
    ├── knowledge-retriever.ps1      # 知识检索引擎
    ├── knowledge-indexer.ps1         # 知识索引器
    ├── faq-manager.ps1              # FAQ管理器
    └── online-source-integrator.ps1 # 在线源集成器
```

---

## 🚀 快速开始

### 加载模块
```powershell
Import-Module .\scripts\knowledge-retriever.ps1
```

### 索引文档
```powershell
Index-Document -Path "docs/api-guide.md" -Category "documentation"
Index-Directory -Path "docs" -Category "documentation"

# 索引代码示例
Index-CodeExamples -Languages @("javascript", "python")

# 索引FAQ
Index-FAQs
```

### 检索知识
```powershell
# 基本检索
$results = Get-Knowledge -Query "API调用"
$results = Get-Knowledge -Query "..." -Category "code-examples" -Limit 5

# 带标签检索
$results = Get-Knowledge -Query "..." -Tags @("javascript", "async")

# 检索FAQ
$faq = Get-FAQ -Question "如何使用API密钥"
$faq = Get-FAQ -Question "..." -Limit 3
```

### 在线检索
```powershell
# 搜索GitHub
$githubResults = Search-GitHub -Query "async await" -Language JavaScript

# 搜索Stack Overflow
$soResults = Search-StackOverflow -Question "database connection"

# 多源检索
$onlineResults = Get-OnlineKnowledge -Query "API best practices" `
                                    -Sources @("github", "stackoverflow")
```

---

## 📊 知识库结构

### 文档分类
| 分类 | 描述 | 文件示例 |
|------|------|----------|
| `documentation` | 项目技术文档 | api-guide.md, architecture.md |
| `code-examples` | 代码示例 | async-api.md, database-connection.md |
| `faq` | 常见问题 | api-key.md, setup.md |
| `best-practices` | 最佳实践 | security.md, performance.md |

### 代码示例格式
```markdown
# 代码示例: 功能描述

## 描述
简短的功能描述

## 代码
```language
代码片段
```

## 使用
```language
使用示例
```

## 说明
要点列表
```

### FAQ格式
```markdown
# FAQ: 问题标题

## Question
具体问题

## Answer
详细答案

## Keywords
关键词列表

## Tags
标签列表

## 常见问题
Q: 问题
A: 回答
```

---

## 🔧 高级用法

### 批量索引
```powershell
$documents = @(
    @{path = "docs/api.md"; category = "documentation"; tags = @("api", "rest")}
    @{path = "docs/auth.md"; category = "documentation"; tags = @("auth")}
)

New-BatchIndex -Documents $documents -Category "documentation"

# 索引整个目录
Index-Directory -Path "docs" -Category "documentation" -Tags @("docs")
```

### 智能检索
```powershell
# 基于上下文推荐
$results = Get-Knowledge -Query "数据库连接" -Context "用户正在写Python代码"

# 基于历史推荐
$history = @("api调用", "错误处理")
$results = Get-Knowledge -Query "..." -History $history
```

### 知识库管理
```powershell
# 获取统计
$stats = Get-KnowledgeStats

# 重建索引
Rebuild-Index

# 清理无效引用
Clean-InvalidReferences

# 导出报告
Export-IndexReport -OutputPath "report.md"
```

### 源配置
```powershell
# 查看源状态
Get-SourceStatus -Detailed

# 启用/禁用源
Update-SourceConfig -Name "github" -Enabled $true
Update-SourceConfig -Name "stackoverflow" -Enabled $false

# 检查速率限制
Check-RateLimit
```

---

## 📈 性能指标

| 指标 | 目标值 | 状态 |
|------|--------|------|
| 检索速度 | <500ms | - |
| 索引速度 | <10s | - |
| 文档支持量 | 100+ | 2个示例 |
| FAQ数量 | 50+ | 1个示例 |
| 在线源集成 | 3个源 | GitHub + Stack Overflow |

---

## 🔗 集成点

### 与其他技能集成
- **Auto-GPT**: 检索相关知识支持任务执行
- **Copilot**: 提供上下文代码示例
- **Prompt-Engineering**: 基于知识库提供模板

### API端点
- `POST /api/knowledge/search` - 检索知识
- `POST /api/knowledge/add` - 添加知识
- `POST /api/knowledge/index` - 更新索引
- `POST /api/faq/search` - 检索FAQ
- `POST /api/online/search` - 在线检索

---

## 📝 更新日志

### v1.0.0 (2026-02-14)
- 初始版本发布
- 文档索引系统
- 代码示例库（2个示例）
- FAQ管理器（1个FAQ）
- 在线源集成器（GitHub + Stack Overflow）
- 知识检索引擎
- 知识索引器

---

## 🤝 贡献

欢迎提交代码示例、FAQ和文档！

---

## 📄 许可证

MIT License
