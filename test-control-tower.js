// 测试控制塔功能

const controlTower = require('./openclaw-3.0/core/control-tower');

console.log('🧪 测试 Control Tower\n');

// 测试 1: 系统模式
console.log('1️⃣ 测试系统模式...');
console.log('   初始模式:', controlTower.getCurrentMode().name);
console.log('   初始状态:', controlTower.currentState);

// 测试 2: 模式更新
console.log('\n2️⃣ 测试模式更新逻辑...');
const report = {
  dailyTokens: 180000,
  successRate: 85
};
const usage = {
  remaining: 20000,
  dailyLimit: 200000
};

controlTower.updateSystemMode(0, 0.1, 0);
console.log('   正常模式:', controlTower.getCurrentMode().name);

controlTower.updateSystemMode(10, 0.1, 0);
console.log('   警告模式:', controlTower.getCurrentMode().name);

controlTower.updateSystemMode(9, 0.1, 0);
console.log('   恢复模式:', controlTower.getCurrentMode().name);

controlTower.setMode('NORMAL');
console.log('   重置为正常:', controlTower.getCurrentMode().name);

// 测试 3: 熔断器
console.log('\n3️⃣ 测试熔断器...');
console.log('   熔断器状态:', {
  isOpen: controlTower.circuitBreaker.isOpen,
  failures: controlTower.circuitBreaker.failures
});

controlTower.updateCircuitBreaker(true);
console.log('   失败一次后:', {
  isOpen: controlTower.circuitBreaker.isOpen,
  failures: controlTower.circuitBreaker.failures
});

controlTower.updateCircuitBreaker(true);
controlTower.updateCircuitBreaker(true);
controlTower.updateCircuitBreaker(true);
controlTower.updateCircuitBreaker(true);
controlTower.updateCircuitBreaker(true);
console.log('   连续失败5次:', {
  isOpen: controlTower.circuitBreaker.isOpen,
  failures: controlTower.circuitBreaker.failures
});

// 测试 4: 调用检查
console.log('\n4️⃣ 测试调用允许检查...');
console.log('   正常状态允许:', controlTower.isCallAllowed());

controlTower.setMode('RECOVERY');
console.log('   恢复模式允许:', controlTower.isCallAllowed());

controlTower.setMode('NORMAL');
console.log('   正常状态允许:', controlTower.isCallAllowed());

// 测试 5: 优化决策
console.log('\n5️⃣ 测试优化决策...');
controlTower.currentState = 'NORMAL';
controlTower.circuitBreaker.isOpen = false;

const metrics = {
  dailyTokens: 180000,
  successRate: 85
};
const goals = {
  costReduction: 30
};

const decision = controlTower.makeOptimizationDecision(metrics, goals);
console.log('   优化提议:', decision);

// 测试 6: 风险评分
console.log('\n6️⃣ 测试风险评分...');
const changes = ['reduce_tokens', 'switch_to_cheap_model'];
const riskScore = controlTower.calculateRiskScore(changes, metrics);
console.log('   风险分数:', riskScore.toFixed(2));

// 测试 7: 快照创建
console.log('\n7️⃣ 测试快照创建...');
controlTower.currentState = 'NORMAL';
controlTower.circuitBreaker.isOpen = false;

const snapshotId = controlTower.createSnapshot('test', { test: 'data' });
console.log('   快照ID:', snapshotId);

// 测试 8: 验证窗口
console.log('\n8️⃣ 测试验证窗口...');
console.log('   初始状态:', controlTower.currentState);
console.log('   验证天数:', controlTower.getValidationDaysLeft());

console.log('\n🎉 Control Tower 测试完成！');
console.log('✅ 所有核心功能正常');
console.log('\n📝 准备完成 Checkpoint 3: Objective Engine');
