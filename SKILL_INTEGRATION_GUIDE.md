# 技能集成完整指南

**版本**: 1.0.0
**创建日期**: 2026-02-23
**维护者**: 灵眸

---

## 📋 目录

1. [概述](#概述)
2. [快速开始](#快速开始)
3. [技能架构](#技能架构)
4. [技能管理](#技能管理)
5. [使用指南](#使用指南)
6. [配置管理](#配置管理)
7. [故障排除](#故障除)
8. [最佳实践](#最佳实践)

---

## 概述

### 什么是技能集成？

技能集成系统是一个统一的技能管理框架，允许AI Agent集成和调用外部技能和工具，扩展系统能力。

### 主要特点

- ✅ **统一接口**: 标准化的技能调用接口
- ✅ **灵活配置**: 每个技能独立配置
- ✅ **安全机制**: 完善的安全检查和权限管理
- ✅ **性能优化**: 智能缓存和并发控制
- ✅ **易于扩展**: 简单添加新技能

---

## 快速开始

### 前提条件

1. **安装技能管理器**
   ```powershell
   # PowerShell
   . .\skill-manager-v2.ps1

   # Bash
   source skill-manager-v2.ps1
   ```

2. **确保技能已启用**
   ```powershell
   # 查看所有技能
   Get-SkillList

   # 检查特定技能
   Get-SkillStatus -SkillName "deepwiki"
   ```

### 第一步：调用技能

```powershell
# 调用DeepWiki
$result = Invoke-Skill -SkillName "deepwiki" -Parameters @{
    query = "mcp server"
    type = "Repository"
}

# 查看结果
if ($result.success) {
    Write-Host "✓ Skill invocation successful"
    $result.data.results | Format-Table url, title
}
```

### 第二步：处理结果

```powershell
# 检查结果
if ($result.success) {
    # 成功处理
    Write-Host "Success: $($result.metadata.duration)"
} else {
    # 错误处理
    Write-Host "Error: $($result.error)"
}
```

---

## 技能架构

### 系统架构

```
┌─────────────────────────────────────────┐
│         技能调用者（应用层）               │
└──────────────┬──────────────────────────┘
               │ Invoke-Skill
┌──────────────▼──────────────────────────┐
│         技能管理器（Core层）               │
│  - 注册管理                                │
│  - 状态管理                                │
│  - 配置管理                                │
└──────┬────────────┬────────────┬─────────┘
       │            │            │
┌──────▼────┐ ┌─────▼─────┐ ┌──▼──────┐
│ 注册表     │ │ 模块管理   │ │ 缓存管理 │
│ Registry  │ │ Modules   │ │ Cache   │
└───────────┘ └───────────┘ └─────────┘
       │            │            │
       ▼            ▼            ▼
┌──────▼────┐ ┌─────▼─────┐ ┌──▼──────┐
│DeepWiki   │ │Exa Search │ │Cache    │
│客户端     │ │客户端     │ │系统     │
└───────────┘ └───────────┘ └─────────┘
```

### 核心组件

#### 1. 技能注册表 (Registry)
存储所有技能的元数据和配置。

**文件**: `skill-registry.json`

**数据结构**:
```json
{
  "skills": {
    "deepwiki": {
      "name": "DeepWiki",
      "description": "GitHub文档查询",
      "version": "1.0.0",
      "config": {
        "enabled": true,
        "cache_enabled": true
      }
    }
  }
}
```

---

#### 2. 技能管理器 (Manager)
统一管理所有技能的加载、调用和配置。

**文件**: `skill-manager-v2.ps1`

**核心函数**:
- `Invoke-Skill` - 调用技能
- `Get-SkillList` - 列出所有技能
- `Enable-Skill` / `Disable-Skill` - 启用/禁用技能
- `Clear-SkillCache` - 清理缓存

---

#### 3. 技能客户端 (Clients)
每个技能的实现模块。

**目录**: `skill-modules/`

**文件结构**:
```
skill-modules/
├── deepwiki.ps1
├── exa-search.ps1
├── technews.ps1
├── git-sync.ps1
└── github-action-gen.ps1
```

---

## 技能管理

### 列出所有技能

```powershell
# 获取所有技能列表
Get-SkillList | Format-Table Name, Description, Version, Status, Priority
```

**输出示例**:
```
Name            Description                    Version  Status    Priority
----            -----------                    -------  ------    --------
DeepWiki        GitHub文档查询                 1.0.0    Enabled   High
Exa Search      AI搜索（代码、新闻等）          1.0.0    Enabled   High
TechNews        科技新闻聚合                   1.0.0    Disabled  Medium
Git Sync        自动化Git同步                  1.0.0    Disabled  Medium
GitHub Action   工作流生成                     1.0.0    Disabled  Low
```

---

### 查看技能状态

```powershell
# 查看特定技能的详细信息
Get-SkillStatus -SkillName "deepwiki"
```

**输出示例**:
```json
{
  "Name": "DeepWiki",
  "Description": "GitHub仓库文档查询",
  "Version": "1.0.0",
  "Author": "Cognition",
  "Status": "Enabled",
  "Priority": "High",
  "RiskLevel": "Low",
  "Features": ["Repository", "Readme", "Q&A", "Code"],
  "Config": {
    "enabled": true,
    "cache_enabled": true,
    "api_key": ""
  }
}
```

---

### 启用/禁用技能

```powershell
# 启用技能
Enable-Skill -SkillName "deepwiki"

# 禁用技能
Disable-Skill -SkillName "deepwiki"

# 验证状态
Get-SkillStatus -SkillName "deepwiki"
```

---

### 清理缓存

```powershell
# 清理所有技能缓存
Clear-SkillCache

# 清理特定技能缓存
Clear-SkillCache -SkillName "deepwiki"

# 清理特定技能的特定缓存
Clear-SkillCache -SkillName "deepwiki" -Key "repo-mcp-10"
```

---

## 使用指南

### DeepWiki使用

#### 1. 仓库查询

```powershell
Invoke-Skill -SkillName "deepwiki" -Parameters @{
    query = "mcp server"
    type = "Repository"
    limit = 10
}
```

#### 2. README提取

```powershell
Invoke-Skill -SkillName "deepwiki" -Parameters @{
    query = "mcp server deepwiki"
    type = "Readme"
}
```

#### 3. 知识问答

```powershell
Invoke-Skill -SkillName "deepwiki" -Parameters @{
    query = "What is DeepWiki?"
    type = "Q&A"
}
```

#### 4. 代码搜索

```powershell
Invoke-Skill -SkillName "deepwiki" -Parameters @{
    query = "PowerShell authentication"
    type = "Code"
}
```

---

### Exa Search使用

#### 1. 代码搜索

```powershell
Invoke-Skill -SkillName "exa-search" -Parameters @{
    query = "PowerShell automation"
    type = "Code"
    limit = 10
}
```

#### 2. 新闻搜索

```powershell
Invoke-Skill -SkillName "exa-search" -Parameters @{
    query = "AI trends 2026"
    type = "News"
    limit = 10
}
```

#### 3. 商业研究

```powershell
Invoke-Skill -SkillName "exa-search" -Parameters @{
    query = "OpenAI business"
    type = "Business"
    limit = 5
}
```

#### 4. 文档搜索

```powershell
Invoke-Skill -SkillName "exa-search" -Parameters @{
    query = "Docker documentation"
    type = "Docs"
    limit = 10
}
```

#### 5. 深度研究

```powershell
Invoke-Skill -SkillName "exa-search" -Parameters @{
    query = "Impact of AI on development"
    type = "DeepResearcher"
    limit = 20
}
```

---

### 错误处理

```powershell
# 调用技能
$result = Invoke-Skill -SkillName "deepwiki" -Parameters @{
    query = "test"
    type = "Repository"
}

# 检查成功状态
if (-not $Result.success) {
    Write-Host "Skill invocation failed: $($Result.error)" -ForegroundColor Red

    # 实现重试机制
    Start-Sleep -Seconds 2
    $Result = Invoke-Skill -SkillName "deepwiki" -Parameters @{
        query = "test"
        type = "Repository"
    }

    if ($Result.success) {
        Write-Host "Retry successful!" -ForegroundColor Green
    } else {
        Write-Host "Retry also failed" -ForegroundColor Yellow
    }
}
```

---

### 批量操作

```powershell
# 批量调用多个技能
$Skills = @(
    @{SkillName = "deepwiki"; Query = "mcp server"; Type = "Repository"},
    @{SkillName = "exa-search"; Query = "AI automation"; Type = "Code"},
    @{SkillName = "exa-search"; Query = "Tech news"; Type = "News"}
)

foreach ($Task in $Skills) {
    $Result = Invoke-Skill -SkillName $Task.SkillName -Parameters @{
        query = $Task.Query
        type = $Task.Type
    }

    if ($Result.success) {
        Write-Host "✓ $($Task.SkillName): Success ($($Result.metadata.duration))" -ForegroundColor Green
    } else {
        Write-Host "✗ $($Task.SkillName): Failed ($($Result.error))" -ForegroundColor Red
    }
}
```

---

## 配置管理

### 查看配置

```powershell
# 获取技能状态（包含配置）
Get-SkillStatus -SkillName "deepwiki"
```

### 修改配置

```powershell
# 技能配置存储在skill-registry.json中
# 可以直接编辑文件，或使用以下方式修改

# 查看注册表
$Registry = Get-Content "skill-registry.json" | ConvertFrom-Json

# 修改配置
$Registry.skills.deepwiki.config.cache_enabled = $true
$Registry.skills.deepwiki.config.max_retries = 5

# 保存注册表
$Registry | ConvertTo-Json -Depth 10 | Out-File "skill-registry.json"
```

### 环境变量

**敏感配置**:
```bash
# 设置Exa API密钥
export EXA_API_KEY="your-api-key-here"

# 设置Git凭证
export GIT_CREDENTIALS="your-credentials"

# 设置GitHub令牌
export GITHUB_TOKEN="your-github-token"
```

**在PowerShell中**:
```powershell
# 设置环境变量
$env:EXA_API_KEY = "your-api-key"
$env:GIT_CREDENTIALS = "your-credentials"
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

### 问题2: API密钥缺失

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

### 问题4: 技能加载失败

**症状**:
```
Error: Skill module not found
```

**解决方法**:
```powershell
# 检查模块文件是否存在
Test-Path "skill-modules/deepwiki.ps1"

# 重新加载模块
. "skill-modules/deepwiki.ps1"
```

---

## 最佳实践

### 1. 错误处理

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
    param([string]$SkillName, [hashtable]$Parameters, [int]$MaxRetries = 3)

    for ($i = 1; $i -le $MaxRetries; $i++) {
        $Result = Invoke-Skill -SkillName $SkillName -Parameters $Parameters

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

### 2. 缓存策略

**利用缓存提升性能**:
```powershell
# 默认使用缓存，快速响应
$result = Invoke-Skill -SkillName "deepwiki" -Parameters @{
    query = "mcp server"
    type = "Repository"
}

# 查看是否来自缓存
if ($Result.metadata.cached) {
    Write-Host "Result from cache" -ForegroundColor Yellow
}
```

**定期刷新重要数据**:
```powershell
# 对于不常变化的数据，定期刷新
$Result = Invoke-Skill -SkillName "deepwiki" -Parameters @{
    query = "mcp server"
    type = "Repository"
    force_refresh = (Get-Date).Date -ne (Get-Date).Date
}
```

---

### 3. 结果处理

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

---

### 4. 性能优化

**使用批量操作**:
```powershell
# 批量查询
$Queries = @("mcp server", "PowerShell", "AI")
$Results = @()

foreach ($Query in $Queries) {
    $Result = Invoke-Skill -SkillName "deepwiki" -Parameters @{
        query = $Query
        type = "Repository"
    }
    $Results += $Result
}
```

**监控性能**:
```powershell
# 调用技能并监控性能
$StartTime = Get-Date
$result = Invoke-Skill -SkillName "deepwiki" -Parameters @{
    query = "mcp server"
    type = "Repository"
}
$Duration = (Get-Date) - $StartTime

Write-Host "Duration: $($Duration.TotalMilliseconds)ms" -ForegroundColor Cyan
```

---

## 相关资源

- [DeepWiki使用指南](./DEEPWIKI_GUIDE.md)
- [Exa Search指南](./EXA_SEARCH_GUIDE.md)
- [Skill Vetter评估报告](./skill-vetter-report.md)
- [技能集成框架](./skill-framework.md)

---

## 更新日志

### v1.0.0 (2026-02-23)
- ✅ 初始版本发布
- ✅ 支持DeepWiki集成
- ✅ 支持Exa Search集成
- ✅ 完整的文档系统
- ✅ 性能优化完成
- ✅ 测试报告生成

---

**文档版本**: 1.0.0
**最后更新**: 2026-02-23
**维护者**: 灵眸
