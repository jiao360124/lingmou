// core/api-tracker.js
// API追踪模块 - V3.0+V3.2 集成版

const winston = require('winston');
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/api-tracker.log' }),
    new winston.transports.Console({ format: winston.format.simple() })
  ]
});

class APITracker {
  constructor(config = {}) {
    this.config = {
      maxHistory: config.maxHistory || 1000,
      errorRateThreshold: config.errorRateThreshold || 0.1, // 10%
      successRateThreshold: config.successRateThreshold || 0.8 // 80%
    };

    this.tracking = {
      totalCalls: 0,
      totalSuccesses: 0,
      totalFailures: 0,
      totalTime: 0,
      callsByModel: {}, // 记录每个模型的调用次数
      callsByEndpoint: {}, // 记录每个端点的调用次数
      latencyDistribution: {
        bucket1: 0, // < 1秒
        bucket2: 0, // 1-2秒
        bucket3: 0, // 2-5秒
        bucket4: 0, // 5-10秒
        bucket5: 0  // > 10秒
      }
    };

    this.sessionStart = Date.now();
  }

  /**
   * 记录API调用
   */
  recordCall(model, endpoint, success, latency, errorMessage = null) {
    this.tracking.totalCalls++;

    if (success) {
      this.tracking.totalSuccesses++;
    } else {
      this.tracking.totalFailures++;
    }

    this.tracking.totalTime += latency;

    // 按模型记录
    this.tracking.callsByModel[model] = (this.tracking.callsByModel[model] || 0) + 1;

    // 按端点记录
    this.tracking.callsByEndpoint[endpoint] = (this.tracking.callsByEndpoint[endpoint] || 0) + 1;

    // 延迟分布
    if (latency < 1000) {
      this.tracking.latencyDistribution.bucket1++;
    } else if (latency < 2000) {
      this.tracking.latencyDistribution.bucket2++;
    } else if (latency < 5000) {
      this.tracking.latencyDistribution.bucket3++;
    } else if (latency < 10000) {
      this.tracking.latencyDistribution.bucket4++;
    } else {
      this.tracking.latencyDistribution.bucket5++;
    }

    logger.debug('✅ API调用已记录', {
      model,
      endpoint,
      success,
      latency: latency.toFixed(0) + 'ms',
      errorMessage
    });
  }

  /**
   * 获取成功/失败率
   */
  getSuccessRate() {
    if (this.tracking.totalCalls === 0) return 1;
    return this.tracking.totalSuccesses / this.tracking.totalCalls;
  }

  /**
   * 获取错误率
   */
  getErrorRate() {
    if (this.tracking.totalCalls === 0) return 0;
    return this.tracking.totalFailures / this.tracking.totalCalls;
  }

  /**
   * 获取平均延迟
   */
  getAverageLatency() {
    if (this.tracking.totalCalls === 0) return 0;
    return this.tracking.totalTime / this.tracking.totalCalls;
  }

  /**
   * 获取吞吐量
   */
  getThroughput() {
    const uptime = (Date.now() - this.sessionStart) / 1000; // 秒
    if (uptime === 0) return 0;
    return this.tracking.totalCalls / uptime;
  }

  /**
   * 获取按模型的统计
   */
  getModelStats() {
    return Object.entries(this.tracking.callsByModel).map(([model, count]) => {
      const successRate = (this.tracking.callsByModel[model] || 0) > 0
        ? ((this.tracking.callsByModel[model] || 0) / this.tracking.totalCalls) * 100
        : 0;

      return {
        model,
        calls: count,
        percentage: successRate.toFixed(2) + '%'
      };
    }).sort((a, b) => b.calls - a.calls);
  }

  /**
   * 获取按端点的统计
   */
  getEndpointStats() {
    return Object.entries(this.tracking.callsByEndpoint).map(([endpoint, count]) => {
      const successRate = (this.tracking.callsByEndpoint[endpoint] || 0) > 0
        ? ((this.tracking.callsByEndpoint[endpoint] || 0) / this.tracking.totalCalls) * 100
        : 0;

      return {
        endpoint,
        calls: count,
        percentage: successRate.toFixed(2) + '%'
      };
    }).sort((a, b) => b.calls - a.calls);
  }

  /**
   * 获取延迟分布
   */
  getLatencyDistribution() {
    const total = Object.values(this.tracking.latencyDistribution).reduce((a, b) => a + b, 0);
    const buckets = [
      { range: '< 1秒', count: this.tracking.latencyDistribution.bucket1 },
      { range: '1-2秒', count: this.tracking.latencyDistribution.bucket2 },
      { range: '2-5秒', count: this.tracking.latencyDistribution.bucket3 },
      { range: '5-10秒', count: this.tracking.latencyDistribution.bucket4 },
      { range: '> 10秒', count: this.tracking.latencyDistribution.bucket5 }
    ];

    return buckets.map(b => ({
      ...b,
      percentage: total > 0 ? ((b.count / total) * 100).toFixed(2) + '%' : '0%'
    }));
  }

  /**
   * 获取系统健康状态
   */
  getHealthStatus() {
    const successRate = this.getSuccessRate();
    const errorRate = this.getErrorRate();
    const avgLatency = this.getAverageLatency();

    let status = 'OK';
    if (successRate < this.config.successRateThreshold) {
      status = 'CRITICAL';
    } else if (successRate < 0.90) {
      status = 'WARNING';
    }

    // 检查是否有频繁失败的模型
    const failedModels = this.getModelStats().filter(m => m.percentage > 10);
    const hasFailedModels = failedModels.length > 0;

    // 检查是否有慢端点
    const slowEndpoints = this.getEndpointStats().filter(e => e.percentage > 10);
    const hasSlowEndpoints = slowEndpoints.length > 0;

    // 检查延迟分布
    const slowLatency = this.getLatencyDistribution().filter(l => l.range === '> 10秒');
    const hasSlowLatency = slowLatency[0].percentage > 10;

    return {
      status,
      successRate: successRate.toFixed(2),
      errorRate: errorRate.toFixed(2),
      avgLatency: avgLatency.toFixed(0) + 'ms',
      throughput: this.getThroughput().toFixed(1) + ' calls/sec',
      failedModels,
      hasFailedModels,
      slowEndpoints,
      hasSlowEndpoints,
      hasSlowLatency,
      metrics: {
        totalCalls: this.tracking.totalCalls,
        totalSuccesses: this.tracking.totalSuccesses,
        totalFailures: this.tracking.totalFailures,
        totalTime: this.tracking.totalTime
      }
    };
  }

  /**
   * 获取状态
   */
  getStatus() {
    return {
      ...this.getHealthStatus(),
      modelStats: this.getModelStats(),
      endpointStats: this.getEndpointStats(),
      latencyDistribution: this.getLatencyDistribution()
    };
  }

  /**
   * 重置
   */
  reset() {
    logger.info('🔄 API追踪已重置');

    this.tracking = {
      totalCalls: 0,
      totalSuccesses: 0,
      totalFailures: 0,
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

    this.sessionStart = Date.now();
  }

  /**
   * 获取会话统计
   */
  getSessionStats() {
    const uptime = (Date.now() - this.sessionStart) / 1000; // 秒

    return {
      uptime: uptime.toFixed(1) + 's',
      totalCalls: this.tracking.totalCalls,
      throughput: this.getThroughput().toFixed(1) + ' calls/sec'
    };
  }
}

module.exports = APITracker;
