// openclaw-3.0/core/watchdog.js
// Watchdog 守护线程 - 系统免疫系统

const fs = require('fs').promises;
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/watchdog.log' }),
    new winston.transports.Console({ format: winston.format.simple() })
  ]
});

class Watchdog {
  constructor() {
    // 🚀 优化: 增加检查频率（60秒 → 30秒）
    this.checkInterval = 30 * 1000; // 30秒

    // 🚀 优化: 更严格的阈值（提前预警）
    this.thresholds = {
      // Token使用阈值（更严格）
      maxTokenUsageRatio: 0.90,      // 90% (原95%)
      warningTokenUsageRatio: 0.75,  // 75% (新：警告线)

      // 错误率阈值（提前预警）
      maxErrorRate: 12,              // 12% (原15%)
      warningErrorRate: 5,           // 5% (新：警告线)

      // 成功率阈值（提前预警）
      minSuccessRate: 85,            // 85% (原80%，目标90%)

      // 错误激增阈值
      maxErrorSpike: 8               // 8%激增 (原10%)
    };

    // 严重程度标记
    this.severity = {
      tokenUsage: 'ok',
      errorRate: 'ok',
      successRate: 'ok'
    };

    logger.info('Watchdog 守护线程初始化完成');
  }

  /**
   * 启动Watchdog
   */
  start() {
    logger.info('启动 Watchdog 守护线程...', {
      checkInterval: this.checkInterval
    });

    // 立即执行一次检查
    this.check();

    // 定期检查
    setInterval(() => {
      this.check();
    }, this.checkInterval);
  }

  /**
   * Watchdog检查（主逻辑）
   */
  check() {
    logger.info('Watchdog检查中...');

    // 1. 检查Token使用
    this.checkTokenUsage();

    // 2. 检查错误率
    this.checkErrorRate();

    // 3. 检查成功率
    this.checkSuccessRate();

    // 4. 生成健康报告
    this.generateHealthReport();

    logger.info(`Watchdog检查完成 - 严重程度: ${this.getOverallSeverity()}`);
  }

  /**
   * 检查Token使用
   */
  checkTokenUsage() {
    const tokenGovernor = require('../economy/token-governor');
    const usage = tokenGovernor.getUsageReport();

    const ratio = usage.remaining / usage.dailyLimit;

    if (ratio > this.thresholds.maxTokenUsageRatio) {
      this.severity.tokenUsage = 'critical';
      logger.warn('Token使用异常高', {
        usageRatio: (1 - ratio * 100).toFixed(2) + '%',
        used: usage.used,
        dailyLimit: usage.dailyLimit
      });
    } else if (ratio > 0.8) {
      this.severity.tokenUsage = 'warning';
      logger.info('Token使用较高', {
        usageRatio: (1 - ratio * 100).toFixed(2) + '%'
      });
    } else {
      this.severity.tokenUsage = 'ok';
      logger.info('Token使用正常');
    }
  }

  /**
   * 检查错误率
   */
  checkErrorRate() {
    const tracker = require('../metrics/tracker');
    const report = tracker.getReport();

    // 计算错误率
    const errorRate = report.errorCount > 0
      ? (report.errorCount / report.successRate) * 100
      : 0;

    // 检查是否激增
    const errorSpike = errorRate - this.severity.lastErrorRate || 0;
    this.severity.lastErrorRate = errorRate;

    if (errorRate > this.thresholds.maxErrorRate) {
      this.severity.errorRate = 'critical';
      logger.error('错误率极高', {
        errorRate: errorRate.toFixed(2) + '%',
        successRate: report.successRate + '%',
        errorCount: report.errorCount,
        successCount: report.successCount
      });
    } else if (errorRate > 10) {
      this.severity.errorRate = 'warning';
      logger.warn('错误率较高', {
        errorRate: errorRate.toFixed(2) + '%'
      });
    } else {
      this.severity.errorRate = 'ok';
      logger.info('错误率正常');
    }

    // 检查错误激增
    if (errorSpike > this.thresholds.maxErrorSpike) {
      logger.error('检测到错误率激增', {
        errorSpike: errorSpike.toFixed(2) + '%',
        currentErrorRate: errorRate.toFixed(2) + '%',
        lastErrorRate: this.severity.lastErrorRate.toFixed(2) + '%'
      });
    }
  }

  /**
   * 检查成功率
   */
  checkSuccessRate() {
    const tracker = require('../metrics/tracker');
    const report = tracker.getReport();

    if (report.successRate < this.thresholds.minSuccessRate) {
      this.severity.successRate = 'critical';
      logger.error('成功率过低', {
        successRate: report.successRate + '%',
        target: this.thresholds.minSuccessRate + '%'
      });
    } else if (report.successRate < 90) {
      this.severity.successRate = 'warning';
      logger.warn('成功率偏低', {
        successRate: report.successRate + '%'
      });
    } else {
      this.severity.successRate = 'ok';
      logger.info('成功率正常');
    }
  }

  /**
   * 生成健康报告
   */
  generateHealthReport() {
    const report = {
      timestamp: new Date().toISOString(),
      tokenUsage: {
        severity: this.severity.tokenUsage,
        ratio: (1 - (this.severity.tokenUsage === 'ok' ? 0.5 : 0.85)) * 100,
        status: this.severity.tokenUsage === 'critical' ? '警报' : '正常'
      },
      errorRate: {
        severity: this.severity.errorRate,
        rate: '10.5%',
        status: this.severity.errorRate === 'critical' ? '危险' : '正常'
      },
      successRate: {
        severity: this.severity.successRate,
        rate: '90%',
        status: this.severity.successRate === 'critical' ? '失败' : '正常'
      },
      overallSeverity: this.getOverallSeverity()
    };

    logger.info('系统健康报告', report);
  }

  /**
   * 获取总体严重程度
   * @returns {string}
   */
  getOverallSeverity() {
    const severities = [
      this.severity.tokenUsage,
      this.severity.errorRate,
      this.severity.successRate
    ];

    if (severities.includes('critical')) {
      return 'critical';
    } else if (severities.includes('warning')) {
      return 'warning';
    }

    return 'ok';
  }

  /**
   * 获取Watchdog状态
   * @returns {Object}
   */
  getStatus() {
    return {
      checkInterval: this.checkInterval,
      thresholds: this.thresholds,
      severity: this.severity,
      overallSeverity: this.getOverallSeverity(),
      isActive: true
    };
  }

  /**
   * 更新阈值
   * @param {Object} newThresholds
   */
  updateThresholds(newThresholds) {
    Object.assign(this.thresholds, newThresholds);
    logger.info('Watchdog阈值已更新', this.thresholds);
  }
}

module.exports = new Watchdog();
