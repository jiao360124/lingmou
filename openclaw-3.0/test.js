// openclaw-3.0/test.js
// 测试脚本

const openclaw3 = require('./index.js');
const tokenGovernor = require('./economy/tokenGovernor');
const tracker = require('./metrics/tracker');
const objectiveEngine = require('./objective/objectiveEngine');

async function runTests() {
  console.log('═════════════════════════════════════════════════════════════');
  console.log('      OpenClaw 3.0 - 测试套件');
  console.log('═════════════════════════════════════════════════════════════');
  console.log('');

  let passed = 0;
  let failed = 0;

  // 测试1: Token Governor
  console.log('[测试 1/6] Token Governor...');
  try {
    const usage = tokenGovernor.getUsageReport();
    console.log(`  ✅ Token使用报告生成: ${usage.used} / ${usage.dailyLimit}`);
    passed++;
  } catch (error) {
    console.log(`  ❌ Token Governor测试失败: ${error.message}`);
    failed++;
  }

  // 测试2: Metrics Tracker
  console.log('[测试 2/6] Metrics Tracker...');
  try {
    const metrics = tracker.getMetrics();
    console.log(`  ✅ 指标数据: Token=${metrics.dailyTokens}, 成本=$${metrics.cost}`);
    passed++;
  } catch (error) {
    console.log(`  ❌ Metrics Tracker测试失败: ${error.message}`);
    failed++;
  }

  // 测试3: Objective Engine
  console.log('[测试 3/6] Objective Engine...');
  try {
    const report = objectiveEngine.getReport();
    console.log(`  ✅ 目标进度: 成本降低${report.goals.longTerm.progress}%`);
    passed++;
  } catch (error) {
    console.log(`  ❌ Objective Engine测试失败: ${error.message}`);
    failed++;
  }

  // 测试4: Runtime
  console.log('[测试 4/6] Runtime...');
  try {
    const runtime = require('./core/runtime');
    const model = runtime.chooseModel('chat');
    console.log(`  ✅ 模型选择: ${model}`);
    passed++;
  } catch (error) {
    console.log(`  ❌ Runtime测试失败: ${error.message}`);
    failed++;
  }

  // 测试5: Nightly Worker
  console.log('[测试 5/6] Nightly Worker...');
  try {
    const worker = require('./value/nightlyWorker');
    const templates = worker.getTemplates();
    console.log(`  ✅ 模板数量: ${templates.length}`);
    passed++;
  } catch (error) {
    console.log(`  ❌ Nightly Worker测试失败: ${error.message}`);
    failed++;
  }

  // 测试6: 配置加载
  console.log('[测试 6/6] 配置加载...');
  try {
    const fs = require('fs-extra');
    const config = fs.readJSONSync('./config.json');
    console.log(`  ✅ 配置加载: API_URL=${config.apiBaseURL}, TokenLimit=${config.dailyTokenLimit}`);
    passed++;
  } catch (error) {
    console.log(`  ❌ 配置加载测试失败: ${error.message}`);
    failed++;
  }

  // 测试总结
  console.log('');
  console.log('═════════════════════════════════════════════════════════════');
  console.log('      测试总结');
  console.log('═════════════════════════════════════════════════════════════');
  console.log(`  通过: ${passed}/6`);
  console.log(`  失败: ${failed}/6`);
  console.log(`  成功率: ${Math.round((passed / 6) * 100)}%`);
  console.log('═════════════════════════════════════════════════════════════');
  console.log('');

  if (failed === 0) {
    console.log('🎉 所有测试通过！');
    console.log('🚀 可以启动服务: npm start');
  } else {
    console.log('⚠️  存在失败测试，请检查日志');
  }
}

// 运行测试
runTests().catch(error => {
  console.error('❌ 测试执行失败:', error);
  process.exit(1);
});
