# Data Visualization System - 数据可视化系统

## 📊 概述
数据可视化系统，展示任务进度、系统状态、搜索结果等数据，提供直观的图表和仪表盘。

---

## ✨ 核心功能

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

---

## 🚀 快速开始

### 生成柱状图
```powershell
$data = @{
    labels = @("任务1", "任务2", "任务3")
    values = @(80, 65, 90)
}

.\skills\data-visualization\main.ps1 -Action chart -Type "bar" -Data $data
```

### 任务进度可视化
```powershell
.\skills\data-visualization\main.ps1 -Action progress -Type "task"
```

### 系统仪表盘
```powershell
.\skills\data-visualization\main.ps1 -Action dashboard -Type "system"
```

### 导出数据
```powershell
.\skills\data-visualization\main.ps1 -Action export -Format "json" -Type "task"
```

---

## 📁 文件结构

```
skills/data-visualization/
├── SKILL.md              # 技能文档
├── README.md             # 本文档
├── data/
│   ├── task-progress.json    # 任务进度数据
│   └── system-stats.json     # 系统统计数据
└── scripts/
    ├── main.ps1          # 主程序入口
    ├── data-collector.ps1  # 数据收集
    └── chart-generator.ps1  # 图表生成
```

---

## 📊 可用图表类型

### 1. 柱状图（Bar Chart）
适合对比不同类别的数值

```powershell
Type: bar
Data: labels + values
```

### 2. 折线图（Line Chart）
适合展示趋势变化

```powershell
Type: line
Data: labels + series
```

### 3. 饼图（Pie Chart）
适合展示占比

```powershell
Type: pie
Data: labels + values
```

### 4. 雷达图（Radar Chart）
适合多维度对比

```powershell
Type: radar
Data: labels + dimensions
```

---

## 🎯 使用场景

### 场景1：任务进度监控
```powershell
# 展示Week 4完成进度
$tasks = @{
    "智能搜索系统" = 100
    "Agent协作系统" = 0
    "数据可视化系统" = 0
    "API网关" = 0
}

.\skills\data-visualization\main.ps1 -Action progress -Type "task"
```

### 场景2：系统性能监控
```powershell
# 展示系统资源使用
$stats = @{
    "CPU" = 35
    "内存" = 45
    "磁盘" = 60
    "网络" = 25
}

.\skills\data-visualization\main.ps1 -Action dashboard -Type "system"
```

### 场景3：搜索结果统计
```powershell
# 展示搜索结果来源分布
$searchStats = @{
    "本地文件" = 15
    "Web搜索" = 25
    "内部记忆" = 8
    "RAG知识库" = 12
}

.\skills\data-visualization\main.ps1 -Action progress -Type "search"
```

---

## 📊 输出格式

### PowerShell输出
- 图表绘制在控制台
- 适合快速查看

### 文件导出
- JSON格式数据
- Markdown格式报告

---

## 🔧 依赖

- PowerShell 5.1+
- 数据源（self-evolution、smart-search、system-integration）

---

## 📝 更新日志

### 2026-02-14
- ✅ 创建基础架构
- ✅ 实现数据收集模块
- ✅ 实现图表生成模块
- ✅ 实现主程序入口
- ✅ 创建示例数据文件
- ✅ 完成文档

---

## 👤 作者
**灵眸** - 自我进化引擎的一部分

---

## 📄 许可证
MIT License
