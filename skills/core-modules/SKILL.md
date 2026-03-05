---
name: core-modules
description: OpenClaw v4.0 核心模块插件 - 注册策略引擎和监控模块为 Agent Tools。提供性能监控、内存监控、API追踪和完整策略引擎功能。
---

# OpenClaw v4.0 核心模块插件

## 概述

这是一个系统级插件，将 `core/strategy/` 和 `core/monitoring/` 目录中的所有模块注册为 Agent 可用的 Tools。这样 Agent 就能通过 LLM 的工具调用机制使用这些强大的功能。

## 模块列表

### 监控模块

- `performance-monitor` - 性能监控
  - API调用跟踪
  - 延迟统计
  - 错误率分析
  - 性能趋势分析

- `memory-monitor` - 内存监控
  - 内存使用跟踪
  - 泄漏检测
  - 垃圾回收统计
  - 资源管理

- `api-tracker` - API追踪
  - API调用统计
  - 模型性能分析
  - 端点监控
  - 吞吐量计算

### 策略引擎模块

- `scenario-generator` - 场景生成
  - 5种策略类型
  - 参数配置
  - 场景评估

- `scenario-evaluator` - 场景评估
  - 成本计算
  - 收益计算
  - ROI分析
  - 优先级排序

- `cost-calculator` - 成本计算
  - Token成本
  - 时间成本
  - 资源成本
  - 风险成本

- `benefit-calculator` - 收益计算
  - 基础收益
  - 效率收益
  - 长期收益
  - 满意度收益

- `roi-analyzer` - ROI分析
  - 投资回报率
  - 成本收益评分
  - 优先级评分
  - ROI等级评估

- `risk-assessor` - 风险评估
  - 风险因子识别
  - 风险等级评估
  - 风险量化

- `risk-controller` - 风险控制
  - 风险控制方法
  - 风险缓解策略
  - 控制效果评估

- `risk-adjusted-scorer` - 风险调整评分
  - 基础分数
  - 风险调整
  - 最终评分

- `adversary-simulator` - 对手模拟
  - 模拟对抗场景
  - 生成防御策略
  - 行为分析

- `multi-perspective-evaluator` - 多视角评估
  - 多角度分析
  - 视角融合
  - 综合评估

## 使用方式

### 直接调用 Tools

Agent 可以通过 LLM 的工具调用机制直接使用这些 Tools。示例：

```
Tool: strategy_scenario-generator
Parameters: { strategies: ["FAST_RESPONSE", "BALANCED"], count: 3 }

Tool: monitoring_performance-monitor
Parameters: {}

Tool: monitoring_api-tracker
Parameters: { model: "glm-4", endpoint: "/chat/completions" }
```

### 代码示例

```javascript
// 模拟 Agent 调用
const api = {
  registerTool: (tool) => {
    console.log('已注册工具:', tool.name);
  }
};

// 执行插件入口
const plugin = require('./core/plugin-entry.js');
plugin(api);
```

## 配置要求

### openclaw.json

插件需要以下配置（已自动配置）：

```json
{
  "plugins": {
    "entries": {
      "core-modules": {
        "enabled": true
      }
    }
  }
}
```

## 技术细节

### 插件实现

插件通过以下机制工作：

1. **动态加载** - 运行时动态加载 JS 模块
2. **实例化** - 为每个模块创建实例
3. **注册** - 将模块注册为 Agent Tool
4. **调用** - Agent 通过 API 调用工具

### 工具命名规范

- 监控模块: `monitoring_<module_name>`
- 策略模块: `strategy_<module_name>`

### 参数传递

所有工具使用统一的参数结构：

```json
{
  "type": "object",
  "properties": {},
  "required": []
}
```

## 功能特性

### 实时监控

- 自动收集性能指标
- 实时警报
- 趋势分析

### 策略分析

- 多维度评估
- 风险调整
- ROI计算

### 集成性

- 无缝集成到 Agent 系统
- 标准 Tool 接口
- 统一的调用方式

## 依赖项

- `winston` - 日志记录
- Node.js v16+

## 许可证

MIT

## 作者

Lingmou (灵眸)

## 版本

v4.0.0

## 更新日志

### v4.0.0 (2026-03-05)
- 初始版本
- 注册所有监控和策略引擎模块
- 提供 Agent Tool 接口
