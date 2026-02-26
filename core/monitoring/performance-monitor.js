// core/performance-monitor.js
// 性能监控模块 - V3.0+V3.2 集成版

const winston = require('winston');
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/performance-monitor.log' }),
    new winston.transports.Console({ format: winston.format.simple() })
  ]
});

class PerformanceMonitor {
  constructor(config = {}) {
    this.config = {
      checkInterval: config.checkInterval || 60000, // 60秒
      warningThresholds: config.warningThresholds || {
        avgLatency: 2000,        // 2秒
        errorRate: 0.05,         // 5%
        successRate: 0.90        // 90%
      },
      criticalThresholds: config.criticalThresholds || {
        avgLatency: 5000,        // 5秒
        errorRate: 0.10,         // 10%
        successRate: 0.80        // 80%
      },
      maxHistory: config.maxHistory || 100
    };

    this.metrics = {
      calls: 0,
      successes: 0,
      failures: 0,
      totalLatency: 0,
      maxLatency: 0,
      minLatency: Infinity,
      latencyHistory: [],
      errorHistory: []
    };

    this.startMonitoring();
  }

  /**
   * 开始监控
   */
  startMonitoring() {
    logger.info('🎯 性能监控模块启动');
    logger.info(`📊 检查间隔: ${this.config.checkInterval}ms`);

    // 定期检查
    setInterval(() => {
      this.check();
    }, this.config.checkInterval);
  }

  /**
   * 记录API调用
   */
  recordCall(latency, success) {
    this.metrics.calls++;
    this.metrics.totalLatency += latency;
    this.metrics.maxLatency = Math.max(this.metrics.maxLatency, latency);
    this.metrics.minLatency = Math.min(this.metrics.minLatency, latency);

    if (success) {
      this.metrics.successes++;
    } else {
      this.metrics.failures++;
      this.metrics.errorHistory.push({
        timestamp: Date.now(),
        latency
      });
    }

    // 记录延迟历史
    this.metrics.latencyHistory.push({
      timestamp: Date.now(),
      latency
    });

    // 限制历史记录数量
    if (this.metrics.latencyHistory.length > this.config.maxHistory) {
      this.metrics.latencyHistory.shift();
    }

    if (this.metrics.errorHistory.length > this.config.maxHistory) {
      this.metrics.errorHistory.shift();
    }
  }

  /**
   * 检查性能指标
   */
  check() {
    const metrics = this.getCurrentMetrics();

    logger.info('📊 性能检查', {
      calls: metrics.calls,
      successRate: metrics.successRate.toFixed(2),
      avgLatency: metrics.avgLatency.toFixed(0) + 'ms',
      errorRate: metrics.errorRate.toFixed(2),
      throughput: metrics.throughput.toFixed(1)
    });

    // 检查警告阈值
    if (metrics.avgLatency > this.config.warningThresholds.avgLatency) {
      logger.warn('⚠️  警告：平均延迟过高', {
        current: metrics.avgLatency.toFixed(0) + 'ms',
        threshold: this.config.warningThresholds.avgLatency + 'ms'
      });
    }

    if (metrics.errorRate > this.config.warningThresholds.errorRate) {
      logger.warn('⚠️  警告：错误率过高', {
        current: metrics.errorRate.toFixed(2),
        threshold: this.config.warningThresholds.errorRate.toFixed(2)
      });
    }

    if (metrics.successRate < this.config.warningThresholds.successRate) {
      logger.warn('⚠️  警告：成功率过低', {
        current: metrics.successRate.toFixed(2),
        threshold: this.config.warningThresholds.successRate.toFixed(2)
      });
    }

    // 检查严重阈值
    if (metrics.avgLatency > this.config.criticalThresholds.avgLatency ||
        metrics.errorRate > this.config.criticalThresholds.errorRate ||
        metrics.successRate < this.config.criticalThresholds.successRate) {
      logger.error('🚨 严重：性能指标异常', metrics);
    }
  }

  /**
   * 获取当前指标
   */
  getCurrentMetrics() {
    const calls = this.metrics.calls;
    const successRate = calls > 0 ? this.metrics.successes / calls : 1;
    const errorRate = calls > 0 ? this.metrics.failures / calls : 0;
    const avgLatency = calls > 0 ? this.metrics.totalLatency / calls : 0;
    const minLatency = this.metrics.minLatency === Infinity ? 0 : this.metrics.minLatency;
    const maxLatency = this.metrics.maxLatency;
    const throughput = calls > 0 ? calls / (Date.now() / 1000) : 0;

    return {
      calls,
      successRate,
      errorRate,
      avgLatency,
      minLatency,
      maxLatency,
      throughput,
      uptime: Date.now()
    };
  }

  /**
   * 获取延迟趋势
   */
  getLatencyTrend() {
    const history = this.metrics.latencyHistory;
    if (history.length < 2) return null;

    const recent = history.slice(-10);
    const oldest = history.slice(-20, -10);
    const recentAvg = recent.reduce((sum, m) => sum + m.latency, 0) / recent.length;
    const oldestAvg = oldest.reduce((sum, m) => sum + m.latency, 0) / oldest.length;

    const trend = recentAvg - oldestAvg;
    const direction = trend > 0 ? 'up' : trend < 0 ? 'down' : 'stable';

    return {
      recentAvg: recentAvg.toFixed(0) + 'ms',
      oldestAvg: oldestAvg.toFixed(0) + 'ms',
      trend,
      percentageChange: ((trend / oldestAvg) * 100).toFixed(1)
    };
  }

  /**
   * 获取错误趋势
   */
  getErrorTrend() {
    const history = this.metrics.errorHistory;
    if (history.length < 2) return null;

    const recent = history.slice(-5);
    const oldest = history.slice(-10, -5);
    const recentCount = recent.length;
    const oldestCount = oldest.length;

    const trend = recentCount - oldestCount;
    const direction = trend > 0 ? 'increasing' : trend < 0 ? 'decreasing' : 'stable';

    return {
      recentErrors: recentCount,
      oldestErrors: oldestCount,
      trend,
      percentageChange: ((trend / oldestCount) * 100).toFixed(1)
    };
  }

  /**
   * 重置指标
   */
  reset() {
    logger.info('🔄 性能指标已重置');

    this.metrics = {
      calls: 0,
      successes: 0,
      failures: 0,
      totalLatency: 0,
      maxLatency: 0,
      minLatency: Infinity,
      latencyHistory: [],
      errorHistory: []
    };
  }

  /**
   * 获取状态
   */
  getStatus() {
    const metrics = this.getCurrentMetrics();

    let status = 'OK';
    if (metrics.successRate < 0.80) status = 'CRITICAL';
    else if (metrics.successRate < 0.90) status = 'WARNING';

    return {
      status,
      ...metrics,
      latencyTrend: this.getLatencyTrend(),
      errorTrend: this.getErrorTrend()
    };
  }
}

module.exports = PerformanceMonitor;
