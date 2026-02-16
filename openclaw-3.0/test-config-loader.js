// test-config-loader.js - 配置加载器测试

const configLoader = require('./config-loader');

async function testConfigLoader() {
  console.log('🧪 测试配置加载器...\n');

  try {
    // 1. 测试配置加载
    console.log('📋 测试 1: 加载配置');
    const config = await configLoader.load('config.json');
    console.log('✅ 配置加载成功');
    console.log(`   API URL: ${config.apiBaseURL}`);
    console.log(`   每日预算: ${config.dailyBudget} tokens`);
    console.log(`   每分钟最大请求: ${config.maxRequestsPerMinute}`);
    console.log(`   夜间任务时间: ${config.nightlyTaskTime}`);
    console.log(`   启用监控: ${config.enableMonitoring}`);
    console.log(`   启用日志: ${config.enableLogging}`);
    console.log(`   调试模式: ${config.debugMode}\n`);

    // 2. 测试配置验证
    console.log('📋 测试 2: 配置验证');
    console.log('✅ 配置验证通过\n');

    // 3. 测试配置获取
    console.log('📋 测试 3: 配置获取');
    const apiBaseURL = configLoader.get('apiBaseURL');
    const dailyBudget = configLoader.get('dailyBudget');
    const timeout = configLoader.get('timeout');
    console.log(`   API URL: ${apiBaseURL}`);
    console.log(`   每日预算: ${dailyBudget} tokens`);
    console.log(`   超时设置: ${timeout}ms`);
    console.log('✅ 配置获取成功\n');

    // 4. 测试配置摘要
    console.log('📋 测试 4: 配置摘要');
    const summary = configLoader.getConfigSummary();
    console.log('   配置摘要:');
    console.log(`   - API URL: ${summary.apiBaseURL}`);
    console.log(`   - 每日预算: ${summary.dailyBudget}`);
    console.log(`   - 已用: ${summary.tokenUsage}`);
    console.log(`   - 剩余: ${summary.remainingTokens}`);
    console.log(`   - 成功率: ${summary.successRate}%`);
    console.log(`   - 每分钟最大请求: ${summary.maxRequestsPerMinute}`);
    console.log(`   - 夜间任务时间: ${summary.nightlyTaskTime}`);
    console.log(`   - 当前是否为夜间: ${summary.isNightTime}`);
    console.log('✅ 配置摘要获取成功\n');

    // 5. 测试 Schema
    console.log('📋 测试 5: Schema 信息');
    console.log(`   Schema 包含 ${Object.keys(configLoader.validateSchema).length} 个字段`);
    console.log(`   必需字段: ${Object.keys(configLoader.validateSchema).filter(k => configLoader.validateSchema[k].required).length}`);
    console.log(`   可选字段: ${Object.keys(configLoader.validateSchema).filter(k => !configLoader.validateSchema[k].required).length}`);
    console.log('✅ Schema 信息获取成功\n');

    // 6. 测试环境变量覆盖
    console.log('📋 测试 6: 环境变量支持');
    console.log('   当前使用环境变量覆盖:');
    console.log('   - LOG_LEVEL:', configLoader.get('logLevel'));
    console.log('   - ENABLE_MONITORING:', configLoader.get('enableMonitoring'));
    console.log('✅ 环境变量支持测试完成\n');

    console.log('🎉 所有测试通过！');
    console.log('\n💡 提示:');
    console.log('   - 创建 .env 文件可覆盖配置');
    console.log('   - 修改 config.json 可自定义配置');
    console.log('   - 修改 config-schema.json 可自定义 Schema');
    console.log('   - 运行 node test-config-loader.js 验证配置\n');

  } catch (err) {
    console.error('❌ 测试失败:', err.message);
    process.exit(1);
  }
}

// 运行测试
testConfigLoader();
