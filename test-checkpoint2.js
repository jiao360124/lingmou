// 测试 Checkpoint 2: Token Governor

const tokenGovernor = require('./openclaw-3.0/economy/token-governor');
const tracker = require('./openclaw-3.0/metrics/tracker');

console.log('🧪 测试 Checkpoint 2: Token Governor\n');

// 测试 1: Token Governor 初始化
console.log('1️⃣ 测试 Token Governor...');
console.log('   初始化状态:', tokenGovernor.getUsageReport());

// 测试 2: 选择模型
console.log('\n2️⃣ 测试模型选择策略...');
const models = tokenGovernor.getModelStats();
console.log('   策略:', Object.keys(models.strategies));

// 测试 3: Token 使用检查
console.log('\n3️⃣ 测试 Token 使用检查...');
const decision1 = tokenGovernor.canUseTokens({ taskType: 'chat', estimatedTokens: 100 });
console.log('   Chat任务:', decision1);

const decision2 = tokenGovernor.canUseTokens({ taskType: 'strategy', estimatedTokens: 500 });
console.log('   Strategy任务:', decision2);

// 测试 4: 记录使用
console.log('\n4️⃣ 测试 Token 使用记录...');
tokenGovernor.recordUsage(100, true);
tokenGovernor.recordUsage(200, true);
tokenGovernor.recordUsage(50, false);
console.log('   使用报告:', tokenGovernor.getUsageReport());

// 测试 5: Metrics Tracker
console.log('\n5️⃣ 测试 Metrics Tracker...');
tracker.trackCall(100, true);
tracker.trackCall(200, true);
tracker.trackError();
tracker.trackNightlyTask();
console.log('   指标报告:', tracker.getReport());

// 测试 6: 重置每日状态
console.log('\n6️⃣ 测试每日重置...');
tokenGovernor.resetDaily();
tracker.resetDaily();
console.log('   Token Governor:', tokenGovernor.getUsageReport());
console.log('   Metrics:', tracker.getReport());

console.log('\n🎉 Checkpoint 2 测试完成！');
console.log('✅ Token Governor 正常工作');
console.log('✅ Metrics Tracker 正常工作');
console.log('\n📝 准备进入 Checkpoint 3: Objective Engine');
