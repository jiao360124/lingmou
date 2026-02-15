// openclaw-3.0/test-observability.js
// 请求级别日志 + 可观测性系统测试

const RequestLogger = require('./core/observability');

console.log('🧪 请求级别日志 + 可观测性系统测试\n');

const logger = new RequestLogger({
  logToFile: false,
  logToConsole: true
});

// 测试 1: 记录请求日志
console.log('【测试 1】记录请求日志');
const requestId1 = logger.getRequestLogs();
console.log(`✅ 日志数量: ${logger.logs.length}`);
console.log('');

// 测试 2: 模拟多个请求
console.log('【测试 2】模拟多个请求');
const requests = [
  {
    requestId: 'req_001',
    startTime: Date.now() - 5000,
    modelName: 'ZAI',
    chosenModel: 'ZAI',
    success: true,
    latency: 120,
    costEstimate: 0.0025,
    fallbackCount: 0,
    errorType: null,
    intervention: { throttleDelay: 0, compressionLevel: 0 }
  },
  {
    requestId: 'req_002',
    startTime: Date.now() - 3000,
    modelName: 'Trinity',
    chosenModel: 'Trinity',
    success: true,
    latency: 80,
    costEstimate: 0.0030,
    fallbackCount: 0,
    errorType: null,
    intervention: { throttleDelay: 0, compressionLevel: 0 }
  },
  {
    requestId: 'req_003',
    startTime: Date.now() - 1000,
    modelName: 'ZAI',
    chosenModel: 'ZAI',
    success: false,
    latency: 5000,
    costEstimate: 0.0025,
    fallbackCount: 1,
    errorType: '429',
    intervention: { throttleDelay: 0, compressionLevel: 0 }
  },
  {
    requestId: 'req_004',
    startTime: Date.now() - 0,
    modelName: 'Anthropic',
    chosenModel: 'Anthropic',
    success: true,
    latency: 200,
    costEstimate: 0.0040,
    fallbackCount: 0,
    errorType: null,
    intervention: { throttleDelay: 0, compressionLevel: 0 }
  }
];

requests.forEach(req => {
  logger.log(req);
});
console.log(`✅ 记录了 ${requests.length} 个请求\n`);

// 测试 3: 获取请求日志
console.log('【测试 3】获取请求日志');
const req001 = logger.getRequestLog('req_001');
console.log(`✅ Request ID: ${req001.requestId}`);
console.log(`✅ Model: ${req001.modelName}`);
console.log(`✅ Success: ${req001.success}`);
console.log(`✅ Latency: ${req001.latency}ms`);
console.log('');

// 测试 4: 获取统计摘要
console.log('【测试 4】获取统计摘要');
const summary = logger.getSummary();
console.log(JSON.stringify(summary, null, 2));
console.log('');

// 测试 5: 获取模型使用报告
console.log('【测试 5】获取模型使用报告');
const modelReport = logger.getModelUsageReport();
console.log(JSON.stringify(modelReport, null, 2));
console.log('');

// 测试 6: 获取成本趋势报告
console.log('【测试 6】获取成本趋势报告（最近 24 小时）');
const costTrend = logger.getCostTrendReport(24);
console.log('最近 24 小时成本趋势:');
costTrend.forEach(item => {
  console.log(`  ${item.time}: ${item.cost}`);
});
console.log('');

// 测试 7: 获取 Fallback 报告
console.log('【测试 7】获取 Fallback 报告');
const fallbackReport = logger.getFallbackReport();
console.log(`✅ 总 Fallback 次数: ${fallbackReport.totalFallbacks}`);
console.log('Fallback 按模型:');
console.log(JSON.stringify(fallbackReport.fallbackByModel, null, 2));
console.log('Fallback 按错误类型:');
console.log(JSON.stringify(fallbackReport.fallbackByError, null, 2));
console.log('');

// 测试 8: 导出完整报告
console.log('【测试 8】导出完整报告');
const report = logger.exportReport({ hours: 24 });
console.log('报告摘要:');
console.log(`  总请求: ${report.summary.totalRequests}`);
console.log(`  总 Fallback: ${report.summary.totalFallbacks}`);
console.log(`  平均延迟: ${report.summary.averageLatency.toFixed(0)}ms`);
console.log(`  总成本: $${report.summary.cost.toFixed(4)}`);
console.log('');

// 测试 9: 过滤日志
console.log('【测试 9】过滤日志');
const zaiSuccessLogs = logger.getRequestLogs({
  modelName: 'ZAI',
  success: true
});
console.log(`✅ ZAI 成功请求: ${zaiSuccessLogs.length}`);
console.log('');

const four29Logs = logger.getRequestLogs({
  errorType: '429'
});
console.log(`✅ 429 错误: ${four29Logs.length}`);
console.log('');

// 测试 10: 保存报告
console.log('【测试 10】保存报告');
logger.saveReport('test-report.json').then(() => {
  console.log('✅ 报告已保存到 logs/test-report.json\n');
});

// 测试 11: 记录更多请求
console.log('【测试 11】记录更多请求以测试统计');
for (let i = 5; i <= 20; i++) {
  const req = {
    requestId: `req_00${i}`,
    startTime: Date.now() - i * 2000,
    modelName: i % 3 === 0 ? 'Trinity' : 'ZAI',
    chosenModel: i % 3 === 0 ? 'Trinity' : 'ZAI',
    success: i % 4 !== 0, // 每 4 个失败一次
    latency: 100 + Math.floor(Math.random() * 200),
    costEstimate: 0.0025,
    fallbackCount: i % 3 === 0 ? 1 : 0,
    errorType: i % 4 === 0 ? '429' : null,
    intervention: { throttleDelay: 0, compressionLevel: 0 }
  };
  logger.log(req);
}
console.log(`✅ 记录了 ${20} 个新请求\n`);

// 测试 12: 验证统计准确性
console.log('【测试 12】验证统计准确性');
const finalSummary = logger.getSummary();
console.log(`  总请求: ${finalSummary.totalRequests} (期望: 24)`);
console.log(`  总 Fallback: ${finalSummary.totalFallbacks} (期望: 8)`);
console.log(`  平均延迟: ${finalSummary.averageLatency.toFixed(0)}ms`);
console.log(`  总成本: $${finalSummary.cost.toFixed(4)}`);
console.log('');

console.log('🎉 所有测试完成！');
