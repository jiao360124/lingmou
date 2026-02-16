const CognitiveLayer = require('./memory/cognitive-layer');

console.log('🧪 Cognitive Layer 测试\n');

const layer = new CognitiveLayer();

// 测试1: 任务模式识别
console.log('📊 测试1: 任务模式识别');
console.log('='.repeat(60));

const task1 = {
  description: '优化数据库查询性能，添加索引，减少查询时间',
  type: 'optimization',
  complexity: 3,
  successRate: 0.95,
  executionTime: 150
};

const task2 = {
  description: '修复API响应超时问题，检查服务器负载',
  type: 'bug_fix',
  complexity: 2,
  successRate: 0.90,
  executionTime: 120
};

const task3 = {
  description: '优化前端页面加载速度，减少资源请求',
  type: 'optimization',
  complexity: 2,
  successRate: 0.88,
  executionTime: 100
};

console.log('📝 记录任务 1:', task1.description);
layer.recordTaskPattern(task1, { success: true, successRate: 0.95, executionTime: 150 });

console.log('📝 记录任务 2:', task2.description);
layer.recordTaskPattern(task2, { success: true, successRate: 0.90, executionTime: 120 });

console.log('📝 记录任务 3:', task3.description);
layer.recordTaskPattern(task3, { success: false, successRate: 0.88, executionTime: 100 });

console.log(`✅ 已记录 ${layer.getStatistics().taskPatterns} 个任务模式\n`);

// 测试2: 用户行为画像
console.log('📊 测试2: 用户行为画像');
console.log('='.repeat(60));

const userInteractions = [
  { timestamp: Date.now() - 3600000, intent: 'help', responseStyle: 'detailed' },
  { timestamp: Date.now() - 1800000, intent: 'optimize', responseStyle: 'concise' },
  { timestamp: Date.now() - 900000, intent: 'help', responseStyle: 'detailed' },
  { timestamp: Date.now() - 600000, intent: 'bug', responseStyle: 'detailed' },
  { timestamp: Date.now() - 300000, intent: 'optimize', responseStyle: 'concise' },
  { timestamp: Date.now() - 120000, intent: 'help', responseStyle: 'detailed' },
  { timestamp: Date.now() - 60000, intent: 'optimize', responseStyle: 'concise' }
];

const profile = layer.buildUserProfile({
  userId: 'user_123',
  interactions: userInteractions
});

if (profile) {
  console.log('✅ 用户画像创建成功');
  console.log('  交互次数:', profile.interactionCount);
  console.log('  主要意图:', profile.behavior.intentDominant);
  console.log('  响应风格:', profile.behavior.responseStyleDominant);
  console.log('  活跃时段:', profile.behavior.timePeak);
} else {
  console.log('⚠️  交互次数不足，无法创建画像');
}
console.log('');

// 测试3: 结构化经验记录
console.log('📊 测试3: 结构化经验记录');
console.log('='.repeat(60));

const strategy = {
  type: 'BALANCED',
  delay: 150,
  compressionLevel: 1,
  modelBias: 'NORMAL'
};

const outcome = {
  success: true,
  successRate: 0.96,
  executionTime: 120,
  metrics: { tokensUsed: 5000, cost: 2.5 }
};

const experienceId = layer.storeStructuredExperience(
  'PATTERN_001',
  strategy,
  outcome
);

console.log('✅ 经验记录成功');
console.log('  经验ID:', experienceId);
console.log('  策略类型:', strategy.type);
console.log('  成功率:', outcome.successRate);
console.log('');

// 测试4: 失败模式记录
console.log('📊 测试4: 失败模式记录');
console.log('='.repeat(60));

const failures = [
  { reason: 'timeout - 请求超时', triggerCondition: 'high_load' },
  { reason: 'timeout - 响应慢', triggerCondition: 'network_latency' },
  { reason: 'cost - token预算超支', triggerCondition: 'high_complexity' }
];

const patternId = layer.recordFailurePattern(failures);

if (patternId) {
  const pattern = layer.failureDatabase.find(f => f.id === patternId);
  console.log('✅ 失败模式记录成功');
  console.log('  模式ID:', patternId);
  console.log('  总失败次数:', pattern.totalFailures);
  console.log('  失败原因分类:', pattern.abstractPattern.categories);
  console.log('  主要类别:', pattern.abstractPattern.mostCommonCategory);
  console.log('');
} else {
  console.log('⚠️  失败次数不足，无法创建模式');
}
console.log('');

// 测试5: 获取推荐策略
console.log('📊 测试5: 推荐策略生成');
console.log('='.repeat(60));

const newTask = '优化API响应性能，减少数据库查询时间';

const recommendation = layer.getRecommendedStrategy(newTask);

console.log('✅ 推荐策略生成成功');
console.log('  推荐来源:', recommendation.source);
console.log('  策略类型:', recommendation.strategy?.type || 'N/A');
console.log('  置信度:', recommendation.confidence.toFixed(2));
console.log('  任务描述:', newTask);
console.log('');

// 测试6: 失败规避建议
console.log('📊 测试6: 失败规避建议');
console.log('='.repeat(60));

const advice = layer.getFailureAvoidanceAdvice(newTask);

if (advice) {
  console.log('✅ 失败规避建议生成成功');
  console.log('  相关模式数量:', advice.patterns.length);

  if (advice.warnings.length > 0) {
    console.log('  ⚠️  警告:');
    advice.warnings.forEach(w => console.log(`    - ${w}`));
  }

  if (advice.recommendations.length > 0) {
    console.log('  💡 建议:');
    advice.recommendations.forEach(r => console.log(`    - ${r}`));
  }
} else {
  console.log('⚠️  没有相关的失败模式');
}
console.log('');

// 测试7: 认知层统计
console.log('📊 测试7: 认知层统计');
console.log('='.repeat(60));

const stats = layer.getStatistics();

console.log('✅ 认知层统计信息:');
console.log('  任务模式数量:', stats.taskPatterns);
console.log('  用户画像数量:', stats.userProfiles);
console.log('  结构化经验数量:', stats.experienceLibrary);
console.log('  失败模式数量:', stats.failureDatabase);
console.log('  任务模式类型分布:', stats.taskPatternTypes);
console.log('  行为风格分布:', stats.behaviorProfileDominantStyles);
console.log('');

console.log('='.repeat(60));
console.log('🎉 所有认知层测试完成！');
console.log('='.repeat(60));
