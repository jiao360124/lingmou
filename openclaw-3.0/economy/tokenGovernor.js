// openclaw-3.0/economy/tokenGovernor.js
// Token管理器

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

class TokenGovernor {
  constructor() {
    this.config = {
      dailyLimit: 200000,
      cheapModelRate: 0.0001,    // $0.1 per 1K tokens
      midModelRate: 0.002,       // $2 per 1K tokens
      highModelRate: 0.01        // $10 per 1K tokens
    };

    this.state = {
      todayUsage: 0,
      costToday: 0,
      lastReset: new Date().toDateString(),
      modelUsage: {
        cheap: 0,
        mid: 0,
        high: 0
      }
    };

    this.loadState();
  }

  loadState() {
    if (fs.existsSync('data/token-governor.json')) {
      this.state = fs.readJSONSync('data/token-governor.json');
    }
  }

  saveState() {
    fs.writeJSONSync('data/token-governor.json', this.state, { spaces: 2 });
  }

  resetDaily() {
    if (this.state.lastReset !== new Date().toDateString()) {
      this.state.todayUsage = 0;
      this.state.costToday = 0;
      this.state.modelUsage = { cheap: 0, mid: 0, high: 0 };
      this.state.lastReset = new Date().toDateString();
      this.saveState();
      logger.info('每日Token状态已重置');
    }
  }

  canUseTokens(amount) {
    return this.state.todayUsage + amount <= this.config.dailyLimit;
  }

  recordUsage(tokens, model = 'cheap') {
    this.resetDaily();

    this.state.todayUsage += tokens;
    this.state.modelUsage[model] += tokens;

    // 计算成本
    const rate = this.getRate(model);
    const cost = rate * (tokens / 1000);
    this.state.costToday += cost;

    this.saveState();

    logger.info(`Token使用: ${tokens} tokens (${model}), 成本: $${cost.toFixed(4)}, 今日总计: ${this.state.todayUsage}`);

    if (this.state.todayUsage >= this.config.dailyLimit) {
      logger.warn('今日Token使用量已达上限');
    }
  }

  getRate(model) {
    switch (model) {
      case 'cheap':
        return this.config.cheapModelRate;
      case 'mid':
        return this.config.midModelRate;
      case 'high':
        return this.config.highModelRate;
      default:
        return this.config.cheapModelRate;
    }
  }

  getRemaining() {
    return this.config.dailyLimit - this.state.todayUsage;
  }

  getCostRemaining() {
    const used = this.state.costToday;
    const maxCost = (this.state.todayUsage / this.config.dailyLimit) * 50; // 假设最大$50
    return maxCost - used;
  }

  getCurrentModel() {
    // 根据剩余Token调整模型
    const remaining = this.getRemaining();

    if (remaining < 50000) {
      logger.warn('Token剩余不足5万，切换到cheap-model');
      return 'cheap';
    }

    if (remaining < 100000) {
      logger.warn('Token剩余不足10万，切换到mid-model');
      return 'mid';
    }

    return 'cheap';
  }

  getUsageReport() {
    return {
      dailyLimit: this.config.dailyLimit,
      used: this.state.todayUsage,
      remaining: this.getRemaining(),
      costToday: this.state.costToday,
      modelUsage: this.state.modelUsage,
      costRemaining: this.getCostRemaining()
    };
  }

  shouldWarn() {
    const usagePercent = (this.state.todayUsage / this.config.dailyLimit) * 100;
    return usagePercent > 80;
  }

  shouldDowngrade() {
    const usagePercent = (this.state.todayUsage / this.config.dailyLimit) * 100;
    return usagePercent > 90;
  }
}

module.exports = new TokenGovernor();
