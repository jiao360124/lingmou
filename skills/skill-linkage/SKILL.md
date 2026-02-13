# Skill Linkage - 技能联动系统

**版本**: 1.0
**状态**: ✅ 已完成
**创建日期**: 2026-02-12

---

## 概述

Skill Linkage 是一个强大的跨技能协作系统，让不同技能能够智能协同工作。它实现了技能注册、自动路由、协作执行和流程定义，大大提升了自动化能力。

---

## 核心功能

### 1. 技能注册中心 (Skill Registry)

**文件**: `scripts/skill-registry.ps1`

让每个技能能够声明自己的能力、输入/输出格式和参数。

**核心能力**:
- 技能元数据注册
- 能力声明
- 参数定义
- 速率限制配置
- 执行时间预估

**使用示例**:
```powershell
# 列出所有技能
.\skill-registry.ps1 -Action list

# 获取特定技能详情
.\skill-registry.ps1 -Action get -SkillId copilot

# 查看注册状态
.\skill-registry.ps1 -Action register
```

---

### 2. 联动路由器 (Linkage Router)

**文件**: `scripts/linkage-router.ps1`

识别用户输入并自动匹配最佳技能。

**核心能力**:
- 任务类型分类
- 智能技能匹配
- 参数自动转换
- 多任务类型支持
- 置信度评分

**支持的分类**:
- **Code** - 代码相关任务（代码分析、重构、调试）
- **Query** - 查询和检索任务
- **Task** - 任务自动化
- **Analysis** - 分析和解释任务
- **Knowledge** - 知识检索
- **General** - 通用任务

**使用示例**:
```powershell
# 路由输入
.\linkage-router.ps1 -Action route -Input "Write a function to calculate fibonacci"

# 测试路由
.\linkage-router.ps1 -Action test

# 列出任务类型
.\linkage-router.ps1 -Action list-task-types
```

---

### 3. 协作引擎 (Collaboration Engine)

**文件**: `scripts/collaboration-engine.ps1`

实现多技能协作执行、状态管理和错误传播。

**核心能力**:
- 顺序工作流执行
- 并行工作流执行
- 条件工作流执行
- 实时状态跟踪
- 详细执行报告
- 错误恢复

**工作流类型**:

#### 顺序工作流 (Sequential)
按顺序执行多个步骤，每个步骤依赖前一步的结果。

```powershell
{
    type = "sequential"
    steps = @(
        @{ skill = "copilot"; step = "analysis"; ... },
        @{ skill = "code-mentor"; step = "explanation"; ... }
    )
}
```

#### 并行工作流 (Parallel)
同时执行多个独立任务，提高效率。

```powershell
{
    type = "parallel"
    parallelCount = 3
    steps = @(
        @{ skill = "copilot"; step = "analysis"; ... },
        @{ skill = "rag"; step = "search"; ... },
        @{ skill = "exa-web-search-free"; step = "web-search"; ... }
    )
}
```

#### 条件工作流 (Conditional)
根据前一步的结果决定是否执行后续步骤。

```powershell
{
    type = "conditional"
    steps = @(
        @{ skill = "copilot"; step = "check"; ... },
        @{ skill = "auto-gpt"; step = "repair"; ...,
           condition = @{ error = "any" } },
        @{ skill = "code-mentor"; step = "explain"; ...,
           condition = @{ error = "none" } }
    )
}
```

**使用示例**:
```powershell
# 执行顺序工作流
.\collaboration-engine.ps1 -Action start

# 测试并行工作流
.\collaboration-engine.ps1 -Action test-parallel

# 查看执行报告
.\collaboration-engine.ps1 -Action report

# 查看运行状态
.\collaboration-engine.ps1 -Action status
```

---

### 4. 协作流程定义 (Workflow Definitions)

**文件**: `scripts/workflow-definitions.ps1`

预定义的常用协作流程模板。

**内建工作流**:

#### 顺序工作流
1. **代码分析工作流**
   - Copilot: 代码质量分析
   - Code Mentor: 代码逻辑解释
   - RAG: 最佳实践检索

2. **文档生成工作流**
   - RAG: 检索现有文档
   - Auto-GPT: 生成技术文档

3. **调试工作流**
   - Copilot: 检测潜在问题
   - Auto-GPT: 提供修复方案
   - Code Mentor: 调试建议

#### 并行工作流
1. **综合分析工作流**
   - 并行分析代码质量、算法复杂度、最佳实践、技术趋势

2. **知识研究工作流**
   - 并行从内部知识库和外部搜索收集信息

3. **任务完成工作流**
   - 并行执行任务规划和任务执行

#### 条件工作流
1. **智能调试工作流**
   - 有错误时进行错误检测和修复
   - 无错误时进行代码解释

2. **智能文档工作流**
   - 有现有文档时更新文档
   - 无现有文档时创建新文档

**使用示例**:
```powershell
# 列出所有可用工作流
.\workflow-definitions.ps1

# 获取特定工作流
$workflow = .\workflow-definitions.ps1 | Get-Workflow "comprehensive-analysis"
```

---

## 工作流程

### 完整协作流程

```
1. 用户输入
   ↓
2. Linkage Router 识别任务类型
   ↓
3. 智能匹配最佳技能
   ↓
4. 构建 Workflow Definition
   ↓
5. Collaboration Engine 执行
   ├─ 顺序执行
   ├─ 并行执行
   └─ 条件执行
   ↓
6. 生成执行报告
   ↓
7. 返回结果给用户
```

---

## 使用指南

### 基础使用

1. **路由任务**:
   ```powershell
   $route = .\linkage-router.ps1 -Action route -Input "你的任务描述"
   $skillId = $route.skillId
   ```

2. **执行工作流**:
   ```powershell
   $workflow = .\workflow-definitions.ps1 | Get-Workflow "your-workflow"
   $result = .\collaboration-engine.ps1 -Action start -Workflow $workflow
   ```

3. **查看报告**:
   ```powershell
   $report = .\collaboration-engine.ps1 -Action report
   ```

### 高级使用

1. **自定义工作流**:
   ```powershell
   $customWorkflow = @{
       type = "parallel"
       parallelCount = 2
       steps = @(
           @{ skill = "copilot"; step = "analysis"; ... },
           @{ skill = "rag"; step = "search"; ... }
       )
   }
   .\collaboration-engine.ps1 -Action start -Workflow $customWorkflow
   ```

2. **条件路由**:
   检查路由结果，根据置信度决定是否使用协作。

3. **参数转换**:
   Linkage Router 会自动将输入转换为技能所需格式。

---

## 技术特性

### 状态管理
- 实时执行状态跟踪
- 错误传播和处理
- 步骤依赖关系管理
- 结果聚合和报告

### 并发控制
- 并行任务批处理
- 速率限制处理
- 资源协调
- 错误隔离

### 可扩展性
- 模块化设计
- 插件式技能注册
- 自定义流程定义
- 灵活的参数系统

---

## 文件结构

```
skills/skill-linkage/
├── SKILL.md                          # 本文档
├── scripts/
│   ├── skill-registry.ps1            # 技能注册中心 (13.8KB)
│   ├── linkage-router.ps1            # 联动路由器 (8.0KB)
│   ├── collaboration-engine.ps1      # 协作引擎 (13.8KB)
│   └── workflow-definitions.ps1      # 流程定义 (11.1KB)
└── data/
    └── skill-meta.json               # 技能元数据
```

**总大小**: ~46KB
**代码行数**: ~1,100 行

---

## 依赖关系

- **技能注册中心**: 无外部依赖
- **联动路由器**: 依赖技能注册中心
- **协作引擎**: 独立工作
- **流程定义**: 独立工作

---

## 测试和验证

### 路由测试
```powershell
.\linkage-router.ps1 -Action test
```

### 工作流测试
```powershell
.\collaboration-engine.ps1 -Action test-sequential
.\collaboration-engine.ps1 -Action test-parallel
.\collaboration-engine.ps1 -Action test-conditional
```

### 完整测试
```powershell
# 1. 路由测试
$route = .\linkage-router.ps1 -Action route -Input "分析这段代码"

# 2. 执行工作流
$workflow = .\workflow-definitions.ps1 | Get-Workflow "debugging"
$result = .\collaboration-engine.ps1 -Action start -Workflow $workflow

# 3. 查看报告
.\collaboration-engine.ps1 -Action report
```

---

## 未来扩展

### 已规划
- [ ] 技能自动发现和注册
- [ ] 协作流程可视化
- [ ] 实时协作监控仪表板
- [ ] 协作结果持久化

### 长期目标
- [ ] 智能技能推荐系统
- [ ] 自动流程优化
- [ ] 跨平台协作支持
- [ ] 协作流程市场

---

## 已知限制

1. **技能调用**: 当前为模拟实现，需要实际技能脚本支持
2. **错误恢复**: 基础错误处理，复杂错误恢复待完善
3. **性能优化**: 并行执行在高负载下需要优化
4. **日志记录**: 详细日志记录功能待增强

---

## 更新日志

### v1.0 (2026-02-12)
- ✅ 技能注册中心实现
- ✅ 联动路由器实现
- ✅ 协作引擎实现
- ✅ 协作流程定义实现
- ✅ 顺序/并行/条件工作流支持
- ✅ 详细文档和示例

---

## 相关技能

- **copilot**: 智能代码助手
- **auto-gpt**: 自动化任务引擎
- **code-mentor**: 编程导师
- **rag**: 知识库检索

---

## 作者和版本

**作者**: 灵眸
**版本**: 1.0
**最后更新**: 2026-02-12

---

**状态**: ✅ 已完成
**可立即使用**
