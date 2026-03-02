/**
 * Report Sender
 * 发送报告到Telegram和Email
 */

const Telegram = require('telegram-bot-api');
const nodemailer = require('nodemailer');

/**
 * 发送Telegram消息
 */
async function sendToTelegram(report, config) {
  if (!config.telegramToken || !config.telegramChatId) {
    throw new Error('Telegram配置不完整');
  }

  const bot = new Telegram(config.telegramToken, { polling: false });

  const message = generateTelegramMessage(report);
  const result = await bot.sendMessage(config.telegramChatId, message, {
    parse_mode: 'HTML',
    disable_web_page_preview: true
  });

  return result;
}

/**
 * 生成Telegram消息
 */
function generateTelegramMessage(report) {
  const title = report.title;
  const summary = report.summary || '暂无摘要';

  return `
✨ *${title}* ✨

${summary}

📊 *统计数据*
${generateStatsSection(report.stats)}

🚀 *改进建议*
${report.recommendations?.map(r => `• ${r}`).join('\n') || '暂无'}

---
📅 ${report.date || new Date().toLocaleString()}
  `.trim();
}

/**
 * 生成统计数据部分
 */
function generateStatsSection(stats) {
  return Object.entries(stats || {})
    .map(([key, value]) => `• ${key}: ${value}`)
    .join('\n');
}

/**
 * 发送邮件报告
 */
async function sendToEmail(report, config) {
  if (!config.emailConfig || !config.emailConfig.to) {
    throw new Error('Email配置不完整');
  }

  const transporter = nodemailer.createTransport(config.emailConfig);

  const mailOptions = {
    from: config.emailConfig.from || 'noreply@openclaw.ai',
    to: config.emailConfig.to,
    subject: report.title,
    text: generateEmailText(report),
    html: generateEmailHTML(report),
    attachments: []
  };

  if (config.attachReportFile && report.reportPath) {
    mailOptions.attachments.push({
      filename: path.basename(report.reportPath),
      path: report.reportPath
    });
  }

  const result = await transporter.sendMail(mailOptions);
  return result;
}

/**
 * 生成纯文本格式
 */
function generateEmailText(report) {
  const { title, summary, date, details } = report;

  let text = `${title}\n\n${summary}\n\n`;
  text += `📅 日期: ${date}\n`;

  if (details?.costs) {
    text += `💰 成本: ${details.costs.current} ${details.costs.unit}\n`;
  }

  if (details?.performance) {
    text += `⚡ 性能: ${details.performance.avgLatency}ms, 成功率 ${details.performance.successRate}%\n`;
  }

  if (details?.recommendations) {
    text += `\n建议:\n${details.recommendations.map(r => `- ${r}`).join('\n')}\n`;
  }

  return text;
}

/**
 * 生成HTML格式
 */
function generateEmailHTML(report) {
  const { title, summary, date, stats, details } = report;

  return `
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: #3b82f6; color: white; padding: 20px; border-radius: 8px 8px 0 0; }
    .content { background: #f9fafb; padding: 20px; }
    .section { margin-bottom: 20px; }
    .stat-row { display: flex; justify-content: space-between; padding: 8px 0; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>${title}</h1>
    </div>
    <div class="content">
      <p><strong>日期:</strong> ${date}</p>
      <p><strong>摘要:</strong></p>
      <p>${summary}</p>

      <div class="section">
        <h3>📊 统计数据</h3>
        ${stats ? Object.entries(stats).map(([key, value]) => `
          <div class="stat-row">
            <span>${key}:</span>
            <strong>${value}</strong>
          </div>
        `).join('') : ''}
      </div>

      ${details?.recommendations ? `
        <div class="section">
          <h3>🚀 改进建议</h3>
          <ul>
            ${details.recommendations.map(r => `<li>${r}</li>`).join('')}
          </ul>
        </div>
      ` : ''}

      <p style="font-size: 12px; color: #6b7280;">
        ————
        <br>报告生成时间: ${new Date().toLocaleString()}
      </p>
    </div>
  </div>
</body>
</html>
  `.trim();
}

/**
 * 发送报告（支持Telegram和Email）
 */
async function sendReport(report, config, sendTo = ['telegram', 'email']) {
  const results = {
    telegram: null,
    email: null,
    errors: []
  };

  if (sendTo.includes('telegram')) {
    try {
      results.telegram = await sendToTelegram(report, config);
    } catch (error) {
      results.errors.push({ channel: 'telegram', error: error.message });
    }
  }

  if (sendTo.includes('email')) {
    try {
      results.email = await sendToEmail(report, config);
    } catch (error) {
      results.errors.push({ channel: 'email', error: error.message });
    }
  }

  return results;
}

/**
 * 配置自动发送
 */
function setupAutoSend(config) {
  const { sendFrequency = 'daily', sendChannels = ['telegram'] } = config;

  // 根据频率定时发送
  setInterval(async () => {
    const report = await generateReport();
    await sendReport(report, config, sendChannels);
  }, getIntervalInMs(sendFrequency));

  return () => {
    // 清除定时器
    clearInterval(intervalId);
  };
}

/**
 * 获取间隔毫秒数
 */
function getIntervalInMs(frequency) {
  switch (frequency) {
    case 'hourly':
      return 60 * 60 * 1000;
    case 'daily':
      return 24 * 60 * 60 * 1000;
    case 'weekly':
      return 7 * 24 * 60 * 60 * 1000;
    default:
      return 24 * 60 * 60 * 1000;
  }
}

module.exports = {
  sendToTelegram,
  sendToEmail,
  sendReport,
  setupAutoSend
};
