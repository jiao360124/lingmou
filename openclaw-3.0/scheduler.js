// openclaw-3.0/scheduler.js
// 定时任务管理器

const fs = require('fs').promises');
const path = require('path');
const cron = require('node-cron');
const { spawn } = require('child_process');
const winston = require('winston');

// 日志配置
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/scheduler.log' }),
    new winston.transports.Console({ format: winston.format.simple() })
  ]
});

/**
 * 🕐 定时任务管理器
 * 支持自动报告生成和任务调度
 */
class Scheduler {
  constructor(options = {}) {
    this.config = {
      reportsDir: options.reportsDir || 'reports',
      logsDir: options.logsDir || 'logs',
      queueFile: options.queueFile || 'reports/sender-queue.json',
      autoRefreshInterval: options.autoRefreshInterval || 30000, // 30秒
      maxRetries: options.maxRetries || 3
    };

    this.tasks = new Map();
    this.schedules = new Map();
    this.queue = [];
    this.running = false;

    logger.info('Scheduler initialized');
  }

  /**
   * 📅 添加定时任务
   * @param {string} taskId - 任务ID
   * @param {string} cronExpr - Cron 表达式
   * @param {Function} callback - 回调函数
   * @param {Object} options - 选项
   * @returns {Object} 任务信息
   */
  addTask(taskId, cronExpr, callback, options = {}) {
    const task = {
      taskId,
      cronExpr,
      callback,
      options: {
        enabled: true,
        description: options.description || '',
        maxRetries: options.maxRetries || 3,
        ...options
      },
      nextRun: null,
      lastRun: null,
      successCount: 0,
      failureCount: 0,
      isRunning: false
    };

    this.tasks.set(taskId, task);
    logger.info(`✅ Task added: ${taskId} (${cronExpr})`);

    return task;
  }

  /**
   * 🔄 启动任务调度器
   * @returns {Promise<void>}
   */
  async start() {
    if (this.running) {
      logger.warn('Scheduler is already running');
      return;
    }

    this.running = true;
    logger.info('🚀 Scheduler started');

    // 加载任务
    await this.loadTasks();

    // 启动任务
    this.tasks.forEach((task, taskId) => {
      if (task.options.enabled) {
        this.scheduleTask(task);
      }
    });

    // 启动队列处理
    this.startQueueProcessing();
  }

  /**
   * ⏸️ 停止任务调度器
   * @returns {Promise<void>}
   */
  async stop() {
    if (!this.running) {
      logger.warn('Scheduler is not running');
      return;
    }

    this.running = false;
    logger.info('⏸️ Scheduler stopped');
  }

  /**
   * 📋 加载任务
   * @returns {Promise<void>}
   */
  async loadTasks() {
    try {
      const tasksFile = path.join(this.config.reportsDir, 'tasks.json');
      if (await fs.access(tasksFile).then(() => true).catch(() => false)) {
        const tasksData = JSON.parse(await fs.readFile(tasksFile, 'utf-8'));

        tasksData.forEach(taskData => {
          const task = this.tasks.get(taskData.taskId);
          if (task) {
            task.options.enabled = taskData.enabled;
            task.options.description = taskData.description;
            logger.info(`📋 Task loaded: ${task.taskId}`);
          }
        });
      }
    } catch (error) {
      logger.error(`❌ Failed to load tasks: ${error.message}`);
    }
  }

  /**
   * 💾 保存任务
   * @returns {Promise<void>}
   */
  async saveTasks() {
    try {
      await fs.mkdir(this.config.reportsDir, { recursive: true });
      const tasksFile = path.join(this.config.reportsDir, 'tasks.json');
      const tasksData = Array.from(this.tasks.values()).map(task => ({
        taskId: task.taskId,
        enabled: task.options.enabled,
        description: task.options.description
      }));

      await fs.writeFile(tasksFile, JSON.stringify(tasksData, null, 2));
      logger.info('💾 Tasks saved');
    } catch (error) {
      logger.error(`❌ Failed to save tasks: ${error.message}`);
    }
  }

  /**
   * ⏰ 调度任务
   * @param {Object} task - 任务对象
   * @returns {void}
   */
  scheduleTask(task) {
    const schedule = cron.schedule(task.cronExpr, async () => {
      // 检查任务是否正在运行
      if (task.isRunning) {
        logger.warn(`⚠️ Task ${task.taskId} is already running, skipping`);
        return;
      }

      // 检查任务是否启用
      if (!task.options.enabled) {
        return;
      }

      // 检查队列限制
      if (this.queue.length >= 10) {
        logger.warn(`⚠️ Queue full, skipping ${task.taskId}`);
        return;
      }

      // 添加到队列
      this.addToQueue(task);
    }, {
      scheduled: true,
      timezone: 'Asia/Shanghai'
    });

    schedule.start();
    this.schedules.set(task.taskId, schedule);
    logger.info(`⏰ Task scheduled: ${task.taskId} (${task.cronExpr})`);

    // 计算下次运行时间
    const nextRun = this.calculateNextRun(task.cronExpr);
    task.nextRun = nextRun;
  }

  /**
   * 📊 计算下次运行时间
   * @param {string} cronExpr - Cron 表达式
   * @returns {Date} 下次运行时间
   */
  calculateNextRun(cronExpr) {
    const now = new Date();
    const tasks = cron.task(cronExpr).nextDates(1);

    if (tasks.length > 0) {
      return tasks[0];
    }

    return now;
  }

  /**
   * ➕ 添加到队列
   * @param {Object} task - 任务对象
   * @returns {boolean} 是否成功添加
   */
  addToQueue(task) {
    if (this.queue.length >= 10) {
      return false;
    }

    this.queue.push({
      task,
      retryCount: 0,
      timestamp: Date.now()
    });

    logger.info(`➕ Task added to queue: ${task.taskId} (Queue: ${this.queue.length}/10)`);

    return true;
  }

  /**
   * 🔄 启动队列处理
   * @returns {void}
   */
  startQueueProcessing() {
    setInterval(async () => {
      if (this.queue.length === 0 || !this.running) {
        return;
      }

      // 取出第一个任务
      const queueItem = this.queue.shift();
      await this.processQueueItem(queueItem);
    }, 1000); // 每秒处理一次
  }

  /**
   * 📊 处理队列项
   * @param {Object} queueItem - 队列项
   * @returns {Promise<void>}
   */
  async processQueueItem(queueItem) {
    const { task } = queueItem;

    logger.info(`🔄 Processing task: ${task.taskId}`);

    task.isRunning = true;
    task.lastRun = new Date();

    try {
      // 执行任务
      await task.callback();

      // 成功
      task.successCount++;
      logger.info(`✅ Task completed: ${task.taskId}`);

    } catch (error) {
      // 失败
      task.failureCount++;
      queueItem.retryCount++;

      if (queueItem.retryCount < task.options.maxRetries) {
        logger.warn(`⚠️ Task ${task.taskId} failed (retry ${queueItem.retryCount}/${task.options.maxRetries})`);
        // 重新加入队列
        this.queue.push(queueItem);
      } else {
        logger.error(`❌ Task ${task.taskId} failed after ${task.options.maxRetries} retries`);
      }
    } finally {
      task.isRunning = false;

      // 更新下次运行时间
      const nextRun = this.calculateNextRun(task.cronExpr);
      task.nextRun = nextRun;
    }
  }

  /**
   * 📋 获取任务列表
   * @returns {Array} 任务列表
   */
  getTasks() {
    return Array.from(this.tasks.values()).map(task => ({
      taskId: task.taskId,
      enabled: task.options.enabled,
      cronExpr: task.cronExpr,
      description: task.options.description,
      nextRun: task.nextRun,
      lastRun: task.lastRun,
      successCount: task.successCount,
      failureCount: task.failureCount,
      isRunning: task.isRunning
    }));
  }

  /**
   * 📝 启用/禁用任务
   * @param {string} taskId - 任务ID
   * @param {boolean} enabled - 是否启用
   * @returns {Promise<void>}
   */
  async toggleTask(taskId, enabled) {
    const task = this.tasks.get(taskId);
    if (!task) {
      throw new Error(`Task ${taskId} not found`);
    }

    task.options.enabled = enabled;

    // 停止旧调度
    if (this.schedules.has(taskId)) {
      this.schedules.get(taskId).stop();
      this.schedules.delete(taskId);
    }

    // 重新调度
    if (enabled) {
      this.scheduleTask(task);
      logger.info(`✅ Task enabled: ${taskId}`);
    } else {
      logger.info(`⏸️ Task disabled: ${taskId}`);
    }

    await this.saveTasks();
  }

  /**
   * 🗑️ 删除任务
   * @param {string} taskId - 任务ID
   * @returns {Promise<void>}
   */
  async removeTask(taskId) {
    const task = this.tasks.get(taskId);
    if (!task) {
      throw new Error(`Task ${taskId} not found`);
    }

    // 停止调度
    if (this.schedules.has(taskId)) {
      this.schedules.get(taskId).stop();
      this.schedules.delete(taskId);
    }

    // 删除任务
    this.tasks.delete(taskId);

    // 删除配置
    await this.saveTasks();

    logger.info(`🗑️ Task removed: ${taskId}`);
  }

  /**
   * 📊 获取队列状态
   * @returns {Object} 队列状态
   */
  getQueueStatus() {
    return {
      length: this.queue.length,
      max: 10,
      tasks: this.queue.map(item => ({
        taskId: item.task.taskId,
        retryCount: item.retryCount,
        timestamp: item.timestamp
      }))
    };
  }

  /**
   * 📊 获取统计信息
   * @returns {Object} 统计信息
   */
  getStats() {
    let totalSuccess = 0;
    let totalFailure = 0;
    let totalTasks = 0;

    this.tasks.forEach(task => {
      totalSuccess += task.successCount;
      totalFailure += task.failureCount;
      totalTasks++;
    });

    return {
      running: this.running,
      tasks: totalTasks,
      enabled: Array.from(this.tasks.values()).filter(t => t.options.enabled).length,
      disabled: totalTasks - Array.from(this.tasks.values()).filter(t => t.options.enabled).length,
      successCount: totalSuccess,
      failureCount: totalFailure,
      queue: this.getQueueStatus()
    };
  }

  /**
   * 🔄 重新加载任务
   * @returns {Promise<void>}
   */
  async reload() {
    logger.info('🔄 Reloading tasks...');

    // 停止所有任务
    this.schedules.forEach(schedule => schedule.stop());
    this.schedules.clear();

    // 重新加载任务
    await this.loadTasks();

    // 重新启动任务
    this.tasks.forEach((task, taskId) => {
      if (task.options.enabled) {
        this.scheduleTask(task);
      }
    });

    logger.info('✅ Tasks reloaded');
  }

  /**
   * 🗑️ 清空队列
   * @returns {void}
   */
  clearQueue() {
    this.queue = [];
    logger.info('🗑️ Queue cleared');
  }
}

module.exports = Scheduler;
