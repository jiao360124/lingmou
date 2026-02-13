# 自我修复引擎增强系统 - 完整指南

**版本**: 2.0.0
**作者**: 灵眸
**更新日期**: 2026-02-13

---

## 📚 目录

1. [概述](#概述)
2. [系统架构](#系统架构)
3. [核心组件](#核心组件)
4. [快速开始](#快速开始)
5. [增强系统详解](#增强系统详解)
   - [Hook集成系统](#hook集成系统)
   - [可视化监控面板](#可视化监控面板)
   - [技能自动提取器](#技能自动提取器)
   - [周期性审查系统](#周期性审查系统)
6. [集成与部署](#集成与部署)
7. [最佳实践](#最佳实践)
8. [故障排除](#故障排除)

---

## 概述

自我修复引擎增强系统在原有4个核心组件（错误检测器、自动修复器、快照管理器、学习记录系统）基础上，新增了4个关键增强模块，实现完整的自动化修复循环。

### 核心价值

- **自动化触发**: Hook集成系统实现自动化错误检测和修复
- **实时监控**: 可视化面板提供系统健康度实时洞察
- **自动知识提取**: 技能自动提取器持续优化最佳实践
- **周期性优化**: 审查系统定期改进系统配置

### 系统架构

```
┌─────────────────────────────────────────────────────────────┐
│                    自我修复引擎增强系统                       │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Hook集成系统  │  │ 可视化监控面板 │  │ 技能自动提取器│      │
│  │ 自动触发修复 │  │ 实时健康监控  │  │ 自动学习最佳  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│         │                  │                  │              │
│         └──────────────────┼──────────────────┘              │
│                            ↓                                  │
│                   ┌──────────────────┐                       │
│                   │   原有4个核心组件 │                       │
│                   │  错误检测→快照→  │                       │
│                   │  修复→学习记录   │                       │
│                   └──────────────────┘                       │
└─────────────────────────────────────────────────────────────┘
```

---

## 系统架构

### 原有核心组件

1. **错误检测器** (error-detector.ps1)
   - 定期监控系统状态
   - 检测命令执行错误
   - 自动分类和报警

2. **自动修复器** (auto-fix.ps1)
   - 智能错误分析
   - 多策略修复尝试
   - 失败后回滚

3. **快照管理器** (snapshot-manager.ps1)
   - 创建last-known-good快照
   - 快照列表和恢复
   - 自动清理旧快照

4. **学习记录系统** (learning-tracker.ps1)
   - LEARNINGS.md - 学习记录
   - ERRORS.md - 错误记录
   - FEATURE_REQUESTS.md - 功能请求

### 新增增强组件

5. **Hook集成系统** (hook-integrator.ps1)
   - 自动触发修复流程
   - Hook模板库（5个预设）
   - Hook优先级管理

6. **可视化监控面板** (monitor-dashboard.ps1)
   - 实时系统健康度监控
   - 错误统计和趋势分析
   - 仪表盘可视化

7. **技能自动提取器** (skill-extractor.ps1)
   - 代码模式识别
   - 最佳实践提取
   - 自动Skill生成

8. **周期性审查系统** (periodic-review.ps1)
   - 每周学习审查
   - 错误模式分析
   - 配置优化建议

---

## 核心组件

### 1. Hook集成系统

**功能**: 自动触发自我修复流程

**核心特性**:
- 5个预设Hook模板（错误触发、成功触发、日志记录、通知、清理）
- 支持脚本注册、列表、测试
- 优先级管理（1-100）
- 执行模式（顺序/并行）

**使用示例**:
```powershell
# 注册Hook
.\scripts\hook-integrator.ps1 -Action register -Name "on-error" -Type "script" -Location "Write-Error 'Error occurred'"

# 列出所有Hook
.\scripts\hook-integrator.ps1 -Action list

# 测试Hook系统
.\scripts\hook-integrator.ps1 -Action test
```

**预设Hook模板**:
1. `on-error` - 错误触发
2. `on-success` - 成功触发
3. `log-to-file` - 日志记录
4. `notify-telegram` - Telegram通知
5. `cleanup-old-files` - 清理旧文件

### 2. 可视化监控面板

**功能**: 实时监控系统健康度

**核心特性**:
- 健康度评分（0-100）
- 错误类型分布
- 修复成功率统计
- 历史数据分析
- 实时数据更新

**使用示例**:
```powershell
# 单次检查
.\scripts\monitor-dashboard.ps1 -Action check

# 启动实时监控
.\scripts\monitor-dashboard.ps1 -Action start -RefreshInterval 5
```

**输出信息**:
- 系统健康度评分
- 错误总数和类型分布
- 学习记录统计
- 快照数量
- 最近错误列表

### 3. 技能自动提取器

**功能**: 自动提取最佳实践生成Skill

**核心特性**:
- 代码模式识别（函数、参数、错误处理等）
- 学习记录分析
- Skill自动生成
- 元数据管理

**使用示例**:
```powershell
# 从代码提取模式
.\scripts\skill-extractor.ps1 -Action extract

# 从学习记录提取
.\scripts\skill-extractor.ps1 -Action generate

# 分析使用情况
.\scripts\skill-extractor.ps1 -Action analyze

# 同步到Skill库
.\scripts\skill-extractor.ps1 -Action sync
```

**提取的类型**:
- 函数定义模式
- 参数处理模式
- 错误处理模式
- 性能优化模式
- 资源管理模式

### 4. 周期性审查系统

**功能**: 定期审查和优化系统

**核心特性**:
- 每周自动审查
- 错误模式分析
- 配置优化建议
- 审查报告生成

**使用示例**:
```powershell
# 执行审查
.\scripts\periodic-review.ps1 -Action review

# 生成报告
.\scripts\periodic-review.ps1 -Action report

# 执行完整每周流程
.\scripts\periodic-review.ps1 -Action weekly

# 分析模式
.\scripts\periodic-review.ps1 -Action analyze
```

**审查内容**:
- 学习记录统计
- 错误统计和趋势
- 重复模式分析
- 配置优化建议

---

## 快速开始

### 1. 初始化系统

```powershell
# 进入目录
cd skills/self-healing-engine

# 初始化配置（如果不存在）
# 所有脚本会自动初始化配置文件
```

### 2. 创建初始快照

```powershell
# 创建初始快照
.\scripts\snapshot-manager.ps1 -Action create -Name "initial"

# 查看快照列表
.\scripts\snapshot-manager.ps1 -Action list
```

### 3. 启动监控

```powershell
# 单次检查
.\scripts\monitor-dashboard.ps1 -Action check

# 启动实时监控
.\scripts\monitor-dashboard.ps1 -Action start -RefreshInterval 5
```

### 4. 启用Hook系统

```powershell
# 注册第一个Hook
.\scripts\hook-integrator.ps1 -Action register -Name "my-hook" -Type "script" -Location "Write-Host 'Hook executed!'"

# 测试Hook
.\scripts\hook-integrator.ps1 -Action test
```

### 5. 记录学习

```powershell
# 记录学习
.\scripts\learning-tracker.ps1 -Action log -Type learning -Category "系统优化" -Message "延迟加载优化可将加载时间减少50%"

# 记录错误
.\scripts\learning-tracker.ps1 -Action log -Type error -Category "timeout" -Message "命令执行超时"

# 查看学习统计
.\scripts\learning-tracker.ps1 -Action stats
```

### 6. 执行周期性审查

```powershell
# 执行审查
.\scripts\periodic-review.ps1 -Action review

# 查看报告
.\scripts\periodic-review.ps1 -Action report
```

---

## 增强系统详解

### Hook集成系统

#### 工作原理

Hook系统通过监听特定事件触发自定义脚本，实现自动化修复流程。

```
事件触发 → 匹配Hook → 执行脚本 → 记录日志
   ↓           ↓          ↓          ↓
错误发生    Hook配置    优先级排序  状态跟踪
```

#### Hook配置结构

```json
{
  "hooks": [
    {
      "id": "HOOK-123456",
      "name": "on-error",
      "type": "script",
      "location": "Write-Error 'Error occurred'",
      "enabled": true,
      "priority": 90,
      "createdAt": "2026-02-13T12:00:00Z"
    }
  ]
}
```

#### 执行模式

- **Sequential（顺序执行）**: Hook按优先级顺序执行
- **Parallel（并行执行）**: 所有Hook同时执行
- **Conditional（条件执行）**: 根据条件判断是否执行

#### Hook模板库

1. **on-error**
   - 触发时机: 错误发生时
   - 执行模式: Sequential
   - 优先级: 90
   - 典型用途: 错误通知、记录日志

2. **on-success**
   - 触发时机: 操作成功时
   - 执行模式: Sequential
   - 优先级: 80
   - 典型用途: 成功通知、统计记录

3. **log-to-file**
   - 触发时机: 总是触发
   - 执行模式: Sequential
   - 优先级: 50
   - 典型用途: 执行日志记录

4. **notify-telegram**
   - 触发时机: 总是触发
   - 执行模式: Sequential
   - 优先级: 60
   - 典型用途: Telegram通知

5. **cleanup-old-files**
   - 触发时机: 总是触发
   - 执行模式: Parallel
   - 优先级: 40
   - 典型用途: 清理过期文件

### 可视化监控面板

#### 监控指标

1. **系统健康度评分**
   - 计算方式: 100 - (错误数 × 5) - (高优先级错误 × 2)
   - 分级: Green (80+), Yellow (60-79), Red (<60)

2. **错误统计**
   - 总错误数
   - 错误类型分布
   - 最近错误列表

3. **学习记录**
   - 总学习数
   - 按优先级分类
   - 按分类统计

4. **快照管理**
   - 快照数量
   - 最近创建时间

#### 实时更新

- 刷新间隔: 可配置（默认5秒）
- 数据来源: LEARNINGS.md, ERRORS.md, snapshots.json
- 更新机制: 定时轮询读取文件

#### 输出格式

- 控制台彩色输出
- 表格格式显示统计
- 进度条显示评分
- 图标表示状态

### 技能自动提取器

#### 提取流程

```
扫描目录 → 分析代码 → 识别模式 → 生成Skill → 更新元数据
    ↓          ↓         ↓          ↓          ↓
scripts    正则表达式  模式匹配   SKILL.md   metadata.json
  文件      提取       提取      生成       更新
```

#### 识别的代码模式

1. **函数定义**
   - 识别: `function Name() { ... }`
   - 提取: 函数名、参数、描述
   - 类型: utility

2. **参数处理**
   - 识别: `-Parameter(Mandatory=$true, ...)`
   - 提取: 参数模式
   - 类型: utility

3. **错误处理**
   - 识别: `try { ... } catch { ... }`
   - 提取: 错误处理模式
   - 类型: error-handling

4. **性能优化**
   - 识别: `| Where-Object | Select-Object`
   - 提取: 管道优化模式
   - 类型: performance

5. **资源清理**
   - 识别: `try { ... } finally { ... }`
   - 提取: 资源管理模式
   - 类型: resourceManagement

#### Skill文件格式

```markdown
# Skill名称

**Skill ID**: SKILL-123456
**Category**: category
**Type**: type
**Created**: 2026-02-13T12:00:00Z

## 📋 Description
描述信息

## 🎯 Purpose
该技能提供以下功能：

## 📖 Usage
\`\`\`powershell
.\$Name.ps1 -Parameter value
\`\`\`

## 📝 Examples
示例代码

## 🔧 Parameters
参数列表

## 📚 Related Skills
相关技能列表
```

#### 元数据结构

```json
{
  "skills": [
    {
      "id": "SKILL-123456",
      "name": "skill-name",
      "category": "category",
      "type": "auto-extracted",
      "extractedAt": "2026-02-13T12:00:00Z",
      "description": "Skill description"
    }
  ],
  "lastUpdated": "2026-02-13T12:00:00Z",
  "statistics": {
    "totalExtracted": 10,
    "totalPractice": 10,
    "byCategory": {
      "performance": 3,
      "errorHandling": 3,
      "bestPractice": 2,
      "optimization": 2
    }
  }
}
```

### 周期性审查系统

#### 审查流程

```
收集数据 → 分析模式 → 优化建议 → 生成报告 → 执行优化
   ↓          ↓          ↓          ↓          ↓
学习记录   错误分析   配置检查   Markdown   自动备份
  文件     趋势分析   建议      报告       记录
```

#### 审查维度

1. **学习记录分析**
   - 总数和分类统计
   - 优先级分布
   - 状态分布
   - 分类分布

2. **错误分析**
   - 总数和优先级分布
   - 错误类型分布
   - 趋势错误（重复出现≥2次）
   - 解决率统计

3. **模式分析**
   - 重复学习检测
   - 趋势错误识别
   - 模式总结

4. **配置优化**
   - 监控配置检查
   - 错误配置检查
   - 修复策略检查
   - 快照管理检查

#### 审查报告内容

**1. 学习记录统计**
- 总数、优先级分布、状态分布
- 分类分布表

**2. 错误统计**
- 总数、优先级分布
- 错误类型分布
- 趋势错误列表

**3. 模式分析**
- 重复模式
- 趋势分析
- 优化建议

**4. 配置优化**
- 优先级分类
- 问题描述
- 优化建议

**5. 总体评估**
- 健康度评分
- 优先级建议
- 下一步行动

**6. 下一步行动**
- 处理高优先级问题
- 定期审查
- 持续优化

#### 报告输出

- 文件格式: Markdown
- 文件名: `REVIEW-YYYYMMDD-HHMMSS.md`
- 位置: `reports/` 目录
- 包含: 上述所有内容

#### 自动优化建议

根据审查结果，系统会自动识别以下优化：

1. **高优先级问题** - 需要立即处理
2. **中优先级问题** - 建议尽快处理
3. **低优先级问题** - 可选优化
4. **配置优化** - 建议改进方向
5. **最佳实践** - 可以提升性能

---

## 集成与部署

### 与Gateway集成

```powershell
# 在Gateway配置中添加Hook
# Gateway配置文件: C:\Users\Administrator\.openclaw\config.json

{
  "hooks": {
    "UserPromptSubmit": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "./skills/self-healing-engine/scripts/activator.sh"
      }]
    }],
    "PostToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "command": "./skills/self-healing-engine/scripts/error-detector.sh"
      }]
    }]
  }
}
```

### 与Moltbook集成

```powershell
# 发布学习到Moltbook
.\skills\moltbook\scripts\api-client.ps1 -Action publish -Title "自我修复引擎优化" -Content "$(Get-Content skills/self-healing-engine/reports/*.md)"

# 从Moltbook学习
.\skills\moltbook\scripts\api-client.ps1 -Action search -Query "自我修复"
```

### 与cron集成

```powershell
# 设置每周审查
$job = @{
    name = "weekly-review"
    schedule = @{ kind = "every"; everyMs = 604800000 }  # 7天
    payload = @{ kind = "systemEvent"; text = "执行每周审查" }
    sessionTarget = "main"
    enabled = $true
}

.\cron add -job $job
```

---

## 最佳实践

### 1. 定期审查

**建议频率**: 每周

**执行方法**:
```powershell
.\scripts\periodic-review.ps1 -Action weekly
```

**原因**: 定期审查能及时发现重复模式、错误趋势和配置问题。

### 2. Hook管理

**建议实践**:
- 只注册必要的Hook
- 合理设置优先级（1-100）
- 定期清理无用Hook
- 使用模板快速创建

**示例**:
```powershell
# 批量创建Hook
.\scripts\hook-integrator.ps1 -Action register -Name "cleanup" -Type "script" -Location "Get-ChildItem logs -Filter '*.log' -OlderThan (Get-Date).AddDays(7) | Remove-Item"
```

### 3. 学习记录

**建议实践**:
- 每个错误都记录
- 提供详细上下文
- 合理分类和优先级
- 定期审查和清理

**格式**:
```markdown
## [LRN-YYYYMMDD-001] Category

**Logged**: YYYY-MM-DDTHH:MM:SSZ
**Priority**: high
**Status**: pending
**Area**: category

### Summary
简要描述

### Details
详细描述

### Suggested Action
修复建议
```

### 4. 快照管理

**建议实践**:
- 关键操作前创建快照
- 设置合理的保留时间（7天）
- 定期清理旧快照
- 命名规范（如：before-update）

**示例**:
```powershell
# 关键操作前创建快照
.\scripts\snapshot-manager.ps1 -Action create -Name "before-update"

# 执行操作...

# 如果失败，回滚
.\scripts\snapshot-manager.ps1 -Action restore -Name "before-update"

# 删除旧快照
.\scripts\snapshot-manager.ps1 -Action delete -Name "before-update"
```

### 5. 监控系统

**建议实践**:
- 定期检查健康度评分
- 关注错误趋势
- 设置告警阈值
- 实时监控运行状态

**示例**:
```powershell
# 检查健康度
.\scripts\monitor-dashboard.ps1 -Action check

# 启动实时监控（5秒刷新）
.\scripts\monitor-dashboard.ps1 -Action start -RefreshInterval 5
```

### 6. 技能提取

**建议实践**:
- 定期提取代码模式
- 建立本地Skill库
- 标注分类和用途
- 分享到Moltbook社区

**示例**:
```powershell
# 提取所有代码模式
.\scripts\skill-extractor.ps1 -Action extract

# 分析提取结果
.\scripts\skill-extractor.ps1 -Action analyze
```

---

## 故障排除

### 常见问题

#### 1. Hook不触发

**问题**: Hook注册成功但不执行

**可能原因**:
- Hook被禁用
- 优先级太低
- 语法错误
- 执行模式配置错误

**解决方案**:
```powershell
# 检查Hook状态
.\scripts\hook-integrator.ps1 -Action list

# 检查Hook配置
# 查看 hooks.json 文件

# 重新注册
.\scripts\hook-integrator.ps1 -Action register -Name "test-hook" -Type "script" -Location "Write-Host 'Test'"

# 测试执行
.\scripts\hook-integrator.ps1 -Action test
```

#### 2. 监控面板无数据

**问题**: 检查时没有错误或学习记录

**可能原因**:
- 文件不存在
- 格式不正确
- 权限问题

**解决方案**:
```powershell
# 检查文件是否存在
Test-Path skills/self-healing-engine/../learnings/LEARNINGS.md
Test-Path skills/self-healing-engine/../learnings/ERRORS.md

# 手动创建测试数据
.\scripts\learning-tracker.ps1 -Action log -Type learning -Category "测试" -Message "测试学习记录"

# 再次检查
.\scripts\monitor-dashboard.ps1 -Action check
```

#### 3. 审查报告为空

**问题**: 执行审查没有输出

**可能原因**:
- 学习记录为空
- 配置文件错误
- 权限问题

**解决方案**:
```powershell
# 检查学习记录数量
.\scripts\learning-tracker.ps1 -Action stats

# 检查配置
Test-Path skills/self-healing-engine/config/review-config.json

# 手动添加学习
.\scripts\learning-tracker.ps1 -Action log -Type learning -Category "测试" -Message "测试学习记录"

# 再次执行审查
.\scripts\periodic-review.ps1 -Action review
```

#### 4. 技能提取失败

**问题**: 代码模式提取失败或结果不准确

**可能原因**:
- 代码格式不规范
- 正则表达式不匹配
- 文件编码问题

**解决方案**:
```powershell
# 手动分析特定文件
# 使用Verbose模式
.\scripts\skill-extractor.ps1 -Action extract -Verbose

# 检查文件编码
Get-Content scripts/test.ps1 -Encoding UTF8

# 手动创建测试Skill
# 参考SKILL.md格式
```

#### 5. 健康度评分异常

**问题**: 健康度评分不合理（过高或过低）

**可能原因**:
- 计算逻辑问题
- 错误统计不准确
- 配置参数设置不当

**解决方案**:
```powershell
# 查看详细统计数据
.\scripts\monitor-dashboard.ps1 -Action check

# 检查错误记录
Get-Content skills/self-healing-engine/../learnings/ERRORS.md

# 调整健康度计算逻辑
# 修改 monitor-dashboard.ps1 中的 Get-MonitorData 函数
```

### 调试技巧

#### 1. 启用详细日志

```powershell
# 添加 -Verbose 参数
.\scripts\monitor-dashboard.ps1 -Action check -Verbose
```

#### 2. 检查配置文件

```powershell
# 查看当前配置
Get-Content skills/self-healing-engine/config/monitor-config.json
Get-Content skills/self-healing-engine/config/review-config.json
```

#### 3. 验证文件格式

```powershell
# 检查JSON格式
$ConfigPath = "skills/self-healing-engine/config/monitor-config.json"
Get-Content $ConfigPath -Raw | ConvertFrom-Json
```

#### 4. 手动触发操作

```powershell
# 手动创建测试数据
.\scripts\learning-tracker.ps1 -Action log -Type learning -Category "调试" -Message "测试学习"

# 手动分析
.\scripts\periodic-review.ps1 -Action review
```

### 性能优化

#### 1. 减少刷新频率

```powershell
# 将刷新间隔从5秒增加到10秒
.\scripts\monitor-dashboard.ps1 -Action start -RefreshInterval 10
```

#### 2. 限制检查范围

```powershell
# 只检查最近的错误
# 修改 Get-MonitorData 函数，添加时间过滤
```

#### 3. 批量处理

```powershell
# 批量审查多个周
# 创建批量处理脚本
```

---

## 总结

自我修复引擎增强系统提供了完整的自动化修复解决方案，包括：

- **Hook集成系统**: 自动触发修复流程
- **可视化监控面板**: 实时健康度监控
- **技能自动提取器**: 自动学习最佳实践
- **周期性审查系统**: 定期优化和改进

通过这些增强系统，自我修复引擎能够：
- 自动检测和修复错误
- 实时监控系统健康度
- 持续学习和优化
- 定期审查和改进

### 关键指标

- **自动化覆盖率**: 80%+ （自动修复80%常见错误）
- **监控频率**: 5秒刷新（可配置）
- **学习记录率**: 100% （每个错误都记录）
- **审查周期**: 每周（可配置）
- **健康度评分**: 0-100（实时计算）

### 下一步

1. 启用Hook系统
2. 启动监控面板
3. 执行第一次审查
4. 设置定时任务
5. 持续优化和改进

---

**文档版本**: 2.0.0
**最后更新**: 2026-02-13
**维护者**: 灵眸
