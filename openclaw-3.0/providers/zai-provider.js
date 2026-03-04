// openclaw-3.0/providers/zai-provider.js
// ZAI GLM Provider

const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/zai-provider.log', level: 'info' }),
    new winston.transports.Console({ format: winston.format.simple() })
  ]
});

class ZaiProvider {
  constructor(config = {}) {
    this.config = config;
    this.apiKey = process.env.ZAI_API_KEY || config.apiKey;
    this.baseUrl = process.env.ZAI_BASE_URL || 'https://api.zhipuai.cn/v4';

    if (!this.apiKey) {
      logger.error('❌ ZAI API Key not found');
      throw new Error('ZAI_API_KEY environment variable required');
    }

    this.providerName = 'ZAI GLM';

    logger.info('✅ ZAI Provider initialized');
  }

  /**
   * 发送聊天请求
   * @param {Array} messages - 消息数组
   * @param {Object} options - 选项
   * @returns {Promise<Object>} 响应
   */
  async chat(messages, options = {}) {
    try {
      logger.info({
        action: 'zai_chat_start',
        baseUrl: this.baseUrl,
        messageCount: messages.length
      });

      const response = await fetch(`${this.baseUrl}/chat/completions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.apiKey}`
        },
        body: JSON.stringify({
          model: options.model || 'glm-4-flash',
          messages: messages,
          stream: options.stream || false,
          temperature: options.temperature || 0.7,
          max_tokens: options.max_tokens || 2000
        })
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error?.message || `HTTP ${response.status}`);
      }

      const data = await response.json();

      logger.info({
        action: 'zai_chat_success',
        model: data.model,
        usage: data.usage
      });

      return data;
    } catch (error) {
      logger.error({
        action: 'zai_chat_failed',
        error: error.message,
        errorType: error.code
      });

      throw new Error(`ZAI error: ${error.message}`);
    }
  }

  /**
   * 获取模型信息
   * @returns {Object} 模型信息
   */
  getModelInfo() {
    return {
      id: 'glm-4.7-flash',
      alias: 'GLM',
      provider: this.providerName,
      tier: 1
    };
  }

  /**
   * 测试连接
   * @returns {Promise<boolean>} 连接是否成功
   */
  async testConnection() {
    try {
      const result = await this.chat([
        { role: 'user', content: 'Hello' }
      ], { stream: false });

      if (result && result.choices && result.choices[0]) {
        logger.info('✅ ZAI connection test passed');
        return true;
      }
      return false;
    } catch (error) {
      logger.error('❌ ZAI connection test failed:', error.message);
      return false;
    }
  }
}

module.exports = ZaiProvider;
