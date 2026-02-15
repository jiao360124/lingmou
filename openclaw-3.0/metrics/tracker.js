// openclaw-3.0/metrics/tracker.js
// 指标追踪系统

const fs = require('fs-extra');
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

class MetricsTracker {
  constructor() {
    this.metrics = {
      dailyTokens: 0,
      totalTokens: 0,
      cost: 0,
      successCount: 0,
      errorCount: 0,
      recoveryRate: 87,
      avgContextSize: 1200,
      templatesGenerated: 0,
      nightlyTasksExecuted: 0,
      costReduction: 5, // 初始: 5%
      dailyOptimizations: 0,
      lastUpdated: new Date().toISOString()
    };

    this.loadMetrics();
  }

  loadMetrics() {
    if (fs.existsSync('data/metrics.json')) {
      this.metrics = fs.readJSONSync('data/metrics.json');
    }
  }

  saveMetrics() {
    this.metrics.lastUpdated = new Date().toISOString();
    fs.writeJSONSync('data/metrics.json', this.metrics, { spaces: 2 });
  }

  trackCall(tokensUsed, success) {
    this.metrics.dailyTokens += tokensUsed;
    this.metrics.totalTokens += tokensUsed;

    if (success) {
      this.metrics.successCount++;
      // 每次成功调用记录一个token
      this.metrics.cost += tokensUsed * 0.0001;
    } else {
      this.metrics.errorCount++;
    }

    this.metrics.avgContextSize = Math.round(
      (this.metrics.avgContextSize * 0.9 + tokensUsed * 0.1)
    );

    this.saveMetrics();
  }

  trackError() {
    this.metrics.errorCount++;

    // 计算错误率
    const totalCalls = this.metrics.successCount + this.metrics.errorCount;
    if (totalCalls > 0) {
      this.metrics.recoveryRate = Math.round(
        (this.metrics.successCount / totalCalls) * 100
      );
    }

    this.saveMetrics();
  }

  trackNightlyTask() {
    this.metrics.nightlyTasksExecuted++;

    // 夜间任务每执行一次，增加一个优化计数
    this.metrics.dailyOptimizations++;

    this.saveMetrics();
  }

  trackTemplateGeneration() {
    this.metrics.templatesGenerated++;
    this.metrics.dailyOptimizations++;

    this.saveMetrics();
  }

  getMetrics() {
    return this.metrics;
  }

  getReport() {
    const totalCalls = this.metrics.successCount + this.metrics.errorCount;
    const successRate = totalCalls > 0
      ? Math.round((this.metrics.successCount / totalCalls) * 100)
      : 0;

    const cost = this.metrics.cost.toFixed(4);

    return {
      ...this.metrics,
      successRate: successRate,
      cost: cost,
      costPercentOfLimit: Math.round((this.metrics.cost / 50) * 100), // 假设最大$50
      tokensPerDay: this.metrics.dailyTokens
    };
  }

  resetDaily() {
    this.metrics.dailyTokens = 0;
    this.metrics.lastUpdated = new Date().toISOString();
    this.saveMetrics();
  }

  updateMetrics(newMetrics) {
    Object.assign(this.metrics, newMetrics);
    this.saveMetrics();
  }
}

module.exports = new MetricsTracker();
