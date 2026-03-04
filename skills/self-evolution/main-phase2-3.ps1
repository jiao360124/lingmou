# Self-Evolution Engine - Phase 2 & 3

# @Author: LingMou
# @Version: 1.0.0

param(
    [ValidateSet("optimize", "moltbook", "all")]
    [string]$Action = "all"
)

Write-Host "`n========== Self-Evolution Engine - Phase 2 & 3 ==========" -ForegroundColor Magenta

switch ($Action) {
    "optimize" {
        Write-Host "`nPhase 2: Continuous Optimization System`n" -ForegroundColor Yellow
        & "$PSScriptRoot/continuous-optimizer.ps1" -Action check
        & "$PSScriptRoot/continuous-optimizer.ps1" -Action plan
    }

    "moltbook" {
        Write-Host "`nPhase 3: Moltbook Integration System`n" -ForegroundColor Yellow
        & "$PSScriptRoot/moltbook-integrator.ps1" -Action sync
        & "$PSScriptRoot/moltbook-integrator.ps1" -Action interact
    }

    "all" {
        Write-Host "`nPhase 1: Learning Analysis`n" -ForegroundColor Yellow
        & "$PSScriptRoot/main.ps1" -Action analyze

        Write-Host "`nPhase 2: Continuous Optimization`n" -ForegroundColor Yellow
        & "$PSScriptRoot/continuous-optimizer.ps1" -Action check
        & "$PSScriptRoot/continuous-optimizer.ps1" -Action plan

        Write-Host "`nPhase 3: Moltbook Integration`n" -ForegroundColor Yellow
        & "$PSScriptRoot/moltbook-integrator.ps1" -Action sync
        & "$PSScriptRoot/moltbook-integrator.ps1" -Action interact
    }
}

Write-Host "`n========== All Phases Completed ==========" -ForegroundColor Green
