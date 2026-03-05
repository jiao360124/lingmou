---
name: search-toolkit
description: "搜索工具包 (Search Toolkit)"
---

# 搜索工具包 (Search Toolkit)

整合了灵眸的AI驱动搜索工具集，包括网络搜索、代码搜索和文档查询。

## 概述

本技能包整合了两个核心搜索工具：

### 1. Exa Web Search (原 smart-search 技能)
基于Exa MCP的免费AI搜索工具，支持网络搜索、代码搜索和公司研究。

**核心功能：**
- 网络搜索（新闻、信息、事实）
- 代码搜索（GitHub、StackOverflow示例）
- 公司研究（商业信息、新闻）
- 多种搜索类型（fast、deep、auto）
- 无需API密钥

**使用场景：**
- 快速查找最新信息
- 搜索代码示例和文档
- 企业研究和分析
- 技术趋势追踪

**快速开始：**
```bash
# 网络搜索
mcporter call 'exa.web_search_exa(query: "latest AI news 2026", numResults: 5)'

# 代码搜索
mcporter call 'exa.get_code_context_exa(query: "React hooks examples", tokensNum: 3000)'

# 公司研究
mcporter call 'exa.company_research_exa(companyName: "Anthropic", numResults: 3)'
```

**搜索类型：**
- `fast` - 快速搜索，适合日常查询
- `deep` - 深度搜索，适合深入研究
- `auto` - 自动选择最佳类型

**代码搜索优化：**
- `tokensNum: 1000-2000` - 聚焦的代码示例
- `tokensNum: 3000-5000` - 中等深度
- `tokensNum: 5000+` - 全面文档

---

### 2. DeepWiki (原 deepwiki 技能)
基于DeepWiki MCP的GitHub仓库文档查询工具，支持AI驱动的仓库文档问答。

**核心功能：**
- 仓库文档问答
- Wiki结构查看
- 文档内容浏览
- AI上下文感知回答
- 支持公开仓库

**使用场景：**
- GitHub仓库文档查询
- 学习新项目架构
- 了解API使用方法
- 查看项目Wiki结构

**快速开始：**
```bash
# 问答
node ./scripts/deepwiki.js ask cognitionlabs/devin "How do I use MCP?"

# 查看结构
node ./scripts/deepwiki.js structure facebook/react

# 浏览内容
node ./scripts/deepwiki.js contents facebook/react docs/getting-started
```

**支持的命令：**
- `ask <owner/repo> <question>` - 问答
- `structure <owner/repo>` - 查看Wiki结构
- `contents <owner/repo> <path>` - 浏览文档内容

---

## 集成架构

### 搜索工具协作
```
Search Toolkit
├── Exa Web Search (网络搜索)
│   ├── 网络搜索 (新闻、信息、事实)
│   ├── 代码搜索 (GitHub、StackOverflow)
│   └── 公司研究 (商业信息)
│       ↓
└── DeepWiki (文档查询)
    ├── 仓库问答
    ├── Wiki结构
    └── 文档浏览
```

### 典型工作流

**场景1: 技术调研**
```
1. 使用 Exa Web Search 搜索最新技术趋势
2. 使用 DeepWiki 查询具体项目文档
3. 结合两者信息，形成全面理解
```

**场景2: 代码开发**
```
1. 使用 Exa Web Search 搜索代码示例
2. 使用 DeepWiki 查看项目API文档
3. 快速上手和开发
```

**场景3: 企业研究**
```
1. 使用 Exa Web Search 搜索公司信息
2. 深度研究特定公司
3. 获取全面分析报告
```

---

## 配置

### Exa Web Search
```bash
# 验证配置
mcporter list exa

# 配置（如果未配置）
mcporter config add exa https://mcp.exa.ai/mcp
```

**启用高级工具（可选）：**
```bash
mcporter config add exa-full "https://mcp.exa.ai/mcp?tools=web_search_exa,web_search_advanced_exa,get_code_context_exa,deep_search_exa,crawling_exa,company_research_exa,people_search_exa,deep_researcher_start,deep_researcher_check"
```

### DeepWiki
无需特殊配置，开箱即用。

**依赖：**
- Node.js
- DeepWiki MCP服务器

---

## 目录结构

```
skills/search-toolkit/
├── SKILL.md                    # 本文档
├── exa-web-search/             # Exa Web Search模块
│   ├── scripts/
│   └── config/
└── deepwiki/                   # DeepWiki模块
    └── scripts/
        └── deepwiki.js
```

---

## 性能指标

| 工具 | 指标 | 目标值 |
|------|------|--------|
| Exa Web Search | 搜索响应 | <1s |
| Exa Web Search | 代码搜索 | <2s |
| DeepWiki | 问答响应 | <3s |
| DeepWiki | 结构查询 | <2s |

---

## 最佳实践

### Exa Web Search
1. **快速搜索** - 使用 `type: "fast"` 进行日常查询
2. **深度研究** - 使用 `type: "deep"` 获取全面信息
3. **代码搜索** - 调整 `tokensNum` 控制范围
4. **公司研究** - 多次查询获取全面信息

### DeepWiki
1. **先看结构** - 使用 `structure` 了解文档组织
2. **针对性问答** - 提出具体问题获取精准答案
3. **浏览文档** - 使用 `contents` 查看完整文档
4. **组合使用** - 结合Exa搜索补充信息

---

## 资源

### Exa Web Search
- GitHub: https://github.com/exa-labs/exa-mcp-server
- npm: https://www.npmjs.com/package/exa-mcp-server
- Docs: https://exa.ai/docs

### DeepWiki
- 官网: https://docs.devin.ai/work-with-devin/deepwiki-mcp
- MCP服务器: https://mcp.deepwiki.com/mcp
- 示例: https://github.com/cognition-labs/deepwiki-mcp

---

## 扩展和定制

### 自定义搜索配置
```bash
# Exa Web Search
mcporter config add exa-custom "https://mcp.exa.ai/mcp?tools=custom_tools"

# DeepWiki
# 配置在 deepwiki/config.json
```

### 集成到工作流
```bash
# 自动化搜索流程
# 1. Exa搜索 → 2. DeepWiki查询 → 3. 结果整合
```

---

## 更新日志

### v1.0.0 (2026-02-26)
- 整合两个搜索工具
- 创建统一使用指南
- 建立工具协作流程
- 优化目录结构

---

## 版本信息

- **整合版本**: v3.2.6
- **整合日期**: 2026-02-26
- **原始技能**: smart-search (exa-web-search-free), deepwiki
