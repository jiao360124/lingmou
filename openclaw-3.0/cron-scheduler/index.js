/**
 * Cron Scheduler
 * 使用统一配置、日志、错误处理和重试机制
 */

const cron = require('node-cron');
const logger = require('./utils/logger');
const errorHandler = require('./utils/error-handler');
const retryManager = require('./utils/retry');
const config = require('./config/cron.config');
const { sendReport, createDailyReport, createWeeklyReport } = require('../report-sender');

// ==================== 配置 ====================

const SCHEDULER_ENABLED = config.scheduler.enabled;
const SCHEDULER_TIMEZONE = config.scheduler.timezone;
const MAX_CONCURRENT_JOBS = config.scheduler.maxConcurrentJobs;

const GATEWAY_CHECK_ENABLED = config.jobs.gatewayCheck.enabled;
const GATEWAY_CHECK_INTERVAL = config.jobs.gatewayCheck.interval;
const GATEWAY_CHECK_ALERT = config.jobs.gatewayCheck.alertOnFailure;

const HEARTBEAT_CHECK_ENABLED = config.jobs.heartbeatCheck.enabled;
const HEARTBEAT_CHECK_INTERVAL = config.jobs.heartbeatCheck.interval;

const DAILY_REPORT_ENABLED = config.jobs.dailyReport.enabled;
const DAILY_REPORT_SCHEDULE = config.jobs.dailyReport.schedule;
const DAILY_REPORT_TIMEZONE = config.jobs.dailyReport.timezone;

const WEEKLY_REPORT_ENABLED = config.jobs.weeklyReport.enabled;
const WEEKLY_REPORT_SCHEDULE = config.jobs.weeklyReport.schedule;
const WEEKLY_REPORT_TIMEZONE = config.jobs.weeklyReport.timezone;

// ==================== 辅助函数 ====================

/**
 * 执行 Job（带日志和错误处理）
 */
async function executeJob(jobName, jobFn, context = {}) {
  const startTime = Date.now();

  try {
    logger.debug(`Job starting: ${jobName}`, { ...context });

    const result = await jobFn();

    const duration = Date.now() - startTime;
    logJobSuccess(jobName, duration, { ...context, result });

    return result;
  } catch (error) {
    const duration = Date.now() - startTime;
    logJobError(jobName, error, { ...context, duration });

    // 如果是 Gateway 检查失败，发送通知
    if (jobName === 'gatewayCheck' && error.code === 'ECONNREFUSED' && GATEWAY_CHECK_ALERT) {
      await sendAlertNotification(error);
    }

    throw errorHandler.createError(
      errorHandler.ErrorType.SERVICE_ERROR,
      `Job ${jobName} failed: ${error.message}`,
      { error, ...context }
    );
  }
}

/**
 * 记录 Job 成功
 */
function logJobSuccess(jobName, duration, context = {}) {
  logger.info(`Job completed: ${jobName}`, {
    duration: `${duration}ms`,
    ...context,
  });
}

/**
 * 记录 Job 错误
 */
function logJobError(jobName, error, context = {}) {
  logger.error(`Job failed: ${jobName}`, {
    error: error.message,
    code: error.code,
    stack: error.stack,
    ...context,
  });
}

/**
 * 发送警报通知
 */
async function sendAlertNotification(error) {
  try {
    const alertMessage = `⚠️ Gateway Check Failed

**错误**: ${error.message}
**错误码**: ${error.code}
**时间**: ${new Date().toISOString()}

建议检查 Gateway 服务状态。`;

    // 发送 Telegram 通知
    if (config.notifications.telegram.enabled && config.notifications.telegram.botToken) {
      await sendTelegramNotification(alertMessage);
    }

    // 发送邮件通知
    if (config.notifications.email.enabled) {
      await sendEmailNotification(alertMessage);
    }
  } catch (notificationError) {
    logger.error('Failed to send alert notification', {
      error: notificationError.message,
    });
  }
}

/**
 * 发送 Telegram 通知
 */
async function sendTelegramNotification(message) {
  if (!config.notifications.telegram.enabled) {
    return;
  }

  const { botToken, chatId } = config.notifications.telegram;

  if (!botToken || !chatId) {
    logger.warn('Telegram notification disabled (missing config)');
    return;
  }

  try {
    const response = await fetch(`https://api.telegram.org/bot${botToken}/sendMessage`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        chat_id: chatId,
        text: message,
        parse_mode: 'markdown',
      }),
    });

    const data = await response.json();

    if (!data.ok) {
      logger.error('Failed to send Telegram notification', {
        error: data.description,
      });
    }
  } catch (error) {
    logger.error('Error sending Telegram notification', {
      error: error.message,
    });
  }
}

/**
 * 发送邮件通知
 */
async function sendEmailNotification(message) {
  // TODO: 实现 nodemailer 邮件发送
  logger.debug('Email notification not implemented');
}

// ==================== Gateway 检查 ====================

async function performGatewayCheck() {
  try {
    logger.debug('Performing Gateway check');

    // TODO: 实际的 Gateway 状态检查
    // 这里只是一个示例
    const result = {
      status: 'ok',
      responseTime: 0,
      timestamp: new Date().toISOString(),
    };

    logger.info('Gateway check completed', result);
    return result;
  } catch (error) {
    logger.error('Gateway check failed', {
      error: error.message,
      code: error.code,
    });
    throw error;
  }
}

/**
 * 创建 Gateway 检查 Job
 */
function createGatewayCheckJob() {
  if (!GATEWAY_CHECK_ENABLED) {
    logger.debug('Gateway check job disabled');
    return null;
  }

  logger.info('Creating Gateway check job', {
    interval: GATEWAY_CHECK_INTERVAL,
  });

  return cron.schedule(
    GATEWAY_CHECK_INTERVAL,
    async () => {
      logger.debug('Gateway check job triggered');
      await executeJob('gatewayCheck', performGatewayCheck);
    },
    { timezone: SCHEDULER_TIMEZONE }
  );
}

// ==================== 心跳检查 ====================

async function performHeartbeatCheck() {
  try {
    logger.debug('Performing Heartbeat check');

    // TODO: 实际的心跳检查逻辑
    const result = {
      status: 'ok',
      timestamp: new Date().toISOString(),
    };

    logger.info('Heartbeat check completed', result);
    return result;
  } catch (error) {
    logger.error('Heartbeat check failed', {
      error: error.message,
    });
    throw error;
  }
}

/**
 * 创建心跳检查 Job
 */
function createHeartbeatCheckJob() {
  if (!HEARTBEAT_CHECK_ENABLED) {
    logger.debug('Heartbeat check job disabled');
    return null;
  }

  logger.info('Creating Heartbeat check job', {
    interval: HEARTBEAT_CHECK_INTERVAL,
  });

  return cron.schedule(
    HEARTBEAT_CHECK_INTERVAL,
    async () => {
      logger.debug('Heartbeat check job triggered');
      await executeJob('heartbeatCheck', performHeartbeatCheck);
    },
    { timezone: SCHEDULER_TIMEZONE }
  );
}

// ==================== 每日报告 ====================

async function generateDailyReport() {
  try {
    logger.debug('Generating daily report');

    // TODO: 从实际数据源获取报告数据
    const data = {
      date: new Date().toISOString().split('T')[0],
      uptime: 3600,
      metrics: {
        totalRequests: 1000,
        errors: 10,
        successRate: 0.99,
        avgResponseTime: 150,
      },
      costs: {
        total: 10.5,
        daily: 2.3,
      },
      errors: [],
    };

    const report = createDailyReport(data);
    logger.info('Daily report generated', { date: data.date });

    return report;
  } catch (error) {
    logger.error('Failed to generate daily report', {
      error: error.message,
    });
    throw error;
  }
}

/**
 * 创建每日报告 Job
 */
function createDailyReportJob() {
  if (!DAILY_REPORT_ENABLED) {
    logger.debug('Daily report job disabled');
    return null;
  }

  logger.info('Creating daily report job', {
    schedule: DAILY_REPORT_SCHEDULE,
    timezone: DAILY_REPORT_TIMEZONE,
  });

  return cron.schedule(
    DAILY_REPORT_SCHEDULE,
    async () => {
      logger.debug('Daily report job triggered');
      const report = await executeJob('dailyReport', generateDailyReport);

      // 发送报告
      await sendReport(report);
    },
    { timezone: DAILY_REPORT_TIMEZONE }
  );
}

// ==================== 每周报告 ====================

async function generateWeeklyReport() {
  try {
    logger.debug('Generating weekly report');

    // TODO: 从实际数据源获取报告数据
    const data = {
      period: 'Week 1',
      uptime: 259200,
      metrics: {
        totalRequests: 5000,
        errors: 50,
        successRate: 0.99,
      },
      costs: {
        total: 15.7,
      },
      trends: {
        requestTrend: 'increasing',
        costTrend: 'stable',
      },
    };

    const report = createWeeklyReport(data);
    logger.info('Weekly report generated', { period: data.period });

    return report;
  } catch (error) {
    logger.error('Failed to generate weekly report', {
      error: error.message,
    });
    throw error;
  }
}

/**
 * 创建每周报告 Job
 */
function createWeeklyReportJob() {
  if (!WEEKLY_REPORT_ENABLED) {
    logger.debug('Weekly report job disabled');
    return null;
  }

  logger.info('Creating weekly report job', {
    schedule: WEEKLY_REPORT_SCHEDULE,
    timezone: WEEKLY_REPORT_TIMEZONE,
  });

  return cron.schedule(
    WEEKLY_REPORT_SCHEDULE,
    async () => {
      logger.debug('Weekly report job triggered');
      const report = await executeJob('weeklyReport', generateWeeklyReport);

      // 发送报告
      await sendReport(report);
    },
    { timezone: WEEKLY_REPORT_TIMEZONE }
  );
}

// ==================== 启动调度器 ====================

/**
 * 启动所有 Jobs
 */
function startScheduler() {
  if (!SCHEDULER_ENABLED) {
    logger.warn('Cron scheduler is disabled');
    return null;
  }

  logger.info('Cron scheduler starting', {
    timezone: SCHEDULER_TIMEZONE,
    maxConcurrentJobs: MAX_CONCURRENT_JOBS,
  });

  // 创建 Jobs
  const jobs = {
    gatewayCheck: createGatewayCheckJob(),
    heartbeatCheck: createHeartbeatCheckJob(),
    dailyReport: createDailyReportJob(),
    weeklyReport: createWeeklyReportJob(),
  };

  // 过滤掉 disabled 的 jobs
  const enabledJobs = Object.entries(jobs)
    .filter(([name, job]) => job !== null)
    .map(([name, job]) => ({ name, job }));

  logger.info('Cron scheduler started', {
    enabledJobs: enabledJobs.map(j => j.name),
    totalJobs: Object.keys(jobs).length,
  });

  // 返回停止函数
  return {
    jobs,
    stop: () => {
      logger.info('Cron scheduler stopping');

      Object.values(jobs).forEach(job => {
        if (job) job.stop();
      });

      logger.info('Cron scheduler stopped');
    },
    getStatus: () => ({
      enabled: SCHEDULER_ENABLED,
      timezone: SCHEDULER_TIMEZONE,
      jobs: Object.fromEntries(
        Object.entries(jobs).map(([name, job]) => [
          name,
          {
            enabled: job !== null,
            running: job?.nextInvocation ? true : false,
          },
        ])
      ),
    }),
  };
}

// ==================== 导出 ====================

module.exports = {
  startScheduler,
  executeJob,
  performGatewayCheck,
  performHeartbeatCheck,
  generateDailyReport,
  generateWeeklyReport,
  GATEWAY_CHECK_ENABLED,
  HEARTBEAT_CHECK_ENABLED,
  DAILY_REPORT_ENABLED,
  WEEKLY_REPORT_ENABLED,
};
