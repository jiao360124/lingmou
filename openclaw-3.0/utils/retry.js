/**
 * 重试机制
 * 支持指数退避、最大重试次数、随机抖动
 */

const { getConfig } = require('../config');
const logger = require('./logger');

/**
 * 重试策略
 */
class RetryStrategy {
  constructor(options = {}) {
    this.maxRetries = options.maxRetries || getConfig().retry.maxRetries;
    this.baseDelay = options.baseDelay || getConfig().retry.delay;
    this.backoff = options.backoff !== undefined ? options.backoff : getConfig().retry.backoff;
    this.jitter = options.jitter !== undefined ? options.jitter : true;
    this.shouldRetry = options.shouldRetry || this.defaultShouldRetry;
    this.onRetry = options.onRetry || this.defaultOnRetry;
    this.logger = options.logger || logger;
  }

  /**
   * 默认的重试条件
   */
  defaultShouldRetry(error) {
    // 网络错误、超时、服务错误等可重试
    const retryableCodes = [
      'ECONNRESET',
      'ENOTFOUND',
      'ETIMEDOUT',
      'ECONNREFUSED',
      'EPIPE',
      'EHOSTUNREACH',
      'ENETDOWN',
      'ENETUNREACH',
      'ECONNABORTED',
    ];

    const retryableNames = [
      'HttpError',
      'AxiosError',
      'TimeoutError',
      'ServiceUnavailableError',
    ];

    const retryableStatusCodes = [408, 429, 500, 502, 503, 504];

    return (
      retryableCodes.includes(error.code) ||
      retryableNames.includes(error.name) ||
      retryableStatusCodes.includes(error.response?.status)
    );
  }

  /**
   * 默认的重试回调
   */
  defaultOnRetry(retryCount, delay, error) {
    this.logger.warn('Retrying...', {
      retry: retryCount,
      delay: `${delay}ms`,
      error: error.message,
    });
  }

  /**
   * 计算延迟时间
   */
  calculateDelay(retryCount) {
    let delay = this.baseDelay * Math.pow(2, retryCount);

    // 添加随机抖动（0-100ms）
    if (this.jitter) {
      delay += Math.random() * 100;
    }

    return delay;
  }

  /**
   * 执行带重试的异步操作
   */
  async execute(fn, context = {}) {
    let lastError;
    let retryCount = 0;

    while (retryCount <= this.maxRetries) {
      try {
        this.logger.debug('Executing operation', {
          retry: retryCount,
          ...context,
        });

        const result = await fn();
        return result;
      } catch (error) {
        lastError = error;

        // 检查是否应该重试
        if (retryCount >= this.maxRetries || !this.shouldRetry(error)) {
          this.logger.error('Operation failed, no more retries', {
            retry: retryCount,
            error: error.message,
            ...context,
          });
          break;
        }

        // 计算延迟时间
        const delay = this.calculateDelay(retryCount);

        // 执行重试回调
        this.onRetry(retryCount, delay, error);

        // 等待
        await this.sleep(delay);

        retryCount++;
      }
    }

    throw lastError;
  }

  /**
   * 执行带重试的同步操作
   */
  executeSync(fn, context = {}) {
    let lastError;
    let retryCount = 0;

    while (retryCount <= this.maxRetries) {
      try {
        this.logger.debug('Executing operation', {
          retry: retryCount,
          ...context,
        });

        const result = fn();
        return result;
      } catch (error) {
        lastError = error;

        // 检查是否应该重试
        if (retryCount >= this.maxRetries || !this.shouldRetry(error)) {
          this.logger.error('Operation failed, no more retries', {
            retry: retryCount,
            error: error.message,
            ...context,
          });
          break;
        }

        // 计算延迟时间
        const delay = this.calculateDelay(retryCount);

        // 执行重试回调
        this.onRetry(retryCount, delay, error);

        // 等待
        this.sleepSync(delay);

        retryCount++;
      }
    }

    throw lastError;
  }

  /**
   * 等待（异步）
   */
  sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * 等待（同步）
   */
  sleepSync(ms) {
    const start = Date.now();
    while (Date.now() - start < ms) {
      // 空循环，等待
    }
  }

  /**
   * 创建重试装饰器
   */
  decorate(fn, options = {}) {
    return async (...args) => {
      return this.execute(fn, { ...options, args });
    };
  }
}

/**
 * 单例重试策略
 */
class RetryManager {
  constructor() {
    this.strategies = new Map();
  }

  /**
   * 获取或创建重试策略
   */
  getStrategy(name, options) {
    if (!this.strategies.has(name)) {
      this.strategies.set(name, new RetryStrategy({ ...options, logger }));
    }
    return this.strategies.get(name);
  }

  /**
   * 执行重试
   */
  async execute(name, fn, context = {}) {
    const strategy = this.getStrategy(name);
    return strategy.execute(fn, context);
  }

  /**
   * 执行同步重试
   */
  executeSync(name, fn, context = {}) {
    const strategy = this.getStrategy(name);
    return strategy.executeSync(fn, context);
  }

  /**
   * 创建装饰器
   */
  decorate(name, fn, options) {
    const strategy = this.getStrategy(name);
    return strategy.decorate(fn, options);
  }
}

// 创建全局重试管理器
const retryManager = new RetryManager();

module.exports = retryManager;
module.exports.RetryStrategy = RetryStrategy;
module.exports.RetryManager = RetryManager;
