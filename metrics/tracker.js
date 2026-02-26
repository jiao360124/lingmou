// metrics/tracker.js
// 指标追踪模块 - V3.0+V3.2 集成版

const winston = require('winston');
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/metrics-tracker.log' }),
    new winston.transports.Console({ format: winston.format.simple() })
  ]
});

class MetricsTracker {
  constructor(config = {}) {
    this.startTime = Date.now();

    this.config = {
      checkInterval: config.checkInterval || 60000,
      maxHistorySize: config.maxHistorySize || 1000,
      metrics: {
        calls: 0,
        successes: 0,
        failures: 0,
        totalTime: 0,
        callsByModel: {},
        callsByEndpoint: {},
        callsByStatus: {},
        latencyDistribution: {
          bucket1: 0,
          bucket2: 0,
          bucket3: 0,
          bucket4: 0,
          bucket5: 0
        }
      }
    };

    this.startMonitoring();
  }

  /**
   * 记录指标
   */
  recordMetrics(model, endpoint, success, latency) {
    this.config.metrics.calls++;

    if (success) {
      this.config.metrics.successes++;
    } else {
      this.config.metrics.failures++;
    }

    this.config.metrics.totalTime += latency;

    // 按模型记录
    this.config.metrics.callsByModel[model] =
      (this.config.metrics.callsByModel[model] || 0) + 1;

    // 按端点记录
    this.config.metrics.callsByEndpoint[endpoint] =
      (this.config.metrics.callsByEndpoint[endpoint] || 0) + 1;

    // 延迟分布
    if (latency < 1000) {
      this.config.metrics.latencyDistribution.bucket1++;
    } else if (latency < 2000) {
      this.config.metrics.latencyDistribution.bucket2++;
    } else if (latency < 5000) {
      this.config.metrics.latencyDistribution.bucket3++;
    } else if (latency < 10000) {
      this.config.metrics.latencyDistribution.bucket4++;
    } else {
      this.config.metrics.latencyDistribution.bucket5++;
    }
  }

  /**
   * 获取当前指标
   */
  getCurrentMetrics() {
    const uptime = (Date.now() - this.startTime) / 1000;
    const totalCalls = this.config.metrics.calls;
    const successRate = totalCalls > 0 ? this.config.metrics.successes / totalCalls : 1;
    const errorRate = totalCalls > 0 ? this.config.metrics.failures / totalCalls : 0;
    const avgLatency = totalCalls > 0 ? this.config.metrics.totalTime / totalCalls : 0;
    const throughput = uptime > 0 ? totalCalls / uptime : 0;

    return {
      uptime,
      totalCalls,
      successRate: parseFloat(successRate.toFixed(2)),
      errorRate: parseFloat(errorRate.toFixed(2)),
      avgLatency: parseFloat(avgLatency.toFixed(0)),
      throughput: parseFloat(throughput.toFixed(1)),
      callsByModel: this.config.metrics.callsByModel,
      callsByEndpoint: this.config.metrics.callsByEndpoint
    };
  }

  /**
   * 获取成功/失败率
   */
  getSuccessRate() {
    const metrics = this.getCurrentMetrics();
    return metrics.successRate;
  }

  /**
   * 获取错误率
   */
  getErrorRate() {
    const metrics = this.getCurrentMetrics();
    return metrics.errorRate;
  }

  /**
   * 获取平均延迟
   */
  getAverageLatency() {
    const metrics = this.getCurrentMetrics();
    return metrics.avgLatency;
  }

  /**
   * 获取吞吐量
   */
  getThroughput() {
    const metrics = this.getCurrentMetrics();
    return metrics.throughput;
  }

  /**
   * 获取会话统计
   */
  getSessionStats() {
    const metrics = this.getCurrentMetrics();

    return {
      uptime: metrics.uptime.toFixed(1) + 's',
      totalCalls: metrics.totalCalls,
      throughput: metrics.throughput.toFixed(1) + ' calls/sec'
    };
  }

  /**
   * 获取状态
   */
  getStatus() {
    return this.getCurrentMetrics();
  }

  /**
   * 重置指标
   */
  reset() {
    logger.info('🔄 指标追踪已重置');

    this.config.metrics = {
      calls: 0,
      successes: 0,
      failures: 0,
      totalTime: 0,
      callsByModel: {},
      callsByEndpoint: {},
      latencyDistribution: {
        bucket1: 0,
        bucket2: 0,
        bucket3: 0,
        bucket4: 0,
        bucket5: 0
      }
    };
  }

  /**
   * 启动监控
   */
  startMonitoring() {
    logger.info('📊 指标追踪模块启动');

    setInterval(() => {
      this.check();
    }, this.config.checkInterval);
  }

  /**
   * 检查指标
   */
  check() {
    const metrics = this.getCurrentMetrics();

    logger.info('📊 指标检查', {
      totalCalls: metrics.totalCalls,
      successRate: metrics.successRate,
      errorRate: metrics.errorRate,
      avgLatency: metrics.avgLatency + 'ms',
      throughput: metrics.throughput + ' calls/sec'
    });
  }
}

module.exports = MetricsTracker;
