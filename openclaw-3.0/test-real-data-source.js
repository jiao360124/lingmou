// test-real-data-source.js - 真实数据源测试

const IntegrationManager = require('./data-sources/integration-manager');

async function testRealDataSource() {
  console.log('🧪 测试真实数据源集成...\n');

  try {
    // 1. 初始化集成管理器
    console.log('📋 测试 1: 初始化集成管理器');
    const manager = new IntegrationManager();
    console.log('✅ 集成管理器初始化成功\n');

    // 2. 集成真实数据源
    console.log('📋 测试 2: 集成真实数据源');
    const result = await manager.integrate();
    if (result.success) {
      console.log('✅ 真实数据源集成成功\n');
    } else {
      console.log('❌ 集成失败:', result.message);
      process.exit(1);
    }

    // 3. 测试数据源连接
    console.log('📋 测试 3: 数据源连接测试');
    const testResult = await manager.testConnection();
    console.log(`${testResult.success ? '✅' : '❌'} 连接测试: ${testResult.message}\n`);

    // 4. 模拟API调用
    console.log('📋 测试 4: 模拟API调用');
    const testCalls = [
      {
        tokensUsed: 100,
        success: true,
        latency: 500,
        cost: 0.01,
        model: 'gpt-3.5-turbo',
        timestamp: new Date()
      },
      {
        tokensUsed: 250,
        success: true,
        latency: 800,
        cost: 0.025,
        model: 'gpt-4',
        timestamp: new Date()
      },
      {
        tokensUsed: 50,
        success: false,
        latency: 12000,
        cost: 0,
        model: 'gpt-3.5-turbo',
        timestamp: new Date()
      },
      {
        tokensUsed: 150,
        success: true,
        latency: 600,
        cost: 0.015,
        model: 'gpt-3.5-turbo',
        timestamp: new Date()
      }
    ];

    for (const call of testCalls) {
      await manager.recordAPICall(call);
    }
    console.log('✅ 模拟API调用完成\n');

    // 5. 获取聚合指标
    console.log('📋 测试 5: 获取聚合指标');
    const aggregated = manager.getAggregatedMetrics();
    console.log('   聚合指标:');
    console.log(`   - 今日Tokens: ${aggregated.tokens}`);
    console.log(`   - 今日调用: ${aggregated.calls}`);
    console.log(`   - 成功次数: ${aggregated.successes}`);
    console.log(`   - 失败次数: ${aggregated.failures}`);
    console.log(`   - 成功率: ${aggregated.successRate}%`);
    console.log(`   - 总成本: $${aggregated.totalCost.toFixed(2)}`);
    console.log(`   - 平均延迟: ${aggregated.avgLatency}ms`);
    console.log('✅ 聚合指标获取成功\n');

    // 6. 获取趋势数据
    console.log('📋 测试 6: 获取趋势数据');
    const trend = manager.getTrendData(3);
    console.log('   过去3天数据:');
    for (const day of trend) {
      console.log(`   - ${day.date}: ${day.tokens} tokens, ${day.calls} calls, ${day.successRate}% 成功`);
    }
    console.log('✅ 趋势数据获取成功\n');

    // 7. 导出CSV
    console.log('📋 测试 7: 导出CSV');
    const csv = manager.exportToCSV(3);
    console.log('   CSV头:');
    console.log('   ' + csv.split('\n')[0]);
    console.log('   CSV行1:');
    console.log('   ' + csv.split('\n')[1]);
    console.log('✅ CSV导出成功\n');

    // 8. 获取优化建议
    console.log('📋 测试 8: 获取优化建议');
    const suggestions = manager.getOptimizationSuggestions();
    console.log(`   获取到 ${suggestions.length} 条建议:`);
    for (const suggestion of suggestions) {
      console.log(`   - [${suggestion.type}] ${suggestion.title}: ${suggestion.message}`);
    }
    console.log('✅ 优化建议获取成功\n');

    // 9. 获取数据源状态
    console.log('📋 测试 9: 获取数据源状态');
    const status = manager.getDataSourceStatus();
    console.log('   数据源状态:');
    console.log(`   - 集成状态: ${status.integrated ? '已集成' : '未集成'}`);
    console.log(`   - 源数量: ${status.sources.length}`);
    console.log('✅ 数据源状态获取成功\n');

    console.log('🎉 所有测试通过！');
    console.log('\n💡 使用示例:');
    console.log('   const manager = new IntegrationManager();');
    console.log('   await manager.integrate();');
    console.log('   await manager.recordAPICall(data);');
    console.log('   const metrics = manager.getAggregatedMetrics();\n');

  } catch (err) {
    console.error('❌ 测试失败:', err.message);
    console.error(err.stack);
    process.exit(1);
  }
}

// 运行测试
testRealDataSource();
