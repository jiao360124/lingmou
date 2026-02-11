# Exa Search使用指南

**版本**: 1.0.0
**创建日期**: 2026-02-24
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

### 什么是Exa Search？
Exa Search是一个强大的AI搜索工具，提供高质量的搜索结果，支持代码、新闻、商业研究等多种场景。

### 主要特点
- ⚡ 快速响应（<1s）
- 🎯 高质量搜索结果
- 📚 支持多种搜索类型
- 💾 智能缓存机制
- 🔒 安全可靠
- 🌐 支持深度研究模式

---

## 功能特性

### 1. 代码搜索

搜索GitHub中的代码片段和示例。

**特点**:
- 代码质量高
- 语言识别准确
- 代码片段完整
- 最新代码优先

**使用示例**:
```powershell
Invoke-Skill -SkillName "exa-search" -Parameters @{
    query = "PowerShell automation script"
    type = "Code"
    limit = 10
}
```

**返回结果**:
```json
{
  "success": true,
  "data": {
    "query": "PowerShell automation script",
    "count": 10,
    "results": [
      {
        "url": "https://github.com/example/ps-automation",
        "title": "PowerShell Automation Scripts",
        "description": "Collection of PowerShell automation scripts",
        "language": "PowerShell",
        "code_snippet": "function Invoke-Automation { ... }"
      }
    ]
  }
}
```

---

### 2. 新闻搜索

搜索最新的科技新闻和行业动态。

**特点**:
- 新闻质量高
- 发布时间准确
- 来源权威
- 内容丰富

**使用示例**:
```powershell
Invoke-Skill -SkillName "exa-search" -Parameters @{
    query = "AI technology trends 2026",
    type = "News",
    limit = 10
}
```

**返回结果**:
```json
{
  "success": true,
  "data": {
    "query": "AI technology trends 2026",
    "count": 10,
    "results": [
      {
        "url": "https://techcrunch.com/ai-trends",
        "title": "Top AI Trends to Watch in 2026",
        "author": "TechCrunch",
        "publishedDate": "2026-02-20",
        "content": "Major AI companies are...",
        "sitePublished": true
      }
    ]
  }
}
```

---

### 3. 商业研究

分析企业和商业信息。

**特点**:
- 企业数据完整
- 商业分析深入
- 市场洞察丰富
- 报告质量高

**使用示例**:
```powershell
Invoke-Skill -SkillName "exa-search" -Parameters @{
    query = "OpenAI company business",
    type = "Business",
    limit = 5
}
```

**返回结果**:
```json
{
  "success": true,
  "data": {
    "query": "OpenAI company business",
    "count": 5,
    "results": [
      {
        "url": "https://example.com/openai-report",
        "title": "OpenAI Business Analysis 2026",
        "content": "Comprehensive business analysis of OpenAI..."
      }
    ]
  }
}
```

---

### 4. 文档搜索

搜索技术文档和教程。

**特点**:
- 文档质量高
- 链接有效
- 内容准确
- 格式完整

**使用示例**:
```powershell
Invoke-Skill -SkillName "exa-search" -Parameters @{
    query = "Docker tutorial documentation",
    type = "Docs",
    limit = 10
}
```

**返回结果**:
```json
{
  "success": true,
  "data": {
    "query": "Docker tutorial documentation",
    "count": 10,
    "results": [
      {
        "url": "https://docs.docker.com/get-started",
        "title": "Docker Tutorial",
        "content": "Complete guide to Docker...",
        "links": {
          "documentation": "https://docs.docker.com",
          "community": "https://forums.docker.com"
        }
      }
    ]
  }
}
```

---

### 5. 深度研究

执行深度研究，获取综合分析报告。

**特点**:
- 分析深度高
- 引用完整
- 综合性强
- 报告详尽

**使用示例**:
```powershell
Invoke-Skill -SkillName "exa-search" -Parameters @{
    query = "Impact of AI on software development",
    type = "DeepResearcher",
    limit = 20
}
```

**返回结果**:
```json
{
  "success": true,
  "data": {
    "question": "Impact of AI on software development",
    "sources": [
      {
        "url": "https://example.com/source1",
        "title": "AI and Software Engineering",
        "author": "Research Lab",
        "publishedDate": "2026-01-15",
        "score": 0.95
      }
    ],
    "summary": "AI is transforming software development by...",
    "key_points": [
      "Automated code generation",
      "Intelligent debugging",
      "Predictive maintenance",
      "Enhanced collaboration"
    ],
    "references": [
      {
        "url": "https://example.com/source1",
        "title": "AI and Software Engineering",
        "author": "Research Lab",
        "publishedDate": "2026-01-15",
        "score": 0.95
      }
    ]
  }
}
```

---

## 快速开始

### 前提条件

1. **安装技能管理器**
   ```powershell
   . .\skill-manager-v2.ps1
   ```

2. **确保Exa Search已启用**
   ```powershell
   Get-SkillStatus -SkillName "exa-search"
   ```

3. **设置API密钥**
   ```powershell
   $env:EXA_API_KEY = "your-api-key-here"
   ```

### 第一步：设置API密钥

```powershell
# PowerShell
$env:EXA_API_KEY = "your-api-key"

# 验证设置
echo $env:EXA_API_KEY
```

### 第二步：搜索代码

```powershell
# 搜索PowerShell代码
$result = Invoke-Skill -SkillName "exa-search" -Parameters @{
    query = "PowerShell automation"
    type = "Code"
    limit = 10
}

# 查看结果
if ($result.success) {
    $result.data.results | ForEach-Object {
        Write-Host "Title: $($_.title)" -ForegroundColor Cyan
        Write-Host "URL: $($_.url)" -ForegroundColor Yellow
        Write-Host "Language: $($_.language)" -ForegroundColor Green
        Write-Host "-------------------"
    }
}
```

### 第三步：搜索新闻

```powershell
# 搜索AI新闻
$result = Invoke-Skill -SkillName "exa-search" -Parameters @{
    query = "AI trends 2026",
    type = "News"
    limit = 10
}

# 查看新闻标题
if ($result.success) {
    $result.data.results | Select-Object -ExpandProperty title | ForEach-Object {
        Write-Host "📢 $_"
    }
}
```

---

## 详细使用

### 使用缓存

默认情况下，Exa Search会缓存搜索结果以提升性能。

**查看缓存状态**:
```powershell
# Exa Search使用标准缓存系统，缓存文件位于:
# skill-cache/exa-search/

# 查看缓存文件
Get-ChildItem skill-cache/exa-search/
```

**强制刷新缓存**:
```powershell
Invoke-Skill -SkillName "exa-search" -Parameters @{
    query = "AI automation"
    type = "Code"
    force_refresh = $true
}
```

**清除缓存**:
```powerspell
# 清除所有Exa Search缓存
Clear-SkillCache -SkillName "exa-search"

# 清除所有技能缓存
Clear-SkillCache
```

---

### 处理错误

```powershell
# 调用技能
$result = Invoke-Skill -SkillName "exa-search" -Parameters @{
    query = "invalid query"
    type = "Code"
}

# 检查结果
if (-not $result.success) {
    Write-Host "Error: $($result.error)" -ForegroundColor Red

    # 检查API密钥
    if ($result.error -like "*EXA_API_KEY*") {
        Write-Host "API Key not set!" -ForegroundColor Yellow
        Write-Host "Please set EXA_API_KEY environment variable" -ForegroundColor Yellow
    }

    # 尝试重试
    Start-Sleep -Seconds 2
    $result = Invoke-Skill -SkillName "exa-search" -Parameters @{
        query = "AI automation"
        type = "Code"
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
# 批量查询多个主题
$Topics = @(
    @{Query = "PowerShell automation"; Type = "Code"},
    @{Query = "Docker containers"; Type = "Code"},
    @{Query = "AI technology news"; Type = "News"},
    @{Query = "OpenAI business"; Type = "Business"}
)

foreach ($Topic in $Topics) {
    $Result = Invoke-Skill -SkillName "exa-search" -Parameters @{
        query = $Topic.Query
        type = $Topic.Type
    }

    if ($Result.success) {
        Write-Host "✓ $(echo $Topic.Query): $(echo $Result.metadata.duration)" -ForegroundColor Green
    } else {
        Write-Host "✗ $(echo $Topic.Query): $(echo $Result.error)" -ForegroundColor Red
    }
}
```

---

## API参考

### Invoke-Skill

**函数**: `Invoke-ExaSearch`

**描述**: 调用Exa Search技能

**参数**:
| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| SkillName | string | 是 | 技能名称，固定为"exa-search" |
| Parameters | hashtable | 是 | 包含查询参数的哈希表 |

**Parameters结构**:
```json
{
  "query": "搜索查询词",
  "type": "搜索类型",
  "limit": "结果数量",
  "force_refresh": "是否强制刷新缓存"
}
```

**返回格式**:
```json
{
  "success": true/false,
  "data": {...},
  "metadata": {
    "skill": "exa-search",
    "query": "...",
    "type": "...",
    "duration": "150ms",
    "timestamp": "2026-02-24T00:00:00Z",
    "version": "1.0.0"
  }
}
```

---

### 支持的搜索类型

| 类型 | 说明 | 参数要求 |
|------|------|----------|
| Code | 代码搜索 | `query` (必需) |
| News | 新闻搜索 | `query` (必需) |
| Business | 商业研究 | `query` (必需) |
| Docs | 文档搜索 | `query` (必需) |
| DeepResearcher | 深度研究 | `query` (必需) |

---

## 最佳实践

### 1. 查询优化

**使用具体查询**:
```powershell
# ✅ 好的查询
Invoke-Skill -SkillName "exa-search" -Parameters @{
    query = "PowerShell authentication"
    type = "Code"
}

# ❌ 不好的查询
Invoke-Skill -SkillName "exa-search" -Parameters @{
    query = "something"
    type = "Code"
}
```

**使用特定类型**:
```powershell
# 根据需求选择合适的搜索类型
Invoke-Skill -SkillName "exa-search" -Parameters @{
    query = "mcp server"
    type = "Code"
}
```

---

### 2. 错误处理

**始终检查成功状态**:
```powershell
$result = Invoke-Skill -SkillName "exa-search" -Parameters @{
    query = "your query"
    type = "Code"
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
    param([string]$Query, [string]$Type, [int]$MaxRetries = 3)

    for ($i = 1; $i -le $MaxRetries; $i++) {
        $Result = Invoke-Skill -SkillName "exa-search" -Parameters @{
            query = $Query
            type = $Type
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
$result = Invoke-Skill -SkillName "exa-search" -Parameters @{
    query = "AI automation"
    type = "Code"
}

# 查看是否来自缓存
if ($Result.metadata.cached) {
    Write-Host "Result from cache" -ForegroundColor Yellow
} else {
    Write-Host "Result from live search" -ForegroundColor Green
}
```

**根据数据类型调整缓存时长**:
```powershell
# 对于不常变化的数据，延长缓存时长
$Result = Invoke-Skill -SkillName "exa-search" -Parameters @{
    query = "OpenAI business"
    type = "Business"
    force_refresh = (Get-Date).Date -ne (Get-Date).Date # 每日刷新
}
```

---

### 4. 结果处理

**格式化输出**:
```powershell
$result = Invoke-Skill -SkillName "exa-search" -Parameters @{
    query = "AI automation"
    type = "News"
    limit = 5
}

if ($Result.success) {
    # 美化显示
    $Result.data.results | ForEach-Object {
        Write-Host "Title: $($_.title)" -ForegroundColor Cyan
        Write-Host "Published: $($_.publishedDate)" -ForegroundColor Yellow
        Write-Host "Author: $($_.author)" -ForegroundColor Green
        Write-Host "-------------------"
    }
}
```

**提取特定信息**:
```powershell
$result = Invoke-Skill -SkillName "exa-search" -Parameters @{
    query = "AI automation"
    type = "Code"
    limit = 3
}

if ($Result.success) {
    # 提取所有URL
    $Urls = $Result.data.results | Select-Object -ExpandProperty url
    Write-Host "Found $($Urls.Count) code examples"

    # 提取所有标题
    $Titles = $Result.data.results | Select-Object -ExpandProperty title
    $Titles -join ", "
}
```

---

### 5. 深度研究

**使用深度研究进行综合分析**:
```powershell
# 对复杂问题使用深度研究
$result = Invoke-Skill -SkillName "exa-search" -Parameters @{
    query = "Impact of AI on software development"
    type = "DeepResearcher"
    limit = 20
}

if ($Result.success) {
    # 显示摘要
    Write-Host "Summary:" -ForegroundColor Cyan
    Write-Host $Result.data.summary -ForegroundColor Yellow

    # 显示关键点
    Write-Host "`nKey Points:" -ForegroundColor Cyan
    $Result.data.key_points | ForEach-Object { Write-Host "• $_" -ForegroundColor Green }

    # 显示引用
    Write-Host "`nSources:" -ForegroundColor Cyan
    $Result.data.sources | ForEach-Object {
        Write-Host "• $($_.title) ($($_.score))" -ForegroundColor Yellow
    }
}
```

---

## 故障排除

### 问题1: API密钥缺失

**症状**:
```
Error: EXA_API_KEY environment variable not set
```

**解决方法**:
```powershell
# 设置环境变量
$env:EXA_API_KEY = "your-api-key"

# 验证设置
echo $env:EXA_API_KEY
```

---

### 问题2: 搜索无结果

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
Invoke-Skill -SkillName "exa-search" -Parameters @{
    query = "mcp"  # 缩短查询词
    type = "Code"
    limit = 20
}

# 尝试不同的搜索类型
Invoke-Skill -SkillName "exa-search" -Parameters @{
    query = "mcp server"
    type = "DeepResearcher"  # 尝试不同的类型
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
Clear-SkillCache -SkillName "exa-search"

# 强制刷新
Invoke-Skill -SkillName "exa-search" -Parameters @{
    query = "AI automation"
    type = "Code"
    force_refresh = $true
}
```

---

## 相关资源

- [DeepWiki使用指南](./DEEPWIKI_GUIDE.md)
- [Skill Vetter评估报告](./skill-vetter-report.md)
- [技能集成框架](./skill-framework.md)
- [技能集成指南](./SKILL_INTEGRATION_GUIDE.md)

---

## 更新日志

### v1.0.0 (2026-02-24)
- ✅ 初始版本发布
- ✅ 支持代码搜索
- ✅ 支持新闻搜索
- ✅ 支持商业研究
- ✅ 支持文档搜索
- ✅ 支持深度研究

---

**文档版本**: 1.0.0
**最后更新**: 2026-02-24
**维护者**: 灵眸
