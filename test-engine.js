const StrategyEngine = require('./core/strategy-engine');

const engine = new StrategyEngine();

const metrics = { callsLastMinute: 85, currentSuccessRate: 0.945, currentCost: 2500, tokensUsed: 150000, remainingBudget: 50000, dailyBudget: 200000, remainingTokens: 40000, maxTokens: 40000 };
const context = { compressionLevel: 1, modelBias: 'NORMAL', budgetConstraints: { maxCost: 3000 } };

console.log('🧪 Strategy Engine 测试');
const strategies = engine.simulateScenarios(metrics, context);
console.log(`✅ 生成 ${strategies.length} 个策略`);

const evaluated = strategies.map(s => ({
  ...s,
  benefit: engine.evaluateBenefit(s, metrics, context),
  risk: engine.evaluateRisk(s, metrics, context),
  combinedScore: engine.calculateCombinedScore(s, metrics, context)
}));

evaluated.forEach(s => console.log(`${s.type}: 评分=${s.combinedScore.toFixed(2)}, 收益=${s.benefit.totalScore.toFixed(2)}, 风险=${s.risk.score.toFixed(2)}`));

const selected = engine.selectOptimalStrategy(evaluated, metrics, context);
console.log(`\n🎉 最优策略: ${selected.type}, 评分=${selected.combinedScore.toFixed(2)}`);
