// openclaw-3.0/providers/openrouter.js
// OpenRouter Provider - Tier 4 免费逃生舱

const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/openrouter.log', level: 'info' }),
    new winston.transports.Console({ format: winston.format.simple() })
  ]
});

class OpenRouterProvider {
  constructor(config = {}) {
    this.config = config;
    this.apiKey = process.env.OPENROUTER_API_KEY || config.apiKey;
    this.model = config.model || 'arcee-ai/trinity-large-preview:free';

    if (!this.apiKey) {
      logger.error('❌ OpenRouter API Key not found');
      throw new Error('OPENROUTER_API_KEY environment variable required');
    }

    this.baseUrl = process.env.OPENROUTER_BASE_URL || 'https://openrouter.ai/api/v1';
    this.providerName = 'OpenRouter Trinity';

    logger.info('✅ OpenRouter Provider initialized');
    logger.info(`  Model: ${this.model}`);
    logger.info(`  API Key: ${this.apiKey.substring(0, 10)}...`);
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
        action: 'openrouter_chat_start',
        model: this.model,
        messageCount: messages.length
      });

      const response = await fetch(`${this.baseUrl}/chat/completions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.apiKey}`,
          'HTTP-Referer': 'https://openclaw.ai',  // 必填，OpenRouter 要求
          'X-Title': 'OpenClaw Trinity'  // 必填，OpenRouter 要求
        },
        body: JSON.stringify({
          model: this.model,
          messages: messages,
          stream: options.stream || false,
          temperature: options.temperature || 0.7,
          max_tokens: options.max_tokens || 2000
        })
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.error?.message || `HTTP ${response.status}`);
      }

      const data = await response.json();

      logger.info({
        action: 'openrouter_chat_success',
        model: data.model,
        usage: data.usage
      });

      return data;
    } catch (error) {
      logger.error({
        action: 'openrouter_chat_failed',
        error: error.message,
        errorType: error.code
      });

      throw new Error(`OpenRouter error: ${error.message}`);
    }
  }

  /**
   * 获取模型信息
   * @returns {Object} 模型信息
   */
  getModelInfo() {
    return {
      id: this.model,
      alias: 'TRINITY-FREE',
      provider: this.providerName,
      tier: 4,
      isFree: true,
      isFallback: true
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
        logger.info('✅ OpenRouter connection test passed');
        return true;
      }
      return false;
    } catch (error) {
      logger.error('❌ OpenRouter connection test failed:', error.message);
      return false;
    }
  }
}

module.exports = OpenRouterProvider;
