// openclaw-3.0/test-predictive-integration.js
// Predictive Engine 集成测试

const ControlTower = require('./core/control-tower');

// 初始化
const controlTower = ControlTower;

console.log('🚀 初始化 Control Tower...');
controlTower.initPredictiveEngine({
  maxRequestsPerMinute: 60,
  alpha: 0.3
});

console.log('\n✅ 初始化完成！开始测试...\n');

// 模拟指标数据
function generateMetrics(callRate, tokenRate) {
  return {
    callsLastMinute: callRate,
    tokensLastHour: tokenRate,
    remainingBudget: 100000,
    successRate: 92,
    dailyTokens: 180000
  };
}

// 模拟上下文数据
function generateContext(remainingTokens, maxTokens) {
  return {
    remainingTokens: remainingTokens,
    maxTokens: maxTokens,
    currentTurn: 5,
    turnThreshold: 10
  };
}

// 模拟延迟
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// 模拟 API 调用
async function mockAPICall(intervention, attempt) {
  const delay = intervention?.throttleDelay || 0;

  if (delay > 0) {
    console.log(`⏱️  等待 ${delay}ms...`);
    await sleep(delay);
  }

  console.log(`📤 发起请求 #${attempt} (延迟=${delay}ms, 压缩=${intervention?.compressionLevel || 0}, 模型=${intervention?.modelBias || 'NORMAL'})`);

  // 模拟 API 响应时间
  await sleep(100 + Math.random() * 200);

  console.log(`✅ 请求 #${attempt} 完成`);

  return { success: true, attempt };
}

// 主测试函数
async function runTests() {
  const testScenarios = [
    {
      name: '正常场景（无干预）',
      metrics: generateMetrics(30, 40000),
      context: generateContext(140000, 200000),
      expectedLevel: 'NORMAL'
    },
    {
      name: '速率压力场景（MEDIUM）',
      metrics: generateMetrics(45, 50000),
      context: generateContext(130000, 200000),
      expectedLevel: 'MEDIUM'
    },
    {
      name: '高压场景（HIGH）',
      metrics: generateMetrics(58, 80000),
      context: generateContext(100000, 200000),
      expectedLevel: 'HIGH'
    },
    {
      name: '严重场景（CRITICAL）',
      metrics: generateMetrics(62, 100000),
      context: generateContext(50000, 200000),
      expectedLevel: 'CRITICAL'
    }
  ];

  for (const scenario of testScenarios) {
    console.log('\n' + '='.repeat(60));
    console.log(`🧪 测试场景: ${scenario.name}`);
    console.log('='.repeat(60));

    // 🚀 预测干预
    const intervention = controlTower.predictIntervention(
      scenario.metrics,
      scenario.context
    );

    console.log('\n📊 干预建议:');
    console.log(JSON.stringify(intervention, null, 2));

    // 验证级别
    if (intervention.warningLevel === scenario.expectedLevel) {
      console.log(`\n✅ 级别验证通过: ${intervention.warningLevel}`);
    } else {
      console.log(`\n❌ 级别验证失败: 期望 ${scenario.expectedLevel}, 实际 ${intervention.warningLevel}`);
    }

    // 模拟请求
    console.log('\n🔄 模拟 API 调用:');
    await mockAPICall(intervention, 1);

    console.log(`\n✅ 场景完成: ${scenario.name}`);
  }

  console.log('\n' + '='.repeat(60));
  console.log('🎉 所有测试完成！');
  console.log('='.repeat(60));
}

// 运行测试
runTests()
  .then(() => process.exit(0))
  .catch(error => {
    console.error('\n❌ 测试失败:', error);
    process.exit(1);
  });
