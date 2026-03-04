// openclaw-3.0/economy/token-governor.js
// Token 预算控制 - 成本控制核心

const fs = require('fs').promises;
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/token-governor.log' }),
    new winston.transports.Console({ format: winston.format.simple() })
  ]
});

// 加载配置
const CONFIG = require('../config.json');

class TokenGovernor {
  constructor() {
    this.dailyBudget = CONFIG.dailyBudget || 200000;
    this.dailyUsage = 0;
    this.hourlyUsage = 0;
    this.currentHour = new Date().getHours();

    // 历史成本统计（过去24小时）
    this.history = {
      last24h: [], // 按小时记录
      last7d: []   // 按天记录
    };

    // 成功率统计（过去7天）
    this.successStats = {
      totalCalls: 0,
      successfulCalls: 0,
      lastUpdated: null
    };

    // 模型分级策略
    this.modelStrategies = {
      cheap: {
        name: 'zai/glm-4-flash',
        dailyLimit: 100000,
        hourlyLimit: 20000,
        avgTokensPerCall: 100,
        successRate: 95
      },
      mid: {
        name: 'zai/glm-4.7-flash',
        dailyLimit: 50000,
        hourlyLimit: 10000,
        avgTokensPerCall: 200,
        successRate: 90
      },
      high: {
        name: 'zai/glm-4.5-flash',
        dailyLimit: 30000,
        hourlyLimit: 6000,
        avgTokensPerCall: 300,
        successRate: 85
      }
    };

    logger.info('Token Governor 初始化完成');
  }

  /**
   * 重置每日状态
   */
  resetDaily() {
    this.dailyUsage = 0;
    this.hourlyUsage = 0;
    this.currentHour = new Date().getHours();

    // 清空24小时历史
    this.history.last24h = [];

    logger.info('Token Governor 每日状态已重置');
  }

  /**
   * 检查是否可以调用
   * @param {Object} taskInfo - 任务信息
   * @returns {Object} 决策结果
   */
  canUseTokens(taskInfo = {}) {
    const { taskType = 'chat', estimatedTokens = 100 } = taskInfo;

    // 检查每日预算
    if (this.dailyUsage + estimatedTokens > this.dailyBudget) {
      return {
        allowed: false,
        reason: 'daily_budget_exceeded',
        available: this.dailyBudget - this.dailyUsage
      };
    }

    // 检查每小时预算
    if (this.hourlyUsage + estimatedTokens > this.modelStrategies.mid.hourlyLimit) {
      // 降级到 cheap model
      return {
        allowed: true,
        reason: 'hourly_limit_warning',
        downgradeTo: 'cheap',
        available: this.modelStrategies.mid.hourlyLimit - this.hourlyUsage
      };
    }

    return {
      allowed: true,
      reason: 'ok',
      model: this.selectModel(taskType)
    };
  }

  /**
   * 选择模型（混合策略）
   * @param {string} taskType - 任务类型
   * @returns {string} 模型类型
   */
  selectModel(taskType) {
    const { taskType: type, contextTokens, successRate, historyCost } = this.getAnalytics();

    // 基础策略：根据任务类型
    let baseModel = this.modelStrategies.cheap.name;

    switch (taskType) {
      case 'analysis':
      case 'strategy':
        baseModel = this.modelStrategies.mid.name;
        break;
      case 'complex':
        baseModel = this.modelStrategies.high.name;
        break;
      default:
        baseModel = this.modelStrategies.cheap.name;
    }

    // 历史成本调整
    if (historyCost && historyCost > 0.8) {
      // 成本过高，降级
      return this.modelStrategies.cheap.name;
    }

    // 成功率调整
    if (successRate && successRate < 80) {
      // 成功率过低，升级
      return this.modelStrategies.mid.name;
    }

    // 上下文大小调整
    if (contextTokens > 50000) {
      return this.modelStrategies.mid.name;
    }

    return baseModel;
  }

  /**
   * 获取分析数据（混合策略）
   * @returns {Object}
   */
  getAnalytics() {
    const now = Date.now();
    const last24h = now - 24 * 60 * 60 * 1000;
    const last7d = now - 7 * 24 * 60 * 60 * 1000;

    // 计算过去24小时平均使用量
    const recentCalls = this.history.last24h.filter(call => call.timestamp > last24h);
    const avgTokens24h = recentCalls.length > 0
      ? recentCalls.reduce((sum, call) => sum + call.tokens, 0) / recentCalls.length
      : 0;

    // 计算过去7天成本趋势
    const last7dCalls = this.history.last7d.filter(call => call.timestamp > last7d);
    const avgTokens7d = last7dCalls.length > 0
      ? last7dCalls.reduce((sum, call) => sum + call.tokens, 0) / last7dCalls.length
      : 0;

    // 成功率
    const totalCalls = this.successStats.totalCalls;
    const successfulCalls = this.successStats.successfulCalls;
    const successRate = totalCalls > 0 ? (successfulCalls / totalCalls) * 100 : 0;

    // 成本趋势（与7天前对比）
    const costTrend = avgTokens24h > 0
      ? ((avgTokens24h - avgTokens7d) / avgTokens7d * 100)
      : 0;

    return {
      taskType: 'chat',
      contextTokens: 0, // 需要从外部传入
      successRate,
      historyCost: avgTokens7d / this.dailyBudget
    };
  }

  /**
   * 记录 Token 使用
   * @param {number} tokens - 使用的 Token 数量
   * @param {boolean} success - 是否成功
   */
  recordUsage(tokens, success = true) {
    const now = Date.now();
    const currentHour = new Date().getHours();

    // 更新当日/当小时使用量
    if (currentHour !== this.currentHour) {
      this.currentHour = currentHour;
      this.hourlyUsage = 0;
    }

    this.dailyUsage += tokens;
    this.hourlyUsage += tokens;

    // 记录到历史
    this.history.last24h.push({
      timestamp: now,
      tokens,
      hour: currentHour
    });

    // 每6小时清理一次历史（保留最近24小时）
    if (this.history.last24h.length > 48) {
      this.history.last24h.shift();
    }

    // 记录到7天历史
    this.history.last7d.push({
      timestamp: now,
      tokens,
      date: new Date().toDateString()
    });

    // 清理超过7天的历史
    if (this.history.last7d.length > 168) {
      this.history.last7d.shift();
    }

    // 记录成功率
    this.successStats.totalCalls++;
    if (success) {
      this.successStats.successfulCalls++;
    }
    this.successStats.lastUpdated = now;

    logger.info({
      action: 'token_usage',
      tokens,
      dailyUsage: this.dailyUsage,
      hourlyUsage: this.hourlyUsage,
      success
    });
  }

  /**
   * 获取使用报告
   * @returns {Object}
   */
  getUsageReport() {
    return {
      used: this.dailyUsage,
      dailyLimit: this.dailyBudget,
      remaining: this.dailyBudget - this.dailyUsage,
      hourlyUsed: this.hourlyUsage,
      hourlyLimit: this.modelStrategies.mid.hourlyLimit,
      usageRatio: (this.dailyUsage / this.dailyBudget * 100).toFixed(2) + '%',
      currentHour: this.currentHour
    };
  }

  /**
   * 获取模型统计
   * @returns {Object}
   */
  getModelStats() {
    return {
      strategies: this.modelStrategies,
      analytics: this.getAnalytics(),
      successRate: this.successStats.totalCalls > 0
        ? (this.successStats.successfulCalls / this.successStats.totalCalls * 100).toFixed(2)
        : 0
    };
  }
}

module.exports = new TokenGovernor();
