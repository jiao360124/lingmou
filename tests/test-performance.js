/**
 * 性能监控模块实际应用测试
 * 使用 OpenClaw 性能监控
 */

const PerformanceMonitor = require('./performance-monitor');

console.log('🚀 性能监控模块测试\n');

// 创建实例
const monitor = new PerformanceMonitor({
  apiLatencyWarningThreshold: 500,
  apiLatencyCriticalThreshold: 1000
});

// 启动监控
monitor.start('openclaw-workspace-analysis');

// 模拟一些操作
console.log('执行任务1: 扫描文件系统...');
const t1 = Date.now();
setTimeout(() => {
  const t2 = Date.now();
  monitor.recordApiPerformance('scan-files', t2 - t1);
  console.log('  ✅ 完成，耗时:', t2 - t1, 'ms\n');

  console.log('执行任务2: 扫描目录结构...');
  const t3 = Date.now();
  setTimeout(() => {
    const t4 = Date.now();
    monitor.recordApiPerformance('scan-directories', t4 - t3);
    console.log('  ✅ 完成，耗时:', t4 - t3, 'ms\n');

    console.log('执行任务3: 分析代码质量...');
    const t5 = Date.now();
    setTimeout(() => {
      const t6 = Date.now();
      monitor.recordApiPerformance('analyze-code-quality', t6 - t5);
      console.log('  ✅ 完成，耗时:', t6 - t5, 'ms\n');

      // 获取统计数据
      const stats = monitor.getStatistics();

      console.log('📊 性能统计:');
      console.log('  运行时间:', (stats.uptime / 1000).toFixed(2), '秒');
      console.log('  API调用数:', Object.keys(stats.apis).length);

      console.log('\n📋 API详情:');
      Object.keys(stats.apis).forEach(name => {
        const apiStats = stats.apis[name];
        const count = apiStats.count;
        const avg = apiStats.avgDuration;
        const min = apiStats.minDuration;
        const max = apiStats.maxDuration;
        const p95 = apiStats.p95;

        console.log(`  📌 ${name}:`);
        console.log(`     记录数: ${count}`);
        console.log(`     平均: ${avg}ms`);
        console.log(`     最小: ${min}ms`);
        console.log(`     最大: ${max}ms`);
        console.log(`     P95: ${p95}ms`);
      });

      // 检查告警
      const alerts = monitor.getAlerts();
      if (alerts.length > 0) {
        console.log('\n⚠️ 性能告警:');
        alerts.forEach(alert => {
          console.log(`  - ${alert.message}`);
        });
      } else {
        console.log('\n✅ 无性能告警');
      }

      // 获取状态
      const status = monitor.getStatus();
      console.log('\n🟡 监控状态:', status.running ? '运行中' : '已停止');

      // 停止监控
      monitor.stop();
      console.log('\n🎉 性能监控测试完成！');
    }, 500);
  }, 500);
}, 500);
