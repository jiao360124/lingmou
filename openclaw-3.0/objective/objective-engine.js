// openclaw-3.0/objective/objective-engine.js
// Objective Engine - 目标管理和优化建议

const fs = require('fs').promises;
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/objective-engine.log' }),
    new winston.transports.Console({ format: winston.format.simple() })
  ]
});

// 加载配置
const CONFIG = require('../config.json');

class ObjectiveEngine {
  constructor() {
    // 默认目标
    this.goals = {
      longTerm: '降低30%API成本',
      monthly: '自动恢复率>90%',
      daily: '优化429退避策略'
    };

    // 目标定义
    this.goalDefinitions = {
      costReduction: {
        name: '成本降低',
        target: 30,
        current: 0,
        unit: '%',
        description: 'API成本降低目标'
      },
      recoveryRate: {
        name: '恢复率提升',
        target: 90,
        current: 87,
        unit: '%',
        description: '自动恢复率目标'
      },
      successRate: {
        name: '成功率提升',
        target: 95,
        current: 90,
        unit: '%',
        description: 'API调用成功率目标'
      },
      tokenUsage: {
        name: 'Token使用优化',
        target: 150000,
        current: 180000,
        unit: 'tokens',
        description: '每日Token使用上限'
      }
    };

    logger.info('Objective Engine 初始化完成');
  }

  /**
   * 获取当前目标
   * @returns {Object}
   */
  getGoals() {
    return this.goals;
  }

  /**
   * 设置目标
   * @param {Object} newGoals - 新目标
   */
  setGoals(newGoals) {
    Object.assign(this.goals, newGoals);
    logger.info('目标已更新', this.goals);
  }

  /**
   * 计算 Gap（目标与实际差距）
   * @param {string} goalKey - 目标键
   * @param {number} currentValue - 当前值
   * @returns {Object}
   */
  calculateGap(goalKey, currentValue) {
    const definition = this.goalDefinitions[goalKey];

    if (!definition) {
      return { error: 'Unknown goal key' };
    }

    const target = definition.target;
    const unit = definition.unit;
    const gap = target - currentValue;

    return {
      goalKey,
      goalName: definition.name,
      target,
      currentValue,
      gap,
      unit,
      status: gap >= 0 ? 'good' : 'needs_improvement'
    };
  }

  /**
   * 分析所有目标的 Gap
   * @returns {Array}
   */
  analyzeAllGaps() {
    const gaps = [];

    // 成本降低
    gaps.push(this.calculateGap('costReduction', this.goals.costReduction || 0));

    // 恢复率提升
    gaps.push(this.calculateGap('recoveryRate', this.goals.recoveryRate || 0));

    // 成功率提升
    gaps.push(this.calculateGap('successRate', this.goals.successRate || 0));

    // Token 使用
    gaps.push(this.calculateGap('tokenUsage', this.goals.tokenUsage || 0));

    return gaps;
  }

  /**
   * 获取 Gap 分析报告
   * @returns {Object}
   */
  getGapAnalysis() {
    const gaps = this.analyzeAllGaps();

    // 找出最大 Gap（最需要改进的）
    const maxGap = gaps.reduce((max, current) =>
      Math.abs(current.gap) > Math.abs(max.gap) ? current : max
    , gaps[0]);

    // 找出所有需要改进的目标
    const needsImprovement = gaps.filter(g => g.status === 'needs_improvement');

    return {
      gaps,
      maxGap,
      needsImprovement,
      totalNeedsImprovement: needsImprovement.length
    };
  }

  /**
   * 获取优化建议
   * @param {Object} metrics - 指标数据
   * @returns {Object}
   */
  getOptimizationSuggestions(metrics) {
    const gapAnalysis = this.getGapAnalysis();

    // 根据最大的 Gap 生成建议
    const suggestions = [];

    if (gapAnalysis.maxGap.status === 'needs_improvement') {
      const gap = gapAnalysis.maxGap;
      suggestions.push({
        goal: gap.goalName,
        current: gap.currentValue,
        target: gap.target,
        gap: gap.gap,
        unit: gap.unit,
        suggestedAction: this.getSuggestedAction(gap)
      });
    }

    // 基于指标数据生成额外建议
    if (metrics.errorRate > 10) {
      suggestions.push({
        goal: '成功率提升',
        current: metrics.successRate || 90,
        target: 95,
        gap: (95 - (metrics.successRate || 90)).toFixed(1),
        unit: '%',
        suggestedAction: 'fix_prompt, reduce_context_length, increase_retry'
      });
    }

    if (metrics.dailyTokens > 180000) {
      suggestions.push({
        goal: 'Token使用优化',
        current: metrics.dailyTokens || 180000,
        target: 150000,
        gap: (metrics.dailyTokens || 180000) - 150000,
        unit: 'tokens',
        suggestedAction: 'reduce_tokens, optimize_summary, enable_cache'
      });
    }

    return {
      suggestions,
      basedOn: gapAnalysis.maxGap ? gapAnalysis.maxGap.goalName : 'no significant gap',
      totalSuggestions: suggestions.length
    };
  }

  /**
   * 根据目标获取建议
   * @param {string} goalKey - 目标键
   * @returns {string}
   */
  getSuggestedAction(goalKey) {
    switch (goalKey) {
      case 'costReduction':
        return 'reduce_tokens, switch_to_cheap_model, enable_cache';
      case 'recoveryRate':
        return 'improve_error_handling, increase_retry, add_fallback';
      case 'successRate':
        return 'fix_prompt, reduce_context_length, increase_retry';
      case 'tokenUsage':
        return 'reduce_tokens, optimize_summary, enable_cache, prune_context';
      default:
        return 'review_and_improve';
    }
  }

  /**
   * 获取目标优化报告
   * @returns {Object}
   */
  getReport() {
    const gaps = this.analyzeAllGaps();
    const optimization = this.getOptimizationSuggestions(gaps);

    return {
      goals: this.goals,
      gapAnalysis: {
        ...this.getGapAnalysis(),
        dailyMetrics: {
          costReduction: gaps[0],
          recoveryRate: gaps[1],
          successRate: gaps[2],
          tokenUsage: gaps[3]
        }
      },
      optimization
    };
  }

  /**
   * 更新目标
   * @param {string} goalKey - 目标键
   * @param {number} value - 新值
   */
  updateGoal(goalKey, value) {
    if (this.goals[goalKey] !== undefined) {
      this.goals[goalKey] = value;
      logger.info(`目标已更新: ${goalKey} = ${value}`);
    } else if (this.goalDefinitions[goalKey]) {
      this.goalDefinitions[goalKey].current = value;
      logger.info(`当前值已更新: ${goalKey} = ${value}`);
    } else {
      logger.warn(`未知的目标键: ${goalKey}`);
    }
  }
}

module.exports = new ObjectiveEngine();
