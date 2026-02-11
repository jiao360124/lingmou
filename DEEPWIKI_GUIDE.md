# DeepWiki使用指南

**版本**: 1.0.0
**创建日期**: 2026-02-19
**维护者**: 灵眸

---

## 📋 目录

1. [概述](#概述)
2. [功能特性](#功能特性)
3. [快速开始](#快速开始)
4. [详细使用](#详细使用)
5. [API参考](#api参考)
6. [最佳实践](#最佳实践)

---

## 概述

### 什么是DeepWiki？
DeepWiki是一个强大的GitHub仓库文档查询和知识问答工具。它可以：

- 🔍 **仓库查询** - 搜索和查找GitHub仓库
- 📖 **文档提取** - 提取README和Wiki文档
- 💬 **知识问答** - 基于文档回答问题
- 🔍 **代码搜索** - 在仓库中搜索代码片段

### 主要特点
- ⚡ 快速响应（<1秒）
- 🎯 精准搜索结果
- 💾 缓存机制提高性能
- 🔒 安全可靠
- 🌐 支持多种查询类型

---

## 功能特性

### 1. 仓库查询

搜索和查找GitHub仓库，获取仓库的基本信息和代码统计。

**支持的参数**:
- `query` (必需): 搜索查询词
- `limit` (可选): 返回结果数量，默认10
- `force_refresh` (可选): 是否强制刷新缓存，默认false

**示例**:
```powershell
Invoke-Skill -SkillName "deepwiki" -Parameters @{
    query = "mcp server deepwiki"
    type = "Repository"
    limit = 10
}
```

**返回格式**:
```json
{
  "success": true,
  "data": {
    "query": "mcp server deepwiki",
    "count": 10,
    "results": [
      {
        "url": "https://github.com/regenrek/deepwiki-mcp",
        "title": "deepwiki-mcp",
        "description": "📖 MCP server for fetch deepwiki.com",
        "language": "TypeScript",
        "stars": 123,
        "created": "2024-01-15T00:00:00Z"
      }
    ]
  }
}
```

---

### 2. 文档提取

提取GitHub仓库的README文档内容。

**支持的参数**:
- `query` (必需): 仓库查询词
- `force_refresh` (可选): 是否强制刷新缓存，默认false

**示例**:
```powershell
Invoke-Skill -SkillName "deepwiki" -Parameters @{
    query = "mcp server deepwiki"
    type = "Readme"
}
```

**返回格式**:
```json
{
  "success": true,
  "data": {
    "url": "https://github.com/regenrek/deepwiki-mcp",
    "title": "deepwiki-mcp",
    "content": "# DeepWiki MCP\n\n📖 MCP server for fetch deepwiki.com...",
    "language": "Markdown"
  }
}
```

---

### 3. 知识问答

基于搜索结果回答问题。

**支持的参数**:
- `question` (必需): 要回答的问题
- `force_refresh` (可选): 是否强制刷新缓存，默认false

**示例**:
```powershell
Invoke-Skill -SkillName "deepwiki" -Parameters @{
    query = "What is the purpose of DeepWiki?"
    type = "Q&A"
}
```

**返回格式**:
```json
{
  "success": true,
  "data": {
    "question": "What is the purpose of DeepWiki?",
    "sources": [
      {
        "title": "DeepWiki MCP - Devin Docs",
        "url": "https://docs.devin.ai/work-with-devin/deepwiki-mcp",
        "snippet": "The DeepWiki MCP server provides programmatic access to DeepWiki’s public repository documentation...",
        "published": "2025-05-24"
      }
    ],
    "answer": "DeepWiki is a tool that provides programmatic access to GitHub repository documentation..."
  }
}
```

---

### 4. 代码搜索

在GitHub仓库中搜索代码片段。

**支持的参数**:
- `query` (必需): 搜索查询词
- `force_refresh` (可选): 是否强制刷新缓存，默认false

**示例**:
```powershell
Invoke-Skill -SkillName "deepwiki" -Parameters @{
    query = "PowerShell authentication"
    type = "Code"
}
```

**返回格式**:
```json
{
  "success": true,
  "data": {
    "query": "PowerShell authentication",
    "count": 10,
    "results": [
      {
        "url": "https://github.com/example/auth-script",
        "title": "PowerShell Auth Script",
        "description": "A PowerShell script for authentication",
        "language": "PowerShell",
        "code_snippet": "function Invoke-Authentication { ... }"
      }
    ]
  }
}
```

---

## 快速开始

### 前提条件

1. **安装技能管理器**:
   ```powershell
   . .\skill-manager-v2.ps1
   ```

2. **确保DeepWiki已启用**:
   ```powershell
   Get-SkillStatus -SkillName "deepwiki"
   ```

### 第一步：搜索仓库

```powershell
# 搜索MCP相关仓库
$result = Invoke-Skill -SkillName "deepwiki" -Parameters @{
    query = "mcp server"
    type = "Repository"
}

# 查看结果
if ($result.success) {
    $result.data.results | Format-Table url, title, description, language, stars
}
```

### 第二步：提取README

```powershell
# 提取第一个仓库的README
$result = Invoke-Skill -SkillName "deepwiki" -Parameters @{
    query = "mcp server"
    type = "Readme"
}

# 显示README内容
if ($result.success) {
    $result.data.content
}
```

### 第三步：问答

```powershell
# 回答关于DeepWiki的问题
$result = Invoke-Skill -SkillName "deepwiki" -Parameters @{
    query = "What is the main feature of DeepWiki?"
    type = "Q&A"
}

# 显示答案
if ($result.success) {
    Write-Host $result.data.answer
    $result.data.sources | Format-Table title, url, snippet
}
```

---

## 详细使用

### 使用缓存

默认情况下，DeepWiki会缓存搜索结果以提升性能。

**查看缓存状态**:
```powershell
# DeepWiki使用标准缓存系统，缓存文件位于:
# skill-cache/deepwiki/

# 查看缓存文件
Get-ChildItem skill-cache/deepwiki/
```

**强制刷新缓存**:
```powershell
Invoke-Skill -SkillName "deepwiki" -Parameters @{
    query = "mcp server"
    type = "Repository"
    force_refresh = $true
}
```

**清除缓存**:
```powershell
# 清除所有DeepWiki缓存
Clear-SkillCache -SkillName "deepwiki"

# 清除所有技能缓存
Clear-SkillCache
```

---

### 处理错误

```powershell
# 调用技能
$result = Invoke-Skill -SkillName "deepwiki" -Parameters @{
    query = "nonexistent repository"
    type = "Readme"
}

# 检查结果
if (-not $result.success) {
    Write-Host "Error: $($result.error)" -ForegroundColor Red

    # 尝试重试
    Start-Sleep -Seconds 2
    $result = Invoke-Skill -SkillName "deepwiki" -Parameters @{
        query = "nonexistent repository"
        type = "Readme"
    }

    if ($result.success) {
        Write-Host "Retry successful!" -ForegroundColor Green
    } else {
        Write-Host "Retry also failed" -ForegroundColor Yellow
    }
}
```

---

### 批量查询

```powershell
# 批量查询多个技能
$Queries = @(
    @{query = "mcp server deepwiki"; type = "Repository"},
    @{query = "PowerShell automation"; type = "Code"},
    @{query = "AI technology trends"; type = "News"}
)

foreach ($Query in $Queries) {
    $Result = Invoke-Skill -SkillName "deepwiki" -Parameters $Query

    if ($Result.success) {
        Write-Host "✓ Query successful: $($Query.query)" -ForegroundColor Green
    } else {
        Write-Host "✗ Query failed: $($Query.query)" -ForegroundColor Red
    }
}
```

---

## API参考

### Invoke-Skill

**函数**: `Invoke-Skill`

**描述**: 调用DeepWiki技能

**参数**:
| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| SkillName | string | 是 | 技能名称，固定为"deepwiki" |
| Parameters | hashtable | 是 | 包含查询参数的哈希表 |

**Parameters结构**:
```json
{
  "query": "搜索查询词",
  "type": "查询类型",
  "limit": 10,
  "force_refresh": false
}
```

**返回格式**:
```json
{
  "success": true/false,
  "data": {...},
  "metadata": {
    "skill": "deepwiki",
    "query": "...",
    "type": "...",
    "duration": "150ms",
    "timestamp": "2026-02-19T00:00:00Z",
    "version": "1.0.0"
  }
}
```

---

### 支持的查询类型

| 类型 | 说明 | 参数要求 |
|------|------|----------|
| Repository | 仓库查询 | `query` (必需) |
| Readme | 提取README | `query` (必需) |
| Q&A | 知识问答 | `query` (必需) |
| Code | 代码搜索 | `query` (必需) |
| Wiki | Wiki文档 | `query` (必需) |

---

## 最佳实践

### 1. 查询优化

**使用具体查询**:
```powershell
# ✅ 好的查询
Invoke-Skill -SkillName "deepwiki" -Parameters @{
    query = "mcp server deepwiki"
    type = "Repository"
}

# ❌ 不好的查询
Invoke-Skill -SkillName "deepwiki" -Parameters @{
    query = "something"
    type = "Repository"
}
```

**使用特定类型**:
```powershell
# 使用特定查询类型获取更准确的结果
Invoke-Skill -SkillName "deepwiki" -Parameters @{
    query = "mcp server"
    type = "Readme"
}
```

---

### 2. 错误处理

**始终检查成功状态**:
```powershell
$result = Invoke-Skill -SkillName "deepwiki" -Parameters @{
    query = "your query"
    type = "Repository"
}

if ($result.success) {
    # 处理成功结果
} else {
    # 处理错误
}
```

**实现重试机制**:
```powershell
function Invoke-SkillWithRetry {
    param([string]$Query, [int]$MaxRetries = 3)

    for ($i = 1; $i -le $MaxRetries; $i++) {
        $Result = Invoke-Skill -SkillName "deepwiki" -Parameters @{
            query = $Query
            type = "Repository"
        }

        if ($Result.success) {
            return $Result
        }

        Write-Host "Attempt $i/$MaxRetries failed. Retrying..."

        if ($i -lt $MaxRetries) {
            Start-Sleep -Seconds 2
        }
    }

    return $Result
}
```

---

### 3. 缓存策略

**利用缓存提升性能**:
```powershell
# 默认使用缓存，快速响应
$result = Invoke-Skill -SkillName "deepwiki" -Parameters @{
    query = "mcp server"
    type = "Repository"
}

# 查看是否来自缓存
if ($result.metadata.cached) {
    Write-Host "Result from cache" -ForegroundColor Yellow
} else {
    Write-Host "Result from live search" -ForegroundColor Green
}
```

**定期刷新重要数据**:
```powershell
# 对于不常变化的数据，定期刷新
$Result = Invoke-Skill -SkillName "deepwiki" -Parameters @{
    query = "mcp server deepwiki"
    type = "Repository"
    force_refresh = (Get-Date).Date -ne (Get-Date).Date # 每日刷新
}
```

---

### 4. 结果处理

**格式化输出**:
```powershell
$result = Invoke-Skill -SkillName "deepwiki" -Parameters @{
    query = "mcp server"
    type = "Repository"
    limit = 5
}

if ($Result.success) {
    # 美化显示
    $Result.data.results | ForEach-Object {
        Write-Host "Title: $($_.title)" -ForegroundColor Cyan
        Write-Host "URL: $($_.url)" -ForegroundColor Yellow
        Write-Host "Stars: $($_.stars)" -ForegroundColor Green
        Write-Host "-------------------"
    }
}
```

**提取特定信息**:
```powershell
$result = Invoke-Skill -SkillName "deepwiki" -Parameters @{
    query = "mcp server"
    type = "Repository"
    limit = 3
}

if ($Result.success) {
    # 提取所有URL
    $Urls = $Result.data.results | Select-Object -ExpandProperty url
    Write-Host "Found $($Urls.Count) repositories"

    # 提取所有标题
    $Titles = $Result.data.results | Select-Object -ExpandProperty title
    $Titles -join ", "
}
```

---

## 故障排除

### 问题1: 技能未启用

**症状**:
```
Error: Skill is disabled: deepwiki
```

**解决方法**:
```powershell
# 启用技能
Enable-Skill -SkillName "deepwiki"

# 验证状态
Get-SkillStatus -SkillName "deepwiki"
```

---

### 问题2: 查询无结果

**症状**:
```
Data: {
  "count": 0,
  "results": []
}
```

**解决方法**:
```powershell
# 尝试更宽泛的查询
Invoke-Skill -SkillName "deepwiki" -Parameters @{
    query = "mcp"  # 缩短查询词
    type = "Repository"
    limit = 20
}

# 尝试不同的查询类型
Invoke-Skill -SkillName "deepwiki" -Parameters @{
    query = "mcp server"
    type = "Code"  # 尝试不同的类型
}
```

---

### 问题3: 缓存问题

**症状**:
```
结果不更新，仍然显示旧数据
```

**解决方法**:
```powershell
# 清除缓存
Clear-SkillCache -SkillName "deepwiki"

# 强制刷新
Invoke-Skill -SkillName "deepwiki" -Parameters @{
    query = "mcp server"
    type = "Repository"
    force_refresh = $true
}
```

---

## 相关资源

- [Skill Vetter评估报告](./skill-vetter-report.md)
- [技能集成框架](./skill-framework.md)
- [技能管理器](./skill-manager-v2.ps1)
- [Exa Search指南](./EXA_SEARCH_GUIDE.md)

---

## 更新日志

### v1.0.0 (2026-02-19)
- ✅ 初始版本发布
- ✅ 支持仓库查询
- ✅ 支持README提取
- ✅ 支持知识问答
- ✅ 支持代码搜索
- ✅ 支持Wiki查询

---

**文档版本**: 1.0.0
**最后更新**: 2026-02-19
**维护者**: 灵眸
