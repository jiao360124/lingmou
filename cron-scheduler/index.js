const cron = require('node-cron');
const fs = require('fs');
const path = require('path');
const winston = require('winston');

// Define paths
const PROJECT_ROOT = path.join(__dirname, '..');
const CONFIG_FILE = path.join(PROJECT_ROOT, 'config', 'cron-config.json');
const TASKS_FILE = path.join(PROJECT_ROOT, 'config', 'scheduler-tasks.json');
const LOG_FILE = path.join(PROJECT_ROOT, 'logs', 'cron-scheduler.log');

// Ensure directories exist
const logsDir = path.dirname(LOG_FILE);
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir, { recursive: true });
}

// Configure Winston logger
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    winston.format.errors({ stack: true }),
    winston.format.splat(),
    winston.format.json()
  ),
  defaultMeta: { service: 'cron-scheduler' },
  transports: [
    new winston.transports.File({ filename: LOG_FILE, level: 'info' }),
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      )
    })
  ]
});

// Task scheduler class
class CronScheduler {
  constructor() {
    this.tasks = [];
    this.running = false;
    this.taskStatus = new Map();
    this.retryCount = new Map();
    this.maxRetries = 3;
    this.taskRegistry = new Map();
  }

  // Load configuration
  async loadConfig() {
    try {
      if (!fs.existsSync(CONFIG_FILE)) {
        logger.warn('Cron config not found, using defaults');
        return this.getDefaultConfig();
      }

      const config = JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8'));
      return config;
    } catch (error) {
      logger.error('Error loading cron config:', error);
      return this.getDefaultConfig();
    }
  }

  // Get default configuration
  getDefaultConfig() {
    return {
      version: '1.0.0',
      timezone: 'Asia/Shanghai',
      enabled: true,
      maxRetries: 3,
      retryDelay: 5 * 60 * 1000, // 5 minutes
      tasks: [
        {
          id: 'daily-report',
          name: '每日报告生成',
          cronExpression: '0 4 * * *',
          timezone: 'Asia/Shanghai',
          enabled: true,
          priority: 10,
          script: 'node scripts/generate-daily-report.js',
          description: '每天凌晨4点生成每日报告'
        },
        {
          id: 'weekly-report',
          name: '每周报告生成',
          cronExpression: '0 0 * * 1',
          timezone: 'Asia/Shanghai',
          enabled: true,
          priority: 15,
          script: 'node scripts/generate-weekly-report.js',
          description: '每周一凌晨生成每周报告'
        },
        {
          id: 'daily-metrics-reset',
          name: '每日指标重置',
          cronExpression: '0 3 * * *',
          timezone: 'Asia/Shanghai',
          enabled: true,
          priority: 5,
          script: 'node scripts/reset-daily-metrics.js',
          description: '每天凌晨3点重置每日指标'
        },
        {
          id: 'weekly-cleanup',
          name: '定期清理旧数据',
          cronExpression: '0 0 * * 0',
          timezone: 'Asia/Shanghai',
          enabled: true,
          priority: 8,
          script: 'node scripts/weekly-data-cleanup.js',
          description: '每周日凌晨清理旧数据'
        },
        {
          id: 'heartbeat-monitor',
          name: '心跳监控',
          cronExpression: '*/30 * * * *',
          timezone: 'Asia/Shanghai',
          enabled: true,
          priority: 12,
          script: 'node scripts/heartbeat-monitor.js',
          description: '每30分钟检查系统健康状态'
        }
      ]
    };
  }

  // Load existing tasks
  async loadTasks() {
    try {
      if (fs.existsSync(TASKS_FILE)) {
        const taskData = JSON.parse(fs.readFileSync(TASKS_FILE, 'utf8'));
        return taskData.tasks || [];
      }
      return [];
    } catch (error) {
      logger.error('Error loading tasks:', error);
      return [];
    }
  }

  // Initialize scheduler
  async initialize() {
    logger.info('Initializing Cron Scheduler...');

    const config = await this.loadConfig();
    const existingTasks = await this.loadTasks();

    this.maxRetries = config.maxRetries || 3;
    this.timezone = config.timezone || 'Asia/Shanghai';

    // Combine existing tasks with config tasks
    this.tasks = this.mergeTasks(config.tasks, existingTasks);

    // Initialize task status
    this.tasks.forEach(task => {
      this.taskStatus.set(task.id, {
        lastRun: null,
        lastSuccess: null,
        lastFailure: null,
        failureCount: 0,
        enabled: task.enabled,
        priority: task.priority
      });
      this.retryCount.set(task.id, 0);
    });

    // Register task scripts
    this.registerTaskScripts();

    // Start scheduler
    await this.startScheduler();
  }

  // Merge tasks from config and existing tasks
  mergeTasks(configTasks, existingTasks) {
    const taskMap = new Map();

    // Add config tasks
    configTasks.forEach(task => {
      taskMap.set(task.id, task);
    });

    // Add existing tasks not in config
    existingTasks.forEach(task => {
      if (!taskMap.has(task.id)) {
        taskMap.set(task.id, task);
      }
    });

    return Array.from(taskMap.values()).sort((a, b) => a.priority - b.priority);
  }

  // Register task scripts
  registerTaskScripts() {
    this.tasks.forEach(task => {
      this.taskRegistry.set(task.id, task.script);
    });
  }

  // Start scheduler
  async startScheduler() {
    if (this.running) {
      logger.warn('Scheduler is already running');
      return;
    }

    logger.info(`Starting cron scheduler with ${this.tasks.length} tasks...`);

    this.tasks.forEach(task => {
      if (task.enabled) {
        this.scheduleTask(task);
      } else {
        logger.info(`Task ${task.name} is disabled`);
      }
    });

    this.running = true;
    logger.info('Cron Scheduler started successfully');
  }

  // Schedule a single task
  scheduleTask(task) {
    try {
      // Create cron job
      const cronJob = cron.schedule(
        task.cronExpression,
        async () => {
          await this.executeTask(task);
        },
        {
          scheduled: true,
          timezone: task.timezone
        }
      );

      // Store cron job reference
      if (!this.cronJobs) {
        this.cronJobs = new Map();
      }
      this.cronJobs.set(task.id, cronJob);

      logger.info(`Scheduled task: ${task.name} (${task.cronExpression})`);
    } catch (error) {
      logger.error(`Error scheduling task ${task.id}:`, error);
    }
  }

  // Execute a task
  async executeTask(task) {
    const status = this.taskStatus.get(task.id);
    status.lastRun = new Date();

    logger.info(`Executing task: ${task.name} [Priority: ${task.priority}]`);

    try {
      // Execute task script
      await this.runScript(task.script);

      // Update status
      status.lastSuccess = new Date();
      status.failureCount = 0;
      status.enabled = true;

      logger.info(`✓ Task ${task.name} completed successfully`);

    } catch (error) {
      status.lastFailure = new Date();
      status.failureCount++;

      logger.error(`✗ Task ${task.name} failed:`, error.message);

      // Retry logic
      if (status.failureCount <= this.maxRetries) {
        logger.info(`  Retrying task ${task.name} (${status.failureCount}/${this.maxRetries})`);
        await this.retryTask(task, status.failureCount);
      } else {
        logger.error(`  Max retries reached for task ${task.name}`);
        status.enabled = false;
      }
    }

    // Save status
    await this.saveTaskStatus();
  }

  // Run a task script
  async runScript(scriptPath) {
    return new Promise((resolve, reject) => {
      // Check if script exists
      const fullPath = path.join(PROJECT_ROOT, scriptPath);
      if (!fs.existsSync(fullPath)) {
        return reject(new Error(`Script not found: ${scriptPath}`));
      }

      // Execute script using spawn
      const { spawn } = require('child_process');
      const process = spawn('node', [fullPath], {
        cwd: PROJECT_ROOT,
        env: { ...process.env, NODE_ENV: 'production' }
      });

      let stdout = '';
      let stderr = '';

      process.stdout.on('data', (data) => {
        stdout += data.toString();
        logger.debug(`[${scriptPath}] ${data}`);
      });

      process.stderr.on('data', (data) => {
        stderr += data.toString();
        logger.debug(`[${scriptPath} ERROR] ${data}`);
      });

      process.on('close', (code) => {
        if (code === 0) {
          resolve(stdout);
        } else {
          reject(new Error(`Script exited with code ${code}: ${stderr}`));
        }
      });

      process.on('error', (error) => {
        reject(error);
      });

      // Timeout after 30 minutes
      setTimeout(() => {
        process.kill();
        reject(new Error(`Script timeout after 30 minutes`));
      }, 30 * 60 * 1000);
    });
  }

  // Retry a task
  async retryTask(task, attemptNumber) {
    const delay = this.maxRetries - attemptNumber + 1;
    logger.info(`  Waiting ${delay * 5} minutes before retry...`);

    await new Promise(resolve => setTimeout(resolve, delay * 5 * 60 * 1000));

    try {
      await this.executeTask(task);
    } catch (error) {
      logger.error(`Retry failed for task ${task.name}:`, error);
    }
  }

  // Stop scheduler
  stopScheduler() {
    if (!this.running) {
      return;
    }

    logger.info('Stopping cron scheduler...');

    if (this.cronJobs) {
      this.cronJobs.forEach(job => job.stop());
      this.cronJobs.clear();
    }

    this.running = false;
    logger.info('Cron Scheduler stopped');
  }

  // Save task status
  async saveTaskStatus() {
    try {
      const statusDir = path.join(PROJECT_ROOT, 'data');
      if (!fs.existsSync(statusDir)) {
        fs.mkdirSync(statusDir, { recursive: true });
      }

      const statusPath = path.join(statusDir, 'task-status.json');
      const statusData = Object.fromEntries(this.taskStatus.entries());

      fs.writeFileSync(statusPath, JSON.stringify(statusData, null, 2), 'utf8');
    } catch (error) {
      logger.error('Error saving task status:', error);
    }
  }

  // Get task status
  getTaskStatus(taskId) {
    return this.taskStatus.get(taskId) || null;
  }

  // Get all task statuses
  getAllTaskStatus() {
    return Object.fromEntries(this.taskStatus.entries());
  }

  // Enable/disable task
  async toggleTask(taskId, enabled) {
    const task = this.tasks.find(t => t.id === taskId);
    if (!task) {
      logger.error(`Task ${taskId} not found`);
      return false;
    }

    task.enabled = enabled;
    const status = this.taskStatus.get(taskId);
    if (status) {
      status.enabled = enabled;
    }

    await this.saveTaskStatus();
    logger.info(`Task ${task.name} ${enabled ? 'enabled' : 'disabled'}`);
    return true;
  }

  // Get scheduler info
  getSchedulerInfo() {
    return {
      running: this.running,
      taskCount: this.tasks.length,
      enabledTaskCount: this.tasks.filter(t => t.enabled).length,
      maxRetries: this.maxRetries,
      tasks: Array.from(this.taskStatus.entries()).map(([id, status]) => ({
        id,
        name: this.tasks.find(t => t.id === id)?.name,
        ...status
      }))
    };
  }
}

// Create and initialize scheduler instance
const scheduler = new CronScheduler();

// Handle graceful shutdown
process.on('SIGINT', async () => {
  logger.info('Received SIGINT, shutting down...');
  await scheduler.stopScheduler();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  logger.info('Received SIGTERM, shutting down...');
  await scheduler.stopScheduler();
  process.exit(0);
});

// Start scheduler if run directly
if (require.main === module) {
  scheduler.initialize()
    .then(() => {
      logger.info('Scheduler is running. Press Ctrl+C to stop.');
    })
    .catch(error => {
      logger.error('Failed to start scheduler:', error);
      process.exit(1);
    });
}

module.exports = { CronScheduler, scheduler };
