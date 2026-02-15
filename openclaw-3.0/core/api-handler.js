// openclaw-3.0/core/api-handler.js
// 统一 API 调用层 - 集中式稳定性控制

const axios = require('axios');
const winston = require('winston');
const errorLogger = winston.createLogger({
  level: 'error',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/api-errors.log' }),
    new winston.transports.Console({ format: winston.format.simple() })
  ]
});

class APIHandler {
  constructor() {
    this.MAX_RETRIES = 3;
    this.RETRY_DELAYS = [1000, 3000, 5000]; // 初始 1s, 最大 5s
    this.DEFAULT_CONFIG = {
      timeout: 30000,
      headers: {
        'Content-Type': 'application/json'
      }
    };
  }

  /**
   * 调用外部 API - 统一接口
   * @param {Object} options - API 调用选项
   * @param {string} options.url - API URL
   * @param {Object} options.payload - 请求数据
   * @param {Object} options.config - 额外配置
   * @returns {Promise<Object>} API 响应数据
   */
  async callAPI(options) {
    const { url, payload, config = {} } = options;
    const finalConfig = { ...this.DEFAULT_CONFIG, ...config };
    let retryCount = 0;

    while (retryCount <= this.MAX_RETRIES) {
      try {
        const response = await axios({
          url,
          method: 'POST',
          data: payload,
          ...finalConfig
        });

        // 记录成功调用
        this.recordSuccess();

        return response.data;

      } catch (error) {
        retryCount++;

        // 记录错误
        this.recordError(error);

        // 检查是否应该重试
        if (!this.shouldRetry(error, retryCount)) {
          throw error;
        }

        // 计算延迟时间（指数退避）
        const delay = this.RETRY_DELAYS[Math.min(retryCount - 1, this.RETRY_DELAYS.length - 1)];

        // 记录重试
        errorLogger.info({
          action: 'api_retry',
          url,
          retryCount,
          delay,
          error: error.message
        });

        await this.sleep(delay);
      }
    }

    // 达到最大重试次数仍失败
    throw new Error(`API call failed after ${this.MAX_RETRIES} retries`);
  }

  /**
   * 判断是否应该重试
   * @param {Error} error - 错误对象
   * @param {number} retryCount - 当前重试次数
   * @returns {boolean}
   */
  shouldRetry(error, retryCount) {
    // 429 Too Many Requests - 必须重试
    if (error.response?.status === 429) {
      return true;
    }

    // 5xx 服务器错误 - 可以重试
    if (error.response?.status >= 500 && error.response?.status < 600) {
      return retryCount <= this.MAX_RETRIES;
    }

    // 网络错误 - 可以重试
    if (!error.response && error.code === 'ECONNABORTED') {
      return retryCount <= this.MAX_RETRIES;
    }

    // 其他错误 - 不重试
    return false;
  }

  /**
   * 记录成功调用
   */
  recordSuccess() {
    // TODO: 通知 Metrics Tracker
  }

  /**
   * 记录错误
   * @param {Error} error
   */
  recordError(error) {
    errorLogger.error({
      action: 'api_error',
      status: error.response?.status,
      statusText: error.response?.statusText,
      error: error.message,
      url: error.config?.url
    });
  }

  /**
   * 延迟函数
   * @param {number} ms - 毫秒
   * @returns {Promise<void>}
   */
  sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

module.exports = new APIHandler();
