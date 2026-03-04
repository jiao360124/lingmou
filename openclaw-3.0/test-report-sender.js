// openclaw-3.0/test-report-sender.js
// 报告发送器测试

const ReportSender = require('./report-sender');
const fs = require('fs').promises;

(async () => {
  console.log('🧪 报告发送器测试\n');

  // 测试 1: 创建报告
  console.log('【测试 1】创建测试报告');
  const testReportContent = `# OpenClaw 测试报告

**生成时间**: ${new Date().toISOString()}

## 📊 测试数据
- 总请求数: 100
- 成功率: 99%
- 平均延迟: 120ms
- Token 使用: 0.0100 tokens

## 🤖 模型使用
| 模型 | 调用次数 | 成功率 | 延迟 |
|------|---------|--------|------|
| ZAI | 60 | 99.2% | 100ms |
| Trinity | 30 | 98.5% | 150ms |
| Anthropic | 10 | 99.0% | 200ms |

## 📈 成本趋势
| 时间 | 成本 |
|------|------|
| 00:00 | 0.0020 |
| 06:00 | 0.0030 |
| 12:00 | 0.0040 |
| 18:00 | 0.0010 |

---

**测试报告已完成！**
`;

  // 保存测试报告
  const testReportFile = 'test-reports/test-report.md';
  await fs.mkdir('test-reports', { recursive: true });
  await fs.writeFile(testReportFile, testReportContent);
  console.log(`✅ 测试报告已保存: ${testReportFile}\n`);

  // 测试 2: 发送到 Telegram
  console.log('【测试 2】发送报告到 Telegram');
  const sender = new ReportSender({
    senderType: 'telegram',
    telegramToken: 'YOUR_TELEGRAM_TOKEN', // 实际使用时替换为真实 Token
    telegramChatId: 'YOUR_CHAT_ID' // 实际使用时替换为真实 Chat ID
  });

  // 检查配置
  if (sender.config.telegramToken === 'YOUR_TELEGRAM_TOKEN') {
    console.log('⚠️ 使用测试配置（Token 未设置），跳过实际发送\n');
    console.log('📝 实际使用时，请设置以下环境变量：');
    console.log('   TELEGRAM_TOKEN=your_actual_token');
    console.log('   TELEGRAM_CHAT_ID=your_actual_chat_id\n');
  } else {
    sender.sendReport(testReportFile, {
      reportType: 'test'
    });
  }

  // 测试 3: 邮件发送（如果配置了）
  if (sender.config.emailConfig) {
    console.log('【测试 3】发送报告到邮件');
    sender.sendToEmail(testReportContent, {
      to: 'test@example.com',
      subject: 'OpenClaw 测试报告',
      html: '<h1>OpenClaw 测试报告</h1><p>测试报告内容...</p>'
    });
  }

  // 测试 4: 发送历史统计
  console.log('\n【测试 4】发送历史统计');
  const stats = sender.getStats();
  console.log('📊 发送统计:');
  console.log(`   总发送: ${stats.total}`);
  console.log(`   成功: ${stats.success}`);
  console.log(`   失败: ${stats.failures}`);
  console.log('   按方法:');
  Object.keys(stats.byMethod).forEach(method => {
    console.log(`     - ${method}: ${stats.byMethod[method].success} 成功, ${stats.byMethod[method].failures} 失败`);
  });

  // 测试 5: 保存历史
  console.log('\n【测试 5】保存发送历史');
  await sender.saveHistory('test-reports/sender-history.json');
  console.log(`✅ 发送历史已保存: test-reports/sender-history.json\n`);

  // 测试 6: 重新发送失败的报告
  console.log('【测试 6】重新发送失败的报告（如果有）');
  if (stats.failures > 0) {
    const retryResults = await sender.retryFailed(5);
    console.log(`✅ 重新发送完成: ${retryResults.filter(r => r.success).length}/${retryResults.length} 成功`);
  } else {
    console.log('✅ 无失败记录需要重试');
  }

  console.log('\n🎉 测试完成！');
})();
