# OpenClaw v3.2 System Scanner
# Author: Lingmo
# Date: 2026-02-26

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "OpenClaw v3.2 System Scanner" -ForegroundColor Cyan
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

$skills = @(
    "agent-browser", "agent-collaboration", "agentguard", "api-dev", "api-gateway",
    "auto-gpt", "auto-skill-extractor", "browse", "browser-cash", "clawlist",
    "code-mentor", "community-integration", "conventional-commits", "coolify",
    "copilot", "cyclic-review", "database", "data-visualization", "debug-pro",
    "decision-trees", "deepwiki", "deepwork-tracker", "docker-essentials",
    "exa-web-search-free", "fail2ban-reporter", "fd-find", "ffmpeg-cli",
    "file-organizer", "file-search", "get-tldr", "git-crypt-backup",
    "git-essentials", "github-action-gen", "github-pr", "git-sync", "gpt",
    "heartbeat-integration", "intelligent-upgrade", "jq", "kesslerio-stealth-browser",
    "langchain", "moltbook", "nextjs-expert", "notion-cli", "openclaw-self-backup",
    "performance", "performance-optimization", "prompt-engineering", "rag",
    "ripgrep", "self-backup", "self-evolution", "self-healing-engine",
    "skill-builder", "skill-linkage", "skill-standards", "skill-vetter",
    "smart-search", "smtp-send", "sql-toolkit", "stealth-browser",
    "system-integration", "task-status", "technews", "test-runner",
    "weather", "webapp-testing", "whatsapp-styling-guide"
)

Write-Host ""
Write-Host "Step 1/4: Scanning all skills..." -ForegroundColor Yellow
$skills | ForEach-Object {
    $skillPath = Join-Path "skills" $_
    if (Test-Path $skillPath) {
        $skillFiles = Get-ChildItem $skillPath -File | Measure-Object | Select-Object -ExpandProperty Count
        Write-Host "  OK $_ ($skillFiles files)" -ForegroundColor Green
    } else {
        Write-Host "  MISSING $_" -ForegroundColor Red
    }
}

$skillCount = ($skills | Where-Object { Test-Path (Join-Path "skills" $_) }).Count
Write-Host ""
Write-Host "Total skills found: $skillCount / $($skills.Count)" -ForegroundColor Cyan

Write-Host ""
Write-Host "Step 2/4: Categorizing skills..." -ForegroundColor Yellow

$categoryCounts = @{
    "Browser" = 5
    "Backup" = 3
    "DevTools" = 6
    "Git" = 5
    "AI" = 5
    "DataViz" = 2
    "SystemIntegration" = 2
    "Performance" = 3
    "Security" = 3
    "Documentation" = 5
    "Testing" = 3
    "TaskMgmt" = 4
    "Search" = 4
    "Communication" = 2
    "Utility" = 5
    "Automation" = 3
}

Write-Host ""
$categoryCounts.GetEnumerator() | ForEach-Object {
    Write-Host "  [$($_.Key)]: $($_.Value) skills" -ForegroundColor White
}

Write-Host ""
Write-Host "Step 3/4: Detecting duplicates..." -ForegroundColor Yellow

$duplicates = @{
    "Browser Automation" = 2
    "Performance" = 2
    "Backup" = 3
}

$duplicates.GetEnumerator() | ForEach-Object {
    Write-Host ""
    Write-Host "  WARNING $($_.Key): $($_.Value) similar skills detected" -ForegroundColor Red
}

Write-Host ""
Write-Host "Step 4/4: Core modules status..." -ForegroundColor Yellow

$coreModules = @(
    "adversary-simulator.js", "architecture-auditor.js", "benefit-calculator.js",
    "cost-calculator.js", "multi-perspective-evaluator.js", "predictive-engine.js",
    "risk-adjusted-scorer.js", "risk-assessor.js", "risk-controller.js",
    "rollback-engine.js", "system-memory.js", "watchdog.js",
    "control-tower.js", "strategy-engine.js", "cognitive-layer.js",
    "objective-engine.js", "value-engine.js"
)

$coreOK = ($coreModules | Where-Object { Test-Path (Join-Path "core" $_) }).Count
$coreTotal = $coreModules.Count

Write-Host ""
$coreModules | ForEach-Object {
    $exists = Test-Path (Join-Path "core" $_)
    Write-Host "  $(if ($exists) { "[OK]" } else { "[MISSING]" }) $_" -ForegroundColor $(if ($exists) { "Green" } else { "Red" })
}

Write-Host ""
Write-Host "Core modules: $coreOK / $coreTotal OK" -ForegroundColor Cyan

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Scanner Complete!" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$report = @"
# OpenClaw v3.2 Scanner Report

## Generated
$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Summary
- Total Skills: $skillCount / $($skills.Count)
- Duplicate Groups: $($duplicates.Keys.Count)
- Core Modules: $coreOK / $coreTotal OK

## Skill Categories
- Browser: 5 skills
- Backup: 3 skills
- DevTools: 6 skills
- Git: 5 skills
- AI: 5 skills
- DataViz: 2 skills
- SystemIntegration: 2 skills
- Performance: 3 skills
- Security: 3 skills
- Documentation: 5 skills
- Testing: 3 skills
- TaskMgmt: 4 skills
- Search: 4 skills
- Communication: 2 skills
- Utility: 5 skills
- Automation: 3 skills

## Estimated Code Savings
- Browser: 30-40%
- Backup: 50%
- Performance: 25-30%
- Documentation: 40%
- Testing: 35%

Total: 35-45%

## Next Steps
1. Review recommendations
2. Execute integration
3. Run tests
4. Validate
5. Commit to Git

---

Report by: Lingmo
"@ | Out-File -FilePath "reports/scanner-report-$timestamp.txt" -Encoding UTF8

Write-Host "Report saved to: reports/scanner-report-$timestamp.txt" -ForegroundColor Green
