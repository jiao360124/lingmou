# OpenClaw v4.0 方法名迁移指南

## 时间
2026-03-05T01:36:17.650Z

## 背景
为统一代码风格和接口，需要对策略引擎模块的方法名进行规范化。

## 统一规范

### 方法名命名规范
- **camelCase**: calculateCost, evaluateScenario
- **snake_case**: assess_risk, generate_scenarios

### 推荐方案
推荐使用 **camelCase**，因为：
- JavaScript 标准库使用 camelCase
- 更符合 JS 生态系统的习惯
- 易于理解和维护

### 参数规范
- 所有参数必须有默认值
- 参数类型应该明确
- 提供清晰的参数描述

## 模块迁移

### CostCalculator
```javascript
// 旧方法
const cost = calculator.calculate({ tokens: 1000 });

// 新方法
const cost = calculator.calculateCost({ tokens: 1000, model: 'glm-4' });
```

### BenefitCalculator
```javascript
// 旧方法
const benefit = calculator.calculateBenefit({ roi: 2.0 });

// 新方法
const benefit = calculator.calculateBenefit({ roi: 2.0, weight: 0.5 });
```

### RiskAssessor
```javascript
// 旧方法
const risk = assessor.assess({ riskFactors: ['high'] });

// 新方法
const risk = assessor.assessRisk({ riskFactors: ['high', 'medium'] });
```

## 迁移优先级
1. **高优先级**: 核心策略引擎模块
2. **中优先级**: 评估和计算模块
3. **低优先级**: 辅助模块

## 测试建议
- 为每个模块编写单元测试
- 验证向后兼容性
- 更新文档和示例代码
- 进行集成测试

## 注意事项
- 保持向后兼容，提供迁移通道
- 更新所有调用这些方法的地方
- 添加代码注释说明变化
- 版本控制，便于回滚
