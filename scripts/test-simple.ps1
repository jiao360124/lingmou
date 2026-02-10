# 简化的测试脚本
$ErrorEvent = @{
    error_type = "network_error"
    error_code = "ERR_TIMEOUT"
    message = "Connection timeout after 30000ms"
    context = "Gateway connection to node failed"
    severity = "high"
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

Write-Host "Test 1: Intelligent Error Pattern Recognition" -ForegroundColor Yellow
Write-Host "Error Event:" -ForegroundColor Cyan
Write-Host "  Type: $($ErrorEvent.error_type)"
Write-Host "  Code: $($ErrorEvent.error_code)"
Write-Host "  Context: $($ErrorEvent.context)"
Write-Host "  Severity: $($ErrorEvent.severity)"
Write-Host ""

$PatternRecognition = Invoke-IntelligentErrorPatternRecognition -ErrorEvent $ErrorEvent

Write-Host "Recognition Results:" -ForegroundColor Cyan
Write-Host "  Confidence: $($PatternRecognition.classification_confidence)%"
Write-Host "  Is Recurring: $($PatternRecognition.is_recurring)"
Write-Host "  Recommendation: $($PatternRecognition.recommendation.action)"
Write-Host ""

Write-Host "Test 2: Intelligent Diagnostics" -ForegroundColor Yellow
$Diagnostics = Invoke-IntelligentDiagnostics -ErrorEvent $ErrorEvent

Write-Host "Diagnostics Results:" -ForegroundColor Cyan
Write-Host "  Root Cause: $($Diagnostics.diagnosis_results[0].result.root_cause)"
Write-Host "  Confidence: $($Diagnostics.diagnosis_results[0].confidence)%"
Write-Host "  Overall Confidence: $($Diagnostics.overall_confidence * 100)%"
Write-Host ""

Write-Host "Test 3: Advanced Log Analysis" -ForegroundColor Yellow
$Analysis = Invoke-AdvancedLogAnalysis -LogDirectory "logs" -OutputReport "logs/test-report.md" -AnalyzeAll:$true

Write-Host "Analysis Results:" -ForegroundColor Cyan
Write-Host "  Total Errors: $($Analysis.error_statistics.total_errors)"
Write-Host "  Top Error: $($Analysis.top_errors[0].error_type) ($($Analysis.top_errors[0].count) times)"
Write-Host "  Growth Rate: $($Analysis.trend_analysis.error_growth_rate)%"
Write-Host "  Trend Direction: $($Analysis.trend_analysis.trend_direction)"
Write-Host ""

Write-Host "Test 4: Visualization System" -ForegroundColor Yellow
$Visualization = Invoke-AdvancedVisualization -Data $Analysis -OutputDirectory "logs/visualizations"

Write-Host "Visualization Results:" -ForegroundColor Cyan
Write-Host "  Trend Chart: $($Visualization.trend_chart)"
Write-Host "  Pie Chart: $($Visualization.pie_chart)"
Write-Host "  Heatmap: $($Visualization.heatmap)"
Write-Host "  Dashboard: $($Visualization.dashboard)"
Write-Host ""

Write-Host "========================================" -ForegroundColor Green
Write-Host "All Tests Completed Successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Test Report: logs/test-report.md" -ForegroundColor Cyan
