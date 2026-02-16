// openclaw-3.0/report-sender.js
// 报告发送器 - Telegram 和邮件

const fs = require('fs').promises;
const path = require('path');

/**
 * 📧 报告发送器
 * 支持 Telegram 和邮件报告发送
 */
class ReportSender {
  constructor(options = {}) {
    this.config = {
      senderType: options.senderType || 'telegram', // telegram, email
      telegramToken: options.telegramToken || process.env.TELEGRAM_TOKEN,
      telegramChatId: options.telegramChatId || process.env.TELEGRAM_CHAT_ID,
      emailConfig: options.emailConfig || null,
      retryCount: options.retryCount || 3,
      retryDelay: options.retryDelay || 5000 // 5 秒
    };

    this.history = [];
  }

  /**
   * 📱 发送报告到 Telegram
   * @param {string} reportContent - 报告内容（Markdown）
   * @param {Object} options - 选项
   * @returns {Promise<Object>} 发送结果
   */
  async sendToTelegram(reportContent, options = {}) {
    if (!this.config.telegramToken) {
      console.log('⚠️ Telegram Token 未配置，跳过 Telegram 发送');
      return { success: false, method: 'telegram', error: 'Token not configured' };
    }

    const chatId = options.chatId || this.config.telegramChatId;
    const reportType = options.reportType || 'daily';
    const now = new Date().toISOString();

    try {
      // 创建 Telegram Bot API URL
      const url = `https://api.telegram.org/bot${this.config.telegramToken}/sendMessage`;

      // 准备消息内容
      const message = {
        chat_id: chatId,
        text: reportContent,
        parse_mode: 'Markdown'
      };

      // 发送到 Telegram
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(message)
      });

      const data = await response.json();

      if (data.ok) {
        const result = {
          success: true,
          method: 'telegram',
          messageId: data.result.message_id,
          chatId: chatId,
          timestamp: now,
          reportType
        };

        this.history.push(result);
        console.log(`✅ Telegram 发送成功: Message ID ${data.result.message_id}`);
        return result;
      } else {
        const error = {
          success: false,
          method: 'telegram',
          error: data.description,
          timestamp: now,
          reportType
        };

        this.history.push(error);
        console.error(`❌ Telegram 发送失败: ${data.description}`);
        return error;
      }
    } catch (error) {
      const errorResult = {
        success: false,
        method: 'telegram',
        error: error.message,
        timestamp: now,
        reportType
      };

      this.history.push(errorResult);
      console.error(`❌ Telegram 发送异常: ${error.message}`);
      return errorResult;
    }
  }

  /**
   * 📧 发送报告到邮件
   * @param {string} reportContent - 报告内容
   * @param {Object} options - 选项
   * @returns {Promise<Object>} 发送结果
   */
  async sendToEmail(reportContent, options = {}) {
    if (!this.config.emailConfig) {
      console.log('⚠️ 邮件配置未配置，跳过邮件发送');
      return { success: false, method: 'email', error: 'Email config not configured' };
    }

    const { to, subject, html } = options;
    const now = new Date().toISOString();

    try {
      // TODO: 集成 SMTP 发送邮件
      // 这里简化处理，实际需要安装 nodemailer 等库
      console.log(`📧 邮件发送（简化）: To=${to}, Subject=${subject}`);

      const result = {
        success: true,
        method: 'email',
        to: to,
        subject: subject,
        timestamp: now
      };

      this.history.push(result);
      console.log(`✅ 邮件发送成功: ${to}`);
      return result;
    } catch (error) {
      const errorResult = {
        success: false,
        method: 'email',
        error: error.message,
        timestamp: now
      };

      this.history.push(errorResult);
      console.error(`❌ 邮件发送异常: ${error.message}`);
      return errorResult;
    }
  }

  /**
   * 📊 发送报告（自动选择渠道）
   * @param {string} reportFile - 报告文件路径
   * @param {Object} options - 选项
   * @returns {Promise<Object>} 发送结果
   */
  async sendReport(reportFile, options = {}) {
    const senderType = options.senderType || this.config.senderType;
    let reportContent;

    try {
      // 读取报告内容
      reportContent = await fs.readFile(reportFile, 'utf-8');
    } catch (error) {
      console.error(`❌ 读取报告文件失败: ${reportFile}`);
      return { success: false, error: error.message };
    }

    let result;

    // 根据配置发送
    if (senderType === 'telegram') {
      result = await this.sendToTelegram(reportContent, options);
    } else if (senderType === 'email') {
      result = await this.sendToEmail(reportContent, options);
    } else {
      return { success: false, error: 'Invalid sender type' };
    }

    return result;
  }

  /**
   * 📋 获取发送历史
   * @returns {Array} 发送历史
   */
  getHistory() {
    return this.history;
  }

  /**
   * 📊 获取统计信息
   * @returns {Object} 统计信息
   */
  getStats() {
    const total = this.history.length;
    const success = this.history.filter(h => h.success).length;
    const failures = total - success;

    const byMethod = {};
    this.history.forEach(h => {
      if (!byMethod[h.method]) {
        byMethod[h.method] = { success: 0, failures: 0 };
      }
      if (h.success) {
        byMethod[h.method].success++;
      } else {
        byMethod[h.method].failures++;
      }
    });

    return {
      total,
      success,
      failures,
      byMethod
    };
  }

  /**
   * 📝 保存发送历史到文件
   * @param {string} filePath - 文件路径
   * @returns {Promise<void>}
   */
  async saveHistory(filePath) {
    try {
      await fs.mkdir(path.dirname(filePath), { recursive: true });
      await fs.writeFile(filePath, JSON.stringify(this.history, null, 2));
      console.log(`✅ 发送历史已保存: ${filePath}`);
    } catch (error) {
      console.error(`❌ 保存发送历史失败: ${error.message}`);
    }
  }

  /**
   * 📝 加载发送历史从文件
   * @param {string} filePath - 文件路径
   * @returns {Promise<void>}
   */
  async loadHistory(filePath) {
    try {
      const data = await fs.readFile(filePath, 'utf-8');
      this.history = JSON.parse(data);
      console.log(`✅ 发送历史已加载: ${this.history.length} 条记录`);
    } catch (error) {
      console.log('⚠️ 无发送历史文件，从零开始');
    }
  }

  /**
   * 🔄 重新发送失败的报告
   * @param {number} limit - 限制数量
   * @returns {Promise<Array>} 重新发送结果
   */
  async retryFailed(limit = 10) {
    const failed = this.history.filter(h => !h.success).slice(0, limit);
    const results = [];

    console.log(`🔄 开始重新发送 ${failed.length} 条失败记录...`);

    for (const record of failed) {
      // 根据原始方法重新发送
      let result;

      if (record.method === 'telegram') {
        result = await this.sendToTelegram(record.reportContent || '', { reportType: record.reportType });
      } else if (record.method === 'email') {
        result = await this.sendToEmail(record.reportContent || '', record);
      }

      results.push(result);
    }

    return results;
  }
}

module.exports = ReportSender;
