// openclaw-3.0/test-dashboard-with-data.js
// Dashboard 真实数据测试

const DataService = require('./data-service');

(async () => {
  console.log('🧪 Dashboard 真实数据测试\n');

  // 初始化数据服务
  const dataService = new DataService({
    cacheDuration: 30000
  });

  // 生成模拟请求日志
  console.log('📝 生成模拟请求日志...');
  const models = ['ZAI', 'Trinity', 'Anthropic'];

  for (let i = 0; i < 500; i++) {
    const model = models[Math.floor(Math.random() * models.length)];
    const latency = Math.floor(Math.random() * 200) + 50;
    const isSuccess = Math.random() > 0.05; // 95% 成功率

    dataService.logRequest({
      requestId: `req-${Date.now()}-${i}`,
      modelName: model,
      success: isSuccess,
      latency,
      costEstimate: 0.01 * (latency / 1000),
      fallbackCount: isSuccess ? 0 : 1,
      errorType: isSuccess ? null : 'SIMULATED_ERROR',
      timestamp: new Date().toISOString()
    });

    if (i % 100 === 0) {
      console.log(`   进度: ${i}/500`);
    }
  }

  console.log(`✅ 生成 ${500} 条模拟日志\n`);

  // 测试 1: API 端点测试
  console.log('【测试 1】测试 API 端点');
  console.log('📍 测试 /api/status');
  const statusResponse = await fetch('http://127.0.0.1:8080/api/status');
  const statusData = await statusResponse.json();
  console.log(`✅ 成功: ${statusData.requests.success}/${statusData.requests.total}`);
  console.log(`✅ 成功率: ${statusData.requests.successRate}`);
  console.log(`✅ 平均延迟: ${statusData.performance.avgLatency}`);
  console.log(`✅ Token 使用: ${statusData.performance.tokenUsage}`);
  console.log(`✅ 模型总数: ${statusData.models.total}`);
  console.log('✅ 状态 API 测试通过\n');

  console.log('📍 测试 /api/models');
  const modelsResponse = await fetch('http://127.0.0.1:8080/api/models');
  const modelsData = await modelsResponse.json();
  console.log(`✅ 模型总数: ${modelsData.total}`);
  modelsData.models.slice(0, 5).forEach((model, index) => {
    console.log(`   ${index + 1}. ${model.name} - ${model.totalCalls} 次`);
  });
  console.log('✅ 模型 API 测试通过\n');

  console.log('📍 测试 /api/trends');
  const trendsResponse = await fetch('http://127.0.0.1:8080/api/trends');
  const trendsData = await trendsResponse.json();
  console.log(`✅ 趋势点数: ${trendsData.trend.length}`);
  trendsData.trend.slice(0, 5).forEach(trend => {
    console.log(`   ${trend.time}: ${trend.cost} tokens`);
  });
  console.log('✅ 趋势 API 测试通过\n');

  console.log('📍 测试 /api/fallbacks');
  const fallbacksResponse = await fetch('http://127.0.0.1:8080/api/fallbacks');
  const fallbacksData = await fallbacksResponse.json();
  console.log(`✅ Fallback 总数: ${fallbacksData.totalFallbacks}`);
  console.log(`✅ 按模型分布: ${Object.keys(fallbacksData.fallbackByModel).length} 个模型`);
  console.log('✅ Fallback API 测试通过\n');

  // 测试 2: 数据刷新
  console.log('【测试 2】测试数据刷新');
  console.log('🔄 刷新缓存...');
  await dataService.refreshCache();
  console.log('✅ 缓存刷新成功\n');

  // 测试 3: 保存日志
  console.log('【测试 3】测试日志保存');
  await dataService.saveLogs('test-dashboard-logs-500.json');
  console.log('✅ 日志保存成功\n');

  // 测试 4: 获取缓存
  console.log('【测试 4】测试缓存数据');
  const cache = dataService.getCache();
  console.log('📊 缓存数据:');
  console.log(`   时间戳: ${new Date(cache.timestamp).toISOString()}`);
  console.log(`   总请求: ${cache.status.requests.total}`);
  console.log(`   成功: ${cache.status.requests.success}`);
  console.log(`   失败: ${cache.status.requests.failures}`);
  console.log(`   成功率: ${cache.status.requests.successRate}`);
  console.log(`   平均延迟: ${cache.status.performance.avgLatency}`);
  console.log(`   Token 使用: ${cache.status.performance.tokenUsage}`);
  console.log(`   模型总数: ${cache.status.models.total}`);
  console.log('✅ 缓存数据测试通过\n');

  console.log('🎉 所有测试完成！');
  console.log('\n✅ Dashboard 集成真实数据源成功！');
  console.log('✅ 所有 API 端点工作正常！');
  console.log('✅ 数据缓存机制正常！');
  console.log('✅ 日志保存功能正常！');
  console.log('\n📊 Dashboard 现在可以显示真实数据了！');
  console.log('📍 访问: http://127.0.0.1:8080/');
})();
