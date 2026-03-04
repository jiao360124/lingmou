// core/strategy-engine.js
// 策略引擎 - V3.0+V3.2 集成版
// 简化版本，专注于核心策略功能

const winston = require('winston');
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/strategy-engine.log' }),
    new winston.transports.Console({ format: winston.format.simple() })
  ]
});

class StrategyEngine {
  constructor(config = {}) {
    this.config = {
      // 策略配置
      strategies: {
        AGGRESSIVE: {
          name: '激进型',
          description: '快速响应，高消耗，高收益',
          characteristics: {
            responseSpeed: 'fast',
            resourceUsage: 'high',
            risk: 'high',
            benefit: 'high',
            reliability: 'medium'
          },
          weights: { responseSpeed: 1.2, resourceUsage: 0.5, risk: 1.5, benefit: 1.8, reliability: 0.3 }
        },
        CONSERVATIVE: {
          name: '保守型',
          description: '缓慢响应，低消耗，低风险',
          characteristics: {
            responseSpeed: 'slow',
            resourceUsage: 'low',
            risk: 'very_low',
            benefit: 'low',
            reliability: 'high'
          },
          weights: { responseSpeed: 0.5, resourceUsage: 1.8, risk: 1.9, benefit: 0.5, reliability: 1.2 }
        },
        BALANCED: {
          name: '平衡型',
          description: '中等响应，中等消耗，平衡收益',
          characteristics: {
            responseSpeed: 'medium',
            resourceUsage: 'medium',
            risk: 'medium',
            benefit: 'medium',
            reliability: 'high'
          },
          weights: { responseSpeed: 1.0, resourceUsage: 1.0, risk: 1.0, benefit: 1.0, reliability: 1.0 }
        },
        EXPLORATORY: {
          name: '探索型',
          description: '尝试新方法，探索未知收益',
          characteristics: {
            responseSpeed: 'medium',
            resourceUsage: 'high',
            risk: 'high',
            benefit: 'very_high',
            reliability: 'low'
          },
          weights: { responseSpeed: 0.9, resourceUsage: 1.2, risk: 1.8, benefit: 2.2, reliability: 0.2 }
        }
      },
      defaultStrategy: 'BALANCED',
      strategyHistory: [],
      maxHistorySize: 100
    };

    this.config = { ...this.config, ...config };
    this.strategyHistory = [];

    logger.info('🧠 策略引擎初始化完成');
    logger.info(`📊 默认策略: ${this.config.strategies[this.config.defaultStrategy].name}`);
  }

  /**
   * 评估任务特征
   * @param {Object} context - 任务上下文
   * @returns {Object} 任务特征评分
   */
  evaluateTaskContext(context) {
    const { taskType, priority, urgency, budget } = context;

    let taskFeatures = {
      responseSpeedRequirement: 0,
      resourceBudget: 0,
      riskTolerance: 0,
      benefitValue: 0
    };

    // 响应速度要求
    if (urgency === 'critical') taskFeatures.responseSpeedRequirement = 1.2;
    else if (urgency === 'high') taskFeatures.responseSpeedRequirement = 1.0;
    else if (urgency === 'medium') taskFeatures.responseSpeedRequirement = 0.8;
    else if (urgency === 'low') taskFeatures.responseSpeedRequirement = 0.6;

    // 资源预算
    if (budget === 'tight') taskFeatures.resourceBudget = 0.5;
    else if (budget === 'normal') taskFeatures.resourceBudget = 1.0;
    else if (budget === 'generous') taskFeatures.resourceBudget = 1.5;

    // 风险容忍度
    if (priority === 'critical') taskFeatures.riskTolerance = 0.8;
    else if (priority === 'high') taskFeatures.riskTolerance = 1.0;
    else if (priority === 'medium') taskFeatures.riskTolerance = 1.2;
    else if (priority === 'low') taskFeatures.riskTolerance = 1.5;

    // 收益价值
    if (taskType === 'emergency') taskFeatures.benefitValue = 2.0;
    else if (taskType === 'optimization') taskFeatures.benefitValue = 1.5;
    else if (taskType === 'maintenance') taskFeatures.benefitValue = 1.0;
    else if (taskType === 'exploration') taskFeatures.benefitValue = 1.3;

    logger.debug('📊 任务特征评估', taskFeatures);

    return taskFeatures;
  }

  /**
   * 计算策略得分
   * @param {string} strategyType - 策略类型
   * @param {Object} taskFeatures - 任务特征
   * @returns {Object} 策略得分
   */
  calculateStrategyScore(strategyType, taskFeatures) {
    const strategy = this.config.strategies[strategyType];

    if (!strategy || !strategy.characteristics) {
      logger.warn(`策略 ${strategyType} 配置不完整，跳过计算`);
      return null;
    }

    const characteristics = strategy.characteristics;

    // 计算加权得分
    const responseScore = taskFeatures.responseSpeedRequirement * characteristics.weights.responseSpeed;
    const resourceScore = taskFeatures.resourceBudget * characteristics.weights.resourceUsage;
    const riskScore = taskFeatures.riskTolerance * characteristics.weights.risk;
    const benefitScore = taskFeatures.benefitValue * characteristics.weights.benefit;
    const reliabilityScore = (characteristics.reliability || 0.8) * characteristics.weights.reliability;

    // 总得分
    const totalScore =
      responseScore + resourceScore + riskScore + benefitScore + reliabilityScore;

    // 计算各项指标的分数
    const metrics = {
      responseSpeed: responseScore,
      resourceUsage: resourceScore,
      risk: riskScore,
      benefit: benefitScore,
      reliability: reliabilityScore,
      total: totalScore
    };

    return {
      strategyType,
      ...strategy,
      metrics,
      totalScore: parseFloat(totalScore.toFixed(2)),
      characteristics
    };
  }

  /**
   * 计算策略得分
   * @param {string} strategyType - 策略类型
   * @param {Object} taskFeatures - 任务特征
   * @returns {Object} 策略得分
   */
  calculateStrategyScore(strategyType, taskFeatures) {
    const strategy = this.config.strategies[strategyType];

    if (!strategy) {
      logger.warn(`策略 ${strategyType} 不存在，跳过计算`);
      return null;
    }

    const characteristics = strategy.characteristics || {};
    const weights = characteristics.weights || {};

    // 使用默认权重值
    const responseScore = (taskFeatures.responseSpeedRequirement || 0) * 1.0;
    const resourceScore = (taskFeatures.resourceBudget || 0) * 1.0;
    const riskScore = (taskFeatures.riskTolerance || 0) * 1.0;
    const benefitScore = (taskFeatures.benefitValue || 0) * 1.0;
    const reliabilityScore = (characteristics.reliability || 1.0) * 0.8;

    // 总得分
    const totalScore = Math.max(0.1, responseScore + resourceScore + riskScore + benefitScore + reliabilityScore);

    // 计算各项指标的分数
    const metrics = {
      responseSpeed: parseFloat(responseScore.toFixed(2)),
      resourceUsage: parseFloat(resourceScore.toFixed(2)),
      risk: parseFloat(riskScore.toFixed(2)),
      benefit: parseFloat(benefitScore.toFixed(2)),
      reliability: parseFloat(reliabilityScore.toFixed(2)),
      total: parseFloat(totalScore.toFixed(2))
    };

    return {
      strategyType,
      ...strategy,
      metrics,
      totalScore,
      characteristics
    };
  }

  /**
   * 选择最优策略
   * @param {Object} context - 任务上下文
   * @returns {Object} 最优策略
   */
  selectBestStrategy(context) {
    logger.info('🎯 开始选择最优策略...');

    // 评估任务特征
    const taskFeatures = this.evaluateTaskContext(context);

    // 计算所有策略得分
    const strategyScores = Object.keys(this.config.strategies)
      .map(type => this.calculateStrategyScore(type, taskFeatures));

    // 按总得分排序
    strategyScores.sort((a, b) => b.totalScore - a.totalScore);

    // 获取最优策略
    const bestStrategy = strategyScores[0];

    logger.info('📊 策略得分', {
      strategies: strategyScores.map(s => ({
        type: s.strategyType,
        name: s.name,
        score: s.totalScore
      })),
      best: {
        type: bestStrategy.strategyType,
        name: bestStrategy.name,
        score: bestStrategy.totalScore
      }
    });

    // 记录策略历史
    this.recordStrategyHistory(bestStrategy, context);

    return {
      strategy: bestStrategy,
      taskFeatures,
      availableStrategies: strategyScores
    };
  }

  /**
   * 记录策略历史
   * @param {Object} strategy - 选择的策略
   * @param {Object} context - 任务上下文
   */
  recordStrategyHistory(strategy, context) {
    this.strategyHistory.push({
      timestamp: Date.now(),
      strategyType: strategy.strategyType,
      name: strategy.name,
      score: strategy.totalScore,
      context
    });

    // 限制历史记录数量
    if (this.strategyHistory.length > this.config.maxHistorySize) {
      this.strategyHistory.shift();
    }
  }

  /**
   * 获取策略历史
   * @returns {Array} 策略历史
   */
  getStrategyHistory() {
    return [...this.strategyHistory];
  }

  /**
   * 获取策略统计
   * @returns {Object} 策略统计
   */
  getStrategyStats() {
    const stats = {
      totalDecisions: this.strategyHistory.length,
      strategyDistribution: {},
      averageScore: 0,
      recentTrend: []
    };

    // 策略分布
    this.strategyHistory.forEach(record => {
      stats.strategyDistribution[record.strategyType] =
        (stats.strategyDistribution[record.strategyType] || 0) + 1;
    });

    // 平均得分
    if (this.strategyHistory.length > 0) {
      const totalScore = this.strategyHistory.reduce((sum, record) => sum + record.score, 0);
      stats.averageScore = parseFloat((totalScore / this.strategyHistory.length).toFixed(2));
    }

    // 最近趋势
    const recentHistory = this.strategyHistory.slice(-10);
    stats.recentTrend = recentHistory.map(record => ({
      strategy: record.name,
      score: record.score,
      timestamp: record.timestamp
    }));

    return stats;
  }

  /**
   * 获取策略建议
   * @param {Object} context - 任务上下文
   * @returns {Object} 策略建议
   */
  getStrategyAdvice(context) {
    const best = this.selectBestStrategy(context);
    const stats = this.getStrategyStats();

    return {
      recommendation: best.strategy.name,
      confidence: parseFloat((best.strategy.totalScore / 10).toFixed(2)),
      reasons: [
        `任务特征需要: ${context.urgency} 紧急度, ${context.budget} 预算`,
        `该策略得分最高: ${best.strategy.totalScore} 分`,
        `使用频率: ${stats.strategyDistribution[best.strategy.strategyType] || 0} 次`
      ],
      details: {
        responseSpeed: best.strategy.characteristics.responseSpeed,
        resourceUsage: best.strategy.characteristics.resourceUsage,
        risk: best.strategy.characteristics.risk,
        benefit: best.strategy.characteristics.benefit,
        reliability: best.strategy.characteristics.reliability
      }
    };
  }

  /**
   * 获取系统状态
   * @returns {Object} 系统状态
   */
  getStatus() {
    return {
      initialized: true,
      defaultStrategy: this.config.defaultStrategy,
      strategiesCount: Object.keys(this.config.strategies).length,
      totalDecisions: this.strategyHistory.length,
      averageScore: this.getStrategyStats().averageScore,
      strategyDistribution: this.getStrategyStats().strategyDistribution
    };
  }
}

module.exports = StrategyEngine;
