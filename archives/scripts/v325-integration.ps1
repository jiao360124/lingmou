# OpenClaw 灵眸 v3.2.5 整合脚本
# 整合所有新开发的 v3.3 核心模块到 v3.2.5

param(
    [switch]$Force = $false
)

$ErrorActionPreference = "Stop"
$workspace = "C:\Users\Administrator\.openclaw\workspace"
$backupDir = "$workspace\backup\v325-integration-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$version = "v3.2.5"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  灵眸 v3.2.5 整合开始" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan
Write-Host "时间: $timestamp" -ForegroundColor Gray
Write-Host "工作目录: $workspace" -ForegroundColor Gray
Write-Host "备份目录: $backupDir" -ForegroundColor Gray

# ==================== 第1步：创建备份 ====================
Write-Host "`n[1/6] 创建备份..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
New-Item -ItemType Directory -Path "$backupDir\backup-core" -Force | Out-Null
New-Item -ItemType Directory -Path "$backupDir\backup-utils" -Force | Out-Null
New-Item -ItemType Directory -Path "$backupDir\backup-economy" -Force | Out-Null
New-Item -ItemType Directory -Path "$backupDir\backup-metrics" -Force | Out-Null

# 备份核心模块
if (Test-Path "$workspace\core") {
    Copy-Item -Path "$workspace\core" -Destination "$backupDir\backup-core" -Recurse -Force
}

# 备份工具模块
if (Test-Path "$workspace\utils") {
    Copy-Item -Path "$workspace\utils" -Destination "$backupDir\backup-utils" -Recurse -Force
}

# 备份经济模块
if (Test-Path "$workspace\economy") {
    Copy-Item -Path "$workspace\economy" -Destination "$backupDir\backup-economy" -Recurse -Force
}

# 备份指标模块
if (Test-Path "$workspace\metrics") {
    Copy-Item -Path "$workspace\metrics" -Destination "$backupDir\backup-metrics" -Recurse -Force
}

Write-Host "✓ 备份完成" -ForegroundColor Green

# ==================== 第2步：扫描所有模块 ====================
Write-Host "`n[2/6] 扫描所有模块..." -ForegroundColor Yellow

$coreModules = @()
Get-ChildItem -Path "$workspace\core" -Filter "*.js" | ForEach-Object {
    $coreModules += [PSCustomObject]@{
        Name = $_.Name
        Size = $_.Length
        Modified = $_.LastWriteTime
    }
}

$utilsModules = @()
Get-ChildItem -Path "$workspace\utils" -Filter "*.js" | ForEach-Object {
    $utilsModules += [PSCustomObject]@{
        Name = $_.Name
        Size = $_.Length
        Modified = $_.LastWriteTime
    }
}

$economyModules = @()
if (Test-Path "$workspace\economy") {
    Get-ChildItem -Path "$workspace\economy" -Filter "*.js" | ForEach-Object {
        $economyModules += [PSCustomObject]@{
            Name = $_.Name
            Size = $_.Length
            Modified = $_.LastWriteTime
        }
    }
}

$metricsModules = @()
if (Test-Path "$workspace\metrics") {
    Get-ChildItem -Path "$workspace\metrics" -Filter "*.js" | ForEach-Object {
        $metricsModules += [PSCustomObject]@{
            Name = $_.Name
            Size = $_.Length
            Modified = $_.LastWriteTime
        }
    }
}

Write-Host "  核心模块: $($coreModules.Count) 个" -ForegroundColor White
Write-Host "  工具模块: $($utilsModules.Count) 个" -ForegroundColor White
Write-Host "  经济模块: $($economyModules.Count) 个" -ForegroundColor White
Write-Host "  指标模块: $($metricsModules.Count) 个" -ForegroundColor White
Write-Host "✓ 扫描完成" -ForegroundColor Green

# ==================== 第3步：验证模块完整性 ====================
Write-Host "`n[3/6] 验证模块完整性..." -ForegroundColor Yellow

$v33CoreModules = @(
    "adversary-simulator.js",
    "api-tracker.js",
    "benefit-calculator.js",
    "cost-calculator.js",
    "multi-perspective-evaluator.js",
    "risk-adjusted-scorer.js",
    "risk-assessor.js",
    "risk-controller.js",
    "roi-analyzer.js",
    "scenario-evaluator.js",
    "scenario-generator.js",
    "strategy-engine-enhanced.js",
    "watchdog.js",
    "rollback-engine.js",
    "performance-monitor.js",
    "nightly-worker.js",
    "memory-monitor.js"
)

$v33UtilsModules = @(
    "session-compressor.js"
)

$v33EconomyModules = @(
    "token-governor.js"
)

$v33MetricsModules = @(
    "tracker.js"
)

$allValid = $true

Write-Host "`n  核心模块验证:" -ForegroundColor Cyan
foreach ($module in $v33CoreModules) {
    $path = "$workspace\core\$module"
    if (Test-Path $path) {
        $size = (Get-Item $path).Length
        $sizeStr = "$size bytes"
        Write-Host "    [OK] $module ($sizeStr)" -ForegroundColor Green
    } else {
        Write-Host "    [MISSING] $module" -ForegroundColor Red
        $allValid = $false
    }
}

Write-Host "`n  工具模块验证:" -ForegroundColor Cyan
foreach ($module in $v33UtilsModules) {
    $path = "$workspace\utils\$module"
    if (Test-Path $path) {
        $size = (Get-Item $path).Length
        $sizeStr = "$size bytes"
        Write-Host "    [OK] $module ($sizeStr)" -ForegroundColor Green
    } else {
        Write-Host "    [MISSING] $module" -ForegroundColor Red
        $allValid = $false
    }
}

Write-Host "`n  经济模块验证:" -ForegroundColor Cyan
foreach ($module in $v33EconomyModules) {
    $path = "$workspace\economy\$module"
    if (Test-Path $path) {
        $size = (Get-Item $path).Length
        $sizeStr = "$size bytes"
        Write-Host "    [OK] $module ($sizeStr)" -ForegroundColor Green
    } else {
        Write-Host "    [MISSING] $module" -ForegroundColor Red
        $allValid = $false
    }
}

Write-Host "`n  指标模块验证:" -ForegroundColor Cyan
foreach ($module in $v33MetricsModules) {
    $path = "$workspace\metrics\$module"
    if (Test-Path $path) {
        $size = (Get-Item $path).Length
        $sizeStr = "$size bytes"
        Write-Host "    [OK] $module ($sizeStr)" -ForegroundColor Green
    } else {
        Write-Host "    [MISSING] $module" -ForegroundColor Red
        $allValid = $false
    }
}

if (-not $allValid) {
    Write-Host "`n✗ 模块验证失败！请检查缺失的模块。" -ForegroundColor Red
    exit 1
}

Write-Host "`n✓ 所有模块验证通过" -ForegroundColor Green

# ==================== 第4步：创建版本配置 ====================
Write-Host "`n[4/6] 创建版本配置..." -ForegroundColor Yellow

$configContent = @"
{
  "version": "$version",
  "releaseDate": "$timestamp",
  "description": "灵眸 v3.2.5 - v3.3 核心模块整合版本",
  "modules": {
    "core": {
      "count": $($coreModules.Count),
      "modules": $($coreModules | ConvertTo-Json -Compress)
    },
    "utils": {
      "count": $($utilsModules.Count),
      "modules": $($utilsModules | ConvertTo-Json -Compress)
    },
    "economy": {
      "count": $($economyModules.Count),
      "modules": $($economyModules | ConvertTo-Json -Compress)
    },
    "metrics": {
      "count": $($metricsModules.Count),
      "modules": $($metricsModules | ConvertTo-Json -Compress)
    }
  },
  "features": [
    "v3.3 Phase 3.3-1: 策略引擎增强",
    "场景模拟器（Scenario Simulator）",
    "成本收益评分器（Cost-Benefit Scorer）",
    "风险权重模型（Risk Weight Model）",
    "自我博弈机制（Self-Play Mechanism）",
    "多视角评估器（Multi-Perspective Evaluator）",
    "对抗模拟器（Adversary Simulator）",
    "会话压缩器（Session Compressor）",
    "代币治理器（Token Governor）",
    "性能监控器（Performance Monitor）",
    "夜间工作者（Nightly Worker）",
    "看门狗（Watchdog）",
    "回滚引擎（Rollback Engine）",
    "架构审计器（Architecture Auditor）",
    "统一索引（Unified Index）"
  ],
  "integration": {
    "baseVersion": "v3.2",
    "fromVersion": "v3.3-phase1",
    "type": "partial"
  },
  "testing": {
    "status": "pending",
    "coverage": "pending"
  }
}
"@

$configPath = "$workspace\core\version-$version.json"
$configContent | Out-File -FilePath $configPath -Encoding UTF8

Write-Host "✓ 版本配置已创建: version-$version.json" -ForegroundColor Green

# ==================== 第5步：生成整合报告 ====================
Write-Host "`n[5/6] 生成整合报告..." -ForegroundColor Yellow

$reportPath = "$workspace\reports\v325-integration-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"

$reportContent = @"
========================================
灵眸 v3.2.5 整合报告
========================================

时间: $timestamp
版本: $version
类型: v3.3 核心模块整合

========================================
模块统计
========================================

核心模块: $($coreModules.Count) 个
$(($coreModules | Format-Table Name, Size, Modified -AutoSize | Out-String).Trim())

工具模块: $($utilsModules.Count) 个
$(($utilsModules | Format-Table Name, Size, Modified -AutoSize | Out-String).Trim())

经济模块: $($economyModules.Count) 个
$(($economyModules | Format-Table Name, Size, Modified -AutoSize | Out-String).Trim())

指标模块: $($metricsModules.Count) 个
$(($metricsModules | Format-Table Name, Size, Modified -AutoSize | Out-String).Trim())

========================================
新增功能（v3.3 Phase 3.3-1）
========================================

策略引擎增强:
  • 场景模拟器（scenario-generator.js + scenario-evaluator.js）
  • 成本收益评分器（cost-calculator.js + benefit-calculator.js + roi-analyzer.js）
  • 风险权重模型（risk-assessor.js + risk-controller.js + risk-adjusted-scorer.js）
  • 自我博弈机制（adversary-simulator.js + multi-perspective-evaluator.js）
  • 增强策略引擎（strategy-engine-enhanced.js）

监控与优化:
  • 性能监控器（performance-monitor.js）
  • 夜间工作者（nightly-worker.js）
  • 记忆监控器（memory-monitor.js）
  • 看门狗（watchdog.js）

系统增强:
  • 回滚引擎（rollback-engine.js）
  • 统一索引（unified-index.js）
  • 架构审计器（architecture-auditor.js）
  • API 追踪器（api-tracker.js）

经济系统:
  • 代币治理器（economy/token-governor.js）

指标追踪:
  • 追踪器（metrics/tracker.js）
  • 仪表板数据（metrics/dashboard-data.json）

工具模块:
  • 会话压缩器（utils/session-compressor.js）

========================================
文件大小统计
========================================

核心模块总大小: $((($coreModules | Measure-Object -Property Size -Sum).Sum / 1KB).ToString('F2')) KB
工具模块总大小: $((($utilsModules | Measure-Object -Property Size -Sum).Sum / 1KB).ToString('F2')) KB
经济模块总大小: $((($economyModules | Measure-Object -Property Size -Sum).Sum / 1KB).ToString('F2')) KB
指标模块总大小: $((($metricsModules | Measure-Object -Property Size -Sum).Sum / 1KB).ToString('F2')) KB
总大小: $(((($coreModules | Measure-Object -Property Size -Sum).Sum + ($utilsModules | Measure-Object -Property Size -Sum).Sum + ($economyModules | Measure-Object -Property Size -Sum).Sum + ($metricsModules | Measure-Object -Property Size -Sum).Sum) / 1KB).ToString('F2')) KB

========================================
整合说明
========================================

基座版本: v3.2
整合来源: v3.3 Phase 3.3-1
整合类型: 部分整合（仅整合策略引擎增强模块）

未整合部分（待 v3.3 完成）:
  • Phase 3.3-2: 认知层深化
  • Phase 3.3-3: 架构自审完善
  • Phase 3.3-4: 集成与测试

========================================
下一步行动
========================================

1. 测试所有核心模块
2. 验证模块间的依赖关系
3. 更新文档（v3.2.5-README.md）
4. Git 提交更改
5. 推送到远程仓库

========================================
备份信息
========================================

备份目录: $backupDir
备份内容:
  • backup-core/ - 完整核心模块
  • backup-utils/ - 完整工具模块
  • backup-economy/ - 完整经济模块
  • backup-metrics/ - 完整指标模块

回滚命令:
  Copy-Item -Path "$backupDir\backup-core" -Destination "core" -Recurse -Force
  Copy-Item -Path "$backupDir\backup-utils" -Destination "utils" -Recurse -Force
  Copy-Item -Path "$backupDir\backup-economy" -Destination "economy" -Recurse -Force
  Copy-Item -Path "$backupDir\backup-metrics" -Destination "metrics" -Recurse -Force

========================================
报告生成时间: $timestamp
========================================
"@

$reportContent | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "✓ 整合报告已生成: $reportPath" -ForegroundColor Green

# ==================== 第6步：创建 Git 提交信息 ====================
Write-Host "`n[6/6] 准备 Git 提交..." -ForegroundColor Yellow

$commitMsgPath = "$workspace\scripts\commit-v325.txt"

$commitMessage = @"
feat: 灵眸 v3.2.5 - v3.3 核心模块整合

## 版本信息
- 版本: v3.2.5
- 时间: $timestamp
- 类型: 部分整合（v3.3 Phase 3.3-1）

## 新增功能

### 策略引擎增强（v3.3 Phase 3.3-1）
- 场景模拟器（scenario-generator.js, scenario-evaluator.js）
- 成本收益评分器（cost-calculator.js, benefit-calculator.js, roi-analyzer.js）
- 风险权重模型（risk-assessor.js, risk-controller.js, risk-adjusted-scorer.js）
- 自我博弈机制（adversary-simulator.js, multi-perspective-evaluator.js）
- 增强策略引擎（strategy-engine-enhanced.js）

### 监控与优化
- 性能监控器（performance-monitor.js）
- 夜间工作者（nightly-worker.js）
- 记忆监控器（memory-monitor.js）
- 看门狗（watchdog.js）

### 系统增强
- 回滚引擎（rollback-engine.js）
- 统一索引（unified-index.js）
- 架构审计器（architecture-auditor.js）
- API 追踪器（api-tracker.js）

### 经济系统
- 代币治理器（economy/token-governor.js）

### 指标追踪
- 追踪器（metrics/tracker.js）
- 仪表板数据（metrics/dashboard-data.json）

### 工具模块
- 会话压缩器（utils/session-compressor.js）

## 模块统计
- 核心模块: $($coreModules.Count) 个
- 工具模块: $($utilsModules.Count) 个
- 经济模块: $($economyModules.Count) 个
- 指标模块: $($metricsModules.Count) 个

## 整合说明
- 基座版本: v3.2
- 整合来源: v3.3 Phase 3.3-1
- 整合类型: 部分整合

## 备份信息
- 备份目录: $backupDir

## 下一步
- 测试所有核心模块
- 验证模块间的依赖关系
- 更新文档（v3.2.5-README.md）
- Git 提交更改

See reports/ and scripts/ for details.
"@

$commitMessage | Out-File -FilePath $commitMsgPath -Encoding UTF8

Write-Host "✓ Git 提交信息已准备: $commitMsgPath" -ForegroundColor Green

# ==================== 完成 ====================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  灵眸 v3.2.5 整合完成" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan
Write-Host "版本: $version" -ForegroundColor Green
Write-Host "备份目录: $backupDir" -ForegroundColor Green
Write-Host "整合报告: $reportPath" -ForegroundColor Green
Write-Host "Git 提交信息: $commitMsgPath" -ForegroundColor Green

Write-Host "`n📊 统计信息:" -ForegroundColor Yellow
Write-Host "  核心模块: $($coreModules.Count) 个" -ForegroundColor White
Write-Host "  工具模块: $($utilsModules.Count) 个" -ForegroundColor White
Write-Host "  经济模块: $($economyModules.Count) 个" -ForegroundColor White
Write-Host "  指标模块: $($metricsModules.Count) 个" -ForegroundColor White

Write-Host "`n✅ 下一步:" -ForegroundColor Cyan
Write-Host "  1. 查看整合报告: $reportPath" -ForegroundColor White
Write-Host "  2. 提交 Git 更改: git commit -F scripts/commit-v325.txt" -ForegroundColor White
Write-Host "  3. 推送到远程仓库: git push" -ForegroundColor White

Write-Host "`n" -ForegroundColor White
