---
name: agent-collaboration
description: "Agent Collaboration System"
---

# Agent Collaboration System

## 概述
混合模式的Agent协作系统，支持并行任务处理、协作式任务、专业分工和结果聚合。

## 核心功能

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

## 使用方法

### 基础协作任务
```powershell
.\skills\agent-collaboration\main.ps1 -Action run -Task "开发新功能" -Mode "collaborative"
```

### 并行任务处理
```powershell
.\skills\agent-collaboration\main.ps1 -Action run -Task "代码审查" -Mode "parallel"
```

### 专业分工协作
```powershell
.\skills\agent-collaboration\main.ps1 -Action run -Task "产品发布" -Mode "specialized" -Agents "coder","tester","docs"
```

### 用户指定Agent
```powershell
$task = @{
    description = "实现用户认证系统"
    mode = "collaborative"
    required_agents = @("coder","tester","security")
    output = "auth-system-report.md"
}
.\skills\agent-collaboration\main.ps1 -Action run -TaskObject $task
```

## 配置文件

### agents.json
```json
{
  "agents": [
    {
      "id": "coder",
      "name": "编码专家",
      "capabilities": ["coding","refactoring","debugging"],
      "weight": 0.9,
      "icon": "💻"
    },
    {
      "id": "tester",
      "name": "测试工程师",
      "capabilities": ["testing","qa","automation"],
      "weight": 0.8,
      "icon": "🧪"
    },
    {
      "id": "docs",
      "name": "文档专家",
      "capabilities": ["writing","documentation","markdown"],
      "weight": 0.7,
      "icon": "📝"
    }
  ]
}
```

## 技术架构

### 模块化设计
- `main.ps1` - 主程序入口
- `agent-registry.ps1` - Agent注册和发现
- `task-scheduler.ps1` - 任务调度和协调
- `result-aggregator.ps1` - 结果聚合
- `collaboration-engine.ps1` - 协作引擎

### 数据流
```
用户任务
  ↓
[Task Analyzer] 任务分析
  ↓
[Agent Selector] Agent选择和推荐
  ↓
[Dependency Analyzer] 依赖关系分析
  ↓
[Scheduler] 任务调度
  ↓
[Execution] 并行/协作执行
  ↓
[Result Aggregator] 结果聚合
  ↓
[Feedback] 反馈循环
  ↓
最终报告
```

## 实施状态

### Phase 4: 功能扩展
- [x] 智能搜索系统 ✅
- [ ] **Agent协作系统** 🚧 进行中
- [ ] 数据可视化系统
- [ ] API网关

## 依赖
- PowerShell 5.1+
- OpenClaw环境
- 现有Agent系统

## 作者
灵眸
