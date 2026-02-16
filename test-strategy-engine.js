/**
 * 测试 Strategy Engine
 */

const StrategyEngine = require('./core/strategy-engine');

// 创建策略引擎实例
const engine = new StrategyEngine({
  riskWeight: 0.3,
  benefitWeight: 0.7
});

// 模拟系统指标
const mockMetrics = {
  callsLastMinute: 85,
  currentSuccessRate: 0.945,
  currentCost: 2500,
  tokensUsed: 150000,
  remainingBudget: 50000,
  dailyBudget: 200000,
  remainingTokens: 40000,
  maxTokens: 40000
};

// 模拟运行上下文
const mockContext = {
  compressionLevel: 1,
  modelBias: 'NORMAL',
  budgetConstraints: {
    maxCost: 3000
  }
};

console.log('🧪 Strategy Engine 测试开始\n');

// 测试1: 基本策略生成
console.log('📊 测试1: 基本策略生成');
console.log('='.repeat(60));

const strategies = engine.simulateScenarios(mockMetrics, mockContext);

console.log(`✅ 生成了 ${strategies.length} 个策略:\n`);

strategies.forEach((strategy, index) => {
  console.log(`${index + 1}. [${strategy.type}] ${strategy.label}`);
  console.log(`   ID: ${strategy.id}`);
  console.log(`   描述: ${strategy.description}`);
  console.log(`   延迟: ${strategy.delay}ms`);
  console.log(`   压缩等级: ${strategy.compressionLevel}`);
  console.log(`   模型偏置: ${strategy.modelBias}`);
  console.log(`   预估成本: ${strategy.estimatedCost}`);
  console.log(`   预期成功率: ${(strategy.expectedSuccessRate * 100).toFixed(2)}%`);
  console.log('');
});

// 测试2: 策略评估
console.log('📊 测试2: 策略收益与风险评估');
console.log('='.repeat(60));

const evaluatedStrategies = strategies.map(strategy => ({
  ...strategy,
  benefit: engine.evaluateBenefit(strategy, mockMetrics, mockContext),
  risk: engine.evaluateRisk(strategy, mockMetrics, mockContext),
  combinedScore: engine.calculateCombinedScore(strategy, mockMetrics, mockContext)
}));

console.log('收益评分详情:\n');
evaluatedStrategies.forEach((s, index) => {
  console.log(`${index + 1}. [${s.type}] 综合评分: ${s.combinedScore.toFixed(2)}`);
  console.log(`   收益: ${s.benefit.totalScore.toFixed(2)}`);
  console.log(`   风险: ${s.risk.score.toFixed(2)}`);
  console.log(`   风险等级: ${s.risk.level}`);
  console.log('');
});

console.log('风险评分详情:\n');
evaluatedStrategies.forEach((s, index) => {
  console.log(`${index + 1}. [${s.type}] 风险评分: ${s.risk.score.toFixed(2)}`);
  console.log(`   等级: ${s.risk.level}`);
  console.log(`   成功率风险: ${(s.risk.details.successRate * 100).toFixed(2)}%`);
  console.log(`   成本风险: ${(s.risk.details.costRatio * 100).toFixed(2)}%`);
  console.log(`   延迟风险: ${(s.risk.details.delayRatio * 100).toFixed(2)}%`);
  console.log('');
});

// 测试3: 最优策略选择
console.log('🎯 测试3: 最优策略选择');
console.log('='.repeat(60));

const selectedStrategy = engine.selectOptimalStrategy(
  evaluatedStrategies,
  mockMetrics,
  mockContext
);

console.log('✅ 选定的最优策略:\n');
console.log(`类型: ${selectedStrategy.type}`);
console.log(`标签: ${selectedStrategy.label}`);
console.log(`ID: ${selectedStrategy.id}`);
console.log(`综合评分: ${selectedStrategy.combinedScore.toFixed(2)}`);
console.log(`延迟: ${selectedStrategy.delay}ms`);
console.log(`压缩等级: ${selectedStrategy.compressionLevel}`);
console.log(`模型偏置: ${selectedStrategy.modelBias}`);
console.log(`预估成本: ${selectedStrategy.estimatedCost}`);
console.log(`预期成功率: ${(selectedStrategy.expectedSuccessRate * 100).toFixed(2)}%`);
console.log('');
console.log('收益详情:');
console.log(`  总分: ${selectedStrategy.benefit.totalScore.toFixed(2)}`);
console.log(`  成功率收益: ${selectedStrategy.benefit.details.successRateGain}`);
console.log(`  成本节约: ${selectedStrategy.benefit.details.costReduction}`);
console.log(`  速度提升: ${selectedStrategy.benefit.details.delayImprovement}`);
console.log(`  压缩改进: ${selectedStrategy.benefit.details.compressionImprovement}`);
console.log('');
console.log('风险详情:');
console.log(`  总分: ${selectedStrategy.risk.score.toFixed(2)}`);
console.log(`  等级: ${selectedStrategy.risk.level}`);
console.log(`  成功率风险: ${selectedStrategy.risk.details.successRate}`);
console.log(`  成本风险: ${selectedStrategy.risk.details.costRatio}`);
console.log('');

// 测试4: 完整流程
console.log('🔄 测试4: 完整策略生成与选择流程');
console.log('='.repeat(60));

const finalStrategy = engine.generateAndSelectStrategy(
  mockMetrics,
  mockContext
);

console.log('\n✅ 完整流程测试通过！');
console.log('\n选定策略详情:');
console.log(`ID: ${finalStrategy.id}`);
console.log(`类型: ${finalStrategy.type}`);
console.log(`标签: ${finalStrategy.label}`);
console.log(`综合评分: ${finalStrategy.combinedScore.toFixed(2)}`);
console.log(`收益评分: ${finalStrategy.benefit.totalScore.toFixed(2)}`);
console.log(`风险评分: ${finalStrategy.risk.score.toFixed(2)}`);
console.log(`风险等级: ${finalStrategy.risk.level}`);

console.log('\n' + '='.repeat(60));
console.log('🎉 所有测试完成！');
console.log('='.repeat(60));
