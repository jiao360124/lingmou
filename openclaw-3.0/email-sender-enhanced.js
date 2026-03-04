// email-sender-enhanced.js - 增强版Email发送器
// 支持Gmail、Outlook、QQ邮箱等多平台

const nodemailer = require('nodemailer');
const fs = require('fs').promises;
const path = require('path');
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

class EmailSenderEnhanced {
  constructor(config = {}) {
    this.config = config;
    this.transporter = null;
    this.templates = new Map();
    this.senderHistory = [];
    this.maxHistory = 100;
    this.initialize();
  }

  // 初始化邮件传输器
  async initialize() {
    if (!this.config.smtp) {
      logger.warn('SMTP 配置未找到，Email 发送功能未启用');
      return false;
    }

    try {
      // 创建传输器
      this.transporter = nodemailer.createTransport({
        host: this.config.smtp.host,
        port: this.config.smtp.port,
        secure: this.config.smtp.secure || false,
        auth: {
          user: this.config.smtp.user,
          pass: this.config.smtp.password
        },
        tls: {
          rejectUnauthorized: this.config.smtp.rejectUnauthorized !== false
        }
      });

      // 测试连接
      await this.transporter.verify();
      logger.info('✅ Email 传输器初始化成功');

      // 加载模板
      await this.loadTemplates();

      // 加载发送历史
      await this.loadSenderHistory();

      return true;
    } catch (err) {
      logger.error('❌ Email 传输器初始化失败:', err.message);
      return false;
    }
  }

  // 加载邮件模板
  async loadTemplates() {
    const templateDir = path.join(__dirname, 'templates/email');

    try {
      // 读取默认模板
      const defaultTemplates = {
        dailyReport: this.getDefaultDailyReportTemplate(),
        weeklyReport: this.getDefaultWeeklyReportTemplate(),
        alert: this.getDefaultAlertTemplate()
      };

      // 合并模板
      for (const [name, template] of Object.entries(defaultTemplates)) {
        this.templates.set(name, template);
      }

      logger.info(`✅ 加载 ${this.templates.size} 个邮件模板`);
    } catch (err) {
      logger.error('加载模板失败:', err.message);
    }
  }

  // 默认每日报告模板
  getDefaultDailyReportTemplate() {
    return {
      subject: (data) => `📊 OpenClaw 每日报告 - ${data.date}`,
      html: (data) => `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 20px; border-radius: 8px 8px 0 0;">
            <h1 style="margin: 0; color: white;">📊 OpenClaw 每日报告</h1>
          </div>
          <div style="padding: 20px; background: white; border: 1px solid #e0e0e0; border-radius: 0 0 8px 8px;">
            <p style="color: #666;">日期: ${data.date}</p>

            <h2 style="margin-top: 20px;">📈 核心指标</h2>
            <table style="width: 100%; border-collapse: collapse; margin-top: 10px;">
              <tr style="background: #f5f5f5;">
                <td style="padding: 12px; border: 1px solid #e0e0e0; font-weight: bold;">指标</td>
                <td style="padding: 12px; border: 1px solid #e0e0e0;">数值</td>
              </tr>
              <tr>
                <td style="padding: 12px; border: 1px solid #e0e0e0;">今日调用</td>
                <td style="padding: 12px; border: 1px solid #e0e0e0;">${data.dailyCalls || 0}</td>
              </tr>
              <tr>
                <td style="padding: 12px; border: 1px solid #e0e0e0;">成功次数</td>
                <td style="padding: 12px; border: 1px solid #e0e0e0; color: green;">${data.successfulCalls || 0}</td>
              </tr>
              <tr>
                <td style="padding: 12px; border: 1px solid #e0e0e0;">失败次数</td>
                <td style="padding: 12px; border: 1px solid #e0e0e0; color: red;">${data.failedCalls || 0}</td>
              </tr>
              <tr>
                <td style="padding: 12px; border: 1px solid #e0e0e0;">成功率</td>
                <td style="padding: 12px; border: 1px solid #e0e0e0;">${data.successRate || 0}%</td>
              </tr>
              <tr>
                <td style="padding: 12px; border: 1px solid #e0e0e0;">Token使用</td>
                <td style="padding: 12px; border: 1px solid #e0e0e0;">${data.totalTokens || 0}</td>
              </tr>
              <tr>
                <td style="padding: 12px; border: 1px solid #e0e0e0;">今日成本</td>
                <td style="padding: 12px; border: 1px solid #e0e0e0;">$${(data.cost || 0).toFixed(2)}</td>
              </tr>
            </table>

            ${data.optimizationSuggestions ? `
              <h2 style="margin-top: 20px;">💡 优化建议</h2>
              <ul style="margin-top: 10px;">
                ${data.optimizationSuggestions.map(s => `
                  <li style="margin: 8px 0; padding: 10px; background: #f9f9f9; border-left: 3px solid #667eea;">
                    <strong>${s.title}</strong>: ${s.message}
                  </li>
                `).join('')}
              </ul>
            ` : ''}

            <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #e0e0e0;">
              <p style="color: #999;">此邮件由 OpenClaw 3.0 自动发送，请勿直接回复。</p>
              <p style="color: #999; font-size: 12px;">© 2026 OpenClaw 3.0</p>
            </div>
          </div>
        </div>
      `,
      text: (data) => `
📊 OpenClaw 每日报告
=====================
日期: ${data.date}

📈 核心指标
---------------------
今日调用: ${data.dailyCalls || 0}
成功次数: ${data.successfulCalls || 0}
失败次数: ${data.failedCalls || 0}
成功率: ${data.successRate || 0}%
Token使用: ${data.totalTokens || 0}
今日成本: $${(data.cost || 0).toFixed(2)}

💡 优化建议
---------------------
${data.optimizationSuggestions ? data.optimizationSuggestions.map(s => `${s.title}: ${s.message}`).join('\n') : '无'}

此邮件由 OpenClaw 3.0 自动发送，请勿直接回复。
      `
    };
  }

  // 默认每周报告模板
  getDefaultWeeklyReportTemplate() {
    return {
      subject: (data) => `📊 OpenClaw 每周报告 - 第${data.weekNumber}周 (${data.dateRange})`,
      html: (data) => `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 20px; border-radius: 8px 8px 0 0;">
            <h1 style="margin: 0; color: white;">📊 OpenClaw 每周报告</h1>
          </div>
          <div style="padding: 20px; background: white; border: 1px solid #e0e0e0; border-radius: 0 0 8px 8px;">
            <p style="color: #666;">周期: ${data.dateRange} | 第${data.weekNumber}周</p>

            <h2 style="margin-top: 20px;">📈 本周概览</h2>
            <table style="width: 100%; border-collapse: collapse; margin-top: 10px;">
              <tr style="background: #f5f5f5;">
                <td style="padding: 12px; border: 1px solid #e0e0e0; font-weight: bold;">指标</td>
                <td style="padding: 12px; border: 1px solid #e0e0e0;">数值</td>
              </tr>
              <tr>
                <td style="padding: 12px; border: 1px solid #e0e0e0;">总调用次数</td>
                <td style="padding: 12px; border: 1px solid #e0e0e0;">${data.totalCalls || 0}</td>
              </tr>
              <tr>
                <td style="padding: 12px; border: 1px solid #e0e0e0;">总Token使用</td>
                <td style="padding: 12px; border: 1px solid #e0e0e0;">${data.totalTokens || 0}</td>
              </tr>
              <tr>
                <td style="padding: 12px; border: 1px solid #e0e0e0;">总成本</td>
                <td style="padding: 12px; border: 1px solid #e0e0e0;">$${(data.totalCost || 0).toFixed(2)}</td>
              </tr>
              <tr>
                <td style="padding: 12px; border: 1px solid #e0e0e0;">平均成功率</td>
                <td style="padding: 12px; border: 1px solid #e0e0e0;">${data.avgSuccessRate || 0}%</td>
              </tr>
            </table>

            ${data.weeklySuggestions ? `
              <h2 style="margin-top: 20px;">💡 本周优化建议</h2>
              <ul style="margin-top: 10px;">
                ${data.weeklySuggestions.map(s => `
                  <li style="margin: 8px 0; padding: 10px; background: #f9f9f9; border-left: 3px solid #667eea;">
                    <strong>${s.title}</strong>: ${s.message}
                  </li>
                `).join('')}
              </ul>
            ` : ''}

            <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #e0e0e0;">
              <p style="color: #999;">此邮件由 OpenClaw 3.0 自动发送，请勿直接回复。</p>
              <p style="color: #999; font-size: 12px;">© 2026 OpenClaw 3.0</p>
            </div>
          </div>
        </div>
      `
    };
  }

  // 默认告警模板
  getDefaultAlertTemplate() {
    return {
      subject: (data) => `⚠️  OpenClaw 告警 - ${data.type}`,
      html: (data) => `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); padding: 20px; border-radius: 8px 8px 0 0;">
            <h1 style="margin: 0; color: white;">⚠️  OpenClaw 告警</h1>
          </div>
          <div style="padding: 20px; background: white; border: 1px solid #e0e0e0; border-radius: 0 0 8px 8px;">
            <p style="color: #666;">类型: ${data.type}</p>

            <h2 style="margin-top: 20px;">📋 告警详情</h2>
            <p style="margin: 10px 0;">${data.message}</p>

            ${data.details ? `
              <pre style="background: #f5f5f5; padding: 10px; border-radius: 4px; overflow-x: auto;">
${JSON.stringify(data.details, null, 2)}
              </pre>
            ` : ''}

            <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #e0e0e0;">
              <p style="color: #999;">此告警由 OpenClaw 3.0 自动生成，请勿直接回复。</p>
              <p style="color: #999; font-size: 12px;">© 2026 OpenClaw 3.0</p>
            </div>
          </div>
        </div>
      `
    };
  }

  // 发送每日报告
  async sendDailyReport(recipient, data = {}) {
    const template = this.templates.get('dailyReport');
    if (!template) {
      logger.error('每日报告模板未找到');
      return { success: false, error: 'Template not found' };
    }

    return await this.sendEmail({
      to: recipient,
      subject: template.subject(data),
      html: template.html(data),
      text: template.text(data)
    });
  }

  // 发送每周报告
  async sendWeeklyReport(recipient, data = {}) {
    const template = this.templates.get('weeklyReport');
    if (!template) {
      logger.error('每周报告模板未找到');
      return { success: false, error: 'Template not found' };
    }

    return await this.sendEmail({
      to: recipient,
      subject: template.subject(data),
      html: template.html(data),
      text: template.text(data)
    });
  }

  // 发送告警
  async sendAlert(recipient, type, message, details = {}) {
    const template = this.templates.get('alert');
    if (!template) {
      logger.error('告警模板未找到');
      return { success: false, error: 'Template not found' };
    }

    return await this.sendEmail({
      to: recipient,
      subject: template.subject({ type }),
      html: template.html({ type, message, details }),
      text: `⚠️  OpenClaw 告警 - ${type}\n\n${message}\n\n${details ? JSON.stringify(details, null, 2) : ''}`
    });
  }

  // 发送邮件
  async sendEmail(mailOptions) {
    if (!this.transporter) {
      return { success: false, error: 'Email sender not initialized' };
    }

    const startTime = Date.now();
    let retryCount = 0;

    try {
      while (retryCount <= 3) {
        try {
          const info = await this.transporter.sendMail(mailOptions);

          // 记录发送历史
          this.recordSenderHistory({
            to: mailOptions.to,
            subject: mailOptions.subject,
            timestamp: new Date(),
            status: 'success',
            messageId: info.messageId,
            executionTime: Date.now() - startTime
          });

          logger.info(`✅ 邮件发送成功: ${info.messageId}`);
          return {
            success: true,
            messageId: info.messageId,
            executionTime: Date.now() - startTime
          };
        } catch (error) {
          retryCount++;

          if (retryCount <= 3) {
            logger.warn(`⚠️  邮件发送失败，第 ${retryCount} 次重试...`);
            await new Promise(resolve => setTimeout(resolve, 1000 * retryCount));
          } else {
            // 最终失败
            this.recordSenderHistory({
              to: mailOptions.to,
              subject: mailOptions.subject,
              timestamp: new Date(),
              status: 'failed',
              error: error.message,
              executionTime: Date.now() - startTime
            });

            logger.error(`❌ 邮件发送失败: ${error.message}`);
            return {
              success: false,
              error: error.message,
              retryCount
            };
          }
        }
      }
    } catch (err) {
      logger.error('❌ 邮件发送异常:', err.message);
      return {
        success: false,
        error: err.message
      };
    }
  }

  // 记录发送历史
  recordSenderHistory(record) {
    this.senderHistory.push(record);

    // 限制历史记录长度
    if (this.senderHistory.length > this.maxHistory) {
      this.senderHistory = this.senderHistory.slice(-this.maxHistory);
    }

    // 保存到文件
    this.saveSenderHistory();
  }

  // 保存发送历史
  async saveSenderHistory() {
    try {
      await fs.writeFile(
        path.join(__dirname, 'email-sender-history.json'),
        JSON.stringify(this.senderHistory, null, 2),
        'utf-8'
      );
    } catch (err) {
      logger.error('保存发送历史失败:', err.message);
    }
  }

  // 加载发送历史
  async loadSenderHistory() {
    try {
      const historyPath = path.join(__dirname, 'email-sender-history.json');
      if (await fs.access(historyPath).then(() => true).catch(() => false)) {
        const content = await fs.readFile(historyPath, 'utf-8');
        this.senderHistory = JSON.parse(content);
        logger.info(`✅ 加载发送历史: ${this.senderHistory.length} 条记录`);
      }
    } catch (err) {
      logger.warn('加载发送历史失败:', err.message);
    }
  }

  // 获取发送历史
  getSenderHistory(filters = {}) {
    let history = [...this.senderHistory];

    // 应用过滤器
    if (filters.status) {
      history = history.filter(h => h.status === filters.status);
    }

    if (filters.recipient) {
      history = history.filter(h => h.to.includes(filters.recipient));
    }

    if (filters.startDate) {
      history = history.filter(h => new Date(h.timestamp) >= new Date(filters.startDate));
    }

    if (filters.endDate) {
      history = history.filter(h => new Date(h.timestamp) <= new Date(filters.endDate));
    }

    return history.slice(-100); // 最多返回100条
  }

  // 获取发送统计
  getSenderStats() {
    const total = this.senderHistory.length;
    const success = this.senderHistory.filter(h => h.status === 'success').length;
    const failed = this.senderHistory.filter(h => h.status === 'failed').length;
    const successRate = total > 0 ? ((success / total) * 100).toFixed(2) : 0;

    return {
      total,
      success,
      failed,
      successRate: parseFloat(successRate)
    };
  }

  // 关闭传输器
  async close() {
    if (this.transporter) {
      await this.transporter.close();
      logger.info('✅ Email 传输器已关闭');
    }
  }
}

module.exports = EmailSenderEnhanced;
