// openclaw-3.0/data-service.js
// Dashboard 数据服务 - 连接真实数据源

const RequestLogger = require('./core/observability');
const fs = require('fs').promises;
const path = require('path');

/**
 * 📊 Dashboard 数据服务
 * 提供实时、准确的数据给 Dashboard
 */
class DataService {
  constructor(options = {}) {
    this.config = {
      cacheDuration: options.cacheDuration || 30000, // 30秒缓存
      maxLogs: options.maxLogs || 10000
    };

    this.logger = new RequestLogger({
      logToFile: false,
      logToConsole: false
    });

    // 缓存数据
    this.cache = {
      status: null,
      models: null,
      trends: null,
      fallbacks: null,
      timestamp: 0
    };

    console.log('📊 Dashboard DataService initialized');
  }

  /**
   * 🔄 更新数据缓存
   * @returns {Promise<Object>} 缓存的数据
   */
  async updateCache() {
    const now = Date.now();

    // 如果缓存未过期，直接返回
    if (now - this.cache.timestamp < this.config.cacheDuration) {
      return this.cache;
    }

    try {
      // 获取状态数据
      this.cache.status = this.getStatusData();

      // 获取模型数据
      this.cache.models = this.getModelsData();

      // 获取趋势数据
      this.cache.trends = this.getTrendsData();

      // 获取 Fallback 数据
      this.cache.fallbacks = this.getFallbacksData();

      this.cache.timestamp = now;

      console.log(`🔄 Dashboard data cache updated at ${new Date().toISOString()}`);

      return this.cache;
    } catch (error) {
      console.error(`❌ Failed to update cache: ${error.message}`);
      throw error;
    }
  }

  /**
   * 📊 获取状态数据
   * @returns {Object} 状态数据
   */
  getStatusData() {
    const summary = this.logger.getSummary();
    const fallbackReport = this.logger.getFallbackReport();

    return {
      timestamp: Date.now(),
      uptime: summary.uptime,
      requests: {
        total: summary.totalRequests,
        success: summary.totalRequests - summary.totalFailures,
        failures: summary.totalFailures,
        fallbacks: fallbackReport.totalFallbacks,
        successRate: summary.totalRequests > 0
          ? ((summary.totalRequests - summary.totalFailures) / summary.totalRequests * 100).toFixed(2) + '%'
          : '0%'
      },
      performance: {
        avgLatency: summary.averageLatency.toFixed(2) + 'ms',
        tokenUsage: summary.cost.toFixed(4) + ' tokens'
      },
      models: {
        total: Object.keys(summary.modelUsage || {}).length
      },
      switcher: {
        primaryModel: 'ZAI', // TODO: 从动态切换器获取
        isSwitched: false,
        zaiHealth: 100 // TODO: 从健康追踪器获取
      }
    };
  }

  /**
   * 📊 获取模型数据
   * @returns {Object} 模型数据
   */
  getModelsData() {
    const modelReport = this.logger.getModelUsageReport();

    return {
      total: modelReport.length,
      models: modelReport.slice(0, 10) // 最多返回 10 个模型
    };
  }

  /**
   * 📈 获取趋势数据
   * @returns {Object} 趋势数据
   */
  getTrendsData() {
    const costTrend = this.logger.getCostTrendReport(24); // 24 小时趋势

    // 补全缺失的小时
    const trendData = [];
    const now = new Date();
    for (let i = 23; i >= 0; i--) {
      const hour = new Date(now - i * 3600000);
      const key = `${hour.toISOString().slice(0, 13)}:${hour.getHours()}`;
      const entry = costTrend.find(t => t.time === key);

      trendData.push({
        time: key,
        cost: entry ? entry.cost : '0.0000'
      });
    }

    return {
      trend: trendData
    };
  }

  /**
   * ⚠️ 获取 Fallback 数据
   * @returns {Object} Fallback 数据
   */
  getFallbacksData() {
    const fallbackReport = this.logger.getFallbackReport();

    return {
      totalFallbacks: fallbackReport.totalFallbacks,
      fallbackLogs: fallbackReport.fallbackLogs.slice(-50), // 最近 50 条
      fallbackByModel: fallbackReport.fallbackByModel,
      fallbackByError: fallbackReport.fallbackByError
    };
  }

  /**
   * 📝 记录请求日志
   * @param {Object} logData - 日志数据
   */
  logRequest(logData) {
    return this.logger.log(logData);
  }

  /**
   * 📊 获取统计摘要
   * @returns {Object} 统计摘要
   */
  getSummary() {
    return this.logger.getSummary();
  }

  /**
   * 📊 导出报告
   * @param {Object} options - 导出选项
   * @returns {Object} 完整报告
   */
  exportReport(options = {}) {
    return this.logger.exportReport(options);
  }

  /**
   * 💾 保存日志到文件
   * @param {string} filename - 文件名
   */
  async saveLogs(filename) {
    return this.logger.saveLogs(filename);
  }

  /**
   * 💾 保存报告到文件
   * @param {string} filename - 文件名
   */
  async saveReport(filename) {
    return this.logger.saveReport(filename);
  }

  /**
   * 🧹 清空日志
   */
  clearLogs() {
    return this.logger.clearLogs();
  }

  /**
   * 🔄 手动刷新缓存
   */
  async refreshCache() {
    return this.updateCache();
  }

  /**
   * 📊 获取当前缓存
   * @returns {Object} 缓存数据
   */
  getCache() {
    return this.cache;
  }
}

module.exports = DataService;
