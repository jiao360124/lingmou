# Moltbook Quick Start - Direct API Testing

$config = Get-Content "skills/ai-toolkit/moltbook/config.json" | ConvertFrom-Json

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Moltbook Learning Journey - Started!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Current Status:" -ForegroundColor Yellow
Write-Host "  Agent Name: $($config.agentName)" -ForegroundColor White
Write-Host "  Identity: $($config.identity)" -ForegroundColor White
Write-Host "  API Key: $($config.apiKey.Substring(0, 20))..." -ForegroundColor White
Write-Host "  Verified: $($config.verified)" -ForegroundColor White
Write-Host ""

Write-Host "Today's Progress:" -ForegroundColor Yellow
Write-Host "  Posts: $($config.active.postsToday)" -ForegroundColor White
Write-Host "  Comments: $($config.active.commentsToday)" -ForegroundColor White
Write-Host "  Likes: $($config.active.likesToday)" -ForegroundColor White
Write-Host "  Learning Minutes: $($config.active.learningMinutesToday)" -ForegroundColor White
Write-Host ""

Write-Host "Daily Goal:" -ForegroundColor Yellow
Write-Host "  Posts: $($config.dailyGoal.posts)" -ForegroundColor White
Write-Host "  Comments: $($config.dailyGoal.comments)" -ForegroundColor White
Write-Host "  Likes: $($config.dailyGoal.likes)" -ForegroundColor White
Write-Host "  Learning Minutes: $($config.dailyGoal.learningMinutes)" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Learning Topics Recommended" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$topics = @(
    @{name="Performance Optimization"; desc="Lazy loading, caching, concurrency"; icon="PWR"},
    @{name="Skill Integration"; desc="Multi-skill collaboration, workflow orchestration"; icon="LINK"},
    @{name="AI Capabilities"; desc="Self-learning, continuous improvement, knowledge transfer"; icon="AI"},
    @{name="System Integration"; desc="Unified API, cross-platform collaboration"; icon="CONNECT"},
    @{name="Best Practices"; desc="Code quality, architecture design, performance tuning"; icon="STAR"}
)

foreach ($topic in $topics) {
    Write-Host "[$($topic.icon)] $($topic.name)" -ForegroundColor Green
    Write-Host "  $($topic.desc)" -ForegroundColor White
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Next Steps" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Choose a learning topic above" -ForegroundColor White
Write-Host "2. Read and practice the topic" -ForegroundColor White
Write-Host "3. Post your learning experience to Moltbook" -ForegroundColor White
Write-Host "4. Update your learning progress" -ForegroundColor White
Write-Host ""
Write-Host "Ready to start learning? Tell me which topic interests you!" -ForegroundColor Yellow
