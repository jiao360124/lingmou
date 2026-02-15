// openclaw-3.0/demo-runtime-integration.js
// Runtime Engine 集成 Predictive Engine 演示

const Runtime = require('./core/runtime');
const winston = require('winston');

// 配置日志
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console({ format: winston.format.simple() })
  ]
});

console.log('🚀 演示：Runtime Engine 集成 Predictive Engine\n');

// 模拟指标更新
function simulateMetrics(runtime, intensity = 'normal') {
  const intensities = {
    'low': { calls: 15, tokens: 30000 },
    'normal': { calls: 45, tokens: 80000 },
    'high': { calls: 75, tokens: 150000 }
  };

  const config = intensities[intensity] || intensities['normal'];

  runtime.metrics.callsLastMinute = config.calls;
  runtime.metrics.tokensLastHour = config.tokens;
  runtime.metrics.remainingBudget = 100000;
  runtime.metrics.successRate = 92;

  logger.info({
    action: 'metrics_updated',
    intensity,
    callsLastMinute: config.calls,
    tokensLastHour: config.tokens
  });
}

// 演示不同压力场景
async function runDemo() {
  const runtime = Runtime;

  console.log('📋 演示场景\n');

  // 场景1: 正常负载
  console.log('场景1: 正常负载');
  simulateMetrics(runtime, 'normal');
  const intervention1 = runtime.controlTower.predictIntervention(runtime.metrics, runtime.context);
  console.log(JSON.stringify(intervention1, null, 2));
  console.log('');

  // 场景2: 高负载
  console.log('场景2: 高负载');
  simulateMetrics(runtime, 'high');
  const intervention2 = runtime.controlTower.predictIntervention(runtime.metrics, runtime.context);
  console.log(JSON.stringify(intervention2, null, 2));
  console.log('');

  // 场景3: 极端负载
  console.log('场景3: 极端负载');
  simulateMetrics(runtime, 'high');
  simulateMetrics(runtime, 'high'); // 两次高负载
  const intervention3 = runtime.controlTower.predictIntervention(runtime.metrics, runtime.context);
  console.log(JSON.stringify(intervention3, null, 2));
  console.log('');

  // 场景4: 模拟 API 调用
  console.log('场景4: 模拟实际 API 调用流程');
  console.log('--- 开始 ---');

  // 更新指标
  simulateMetrics(runtime, 'normal');
  logger.info({
    action: 'update_metrics_before_call'
  });

  // 🚀 预测干预
  const intervention = runtime.controlTower.predictIntervention(runtime.metrics, runtime.context);
  if (intervention) {
    console.log(`📊 预测干预: ${intervention.warningLevel} 级别`);
    console.log(`  - 速率延迟: ${intervention.throttleDelay}ms`);
    console.log(`  - 上下文压缩: ${intervention.compressionLevel} 级`);
    console.log(`  - 模型偏置: ${intervention.modelBias}`);
  } else {
    console.log('📊 预测干预: 无需干预');
  }

  // 模拟延迟
  if (intervention?.throttleDelay > 0) {
    console.log(`⏱️  延迟 ${intervention.throttleDelay}ms...`);
  }

  // 模拟 API 调用
  console.log('📤 执行 API 调用...');

  // 模拟成功调用
  runtime.recordUsage(5000);
  runtime.updateMetrics();

  console.log('✅ API 调用成功');
  console.log('📊 Token 使用: +5000');
  console.log('📊 剩余预算: ' + runtime.metrics.remainingBudget);
  console.log('📊 累计 Token: ' + runtime.stats.todayUsage);
  console.log('--- 完成 ---\n');

  // 获取运行时状态
  console.log('📊 运行时状态:');
  const status = runtime.getStatus();
  console.log(JSON.stringify(status, null, 2));

  console.log('\n🎉 演示完成！');
}

// 运行演示
runDemo()
  .then(() => process.exit(0))
  .catch(error => {
    console.error('❌ 演示失败:', error);
    process.exit(1);
  });
