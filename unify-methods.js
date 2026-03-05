/**
 * OpenClaw v4.0 方法名统一优化脚本
 *
 * 统一策略引擎模块的方法名和参数结构
 */

const fs = require('fs');
const path = require('path');

const results = {
  fixes: [],
  issues: []
};

// 方法名映射表
const methodMappings = {
  'cost-calculator': {
    calculate: 'estimateCost',
    calculateCost: 'calculateTotalCost'
  },
  'benefit-calculator': {
    calculateBenefit: 'calculateTotalBenefit'
  },
  'risk-assessor': {
    assess: 'assessRisk',
    getRisk: 'getRiskLevel'
  },
  'risk-controller': {
    control: 'controlRisk',
    selectRiskControl: 'selectRiskControlMethod'
  },
  'risk-adjusted-scorer': {
    calculate: 'calculateRiskAdjustedScore'
  },
  'adversary-simulator': {
    simulate: 'simulateAdversary',
    generateScenarios: 'generateAdversaryScenarios'
  },
  'multi-perspective-evaluator': {
    evaluate: 'evaluatePerspectives',
    evaluateScenario: 'evaluatePerspectives'
  },
  'scenario-generator': {
    generateScenarios: 'generateScenarios',
    createScenario: 'createScenario'
  },
  'scenario-evaluator': {
    evaluateScenario: 'evaluateScenario',
    calculate: 'calculateCostBenefitScore'
  }
};

// 参数结构优化
const paramStructures = {
  'generateScenarios': {
    require: ['strategies', 'count']
  },
  'evaluateScenario': {
    require: ['strategyType', 'cost', 'benefit', 'risk']
  },
  'assessRisk': {
    require: ['riskFactors']
  },
  'controlRisk': {
    require: ['riskLevel', 'action']
  }
};

console.log('=== 方法名统一优化 ===\n');

// 1. 分析方法名使用情况
console.log('1. 分析现有代码中的方法名使用\n');

Object.keys(methodMappings).forEach(moduleName => {
  const mapping = methodMappings[moduleName];
  console.log(`\n模块: ${moduleName}`);
  console.log('旧方法 → 新方法:');
  Object.entries(mapping).forEach(([oldMethod, newMethod]) => {
    console.log(`  ${oldMethod} → ${newMethod}`);
  });
});

// 2. 分析参数结构要求
console.log('\n2. 参数结构要求\n');
Object.entries(paramStructures).forEach(([methodName, structure]) => {
  console.log(`\n方法: ${methodName}`);
  console.log('必需参数:', structure.require.join(', '));
});

// 3. 生成修复建议
console.log('\n3. 修复建议\n');
console.log('以下模块需要统一方法名和参数结构:\n');

const modulesToFix = Object.keys(methodMappings);

modulesToFix.forEach(moduleName => {
  console.log(`\n【${moduleName}】`);
  console.log('建议的统一方案:');
  console.log('- 统一使用 snake_case 或 camelCase 方法名');
  console.log('- 明确定义参数结构');
  console.log('- 提供默认参数值');
  console.log('- 添加类型检查和错误处理');
});

// 4. 创建统一方法文档
const unifiedDoc = {
  timestamp: new Date().toISOString(),
  overview: '方法名统一规范',
  modules: methodMappings,
  parameterStructures: paramStructures,
  recommendations: [
    '所有公共方法使用 camelCase 或 snake_case，保持一致',
    '方法参数使用明确的类型和默认值',
    '所有方法返回结构化的结果对象',
    '添加错误处理和参数验证',
    '提供清晰的文档注释'
  ]
};

fs.writeFileSync(
  path.join(__dirname, 'memory', 'unified-methods-doc.md'),
  JSON.stringify(unifiedDoc, null, 2)
);

console.log('\n4. 已生成统一方法文档: memory/unified-methods-doc.md');

// 5. 生成迁移指南
const migrationGuide = `# OpenClaw v4.0 方法名迁移指南

## 时间
${new Date().toISOString()}

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
\`\`\`javascript
// 旧方法
const cost = calculator.calculate({ tokens: 1000 });

// 新方法
const cost = calculator.calculateCost({ tokens: 1000, model: 'glm-4' });
\`\`\`

### BenefitCalculator
\`\`\`javascript
// 旧方法
const benefit = calculator.calculateBenefit({ roi: 2.0 });

// 新方法
const benefit = calculator.calculateBenefit({ roi: 2.0, weight: 0.5 });
\`\`\`

### RiskAssessor
\`\`\`javascript
// 旧方法
const risk = assessor.assess({ riskFactors: ['high'] });

// 新方法
const risk = assessor.assessRisk({ riskFactors: ['high', 'medium'] });
\`\`\`

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
`;

fs.writeFileSync(
  path.join(__dirname, 'memory', 'method-migration-guide.md'),
  migrationGuide
);

console.log('已生成迁移指南: memory/method-migration-guide.md');
console.log('\n=== 优化完成 ===');
