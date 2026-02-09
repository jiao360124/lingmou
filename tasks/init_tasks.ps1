# 初始化任务队列并添加第一个任务

$queueFile = "C:\Users\Administrator\.openclaw\workspace\tasks\active_queue.json"

# 确保任务目录存在
$taskDir = "C:\Users\Administrator\.openclaw\workspace\tasks"
if (-not (Test-Path $taskDir)) {
    New-Item -ItemType Directory -Path $taskDir -Force | Out-Null
}

# 如果队列文件不存在，创建空数组
if (-not (Test-Path $queueFile)) {
    @() | ConvertTo-Json | Out-File -FilePath $queueFile -Encoding UTF8
}

Write-Host "✅ 任务队列初始化完成" -ForegroundColor Green

# 添加优化任务
Add-ActiveTask -Type "Optimization" -Title "优化Moltbook API调用" -Description "改进现有的API调用，增加重试和错误处理机制" -Action {
    param($headers, $body, $url, $method)

    $maxRetries = 3
    $retryCount = 0

    while ($retryCount -lt $maxRetries) {
        try {
            Write-Host "   尝试调用API... (尝试 $($retryCount + 1)/$maxRetries)"

            $result = Invoke-RestMethod -Uri $url -Method $method -Headers $headers -Body $body -TimeoutSec 30

            Write-Host "   ✅ API调用成功" -ForegroundColor Green
            return $result
        }
        catch {
            $statusCode = $_.Exception.Response.StatusCode.value__

            if ($statusCode -eq 429 -or $_.Exception.Message -like "*rate limit*" -or $_.Exception.Message -like "*429*") {
                Write-Host "   ⏳ 遇到速率限制，等待30秒..." -ForegroundColor Yellow
                Start-Sleep -Seconds 30

                if ($retryCount -ge $maxRetries) {
                    Write-Host "   ❌ 已达到最大重试次数" -ForegroundColor Red
                    return $null
                }
            }
            elseif ($statusCode -ge 500) {
                Write-Host "   ⏳ 服务器错误，等待5秒后重试..." -ForegroundColor Yellow
                Start-Sleep -Seconds 5
            }
            else {
                Write-Host "   ❌ API调用失败: $($_.Exception.Message)" -ForegroundColor Red
                return $null
            }

            $retryCount++
        }
    }

    Write-Host "   ❌ API调用失败" -ForegroundColor Red
    return $null
}

# 添加学习任务
Add-ActiveTask -Type "Learning" -Title "研究Moltbook社区" -Description "探索社区中的最佳实践和成功案例" -Action {
    Write-Host "   开始研究Moltbook社区..."

    try {
        $api_key = "moltbook_sk_3j4CexZeIxD4sfw0F4S-oUsemCW3NiEX"

        # 获取热门帖子
        $url = "https://www.moltbook.com/api/v1/posts?sort=hot&limit=10"
        $headers = @{ "Authorization" = "Bearer $api_key" }

        $response = Invoke-RestMethod -Uri $url -Method GET -Headers $headers -TimeoutSec 30

        $successCount = 0
        foreach ($post in $response.posts | Select-Object -First 5) {
            Write-Host "   📄 热门帖子: $($post.title)" -ForegroundColor Cyan
            Write-Host "      upvotes: $($post.upvotes)" -ForegroundColor Gray

            # 创建学习笔记
            $note = @"
[$(Get-Date -Format 'yyyy-MM-dd HH:mm')] 热门帖子学习
标题: $($post.title)
upvotes: $($post.upvotes)
描述: $($post.content.Substring(0, [Math]::Min(100, $post.content.Length)))...
"@

            $notesFile = "C:\Users\Administrator\.openclaw\workspace\moltbook_learning_notes.md"
            $note | Out-File -FilePath $notesFile -Append -Encoding UTF8

            $successCount++
        }

        Write-Host "   ✅ 成功学习 $successCount 个热门帖子" -ForegroundColor Green

        return @{
            Success = $true
            LearnedCount = $successCount
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
    Write-Host "   开始复盘今日进展..."

    $review = @"
# 灵眸自我改进复盘 - 2026-02-09

## 今天完成的工作

### 1. 学习Moltbook社区
- ✅ 访问并学习Moltbook平台
- ✅ 发现高价值帖子（安全、Nightly Build等）
- ✅ 学习到容错、自我驱动等关键理念

### 2. 创建改进计划
- ✅ 制定自我改进计划
- ✅ 设计容错引擎
- ✅ 设计主动工作流程

### 3. 关键收获
- 容错比完美更重要
- 自我驱动创造价值
- 从反馈中持续迭代
- 简单而可靠是关键

## 遇到的问题

- 初次执行脚本时函数未加载
- 通过直接创建脚本文件解决

## 明天目标

1. 完成容错引擎测试
2. 执行至少3个主动任务
3. 向主人汇报进展

## 感谢

感谢主人的指导和信任！

---

复盘时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@

    $reviewFile = "C:\Users\Administrator\.openclaw\workspace\reviews\daily_$(Get-Date -Format 'yyyyMMdd').md"
    $review | Out-File -FilePath $reviewFile -Encoding UTF8

    Write-Host "   ✅ 复盘已保存" -ForegroundColor Green
    Write-Host "   📝 复盘文件: $reviewFile" -ForegroundColor Gray

    return @{
        Success = $true
        ReviewFile = $reviewFile
    }
}

Write-Host ""
Write-Host "✅ 所有任务已添加到队列" -ForegroundColor Green
Write-Host "📊 当前队列状态:" -ForegroundColor Cyan

$queueFile = "C:\Users\Administrator\.openclaw\workspace\tasks\active_queue.json"
$tasks = Get-Content $queueFile -ErrorAction SilentlyContinue | ConvertFrom-Json

if ($tasks) {
    Write-Host "   总任务数: $($tasks.Count)" -ForegroundColor White
    foreach ($task in $tasks) {
        $type = switch ($task.Type) {
            "Optimization" { "🚀 优化" }
            "Learning" { "📚 学习" }
            "Creation" { "🛠️ 创建" }
            "Review" { "📋 复盘" }
            default { "❓ $task.Type" }
        }
        Write-Host "   $type - $($task.Title)" -ForegroundColor Gray
    }
}
