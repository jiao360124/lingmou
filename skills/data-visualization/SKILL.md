# Data Visualization System

## 概述
数据可视化系统，展示任务进度、系统状态、搜索结果等数据，提供直观的图表和仪表盘。

## 核心功能

### 1. 任务数据展示
- 任务进度可视化
- 完成率统计
- 里程碑追踪
- 时间线展示

### 2. 进度可视化
- 日/周/月进度图
- 目标完成度
- 实际vs计划对比
- 趋势分析

### 3. 结果图表
- 柱状图
- 折线图
- 饼图
- 雷达图
- 热力图

### 4. 交互式仪表盘
- 实时状态监控
- 数据筛选和排序
- 自定义视图
- 导出功能

## 使用方法

### 基础图表生成
```powershell
.\skills\data-visualization\main.ps1 -Action chart -Type "bar" -Data $data
```

### 任务进度可视化
```powershell
.\skills\data-visualization\main.ps1 -Action progress -Tasks $tasks
```

### 仪表盘生成
```powershell
.\skills\data-visualization\main.ps1 -Action dashboard -Type "system"
```

### 导出图表
```powershell
.\skills\data-visualization\main.ps1 -Action export -Format "png" -Data $data -Output "chart.png"
```

## 数据源

- self-evolution（自主学习系统）
- smart-search（智能搜索系统）
- system-integration（系统集成）

## 技术架构

### 模块设计
- main.ps1 - 主程序入口
- data-collector.ps1 - 数据收集
- chart-generator.ps1 - 图表生成
- dashboard-builder.ps1 - 仪表盘构建
- export-module.ps1 - 导出功能

## 依赖
- PowerShell图表库
- Chart.js（可选，用于Web可视化）

## 作者
灵眸
