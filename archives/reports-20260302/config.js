/**
 * Report Configuration
 */

module.exports = {
  // Telegram配置
  telegram: {
    enabled: true,
    token: process.env.TELEGRAM_TOKEN || '',
    chatId: process.env.TELEGRAM_CHAT_ID || '',
    sendChannels: ['telegram']
  },

  // Email配置
  email: {
    enabled: true,
    to: process.env.EMAIL_TO || '',
    from: process.env.EMAIL_FROM || 'noreply@openclaw.ai',
    config: {
      service: 'gmail',
      auth: {
        user: process.env.EMAIL_USER || '',
        pass: process.env.EMAIL_PASS || ''
      }
    }
  },

  // 报告配置
  report: {
    generateDaily: true,
    generateWeekly: true,
    sendDaily: true,
    sendWeekly: true,
    attachReportFile: true
  },

  // 自动发送配置
  autoSend: {
    enabled: true,
    frequency: 'daily', // hourly | daily | weekly
    sendChannels: ['telegram'], // telegram | email | both
    time: '09:00', // 发送时间
    timezone: 'Asia/Shanghai'
  }
};
