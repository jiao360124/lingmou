# 实际使用示例

**灵眸系统实际应用场景**
**版本**: 1.0.0
**更新日期**: 2026-02-11

---

## 📚 目录

1. [日常运维](#日常运维)
2. [性能优化](#性能优化)
3. [故障处理](#故障处理)
4. [自动化场景](#自动化场景)
5. [高级功能](#高级功能)

---

## 日常运维

### 示例1: 每日健康检查

**场景**: 每天早上8点检查系统状态

**脚本**:
```powershell
# daily-health-check.ps1
$CheckTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Host "=== System Health Check ===" -ForegroundColor Green
Write-Host "Time: $CheckTime"
Write-Host ""

# 执行健康检查
& "$PSScriptRoot/scripts/simple-health-check.ps1" | ConvertFrom-Json | ConvertTo-Json -Depth 10 | Write-Host

# 记录到日志
$output = & "$PSScriptRoot/scripts/simple-health-check.ps1"
$output | Out-File -FilePath "$PSScriptRoot/logs/health-check-$(Get-Date -Format 'yyyyMMdd').log" -Append

Write-Host ""
Write-Host "✅ Health check completed" -ForegroundColor Green
```

**运行方式**:
```bash
powershell -ExecutionPolicy Bypass -File daily-health-check.ps1
```

**定时任务**:
```cron
0 8 * * * powershell -ExecutionPolicy Bypass -File daily-health-check.ps1
```

---

### 示例2: 每周系统报告

**场景**: 每周日生成系统运行报告

**脚本**:
```powershell
# weekly-report.ps1
$Date = Get-Date -Format "yyyy-MM-dd"
$ReportPath = "$PSScriptRoot/reports/weekly-$Date.md"

Write-Host "=== Generating Weekly Report ===" -ForegroundColor Green
Write-Host "Date: $Date"
Write-Host ""

# 生成报告内容
$Report = @"
# Weekly System Report

## System Overview
- **Date**: $Date
- **Status**: $(Get-Content "$PSScriptRoot/logs/health-check-$Date.log" -Raw)

## Performance Metrics
- **Gateway Status**: $(Get-Content "$PSScriptRoot/logs/health-check-$Date.log" | ConvertFrom-Json).checks.Gateway.status
- **Memory Usage**: $(Get-Content "$PSScriptRoot/logs/health-check-$Date.log" | ConvertFrom-Json).checks.Memory.usage
- **Disk Usage**: $(Get-Content "$PSScriptRoot/logs/health-check-$Date.log" | ConvertFrom-Json).checks.Disk.usage

## Errors Found
$(Get-Content "$PSScriptRoot/logs/nightly-evolution-$Date.json" | ConvertFrom-Json | Select-Object -ExpandProperty errors)

## Next Steps
- Review error patterns
- Optimize performance bottlenecks
- Update documentation if needed
"@

# 保存报告
$Report | Out-File -FilePath $ReportPath -Encoding UTF8
Write-Host "✅ Report saved to: $ReportPath"
```

**运行方式**:
```bash
powershell -ExecutionPolicy Bypass -File weekly-report.ps1
```

**定时任务**:
```cron
0 0 * * 0 powershell -ExecutionPolicy Bypass -File weekly-report.ps1
```

---

## 性能优化

### 示例3: 批量清理旧文件

**场景**: 清理30天前的临时文件和日志

**脚本**:
```powershell
# cleanup-old-files.ps1
$DaysAgo = 30
$CutoffDate = (Get-Date).AddDays(-$DaysAgo)
$Count = 0

Write-Host "=== Cleaning up files older than $DaysAgo days ===" -ForegroundColor Green

# 清理临时脚本
$TempScripts = Get-ChildItem -Path "$PSScriptRoot" -Filter "temp-*.ps1"
foreach ($File in $TempScripts) {
    if ($File.LastWriteTime -lt $CutoffDate) {
        Remove-Item $File.FullName -Force
        Write-Host "✅ Removed: $($File.Name)" -ForegroundColor Cyan
        $Count++
    }
}

# 清理会话缓存
$SessionCache = Get-ChildItem -Path "$PSScriptRoot\.session" -Recurse -ErrorAction SilentlyContinue
foreach ($File in $SessionCache) {
    if ($File.LastWriteTime -lt $CutoffDate) {
        Remove-Item $File.FullName -Recurse -Force
        Write-Host "✅ Removed: $($File.FullName)" -ForegroundColor Cyan
        $Count++
    }
}

# 清理旧日志
$OldLogs = Get-ChildItem -Path "$PSScriptRoot/logs" -Filter "*.log"
foreach ($File in $OldLogs) {
    if ($File.LastWriteTime -lt $CutoffDate) {
        Remove-Item $File.FullName -Force
        Write-Host "✅ Removed: $($File.Name)" -ForegroundColor Cyan
        $Count++
    }
}

Write-Host ""
Write-Host "✅ Cleanup completed: $Count files removed" -ForegroundColor Green
Write-Host "Freespace: $(Get-DiskUsage $PSScriptRoot | Select-Object -ExpandProperty Free)" -ForegroundColor Yellow
```

**运行方式**:
```bash
powershell -ExecutionPolicy Bypass -File cleanup-old-files.ps1
```

---

### 示例4: 性能基准测试对比

**场景**: 对比优化前后的性能

**脚本**:
```powershell
# performance-compare.ps1
$TestName = "PowerShell-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

Write-Host "=== Performance Comparison Test ===" -ForegroundColor Green
Write-Host "Test Name: $TestName"
Write-Host ""

# 运行优化前测试
Write-Host "Running baseline test..." -ForegroundColor Cyan
& "$PSScriptRoot/scripts/performance-benchmark.ps1" -TestName "baseline" | Out-Null
$BaselineResult = Get-Content "$PSScriptRoot/reports/performance-benchmark-baseline.json" | ConvertFrom-Json
Write-Host "✅ Baseline test completed" -ForegroundColor Green

Start-Sleep -Seconds 2

# 运行优化后测试
Write-Host "Running optimized test..." -ForegroundColor Cyan
& "$PSScriptRoot/scripts/performance-benchmark.ps1" -TestName "optimized" | Out-Null
$OptimizedResult = Get-Content "$PSScriptRoot/reports/performance-benchmark-optimized.json" | ConvertFrom-Json
Write-Host "✅ Optimized test completed" -ForegroundColor Green

Write-Host ""
Write-Host "=== Comparison Results ===" -ForegroundColor Green
Write-Host "Response Time (ms):"
Write-Host "  Baseline:  $($BaselineResult.response_time)"
Write-Host "  Optimized: $($OptimizedResult.response_time)"
Write-Host "  Improvement: $($BaselineResult.response_time - $OptimizedResult.response_time)ms ($((($BaselineResult.response_time - $OptimizedResult.response_time) / $BaselineResult.response_time * 100).ToString('F2'))%)"
Write-Host ""

# 保存结果
$Report = @"
# Performance Comparison Report

## Test Information
- **Test Name**: $TestName
- **Date**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Results

| Metric | Baseline | Optimized | Improvement |
|--------|----------|-----------|-------------|
| Response Time | $($BaselineResult.response_time)ms | $($OptimizedResult.response_time)ms | $($BaselineResult.response_time - $OptimizedResult.response_time)ms ($((($BaselineResult.response_time - $OptimizedResult.response_time) / $BaselineResult.response_time * 100).ToString('F2'))%) |
| Memory Usage | $($BaselineResult.memory_usage)MB | $($OptimizedResult.memory_usage)MB | $($BaselineResult.memory_usage - $OptimizedResult.memory_usage)MB |
"@

$Report | Out-File -FilePath "$PSScriptRoot/reports/performance-compare-$TestName.md" -Encoding UTF8
Write-Host "✅ Report saved: reports/performance-compare-$TestName.md" -ForegroundColor Yellow
```

**运行方式**:
```bash
powershell -ExecutionPolicy Bypass -File performance-compare.ps1
```

---

## 故障处理

### 示例5: 自动错误报告

**场景**: 检测到错误后自动发送通知

**脚本**:
```powershell
# error-report.ps1
$Date = Get-Date -Format "yyyy-MM-dd"
$LogFile = "$PSScriptRoot/logs/nightly-evolution-$Date.json"

# 检查是否有错误
$Errors = Get-Content $LogFile | ConvertFrom-Json | Select-Object -ExpandProperty errors

if ($Errors -and $Errors.Count -gt 0) {
    Write-Host "⚠️  Errors detected: $($Errors.Count)" -ForegroundColor Red

    # 生成错误报告
    $Report = @"
# Error Report - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Total Errors
$($Errors.Count)

## Error Details
$(foreach ($Error in $Errors) {
    "### $($Error.type)
- **Message**: $($Error.message)
- **Time**: $($Error.time)
- **Count**: $($Error.count)
"
})"@

    # 发送通知（示例 - 需要配置）
    # $Report | Send-Notification -Method Telegram -Channel @AE8F88

    # 保存报告
    $Report | Out-File -FilePath "$PSScriptRoot/reports/error-report-$Date.md" -Encoding UTF8

    Write-Host "✅ Error report saved" -ForegroundColor Green
} else {
    Write-Host "✅ No errors detected" -ForegroundColor Green
}
```

**运行方式**:
```bash
powershell -ExecutionPolicy Bypass -File error-report.ps1
```

---

## 自动化场景

### 示例6: 完整的自动化工作流

**场景**: 早上8点执行完整检查流程

**脚本**:
```powershell
# full-automation-workflow.ps1
$WorkflowName = "Morning-Workflow-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$StartTime = Get-Date

Write-Host "=== $WorkflowName ===" -ForegroundColor Green
Write-Host "Start Time: $StartTime"
Write-Host ""

# 1. 系统健康检查
Write-Host "Step 1: System Health Check" -ForegroundColor Cyan
$HealthResult = & "$PSScriptRoot/scripts/simple-health-check.ps1"
Write-Host "✅ Step 1 completed" -ForegroundColor Green

Start-Sleep -Seconds 2

# 2. 性能检查
Write-Host "Step 2: Performance Check" -ForegroundColor Cyan
& "$PSScriptRoot/scripts/performance-benchmark.ps1" | Out-Null
Write-Host "✅ Step 2 completed" -ForegroundColor Green

Start-Sleep -Seconds 2

# 3. 错误分析
Write-Host "Step 3: Error Analysis" -ForegroundColor Cyan
& "$PSScriptRoot/scripts/analyze-errors.ps1" | Out-Null
Write-Host "✅ Step 3 completed" -ForegroundColor Green

Start-Sleep -Seconds 2

# 4. 日志清理
Write-Host "Step 4: Log Cleanup" -ForegroundColor Cyan
& "$PSScriptRoot/scripts/cleanup-logs.ps1" | Out-Null
Write-Host "✅ Step 4 completed" -ForegroundColor Green

Start-Sleep -Seconds 2

# 5. 生成报告
Write-Host "Step 5: Generate Report" -ForegroundColor Cyan
$EndTime = Get-Date
$Duration = ($EndTime - $StartTime).TotalSeconds

$Report = @"
# $WorkflowName

## Workflow Information
- **Name**: $WorkflowName
- **Start Time**: $StartTime
- **End Time**: $EndTime
- **Duration**: $Duration seconds

## Results

### Health Check
$(Write-Output $HealthResult | ConvertFrom-Json | ConvertTo-Json -Depth 10)

### Performance
- See performance-benchmark-*.json

### Errors
- See error-database.json

### Logs
- All logs available in logs/ directory
"@

$Report | Out-File -FilePath "$PSScriptRoot/reports/$WorkflowName.md" -Encoding UTF8
Write-Host "✅ Report saved: reports/$WorkflowName.md" -ForegroundColor Yellow

Write-Host ""
Write-Host "=== Workflow Completed ===" -ForegroundColor Green
Write-Host "Duration: $Duration seconds" -ForegroundColor Yellow
```

**运行方式**:
```bash
powershell -ExecutionPolicy Bypass -File full-automation-workflow.ps1
```

**定时任务**:
```cron
0 8 * * * powershell -ExecutionPolicy Bypass -File full-automation-workflow.ps1
```

---

## 高级功能

### 示例7: 跨模块协作

**场景**: 结合技能集成和自动化工作流

**脚本**:
```powershell
# cross-module-collaboration.ps1
Write-Host "=== Cross-Module Collaboration ===" -ForegroundColor Green
Write-Host ""

# 1. 启动健康检查模块
Write-Host "Starting Health Check Module..." -ForegroundColor Cyan
$HealthCheck = & "$PSScriptRoot/scripts/simple-health-check.ps1" | ConvertFrom-Json
Write-Host "✅ Health Check completed" -ForegroundColor Green

# 2. 根据健康状态执行不同操作
if ($HealthCheck.status -eq "OK") {
    Write-Host "System is healthy. Running optimization..." -ForegroundColor Green

    # 运行性能优化
    & "$PSScriptRoot/scripts/performance-benchmark.ps1" -Optimize | Out-Null
    Write-Host "✅ Optimization completed" -ForegroundColor Green

    # 运行备份
    & "$PSScriptRoot/scripts/daily-backup.ps1" | Out-Null
    Write-Host "✅ Backup completed" -ForegroundColor Green

} else {
    Write-Host "⚠️  System has issues. Checking errors..." -ForegroundColor Red

    # 检查错误
    $Errors = Get-Content "$PSScriptRoot/logs/nightly-evolution-$(Get-Date -Format 'yyyyMMdd').json" | ConvertFrom-Json | Select-Object -ExpandProperty errors

    if ($Errors.Count -gt 0) {
        Write-Host "✅ Errors detected: $($Errors.Count)" -ForegroundColor Red
        Write-Host "Errors:" -ForegroundColor Yellow
        foreach ($Error in $Errors) {
            Write-Host "  - $($Error.type): $($Error.message)" -ForegroundColor Yellow
        }

        # 尝试自动修复
        Write-Host "Attempting auto-repair..." -ForegroundColor Cyan
        & "$PSScriptRoot/scripts/nightly-evolution.ps1" -Repair | Out-Null
        Write-Host "✅ Auto-repair completed" -ForegroundColor Green
    }
}

# 3. 技能集成 - 代码审查
Write-Host ""
Write-Host "Running Code Review Skill..." -ForegroundColor Cyan
& "$PSScriptRoot/scripts/skill-integration/code-mentor-integration.ps1" -Review $PSScriptRoot | Out-Null
Write-Host "✅ Code Review completed" -ForegroundColor Green

Write-Host ""
Write-Host "=== Collaboration Completed ===" -ForegroundColor Green
```

**运行方式**:
```bash
powershell -ExecutionPolicy Bypass -File cross-module-collaboration.ps1
```

---

### 示例8: 条件触发自动化

**场景**: 当磁盘使用超过85%时自动执行清理

**脚本**:
```powershell
# disk-triggered-cleanup.ps1
Write-Host "=== Disk Triggered Cleanup ===" -ForegroundColor Green
Write-Host ""

# 获取磁盘使用情况
$DiskInfo = Get-PSDrive C
$UsagePercent = [math]::Round(($DiskInfo.Used / $DiskInfo.Free) * 100, 2)

Write-Host "Disk Usage: $UsagePercent%" -ForegroundColor Cyan

# 检查是否超过阈值
if ($UsagePercent -gt 85) {
    Write-Host "⚠️  Disk usage exceeds 85% threshold!" -ForegroundColor Red

    # 执行清理
    Write-Host "Starting cleanup..." -ForegroundColor Yellow
    & "$PSScriptRoot/scripts/cleanup-logs.ps1" | Out-Null
    & "$PSScriptRoot/scripts/cleanup-old-files.ps1" | Out-Null

    # 检查清理结果
    $DiskInfo = Get-PSDrive C
    $NewUsage = [math]::Round(($DiskInfo.Used / $DiskInfo.Free) * 100, 2)

    Write-Host ""
    Write-Host "After Cleanup:" -ForegroundColor Green
    Write-Host "Disk Usage: $NewUsage%" -ForegroundColor Cyan

    if ($NewUsage -le 85) {
        Write-Host "✅ Cleanup successful. Usage below 85%." -ForegroundColor Green
    } else {
        Write-Host "⚠️  Cleanup did not reduce usage enough." -ForegroundColor Red
    }

} else {
    Write-Host "✅ Disk usage is healthy (< 85%). No action needed." -ForegroundColor Green
}
```

**运行方式**:
```bash
powershell -ExecutionPolicy Bypass -File disk-triggered-cleanup.ps1
```

**定时任务**:
```cron
*/30 * * * * powershell -ExecutionPolicy Bypass -File disk-triggered-cleanup.ps1
```

---

## 📖 下一步

更多示例请参考：
- **教程**: [TUTORIALS.md](TUTORIALS.md)
- **API文档**: [API_DOCUMENTATION.md](API_DOCUMENTATION.md)
- **部署指南**: [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

---

**示例版本**: 1.0.0
**最后更新**: 2026-02-11
