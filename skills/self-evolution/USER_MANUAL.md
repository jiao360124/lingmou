# 自主学习引擎 - 用户手册

**版本**: 1.0.0
**作者**: 灵眸
**日期**: 2026-02-13
**状态**: ✅ 已完成

---

## 目录

1. [简介](#简介)
2. [系统架构](#系统架构)
3. [快速开始](#快速开始)
4. [使用指南](#使用指南)
5. [配置说明](#配置说明)
6. [最佳实践](#最佳实践)
7. [故障排除](#故障排除)
8. [常见问题](#常见问题)

---

## 简介

自主学习引擎是一个完整的3阶段自我进化系统，基于Moltbook学到的7个核心模式实现。

### 核心能力

1. **可测量可执行性** - 系统输出清晰、可验证
2. **自我评估** - 多维度分析
3. **结构化反思** - 分步骤分析
4. **持久化上下文** - 所有数据保存
5. **主动学习** - 基于实际数据
6. **持续改进** - 定期优化
7. **社区学习** - Moltbook集成

---

## 系统架构

### 3个Phase

```
Phase 1: 学习分析
   ↓
   分析系统使用数据
   识别模式和趋势
   生成改进建议
   ↓
Phase 2: 持续优化
   ↓
   定期系统检查
   生成优化方案
   自动应用改进
   效果跟踪
   ↓
Phase 3: Moltbook集成
   ↓
   数据同步
   Skill导入
   经验分享
   社区互动
```

### 核心模块

- **学习分析器** - 分析系统使用模式
- **模式识别引擎** - 识别使用和Skill模式
- **改进建议生成器** - 生成智能建议
- **定期检查器** - 系统健康检查
- **优化方案生成器** - 生成优化计划
- **自动应用引擎** - 应用优化方案
- **同步引擎** - Moltbook数据同步
- **社区互动器** - 社区互动

---

## 快速开始

### 安装

确保你已经有了OpenClaw工作空间：

```powershell
cd C:\Users\Administrator\.openclaw\workspace
```

### 基本使用

#### 运行所有Phase

```powershell
.\skills\self-evolution\main-phase2-3.ps1 -Action all
```

#### 运行单个Phase

```powershell
# Phase 1: 学习分析
.\skills\self-evolution\main.ps1 -Action all

# Phase 2: 持续优化
.\skills\self-evolution\continuous-optimizer.ps1 -Action check

# Phase 3: Moltbook集成
.\skills\self-evolution\moltbook-integrator.ps1 -Action sync
```

---

## 使用指南

### Phase 1: 学习分析

#### 1. 运行学习分析

```powershell
.\skills\self-evolution\main.ps1 -Action analyze
```

#### 2. 运行模式识别

```powershell
.\skills\self-evolution\main.ps1 -Action recognize
```

#### 3. 生成改进建议

```powershell
.\skills\self-evolution\main.ps1 -Action generate
```

#### 4. 查看报告

```powershell
# 学习日志
Get-Content skills\self-evolution\data\learning-log.md

# 模式数据库
Get-Content skills\self-evolution\data\pattern-database.json

# 改进建议
Get-Content skills\self-evolution\data\recommendations.json
```

### Phase 2: 持续优化

#### 1. 运行系统检查

```powershell
.\skills\self-evolution\continuous-optimizer.ps1 -Action check
```

输出：
- 系统健康状态
- 文件完整性检查
- 配置验证
- 问题检测

#### 2. 生成优化方案

```powershell
.\skills\self-evolution\continuous-optimizer.ps1 -Action plan
```

输出：
- 优化计划
- 优先级排序
- 时间估算
- 行动项列表

#### 3. 应用优化方案

```powershell
.\skills\self-evolution\continuous-optimizer.ps1 -Action apply
```

功能：
- 自动应用优化方案
- 状态跟踪
- 进度报告

#### 4. 跟踪优化效果

```powershell
.\skills\self-evolution\continuous-optimizer.ps1 -Action track
```

输出：
- 执行进度跟踪
- 完成状态报告
- 待办事项管理

### Phase 3: Moltbook集成

#### 1. 同步数据到Moltbook

```powershell
.\skills\self-evolution\moltbook-integrator.ps1 -Action sync
```

功能：
- 本地数据同步
- 远程数据获取
- 变更检测
- 自动同步

输出：
- 同步报告
- 每日活动统计
- 建议

#### 2. 导入Skills

```powershell
.\skills\self-evolution\moltbook-integrator.ps1 -Action import
```

功能：
- API认证
- Skill导入
- 元数据管理

#### 3. 分享成就

```powershell
.\skills\self-evolution\moltbook-integrator.ps1 -Action share
```

功能：
- 成就分享
- 经验记录
- 社交互动

输出：
- 分享的成就列表

#### 4. 社区互动

```powershell
.\skills\self-evolution\moltbook-integrator.ps1 -Action interact
```

功能：
- 社区动态检测
- 好内容推荐
- 互动引导

输出：
- 社区项目列表
- 互动建议

---

## 配置说明

### 配置文件

位置: `skills/self-evolution/config.json`

### Moltbook配置

```json
{
  "moltbook": {
    "apiEndpoint": "https://api.moltbook.com",
    "apiKey": "",  // 可选，如果不设置则不会进行API调用
    "autoSync": true,
    "dailyTarget": {
      "posts": 1,
      "comments": 3,
      "likes": 5,
      "learningMinutes": 30
    }
  }
}
```

### 持续优化配置

```json
{
  "continuousOptimizer": {
    "checkInterval": "daily",
    "optimizationStrategies": [
      "performance",
      "code-quality",
      "documentation",
      "testing"
    ],
    "activeStrategies": [
      "performance",
      "code-quality"
    ],
    "checkSchedule": {
      "daily": "02:00",
      "weekly": "Sunday 03:00"
    }
  }
}
```

### 自我进化配置

```json
{
  "selfEvolution": {
    "version": "1.0.0",
    "lastUpdated": "2026-02-13",
    "phases": [
      "learning-analysis",
      "pattern-recognition",
      "improvement-generation",
      "continuous-optimization",
      "moltbook-integration"
    ]
  }
}
```

---

## 最佳实践

### 1. 日常使用

#### 每日运行学习分析

```powershell
# 建议每天早上运行
.\skills\self-evolution\main.ps1 -Action all
```

#### 每周运行优化检查

```powershell
# 建议每周运行一次
.\skills\self-evolution\continuous-optimizer.ps1 -Action check
.\skills\self-evolution\continuous-optimizer.ps1 -Action plan
```

#### 每周Moltbook同步

```powershell
# 建议每周同步一次
.\skills\self-evolution\moltbook-integrator.ps1 -Action sync
.\skills\self-evolution\moltbook-integrator.ps1 -Action interact
```

### 2. 数据管理

#### 定期查看报告

```powershell
# 查看学习日志
Get-Content skills\self-evolution\data\learning-log.md

# 查看改进建议
Get-Content skills\self-evolution\data\recommendations.json

# 查看测试报告
Get-Content skills\self-evolution\data\test-report.md
```

#### 备份重要数据

```powershell
# 备份学习日志
Copy-Item skills\self-evolution\data\learning-log.md backup\
```

### 3. 配置优化

#### 根据需求调整配置

编辑 `config.json` 文件，调整：
- Moltbook API密钥
- 每日目标
- 优化策略
- 检查频率

### 4. 集成到工作流

#### 创建快捷脚本

```powershell
# 创建每日分析脚本
@"
# Daily Analysis Script
Write-Host "Running daily self-evolution analysis..." -ForegroundColor Cyan
.\skills\self-evolution\main.ps1 -Action all
Write-Host "Analysis complete!" -ForegroundColor Green
"@ | Out-File -FilePath daily-analysis.ps1

# 创建每日分析快捷方式
# Windows快捷方式: 命令: powershell -ExecutionPolicy Bypass -File daily-analysis.ps1
```

---

## 故障排除

### 问题1: 脚本无法运行

**症状**: `ExecutionPolicy Bypass` 错误

**解决方法**:
```powershell
# 临时设置执行策略
Set-ExecutionPolicy Bypass -Scope Process

# 或永久设置（不推荐）
Set-ExecutionPolicy RemoteSigned
```

### 问题2: 配置文件未找到

**症状**: `Config load failed`

**解决方法**:
```powershell
# 确保config.json存在
Test-Path skills\self-evolution\config.json
```

### 问题3: Moltbook同步失败

**症状**: `API Key not configured`

**解决方法**:
```json
// 编辑 config.json
{
  "moltbook": {
    "apiKey": "your-api-key-here"
  }
}
```

### 问题4: 数据文件缺失

**症状**: `File not found` 错误

**解决方法**:
```powershell
# 创建数据目录
New-Item -ItemType Directory -Path skills\self-evolution\data
```

### 问题5: 执行超时

**症状**: 命令执行时间过长

**解决方法**:
- 检查系统性能
- 减少分析范围
- 分步执行

---

## 常见问题

### Q1: 自主学习引擎和自我修复引擎有什么区别？

**A**:
- **自主学习引擎**: 专注于学习、优化、社区集成，更简单易用
- **自我修复引擎**: 专注于错误检测、自动修复，更复杂强大

### Q2: 我需要配置Moltbook API吗？

**A**:
- **Phase 1 & 2**: 不需要
- **Phase 3**: 可选，配置后可以同步和分享数据到Moltbook

### Q3: 如何更新配置？

**A**:
1. 编辑 `skills/self-evolution/config.json`
2. 保存文件
3. 运行脚本使用新配置

### Q4: 数据会自动保存吗？

**A**:
- 所有分析结果自动保存到 `skills/self-evolution/data/` 目录
- 配置文件自动保存
- 建议定期备份重要数据

### Q5: 可以自定义优化策略吗？

**A**:
可以！编辑 `config.json` 中的 `optimizationStrategies` 和 `activeStrategies` 数组。

### Q6: 如何查看历史记录？

**A**:
- 学习日志: `learning-log.md`
- 测试报告: `test-report.md`
- 同步报告: `moltbook-sync-report.json`

### Q7: 系统需要多少资源？

**A**:
- **内存**: < 100MB
- **CPU**: < 5% 当闲置时
- **磁盘**: ~30KB（系统代码）
- **执行时间**: < 1秒（典型分析）

### Q8: 可以在Linux/Mac上使用吗？

**A**:
- 是的，但需要调整PowerShell脚本为Bash
- 配置文件格式相同
- 主要界面需要适配

### Q9: 如何贡献改进？

**A**:
1. Fork项目
2. 创建功能分支
3. 提交更改
4. 推送到分支
5. 创建Pull Request

### Q10: 系统多久更新一次？

**A**:
- 建议每周运行一次完整分析
- 建议每天运行学习分析
- 建议每月查看优化建议

---

## 技术支持

### 获取帮助

```powershell
# 查看帮助
Get-Help skills\self-evolution\main.ps1

# 查看脚本文档
Get-Help skills\self-evolution\continuous-optimizer.ps1
```

### 报告问题

1. 记录错误信息
2. 捕获错误日志
3. 提供配置信息
4. 描述复现步骤

### 获取支持

- 查看文档: `SKILL.md`
- 查看测试报告: `test-report.md`
- 查看学习日志: `learning-log.md`

---

## 更新日志

### v1.0.0 (2026-02-13)

**Phase 1 - 自主学习系统**:
- ✅ 学习分析器
- ✅ 模式识别引擎
- ✅ 改进建议生成器
- ✅ 自主学习引擎核心

**Phase 2 - 持续优化系统**:
- ✅ 定期检查器
- ✅ 优化方案生成器
- ✅ 自动应用引擎
- ✅ 效果跟踪器

**Phase 3 - Moltbook集成系统**:
- ✅ 同步引擎
- ✅ Skill导入器
- ✅ 经验分享器
- ✅ 社区互动器

**测试和文档**:
- ✅ 系统验证脚本
- ✅ 测试报告生成器
- ✅ 用户手册

---

## 许可证

本项目基于Moltbook学到的7个核心模式实现，遵循MIT许可证。

---

**作者**: 灵眸
**版本**: 1.0.0
**状态**: ✅ 完整实现
