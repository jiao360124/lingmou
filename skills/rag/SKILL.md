# RAG Knowledge Base Skill

检索增强生成知识库，支持项目文档、代码示例、FAQ和在线知识源。

## 功能概览

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
- 知识更新同步

## 核心文件

### 知识库数据
- `data/documents/` - 项目文档目录
- `data/code-examples/` - 代码示例目录
- `data/faq/` - FAQ目录
- `data/knowledge-base.json` - 主知识库索引

### 核心脚本
- `scripts/knowledge-retriever.ps1` - 知识检索引擎
- `scripts/knowledge-indexer.ps1` - 知识索引器
- `scripts/faq-manager.ps1` - FAQ管理器
- `scripts/online-source-integrator.ps1` - 在线源集成器

### 配置文件
- `config/knowledge-rules.json` - 知识检索规则
- `config/index-config.json` - 索引配置

## 使用方法

### 基本用法
```powershell
# 加载模块
Import-Module .\scripts\knowledge-retriever.ps1

# 检索知识
$results = Get-Knowledge -Query "API调用"
$results = Get-Knowledge -Query "..." -Category "code"
$results = Get-Knowledge -Query "..." -Limit 5

# 添加文档
Add-Document -Path "docs/api-guide.md" -Category "documentation"
Add-Document -Path "docs/..." -Category "..."

# 索引文档
Update-KnowledgeIndex

# 检索FAQ
$faq = Get-FAQ -Question "如何使用API"
```

### 命令行接口
```bash
# 检索知识
rag search "API调用"
rag search "..." --category code --limit 5

# 添加文档
rag add docs/api-guide.md --category documentation
rag add docs/... --category ...

# 更新索引
rag index

# 检索FAQ
rag faq "如何使用API"
```

## 知识库结构

### 文档分类
```
documentation/
├── api-guide.md
├── architecture.md
├── development.md
└── deployment.md
```

### 代码示例
```
code-examples/
├── javascript/
│   ├── async-api.md
│   └── error-handling.md
├── python/
│   ├── data-processing.md
│   └── database-connection.md
└── ...
```

### FAQ分类
```
faq/
├── getting-started/
├── usage/
├── troubleshooting/
└── advanced/
```

## 检索功能

### 多维度检索
```powershell
# 基于关键词
Get-Knowledge -Query "API调用"

# 基于分类
Get-Knowledge -Query "..." -Category "code"

# 基于标签
Get-Knowledge -Query "..." -Tags ["javascript", "async"]

# 组合检索
Get-Knowledge -Query "..." -Category "code" -Tags ["javascript"] -Limit 5
```

### 智能推荐
```powershell
# 基于上下文推荐
Get-Knowledge -Query "..." -Context "用户正在编写JavaScript代码"

# 基于历史推荐
Get-Knowledge -Query "..." -History @(...)
```

## 代码示例库

### 示例格式
```markdown
# 代码示例: 异步API调用

## 描述
使用fetch API进行异步HTTP请求

## 代码
\`\`\`javascript
async function fetchData(url) {
  try {
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    return await response.json();
  } catch (error) {
    console.error('Fetch error:', error);
    throw error;
  }
}
\`\`\`

## 使用
\`\`\`javascript
fetchData('https://api.example.com/data')
  .then(data => console.log(data))
  .catch(error => console.error(error));
\`\`\`

## 说明
- 异步处理防止阻塞
- 错误处理确保健壮性
- 返回Promise便于链式调用
```

## FAQ系统

### FAQ格式
```markdown
# FAQ: 如何使用API密钥？

## 问题
如何在应用程序中使用API密钥？

## 答案
1. **获取API密钥**
   - 登录到控制台
   - 进入API密钥管理页面
   - 创建新密钥

2. **配置密钥**
   - 在代码中设置环境变量
   - 或在配置文件中存储
   - 确保**不要**将密钥提交到版本控制

3. **使用密钥**
   - 在请求头中包含: \`Authorization: Bearer YOUR_KEY\`
   - 或使用SDK的认证方法

## 常见问题
- **Q: 密钥过期怎么办?**
  A: 密钥长期有效，需手动在控制台删除和重新生成

- **Q: 可以共享密钥吗?**
  A: 不可以，每个API密钥应保持私密
```

## 在线知识源

### 集成的知识源
- GitHub文档
- 官方文档
- Stack Overflow
- 技术博客

### 检索流程
1. 检索本地知识库
2. 如未找到，搜索在线源
3. 聚合多源结果
4. 提供引用来源

## 性能指标

| 指标 | 目标值 | 当前值 |
|------|--------|--------|
| 检索速度 | <500ms | - |
| 索引速度 | <10s | - |
| 文档支持量 | 100+ | - |
| FAQ数量 | 50+ | - |

## 扩展接口

### 自定义知识源
```powershell
Register-KnowledgeSource -Name "custom" -Source {
    param($query)
    # 实现自定义检索逻辑
}
```

### 自定义分类
```powershell
Add-KnowledgeCategory -Name "custom" -Parent "documentation"
```

### 索引优化
```powershell
Update-IndexConfig -EnableCaching $true
Update-IndexConfig -EnableVectorSearch $true
```

## 集成点

### 与其他技能集成
- **Auto-GPT**: 检索相关知识支持任务执行
- **Copilot**: 提供上下文代码示例
- **Prompt-Engineering**: 基于知识库提供模板

### API端点
- `POST /api/knowledge/search` - 检索知识
- `POST /api/knowledge/add` - 添加知识
- `POST /api/knowledge/index` - 更新索引
- `POST /api/faq/search` - 检索FAQ

## 更新日志

### v1.0.0 (2026-02-14)
- 初始版本
- 文档索引系统
- 代码示例库
- FAQ管理器
- 在线源集成器
