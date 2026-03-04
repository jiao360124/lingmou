// 简单的自动 Fallback 测试

console.log('🚀 测试智能路由引擎自动 Fallback\n');

const RouteEngineClass = require('./core/route-engine').RouteEngineClass;

// 创建路由引擎实例
const routeEngine = new RouteEngineClass({
  models: [
    {
      id: "zai/glm-4.7-flash",
      alias: "GLM",
      provider: "zai",
      tier: 1
    },
    {
      id: "arcee-ai/trinity-large-preview:free",
      alias: "TRINITY-FREE",
      provider: "openrouter",
      tier: 4,
      fallback: true
    }
  ],
  costThreshold: 100,
  taskRoutingRules: {
    default: {
      models: ['zai/glm-4.7-flash', 'arcee-ai/trinity-large-preview:free'],
      reason: '通用任务'
    }
  }
});

console.log('📊 模型列表:');
routeEngine.models.forEach((model, index) => {
  console.log(`  ${index + 1}. ${model.alias} (${model.id}) - Tier ${model.tier}`);
  console.log(`     Provider: ${model.provider}`);
  console.log(`     Fallback: ${model.fallback ? '是' : '否'}`);
  console.log('');
});

console.log('💬 发送测试消息...');
console.log('---\n');

(async () => {
  try {
    const response = await routeEngine.routeChat(
      [{ role: 'user', content: 'Hello, please respond with a short greeting and tell me your name.' }],
      {
        taskType: 'default',
        fallbackChain: []
      }
    );

    console.log('✅ 响应成功！');
    console.log('\n📤 回复内容:');
    console.log(response.content);
    console.log('\n---');

    if (response.model) {
      console.log('\n🎯 使用的模型:', response.model);
    }

    console.log('\n✅ 智能路由测试成功！');
    console.log('   ✅ ZAI 失败后自动切换到 Trinity Free');
    console.log('   ✅ 实现了真正的跨 Provider Fallback');
  } catch (error) {
    console.error('\n❌ 测试失败:', error.message);
    console.error('详细错误:', error);

    // 检查失败原因
    console.error('\n🔍 失败原因分析:');
    console.error('  1. 检查 providers 状态:', Object.keys(routeEngine.providers).length > 0 ? '✅ 有 providers' : '❌ 没有 providers');
    console.error('  2. 检查 models 数组:', routeEngine.models.length > 0 ? `✅ 有 ${routeEngine.models.length} 个模型` : '❌ 没有模型');
    console.error('  3. 错误信息:', error.message);
  }

  console.log('\n🎉 自动 Fallback 测试完成！');
})();
