/**
 * OpenClaw Cron Scheduler
 * 简化版调度器，使用模块化的任务定义
 */

const cron = require('node-cron');
const fs = require('fs');
const path = require('path');

const PROJECT_ROOT = path.join(__dirname, '..');

// 导入配置
const config = require('./config/index');

// 导入任务
const tasks = {
  'gateway-check': require('./jobs/gateway-check'),
  'heartbeat': require('./jobs/heartbeat'),
  'daily-report': require('./jobs/daily-report'),
  'weekly-report': require('./jobs/weekly-report')
};

// 调度器实例
const scheduler = {
  tasks: [],
  running: false,
  cronJobs: new Map(),
  taskStatus: new Map(),
  retryCount: new Map()
};

/**
 * 加载配置
 */
async function loadConfig() {
  const configPath = path.join(PROJECT_ROOT, config.config.configPath);
  if (fs.existsSync(configPath)) {
    return JSON.parse(fs.readFileSync(configPath, 'utf8'));
  }
  return config.defaultTasks;
}

/**
 * 加载任务状态
 */
function loadTaskStatus() {
  const statusPath = path.join(PROJECT_ROOT, config.taskStatus.savePath);
  if (fs.existsSync(statusPath)) {
    return JSON.parse(fs.readFileSync(statusPath, 'utf8'));
  }
  return {};
}

/**
 * 保存任务状态
 */
function saveTaskStatus() {
  const statusPath = path.join(PROJECT_ROOT, config.taskStatus.savePath);
  const statusData = Object.fromEntries(scheduler.taskStatus.entries());

  fs.writeFileSync(statusPath, JSON.stringify(statusData, null, 2), 'utf8');
}

/**
 * 初始化调度器
 */
async function initialize() {
  console.log('🚀 Cron Scheduler 初始化中...');

  // 加载配置
  const taskConfigs = await loadConfig();

  // 合并默认任务和配置任务
  const existingTasks = loadTaskStatus();
  const taskMap = new Map();

  // 添加配置任务
  taskConfigs.forEach(task => {
    taskMap.set(task.id, task);
  });

  // 添加已保存的任务（如果没有在配置中）
  Object.keys(existingTasks).forEach(taskId => {
    if (!taskMap.has(taskId)) {
      taskMap.set(taskId, {
        id: taskId,
        name: taskId.replace(/-/g, ' ').toUpperCase(),
        cronExpression: '0 0 * * *',
        timezone: 'Asia/Shanghai',
        enabled: true,
        priority: 10,
        script: `cron-scheduler/jobs/${taskId}.js`,
        description: '自动保存的任务'
      });
    }
  });

  scheduler.tasks = Array.from(taskMap.values()).sort((a, b) => a.priority - b.priority);

  // 初始化任务状态
  scheduler.tasks.forEach(task => {
    const existingStatus = existingTasks[task.id];
    scheduler.taskStatus.set(task.id, {
      lastRun: existingStatus?.lastRun || null,
      lastSuccess: existingStatus?.lastSuccess || null,
      lastFailure: existingStatus?.lastFailure || null,
      failureCount: existingStatus?.failureCount || 0,
      enabled: task.enabled,
      priority: task.priority
    });
    scheduler.retryCount.set(task.id, 0);
  });

  // 启动调度器
  await startScheduler();

  console.log(`✅ 调度器初始化完成，共 ${scheduler.tasks.length} 个任务`);
}

/**
 * 启动调度器
 */
async function startScheduler() {
  if (scheduler.running) {
    console.log('⚠️ 调度器已在运行');
    return;
  }

  console.log('📋 启动调度器...');

  scheduler.tasks.forEach(task => {
    if (task.enabled) {
      scheduleTask(task);
    } else {
      console.log(`⏭️  跳过已禁用任务: ${task.name}`);
    }
  });

  scheduler.running = true;
  console.log('✅ 调度器启动成功');
}

/**
 * 调度任务
 */
function scheduleTask(task) {
  try {
    const cronJob = cron.schedule(
      task.cronExpression,
      async () => {
        await executeTask(task);
      },
      {
        scheduled: true,
        timezone: task.timezone
      }
    );

    scheduler.cronJobs.set(task.id, cronJob);
    console.log(`⏰ 已调度: ${task.name} (${task.cronExpression})`);
  } catch (error) {
    console.error(`❌ 调度任务失败 ${task.id}:`, error.message);
  }
}

/**
 * 执行任务
 */
async function executeTask(task) {
  const status = scheduler.taskStatus.get(task.id);
  status.lastRun = new Date();

  console.log(`\n🔧 执行任务: ${task.name} [优先级: ${task.priority}]`);

  try {
    // 执行任务脚本
    await runTaskScript(task);

    // 更新状态
    status.lastSuccess = new Date();
    status.failureCount = 0;
    status.enabled = true;

    console.log(`✅ 任务 "${task.name}" 执行成功`);

  } catch (error) {
    status.lastFailure = new Date();
    status.failureCount++;

    console.error(`❌ 任务 "${task.name}" 执行失败:`, error.message);

    // 重试逻辑
    if (status.failureCount <= config.scheduler.maxRetries) {
      console.log(`  重试中 (${status.failureCount}/${config.scheduler.maxRetries})`);
      await retryTask(task, status.failureCount);
    } else {
      console.error(`  已达到最大重试次数`);
      status.enabled = false;
    }
  }

  // 保存状态
  saveTaskStatus();
}

/**
 * 运行任务脚本
 */
async function runTaskScript(task) {
  const scriptPath = path.join(PROJECT_ROOT, task.script);

  if (!fs.existsSync(scriptPath)) {
    throw new Error(`脚本文件不存在: ${scriptPath}`);
  }

  return new Promise((resolve, reject) => {
    const { spawn } = require('child_process');
    const process = spawn('node', [scriptPath], {
      cwd: PROJECT_ROOT,
      env: { ...process.env, NODE_ENV: 'production' }
    });

    let stdout = '';
    let stderr = '';

    process.stdout.on('data', (data) => {
      stdout += data.toString();
    });

    process.stderr.on('data', (data) => {
      stderr += data.toString();
    });

    process.on('close', (code) => {
      if (code === 0) {
        resolve(stdout);
      } else {
        reject(new Error(`脚本执行失败，退出码: ${code}\n${stderr}`));
      }
    });

    process.on('error', (error) => {
      reject(error);
    });

    // 超时处理
    setTimeout(() => {
      process.kill();
      reject(new Error('任务执行超时（30分钟）'));
    }, 30 * 60 * 1000);
  });
}

/**
 * 重试任务
 */
async function retryTask(task, attemptNumber) {
  const delay = (config.scheduler.maxRetries - attemptNumber + 1) * config.scheduler.retryDelay;
  console.log(`  等待 ${delay / 1000} 秒后重试...`);

  await new Promise(resolve => setTimeout(resolve, delay));

  try {
    await executeTask(task);
  } catch (error) {
    console.error(`  重试失败:`, error.message);
  }
}

/**
 * 停止调度器
 */
function stopScheduler() {
  if (!scheduler.running) {
    return;
  }

  console.log('⏹️  停止调度器...');

  scheduler.cronJobs.forEach(job => job.stop());
  scheduler.cronJobs.clear();

  scheduler.running = false;
  console.log('✅ 调度器已停止');
}

/**
 * 获取调度器状态
 */
function getSchedulerInfo() {
  return {
    running: scheduler.running,
    taskCount: scheduler.tasks.length,
    enabledTaskCount: scheduler.tasks.filter(t => t.enabled).length,
    tasks: Array.from(scheduler.taskStatus.entries()).map(([id, status]) => ({
      id,
      name: scheduler.tasks.find(t => t.id === id)?.name,
      ...status
    }))
  };
}

/**
 * 启用/禁用任务
 */
async function toggleTask(taskId, enabled) {
  const task = scheduler.tasks.find(t => t.id === taskId);
  if (!task) {
    throw new Error(`任务 ${taskId} 不存在`);
  }

  task.enabled = enabled;
  const status = scheduler.taskStatus.get(taskId);
  if (status) {
    status.enabled = enabled;
  }

  saveTaskStatus();
  console.log(`✅ 任务 "${task.name}" ${enabled ? '已启用' : '已禁用'}`);

  return true;
}

// 优雅关闭
process.on('SIGINT', async () => {
  console.log('\n⚠️  收到中断信号，正在关闭...');
  await stopScheduler();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('\n⚠️  收到终止信号，正在关闭...');
  await stopScheduler();
  process.exit(0);
});

// 启动调度器
if (require.main === module) {
  initialize()
    .then(() => {
      console.log('✅ 调度器正在运行，按 Ctrl+C 停止');
    })
    .catch(error => {
      console.error('❌ 调度器启动失败:', error);
      process.exit(1);
    });
}

module.exports = {
  scheduler,
  initialize,
  stopScheduler,
  getSchedulerInfo,
  toggleTask
};
