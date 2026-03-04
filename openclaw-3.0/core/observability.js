// openclaw-3.0/core/observability.js
// 请求级别日志 + 可观测性系统

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
    new winston.transports.File({ filename: 'logs/observability.log' }),
    new winston.transports.File({ filename: 'logs/observability-errors.log', level: 'error' }),
    new winston.transports.Console({ format: winston.format.simple() })
  ]
});

/**
 * 📊 请求日志记录器
 * 记录每次 API 调用的详细信息
 */
class RequestLogger {
  constructor(options = {}) {
    // 配置
    this.config = {
      enableLogging: options.enableLogging !== false,
      logToFile: options.logToFile !== false,
      logToConsole: options.logToConsole !== false,
      minLogLevel: options.minLogLevel || 'info'
    };

    // 日志存储（内存）
    this.logs = [];
    this.maxLogs = options.maxLogs || 10000;

    // 统计数据
    this.stats = {
      totalRequests: 0,
      totalFailures: 0,
      totalFallbacks: 0,
      averageLatency: 0,
      cost: 0
    };

    // 模型使用统计
    this.modelUsage = {};

    // 日志索引（用于快速查询）
    this.index = {};

    logger.info('Request Logger initialized');
  }

  /**
   * 📝 记录请求日志
   * @param {Object} logData - 日志数据
   */
  log(logData) {
    if (!this.config.enableLogging) {
      return;
    }

    const now = Date.now();
    const logEntry = {
      requestId: logData.requestId,
      timestamp: new Date().toISOString(),
      duration: now - logData.startTime,
      ...logData
    };

    // 记录到内存
    this.logs.push(logEntry);
    if (this.logs.length > this.maxLogs) {
      this.logs.shift();
    }

    // 建立索引
    if (logData.requestId) {
      this.index[logData.requestId] = logEntry;
    }

    // 更新统计
    this.updateStats(logData);

    // 记录到文件/控制台
    if (this.config.logToFile) {
      logger.info('Request completed', logEntry);
    }

    if (this.config.logToConsole) {
      const level = logData.success ? 'info' : 'warn';
      const prefix = logData.success ? '✅' : '❌';
      console.log(`${prefix} ${logEntry.modelName} - ${logEntry.latency}ms - ${logEntry.errorType || 'success'}`);
    }
  }

  /**
   * 📊 更新统计
   * @param {Object} logData - 日志数据
   */
  updateStats(logData) {
    this.stats.totalRequests++;

    if (logData.success) {
      this.stats.totalFailures++;
    } else {
      this.stats.totalFailures++;
    }

    if (logData.fallbackCount > 0) {
      this.stats.totalFallbacks++;
    }

    // 更新延迟统计
    const allLatencies = this.logs
      .filter(l => l.success && l.latency)
      .map(l => l.latency);

    const avgLatency = allLatencies.reduce((sum, l) => sum + l, 0) / allLatencies.length;
    this.stats.averageLatency = avgLatency;

    // 更新成本
    if (logData.costEstimate) {
      this.stats.cost += logData.costEstimate;
    }

    // 更新模型使用统计
    if (logData.modelName) {
      if (!this.modelUsage[logData.modelName]) {
        this.modelUsage[logData.modelName] = {
          totalCalls: 0,
          successCalls: 0,
          totalCost: 0,
          totalLatency: 0,
          fallbackCount: 0
        };
      }

      const modelStats = this.modelUsage[logData.modelName];
      modelStats.totalCalls++;
      if (logData.success) {
        modelStats.successCalls++;
      }
      if (logData.fallbackCount > 0) {
        modelStats.fallbackCount++;
      }
      if (logData.costEstimate) {
        modelStats.totalCost += logData.costEstimate;
      }
      if (logData.latency) {
        modelStats.totalLatency += logData.latency;
      }
    }
  }

  /**
   * 📊 获取请求日志
   * @param {string} requestId - 请求ID
   * @returns {Object|null} 请求日志
   */
  getRequestLog(requestId) {
    return this.index[requestId] || null;
  }

  /**
   * 📊 获取请求列表
   * @param {Object} filters - 过滤条件
   * @returns {Array} 请求日志列表
   */
  getRequestLogs(filters = {}) {
    let logs = [...this.logs];

    // 按时间过滤
    if (filters.startTime) {
      logs = logs.filter(l => l.timestamp >= filters.startTime);
    }

    if (filters.endTime) {
      logs = logs.filter(l => l.timestamp <= filters.endTime);
    }

    // 按模型过滤
    if (filters.modelName) {
      logs = logs.filter(l => l.modelName === filters.modelName);
    }

    // 按状态过滤
    if (filters.success !== undefined) {
      logs = logs.filter(l => l.success === filters.success);
    }

    // 按错误类型过滤
    if (filters.errorType) {
      logs = logs.filter(l => l.errorType === filters.errorType);
    }

    // 按分页过滤
    if (filters.limit) {
      logs = logs.slice(-filters.limit);
    }

    return logs;
  }

  /**
   * 📊 获取统计摘要
   * @returns {Object} 统计摘要
   */
  getSummary() {
    return {
      ...this.stats,
      modelUsage: this.modelUsage,
      uptime: Date.now() - this.logs[0]?.timestamp || 0
    };
  }

  /**
   * 📊 获取模型使用报告
   * @returns {Object} 模型使用报告
   */
  getModelUsageReport() {
    const report = [];

    for (const [modelName, stats] of Object.entries(this.modelUsage)) {
      const usageRate = stats.totalCalls > 0
        ? (stats.successCalls / stats.totalCalls) * 100
        : 0;

      const avgLatency = stats.totalCalls > 0
        ? Math.round(stats.totalLatency / stats.totalCalls)
        : 0;

      const costPerCall = stats.totalCalls > 0
        ? stats.totalCost / stats.totalCalls
        : 0;

      report.push({
        modelName,
        totalCalls: stats.totalCalls,
        successCalls: stats.successCalls,
        failureCalls: stats.totalCalls - stats.successCalls,
        usageRate: usageRate.toFixed(2) + '%',
        avgLatency,
        totalCost: stats.totalCost.toFixed(4),
        costPerCall: costPerCall.toFixed(4),
        fallbackCount: stats.fallbackCount
      });
    }

    return report.sort((a, b) => b.totalCalls - a.totalCalls);
  }

  /**
   * 📊 获取成本趋势报告
   * @returns {Array} 成本趋势数据
   */
  getCostTrendReport(hours = 24) {
    const now = Date.now();
    const windowMs = hours * 3600000;

    const logs = this.logs.filter(l =>
      l.success &&
      l.costEstimate &&
      l.timestamp >= new Date(now - windowMs).toISOString()
    );

    // 按小时分组
    const hourlyCost = {};
    logs.forEach(log => {
      const hour = new Date(log.timestamp).getHours();
      const key = `${new Date(log.timestamp).toISOString().slice(0, 13)}:${hour}`;
      hourlyCost[key] = (hourlyCost[key] || 0) + log.costEstimate;
    });

    // 转换为数组
    return Object.entries(hourlyCost)
      .map(([time, cost]) => ({ time, cost: cost.toFixed(4) }))
      .sort((a, b) => a.time.localeCompare(b.time));
  }

  /**
   * 📊 获取 Fallback 报告
   * @returns {Object} Fallback 报告
   */
  getFallbackReport() {
    const fallbackLogs = this.logs.filter(l => l.fallbackCount > 0);

    // 按模型分组
    const fallbackByModel = {};
    fallbackLogs.forEach(log => {
      if (!fallbackByModel[log.modelName]) {
        fallbackByModel[log.modelName] = 0;
      }
      fallbackByModel[log.modelName]++;
    });

    // 按错误类型分组
    const fallbackByError = {};
    fallbackLogs.forEach(log => {
      if (!fallbackByError[log.errorType]) {
        fallbackByError[log.errorType] = 0;
      }
      fallbackByError[log.errorType]++;
    });

    // 按时间段分组
    const fallbackByTime = {};
    fallbackLogs.forEach(log => {
      const key = log.timestamp.slice(0, 13); // 年-月-日-HH
      fallbackByTime[key] = (fallbackByTime[key] || 0) + 1;
    });

    return {
      totalFallbacks: this.stats.totalFallbacks,
      fallbackLogs: fallbackLogs.slice(-100), // 最近 100 条
      fallbackByModel,
      fallbackByError,
      fallbackByTime
    };
  }

  /**
   * 📊 导出报告
   * @param {Object} options - 导出选项
   * @returns {Object} 完整报告
   */
  exportReport(options = {}) {
    const report = {
      summary: this.getSummary(),
      modelUsage: this.getModelUsageReport(),
      costTrend: this.getCostTrendReport(options.hours),
      fallback: this.getFallbackReport()
    };

    return report;
  }

  /**
   * 📝 保存日志到文件
   * @param {string} filename - 文件名
   */
  async saveLogs(filename) {
    try {
      await fs.mkdir('logs', { recursive: true });
      const content = JSON.stringify(this.logs, null, 2);
      await fs.writeFile(`logs/${filename}`, content);
      logger.info(`Logs saved to ${filename}`);
    } catch (error) {
      logger.error('Failed to save logs:', error);
    }
  }

  /**
   * 📝 保存报告到文件
   * @param {string} filename - 文件名
   */
  async saveReport(filename) {
    try {
      await fs.mkdir('logs', { recursive: true });
      const report = this.exportReport();
      await fs.writeFile(`logs/${filename}`, JSON.stringify(report, null, 2));
      logger.info(`Report saved to ${filename}`);
    } catch (error) {
      logger.error('Failed to save report:', error);
    }
  }

  /**
   * 🧹 清空日志
   */
  clearLogs() {
    this.logs = [];
    this.index = {};
    this.stats = {
      totalRequests: 0,
      totalFailures: 0,
      totalFallbacks: 0,
      averageLatency: 0,
      cost: 0
    };
    this.modelUsage = {};
    logger.info('Logs cleared');
  }
}

module.exports = RequestLogger;
