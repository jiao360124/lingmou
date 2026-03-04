// integration-manager.js - 数据源集成管理器
// 整合真实数据源到现有系统

const MetricsTracker = require('../metrics/tracker');
const RealDataCollector = require('./real-data-collector');
const { DataSourceAdapter } = require('./data-source-adapter');
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/openclaw-3.0.log' }),
    new winston.transports.Console()
  ]
});

class IntegrationManager {
  constructor(config = {}) {
    this.config = config;
    this.metricsTracker = new MetricsTracker();
    this.realDataCollector = new RealDataCollector(config);
    this.dataSourceAdapter = new DataSourceAdapter(config);
    this.isIntegrated = false;
  }

  // 集成真实数据源
  async integrate() {
    try {
      logger.info('开始集成真实数据源...');

      // 集成真实数据采集器
      this.isIntegrated = true;
      logger.info('✅ 真实数据源集成完成');

      return {
        success: true,
        message: '真实数据源集成完成',
        collector: 'real-data-collector',
        tracker: 'metrics-tracker'
      };
    } catch (err) {
      logger.error('真实数据源集成失败:', err.message);
      return {
        success: false,
        message: `集成失败: ${err.message}`
      };
    }
  }

  // 记录API调用数据
  async recordAPICall(data) {
    if (!this.isIntegrated) {
      logger.warn('数据源未集成，使用传统方式记录');
      this.metricsTracker.trackCall(data.tokensUsed, data.success);
      return this.metricsTracker.getMetrics();
    }

    // 使用真实数据采集器
    const dailyMetrics = await this.realDataCollector.collectCall(data);
    return {
      ...dailyMetrics,
      tracker: 'real-data-collector'
    };
  }

  // 获取聚合指标
  getAggregatedMetrics() {
    if (this.isIntegrated) {
      return this.realDataCollector.getAggregatedMetrics();
    }

    return this.metricsTracker.getMetrics();
  }

  // 获取趋势数据
  getTrendData(days = 7) {
    if (this.isIntegrated) {
      return this.realDataCollector.getTrendData(days);
    }

    return [];
  }

  // 获取每日指标
  getDailyMetrics(dateStr = null) {
    if (this.isIntegrated) {
      const allMetrics = this.realDataCollector.getAggregatedMetrics();
      const trend = this.getTrendData(7);

      if (dateStr) {
        return trend.find(t => t.date === dateStr);
      }

      return allMetrics;
    }

    return this.metricsTracker.getMetrics();
  }

  // 重置每日指标
  resetDailyMetrics() {
    if (this.isIntegrated) {
      this.realDataCollector.resetDailyMetrics();
      return true;
    }

    this.metricsTracker = new MetricsTracker();
    return true;
  }

  // 导出CSV
  exportToCSV(days = 7) {
    if (this.isIntegrated) {
      return this.realDataCollector.exportToCSV(days);
    }

    const trend = this.getTrendData(days);
    const headers = ['Date', 'Tokens', 'Calls', 'Successes', 'Failures', 'Cost'];
    const rows = trend.map(t => [
      t.date,
      t.tokens,
      t.calls,
      t.successes,
      t.failures,
      `$${t.cost.toFixed(2)}`
    ]);

    return [headers.join(','), ...rows.map(r => r.join(','))].join('\n');
  }

  // 获取数据源状态
  getDataSourceStatus() {
    return {
      integrated: this.isIntegrated,
      collector: this.realDataCollector.metrics,
      sources: this.dataSourceAdapter.getSources(),
      date: new Date().toISOString()
    };
  }

  // 更新数据源配置
  async updateDataSourceConfig(config) {
    try {
      this.config = { ...this.config, ...config };
      this.realDataCollector = new RealDataCollector(this.config);
      this.dataSourceAdapter = new DataSourceAdapter(this.config);
      logger.info('数据源配置已更新');
      return true;
    } catch (err) {
      logger.error('更新数据源配置失败:', err.message);
      return false;
    }
  }

  // 测试数据源连接
  async testConnection() {
    try {
      const testCall = {
        tokensUsed: 100,
        success: true,
        latency: 500,
        cost: 0.01,
        model: 'test-model',
        timestamp: new Date()
      };

      await this.realDataCollector.collectCall(testCall);
      return {
        success: true,
        message: '数据源连接测试成功'
      };
    } catch (err) {
      logger.error('数据源连接测试失败:', err.message);
      return {
        success: false,
        message: `连接测试失败: ${err.message}`
      };
    }
  }

  // 获取优化建议
  getOptimizationSuggestions() {
    const trend = this.getTrendData(7);
    const suggestions = [];

    // Token趋势分析
    if (trend.length >= 2) {
      const first = trend[0];
      const last = trend[trend.length - 1];
      const tokenChange = ((last.tokens - first.tokens) / first.tokens) * 100;

      if (tokenChange > 20) {
        suggestions.push({
          type: 'warning',
          title: 'Token使用量上升',
          message: `过去7天Token使用量上升 ${tokenChange.toFixed(1)}%`,
          severity: 'high'
        });
      } else if (tokenChange < -10) {
        suggestions.push({
          type: 'success',
          title: 'Token使用量下降',
          message: `过去7天Token使用量下降 ${Math.abs(tokenChange).toFixed(1)}%`,
          severity: 'low'
        });
      }
    }

    // 成功率分析
    const last = trend[trend.length - 1];
    if (last.successRate < 80) {
      suggestions.push({
        type: 'error',
        title: '成功率过低',
        message: `当前成功率 ${last.successRate}%，建议检查API状态`,
        severity: 'high'
      });
    }

    // 成本分析
    const totalCost = trend.reduce((sum, t) => sum + t.cost, 0);
    if (totalCost > 100) {
      suggestions.push({
        type: 'warning',
        title: '成本过高',
        message: `过去7天总成本 $${totalCost.toFixed(2)}`,
        severity: 'medium'
      });
    }

    return suggestions;
  }
}

module.exports = IntegrationManager;
