/**
 * Report Sender
 * 使用统一配置、日志、错误处理和重试机制
 */

const fetch = require('node-fetch');
const logger = require('./utils/logger');
const errorHandler = require('./utils/error-handler');
const retryManager = require('./utils/retry');
const config = require('./config/report.config');

// ==================== 配置 ====================

const TELEGRAM_ENABLED = config.telegram.enabled;
const EMAIL_ENABLED = config.email.enabled;
const REPORT_RETRY_MAX_RETRIES = config.sender.retry.maxRetries;
const REPORT_RETRY_DELAY = config.sender.retry.delay;
const REPORT_RETRY_BACKOFF = config.sender.retry.backoff;

// ==================== Telegram 发送 ====================

async function sendTelegram(report) {
  if (!TELEGRAM_ENABLED) {
    throw errorHandler.createError(
      errorHandler.ErrorType.CONFIG_ERROR,
      'Telegram sender is not enabled'
    );
  }

  const botToken = config.telegram.botToken;
  const chatId = config.telegram.chatId;

  if (!botToken || !chatId) {
    throw errorHandler.createError(
      errorHandler.ErrorType.CONFIG_ERROR,
      'Telegram configuration is incomplete (botToken or chatId missing)'
    );
  }

  return retryManager.execute('telegram-sender', async () => {
    logger.debug('Sending report via Telegram', { chatId });

    const response = await fetch(`https://api.telegram.org/bot${botToken}/sendMessage`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        chat_id: chatId,
        text: report,
        parse_mode: config.telegram.messageFormat,
        disable_web_page_preview: true,
      }),
    });

    const data = await response.json();

    if (!data.ok) {
      throw errorHandler.createError(
        errorHandler.ErrorType.SERVICE_ERROR,
        `Telegram API error: ${data.description}`,
        { apiError: data }
      );
    }

    logger.info('Telegram report sent successfully', { chatId });

    return data;
  });
}

// ==================== 邮件发送 ====================

async function sendEmail(report) {
  if (!EMAIL_ENABLED) {
    throw errorHandler.createError(
      errorHandler.ErrorType.CONFIG_ERROR,
      'Email sender is not enabled'
    );
  }

  // TODO: 实现 nodemailer 邮件发送
  logger.warn('Email sender not implemented yet', {
    smtpHost: config.email.smtp.host,
    from: config.email.from,
  });

  throw errorHandler.createError(
    errorHandler.ErrorType.SERVICE_ERROR,
    'Email sender is not implemented',
    { smtpHost: config.email.smtp.host }
  );
}

// ==================== 主发送函数 ====================

async function sendReport(report, options = {}) {
  const { forceRetry = false, retryCount = 0 } = options;

  try {
    logger.info('Sending report', {
      telegramEnabled: TELEGRAM_ENABLED,
      emailEnabled: EMAIL_ENABLED,
      forceRetry,
      retryCount,
    });

    // 优先使用 Telegram，如果启用的话
    if (TELEGRAM_ENABLED) {
      const result = await sendTelegram(report);

      if (result && result.ok) {
        logger.info('Report sent via Telegram successfully');
        return result;
      }
    }

    // 如果 Telegram 失败，尝试邮件
    if (EMAIL_ENABLED) {
      const result = await sendEmail(report);

      if (result) {
        logger.info('Report sent via Email successfully');
        return result;
      }
    }

    throw errorHandler.createError(
      errorHandler.ErrorType.CONFIG_ERROR,
      'No sender available (telegram or email)',
      {
        telegramEnabled: TELEGRAM_ENABLED,
        emailEnabled: EMAIL_ENABLED,
      }
    );
  } catch (error) {
    // 记录错误
    logger.error('Failed to send report', {
      error: error.message,
      type: error.type,
      severity: error.severity,
      telegramEnabled: TELEGRAM_ENABLED,
      emailEnabled: EMAIL_ENABLED,
      forceRetry,
      retryCount,
    });

    // 如果强制重试，重新抛出错误
    if (forceRetry) {
      throw error;
    }

    // 否则，抛出包装后的错误
    throw errorHandler.createError(
      errorHandler.ErrorType.SERVICE_ERROR,
      `Failed to send report: ${error.message}`,
      { error, telegramEnabled: TELEGRAM_ENABLED, emailEnabled: EMAIL_ENABLED }
    );
  }
}

// ==================== 批量发送 ====================

async function sendReports(reports, options = {}) {
  const { maxConcurrent = 3 } = options;

  logger.info('Batch sending reports', {
    count: reports.length,
    telegramEnabled: TELEGRAM_ENABLED,
    emailEnabled: EMAIL_ENABLED,
    maxConcurrent,
  });

  const results = [];

  for (let i = 0; i < reports.length; i += maxConcurrent) {
    const batch = reports.slice(i, i + maxConcurrent);

    const batchResults = await Promise.allSettled(
      batch.map((report, index) =>
        sendReport(report, options).catch(error => ({
          error: true,
          report,
          originalError: error.message,
        }))
      )
    );

    batchResults.forEach((result, index) => {
      const reportIndex = i + index;
      results.push({
        report: reports[reportIndex],
        status: result.status === 'fulfilled' ? 'success' : 'failed',
        data: result.status === 'fulfilled' ? result.value : result.reason,
      });
    });
  }

  const successCount = results.filter(r => r.status === 'success').length;
  const failureCount = results.filter(r => r.status === 'failed').length;

  logger.info('Batch sending completed', {
    total: results.length,
    success: successCount,
    failure: failureCount,
  });

  return results;
}

// ==================== 报告模板 ====================

function createDailyReport(data) {
  const { date, uptime, metrics, costs, errors } = data;

  return `# OpenClaw 每日报告

**日期**: ${date}
**运行时间**: ${Math.floor(uptime)} 秒

## 📊 系统指标

- **总请求数**: ${metrics.totalRequests || 0}
- **错误数**: ${metrics.errors || 0}
- **成功率**: ${(metrics.successRate * 100).toFixed(2)}%
- **平均响应时间**: ${metrics.avgResponseTime}ms

## 💰 成本统计

- **总成本**: $${costs.total || 0}
- **今日成本**: $${costs.daily || 0}

## ⚠️ 错误统计

${errors.length > 0 ? errors.map(e => `- ${e}`).join('\n') : '- 无错误'}

---
*报告生成时间: ${new Date().toISOString()}*`;
}

function createWeeklyReport(data) {
  const { period, uptime, metrics, costs, trends } = data;

  return `# OpenClaw 每周报告

**周期**: ${period}
**总运行时间**: ${Math.floor(uptime)} 秒

## 📊 系统指标

- **总请求数**: ${metrics.totalRequests || 0}
- **错误数**: ${metrics.errors || 0}
- **成功率**: ${(metrics.successRate * 100).toFixed(2)}%

## 💰 成本统计

- **总成本**: $${costs.total || 0}

## 📈 趋势分析

- **请求量趋势**: ${trends.requestTrend || '正常'}
- **成本趋势**: ${trends.costTrend || '正常'}

---
*报告生成时间: ${new Date().toISOString()}*`;
}

// ==================== 导出 ====================

module.exports = {
  sendReport,
  sendReports,
  sendTelegram,
  sendEmail,
  createDailyReport,
  createWeeklyReport,
  REPORT_RETRY_MAX_RETRIES,
  REPORT_RETRY_DELAY,
  TELEGRAM_ENABLED,
  EMAIL_ENABLED,
};
