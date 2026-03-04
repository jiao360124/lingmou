// openclaw-3.0/test-report-generator.js
// 报告生成器测试

const ReportGenerator = require('./report-generator');

console.log('🧪 报告生成器测试\n');

const generator = new ReportGenerator({
  outputDir: 'test-reports'
});

// 测试 1: 生成每日报告
console.log('【测试 1】生成每日报告');
generator.generateDailyReport()
  .then(file => {
    console.log(`✅ 每日报告生成成功: ${file}`);
    return file;
  })
  .catch(err => {
    console.log(`❌ 每日报告生成失败: ${err.message}`);
  });

// 测试 2: 生成每周报告
console.log('\n【测试 2】生成每周报告');
generator.generateWeeklyReport()
  .then(file => {
    console.log(`✅ 每周报告生成成功: ${file}`);
  })
  .catch(err => {
    console.log(`❌ 每周报告生成失败: ${err.message}`);
  });

console.log('\n🎉 测试启动！');
