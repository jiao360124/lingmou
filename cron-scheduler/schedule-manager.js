const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const PROJECT_ROOT = path.join(__dirname, '..');
const CONFIG_FILE = path.join(PROJECT_ROOT, 'config', 'cron-config.json');

console.log('========================================');
console.log('   Cron Scheduler Manager');
console.log('========================================\n');

async function scheduleManager() {
  try {
    // Load configuration
    if (!fs.existsSync(CONFIG_FILE)) {
      console.error('❌ 配置文件不存在:', CONFIG_FILE);
      process.exit(1);
    }

    const config = JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8'));
    console.log(`📋 已加载配置 (版本: ${config.version})\n`);

    // Menu
    while (true) {
      console.log('请选择操作:');
      console.log('1. 查看所有任务');
      console.log('2. 启用任务');
      console.log('3. 禁用任务');
      console.log('4. 手动执行任务');
      console.log('5. 查看任务状态');
      console.log('6. 查看执行日志');
      console.log('7. 重启调度器');
      console.log('0. 退出');
      console.log('');

      const choice = prompt('请输入选项 (0-7): ');

      switch (choice) {
        case '1':
          displayTasks(config);
          break;

        case '2':
          enableTask(config);
          break;

        case '3':
          disableTask(config);
          break;

        case '4':
          executeTask(config);
          break;

        case '5':
          displayTaskStatus();
          break;

        case '6':
          viewLogs();
          break;

        case '7':
          restartScheduler();
          break;

        case '0':
          console.log('退出程序');
          return;

        default:
          console.log('无效的选项，请重新输入');
      }

      console.log('');
    }
  } catch (error) {
    console.error('❌ 错误:', error.message);
    process.exit(1);
  }
}

function prompt(message) {
  const readline = require('readline').createInterface({
    input: process.stdin,
    output: process.stdout
  });

  return new Promise((resolve) => {
    readline.question(message, (answer) => {
      readline.close();
      resolve(answer.trim());
    });
  });
}

function displayTasks(config) {
  console.log('📋 任务列表:\n');
  config.tasks.forEach((task, index) => {
    const status = task.enabled ? '✅ 启用' : '❌ 禁用';
    const priority = getPriorityLabel(task.priority);
    console.log(`${index + 1}. ${task.name}`);
    console.log(`   ID: ${task.id}`);
    console.log(`   状态: ${status}`);
    console.log(`   优先级: ${priority} (优先级 ${task.priority})`);
    console.log(`   Cron: ${task.cronExpression}`);
    console.log(`   脚本: ${task.script}`);
    console.log(`   描述: ${task.description}`);
    console.log('');
  });
}

function getPriorityLabel(priority) {
  if (priority <= 5) return '低';
  if (priority <= 10) return '中';
  if (priority <= 15) return '高';
  return '最高';
}

async function enableTask(config) {
  displayTasks(config);
  const taskId = prompt('请输入要启用的任务ID: ');
  const task = config.tasks.find(t => t.id === taskId);

  if (!task) {
    console.log('❌ 任务不存在');
    return;
  }

  task.enabled = true;
  saveConfig(config);
  console.log(`✅ 任务 "${task.name}" 已启用`);
}

async function disableTask(config) {
  displayTasks(config);
  const taskId = prompt('请输入要禁用的任务ID: ');
  const task = config.tasks.find(t => t.id === taskId);

  if (!task) {
    console.log('❌ 任务不存在');
    return;
  }

  task.enabled = false;
  saveConfig(config);
  console.log(`✅ 任务 "${task.name}" 已禁用`);
}

async function executeTask(config) {
  displayTasks(config);
  const taskId = prompt('请输入要执行的任务ID: ');
  const task = config.tasks.find(t => t.id === taskId);

  if (!task) {
    console.log('❌ 任务不存在');
    return;
  }

  if (!task.enabled) {
    console.log('❌ 任务当前已禁用');
    const action = prompt('是否强制执行？(y/n): ');
    if (action.toLowerCase() !== 'y') {
      return;
    }
  }

  console.log(`\n执行任务: ${task.name}`);
  console.log(`脚本: ${task.script}\n`);

  try {
    const scriptPath = path.join(PROJECT_ROOT, task.script);

    if (!fs.existsSync(scriptPath)) {
      console.log(`❌ 脚本文件不存在: ${scriptPath}`);
      return;
    }

    const process = spawn('node', [scriptPath], {
      cwd: PROJECT_ROOT,
      env: { ...process.env, NODE_ENV: 'development' }
    });

    process.stdout.on('data', (data) => {
      process.stdout.write(data);
    });

    process.stderr.on('data', (data) => {
      process.stderr.write(data);
    });

    await new Promise((resolve, reject) => {
      process.on('close', (code) => {
        if (code === 0) {
          resolve();
        } else {
          reject(new Error(`脚本执行失败，退出码: ${code}`));
        }
      });
      process.on('error', (error) => {
        reject(error);
      });
    });

    console.log('\n✅ 任务执行成功');
  } catch (error) {
    console.log(`\n❌ 任务执行失败: ${error.message}`);
  }
}

function displayTaskStatus() {
  const statusPath = path.join(PROJECT_ROOT, 'data', 'task-status.json');

  if (!fs.existsSync(statusPath)) {
    console.log('❌ 任务状态文件不存在');
    return;
  }

  const status = JSON.parse(fs.readFileSync(statusPath, 'utf8'));

  console.log('📊 任务状态:\n');

  Object.entries(status).forEach(([taskId, status]) => {
    const taskName = taskId.replace(/-/g, ' ').toUpperCase();
    console.log(`${taskId}: ${taskName}`);
    console.log(`  状态: ${status.enabled ? '运行中' : '已禁用'}`);
    console.log(`  优先级: ${status.priority}`);
    if (status.lastRun) {
      console.log(`  最后执行: ${new Date(status.lastRun).toLocaleString('zh-CN', { timeZone: 'Asia/Shanghai' })}`);
    } else {
      console.log(`  最后执行: 未执行`);
    }
    if (status.lastSuccess) {
      console.log(`  最后成功: ${new Date(status.lastSuccess).toLocaleString('zh-CN', { timeZone: 'Asia/Shanghai' })}`);
    } else {
      console.log(`  最后成功: 未成功`);
    }
    if (status.lastFailure) {
      console.log(`  最后失败: ${new Date(status.lastFailure).toLocaleString('zh-CN', { timeZone: 'Asia/Shanghai' })}`);
      console.log(`  失败次数: ${status.failureCount}`);
    }
    console.log('');
  });
}

function viewLogs() {
  const logPath = path.join(PROJECT_ROOT, 'logs', 'cron-scheduler.log');

  if (!fs.existsSync(logPath)) {
    console.log('❌ 日志文件不存在');
    return;
  }

  console.log('📝 查看最近50条日志:\n');

  const lines = fs.readFileSync(logPath, 'utf8').split('\n');
  const recentLogs = lines.slice(-50).join('\n');

  console.log(recentLogs);
}

async function restartScheduler() {
  console.log('🔄 重启调度器...');

  // Kill existing scheduler
  try {
    const { spawn } = require('child_process');
    const process = spawn('taskkill', ['/F', '/IM', 'node.exe'], {
      stdio: 'ignore'
    });
    process.on('close', () => {
      console.log('✓ 进程已终止');
      console.log('💡 请运行 "npm start" 重新启动调度器');
    });
  } catch (error) {
    console.log('⚠ 进程终止失败，请手动重启调度器');
  }
}

function saveConfig(config) {
  fs.writeFileSync(CONFIG_FILE, JSON.stringify(config, null, 2), 'utf8');
}

// Start manager
scheduleManager();
