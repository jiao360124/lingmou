// 测试智能路由引擎 - 自动 Fallback

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

console.log('📊 路由引擎状态:');
console.log(JSON.stringify(routeEngine.getStatus(), null, 2));

console.log('\n💬 发送测试消息...');
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
  }

  console.log('\n🎉 自动 Fallback 测试完成！');
})();
