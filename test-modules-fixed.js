/**
 * OpenClaw v4.0 核心模块简化测试脚本
 */

const fs = require('fs');
const path = require('path');

const results = {
  timestamp: new Date().toISOString(),
  coreModules: [],
  strategies: []
};

// 测试核心监控模块
console.log('=== 测试核心监控模块 ===\n');

try {
  const PerformanceMonitor = require('./core/monitoring/performance-monitor');
  const monitor = new PerformanceMonitor({ checkInterval: 5000 });
  setTimeout(() => {
    const status = monitor.getStatus();
    results.coreModules.push({
      module: 'performance-monitor',
      status: status.status,
      successRate: status.successRate,
      errorRate: status.errorRate,
      avgLatency: status.avgLatency,
      passed: status.status === 'OK' || status.status === 'WARNING'
    });
    monitor.reset();
  }, 3000);
} catch (e) {
  results.coreModules.push({
    module: 'performance-monitor',
    error: e.message,
    passed: false
  });
}

try {
  const MemoryMonitor = require('./core/monitoring/memory-monitor');
  const monitor = new MemoryMonitor({ checkInterval: 5000 });
  setTimeout(() => {
    const status = monitor.getStatus();
    results.coreModules.push({
      module: 'memory-monitor',
      status: status.status,
      heapUsage: status.heapUsagePercentage,
      leakDetection: status.leakDetection.hasLeak,
      passed: status.status !== 'CRITICAL'
    });
    monitor.reset();
  }, 3000);
} catch (e) {
  results.coreModules.push({
    module: 'memory-monitor',
    error: e.message,
    passed: false
  });
}

try {
  const APITracker = require('./core/monitoring/api-tracker');
  const tracker = new APITracker();
  // 模拟一些API调用
  setTimeout(() => {
    for (let i = 0; i < 10; i++) {
      tracker.recordCall('glm-4', '/chat/completions', Math.random() > 0.1, Math.floor(Math.random() * 500) + 50);
    }
    const status = tracker.getStatus();
    results.coreModules.push({
      module: 'api-tracker',
      status: status.status,
      successRate: parseFloat(status.successRate),
      avgLatency: parseInt(status.avgLatency),
      passed: status.successRate >= 0.7
    });
    tracker.reset();
  }, 1000);
} catch (e) {
  results.coreModules.push({
    module: 'api-tracker',
    error: e.message,
    passed: false
  });
}

// 测试策略引擎模块
console.log('\n=== 测试策略引擎模块 ===\n');

try {
  const ScenarioGenerator = require('./core/strategy/scenario-generator');
  const generator = new ScenarioGenerator();
  generator.generateScenarios({}, 3).then(scenarios => {
    results.strategies.push({
      module: 'scenario-generator',
      passed: scenarios.length === 3,
      scenarioCount: scenarios.length,
      strategies: scenarios.map(s => s.strategyType)
    });
  });
} catch (e) {
  results.strategies.push({
    module: 'scenario-generator',
    error: e.message,
    passed: false
  });
}

try {
  const ScenarioEvaluator = require('./core/strategy/scenario-evaluator');
  const evaluator = new ScenarioEvaluator();
  evaluator.evaluateScenario({}).then(result => {
    results.strategies.push({
      module: 'scenario-evaluator',
      passed: result !== null && result.score !== undefined,
      score: result ? result.score : null
    });
  });
} catch (e) {
  results.strategies.push({
    module: 'scenario-evaluator',
    error: e.message,
    passed: false
  });
}

try {
  const CostCalculator = require('./core/strategy/cost-calculator');
  const calculator = new CostCalculator();
  const result = calculator.estimateCost({});
  results.strategies.push({
    module: 'cost-calculator',
    passed: result.cost !== undefined && result.cost >= 0,
    estimatedCost: result ? result.cost : null
  });
} catch (e) {
  results.strategies.push({
    module: 'cost-calculator',
    error: e.message,
    passed: false
  });
}

try {
  const BenefitCalculator = require('./core/strategy/benefit-calculator');
  const calculator = new BenefitCalculator({ benefitWeight: 0.5 });
  const result = calculator.calculateTotalBenefit({});
  results.strategies.push({
    module: 'benefit-calculator',
    passed: result.benefit !== undefined && result.benefit >= 0,
    estimatedBenefit: result ? result.benefit : null
  });
} catch (e) {
  results.strategies.push({
    module: 'benefit-calculator',
    error: e.message,
    passed: false
  });
}

try {
  const ROIAnalyzer = require('./core/strategy/roi-analyzer');
  const analyzer = new ROIAnalyzer({ costWeight: 0.5 });
  const result = analyzer.calculateROI({ cost: 100, benefit: 200 });
  results.strategies.push({
    module: 'roi-analyzer',
    passed: result.roi !== undefined && result.roi >= 0,
    roi: result ? result.roi : null
  });
} catch (e) {
  results.strategies.push({
    module: 'roi-analyzer',
    error: e.message,
    passed: false
  });
}

try {
  const RiskAssessor = require('./core/strategy/risk-assessor');
  const assessor = new RiskAssessor();
  const result = assessor.assess({});
  results.strategies.push({
    module: 'risk-assessor',
    passed: result.riskLevel !== undefined,
    riskLevel: result ? result.riskLevel : null
  });
} catch (e) {
  results.strategies.push({
    module: 'risk-assessor',
    error: e.message,
    passed: false
  });
}

try {
  const StrategyEngineEnhanced = require('./core/strategy/strategy-engine-enhanced');
  const engine = new StrategyEngineEnhanced();
  const result = engine.getAvailableStrategies();
  results.strategies.push({
    module: 'strategy-engine-enhanced',
    passed: result && result.length > 0,
    strategiesCount: result ? result.length : 0
  });
} catch (e) {
  results.strategies.push({
    module: 'strategy-engine-enhanced',
    error: e.message,
    passed: false
  });
}

// 保存测试结果
fs.writeFileSync(
  path.join(__dirname, 'memory', 'module-test-results.json'),
  JSON.stringify(results, null, 2)
);

console.log('\n=== 测试完成 ===');
console.log(`核心模块测试完成: ${results.coreModules.filter(m => m.passed).length}/${results.coreModules.length}`);
console.log(`策略引擎测试完成: ${results.strategies.filter(m => m.passed).length}/${results.strategies.length}`);

// 生成摘要报告
const summary = {
  ...results,
  summary: {
    totalCore: results.coreModules.length,
    passedCore: results.coreModules.filter(m => m.passed).length,
    totalStrategy: results.strategies.length,
    passedStrategy: results.strategies.filter(m => m.passed).length,
    overall: (results.coreModules.filter(m => m.passed).length + results.strategies.filter(m => m.passed).length) /
             (results.coreModules.length + results.strategies.length) * 100
  }
};

fs.writeFileSync(
  path.join(__dirname, 'memory', 'module-test-summary.json'),
  JSON.stringify(summary, null, 2)
);

console.log(`总体通过率: ${summary.summary.overall.toFixed(2)}%`);
