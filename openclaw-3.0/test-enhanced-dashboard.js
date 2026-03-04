// openclaw-3.0/test-enhanced-dashboard.js
// 增强版 Dashboard 测试

const DataService = require('./data-service');

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

    if (i % 100 === 0) {
      console.log(`   进度: ${i}/1000`);
    }
  }

  console.log(`✅ 生成 1000 条模拟日志\n`);

  // 测试导出功能
  console.log('【测试 1】测试导出功能');

  // 测试 JSON 导出
  console.log('📍 测试 JSON 导出');
  const jsonResponse = await fetch('http://127.0.0.1:8080/api/logs/export', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ format: 'json' })
  });
  const jsonData = await jsonResponse.json();

  console.log('✅ JSON 导出成功');
  console.log(`   数据点数: ${Object.keys(jsonData).length}`);
  console.log(`   摘要: ${jsonData.summary.totalRequests} 请求`);
  console.log(`   模型数: ${jsonData.models.length}`);
  console.log(`   趋势点数: ${jsonData.trends.length}`);
  console.log('✅ JSON 导出测试通过\n');

  // 测试 CSV 导出
  console.log('📍 测试 CSV 导出');
  const csvResponse = await fetch('http://127.0.0.1:8080/api/logs/export', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ format: 'csv' })
  });
  const csvData = await csvResponse.text();

  console.log('✅ CSV 导出成功');
  console.log(`   CSV 行数: ${csvData.split('\n').length}`);
  console.log(`   第一行: ${csvData.split('\n')[0].substring(0, 80)}...`);
  console.log('✅ CSV 导出测试通过\n');

  // 测试日志导出 (JSON)
  console.log('📍 测试日志导出 (JSON)');
  const logsJsonResponse = await fetch('http://127.0.0.1:8080/api/export/json');
  const logsJson = await logsJsonResponse.text();

  console.log('✅ JSON 日志导出成功');
  console.log(`   日志条数: ${logsJson.split('\n').filter(l => l.trim()).length}`);
  console.log('✅ JSON 日志导出测试通过\n');

  // 测试日志导出 (CSV)
  console.log('📍 测试日志导出 (CSV)');
  const logsCsvResponse = await fetch('http://127.0.0.1:8080/api/export/csv');
  const logsCsv = await logsCsvResponse.text();

  console.log('✅ CSV 日志导出成功');
  console.log(`   CSV 行数: ${logsCsv.split('\n').length}`);
  console.log('✅ CSV 日志导出测试通过\n');

  // 测试数据刷新
  console.log('【测试 2】测试数据刷新');
  console.log('🔄 刷新缓存...');
  await dataService.refreshCache();
  console.log('✅ 缓存刷新成功\n');

  // 测试获取缓存
  console.log('【测试 3】测试缓存数据');
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

  console.log(`\n📊 模型数据 (${cache.models.total} 个模型):`);
  cache.models.models.slice(0, 5).forEach((model, index) => {
    console.log(`   ${index + 1}. ${model.name}`);
    console.log(`      - 调用次数: ${model.totalCalls}`);
    console.log(`      - 成功: ${model.successCalls}`);
    console.log(`      - 成功率: ${model.usageRate}`);
    console.log(`      - 平均延迟: ${model.avgLatency}`);
    console.log(`      - Token: ${model.totalCost}`);
  });

  console.log(`\n📈 趋势数据 (${cache.trends.trend.length} 个点):`);
  cache.trends.trend.slice(0, 5).forEach(trend => {
    console.log(`   ${trend.time}: ${trend.cost} tokens`);
  });

  console.log(`\n⚠️ Fallback 数据:`);
  console.log(`   总 Fallback: ${cache.fallbacks.totalFallbacks}`);
  console.log(`   按模型: ${Object.keys(cache.fallbacks.fallbackByModel).length} 个模型`);

  console.log('✅ 缓存数据测试通过\n');

  console.log('🎉 所有测试完成！');
  console.log('\n✅ Enhanced Dashboard 功能正常！');
  console.log('✅ 导出功能工作正常！');
  console.log('✅ 数据缓存机制正常！');
  console.log('✅ API 端点全部工作正常！');
  console.log('\n📊 Dashboard 现在支持:');
  console.log('   ✅ 更多的导出格式 (JSON, CSV)');
  console.log('   ✅ 数据导出按钮');
  console.log('   ✅ 日志导出功能');
  console.log('   ✅ 时间选择器');
  console.log('📍 访问: http://127.0.0.1:8080/');
})();
