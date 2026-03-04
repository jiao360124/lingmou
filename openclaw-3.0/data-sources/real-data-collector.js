// real-data-collector.js - 真实数据采集器
// 从API调用中采集真实数据

const axios = require('axios');
const fs = require('fs').promises;
const path = require('path');
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

class RealDataCollector {
  constructor(config = {}) {
    this.config = config;
    this.metrics = {
      daily: {
        startTime: new Date().toDateString(),
        tokens: 0,
        calls: 0,
        successes: 0,
        failures: 0,
        totalCost: 0,
        avgLatency: 0
      },
      hourly: [],
      dailyByHour: {},
      successRate: 90,
      costTrend: [],
      lastMetrics: {}
    };

    this.callHistory = [];
    this.loadLastMetrics();
  }

  // 加载上次采集的指标
  loadLastMetrics() {
    const metricsPath = path.join(__dirname, '../data/real-metrics.json');
    try {
      if (fs.existsSync(metricsPath)) {
        this.metrics.lastMetrics = fs.readJSONSync(metricsPath);
        logger.info('上次采集指标已加载');
      }
    } catch (err) {
      logger.warn('加载上次指标失败:', err.message);
    }
  }

  // 采集单次API调用数据
  async collectCall(data) {
    const {
      tokensUsed,
      success,
      latency,
      cost,
      model,
      timestamp = new Date()
    } = data;

    // 更新今日指标
    this.metrics.daily.tokens += tokensUsed;
    this.metrics.daily.calls++;
    this.metrics.daily.successes += success ? 1 : 0;
    this.metrics.daily.failures += success ? 0 : 1;
    this.metrics.daily.totalCost += cost || 0;
    this.metrics.daily.avgLatency = this.calculateAvgLatency(latency);

    // 更新历史
    this.updateHourlyMetrics(timestamp);
    this.updateDailyByHourMetrics(timestamp, tokensUsed);

    // 计算成功率
    if (this.metrics.daily.calls > 0) {
      this.metrics.daily.successRate = Math.round(
        (this.metrics.daily.successes / this.metrics.daily.calls) * 100
      );
    } else {
      this.metrics.daily.successRate = 100;
    }

    // 记录调用历史
    this.callHistory.push({
      tokensUsed,
      success,
      latency,
      cost,
      model,
      timestamp: timestamp.toISOString()
    });

    // 限制历史记录长度
    if (this.callHistory.length > 1000) {
      this.callHistory = this.callHistory.slice(-1000);
    }

    // 保存
    this.saveMetrics();

    return this.metrics.daily;
  }

  // 计算平均延迟
  calculateAvgLatency(newLatency) {
    if (this.metrics.daily.avgLatency === 0) {
      return newLatency;
    }
    const oldAvg = this.metrics.daily.avgLatency;
    const totalCalls = this.metrics.daily.calls;
    return Math.round((oldAvg * (totalCalls - 1) + newLatency) / totalCalls);
  }

  // 更新每小时指标
  updateHourlyMetrics(timestamp) {
    const hour = new Date(timestamp).getHours();

    // 查找或创建
    let hourly = this.metrics.hourly.find(h => h.hour === hour);
    if (!hourly) {
      hourly = { hour, tokens: 0, calls: 0, successes: 0, failures: 0, cost: 0 };
      this.metrics.hourly.push(hourly);
    }

    hourly.tokens += this.metrics.daily.tokens - hourly.tokens;
    hourly.calls += this.metrics.daily.calls - hourly.calls;
    hourly.successes += this.metrics.daily.successes - hourly.successes;
    hourly.failures += this.metrics.daily.failures - hourly.failures;
    hourly.cost += this.metrics.daily.totalCost - hourly.cost;

    // 按小时排序
    this.metrics.hourly.sort((a, b) => a.hour - b.hour);
  }

  // 更新按小时分组的每日指标
  updateDailyByHourMetrics(timestamp, tokensUsed) {
    const hour = new Date(timestamp).getHours();

    if (!this.metrics.dailyByHour[hour]) {
      this.metrics.dailyByHour[hour] = {
        hour,
        tokens: 0,
        calls: 0,
        successes: 0,
        failures: 0,
        cost: 0
      };
    }

    this.metrics.dailyByHour[hour].tokens += tokensUsed;
    this.metrics.dailyByHour[hour].calls++;
    this.metrics.dailyByHour[hour].successes += this.metrics.daily.successes - this.metrics.dailyByHour[hour].successes;
    this.metrics.dailyByHour[hour].failures += this.metrics.daily.failures - this.metrics.dailyByHour[hour].failures;
    this.metrics.dailyByHour[hour].cost += this.metrics.daily.totalCost - this.metrics.dailyByHour[hour].cost;
  }

  // 获取聚合指标
  getAggregatedMetrics() {
    return {
      ...this.metrics.daily,
      hourly: this.metrics.hourly,
      dailyByHour: this.metrics.dailyByHour,
      successRate: this.metrics.daily.successRate,
      avgLatency: this.metrics.daily.avgLatency
    };
  }

  // 获取趋势数据（用于图表）
  getTrendData(days = 7) {
    const trend = [];

    for (let i = days - 1; i >= 0; i--) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      const dateStr = date.toDateString();

      const totalCalls = this.getDailyCalls(dateStr);
      const successes = this.getDailySuccesses(dateStr);
      const successRate = totalCalls > 0
        ? Math.round((successes / totalCalls) * 100)
        : 100;

      trend.push({
        date: dateStr,
        tokens: this.getDailyTotal(dateStr),
        calls: totalCalls,
        successes: successes,
        failures: this.getDailyFailures(dateStr),
        cost: this.getDailyCost(dateStr),
        successRate: successRate
      });
    }

    return trend;
  }

  // 获取指定日期的总tokens
  getDailyTotal(dateStr) {
    return this.callHistory
      .filter(c => new Date(c.timestamp).toDateString() === dateStr)
      .reduce((sum, c) => sum + c.tokensUsed, 0);
  }

  // 获取指定日期的调用次数
  getDailyCalls(dateStr) {
    return this.callHistory
      .filter(c => new Date(c.timestamp).toDateString() === dateStr)
      .reduce((sum) => sum + 1, 0);
  }

  // 获取指定日期的成功次数
  getDailySuccesses(dateStr) {
    return this.callHistory
      .filter(c => new Date(c.timestamp).toDateString() === dateStr && c.success)
      .reduce((sum) => sum + 1, 0);
  }

  // 获取指定日期的失败次数
  getDailyFailures(dateStr) {
    return this.callHistory
      .filter(c => new Date(c.timestamp).toDateString() === dateStr && !c.success)
      .reduce((sum) => sum + 1, 0);
  }

  // 获取指定日期的成本
  getDailyCost(dateStr) {
    return this.callHistory
      .filter(c => new Date(c.timestamp).toDateString() === dateStr)
      .reduce((sum, c) => sum + (c.cost || 0), 0);
  }

  // 保存指标
  async saveMetrics() {
    const metricsPath = path.join(__dirname, '../data/real-metrics.json');

    // 保存每日指标
    await fs.writeFile(
      path.join(__dirname, '../data/daily-metrics.json'),
      JSON.stringify(this.metrics.daily, null, 2)
    );

    // 保存历史记录
    await fs.writeFile(
      metricsPath,
      JSON.stringify({
        daily: this.metrics.daily,
        hourly: this.metrics.hourly,
        dailyByHour: this.metrics.dailyByHour,
        callHistory: this.callHistory,
        lastUpdated: new Date().toISOString()
      }, null, 2)
    );

    logger.info('真实数据已采集并保存');
  }

  // 重置每日指标（每日0点调用）
  resetDailyMetrics() {
    const today = new Date().toDateString();

    if (this.metrics.daily.startTime === today) {
      return; // 今天已经重置
    }

    // 保存上次指标
    this.metrics.lastMetrics = { ...this.metrics.daily };

    // 重置
    this.metrics.daily = {
      startTime: today,
      tokens: 0,
      calls: 0,
      successes: 0,
      failures: 0,
      totalCost: 0,
      avgLatency: 0
    };

    this.saveMetrics();
    logger.info('每日指标已重置');
  }

  // 导出CSV格式数据
  exportToCSV(dateRange = 7) {
    const trend = this.getTrendData(dateRange);
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

  // 清理旧数据
  cleanupOldData(days = 30) {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - days);

    this.callHistory = this.callHistory.filter(c => {
      return new Date(c.timestamp) > cutoffDate;
    });

    this.metrics.hourly = this.metrics.hourly.filter(h => {
      const hourDate = new Date();
      hourDate.setHours(h.hour, 0, 0, 0);
      return hourDate > cutoffDate;
    });

    this.metrics.dailyByHour = {};
    this.saveMetrics();

    logger.info(`已清理 ${days} 天前的数据`);
  }
}

module.exports = RealDataCollector;
