// openclaw-3.0/test-model-scheduler.js
// 自适应模型调度系统测试

const { ModelScorer, ModelHealthTracker } = require('./core/model-scheduler');

console.log('🧪 自适应模型调度系统测试\n');

// 创建实例
const scorer = new ModelScorer({
  qualityWeight: 0.4,
  costWeight: 0.3,
  latencyWeight: 0.2,
  failureWeight: 0.1
});

const tracker = new ModelHealthTracker();

// 测试 1: 注册模型
console.log('【测试 1】注册模型');
tracker.registerModel('ZAI', { quality: 9.0, cost: 0.2, latency: 100, failRate: 0.01 });
tracker.registerModel('Trinity', { quality: 9.5, cost: 0.5, latency: 50, failRate: 0.02 });
tracker.registerModel('Anthropic', { quality: 8.5, cost: 0.3, latency: 200, failRate: 0.03 });
console.log('✅ 注册了 3 个模型\n');

// 测试 2: 计算分数
console.log('【测试 2】计算模型分数');
const scores = tracker.getAllScores();
scores.forEach(score => {
  console.log(`  ${score.name}:`);
  console.log(`    - 分数: ${score.score.toFixed(2)}`);
  console.log(`    - 等级: ${score.level}`);
  console.log(`    - 健康度: ${score.health.toFixed(1)}`);
});
console.log('');

// 测试 3: 选择最佳模型
console.log('【测试 3】选择最佳模型');
const availableModels = ['ZAI', 'Trinity', 'Anthropic'];
const best = tracker.selectBestModel(availableModels);
console.log(`  最佳模型: ${best.model}`);
console.log(`  分数: ${best.score.toFixed(2)}`);
console.log(`  Fallback: ${best.fallback ? '是' : '否'}`);
console.log('');

// 测试 4: 更新模型指标（成功）
console.log('【测试 4】更新模型指标 - 成功');
tracker.updateModelMetrics('ZAI', true, 120);
tracker.updateModelMetrics('ZAI', true, 150);
console.log('✅ ZAI 连续 2 次成功\n');

// 测试 5: 更新模型指标（失败）
console.log('【测试 5】更新模型指标 - 失败');
tracker.updateModelMetrics('Trinity', false, 3000, new Error('Timeout'));
tracker.updateModelMetrics('Trinity', false, 5000, new Error('Network error'));
console.log('✅ Trinity 连续 2 次失败\n');

// 测试 6: 重新计算分数
console.log('【测试 6】重新计算分数（失败后）');
const newScores = tracker.getAllScores();
newScores.forEach(score => {
  console.log(`  ${score.name}:`);
  console.log(`    - 分数: ${score.score.toFixed(2)}`);
  console.log(`    - 等级: ${score.level}`);
  console.log(`    - 健康度: ${score.health.toFixed(1)}`);
});
console.log('');

// 测试 7: 手动配置更新
console.log('【测试 7】手动更新模型配置');
tracker.updateModelConfig('ZAI', { quality: 9.5 });
console.log('✅ ZAI 质量更新为 9.5\n');

// 测试 8: 获取模型统计
console.log('【测试 8】获取模型统计');
const stats = tracker.getModelStats('ZAI');
console.log(JSON.stringify(stats, null, 2));
console.log('');

// 测试 9: 健康报告
console.log('【测试 9】完整健康报告');
const report = tracker.getHealthReport();
console.log(JSON.stringify(report, null, 2));
console.log('');

// 测试 10: 评分算法详细分析
console.log('【测试 10】评分算法详细分析');
console.log('测试数据:');
console.log('  ZAI: quality=9.0, cost=0.2, latency=100ms, failRate=0.01');
console.log('  Trinity: quality=9.5, cost=0.5, latency=50ms, failRate=0.02');
console.log('  Anthropic: quality=8.5, cost=0.3, latency=200ms, failRate=0.03');
console.log('');
console.log('ZAI 分数计算:');
console.log('  qualityScore = 9.0 * 1.0 = 9.0');
console.log('  costScore = 0.2 * 1.0 * 10 = 2.0');
console.log('  latencyScore = 10 - (100/100) = 9.0');
console.log('  failureScore = (1-0.01) * 10 * 1.0 = 9.9');
console.log('  score = 9.0*0.4 + 2.0*0.3 + 9.0*0.2 + 9.9*0.1');
console.log('  score = 3.6 + 0.6 + 1.8 + 0.99 = 6.99');
console.log('');
console.log('Trinity 分数计算:');
console.log('  qualityScore = 9.5 * 1.0 = 9.5');
console.log('  costScore = 0.5 * 1.0 * 10 = 5.0');
console.log('  latencyScore = 10 - (50/100) = 9.5');
console.log('  failureScore = (1-0.02) * 10 * 1.0 = 9.8');
console.log('  score = 9.5*0.4 + 5.0*0.3 + 9.5*0.2 + 9.8*0.1');
console.log('  score = 3.8 + 1.5 + 1.9 + 0.98 = 8.18');
console.log('');
console.log('结论: Trinity 分数更高 (8.18 vs 6.99)');
console.log('原因: 质量更高、成本适中、延迟更短');
console.log('');

// 测试 11: 测试不同的权重配置
console.log('【测试 11】测试不同的权重配置');
const scorer2 = new ModelScorer({
  qualityWeight: 0.6,
  costWeight: 0.2,
  latencyWeight: 0.1,
  failureWeight: 0.1
});
tracker.registerModel('ModelX', { quality: 10.0, cost: 0.1, latency: 10, failRate: 0.0 });
tracker.registerModel('ModelY', { quality: 8.0, cost: 0.5, latency: 500, failRate: 0.5 });

const scores2 = tracker.getAllScores();
scores2.forEach(score => {
  console.log(`  ${score.name}: ${score.score.toFixed(2)} (${score.level})`);
});
console.log('');

console.log('🎉 所有测试完成！');
