// cron-scheduler.js - 定时任务调度器
// 支持每日、每周、每月定时任务

const cron = require('cron');
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/openclaw-3.0.log' }),
    new winston.transports.Console()
  ]
});

class CronScheduler {
  constructor(config = {}) {
    this.config = config;
    this.jobs = new Map();
    this.taskQueue = [];
    this.isRunning = false;
    this.init();
  }

  // 初始化调度器
  init() {
    logger.info('初始化定时任务调度器...');

    // 注册默认任务
    this.registerDefaultTasks();

    logger.info('✅ 定时任务调度器初始化完成');
  }

  // 注册默认任务
  registerDefaultTasks() {
    // 每日报告生成（凌晨4点）
    this.registerJob('daily-report', {
      cron: '0 4 * * *',
      name: '每日报告生成',
      task: this.generateDailyReport.bind(this)
    });

    // 每周报告生成（每周日凌晨2点）
    this.registerJob('weekly-report', {
      cron: '0 2 * * 0',
      name: '每周报告生成',
      task: this.generateWeeklyReport.bind(this)
    });

    // 每日指标重置（凌晨3点）
    this.registerJob('daily-metrics-reset', {
      cron: '0 3 * * *',
      name: '每日指标重置',
      task: this.resetDailyMetrics.bind(this)
    });

    // 清理旧数据（每周日凌晨3点）
    this.registerJob('cleanup-old-data', {
      cron: '0 3 * * 0',
      name: '清理旧数据',
      task: this.cleanupOldData.bind(this)
    });

    // 发送每日摘要（凌晨5点）
    this.registerJob('daily-summary', {
      cron: '0 5 * * *',
      name: '每日摘要发送',
      task: this.sendDailySummary.bind(this)
    });
  }

  // 注册任务
  registerJob(name, config) {
    const job = new cron.CronJob(
      config.cron,
      config.task,
      null,
      true
    );

    this.jobs.set(name, {
      job,
      name: config.name,
      enabled: true,
      nextRun: job.nextDate().toISOString()
    });

    logger.info(`✅ 注册任务: ${config.name} (${config.cron})`);
  }

  // 启用任务
  enableJob(name) {
    const job = this.jobs.get(name);
    if (job) {
      job.job.start();
      job.enabled = true;
      job.nextRun = job.job.nextDate().toISOString();
      logger.info(`✅ 启用任务: ${job.name}`);
      return true;
    }
    return false;
  }

  // 禁用任务
  disableJob(name) {
    const job = this.jobs.get(name);
    if (job) {
      job.job.stop();
      job.enabled = false;
      job.nextRun = null;
      logger.warn(`⚠️  禁用任务: ${job.name}`);
      return true;
    }
    return false;
  }

  // 获取任务状态
  getJobStatus(name) {
    const job = this.jobs.get(name);
    if (!job) return null;

    return {
      name: job.name,
      enabled: job.enabled,
      nextRun: job.nextRun,
      status: job.enabled ? 'running' : 'stopped'
    };
  }

  // 获取所有任务状态
  getAllJobsStatus() {
    const status = [];

    for (const [name, job] of this.jobs.entries()) {
      status.push({
        name: job.name,
        key: name,
        enabled: job.enabled,
        nextRun: job.nextRun,
        status: job.enabled ? 'running' : 'stopped'
      });
    }

    return status;
  }

  // 生成每日报告
  async generateDailyReport() {
    const startTime = Date.now();
    logger.info('开始生成每日报告...');

    try {
      // 导入报告生成器
      const ReportGenerator = require('./report-generator');

      const reportGenerator = new ReportGenerator();

      // 生成每日报告
      await reportGenerator.generateDailyReport();

      logger.info(`✅ 每日报告生成完成 (耗时: ${Date.now() - startTime}ms)`);

      return {
        success: true,
        type: 'daily-report',
        executionTime: Date.now() - startTime
      };
    } catch (err) {
      logger.error('❌ 每日报告生成失败:', err.message);
      return {
        success: false,
        type: 'daily-report',
        error: err.message
      };
    }
  }

  // 生成每周报告
  async generateWeeklyReport() {
    const startTime = Date.now();
    logger.info('开始生成每周报告...');

    try {
      // 导入报告生成器
      const ReportGenerator = require('./report-generator');

      const reportGenerator = new ReportGenerator();

      // 生成每周报告
      await reportGenerator.generateWeeklyReport();

      logger.info(`✅ 每周报告生成完成 (耗时: ${Date.now() - startTime}ms)`);

      return {
        success: true,
        type: 'weekly-report',
        executionTime: Date.now() - startTime
      };
    } catch (err) {
      logger.error('❌ 每周报告生成失败:', err.message);
      return {
        success: false,
        type: 'weekly-report',
        error: err.message
      };
    }
  }

  // 重置每日指标
  async resetDailyMetrics() {
    const startTime = Date.now();
    logger.info('开始重置每日指标...');

    try {
      // 导入真实数据采集器
      const RealDataCollector = require('./data-sources/real-data-collector');

      const collector = new RealDataCollector();
      collector.resetDailyMetrics();

      logger.info(`✅ 每日指标重置完成 (耗时: ${Date.now() - startTime}ms)`);

      return {
        success: true,
        type: 'daily-metrics-reset',
        executionTime: Date.now() - startTime
      };
    } catch (err) {
      logger.error('❌ 每日指标重置失败:', err.message);
      return {
        success: false,
        type: 'daily-metrics-reset',
        error: err.message
      };
    }
  }

  // 清理旧数据
  async cleanupOldData() {
    const startTime = Date.now();
    logger.info('开始清理旧数据...');

    try {
      // 导入真实数据采集器
      const RealDataCollector = require('./data-sources/real-data-collector');

      const collector = new RealDataCollector();
      collector.cleanupOldData(30); // 清理30天前的数据

      logger.info(`✅ 旧数据清理完成 (耗时: ${Date.now() - startTime}ms)`);

      return {
        success: true,
        type: 'cleanup-old-data',
        executionTime: Date.now() - startTime
      };
    } catch (err) {
      logger.error('❌ 旧数据清理失败:', err.message);
      return {
        success: false,
        type: 'cleanup-old-data',
        error: err.message
      };
    }
  }

  // 发送每日摘要
  async sendDailySummary() {
    const startTime = Date.now();
    logger.info('开始发送每日摘要...');

    try {
      // 导入报告发送器
      const ReportSender = require('./report-sender');

      const reportSender = new ReportSender();

      // 发送每日摘要
      await reportSender.sendDailySummary();

      logger.info(`✅ 每日摘要发送完成 (耗时: ${Date.now() - startTime}ms)`);

      return {
        success: true,
        type: 'daily-summary',
        executionTime: Date.now() - startTime
      };
    } catch (err) {
      logger.error('❌ 每日摘要发送失败:', err.message);
      return {
        success: false,
        type: 'daily-summary',
        error: err.message
      };
    }
  }

  // 手动触发任务
  async runJob(name) {
    const job = this.jobs.get(name);
    if (!job) {
      logger.warn(`任务不存在: ${name}`);
      return {
        success: false,
        error: 'Job not found'
      };
    }

    logger.info(`手动触发任务: ${job.name}`);

    return await job.task();
  }

  // 获取调度器状态
  getStatus() {
    return {
      totalJobs: this.jobs.size,
      runningJobs: this.jobs.filter(j => j.enabled).size,
      stoppedJobs: this.jobs.filter(j => !j.enabled).size,
      jobs: this.getAllJobsStatus()
    };
  }

  // 停止所有任务
  stopAll() {
    logger.info('停止所有任务...');

    for (const [name, job] of this.jobs.entries()) {
      job.job.stop();
      job.enabled = false;
    }

    this.isRunning = false;
    logger.info('✅ 所有任务已停止');
  }

  // 启动所有任务
  startAll() {
    logger.info('启动所有任务...');

    for (const [name, job] of this.jobs.entries()) {
      if (job.enabled) {
        job.job.start();
      }
    }

    this.isRunning = true;
    logger.info('✅ 所有任务已启动');
  }
}

// 导出单例
module.exports = new CronScheduler();
