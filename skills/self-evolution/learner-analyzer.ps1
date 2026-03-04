# Learning Analyzer

$ScriptPath = $PSScriptRoot
$Workspace = "$ScriptPath/../../.."
$MemoryFile = "$Workspace/memory/YYYY-MM-DD.md"
$LearningLog = "$ScriptPath/data/learning-log.md"
$PatternsFile = "$ScriptPath/data/patterns.json"

Write-Host "[LEARNING] Starting Analysis`n" -ForegroundColor Magenta

$Result = @{
    UsagePatterns = @{}
    PerformanceInsights = @{}
    OptimizationOpportunities = @()
}

# Step 1: Usage Patterns
Write-Host "[INFO] Analyzing usage patterns..." -ForegroundColor Cyan
$Result.UsagePatterns.totalSessions = 0

if (Test-Path $MemoryFile) {
    $Content = Get-Content -Path $MemoryFile -Raw
    $Dates = ($Content -match '^\d{4}-\d{2}-\d{2}') | Select-Object -Unique
    $Result.UsagePatterns.totalSessions = $Dates.Count
    Write-Host "[SUCCESS] Found $($Dates.Count) days of data`n" -ForegroundColor Green
} else {
    Write-Host "[WARNING] Memory file not found`n" -ForegroundColor Yellow
}

# Step 2: Performance Insights
Write-Host "[INFO] Analyzing performance..." -ForegroundColor Cyan
$SkillsDir = "$Workspace/skills"
$SkillUsage = @{}

if (Test-Path $SkillsDir) {
    foreach ($Skill in Get-ChildItem -Path $SkillsDir -Directory) {
        $UsageCount = ($Content -split "`n" | Where-Object { $_ -match $Skill.Name }).Count
        $SkillUsage[$Skill.Name] = @{
            name = $Skill.Name
            usageCount = $UsageCount
        }
    }

    $Result.PerformanceInsights.skillUsage = $SkillUsage
    Write-Host "[SUCCESS] Analyzed $($SkillUsage.Count) skills`n" -ForegroundColor Green
}

# Step 3: Optimization Opportunities
Write-Host "[INFO] Finding optimization opportunities..." -ForegroundColor Cyan

$Optimizations = @()

if ($SkillUsage) {
    # Unused skills
    $Unused = $SkillUsage.Values | Where-Object { $_.usageCount -eq 0 }
    if ($Unused.Count -gt 0) {
        $Optimizations += @{
            type = "skill-usage"
            priority = "medium"
            description = "$($Unused.Count) skills unused"
            recommendation = "Consider deleting unused skills"
        }
    }

    # Frequent skills
    $Frequent = $SkillUsage.Values | Where-Object { $_.usageCount -gt 5 }
    if ($Frequent.Count -gt 0) {
        $Optimizations += @{
            type = "skill-usage"
            priority = "low"
            description = "$($Frequent.Count) skills used frequently"
            recommendation = "Consider optimizing frequent skills"
        }
    }
}

# Storage size
$TotalSize = 0
try {
    $Files = Get-ChildItem -Path $SkillsDir -File -Recurse -ErrorAction SilentlyContinue
    $TotalSize = ($Files | Measure-Object -Property Length -Sum).Sum / 1KB
} catch {}

if ($TotalSize -gt 1000) {
    $Optimizations += @{
        type = "storage"
        priority = "low"
        description = "Skills size: $([math]::Round($TotalSize, 2))KB"
        recommendation = "Clean up unused files"
    }
}

$Result.OptimizationOpportunities = $Optimizations
Write-Host "[SUCCESS] Found $($Optimizations.Count) opportunities`n" -ForegroundColor Green

# Step 4: Save Pattern Data
if (-not (Test-Path (Split-Path $PatternsFile))) {
    New-Item -ItemType Directory -Path (Split-Path $PatternsFile) -Force | Out-Null
}

$PatternData = @{
    timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    usagePatterns = $Result.UsagePatterns
    performanceInsights = $Result.PerformanceInsights
    optimizationOpportunities = $Optimizations
}

$PatternData | ConvertTo-Json -Depth 10 | Out-File -FilePath $PatternsFile -Encoding UTF8 -Force
Write-Host "[SUCCESS] Pattern data saved to $PatternsFile`n" -ForegroundColor Green

# Print Summary
Write-Host "========== Summary ==========" -ForegroundColor Magenta
Write-Host "Sessions: $($Result.UsagePatterns.totalSessions)`n"
Write-Host "Skills found: $($SkillUsage.Count)`n"
Write-Host "Optimization opportunities: $($Optimizations.Count)`n"

if ($Optimizations.Count -gt 0) {
    Write-Host "`nPriorities:" -ForegroundColor Yellow
    foreach ($Opt in $Optimizations) {
        $Icon = switch ($Opt.priority) {
            "high" { "🔴" }
            "medium" { "🟡" }
            "low" { "🟢" }
        }
        Write-Host "  $Icon $($Opt.description)" -ForegroundColor Cyan
    }
}

Write-Host "=============================`n" -ForegroundColor Magenta

$Result
