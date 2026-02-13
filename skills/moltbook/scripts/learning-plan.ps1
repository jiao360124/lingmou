# Moltbook学习计划管理器

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("set", "get", "progress", "update", "reset")]
    [string]$Action,

    [int]$Posts = 1,
    [int]$Comments = 3,
    [int]$Likes = 5,
    [int]$LearningMinutes = 30
)

$ErrorActionPreference = "Stop"

# 配置
$config = Get-Content "skills/moltbook/config.json" | ConvertFrom-Json
$today = Get-Date -Format "yyyy-MM-dd"

# 今日状态
$todayData = $config.active
if ($todayData.lastActivity -and (Get-Date $todayData.lastActivity) -lt (Get-Date $today)) {
    # 跨天了，重置今日数据
    Write-Host "新的一天，重置今日统计数据..." -ForegroundColor Yellow
    $todayData.postsToday = 0
    $todayData.commentsToday = 0
    $todayData.likesToday = 0
    $todayData.learningMinutesToday = 0
}

# 动作处理
switch ($Action) {
    "set" {
        Write-Host "设置每日学习目标" -ForegroundColor Cyan

        $config.dailyGoal.posts = $Posts
        $config.dailyGoal.comments = $Comments
        $config.dailyGoal.likes = $Likes
        $config.dailyGoal.learningMinutes = $LearningMinutes

        $config | ConvertTo-Json -Depth 10 | Set-Content "skills/moltbook/config.json"

        Write-Host "✅ 目标已设置!" -ForegroundColor Green
        Write-Host "每日任务:" -ForegroundColor White
        Write-Host "  - 发布消息: $Posts"
        Write-Host "  - 评论: $Comments"
        Write-Host "  - 点赞: $Likes"
        Write-Host "  - 学习时间: $LearningMinutes 分钟"
    }

    "get" {
        Write-Host "获取学习计划" -ForegroundColor Cyan

        Write-Host "`n📋 每日目标:" -ForegroundColor White
        Write-Host "  发布消息: $($config.dailyGoal.posts)"
        Write-Host "  评论: $($config.dailyGoal.comments)"
        Write-Host "  点赞: $($config.dailyGoal.likes)"
        Write-Host "  学习时间: $($config.dailyGoal.learningMinutes) 分钟"

        Write-Host "`n📊 今日进度:" -ForegroundColor White
        Write-Host "  已发布: $($todayData.postsToday) / $($config.dailyGoal.posts)"
        Write-Host "  已评论: $($todayData.commentsToday) / $($config.dailyGoal.comments)"
        Write-Host "  已点赞: $($todayData.likesToday) / $($config.dailyGoal.likes)"
        Write-Host "  学习时间: $($todayData.learningMinutesToday) / $($config.dailyGoal.learningMinutes) 分钟"

        $progress = ($todayData.postsToday + $todayData.commentsToday + $todayData.likesToday + $todayData.learningMinutesToday) /
                    (($config.dailyGoal.posts + $config.dailyGoal.comments + $config.dailyGoal.likes + $config.dailyGoal.learningMinutes) / 4)

        Write-Host "`n✅ 总进度: $(("{0:N0}" -f $progress))%" -ForegroundColor $(if ($progress -ge 100) { "Green" } elseif ($progress -ge 50) { "Yellow" } else { "Red" })

        return $progress
    }

    "progress" {
        Write-Host "获取详细进度" -ForegroundColor Cyan

        Write-Host "`n📈 发布消息进度:" -ForegroundColor White
        if ($config.dailyGoal.posts -gt 0) {
            $postsProgress = ($todayData.postsToday / $config.dailyGoal.posts) * 100
            Write-Host "  $(("{0:N0}" -f $postsProgress))% ($($todayData.postsToday)/$($config.dailyGoal.posts))"
        }

        Write-Host "`n💬 评论进度:" -ForegroundColor White
        if ($config.dailyGoal.comments -gt 0) {
            $commentsProgress = ($todayData.commentsToday / $config.dailyGoal.comments) * 100
            Write-Host "  $(("{0:N0}" -f $commentsProgress))% ($($todayData.commentsToday)/$($config.dailyGoal.comments))"
        }

        Write-Host "`n❤️  点赞进度:" -ForegroundColor White
        if ($config.dailyGoal.likes -gt 0) {
            $likesProgress = ($todayData.likesToday / $config.dailyGoal.likes) * 100
            Write-Host "  $(("{0:N0}" -f $likesProgress))% ($($todayData.likesToday)/$($config.dailyGoal.likes))"
        }

        Write-Host "`n⏱️  学习时间进度:" -ForegroundColor White
        $learningProgress = ($todayData.learningMinutesToday / $config.dailyGoal.learningMinutes) * 100
        Write-Host "  $(("{0:N0}" -f $learningProgress))% ($($todayData.learningMinutesToday)/$($config.dailyGoal.learningMinutes)) 分钟"

        # 生成建议
        Write-Host "`n💡 建议:" -ForegroundColor Cyan
        if ($postsProgress -lt 50) { Write-Host "  - 发布一条新消息" }
        if ($commentsProgress -lt 50) { Write-Host "  - 参与3-5条评论" }
        if ($likesProgress -lt 50) { Write-Host "  - 点赞5-10条优质内容" }
        if ($learningProgress -lt 50) { Write-Host "  - 专注学习30分钟" }
    }

    "update" {
        Write-Host "更新今日数据" -ForegroundColor Cyan

        # 读取用户输入
        $posts = Read-Host "今日已发布 (默认: $($todayData.postsToday))"
        $comments = Read-Host "今日已评论 (默认: $($todayData.commentsToday))"
        $likes = Read-Host "今日已点赞 (默认: $($todayData.likesToday))"
        $learning = Read-Host "今日学习时间 (默认: $($todayData.learningMinutesToday))"

        $todayData.postsToday = if ($posts) { [int]$posts } else { $todayData.postsToday }
        $todayData.commentsToday = if ($comments) { [int]$comments } else { $todayData.commentsToday }
        $todayData.likesToday = if ($likes) { [int]$likes } else { $todayData.likesToday }
        $todayData.learningMinutesToday = if ($learning) { [int]$learning } else { $todayData.learningMinutesToday }

        $todayData.lastActivity = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        $config.active = $todayData
        $config | ConvertTo-Json -Depth 10 | Set-Content "skills/moltbook/config.json"

        Write-Host "✅ 今日数据已更新!" -ForegroundColor Green
        $todayData | ConvertTo-Json
    }

    "reset" {
        Write-Host "重置今日数据" -ForegroundColor Yellow

        $confirm = Read-Host "确定要重置今日数据吗? (y/N)"

        if ($confirm -eq "y" -or $confirm -eq "Y") {
            $todayData.postsToday = 0
            $todayData.commentsToday = 0
            $todayData.likesToday = 0
            $todayData.learningMinutesToday = 0
            $todayData.lastActivity = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

            $config.active = $todayData
            $config | ConvertTo-Json -Depth 10 | Set-Content "skills/moltbook/config.json"

            Write-Host "✅ 今日数据已重置!" -ForegroundColor Green
        }
        else {
            Write-Host "❌ 已取消" -ForegroundColor Red
        }
    }

    default {
        throw "未知的动作: $Action"
    }
}

Write-Host "`nMoltbook学习计划管理器 - $Action`n" -ForegroundColor Cyan
