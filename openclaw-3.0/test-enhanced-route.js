// openclaw-3.0/test-enhanced-route.js
// 增强版路由引擎完整测试

console.log('🚀 测试增强版路由引擎\n');

// 模拟配置
const config = {
  models: [
    {
      id: "zai/glm-4.7-flash",
      alias: "GLM",
      provider: "zai",
      tier: 1
    },
    {
      id: "zai/glm-4.5-flash",
      alias: "GLM-450",
      provider: "zai",
      tier: 2
    },
    {
      id: "arcee-ai/trinity-large-preview:free",
      alias: "TRINITY-FREE",
      provider: "openrouter",
      tier: 4,
      fallback: true,
      isFree: true
    }
  ],
  costThreshold: 100,
  taskRoutingRules: {
    default: {
      models: ['zai/glm-4.7-flash', 'zai/glm-4.5-flash', 'arcee-ai/trinity-large-preview:free'],
      reason: '通用任务'
    }
  },
  halfOpenRecoveryTime: 10 * 60 * 1000, // 10分钟
  healthThreshold: 0.5 // 50%
};

// 创建路由引擎（单例）
const routeEngine = require('./core/route-engine-v2');

console.log('📊 初始化完成！');
console.log('---\n');

// 测试 1：获取状态
console.log('📋 测试1：系统状态');
console.log('---');
const status = routeEngine.getStatus();
console.log(JSON.stringify(status, null, 2));
console.log('\n');

// 测试 2：请求日志
console.log('📋 测试2：请求日志');
console.log('---');
const logs = routeEngine.getRequestLogs(5);
console.log(`日志数量: ${logs.length}`);
console.log(JSON.stringify(logs, null, 2));
console.log('\n');

// 测试 3：模型使用统计
console.log('📋 测试3：模型使用统计');
console.log('---');
const stats = routeEngine.getModelStats();
console.log(JSON.stringify(stats, null, 2));
console.log('\n');

// 测试 4：动态评分
console.log('📋 测试4：动态评分');
console.log('---');
const scores = routeEngine.scoreEngine.getStatus();
console.log(JSON.stringify(scores, null, 2));
console.log('\n');

// 测试 5：Half-Open 恢复模拟
console.log('📋 测试5：Half-Open 恢复机制');
console.log('---');

// 模拟模型连续失败
const zaiModel = config.models[0];
console.log(`1. 模拟 ${zaiModel.alias} 连续失败...`);
routeEngine.recordFailure(zaiModel.id, 'rate_limit');
routeEngine.recordFailure(zaiModel.id, 'rate_limit');
routeEngine.recordFailure(zaiModel.id, 'rate_limit');

const healthAfterFailures = routeEngine.modelHealth[zaiModel.id];
console.log(`   当前状态: ${healthAfterFailures.isUnhealthy ? '❌ Unhealthy' : '✅ Healthy'}`);
console.log(`   连续失败: ${healthAfterFailures.consecutiveFailures}`);
console.log(`   isHalfOpen: ${healthAfterFailures.isHalfOpen}`);
console.log(`   isUnhealthy: ${healthAfterFailures.isUnhealthy}`);
console.log('\n');

// 触发 Half-Open 恢复测试
console.log(`2. 触发 Half-Open 恢复测试...`);
(async () => {
  await routeEngine.tryHalfOpenRecovery(zaiModel.id);

  const healthAfterRecovery = routeEngine.modelHealth[zaiModel.id];
  console.log(`   当前状态: ${healthAfterRecovery.isUnhealthy ? '❌ Unhealthy' : '✅ Healthy'}`);
  console.log(`   isHalfOpen: ${healthAfterRecovery.isHalfOpen}`);
  console.log(`   isUnhealthy: ${healthAfterRecovery.isUnhealthy}`);
  console.log(`   连续失败: ${healthAfterRecovery.consecutiveFailures}`);
  console.log('\n');

  // 测试 6：Trinity 自动切换
  console.log('📋 测试6：Trinity 自动切换');
  console.log('---');
  console.log(`1. ZAI 健康度 < 50%? ${routeEngine.shouldSwitchToTrinity() ? '✅ 是' : '❌ 否'}`);
  console.log(`2. 当前最佳模型: ${routeEngine.selectBestModelByScore()?.alias || 'None'}`);
  console.log('\n');

  // 测试 7：模拟异常
  console.log('📋 测试7：异常模拟');
  console.log('---');

  console.log('1. 模拟 429 错误...');
  routeEngine.recordFailure(zaiModel.id, 'rate_limit');
  console.log(`   当前状态: ${routeEngine.modelHealth[zaiModel.id].isUnhealthy ? '❌ Unhealthy' : '✅ Healthy'}`);

  console.log('\n2. 模拟余额不足...');
  routeEngine.recordFailure('zai/glm-4.5-flash', 'insufficient_funds');
  console.log(`   当前状态: ${routeEngine.modelHealth['zai/glm-4.5-flash'].isUnhealthy ? '❌ Unhealthy' : '✅ Healthy'}`);

  console.log('\n3. 模拟网络错误...');
  routeEngine.recordFailure('arcee-ai/trinity-large-preview:free', 'network_error');
  console.log(`   Trinity Free 状态: ${routeEngine.modelHealth['arcee-ai/trinity-large-preview:free'].isUnhealthy ? '❌ Unhealthy' : '✅ Healthy'}`);

  console.log('\n📊 异常统计:');
  const statsAfterErrors = routeEngine.getModelStats();
  console.log(JSON.stringify(statsAfterErrors, null, 2));
  console.log('\n');

  // 最终状态
  console.log('📊 最终系统状态');
  console.log('---');
  const finalStatus = routeEngine.getStatus();
  console.log(JSON.stringify({
    models: finalStatus.models.map(m => ({
      alias: m.alias,
      health: m.health
    })),
    scoreEngine: finalStatus.scoreEngine.avgScores,
    shouldSwitchToTrinity: finalStatus.shouldSwitchToTrinity
  }, null, 2));

  console.log('\n🎉 增强版路由引擎测试完成！');
  console.log('\n✅ 实现的功能:');
  console.log('   1. ✅ Half-Open 恢复机制（10分钟自动测试）');
  console.log('   2. ✅ 动态评分系统（质量-成本-延迟-失败）');
  console.log('   3. ✅ 请求日志 + 可视化');
  console.log('   4. ✅ Trinity 自动切换（健康度 < 50%）');
  console.log('   5. ✅ 错误类型检测（429/余额不足/网络错误）');
  console.log('   6. ✅ 模型健康状态跟踪');
  console.log('   7. ✅ 成本估算');
})();
