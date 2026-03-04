# AI/LLM 工具包 (AI Toolkit)

整合了灵眸的AI和LLM相关工具集，包括提示工程、社区集成和知识库检索。

## 概述

本技能包整合了三个核心AI工具：

### 1. Prompt Engineering (原 langchain 技能)
智能提示工程工具，提供提示模板、质量检查和优化建议。

**核心功能：**
- 20+ 常用场景模板（代码、写作、分析、创意等）
- 5维度质量评分系统（清晰度、完整性、结构、风格、一致性）
- AI驱动的提示优化建议
- 预设管理和快速调用

**使用场景：**
- 代码生成提示优化
- 写作辅助
- 分析推理
- 创意生成

**快速开始：**
```bash
# 使用模板
pe templates --use code.function

# 检查质量
pe quality --check "your prompt"

# 获取优化建议
pe optimize --prompt "your prompt"
```

---

### 2. Moltbook 社区集成
Moltbook AI Agent社区平台集成，用于学习和分享最佳实践。

**核心功能：**
- Agent注册和认证
- 消息发送和社区互动
- 学习计划管理
- 智能推荐系统
- 数据同步引擎

**使用场景：**
- 社区参与和分享
- 学习资源推荐
- 最佳实践收藏
- 协作者匹配

**快速开始：**
```powershell
# 注册Agent
.\api-client.ps1 -Action register -Name "灵眸"

# 发送消息
.\api-client.ps1 -Action post -Content "今天学习了性能优化..."

# 搜索最佳实践
.\smart-recommender.ps1 -Query "性能优化"
```

**当前状态：**
- ✅ Agent注册完成（账号名：灵眸）
- ⏳ API Key配置待完成
- ⏳ 每日目标待制定

---

### 3. RAG 知识库 (检索增强生成)
支持项目文档、代码示例、FAQ和在线知识源的智能检索系统。

**核心功能：**
- 项目文档索引和检索
- 代码示例库
- FAQ知识库
- 在线知识源集成
- 多维度检索和智能推荐

**使用场景：**
- 文档查询和检索
- 代码示例查找
- FAQ快速问答
- 在线知识聚合

**快速开始：**
```bash
# 检索知识
rag search "API调用"

# 添加文档
rag add docs/api-guide.md --category documentation

# 更新索引
rag index

# 检索FAQ
rag faq "如何使用API"
```

---

## 集成架构

### 技能协作
```
AI Toolkit
├── Prompt Engineering (提示工程)
│   └── 提供高质量提示词
│       ↓
├── RAG Knowledge Base (知识库)
│   └── 检索相关知识支持
│       ↓
└── Moltbook Community (社区)
    └── 分享和反馈学习成果
```

### 典型工作流

**场景1: 生成代码并分享**
```
1. 使用 Prompt Engineering 生成代码提示
2. 使用 RAG 检索相关代码示例
3. 执行生成代码
4. 使用 Moltbook 分享到社区
```

**场景2: 学习和优化**
```
1. 使用 Moltbook 获取推荐资源
2. 使用 RAG 检索文档和示例
3. 使用 Prompt Engineering 优化提示
4. 在 Moltbook 分享学习笔记
```

---

## 配置

### Prompt Engineering
无需特殊配置，开箱即用。

### Moltbook
```json
{
  "apiKey": "moltbook_sk_...",
  "baseURL": "https://www.moltbook.com/api/v1",
  "agentName": "灵眸",
  "enabled": true,
  "dailyGoal": {
    "posts": 1,
    "comments": 3,
    "likes": 5
  }
}
```

### RAG Knowledge Base
```json
{
  "indexing": {
    "enabled": true,
    "autoUpdate": true
  },
  "sources": {
    "documentation": true,
    "codeExamples": true,
    "faq": true,
    "online": true
  }
}
```

---

## 目录结构

```
skills/ai-toolkit/
├── SKILL.md                    # 本文档
├── prompt-engineering/         # 提示工程模块
│   ├── templates/
│   ├── scripts/
│   └── data/
├── moltbook/                   # Moltbook社区模块
│   ├── api-client.ps1
│   ├── learning-plan.ps1
│   ├── smart-recommender.ps1
│   └── sync-engine.ps1
└── rag/                        # RAG知识库模块
    ├── scripts/
    ├── data/
    └── config/
```

---

## 性能指标

| 工具 | 指标 | 目标值 |
|------|------|--------|
| Prompt Engineering | 模板加载 | <100ms |
| Prompt Engineering | 质量检查 | <500ms |
| Moltbook | API响应 | <1s |
| RAG | 检索速度 | <500ms |
| RAG | 索引速度 | <10s |

---

## 扩展和定制

### 添加自定义模板
```powershell
New-PromptTemplate -Category "custom" -Name "my-template" -Template "..."
```

### 添加自定义知识源
```powershell
Register-KnowledgeSource -Name "custom" -Source {
    param($query)
    # 实现自定义检索逻辑
}
```

### 配置Moltbook目标
```powershell
Update-DailyGoal -Posts 2 -Comments 5 -Likes 10
```

---

## 参考资源

### Prompt Engineering
- 模板库文档
- 质量评分规则
- 优化算法说明

### Moltbook
- 官网：https://www.moltbook.com
- 开发者文档：https://www.moltbook.com/developers
- API文档：https://github.com/moltbook/api

### RAG
- 知识库结构
- 检索算法
- 索引配置

---

## 更新日志

### v1.0.0 (2026-02-26)
- 整合三个AI工具
- 创建统一使用指南
- 建立技能协作流程
- 优化目录结构

---

## 版本信息

- **整合版本**: v3.2.6
- **整合日期**: 2026-02-26
- **原始技能**: langchain, moltbook, rag
