# Agent Collaboration System - Agent协作系统

## 📊 概述
混合模式的Agent协作系统，支持并行任务处理、协作式任务、专业分工和结果聚合。

---

## ✨ 核心功能

### 1. 混合协作模式
- **并行模式** - 将大型任务拆分给多个Agent并行执行
- **协作模式** - 多个Agent协同完成一个复杂任务
- **专业分工** - 不同专业领域的Agent互相配合
- **自动融合** - 任务需求→Agent选择→执行→结果聚合

### 2. Agent选择和注册
- **能力声明** - Agent注册时声明能力范围
- **自动推荐** - 系统根据任务需求自动推荐Agent
- **用户指定** - 用户可直接指定使用哪些Agent
- **混合模式** - 用户指定 + 系统自动推荐 + 能力声明

### 3. 任务调度和协调
- **依赖检测** - 自动检测Agent之间的依赖关系
- **拓扑排序** - 优化执行顺序，避免阻塞
- **并行调度** - 无依赖任务并行执行
- **状态跟踪** - 实时监控任务执行状态

### 4. 结果聚合和反馈
- **结果合并** - 多Agent结果智能合并
- **质量评分** - 基于标准评分各Agent结果质量
- **反馈循环** - 将结果反馈给相关Agent改进
- **决策支持** - 生成最终决策建议

---

## 🚀 快速开始

### 创建工作流
```powershell
$workflow = [PSCustomObject]@{
    name = "代码审查"
    description = "多Agent协同进行代码审查"
    mode = "collaborative"
    tasks = @(
        @{
            id = "1"
            name = "代码审查"
            description = "审查代码质量和最佳实践"
            type = "coding"
            assigned_agent = "coder"
            dependencies = @()
        },
        @{
            id = "2"
            name = "测试验证"
            description = "验证代码功能和测试覆盖率"
            type = "testing"
            assigned_agent = "tester"
            dependencies = @("1")
        },
        @{
            id = "3"
            name = "文档更新"
            description = "更新API文档和变更日志"
            type = "documentation"
            assigned_agent = "docs"
            dependencies = @("1", "2")
        }
    )
}

.\skills\agent-collaboration\main.ps1 -Action create -Workflow $workflow
```

### 执行工作流
```powershell
# 执行工作流
.\skills\agent-collaboration\main.ps1 -Action execute -Workflow $workflow -Mode "collaborative"
```

### 列出工作流
```powershell
.\skills\agent-collaboration\main.ps1 -Action list
```

---

## 📁 文件结构

```
skills/agent-collaboration/
├── SKILL.md              # 技能文档
├── README.md             # 本文档
├── agents.json           # Agent配置
├── scripts/
│   ├── main.ps1          # 主程序入口
│   ├── agent-registry.ps1  # Agent注册
│   ├── task-scheduler.ps1  # 任务调度
│   ├── result-aggregator.ps1  # 结果聚合
│   └── collaboration-engine.ps1  # 协作引擎
└── data/
    └── workflows/        # 工作流定义
```

---

## 🎯 核心模块

### 1. Agent注册 (agent-registry.ps1)
- Agent能力声明
- Agent发现和推荐
- 用户指定Agent

### 2. 任务调度 (task-scheduler.ps1)
- 依赖关系分析
- 拓扑排序
- 并行/串行执行
- 执行顺序优化

### 3. 结果聚合 (result-aggregator.ps1)
- 多模式聚合（merge、average、best、consensus）
- 质量评分
- 报告生成

### 4. 协作引擎 (collaboration-engine.ps1)
- 工作流初始化
- 任务分配
- 协作执行
- 结果整合

---

## 📊 可用模式

### 1. 并行模式
适合无依赖关系的任务并行执行。

```powershell
Mode: parallel
Description: 同时执行多个独立任务
```

### 2. 协作模式
适合需要Agent协同的复杂任务。

```powershell
Mode: collaborative
Description: 多Agent协同完成复杂任务
```

---

## 🎯 使用场景

### 场景1: 代码审查
```powershell
$workflow = [PSCustomObject]@{
    name = "代码审查"
    tasks = @(
        @{ name = "代码审查"; assigned_agent = "coder" }
        @{ name = "测试验证"; assigned_agent = "tester"; dependencies = @("1") }
    )
}
```

### 场景2: 项目文档
```powershell
$workflow = [PSCustomObject]@{
    name = "文档生成"
    tasks = @(
        @{ name = "技术文档"; assigned_agent = "docs" }
        @{ name = "API文档"; assigned_agent = "docs"; dependencies = @("1") }
    )
}
```

### 场景3: 复杂系统设计
```powershell
$workflow = [PSCustomObject]@{
    name = "系统设计"
    mode = "collaborative"
    tasks = @(
        @{ name = "架构设计"; assigned_agent = "analyst" }
        @{ name = "后端实现"; assigned_agent = "coder" }
        @{ name = "前端实现"; assigned_agent = "coder"; dependencies = @("1") }
        @{ name = "UI测试"; assigned_agent = "tester"; dependencies = @("1", "2", "3") }
    )
}
```

---

## 📊 输出格式

### Markdown报告
```markdown
# Agent协作工作流报告

## 执行概览
- 总任务数: 3
- 平均准确率: 85.5%
- 综合质量: 88.3%

## 详细结果
| 排名 | Agent | 准确率 | 完整度 | ...
```

### JSON格式
```json
{
  "workflow": {...},
  "tasks": [...],
  "results": [...],
  "aggregated": {...}
}
```

---

## 🔧 配置说明

### agents.json
```json
{
  "agents": [
    {
      "id": "coder",
      "name": "编码专家",
      "capabilities": ["coding", "refactoring", "debugging"],
      "weight": 0.9,
      "icon": "💻"
    }
  ]
}
```

---

## 📝 更新日志

### 2026-02-14
- ✅ 创建基础架构
- ✅ 实现Agent注册系统
- ✅ 实现任务调度系统（依赖分析、拓扑排序）
- ✅ 实现结果聚合系统（4种模式）
- ✅ 实现协作引擎（工作流执行）
- ✅ 完成文档

---

## 👤 作者
**灵眸** - 自我进化引擎的一部分

---

## 📄 许可证
MIT License
