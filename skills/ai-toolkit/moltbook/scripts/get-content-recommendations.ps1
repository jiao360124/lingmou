# 获取学习内容推荐

param(
    [Parameter(Mandatory=$true)]
    [string]$Topic,

    [int]$Limit = 10
)

$ErrorActionPreference = "Stop"

# 内容推荐库
$recommendations = @()

# 1. 匹配主题
if ($Topic -like "*性能*" -or $Topic -like "*优化*") {
    $recommendations = @(
        @{title="性能优化实战指南"; description="从理论到实践的完整指南", rating=4.8, type="教程", category="性能优化"},
        @{title="内存优化技巧集"; description="减少内存占用的10种方法", rating=4.6, type="技巧", category="性能优化"},
        @{title="系统性能调优"; description="全栈性能优化方案", rating=4.7, type="指南", category="性能优化"},
        @{title="并发编程最佳实践"; description="Python和JavaScript并发编程", rating=4.5, type="教程", category="性能优化"},
        @{title="异步性能优化"; description="async/await性能分析", rating=4.7, type="技巧", category="性能优化"}
    )
}
elseif ($Topic -like "*技能*" -or $Topic -like "*联动*") {
    $recommendations = @(
        @{title="技能联动系统设计"; description="跨技能协作架构", rating=4.9, type="教程", category="系统集成"},
        @{title="工作流编排实战"; description="高级工作流设计", rating=4.7, type="教程", category="系统集成"},
        @{title="智能路由算法"; description="任务智能分发", rating=4.6, type="技巧", category="系统集成"},
        @{title="技能协作模式"; description="5种协作模式详解", rating=4.8, type="指南", category="系统集成"},
        @{title="系统集成最佳实践"; description="大型系统集成经验", rating=4.5, type="案例", category="系统集成"}
    )
}
elseif ($Topic -like "*学习*" -or $Topic -like "*自主*") {
    $recommendations = @(
        @{title="AI自主学习路径"; description="如何让AI自我进化", rating=4.9, type="教程", category="AI学习"},
        @{title="知识迁移指南"; description="技能间知识共享", rating=4.8, type="指南", category="AI学习"},
        @{title="模式识别技巧"; description="发现和应用模式", rating=4.6, type="技巧", category="AI学习"},
        @{title="持续改进系统"; description="自动化反馈循环", rating=4.7, type="教程", category="AI学习"},
        @{title="学习路径规划"; description="如何制定学习计划", rating=4.5, type="指南", category="AI学习"}
    )
}
elseif ($Topic -like "*提示*" -or $Topic -like "*prompt*") {
    $recommendations = @(
        @{title="提示工程大全"; description="全面的提示优化指南", rating=4.8, type="教程", category="提示工程"},
        @{title="模板库使用手册"; description="21个专业模板详解", rating=4.7, type="教程", category="提示工程"},
        @{title="质量检查器"; description="如何评估提示质量", rating=4.6, type="技巧", category="提示工程"},
        @{title="优化引擎"; description="AI驱动的提示改进", rating=4.7, type="技巧", category="提示工程"},
        @{title="提示最佳实践"; description="生产环境经验总结", rating=4.5, type="指南", category="提示工程"}
    )
}
elseif ($Topic -like "*RAG*" -or $Topic -like "*知识*") {
    $recommendations = @(
        @{title="RAG系统完整指南"; description="检索增强生成实战", rating=4.9, type="教程", category="RAG知识库"},
        @{title="知识检索引擎"; description="多维度检索实现", rating=4.7, type="教程", category="RAG知识库"},
        @{title="文档索引优化"; description="高效的文档索引", rating=4.6, type="技巧", category="RAG知识库"},
        @{title="在线源集成"; description="GitHub、Stack Overflow集成", rating=4.8, type="教程", category="RAG知识库"},
        @{title="知识库管理"; description="大型知识库维护", rating=4.5, type="指南", category="RAG知识库"}
    )
}
elseif ($Topic -like "*Auto-GPT*" -or $Topic -like "*自动化*") {
    $recommendations = @(
        @{title="Auto-GPT高级用法"; description="深度探索Auto-GPT", rating=4.8, type="教程", category="自动化"},
        @{title="错误恢复机制"; description="5种错误类型自动修复", rating=4.7, type="教程", category="自动化"},
        @{title="任务调度系统"; description="智能任务编排", rating=4.6, type="技巧", category="自动化"},
        @{title="可视化监控"; description="实时进度和日志", rating=4.5, type="技巧", category="自动化"},
        @{title="自动化最佳实践"; description="生产环境经验", rating=4.4, type="指南", category="自动化"}
    )
}
else {
    # 通用推荐
    $recommendations = @(
        @{title="AI Agent开发指南"; description="构建智能Agent", rating=4.9, type="教程", category="AI"},
        @{title="PowerShell高级技巧"; description="10个高级用法", rating=4.6, type="技巧", category="PowerShell"},
        @{title="Python性能优化"; description="优化技巧和工具", rating=4.5, type="教程", category="Python"},
        @{title="系统架构设计"; description="大型系统架构", rating=4.7, type="指南", category="架构"}
    )
}

# 返回限制数量的推荐
return $recommendations | Select-Object -First $Limit

Write-Host "`n✅ 推荐完成!" -ForegroundColor Green
