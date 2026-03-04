# Self-Evolution Engine - Main Program

# @Author: LingMou
# @Version: 1.0.0

param(
    [ValidateSet("analyze", "recognize", "generate", "all")]
    [string]$Action = "analyze"
)

Write-Host "`n========== Self-Evolution Engine ==========" -ForegroundColor Magenta
Write-Host "Action: $Action`n" -ForegroundColor Cyan

switch ($Action) {
    "analyze" {
        Write-Host "Step 1: Learning Analysis`n" -ForegroundColor Yellow
        & "$PSScriptRoot/learner-analyzer.ps1"
    }

    "recognize" {
        Write-Host "Step 2: Pattern Recognition`n" -ForegroundColor Yellow
        & "$PSScriptRoot/pattern-recognizer.ps1"
    }

    "generate" {
        Write-Host "Step 3: Generate Recommendations`n" -ForegroundColor Yellow
        & "$PSScriptRoot/improvement-generator.ps1"
    }

    "all" {
        Write-Host "Step 1: Learning Analysis`n" -ForegroundColor Yellow
        & "$PSScriptRoot/learner-analyzer.ps1"

        Write-Host "Step 2: Pattern Recognition`n" -ForegroundColor Yellow
        & "$PSScriptRoot/pattern-recognizer.ps1"

        Write-Host "Step 3: Generate Recommendations`n" -ForegroundColor Yellow
        & "$PSScriptRoot/improvement-generator.ps1"

        Write-Host "=============================" -ForegroundColor Green
    }
}
