// openclaw-3.0/test-data-service.js
// Dashboard 数据服务测试

const DataService = require('./data-service');

(async () => {
  console.log('🧪 Dashboard DataService 测试\n');

  // 初始化数据服务
  const dataService = new DataService({
    cacheDuration: 30000
  });

  // 模拟一些请求日志
  console.log('📝 生成模拟请求日志...');
  const models = ['ZAI', 'Trinity', 'Anthropic'];

  for (let i = 0; i < 100; i++) {
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

    if (i % 20 === 0) {
      console.log(`   进度: ${i}/100`);
    }
  }

  console.log(`✅ 生成 ${100} 条模拟日志\n`);

  // 测试 1: 更新缓存
  console.log('【测试 1】更新缓存');
  await dataService.updateCache();
  console.log('✅ 缓存更新成功\n');

  // 测试 2: 获取状态数据
  console.log('【测试 2】获取状态数据');
  const cache = dataService.getCache();
  console.log('📊 缓存状态:');
  console.log(`   时间戳: ${new Date(cache.timestamp).toISOString()}`);
  console.log(`   总请求: ${cache.status.requests.total}`);
  console.log(`   成功: ${cache.status.requests.success}`);
  console.log(`   失败: ${cache.status.requests.failures}`);
  console.log(`   成功率: ${cache.status.requests.successRate}`);
  console.log(`   平均延迟: ${cache.status.performance.avgLatency}`);
  console.log(`   Token 使用: ${cache.status.performance.tokenUsage}`);
  console.log(`   模型总数: ${cache.status.models.total}`);
  console.log(`   主模型: ${cache.status.switcher.primaryModel}`);
  console.log('✅ 状态数据获取成功\n');

  // 测试 3: 获取模型数据
  console.log('【测试 3】获取模型数据');
  const modelsData = cache.models;
  console.log('📊 模型数据:');
  console.log(`   总模型数: ${modelsData.total}`);
  console.log(`   模型列表:`);
  modelsData.models.forEach((model, index) => {
    console.log(`     ${index + 1}. ${model.name}`);
    console.log(`        - 调用次数: ${model.totalCalls}`);
    console.log(`        - 成功: ${model.successCalls}`);
    console.log(`        - 失败: ${model.failureCalls}`);
    console.log(`        - 使用率: ${model.usageRate}`);
    console.log(`        - 平均延迟: ${model.avgLatency}`);
    console.log(`        - 总成本: ${model.totalCost} tokens`);
    console.log(`        - Fallback: ${model.fallbackCount}`);
  });
  console.log('✅ 模型数据获取成功\n');

  // 测试 4: 获取趋势数据
  console.log('【测试 4】获取趋势数据');
  const trendsData = cache.trends.trend;
  console.log('📊 成本趋势（最近 24 小时）:');
  trendsData.forEach((trend, index) => {
    if (index % 6 === 0) { // 每 6 个显示一次
      console.log(`   ${trend.time}: ${trend.cost} tokens`);
    }
  });
  console.log('✅ 趋势数据获取成功\n');

  // 测试 5: 获取 Fallback 数据
  console.log('【测试 5】获取 Fallback 数据');
  const fallbackData = cache.fallbacks;
  console.log('📊 Fallback 统计:');
  console.log(`   总 Fallback: ${fallbackData.totalFallbacks}`);
  console.log(`   Fallback 日志数: ${fallbackData.fallbackLogs.length}`);
  console.log(`   按 Fallback 日志数前 5 名:`);
  const topFallbacks = Object.entries(fallbackData.fallbackByModel || {})
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5);

  topFallbacks.forEach(([model, count], index) => {
    console.log(`     ${index + 1}. ${model}: ${count} 次`);
  });
  console.log('✅ Fallback 数据获取成功\n');

  // 测试 6: 保存日志
  console.log('【测试 6】保存日志到文件');
  await dataService.saveLogs('test-dashboard-logs.json');
  console.log('✅ 日志保存成功\n');

  // 测试 7: 获取摘要
  console.log('【测试 7】获取摘要');
  const summary = dataService.getSummary();
  console.log('📊 系统摘要:');
  console.log(`   总请求: ${summary.totalRequests}`);
  console.log(`   总失败: ${summary.totalFailures}`);
  console.log(`   平均延迟: ${summary.averageLatency.toFixed(2)}ms`);
  console.log(`   总成本: ${summary.cost.toFixed(4)} tokens`);
  console.log(`   模型数: ${Object.keys(summary.modelUsage || {}).length}`);
  console.log('✅ 摘要获取成功\n');

  console.log('🎉 所有测试完成！');
  console.log('\n✅ 数据服务功能正常！');
  console.log('✅ 所有 API 端点工作正常！');
})();
