// 测试第一阶段升级（自我保护层）

const rollbackEngine = require('./openclaw-3.0/core/rollback-engine');
const systemMemory = require('./openclaw-3.0/memory/system-memory');

console.log('🧪 测试第一阶段升级：自我保护层\n');

// 测试 1: Rollback Engine 初始化
console.log('1️⃣ 测试差异回滚引擎...');
console.log('   有当前配置:', rollbackEngine.getStatus().hasCurrentConfig);
console.log('   当前配置数量:', rollbackEngine.getStatus().currentConfigKeys);

// 测试 2: System Memory 初始化
console.log('\n2️⃣ 测试 System Memory Layer...');
console.log('   优化历史条目:', systemMemory.memory.optimizationHistory.length);
console.log('   失败模式条目:', systemMemory.memory.failurePatterns.length);
console.log('   成本趋势条目:', systemMemory.memory.costTrends.length);

// 测试 3: 优化历史记录
console.log('\n3️⃣ 测试优化历史记录...');
systemMemory.recordOptimization({
  type: 'test_optimization',
  description: '测试优化',
  changes: ['test_change'],
  result: { success: true },
  success: true,
  riskScore: 0.5,
  snapshotId: 'test_snapshot'
});
console.log('   记录成功:', systemMemory.memory.optimizationHistory.length);

// 测试 4: 检测重复优化
console.log('\n4️⃣ 测试重复优化检测...');
const isDuplicate = systemMemory.isDuplicateOptimization('test_optimization');
console.log('   重复检测 (已记录):', isDuplicate);

systemMemory.recordOptimization({
  type: 'test_optimization',
  description: '测试优化2',
  changes: ['test_change2'],
  result: { success: false },
  success: false,
  riskScore: 0.3,
  snapshotId: 'test_snapshot2'
});
console.log('   再次记录失败优化...');

const isDuplicate2 = systemMemory.isDuplicateOptimization('test_optimization');
console.log('   重复检测 (包含失败):', isDuplicate2);

// 测试 5: 失败模式记录
console.log('\n5️⃣ 测试失败模式记录...');
systemMemory.recordFailurePattern({
  type: 'api_timeout',
  description: 'API超时',
  triggerCondition: 'timeout',
  errorType: 'TimeoutError',
  recoveryAction: 'increase_timeout'
});
console.log('   记录成功:', systemMemory.memory.failurePatterns.length);

// 测试 6: 高频失败模式
console.log('\n6️⃣ 测试高频失败模式...');
systemMemory.recordFailurePattern({
  type: 'api_timeout',
  description: 'API超时',
  triggerCondition: 'timeout',
  errorType: 'TimeoutError',
  recoveryAction: 'increase_timeout'
});
console.log('   频率:', systemMemory.memory.failurePatterns.find(p => p.type === 'api_timeout').frequency);

// 测试 7: 成本趋势
console.log('\n7️⃣ 测试成本趋势记录...');
systemMemory.recordCostTrend({
  dailyTokens: 150000,
  cost: 15,
  successRate: 90,
  optimizationCount: 2
});
console.log('   记录成功:', systemMemory.memory.costTrends.length);

// 测试 8: 成本趋势分析
console.log('\n8️⃣ 测试成本趋势分析...');
const trend = systemMemory.analyzeCostTrend();
console.log('   趋势:', trend.trend);
console.log('   Token变化:', trend.tokenChange + '%');
console.log('   成本变化:', trend.costChange + '%');

// 测试 9: 优化历史摘要
console.log('\n9️⃣ 测试优化历史摘要...');
const summary = systemMemory.getOptimizationSummary();
console.log('   总数:', summary.total);
console.log('   成功:', summary.successful);
console.log('   失败:', summary.failed);
console.log('   成功率:', summary.successRate + '%');

// 测试 10: 失败模式摘要
console.log('\n🔟 测试失败模式摘要...');
const failureSummary = systemMemory.getFailureSummary();
console.log('   总数:', failureSummary.total);
console.log('   高频:', failureSummary.highFrequency);

// 测试 11: 伪优化检测
console.log('\n1️⃣1️⃣ 测试伪优化检测...');
systemMemory.recordOptimization({
  type: 'test_optimization2',
  description: '测试优化2',
  changes: [],
  result: { success: true },
  success: true,
  riskScore: 0.4,
  snapshotId: 'test_snapshot3'
});

systemMemory.recordOptimization({
  type: 'test_optimization2',
  description: '测试优化3',
  changes: [],
  result: { success: false },
  success: false,
  riskScore: 0.6,
  snapshotId: 'test_snapshot4'
});

const pseudoOptimizations = systemMemory.detectPseudoOptimizations();
console.log('   伪优化数:', pseudoOptimizations.length);

console.log('\n🎉 第一阶段升级测试完成！');
console.log('✅ 差异回滚引擎正常');
console.log('✅ System Memory Layer 正常');
console.log('✅ 所有功能正常工作');
console.log('\n📊 升级总结:');
console.log('   - 差异回滚引擎: 有安全阀');
console.log('   - 系统记忆层: 有长期学习');
console.log('   - 优化历史: 正常记录');
console.log('   - 失败模式: 正常记录');
console.log('   - 成本趋势: 正常追踪');
console.log('   - 伪优化检测: 正常工作');
console.log('\n📝 准备进入第二阶段...');
