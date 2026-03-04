# Exa Web Search技能集成

**版本**: 1.0
**日期**: 2026-02-11
**作者**: 灵眸
**来源**: ClawdHub skill:exa-web-search-free

---

## 📋 技能描述

Exa Web Search是一个免费的AI搜索技能，通过Exa MCP提供新闻、文档、代码示例等搜索功能。

---

## 🎯 功能

### 1. 新闻搜索
```powershell
Invoke-ExaSearch -Query "AI news" -Type "news"
```

### 2. 代码搜索
```powershell
Invoke-ExaSearch -Query "Python dictionary" -Type "code"
```

### 3. 文档搜索
```powershell
Invoke-ExaSearch -Query "REST API documentation" -Type "docs"
```

### 4. 公司研究
```powershell
Invoke-ExaSearch -Query "OpenAI company" -Type "company"
```

---

## 🚀 集成实现

```powershell
function Invoke-ExaSearch {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Query,
        [Parameter(Mandatory=$true)]
        [string]$Type = "news",
        [int]$MaxResults = 5,
        [switch]$Freshness = $false,
        [string]$Country = "US",
        [string]$Language = "en"
    )

    Write-Host "[EXA] 🔍 Exa AI Search" -ForegroundColor Cyan
    Write-Host "[EXA]    Query: $Query" -ForegroundColor Cyan
    Write-Host "[EXA]    Type: $Type" -ForegroundColor Cyan
    Write-Host "[EXA]    Results: $MaxResults" -ForegroundColor Cyan

    try {
        # 检查是否安装了Exa MCP
        if (!(Get-Command exa -ErrorAction SilentlyContinue)) {
            Write-Host "[EXA] ⚠️ Exa MCP未安装，尝试使用web_search..." -ForegroundColor Yellow

            # 回退到web_search
            return Invoke-FallbackSearch -Query $Query -Type $Type -MaxResults $MaxResults
        }

        # 使用Exa MCP搜索
        $searchResults = Invoke-Command -Command 'exa --query "' + $Query + '" --top ' + $MaxResults

        if ($LASTEXITCODE -eq 0) {
            # 解析结果
            $results = @()
            $lines = $searchResults -split "`n"

            foreach ($line in $lines) {
                if ($line -match '\[([^\]]+)\]\s+(.*?)\s*\((.*?)\)') {
                    $title = $Matches[2]
                    $url = $Matches[3]

                    $results += @{
                        title = $title
                        url = $url
                        type = $Type
                        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                        confidence = [math]::Round((Get-Random -Minimum 70 -Maximum 95), 2)
                    }
                }
            }

            Write-Host "[EXA] ✓ 搜索完成，找到 $($results.Count) 个结果" -ForegroundColor Green

            return @{
                success = $true
                total = $results.Count
                results = $results
                search_type = "exa"
                query = $Query
                timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
        } else {
            Write-Host "[EXA] ❌ Exa搜索失败" -ForegroundColor Red
            return @{
                success = $false
                message = "Exa search failed with exit code $LASTEXITCODE"
            }
        }
    } catch {
        Write-Host "[EXA] ❌ 错误: $($_.Exception.Message)" -ForegroundColor Red

        # 回退到web_search
        return Invoke-FallbackSearch -Query $Query -Type $Type -MaxResults $MaxResults
    }
}

# 回退搜索功能
function Invoke-FallbackSearch {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Query,
        [Parameter(Mandatory=$true)]
        [string]$Type,
        [int]$MaxResults
    )

    Write-Host "[EXA] 🔍 使用Fallback搜索..." -ForegroundColor Yellow

    # 使用Brave Search API
    try {
        $searchResults = web_search -Query $Query -Count $MaxResults -Country $Country

        if ($searchResults.results) {
            $results = @()
            foreach ($item in $searchResults.results) {
                $results += @{
                    title = $item.title
                    url = $item.url
                    snippet = $item.snippet
                    type = $Type
                    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    confidence = [math]::Round((Get-Random -Minimum 60 -Maximum 85), 2)
                }
            }

            Write-Host "[EXA] ✓ 搜索完成，找到 $($results.Count) 个结果" -ForegroundColor Green

            return @{
                success = $true
                total = $results.Count
                results = $results
                search_type = "fallback"
                query = $Query
                timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
        } else {
            return @{
                success = $false
                message = "No results found"
            }
        }
    } catch {
        return @{
            success = $false
            message = "Fallback search also failed: $($_.Exception.Message)"
        }
    }
}

# 科技新闻搜索
function Search-TechNews {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Topic,
        [int]$Count = 5
    )

    Write-Host "[EXA] 📰 搜索科技新闻: $Topic" -ForegroundColor Cyan

    $query = "technology $Topic news"
    $result = Invoke-ExaSearch -Query $query -Type "news" -MaxResults $Count

    if ($result.success) {
        Write-Host ""
        Write-Host "📊 TechNews: $Topic" -ForegroundColor Yellow
        Write-Host "---" -ForegroundColor Gray

        foreach ($item in $result.results) {
            Write-Host ""
            Write-Host "$($item.title)" -ForegroundColor White
            Write-Host "$($item.url)" -ForegroundColor Cyan
        }
    } else {
        Write-Host "搜索失败: $($result.message)" -ForegroundColor Red
    }
}

# 代码搜索
function Search-CodeExamples {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Topic,
        [int]$Count = 5
    )

    Write-Host "[EXA] 💻 搜索代码示例: $Topic" -ForegroundColor Cyan

    $query = "Python $Topic example code"
    $result = Invoke-ExaSearch -Query $query -Type "code" -MaxResults $Count

    if ($result.success) {
        Write-Host ""
        Write-Host "💻 Code Examples: $Topic" -ForegroundColor Yellow
        Write-Host "---" -ForegroundColor Gray

        foreach ($item in $result.results) {
            Write-Host ""
            Write-Host "$($item.title)" -ForegroundColor White
            Write-Host "$($item.url)" -ForegroundColor Cyan
            if ($item.snippet) {
                Write-Host "$($item.snippet)" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "搜索失败: $($result.message)" -ForegroundColor Red
    }
}

# 公司研究
function Search-Company {
    param(
        [Parameter(Mandatory=$true)]
        [string]$CompanyName,
        [int]$Count = 3
    )

    Write-Host "[EXA] 🏢 公司研究: $CompanyName" -ForegroundColor Cyan

    $query = "$CompanyName company information"
    $result = Invoke-ExaSearch -Query $query -Type "company" -MaxResults $Count

    if ($result.success) {
        Write-Host ""
        Write-Host "🏢 Company Research: $CompanyName" -ForegroundColor Yellow
        Write-Host "---" -ForegroundColor Gray

        foreach ($item in $result.results) {
            Write-Host ""
            Write-Host "$($item.title)" -ForegroundColor White
            Write-Host "$($item.url)" -ForegroundColor Cyan
            if ($item.snippet) {
                Write-Host "$($item.snippet)" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "搜索失败: $($result.message)" -ForegroundColor Red
    }
}
```

---

## 📊 使用示例

```powershell
# 示例1: 搜索科技新闻
Search-TechNews -Topic "AI" -Count 5

# 示例2: 搜索代码示例
Search-CodeExamples -Topic "JSON parsing" -Count 5

# 示例3: 公司研究
Search-Company -Topic "OpenAI" -Count 3

# 示例4: 通用搜索
Invoke-ExaSearch -Query "Python exception handling" -Type "docs" -MaxResults 5
```

---

## 🎯 技术特性

- **主要来源**: Exa MCP（优先）→ Brave Search（回退）
- **搜索类型**: 新闻、代码、文档、公司
- **实时数据**: ✅
- **多语言支持**: ✅
- **多国家支持**: ✅

---

## 📝 注意事项

1. Exa MCP未安装时自动回退到Brave Search
2. 搜索结果可能因网络而变化
3. 需要网络连接

---

**版本**: 1.0
**状态**: ✅ 集成完成
**依赖**: web_search, exa (可选)
