// openclaw-3.0/core/circuit-breaker.js
// Circuit Breaker + Half-Open Recovery - 自动恢复机制

const winston = require('winston');
const fs = require('fs').promises;

// 日志配置
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/circuit-breaker.log' }),
    new winston.transports.Console({ format: winston.format.simple() })
  ]
});

class CircuitBreaker {
  constructor(options = {}) {
    // 配置
    this.config = {
      maxFailures: options.maxFailures || 3,        // 最大连续失败次数
      resetTimeout: options.resetTimeout || 10 * 60 * 1000, // 10 分钟
      halfOpenMaxSuccesses: options.halfOpenMaxSuccesses || 1, // 半开测试允许成功次数
      successThreshold: options.successThreshold || 0.8,    // 成功率阈值（用于恢复）
      monitorInterval: options.monitorInterval || 60000     // 监控间隔
    };

    // 状态机
    this.state = 'CLOSED'; // CLOSED, OPEN, HALF-OPEN
    this.failures = 0;
    this.successesInHalfOpen = 0;
    this.lastFailureTime = null;
    this.lastSuccessTime = null;
    this.failuresHistory = []; // 记录失败历史（用于趋势分析）

    // 统计
    this.stats = {
      totalRequests: 0,
      successRequests: 0,
      failureRequests: 0,
      totalCallTime: 0
    };

    // Provider 信息
    this.providerName = options.providerName || 'Unknown';
    this.currentHealth = 100; // 0-100

    // 监控定时器
    this.monitorInterval = null;

    logger.info(`Circuit Breaker initialized for ${this.providerName}`);
    this.startMonitoring();
  }

  /**
   * 🔄 监控定时器
   */
  startMonitoring() {
    if (this.monitorInterval) {
      clearInterval(this.monitorInterval);
    }

    this.monitorInterval = setInterval(() => {
      this.monitorHealth();
    }, this.config.monitorInterval);

    logger.info(`Monitoring started for ${this.providerName} (${this.config.monitorInterval}ms)`);
  }

  /**
   * 📊 监控健康度
   */
  monitorHealth() {
    const now = Date.now();

    // 检查是否需要从 HALF-OPEN 自动恢复到 CLOSED
    if (this.state === 'HALF-OPEN') {
      // 如果半开测试已经成功多次，且时间超过 5 分钟
      if (this.successesInHalfOpen >= this.config.halfOpenMaxSuccesses &&
          now - this.lastSuccessTime > 5 * 60 * 1000) {
        logger.info(`✅ Provider ${this.providerName} recovering from HALF-OPEN to CLOSED`);
        this.reset();
      }
    }

    // 检查是否需要从 OPEN 自动恢复到 HALF-OPEN
    if (this.state === 'OPEN' && now - this.lastFailureTime > this.config.resetTimeout) {
      logger.info(`🔄 Provider ${this.providerName} transitioning from OPEN to HALF-OPEN`);
      this.state = 'HALF-OPEN';
      this.successesInHalfOpen = 0;
    }
  }

  /**
   * 📡 检查是否允许调用
   * @returns {Object} { allowed, state, reason }
   */
  check() {
    this.stats.totalRequests++;

    if (this.state === 'CLOSED') {
      return {
        allowed: true,
        state: 'CLOSED',
        reason: 'Normal operation'
      };
    }

    if (this.state === 'HALF-OPEN') {
      // 半开测试：允许 1 次尝试
      return {
        allowed: true,
        state: 'HALF-OPEN',
        reason: 'Half-open testing: 1 attempt allowed'
      };
    }

    if (this.state === 'OPEN') {
      // 开放状态：拒绝调用
      return {
        allowed: false,
        state: 'OPEN',
        reason: `Provider ${this.providerName} is in OPEN state (failed ${this.failures} times). Try again later.`
      };
    }

    return {
      allowed: true,
      state: 'UNKNOWN',
      reason: 'Unknown state'
    };
  }

  /**
   * ✅ 记录成功
   * @param {number} latency - 延迟（ms）
   */
  recordSuccess(latency) {
    this.stats.successRequests++;
    this.stats.totalCallTime += latency;

    this.failures = 0; // 重置失败计数
    this.failuresHistory.push({ success: true, timestamp: Date.now() });

    // 保持最近 100 条历史
    if (this.failuresHistory.length > 100) {
      this.failuresHistory.shift();
    }

    // 更新健康度（成功 = +5%，上限 100）
    this.currentHealth = Math.min(100, this.currentHealth + 5);

    logger.debug(`✅ Provider ${this.providerName} success recorded (latency: ${latency}ms)`);
  }

  /**
   * ❌ 记录失败
   * @param {Error} error - 错误对象
   * @param {string} errorType - 错误类型（例如：429, TIMEOUT, NETWORK）
   */
  recordFailure(error, errorType = 'UNKNOWN') {
    this.stats.failureRequests++;
    this.failures++;
    this.lastFailureTime = Date.now();

    this.failuresHistory.push({ success: false, timestamp: Date.now(), error: error.message });

    // 保持最近 100 条历史
    if (this.failuresHistory.length > 100) {
      this.failuresHistory.shift();
    }

    // 更新健康度（失败 = -10%，下限 0）
    this.currentHealth = Math.max(0, this.currentHealth - 10);

    // 状态机转换
    if (this.state === 'CLOSED' && this.failures >= this.config.maxFailures) {
      logger.error(`🚨 Circuit Breaker opened for ${this.providerName} (failures: ${this.failures})`);
      this.state = 'OPEN';
    }

    if (this.state === 'HALF-OPEN') {
      // 半开测试失败，重新进入 OPEN
      this.state = 'OPEN';
      logger.warn(`⚠️ Provider ${this.providerName} failed in HALF-OPEN state, returning to OPEN`);
    }

    logger.error(`❌ Provider ${this.providerName} failure recorded: ${errorType} - ${error.message}`);
  }

  /**
   * 🔄 重置状态（恢复为 CLOSED）
   */
  reset() {
    this.state = 'CLOSED';
    this.failures = 0;
    this.successesInHalfOpen = 0;
    logger.info(`✅ Circuit Breaker reset for ${this.providerName}`);
  }

  /**
   * 🎯 手动打开 Circuit Breaker
   */
  open() {
    this.state = 'OPEN';
    logger.warn(`⚠️ Circuit Breaker manually opened for ${this.providerName}`);
  }

  /**
   * 🎯 手动关闭 Circuit Breaker
   */
  close() {
    this.reset();
    logger.info(`✅ Circuit Breaker manually closed for ${this.providerName}`);
  }

  /**
   * 📊 获取状态
   * @returns {Object} 当前状态信息
   */
  getStatus() {
    return {
      state: this.state,
      failures: this.failures,
      successesInHalfOpen: this.successesInHalfOpen,
      lastFailureTime: this.lastFailureTime,
      lastSuccessTime: this.lastSuccessTime,
      currentHealth: this.currentHealth,
      stats: { ...this.stats }
    };
  }

  /**
   * 📊 获取历史数据
   * @returns {Array} 失败/成功历史
   */
  getHistory() {
    return this.failuresHistory;
  }

  /**
   * 📊 获取健康度报告
   * @returns {Object} 详细报告
   */
  getHealthReport() {
    const now = Date.now();

    // 计算最近 1 小时的成功率
    const oneHourAgo = now - 3600000;
    const recentHistory = this.failuresHistory.filter(h => h.timestamp > oneHourAgo);

    const successCount = recentHistory.filter(h => h.success).length;
    const failureCount = recentHistory.filter(h => !h.success).length;
    const successRate = recentHistory.length > 0
      ? (successCount / recentHistory.length) * 100
      : 100;

    // 计算平均延迟
    const avgLatency = this.stats.successRequests > 0
      ? Math.round(this.stats.totalCallTime / this.stats.successRequests)
      : 0;

    return {
      provider: this.providerName,
      state: this.state,
      currentHealth: this.currentHealth,
      recentSuccessRate: successRate.toFixed(2),
      avgLatency: avgLatency,
      recentFailures: failureCount,
      config: {
        maxFailures: this.config.maxFailures,
        resetTimeout: this.config.resetTimeout,
        halfOpenMaxSuccesses: this.config.halfOpenMaxSuccesses
      }
    };
  }

  /**
   * 📝 保存状态到文件
   */
  async saveState() {
    const state = {
      state: this.state,
      failures: this.failures,
      successesInHalfOpen: this.successesInHalfOpen,
      lastFailureTime: this.lastFailureTime,
      lastSuccessTime: this.lastSuccessTime,
      currentHealth: this.currentHealth,
      stats: this.stats,
      config: this.config,
      timestamp: Date.now()
    };

    try {
      await fs.mkdir('data', { recursive: true });
      await fs.writeFile(`data/circuit-breaker-${this.providerName}.json`, JSON.stringify(state, null, 2));
    } catch (error) {
      logger.error('Failed to save Circuit Breaker state:', error);
    }
  }

  /**
   * 📝 加载状态从文件
   */
  async loadState() {
    try {
      const data = await fs.readFile(`data/circuit-breaker-${this.providerName}.json`, 'utf-8');
      const state = JSON.parse(data);

      this.state = state.state;
      this.failures = state.failures;
      this.successesInHalfOpen = state.successesInHalfOpen;
      this.lastFailureTime = state.lastFailureTime;
      this.lastSuccessTime = state.lastSuccessTime;
      this.currentHealth = state.currentHealth;
      this.stats = state.stats;
      this.config = state.config;

      logger.info(`Circuit Breaker state loaded for ${this.providerName}`);
    } catch (error) {
      logger.info(`No saved state found for ${this.providerName}, starting fresh`);
    }
  }

  /**
   * 🔧 健康度诊断
   * @returns {Object} 诊断结果
   */
  diagnose() {
    const report = this.getHealthReport();

    let diagnosis = 'Normal';
    let severity = 'INFO';

    if (report.state === 'OPEN') {
      diagnosis = 'CRITICAL: Provider is in OPEN state';
      severity = 'CRITICAL';
    } else if (report.state === 'HALF-OPEN') {
      diagnosis = 'WARNING: Provider is in HALF-OPEN state (testing)';
      severity = 'WARNING';
    } else if (report.currentHealth < 50) {
      diagnosis = 'WARNING: Provider health is low (< 50%)';
      severity = 'WARNING';
    } else if (report.currentHealth < 80) {
      diagnosis = 'INFO: Provider health is moderate (50-80%)';
      severity = 'INFO';
    } else {
      diagnosis = 'INFO: Provider health is good (> 80%)';
      severity = 'INFO';
    }

    return {
      ...report,
      diagnosis,
      severity
    };
  }

  /**
   * 📦 导出配置（用于配置文件）
   */
  exportConfig() {
    return {
      maxFailures: this.config.maxFailures,
      resetTimeout: this.config.resetTimeout,
      halfOpenMaxSuccesses: this.config.halfOpenMaxSuccesses,
      successThreshold: this.config.successThreshold,
      monitorInterval: this.config.monitorInterval
    };
  }
}

module.exports = CircuitBreaker;
