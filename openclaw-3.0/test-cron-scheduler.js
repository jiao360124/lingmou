// test-cron-scheduler.js - 定时任务调度器测试

const cronScheduler = require('./cron-scheduler');

async function testCronScheduler() {
  console.log('🧪 测试定时任务调度器...\n');

  try {
    // 1. 获取调度器状态
    console.log('📋 测试 1: 获取调度器状态');
    const status = cronScheduler.getStatus();
    console.log('✅ 调度器状态获取成功');
    console.log(`   总任务数: ${status.totalJobs}`);
    console.log(`   运行中任务: ${status.runningJobs}`);
    console.log(`   停止任务: ${status.stoppedJobs}`);
    console.log('');

    // 2. 获取所有任务状态
    console.log('📋 测试 2: 获取所有任务状态');
    const jobsStatus = cronScheduler.getAllJobsStatus();
    console.log(`✅ 获取到 ${jobsStatus.length} 个任务:`);
    jobsStatus.forEach(job => {
      console.log(`   - ${job.name} (${job.key}): ${job.status} (下次执行: ${job.nextRun})`);
    });
    console.log('');

    // 3. 获取特定任务状态
    console.log('📋 测试 3: 获取特定任务状态');
    const jobStatus = cronScheduler.getJobStatus('daily-report');
    if (jobStatus) {
      console.log('   任务状态:');
      console.log(`   - 名称: ${jobStatus.name}`);
      console.log(`   - 状态: ${jobStatus.status}`);
      console.log(`   - 下次执行: ${jobStatus.nextRun}`);
    } else {
      console.log('   ⚠️  任务不存在');
    }
    console.log('');

    // 4. 手动触发任务
    console.log('📋 测试 4: 手动触发任务');
    const result = await cronScheduler.runJob('daily-report');
    if (result.success) {
      console.log('✅ 任务触发成功');
      console.log(`   执行时间: ${result.executionTime}ms`);
    } else {
      console.log('❌ 任务触发失败');
      console.log(`   错误: ${result.error}`);
    }
    console.log('');

    // 5. 启用/禁用任务
    console.log('📋 测试 5: 启用/禁用任务');
    const enabled = cronScheduler.enableJob('weekly-report');
    console.log(`   启用任务: ${enabled ? '成功' : '失败'}`);

    const disabled = cronScheduler.disableJob('daily-report');
    console.log(`   禁用任务: ${disabled ? '成功' : '失败'}`);

    // 获取更新后的状态
    const updatedStatus = cronScheduler.getAllJobsStatus();
    console.log('\n   更新后的状态:');
    updatedStatus.forEach(job => {
      console.log(`   - ${job.name} (${job.key}): ${job.status} (下次执行: ${job.nextRun})`);
    });
    console.log('');

    // 6. 测试重置任务
    console.log('📋 测试 6: 手动触发重置任务');
    const resetResult = await cronScheduler.runJob('daily-metrics-reset');
    if (resetResult.success) {
      console.log('✅ 重置任务触发成功');
      console.log(`   执行时间: ${resetResult.executionTime}ms`);
    }
    console.log('');

    console.log('🎉 所有定时任务测试完成！');
    console.log('\n💡 使用示例:');
    console.log('   const cronScheduler = require("./cron-scheduler");');
    console.log('   const status = cronScheduler.getStatus();');
    console.log('   await cronScheduler.runJob("daily-report");\n');

  } catch (err) {
    console.error('❌ 测试失败:', err.message);
    process.exit(1);
  }
}

// 运行测试
testCronScheduler();
