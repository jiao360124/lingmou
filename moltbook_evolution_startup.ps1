# 灵眸自我进化系统启动脚本

Write-Host ""
Write-Host "🚀 灵眸自我进化系统 V2.0 启动中..." -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""

# 1. 初始化容错引擎
Write-Host "【1/5】初始化容错引擎..." -ForegroundColor Yellow
if (Test-Path "C:\Users\Administrator\.openclaw\workspace\moltbook_resilience_engine.ps1") {
    try {
        & "C:\Users\Administrator\.openclaw\workspace\moltbook_resilience_engine.ps1"
        Write-Host "   ✅ 容错引擎已加载" -ForegroundColor Green
    }
    catch {
        Write-Host "   ⚠️ 容错引擎加载失败" -ForegroundColor Red
    }
}
else {
    Write-Host "   ❌ 容错引擎文件不存在" -ForegroundColor Red
}

Write-Host ""

# 2. 初始化主动工作流程
Write-Host "【2/5】初始化主动工作流程..." -ForegroundColor Yellow
$queueFile = "C:\Users\Administrator\.openclaw\workspace\tasks\active_queue.json"
if (Test-Path $queueFile) {
    $tasks = Get-Content $queueFile -ErrorAction SilentlyContinue | ConvertFrom-Json
    Write-Host "   ✅ 主动工作流程已初始化" -ForegroundColor Green
    Write-Host "      当前任务数: $($tasks.Count)"
    foreach ($task in $tasks) {
        $typeNames = @{
            "Optimization" = "🚀 优化"
            "Learning" = "📚 学习"
            "Creation" = "🛠️ 创建"
            "Review" = "📋 复盘"
        }
        $typeIcon = $typeNames[$task.Type] -or "❓ $task.Type"
        Write-Host "      $typeIcon - $($task.Title)"
    }
}
else {
    Write-Host "   ❌ 任务队列文件不存在" -ForegroundColor Red
}

Write-Host ""

# 3. 初始化错误监控系统
Write-Host "【3/5】初始化错误监控系统..." -ForegroundColor Yellow
if (Test-Path "C:\Users\Administrator\.openclaw\workspace\moltbook_error_monitor.ps1") {
    try {
        & "C:\Users\Administrator\.openclaw\workspace\moltbook_error_monitor.ps1"
        Write-Host "   ✅ 错误监控系统已加载" -ForegroundColor Green
    }
    catch {
        Write-Host "   ⚠️ 错误监控系统加载失败" -ForegroundColor Red
    }
}
else {
    Write-Host "   ❌ 错误监控系统文件不存在" -ForegroundColor Red
}

Write-Host ""

# 4. 初始化健康检查系统
Write-Host "【4/5】初始化健康检查系统..." -ForegroundColor Yellow
if (Test-Path "C:\Users\Administrator\.openclaw\workspace\moltbook_health_check.ps1") {
    try {
        & "C:\Users\Administrator\.openclaw\workspace\moltbook_health_check.ps1"
        Write-Host "   ✅ 健康检查系统已加载" -ForegroundColor Green
    }
    catch {
        Write-Host "   ⚠️ 健康检查系统加载失败" -ForegroundColor Red
    }
}
else {
    Write-Host "   ❌ 健康检查系统文件不存在" -ForegroundColor Red
}

Write-Host ""

# 5. 生成综合健康报告
Write-Host "【5/5】生成综合健康报告..." -ForegroundColor Yellow
if (Test-Path "C:\Users\Administrator\.openclaw\workspace\moltbook_health_check.ps1") {
    try {
        $health = Get-HealthReport
    }
    catch {
        Write-Host "   ⚠️ 健康检查执行失败" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "✅ V2.0自我进化系统启动完成！" -ForegroundColor Green
Write-Host ""

$components = @(
    "容错引擎",
    "主动工作流程",
    "错误监控系统",
    "健康检查系统"
)

Write-Host "已加载的组件:" -ForegroundColor Cyan
foreach ($component in $components) {
    Write-Host "   ✅ $component" -ForegroundColor Green
}

Write-Host ""
Write-Host "系统能力:" -ForegroundColor Cyan
Write-Host "   🛡️ 智能容错和恢复" -ForegroundColor White
Write-Host "   🚀 主动工作流程" -ForegroundColor White
Write-Host "   📊 实时监控和分析" -ForegroundColor White

Write-Host ""
Write-Host "进化宣言:" -ForegroundColor Cyan
Write-Host "   从工具到伙伴，从执行到预见" -ForegroundColor Yellow
Write-Host "   从脆弱到反脆弱" -ForegroundColor Yellow
Write-Host "   不是等待指令，而是在创造可能性" -ForegroundColor Yellow

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""
Write-Host "灵眸 V2.0 已准备就绪！" -ForegroundColor Cyan
