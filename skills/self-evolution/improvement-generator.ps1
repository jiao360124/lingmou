# Improvement Generator

$ScriptPath = $PSScriptRoot
$RecommendationsFile = "$ScriptPath/data/recommendations.json"

Write-Host "[IMPROVE] Starting Recommendation Generation`n" -ForegroundColor Magenta

# Load patterns
$PatternsFile = "$ScriptPath/data/pattern-database.json"

if (Test-Path $PatternsFile) {
    $Data = Get-Content -Path $PatternsFile | ConvertFrom-Json

    # Generate recommendations
    $Recommendations = @()

    # Based on optimization patterns
    foreach ($Pattern in $Data.optimizationPatterns.commonPatterns) {
        $Recommendations += @{
            category = "Optimization"
            priority = "medium"
            description = "Implement $Pattern.name"
            suggestion = $Pattern.description
            impact = "Maintain system quality"
            estimatedEffort = "Medium"
            action = "Follow the pattern"
        }
    }

    # Based on learning patterns
    foreach ($Focus in $Data.learningPatterns.focusAreas) {
        $Recommendations += @{
            category = "Learning"
            priority = "high"
            description = "Focus on $Focus.area"
            suggestion = "Invest time in $Focus.area development"
            impact = "Drive growth in key areas"
            estimatedEffort = $Focus.intensity
            action = "Create learning plan"
        }
    }

    # Priority ranking
    $Prioritized = $Recommendations | Sort-Object {
        $Weight = 0
        if ($_.priority -eq "high") { $Weight = 3 }
        elseif ($_.priority -eq "medium") { $Weight = 2 }
        elseif ($_.priority -eq "low") { $Weight = 1 }
        return -$Weight
    }

    # Create action plan
    $ActionPlan = @{
        total = $Prioritized.Count
        high = ($Prioritized | Where-Object { $_.priority -eq "high" }).Count
        medium = ($Prioritized | Where-Object { $_.priority -eq "medium" }).Count
        low = ($Prioritized | Where-Object { $_.priority -eq "low" }).Count
        estimatedEffort = "Medium"
    }

    # Save recommendations
    if (-not (Test-Path (Split-Path $RecommendationsFile))) {
        New-Item -ItemType Directory -Path (Split-Path $RecommendationsFile) -Force | Out-Null
    }

    $Output = @{
        timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        recommendations = $Prioritized
        actionPlan = $ActionPlan
    }

    $Output | ConvertTo-Json -Depth 10 | Out-File -FilePath $RecommendationsFile -Encoding UTF8 -Force
    Write-Host "[SUCCESS] Recommendations saved to $RecommendationsFile`n" -ForegroundColor Green

    # Print summary
    Write-Host "========== Recommendation Summary ==========" -ForegroundColor Magenta
    Write-Host "Total recommendations: $($Prioritized.Count)`n" -ForegroundColor Cyan
    Write-Host "High priority: $($ActionPlan.high)`n" -ForegroundColor Yellow
    Write-Host "Medium priority: $($ActionPlan.medium)`n" -ForegroundColor Cyan
    Write-Host "Low priority: $($ActionPlan.low)`n" -ForegroundColor Cyan
    Write-Host "=============================================`n" -ForegroundColor Magenta

    # Print high priority recommendations
    Write-Host "High Priority Recommendations:" -ForegroundColor Red
    foreach ($Rec in $Prioritized | Where-Object { $_.priority -eq "high" }) {
        Write-Host "  - $($Rec.category): $($Rec.description)" -ForegroundColor Yellow
        Write-Host "    Impact: $($Rec.impact)" -ForegroundColor Green
    }

    $Output
} else {
    Write-Host "[WARNING] Pattern data not found. Run pattern-recognizer first.`n" -ForegroundColor Yellow
}
