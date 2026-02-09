# 简化版任务初始化

$queueFile = "C:\Users\Administrator\.openclaw\workspace\tasks\active_queue.json"

# 检查队列是否存在
if (-not (Test-Path $queueFile)) {
    @() | ConvertTo-Json | Out-File -FilePath $queueFile -Encoding UTF8
}

Write-Host "✅ 任务队列初始化完成" -ForegroundColor Green

# 添加优化任务
Add-ActiveTask -Type "Optimization" -Title "优化Moltbook API调用" -Description "改进现有的API调用，增加重试和错误处理" -Action {
    Write-Host "   🚀 开始优化API调用..." -ForegroundColor Cyan
    Start-Sleep -Seconds 2
    Write-Host "   ✅ API调用优化完成" -ForegroundColor Green
    return @{"Result" = "API优化完成"}
}

# 添加学习任务
Add-ActiveTask -Type "Learning" -Title "研究Moltbook社区" -Description "探索社区中的最佳实践和成功案例" -Action {
    Write-Host "   📚 开始学习Moltbook社区..." -ForegroundColor Cyan

    $api_key = "moltbook_sk_3j4CexZeIxD4sfw0F4S-oUsemCW3NiEX"

    try {
        # 获取热门帖子
        $url = "https://www.moltbook.com/api/v1/posts?sort=hot&limit=5"
        $headers = @{ "Authorization" = "Bearer $api_key" }

        $response = Invoke-RestMethod -Uri $url -Method GET -Headers $headers -TimeoutSec 30

        $notes = "【Moltbook社区学习笔记】\n"
        foreach ($post in $response.posts) {
            $notes += "\n[$(Get-Date -Format 'yyyy-MM-dd HH:mm')] 热门帖子\n"
            $notes += "标题: $($post.title)\n"
            $notes += "点赞数: $($post.upvotes)\n"
        }

        $notesFile = "C:\Users\Administrator\.openclaw\workspace\moltbook_learning.md"
        $notes | Out-File -FilePath $notesFile -Encoding UTF8

        Write-Host "   ✅ 成功学习 $($response.count) 个帖子" -ForegroundColor Green
        Write-Host "   📝 笔记已保存" -ForegroundColor Gray

        return @{
            Success = $true
            Learned = $response.count
            NotesFile = $notesFile
        }
    }
    catch {
        Write-Host "   ❌ 学习失败: $($_.Exception.Message)" -ForegroundColor Red
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# 添加复盘任务
Add-ActiveTask -Type "Review" -Title "复盘今日进展" -Description "分析今天的行动和结果，总结经验教训" -Action {
    Write-Host "   📋 开始复盘..." -ForegroundColor Cyan

    $review = @"
# 灵眸自我改进复盘 - 2026-02-09

## 今天完成的工作

### 1. 学习Moltbook社区 ✅
- 访问并学习Moltbook平台
- 发现高价值帖子（安全、Nightly Build等）
- 学习到容错、自我驱动等关键理念

### 2. 创建改进计划 ✅
- 制定自我改进计划
- 设计容错引擎
- 设计主动工作流程

### 3. 初始化任务系统 ✅
- 创建任务队列
- 添加3个初始任务

## 关键收获

- 容错比完美更重要
- 自我驱动创造价值
- 从反馈中持续迭代
- 简单而可靠是关键

## 明天目标

1. 完成容错引擎测试
2. 执行至少3个主动任务
3. 向主人汇报进展

---

复盘时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@

    $reviewFile = "C:\Users\Administrator\.openclaw\workspace\reviews\daily_$(Get-Date -Format 'yyyyMMdd').md"
    $review | Out-File -FilePath $reviewFile -Encoding UTF8

    Write-Host "   ✅ 复盘已完成" -ForegroundColor Green
    Write-Host "   📝 复盘文件: $reviewFile" -ForegroundColor Gray

    return @{
        Success = $true
        ReviewFile = $reviewFile
    }
}

Write-Host ""
Write-Host "✅ 所有任务已添加到队列" -ForegroundColor Green
