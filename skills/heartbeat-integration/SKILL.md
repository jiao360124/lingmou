---
name: heartbeat-integration
description: "Heartbeat整合增强系统"
---

# Heartbeat整合增强系统

**版本**: 1.0.0
**创建日期**: 2026-02-13
**作者**: 灵眸
**状态**: 实施中

---

## 🎯 核心使命

通过主动任务执行和智能队列管理，让Heartbeat从被动心跳变为主动任务管理系统。

---

## 📋 目录

- [概述](#概述)
- [核心功能](#核心功能)
- [使用指南](#使用指南)
- [工作原理](#工作原理)
- [配置管理](#配置管理)
- [最佳实践](#最佳实践)

---

## 概述

Heartbeat整合增强系统将Heartbeat从简单的健康检查升级为主动任务执行引擎：

### 核心能力

1. **主动任务管理** - 定期检查和执行任务
2. **智能优先级** - 按优先级自动排序任务
3. **逾期提醒** - 自动检测和提醒逾期任务
4. **状态跟踪** - 实时任务状态监控
5. **记忆集成** - 与持久化记忆系统整合

---

## 核心功能

### 1. 任务管理
- ✅ 添加任务到队列
- ✅ 列出所有任务
- ✅ 开始/停止任务
- ✅ 完成任务
- ✅ 移除任务
- ✅ 查看任务状态

### 2. 优先级调度
- ✅ High优先级（紧急）
- ✅ Medium优先级（正常）
- ✅ Low优先级（可选）

### 3. 逾期检测
- ✅ 自动检测逾期任务
- ✅ 实时提醒
- ✅ 剩余时间计算

### 4. Heartbeat集成
- ✅ 自动任务检查
- ✅ 逾期任务提醒
- ✅ 记忆主动记录

---

## 使用指南

### 快速开始

#### 1. 添加任务

```powershell
# 添加高优先级任务
.\heartbeat-integration.ps1 -Action add -TaskName "清理日志" -Priority high -Category "maintenance"

# 添加普通任务
.\heartbeat-integration.ps1 -Action add -TaskName "备份数据" -Priority medium -Category "backup"

# 添加带到期时间的任务
.\heartbeat-integration.ps1 -Action add -TaskName "检查系统" -Priority medium -DueDate "2026-02-14 00:00"
```

#### 2. 查看任务

```powershell
# 列出所有任务
.\heartbeat-integration.ps1 -Action list

# 查看单个任务状态
.\heartbeat-integration.ps1 -Action status -TaskName "清理日志"
```

#### 3. 执行任务

```powershell
# 开始任务
.\heartbeat-integration.ps1 -Action start -TaskName "清理日志"

# 完成任务
.\heartbeat-integration.ps1 -Action complete -TaskName "清理日志"

# 停止任务
.\heartbeat-integration.ps1 -Action stop -TaskName "清理日志"
```

#### 4. 任务队列

```powershell
# 移除任务
.\heartbeat-integration.ps1 -Action remove -TaskName "清理日志"
```

---

## 工作原理

### 任务生命周期

```
┌─────────────┐
│  添加任务   │
└──────┬──────┘
       ↓
┌─────────────┐
│  等待队列   │
└──────┬──────┘
       ↓
┌─────────────┐
│  开始执行   │
└──────┬──────┘
       ↓
┌─────────────┐
│  执行中     │
└──────┬──────┘
       ↓
┌─────────────┐
│  完成或失败 │
└─────────────┘
```

### 优先级调度

```
High → Medium → Low

1. High优先级任务优先执行
2. Medium优先级任务次之
3. Low优先级任务最后
```

### Heartbeat整合

```
Heartbeat循环
    ↓
检查任务队列
    ↓
发现待执行任务?
    ├─ Yes → 按优先级执行
    └─ No  → 继续心跳
    ↓
检查逾期任务
    ↓
发现逾期任务?
    ├─ Yes → 发送提醒
    └─ No  → 继续心跳
```

---

## 配置管理

### 任务队列文件

位置: `skills/heartbeat-integration/data/tasks.json`

```json
[
  {
    "id": "uuid",
    "name": "task-name",
    "category": "general",
    "priority": "medium",
    "status": "pending",
    "createdAt": "2026-02-13 20:00:00",
    "dueDate": "2026-02-14 00:00:00",
    "attempts": 0
  }
]
```

### 配置选项

| 参数 | 类型 | 必填 | 默认值 | 描述 |
|------|------|------|--------|------|
| Action | string | 是 | - | 操作类型 |
| TaskName | string | 是 | - | 任务名称 |
| Category | string | 否 | general | 任务类别 |
| Priority | string | 否 | medium | 优先级 |
| DueDate | string | 否 | - | 到期时间 |

---

## 最佳实践

### 日常使用

**1. 定期添加任务**
```powershell
# 每日备份
.\heartbeat-integration.ps1 -Action add -TaskName "每日备份" -Priority high -Category "backup"

# 定期清理
.\heartbeat-integration.ps1 -Action add -TaskName "清理日志" -Priority medium -Category "maintenance"
```

**2. 监控任务队列**
```powershell
# 每次Heartbeat时检查
.\heartbeat-integration.ps1 -Action list
```

**3. 及时完成任务**
```powershell
# 任务完成后标记
.\heartbeat-integration.ps1 -Action complete -TaskName "每日备份"
```

**4. 管理逾期任务**
```powershell
# 检查逾期任务
.\heartbeat-integration.ps1 -Action list

# 优先处理高优先级逾期任务
.\heartbeat-integration.ps1 -Action start -TaskName "逾期任务"
```

### 任务设计

1. **合理设置优先级**
   - High: 紧急/重要任务
   - Medium: 正常日常任务
   - Low: 可选/低优先级任务

2. **设置合理的到期时间**
   - 给自己足够时间
   - 不要设置得太紧

3. **描述清晰**
   - 详细的任务描述
   - 便于理解和执行

---

## 技术架构

### 核心组件

```
heartbeat-integration/
├── SKILL.md
├── main.ps1
├── data/
│   ├── tasks.json       # 任务队列
│   ├── errors/          # 错误日志
│   └── report/          # 执行报告
├── config/
│   └── config.json      # 配置文件
└── templates/           # 任务模板
```

---

## 未来计划

- [ ] Heartbeat循环集成
- [ ] 任务执行历史
- [ ] 任务统计分析
- [ ] 智能重试机制
- [ ] 通知提醒系统

---

## 依赖关系

### 核心依赖

- **persistent-memory** - 持久化记忆系统

---

## 使用场景

### 场景1: 定时维护

```powershell
# 添加维护任务
.\heartbeat-integration.ps1 -Action add -TaskName "系统健康检查" -Priority medium -DueDate "每晚20:00"
```

### 场景2: 逾期提醒

```powershell
# 检查任务状态
.\heartbeat-integration.ps1 -Action status -TaskName "系统健康检查"

# 如果逾期，开始执行
.\heartbeat-integration.ps1 -Action start -TaskName "系统健康检查"
```

### 场景3: 任务队列管理

```powershell
# 查看所有任务
.\heartbeat-integration.ps1 -Action list

# 移除不再需要的任务
.\heartbeat-integration.ps1 -Action remove -TaskName "临时任务"
```

---

## 退出策略

**使用场景**:

- [ ] 在Heartbeat循环中调用
- [ ] 定时任务调用
- [ ] 手动任务管理

---

**更新日志**:

- 2026-02-13: v1.0.0 初始版本
  - 基础任务管理功能
  - 优先级调度
  - 逾期检测
  - Heartbeat集成准备
