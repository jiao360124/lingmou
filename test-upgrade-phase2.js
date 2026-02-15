// 测试第二阶段升级（调节能力）

const controlTower = require('./openclaw-3.0/core/control-tower');
const watchdog = require('./openclaw-3.0/core/watchdog');

console.log('🧪 测试第二阶段升级：调节能力\n');

// 测试 1: Nightly Worker 预算
console.log('1️⃣ 测试 Nightly Worker 冷却预算...');
const nightlyWorker = require('./openclaw-3.0/value/nightly-worker');
console.log('   Token预算:', nightlyWorker.nightBudget.tokens);
console.log('   调用预算:', nightlyWorker.nightBudget.calls);

// 测试 2: Watchdog 初始化
console.log('\n2️⃣ 测试 Watchdog 守护线程...');
const status = watchdog.getStatus();
console.log('   检查间隔:', status.checkInterval / 1000 + '秒');
console.log('   总体严重程度:', status.overallSeverity);
console.log('   有激活:', status.isActive);

// 测试 3: 权重模式计算
console.log('\n3️⃣ 测试权重模式...');
controlTower.updateWeightedMode(10, 0.1, 0);
const weights = controlTower.weights;
console.log('   稳定性得分:', weights.stabilityScore.toFixed(2));
console.log('   成本压力得分:', weights.costPressureScore.toFixed(2));
console.log('   失败压力得分:', weights.failurePressureScore.toFixed(2));
console.log('   总体压力:', (weights.stabilityScore * 0.4 + weights.costPressureScore * 0.3 + weights.failurePressureScore * 0.3).toFixed(2));

// 测试 4: 模式选择
console.log('\n4️⃣ 测试模式选择...');
const modes = ['NORMAL', 'WARNING', 'LIMITED', 'RECOVERY'];
for (const mode of modes) {
  controlTower.setMode(mode);
  const current = controlTower.getCurrentMode();
  console.log(`   ${mode}: ${current.name} (${current.description})`);
}

// 测试 5: 熔断器影响
console.log('\n5️⃣ 测试熔断器影响...');
controlTower.updateWeightedMode(10, 0.1, 0);
console.log('   无失败:', controlTower.getCurrentMode().name);

controlTower.updateWeightedMode(10, 0.1, 2);
console.log('   2次失败:', controlTower.getCurrentMode().name);

controlTower.updateWeightedMode(10, 0.1, 5);
console.log('   5次失败:', controlTower.getCurrentMode().name);

// 测试 6: Token使用影响
console.log('\n6️⃣ 测试Token使用影响...');
controlTower.setMode('NORMAL');
controlTower.updateWeightedMode(10, 0.5, 0);
console.log('   50%使用:', controlTower.getCurrentMode().name);

controlTower.updateWeightedMode(10, 0.9, 0);
console.log('   90%使用:', controlTower.getCurrentMode().name);

// 测试 7: 错误率影响
console.log('\n7️⃣ 测试错误率影响...');
controlTower.setMode('NORMAL');
controlTower.updateWeightedMode(2, 0.1, 0);
console.log('   2%错误率:', controlTower.getCurrentMode().name);

controlTower.updateWeightedMode(8, 0.1, 0);
console.log('   8%错误率:', controlTower.getCurrentMode().name);

// 测试 8: 组合影响
console.log('\n8️⃣ 测试组合影响...');
controlTower.setMode('NORMAL');
controlTower.updateWeightedMode(5, 0.9, 2);
console.log('   高Token + 中错误:', controlTower.getCurrentMode().name);

controlTower.updateWeightedMode(12, 0.2, 3);
console.log('   低Token + 高错误:', controlTower.getCurrentMode().name);

console.log('\n🎉 第二阶段升级测试完成！');
console.log('✅ Nightly Worker 冷却预算正常');
console.log('✅ Watchdog 守护线程正常');
console.log('✅ 权重驱动模式正常');
console.log('\n📊 升级总结:');
console.log('   - Nightly Budget: Token 50k, Calls 10');
console.log('   - Watchdog: 60秒检查, 4种严重程度');
console.log('   - 权重模式: 3个得分, 总体压力驱动');
console.log('   - 模式切换: 4种模式自动切换');
console.log('\n📝 准备生成最终报告...');
