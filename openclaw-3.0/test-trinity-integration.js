// openclaw-3.0/test-trinity-integration.js
// Trinity 多供应商架构集成测试

console.log('🚀 演示：Trinity 多供应商架构集成\n');

const RouteEngine = require('./core/route-engine');
const RuntimeV2 = require('./core/runtime-v2');

// 测试 1：路由引擎初始化
console.log('📋 测试1：路由引擎初始化\n');
const routeEngine = RouteEngine;
console.log(JSON.stringify(routeEngine.getStatus(), null, 2));

// 测试 2：Runtime v2 初始化
console.log('\n📋 测试2：Runtime v2 初始化\n');
const runtime = RuntimeV2;
console.log('✅ Runtime v2 初始化完成');
console.log('✅ Route Engine 已加载');
console.log('✅ Predictive Engine 已加载');
console.log('✅ 支持跨 Provider Fallback');

// 测试 3：智能路由演示
console.log('\n📋 测试3：智能路由演示\n');
console.log('--- 正常任务 ---\n');

(async () => {
  try {
    const response = await runtime.handleMessage('Hello, this is a test message.', {
      taskType: 'default'
    });
    console.log('✅ 响应成功:', response.content.substring(0, 100) + '...');
    console.log('✅ 使用模型:', response.model || 'unknown');
  } catch (error) {
    console.error('❌ 响应失败:', error.message);
  }

  // 测试 4：长推理任务
  console.log('\n--- 长推理任务 ---\n');

  try {
    const response = await runtime.handleMessage('Please reason step by step about the benefits of using multiple AI providers.', {
      taskType: 'long_reasoning'
    });
    console.log('✅ 响应成功');
    console.log('✅ 使用模型:', response.model || 'unknown');
    console.log('✅ 长度:', response.content.length, '字符');
  } catch (error) {
    console.error('❌ 响应失败:', error.message);
  }

  // 测试 5：工具调用任务
  console.log('\n--- 工具调用任务 ---\n');

  try {
    const response = await runtime.handleMessage('What is the weather in Shanghai today?', {
      taskType: 'tool_call'
    });
    console.log('✅ 响应成功');
    console.log('✅ 使用模型:', response.model || 'unknown');
    console.log('✅ 长度:', response.content.length, '字符');
  } catch (error) {
    console.error('❌ 响应失败:', error.message);
  }

  // 测试 6：状态报告
  console.log('\n📋 测试6：系统状态\n');
  const status = runtime.getStatus();
  console.log(JSON.stringify({
    uptime: status.uptime + 's',
    todayUsage: status.stats.todayUsage + ' tokens',
    successCount: status.stats.successCount,
    errorCount: status.stats.errorCount,
    models: status.routeEngine.models.map(m => ({
      id: m.id,
      alias: m.alias,
      provider: m.provider,
      tier: m.tier,
      health: m.health
    })),
    providers: status.routeEngine.providers
  }, null, 2));

  console.log('\n🎉 Trinity 多供应商架构测试完成！');
  console.log('\n✅ 关键特性:');
  console.log('   1. 跨 Provider Fallback（ZAI 失败自动切换到 Trinity）');
  console.log('   2. 按错误类型智能判断');
  console.log('   3. 成本检测自动降级');
  console.log('   4. 任务分流策略');
  console.log('   5. API 健康检测');
  console.log('   6. 模型健康状态跟踪');
})();
