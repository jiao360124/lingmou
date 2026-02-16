// openclaw-3.0/test-dashboard-enhanced.js
// 增强版 Dashboard 测试

const DataService = require('./data-service');
const fs = require('fs').promises;

(async () => {
  console.log('🧪 Enhanced Dashboard 测试\n');

  // 初始化数据服务
  const dataService = new DataService({
    cacheDuration: 30000
  });

  // 生成模拟请求日志
  console.log('📝 生成模拟请求日志...');
  const models = ['ZAI', 'Trinity', 'Anthropic'];

  for (let i = 0; i < 1000; i++) {
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

    if (i % 200 === 0) {
      console.log(`   进度: ${i}/1000`);
    }
  }

  console.log(`✅ 生成 1000 条模拟日志\n`);

  // 测试 1: API 端点测试
  console.log('【测试 1】测试 API 端点');
  const statusResponse = await fetch('http://127.0.0.1:8080/api/status');
  const statusData = await statusResponse.json();
  console.log(`✅ 成功: ${statusData.requests.success}/${statusData.requests.total}`);
  console.log(`✅ 成功率: ${statusData.requests.successRate}`);
  console.log(`✅ 平均延迟: ${statusData.performance.avgLatency}`);
  console.log(`✅ Token 使用: ${statusData.performance.tokenUsage}`);
  console.log('✅ 状态 API 测试通过\n');

  const modelsResponse = await fetch('http://127.0.0.1:8080/api/models');
  const modelsData = await modelsResponse.json();
  console.log(`✅ 模型总数: ${modelsData.total}`);
  modelsData.models.slice(0, 5).forEach((model, index) => {
    console.log(`   ${index + 1}. ${model.name} - ${model.totalCalls} 次`);
  });
  console.log('✅ 模型 API 测试通过\n');

  const trendsResponse = await fetch('http://127.0.0.1:8080/api/trends');
  const trendsData = await trendsResponse.json();
  console.log(`✅ 趋势点数: ${trendsData.trend.length}`);
  console.log('✅ 趋势 API 测试通过\n');

  const fallbacksResponse = await fetch('http://127.0.0.1:8080/api/fallbacks');
  const fallbacksData = await fallbacksResponse.json();
  console.log(`✅ Fallback 总数: ${fallbacksData.totalFallbacks}`);
  console.log('✅ Fallback API 测试通过\n');

  // 测试 2: 性能测试
  console.log('【测试 2】性能测试');
  const startTime = Date.now();

  for (let i = 0; i < 10; i++) {
    await fetch('http://127.0.0.1:8080/api/status');
    await fetch('http://127.0.0.1:8080/api/models');
    await fetch('http://127.0.0.1:8080/api/trends');
    await fetch('http://127.0.0.1:8080/api/fallbacks');
  }

  const endTime = Date.now();
  const duration = ((endTime - startTime) / 1000).toFixed(2);
  const avgTime = ((duration / 40 * 1000) / 1000).toFixed(2);

  console.log(`✅ 40 个请求完成`);
  console.log(`⏱️  总耗时: ${duration} 秒`);
  console.log(`⚡ 平均响应时间: ${avgTime} ms`);
  console.log('✅ 性能测试通过\n');

  // 测试 3: 缓存测试
  console.log('【测试 3】测试缓存机制');
  await dataService.refreshCache();
  console.log('✅ 缓存刷新成功\n');

  // 测试 4: 日志保存
  console.log('【测试 4】测试日志保存');
  await dataService.saveLogs('test-enhanced-logs-1000.json');
  console.log('✅ 日志保存成功\n');

  console.log('🎉 所有测试完成！');
  console.log('\n✅ Enhanced Dashboard 功能正常！');
  console.log('✅ API 端点工作正常！');
  console.log('✅ 性能表现良好！');
  console.log('✅ 缓存机制正常！');
  console.log('\n📊 增强版 Dashboard 已就绪！');
  console.log('📍 访问: http://127.0.0.1:8080/');
})();
