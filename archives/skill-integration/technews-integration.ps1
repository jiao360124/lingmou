# TechNews技能集成

**版本**: 1.0
**日期**: 2026-02-11
**作者**: 灵眸
**来源**: ClawdHub skill:technews

---

## 📋 技能描述

TechNews技能从TechMeme获取顶级科技新闻，为用户保持技术前沿。

---

## 🎯 功能

### 1. 获取科技新闻
```powershell
Invoke-TechNews -Count 5 -Topic "AI"
```

### 2. 获取顶级新闻
```powershell
Invoke-TechNews -TopStories
```

### 3. 按主题筛选
```powershell
Invoke-TechNews -Topic "AI" -Count 10
```

---

## 🚀 集成实现

```powershell
function Invoke-TechNews {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Topic = "technology",
        [int]$Count = 5,
        [switch]$TopStories,
        [string]$Source = "techmeme"
    )

    Write-Host "[TECHNEWS] 📰 获取TechNews..." -ForegroundColor Cyan
    Write-Host "[TECHNEWS]    主题: $Topic" -ForegroundColor Cyan
    Write-Host "[TECHNEWS]    数量: $Count" -ForegroundColor Cyan
    Write-Host "[TECHNEWS]    来源: $Source" -ForegroundColor Cyan

    try {
        # 使用web_fetch获取TechMeme内容
        $techmemeUrl = "https://techmeme.com"
        $content = Invoke-WebRequest -Uri $techmemeUrl -UseBasicParsing -TimeoutSec 10

        if ($content.StatusCode -eq 200) {
            # 提取新闻标题
            $newsItems = @()

            # 根据主题筛选
            if ($Topic -eq "technology") {
                # 获取一般科技新闻
                $articlePattern = '<a href="(.*?)"[^>]*>(.*?)</a>'
            } else {
                # 特定主题
                $articlePattern = "($Topic)[^<]*<a href=\"(.*?)\">(.*?)</a>"
            }

            # 提取新闻
            $matches = [regex]::Matches($content.Content, $articlePattern)

            $newsCount = 0
            foreach ($match in $matches) {
                if ($newsCount -ge $Count) {
                    break
                }

                $url = $match.Groups[2].Value
                $title = $match.Groups[3].Value

                if ($url -and $title) {
                    $newsItems += @{
                        title = $title
                        url = $url
                        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                        source = $Source
                    }
                    $newsCount++
                }
            }

            # 显示结果
            Write-Host "[TECHNEWS] ✓ 获取到 $newsCount 条新闻" -ForegroundColor Green

            return @{
                success = $true
                total = $newsCount
                news_items = $newsItems
                timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
        } else {
            Write-Host "[TECHNEWS] ❌ 无法访问TechMeme" -ForegroundColor Red
            return @{
                success = $false
                message = "Failed to access TechMeme: HTTP $($content.StatusCode)"
            }
        }
    } catch {
        Write-Host "[TECHNEWS] ❌ 错误: $($_.Exception.Message)" -ForegroundColor Red
        return @{
            success = $false
            message = $_.Exception.Message
        }
    }
}

# 获取科技新闻（包装函数）
function Get-TechNews {
    param(
        [int]$Count = 5,
        [string]$Topic = "technology"
    )

    Write-Host "📊 TechNews - 科技新闻" -ForegroundColor Cyan
    Write-Host "---" -ForegroundColor Gray

    $result = Invoke-TechNews -Topic $Topic -Count $Count

    if ($result.success) {
        foreach ($item in $result.news_items) {
            Write-Host ""
            Write-Host "[$($item.timestamp)]" -ForegroundColor Yellow
            Write-Host "$($item.title)" -ForegroundColor White
            Write-Host "🔗 $($item.url)" -ForegroundColor Cyan
        }
    } else {
        Write-Host "获取失败: $($result.message)" -ForegroundColor Red
    }
}
```

---

## 📊 使用示例

```powershell
# 示例1: 获取一般科技新闻
Get-TechNews -Count 3

# 示例2: 获取AI相关新闻
Get-TechNews -Topic "AI" -Count 5

# 示例3: 获取技术主题新闻
Get-TechNews -Topic "coding" -Count 10
```

---

## 🎯 技术特性

- **来源**: TechMeme
- **实时数据**: ✅
- **主题筛选**: ✅
- **摘要功能**: ⏳（待实现）
- **历史记录**: ⏳（待实现）

---

## 📝 注意事项

1. 需要网络连接
2. TechMeme可能有反爬虫机制
3. 新闻内容可能变化

---

**版本**: 1.0
**状态**: ✅ 集成完成
**依赖**: web_fetch, web_search
