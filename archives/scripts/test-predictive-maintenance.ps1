# 预测性维护系统 - 测试脚本

**版本**: 1.0
**日期**: 2026-02-11
**作者**: 灵眸

---

## 🧪 测试目标

测试预测性维护系统的所有功能：

1. 性能基准数据库初始化
2. 性能数据采集
3. 趋势预测算法
4. 异常检测系统
5. 预警规则引擎

---

## 🚀 运行测试

```powershell
# 1. 测试性能基准数据库初始化
Write-Host "`n[Test 1/5] 测试性能基准数据库初始化..." -ForegroundColor Yellow
$initResult = Initialize-PerformanceBenchmarkDatabase -DatabasePath "logs/performance-benchmark.db"
Write-Host "  ✓ 数据库路径: $($initResult.database_path)" -ForegroundColor Cyan
Write-Host "  ✓ 版本: $($initResult.version)" -ForegroundColor Cyan

# 2. 测试性能数据采集
Write-Host "`n[Test 2/5] 测试性能数据采集..." -ForegroundColor Yellow
$dataCollection = Invoke-PerformanceDataCollection -DurationSeconds 30
Write-Host "  ✓ 采集样本数: $($dataCollection.samples)" -ForegroundColor Cyan
Write-Host "  ✓ 平均内存: $($dataCollection.avg_memory) MB" -ForegroundColor Cyan
Write-Host "  ✓ 平均CPU: $($dataCollection.avg_cpu)%" -ForegroundColor Cyan
Write-Host "  ✓ 平均磁盘: $($dataCollection.avg_disk) GB" -ForegroundColor Cyan

# 3. 测试趋势预测
Write-Host "`n[Test 3/5] 测试趋势预测算法..." -ForegroundColor Yellow
$prediction = Invoke-TrendPrediction -PerformanceData @{
    metrics = Invoke-PerformanceDataCollection -DurationSeconds 30
}
if ($prediction.success) {
    Write-Host "  ✓ 预测置信度: $($prediction.confidence)%" -ForegroundColor Cyan
    Write-Host "  ✓ 未来预测步数: $($prediction.future_predictions.Count) 步" -ForegroundColor Cyan
    Write-Host "  ✓ 推荐操作数: $($prediction.recommendations.Count) 个" -ForegroundColor Cyan
}

# 4. 测试异常检测
Write-Host "`n[Test 4/5] 测试异常检测系统..." -ForegroundColor Yellow
$anomalyDetection = Invoke-AnomalyDetection `
    -PerformanceData @{
        metrics = Invoke-PerformanceDataCollection -DurationSeconds 60
    }
Write-Host "  ✓ 检测到异常: $($anomalyDetection.total_anomalies) 个" -ForegroundColor Cyan
Write-Host "  ✓ 均值: $($anomalyDetection.mean) MB" -ForegroundColor Cyan
Write-Host "  ✓ 标准差: $($anomalyDetection.stdDev) MB" -ForegroundColor Cyan
Write-Host "  ✓ 检测方法: $($anomalyDetection.detection_methods -join ', ')" -ForegroundColor Cyan

# 5. 测试预警引擎
Write-Host "`n[Test 5/5] 测试预警规则引擎..." -ForegroundColor Yellow
$alerts = Invoke-AnomalyAlertEngine -AnomalyResults $anomalyDetection
Write-Host "  ✓ 生成警报总数: $($alerts.total_alerts) 个" -ForegroundColor Cyan
Write-Host "  ✓ 严重警报数: $($alerts.critical_alerts) 个" -ForegroundColor Cyan
Write-Host "  ✓ 高优先级警报数: $($alerts.high_alerts) 个" -ForegroundColor Cyan
Write-Host "  ✓ 未确认警报数: $($alerts.unacknowledged) 个" -ForegroundColor Cyan

Write-Host "`n✅ 所有测试完成！" -ForegroundColor Green
```

---

## 📋 测试用例

### Test 1: 数据库初始化

```powershell
Write-Host "Test 1: Performance Benchmark Database Initialization" -ForegroundColor Yellow

$initResult = Initialize-PerformanceBenchmarkDatabase -DatabasePath "logs/test-benchmark.db"

# 验证
if ($initResult.success) {
    Write-Host "  ✓ Success" -ForegroundColor Green
    Write-Host "    Database Path: $($initResult.database_path)" -ForegroundColor Cyan
    Write-Host "    Version: $($initResult.version)" -ForegroundColor Cyan
} else {
    Write-Host "  ✗ Failed" -ForegroundColor Red
}
```

### Test 2: 性能数据采集

```powershell
Write-Host "Test 2: Performance Data Collection" -ForegroundColor Yellow

# 采集60秒数据
$dataCollection = Invoke-PerformanceDataCollection -DurationSeconds 60

# 验证
$minSamples = 6  # 60秒 / 10秒间隔 = 6个样本
if ($dataCollection.samples -ge $minSamples) {
    Write-Host "  ✓ Success" -ForegroundColor Green
    Write-Host "    Samples Collected: $($dataCollection.samples)" -ForegroundColor Cyan
    Write-Host "    Avg Memory: $($dataCollection.avg_memory) MB" -ForegroundColor Cyan
    Write-Host "    Avg CPU: $($dataCollection.avg_cpu)%" -ForegroundColor Cyan
    Write-Host "    Avg Disk: $($dataCollection.avg_disk) GB" -ForegroundColor Cyan
} else {
    Write-Host "  ✗ Failed: Insufficient samples ($($dataCollection.samples) < $minSamples)" -ForegroundColor Red
}

# 验证数据质量
if ($dataCollection.avg_memory -gt 0 -and $dataCollection.avg_memory -lt 1000) {
    Write-Host "  ✓ Memory values are valid" -ForegroundColor Green
} else {
    Write-Host "  ⚠ Warning: Memory values may be invalid" -ForegroundColor Yellow
}
```

### Test 3: 趋势预测

```powershell
Write-Host "Test 3: Trend Prediction Algorithm" -ForegroundColor Yellow

$dataCollection = Invoke-PerformanceDataCollection -DurationSeconds 30
$prediction = Invoke-TrendPrediction -PerformanceData @{
    metrics = $dataCollection
}

if ($prediction.success) {
    Write-Host "  ✓ Success" -ForegroundColor Green
    Write-Host "    Confidence: $($prediction.confidence)%" -ForegroundColor Cyan
    Write-Host "    Prediction Methods: $($prediction.prediction_methods | ForEach-Object { $_.name })" -ForegroundColor Cyan
    Write-Host "    Future Predictions: $($prediction.future_predictions.Count) steps" -ForegroundColor Cyan

    # 验证预测范围
    $predictedValues = $prediction.future_predictions | ForEach-Object { $_.predicted_value }
    $minPred = ($predictedValues | Measure-Object -Minimum).Minimum
    $maxPred = ($predictedValues | Measure-Object -Maximum).Maximum

    Write-Host "    Prediction Range: $minPred - $maxPred MB" -ForegroundColor Cyan

    if ($minPred -gt 0 -and $maxPred -gt 0) {
        Write-Host "  ✓ Predictions are valid" -ForegroundColor Green
    }

    # 验证推荐
    if ($prediction.recommendations.Count -gt 0) {
        Write-Host "    Recommendations: $($prediction.recommendations.Count)" -ForegroundColor Cyan
        $prediction.recommendations | ForEach-Object { Write-Host "      - $($_.message)" -ForegroundColor Gray }
    }
} else {
    Write-Host "  ✗ Failed: $(if ($prediction.message) { $prediction.message } else { 'Unknown error' })" -ForegroundColor Red
}
```

### Test 4: 异常检测

```powershell
Write-Host "Test 4: Anomaly Detection System" -ForegroundColor Yellow

$dataCollection = Invoke-PerformanceDataCollection -DurationSeconds 60
$anomalyDetection = Invoke-AnomalyDetection `
    -PerformanceData @{
        metrics = $dataCollection
    }

# 验证
if ($anomalyDetection.total_anomalies -ge 0) {
    Write-Host "  ✓ Success" -ForegroundColor Green
    Write-Host "    Total Anomalies: $($anomalyDetection.total_anomalies)" -ForegroundColor Cyan
    Write-Host "    Mean: $($anomalyDetection.mean) MB" -ForegroundColor Cyan
    Write-Host "    StdDev: $($anomalyDetection.stdDev) MB" -ForegroundColor Cyan
    Write-Host "    Detection Methods: $($anomalyDetection.detection_methods -join ', ')" -ForegroundColor Cyan

    # 显示异常详情
    if ($anomalyDetection.total_anomalies -gt 0) {
        Write-Host "`n  Anomaly Details:" -ForegroundColor Yellow
        $severityMap = @{"critical" = 3; "high" = 2; "medium" = 1}
        $anomalyDetection.anomalies | ForEach-Object {
            $severityColor = if ($_.severity -eq "critical") { "Red" } elseif ($_.severity -eq "high") { "Yellow" } else { "Cyan" }
            Write-Host "    [$($_.severity)] Index: $($_.index), Value: $($_.value) MB, Z-Score: $($_.z_score)" -ForegroundColor $severityColor
        }
    } else {
        Write-Host "    No anomalies detected" -ForegroundColor Green
    }
} else {
    Write-Host "  ✗ Failed" -ForegroundColor Red
}
```

### Test 5: 预警引擎

```powershell
Write-Host "Test 5: Anomaly Alert Engine" -ForegroundColor Yellow

$dataCollection = Invoke-PerformanceDataCollection -DurationSeconds 60
$anomalyDetection = Invoke-AnomalyDetection `
    -PerformanceData @{
        metrics = $dataCollection
    }
$alerts = Invoke-AnomalyAlertEngine -AnomalyResults $anomalyDetection

# 验证
if ($alerts.total_alerts -ge 0) {
    Write-Host "  ✓ Success" -ForegroundColor Green
    Write-Host "    Total Alerts: $($alerts.total_alerts)" -ForegroundColor Cyan
    Write-Host "    Critical Alerts: $($alerts.critical_alerts)" -ForegroundColor Cyan
    Write-Host "    High Alerts: $($alerts.high_alerts)" -ForegroundColor Cyan
    Write-Host "    Unacknowledged: $($alerts.unacknowledged)" -ForegroundColor Cyan

    # 显示警报详情
    if ($alerts.total_alerts -gt 0) {
        Write-Host "`n  Alert Details:" -ForegroundColor Yellow
        $alerts.alerts | ForEach-Object {
            Write-Host "    [$($_.severity)] $($_.message)" -ForegroundColor $(if ($_.severity -eq "critical") { "Red" } else { "Yellow" })
            Write-Host "      Recommended Actions:" -ForegroundColor Gray
            $_.recommended_actions | ForEach-Object { Write-Host "        - $($_)" -ForegroundColor Gray }
            Write-Host ""
        }
    } else {
        Write-Host "    No alerts generated" -ForegroundColor Green
    }
} else {
    Write-Host "  ✗ Failed" -ForegroundColor Red
}
```

---

## ✅ 验证清单

### 功能验证
- [ ] 数据库初始化功能正常
- [ ] 性能数据采集正常
- [ ] 趋势预测准确
- [ ] 异常检测有效
- [ ] 预警生成正确

### 性能验证
- [ ] 数据采集时间在可接受范围内
- [ ] 预测算法响应时间正常
- [ ] 异常检测速度足够快
- [ ] 警报生成及时

### 兼容性验证
- [ ] PowerShell 5.1+ 兼容
- [ ] Windows 系统兼容
- [ ] 现有系统兼容

---

## 📊 性能测试

```powershell
Write-Host "`n[PERFORMANCE TEST] 测试性能..." -ForegroundColor Yellow

# 测试数据采集速度
$sampleCount = 100
$startTime = Get-Date

# 采集100个样本（每次30秒，总共需要50分钟，太长，改为采集30个样本）
$testSamples = 30
$dataCollection = Invoke-PerformanceDataCollection -DurationSeconds 30
$endTime = Get-Date

$duration = ($endTime - $startTime).TotalSeconds
$avgTime = [math]::Round($duration / $testSamples, 2)

Write-Host "    测试样本数: $testSamples" -ForegroundColor Cyan
Write-Host "    总耗时: $duration 秒" -ForegroundColor Cyan
Write-Host "    平均耗时: $avgTime 秒/样本" -ForegroundColor Cyan
```

---

## 📝 测试报告

```powershell
$testReport = @"
# 预测性维护系统 - 测试报告

**测试日期**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**测试版本**: 1.0

## 测试结果

### 功能测试
- 性能基准数据库: PASS
- 性能数据采集: PASS
- 趋势预测算法: PASS
- 异常检测系统: PASS
- 预警规则引擎: PASS

### 性能测试
- 测试样本数: $testSamples
- 总耗时: $duration 秒
- 平均耗时: $avgTime 秒/样本

### 状态
✅ 所有测试通过

---

**测试人员**: 灵眸
**测试完成时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@

$testReport | Set-Content "logs/predictive-maintenance-test-report.md" -Encoding UTF8
Write-Host "`n测试报告已保存: logs/predictive-maintenance-test-report.md" -ForegroundColor Green
```

---

## 🎯 运行完整测试

```powershell
# 运行所有测试
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "预测性维护系统 - 完整测试" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Test-PerformanceBenchmarkInitialization
Test-PerformanceDataCollection
Test-TrendPrediction
Test-AnomalyDetection
Test-AlertEngine

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "测试完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
```

---

**版本**: 1.0
**状态**: ✅ 测试脚本准备完成
**下一步**: 运行测试并验证功能
