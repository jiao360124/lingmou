// openclaw-3.0/report-scheduler.js
// 报告调度器 - 定时生成和发送报告

const { spawn } = require('child_process');
const fs = require('fs').promises;
const path = require('path');
const winston = require('winston');

// 日志配置
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/report-scheduler.log' }),
    new winston.transports.Console({ format: winston.format.simple() })
  ]
});

/**
 * 📊 报告调度器
 * 定时生成和发送每日/每周报告
 */
class ReportScheduler {
  constructor(options = {}) {
    this.config = {
      reportsDir: options.reportsDir || 'reports',
      logsDir: options.logsDir || 'logs',
      sender: options.sender || 'report-sender.js',
      generator: options.generator || 'report-generator.js',
      dailyTime: options.dailyTime || '02:00',
      weeklyTime: options.weeklyTime || '03:00',
      timezone: options.timezone || 'Asia/Shanghai'
    };

    this.scheduler = null;
    this.requestLogger = null;

    logger.info('ReportScheduler initialized');
  }

  /**
   * 🔧 初始化 Request Logger
   * @param {Object} requestLogger - Request Logger 实例
   * @returns {void}
   */
  initRequestLogger(requestLogger) {
    this.requestLogger = requestLogger;
    logger.info('Request Logger initialized');
  }

  /**
   * 📅 添加每日报告任务
   * @returns {Object} 任务ID
   */
  addDailyReportTask() {
    return this.scheduler.addTask(
      'daily-report',
      `0 ${this.config.dailyTime} * * *`,
      async () => {
        await this.generateDailyReport();
      },
      {
        description: 'Generate daily report',
        maxRetries: 3
      }
    );
  }

  /**
   * 📅 添加每周报告任务
   * @returns {Object} 任务ID
   */
  addWeeklyReportTask() {
    return this.scheduler.addTask(
      'weekly-report',
      `0 ${this.config.weeklyTime} * * 0`,
      async () => {
        await this.generateWeeklyReport();
      },
      {
        description: 'Generate weekly report',
        maxRetries: 3
      }
    );
  }

  /**
   * 📊 生成每日报告
   * @returns {Promise<void>}
   */
  async generateDailyReport() {
    logger.info('📄 Generating daily report...');

    try {
      // 执行报告生成器
      const generatorPath = path.join(__dirname, this.config.generator);
      const process = spawn('node', [generatorPath], {
        cwd: __dirname,
        stdio: ['pipe', 'pipe', 'pipe']
      });

      let stdout = '';
      let stderr = '';

      process.stdout.on('data', (data) => {
        stdout += data.toString();
      });

      process.stderr.on('data', (data) => {
        stderr += data.toString();
      });

      process.on('close', async (code) => {
        if (code === 0) {
          logger.info('✅ Daily report generated');
          logger.debug(`Output: ${stdout}`);

          // 发送报告
          await this.sendReport('daily');
        } else {
          logger.error(`❌ Daily report generation failed (code ${code})`);
          logger.error(`Error: ${stderr}`);
        }
      });

    } catch (error) {
      logger.error(`❌ Failed to generate daily report: ${error.message}`);
      throw error;
    }
  }

  /**
   * 📊 生成每周报告
   * @returns {Promise<void>}
   */
  async generateWeeklyReport() {
    logger.info('📄 Generating weekly report...');

    try {
      // 执行报告生成器
      const generatorPath = path.join(__dirname, this.config.generator);
      const process = spawn('node', [generatorPath], {
        cwd: __dirname,
        stdio: ['pipe', 'pipe', 'pipe']
      });

      let stdout = '';
      let stderr = '';

      process.stdout.on('data', (data) => {
        stdout += data.toString();
      });

      process.stderr.on('data', (data) => {
        stderr += data.toString();
      });

      process.on('close', async (code) => {
        if (code === 0) {
          logger.info('✅ Weekly report generated');
          logger.debug(`Output: ${stdout}`);

          // 发送报告
          await this.sendReport('weekly');
        } else {
          logger.error(`❌ Weekly report generation failed (code ${code})`);
          logger.error(`Error: ${stderr}`);
        }
      });

    } catch (error) {
      logger.error(`❌ Failed to generate weekly report: ${error.message}`);
      throw error;
    }
  }

  /**
   * 📧 发送报告
   * @param {string} reportType - 报告类型
   * @returns {Promise<void>}
   */
  async sendReport(reportType) {
    logger.info(`📨 Sending ${reportType} report...`);

    try {
      const senderPath = path.join(__dirname, this.config.sender);
      const process = spawn('node', [senderPath], {
        cwd: __dirname,
        stdio: ['pipe', 'pipe', 'pipe']
      });

      let stdout = '';
      let stderr = '';

      process.stdout.on('data', (data) => {
        stdout += data.toString();
      });

      process.stderr.on('data', (data) => {
        stderr += data.toString();
      });

      process.on('close', async (code) => {
        if (code === 0) {
          logger.info(`✅ ${reportType} report sent successfully`);
          logger.debug(`Output: ${stdout}`);
        } else {
          logger.error(`❌ ${reportType} report sending failed (code ${code})`);
          logger.error(`Error: ${stderr}`);
        }
      });

    } catch (error) {
      logger.error(`❌ Failed to send ${reportType} report: ${error.message}`);
      throw error;
    }
  }

  /**
   * 🚀 启动报告调度器
   * @returns {Promise<void>}
   */
  async start() {
    if (!this.scheduler) {
      this.scheduler = require('./scheduler');
    }

    logger.info('🚀 Starting Report Scheduler...');

    // 初始化 Request Logger
    if (this.requestLogger) {
      this.scheduler.initRequestLogger(this.requestLogger);
    }

    // 添加报告任务
    this.addDailyReportTask();
    this.addWeeklyReportTask();

    // 启动调度器
    await this.scheduler.start();

    logger.info('✅ Report Scheduler started');
  }

  /**
   * ⏸️ 停止报告调度器
   * @returns {Promise<void>}
   */
  async stop() {
    logger.info('⏸️ Stopping Report Scheduler...');

    if (this.scheduler) {
      await this.scheduler.stop();
    }

    logger.info('✅ Report Scheduler stopped');
  }

  /**
   * 📊 获取任务列表
   * @returns {Array} 任务列表
   */
  getTasks() {
    return this.scheduler.getTasks();
  }

  /**
   * 📊 获取调度器状态
   * @returns {Object} 状态信息
   */
  getStats() {
    return {
      scheduler: this.scheduler ? this.scheduler.getStats() : null
    };
  }

  /**
   * 📝 手动触发报告生成
   * @param {string} reportType - 报告类型
   * @returns {Promise<void>}
   */
  async manualGenerate(reportType) {
    logger.info(`📋 Manual ${reportType} report generation requested`);

    if (reportType === 'daily') {
      await this.generateDailyReport();
    } else if (reportType === 'weekly') {
      await this.generateWeeklyReport();
    } else {
      throw new Error(`Invalid report type: ${reportType}`);
    }
  }

  /**
   * 📧 手动发送报告
   * @param {string} reportType - 报告类型
   * @returns {Promise<void>}
   */
  async manualSend(reportType) {
    logger.info(`📤 Manual ${reportType} report sending requested`);

    if (reportType === 'daily') {
      await this.sendReport('daily');
    } else if (reportType === 'weekly') {
      await this.sendReport('weekly');
    } else {
      throw new Error(`Invalid report type: ${reportType}`);
    }
  }
}

module.exports = ReportScheduler;
