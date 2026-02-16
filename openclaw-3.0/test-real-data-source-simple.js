// test-real-data-source-simple.js - 简化版测试（不使用MetricsTracker）

const RealDataCollector = require('./data-sources/real-data-collector');

async function testRealDataSource() {
  console.log('🧪 测试真实数据源（简化版）...\n');

  try {
    // 1. 初始化真实数据采集器
    console.log('📋 测试 1: 初始化真实数据采集器');
    const collector = new RealDataCollector();
    console.log('✅ 真实数据采集器初始化成功\n');

    // 2. 模拟API调用
    console.log('📋 测试 2: 模拟API调用');
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
      await collector.collectCall(call);
    }
    console.log('✅ 模拟API调用完成\n');

    // 3. 获取聚合指标
    console.log('📋 测试 3: 获取聚合指标');
    const aggregated = collector.getAggregatedMetrics();
    console.log('   聚合指标:');
    console.log(`   - 今日Tokens: ${aggregated.tokens}`);
    console.log(`   - 今日调用: ${aggregated.calls}`);
    console.log(`   - 成功次数: ${aggregated.successes}`);
    console.log(`   - 失败次数: ${aggregated.failures}`);
    console.log(`   - 成功率: ${aggregated.successRate}%`);
    console.log(`   - 总成本: $${aggregated.totalCost.toFixed(2)}`);
    console.log(`   - 平均延迟: ${aggregated.avgLatency}ms`);
    console.log('✅ 聚合指标获取成功\n');

    // 4. 获取趋势数据
    console.log('📋 测试 4: 获取趋势数据');
    const trend = collector.getTrendData(3);
    console.log('   过去3天数据:');
    for (const day of trend) {
      console.log(`   - ${day.date}: ${day.tokens} tokens, ${day.calls} calls, ${day.successRate}% 成功`);
    }
    console.log('✅ 趋势数据获取成功\n');

    // 5. 导出CSV
    console.log('📋 测试 5: 导出CSV');
    const csv = collector.exportToCSV(3);
    console.log('   CSV头:');
    console.log('   ' + csv.split('\n')[0]);
    console.log('   CSV行1:');
    console.log('   ' + csv.split('\n')[1]);
    console.log('✅ CSV导出成功\n');

    // 6. 数据源状态
    console.log('📋 测试 6: 数据源状态');
    const status = collector.metrics;
    console.log('   当前状态:');
    console.log(`   - Tokens: ${status.daily.tokens}`);
    console.log(`   - Calls: ${status.daily.calls}`);
    console.log(`   - Success Rate: ${status.daily.successRate}%`);
    console.log('✅ 数据源状态获取成功\n');

    console.log('🎉 所有测试通过！');
    console.log('\n💡 使用示例:');
    console.log('   const collector = new RealDataCollector();');
    console.log('   await collector.collectCall(data);');
    console.log('   const metrics = collector.getAggregatedMetrics();\n');

  } catch (err) {
    console.error('❌ 测试失败:', err.message);
    console.error(err.stack);
    process.exit(1);
  }
}

// 运行测试
testRealDataSource();
