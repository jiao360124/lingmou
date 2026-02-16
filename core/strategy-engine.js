/**
 * OpenClaw V3.2 - Strategy Engine
 * 预测 → 多策略生成 → 收益评估 → 最优选择 → 执行 → 复盘
 * 从"反应型智能"升级为"规划型智能"
 */

class StrategyEngine {
  constructor(config = {}) {
    this.config = {
      riskWeight: 0.3,                // 风险权重系数
      benefitWeight: 0.7,             // 收益权重系数
      ...config
    };

    // 策略类型定义
    this.strategyTypes = {
      AGGRESSIVE: { label: '激进型', desc: '快速响应，高消耗，高收益' },
      CONSERVATIVE: { label: '保守型', desc: '缓慢响应，低消耗，低风险' },
      BALANCED: { label: '平衡型', desc: '中等响应，中等消耗，平衡收益' },
      EXPLORATORY: { label: '探索型', desc: '尝试新方法，探索未知收益' }
    };
  }

  /**
   * 主入口：生成策略池并选择最优策略
   */
  generateAndSelectStrategy(metrics, context, constraints = {}) {
    const strategies = this.simulateScenarios(metrics, context, constraints);
    if (strategies.length === 0) {
      throw new Error('No strategies generated');
    }

    const evaluated = strategies.map(s => ({
      ...s,
      benefit: this.evaluateBenefit(s, metrics, context),
      risk: this.evaluateRisk(s, metrics, context),
      combinedScore: this.calculateCombinedScore(s, metrics, context)
    }));

    const best = this.selectOptimalStrategy(evaluated, metrics, context);
    this.logStrategySelection(best, evaluated, metrics, context);

    return best;
  }

  /**
   * 场景模拟器：生成多个响应策略
   */
  simulateScenarios(metrics, context, constraints = {}) {
    const strategies = [];

    strategies.push(this.createConservativeStrategy(metrics, context, constraints));
    strategies.push(this.createAggressiveStrategy(metrics, context, constraints));
    strategies.push(this.createBalancedStrategy(metrics, context, constraints));

    const pressure = this.assessOverallPressure(metrics, context);
    if (pressure.pressure > 0.6) {
      strategies.push(this.createExploratoryStrategy(metrics, context, constraints));
    }

    return strategies;
  }

  createConservativeStrategy(metrics, context, constraints) {
    const delay = Math.min(500, this.calculateDelay(0.4));
    const compression = Math.max(0, context.compressionLevel - 1);
    const model = this.selectModelByBudget(0.8);

    return {
      id: this.genId('CONSERVATIVE'),
      type: 'CONSERVATIVE',
      label: this.strategyTypes.CONSERVATIVE.label,
      delay,
      compressionLevel: compression,
      modelBias: model,
      estimatedCost: this.estimateCost({ delay, compression, model }, metrics),
      expectedSuccessRate: Math.min(0.99, 0.97 + context.compressionLevel * 0.005),
      risks: ['响应延迟较高', '资源消耗低'],
      benefits: ['风险最低', '成本最低', '适合稳定环境']
    };
  }

  createAggressiveStrategy(metrics, context, constraints) {
    const delay = Math.min(50, this.calculateDelay(0.95));
    const compression = Math.min(3, context.compressionLevel + 1);
    const model = this.selectModelByBudget(0.2);

    return {
      id: this.genId('AGGRESSIVE'),
      type: 'AGGRESSIVE',
      label: this.strategyTypes.AGGRESSIVE.label,
      delay,
      compressionLevel: compression,
      modelBias: model,
      estimatedCost: this.estimateCost({ delay, compression, model }, metrics),
      expectedSuccessRate: Math.min(0.95, 0.93 - context.compressionLevel * 0.005),
      risks: ['响应速度快但错误率高', '成本较高'],
      benefits: ['响应最快', '处理能力最强', '适合紧急场景']
    };
  }

  createBalancedStrategy(metrics, context, constraints) {
    return {
      id: this.genId('BALANCED'),
      type: 'BALANCED',
      label: this.strategyTypes.BALANCED.label,
      delay: this.calculateDelay(0.6),
      compressionLevel: context.compressionLevel,
      modelBias: this.selectModelByBudget(0.5),
      estimatedCost: this.estimateCost(
        { delay: this.calculateDelay(0.6), compression: context.compressionLevel, model: this.selectModelByBudget(0.5) },
        metrics
      ),
      expectedSuccessRate: 0.96,
      risks: ['响应速度中等', '资源消耗中等'],
      benefits: ['平衡性好', '风险可控', '成本合理']
    };
  }

  createExploratoryStrategy(metrics, context, constraints) {
    return {
      id: this.genId('EXPLORATORY'),
      type: 'EXPLORATORY',
      label: this.strategyTypes.EXPLORATORY.label,
      delay: this.calculateDelay(0.5) * 0.7,
      compressionLevel: context.compressionLevel,
      modelBias: this.selectModelByBudget(0.7),
      estimatedCost: this.estimateCost(
        { delay: this.calculateDelay(0.5) * 0.7, compression: context.compressionLevel, model: this.selectModelByBudget(0.7) },
        metrics
      ),
      expectedSuccessRate: 0.94,
      risks: ['成功率不确定', '可能产生意外效果'],
      benefits: ['可能发现新优化路径', '探索未知领域'],
      experimental: true
    };
  }

  evaluateBenefit(strategy, metrics, context) {
    const successRateGain = strategy.expectedSuccessRate - (metrics.currentSuccessRate || 0.945);
    const costReduction = (this.calculateCostImpact(metrics) - strategy.estimatedCost) / this.calculateCostImpact(metrics);
    const delayImprovement = (this.calculateDelayImpact(metrics) - strategy.delay) / this.calculateDelayImpact(metrics);
    const compressionImprovement = context.compressionLevel - strategy.compressionLevel;
    const modelScore = this.calculateModelScore(strategy.modelBias);

    const totalScore = (successRateGain * 0.35) + (costReduction * 0.25) +
                       (delayImprovement * 0.20) + (compressionImprovement * 0.10) +
                       (modelScore * 0.10);

    return {
      totalScore: Math.max(0, Math.min(100, totalScore)),
      details: { successRateGain, costReduction, delayImprovement, compressionImprovement, modelScore }
    };
  }

  evaluateRisk(strategy, metrics, context) {
    let totalRisk = 0;

    const successRateRisk = 1 - strategy.expectedSuccessRate;
    totalRisk += successRateRisk * 40;

    const costRatio = strategy.estimatedCost / this.calculateCostImpact(metrics);
    totalRisk += Math.max(0, costRatio - 1) * 30;

    const delayRatio = strategy.delay / this.calculateDelayImpact(metrics);
    totalRisk += Math.max(0, delayRatio - 1) * 20;

    totalRisk += strategy.compressionLevel * 10;
    totalRisk += this.calculateModelRisk(strategy.modelBias);

    return {
      score: Math.min(100, Math.max(0, totalRisk)),
      level: totalRisk >= 70 ? 'CRITICAL' : totalRisk >= 50 ? 'HIGH' : totalRisk >= 30 ? 'MEDIUM' : 'LOW',
      details: { successRateRisk, costRatio, delayRatio, compression: strategy.compressionLevel }
    };
  }

  calculateCombinedScore(strategy, metrics, context) {
    const benefit = this.evaluateBenefit(strategy, metrics, context);
    const risk = this.evaluateRisk(strategy, metrics, context);

    return (benefit.totalScore - risk.score * this.config.riskWeight) * this.config.benefitWeight;
  }

  selectOptimalStrategy(evaluated, metrics, context) {
    const sorted = [...evaluated].sort((a, b) => b.combinedScore - a.combinedScore);
    let best = sorted[0];

    if (best.constraints?.delay) {
      const { min, max } = best.constraints.delay;
      if (best.delay < min || best.delay > max) {
        for (let i = 1; i < sorted.length; i++) {
          const c = sorted[i];
          if (c.constraints?.delay?.min <= c.delay && c.constraints?.delay?.max >= c.delay) {
            best = c;
            break;
          }
        }
      }
    }

    if (context.budgetConstraints?.maxCost && best.estimatedCost > context.budgetConstraints.maxCost) {
      for (let i = 1; i < sorted.length; i++) {
        const c = sorted[i];
        if (c.estimatedCost <= context.budgetConstraints.maxCost) {
          best = c;
          break;
        }
      }
    }

    return best;
  }

  calculateDelay(pressure) {
    if (pressure < 0.4) return 300;
    if (pressure < 0.6) return 150;
    if (pressure < 0.8) return 50;
    return 0;
  }

  selectModelByBudget(budgetRatio) {
    if (budgetRatio < 0.3) return 'CHEAP_ONLY';
    if (budgetRatio < 0.7) return 'MID_ONLY';
    if (budgetRatio < 0.9) return 'REDUCE_HIGH';
    return 'NORMAL';
  }

  estimateCost(params, metrics) {
    let cost = params.delay * 0.1 + params.compression * 100;
    if (params.model === 'CHEAP_ONLY') cost *= 0.5;
    else if (params.model === 'MID_ONLY') cost *= 0.7;
    else if (params.model === 'REDUCE_HIGH') cost *= 0.85;
    return Math.round(cost * 10) / 10;
  }

  calculateCostImpact(metrics) { return metrics.currentCost || 1000; }
  calculateDelayImpact(metrics) { return metrics.currentDelay || 200; }
  calculateModelScore(model) {
    if (model === 'CHEAP_ONLY') return 70;
    if (model === 'MID_ONLY') return 85;
    if (model === 'REDUCE_HIGH') return 90;
    return 95;
  }
  calculateModelRisk(model) {
    if (model === 'CHEAP_ONLY') return 20;
    if (model === 'MID_ONLY') return 10;
    if (model === 'REDUCE_HIGH') return 15;
    return 5;
  }
  genId(type) { return `${type}_${Date.now()}_${Math.floor(Math.random() * 1000)}`; }

  assessOverallPressure(metrics, context) {
    const ratePressure = this.evaluateRatePressure(metrics);
    const ctxPressure = this.evaluateContextPressure(context);
    const budgetPressure = this.evaluateBudgetPressure(metrics);

    const total = (ratePressure.pressure + ctxPressure.remainingRatio + (1 - metrics.remainingBudget / metrics.dailyBudget)) / 3;
    return {
      pressure: Math.round(total * 100) / 100,
      level: total > 0.85 ? 'CRITICAL' : total > 0.7 ? 'HIGH' : total > 0.4 ? 'MEDIUM' : 'NORMAL'
    };
  }

  evaluateRatePressure(metrics) {
    const p = (metrics.callsLastMinute || 0) / 100;
    return {
      pressure: Math.round(p * 100) / 100,
      delay: p > 0.9 ? 800 : p > 0.7 ? 400 : p > 0.4 ? 150 : 0,
      level: p > 0.9 ? 'CRITICAL' : p > 0.7 ? 'HIGH' : p > 0.4 ? 'MEDIUM' : 'NORMAL'
    };
  }

  evaluateContextPressure(context) {
    const r = context.remainingTokens / context.maxTokens;
    let comp = 0;
    if (r < 0.25) comp = 2;
    if (r < 0.15) comp = 3;
    return { remainingRatio: Math.round(r * 100) / 100, compressionLevel: comp };
  }

  evaluateBudgetPressure(metrics) {
    const hoursLeft = metrics.remainingBudget / metrics.dailyBudget;
    if (hoursLeft < 0.125) return { hoursLeft: Math.round(hoursLeft * 10) / 10, modelBias: 'CHEAP_ONLY', level: 'CRITICAL' };
    if (hoursLeft < 0.25) return { hoursLeft: Math.round(hoursLeft * 10) / 10, modelBias: 'MID_ONLY', level: 'HIGH' };
    if (hoursLeft < 0.5) return { hoursLeft: Math.round(hoursLeft * 10) / 10, modelBias: 'REDUCE_HIGH', level: 'MEDIUM' };
    return { hoursLeft: Math.round(hoursLeft * 10) / 10, modelBias: 'NORMAL', level: 'NORMAL' };
  }

  logStrategySelection(selected, all, metrics, context) {
    console.log('[StrategyEngine] 策略选择:', {
      selected: { type: selected.type, score: selected.combinedScore.toFixed(2), benefit: selected.benefit.totalScore, risk: selected.risk.score },
      strategies: all.map(s => ({ type: s.type, score: s.combinedScore.toFixed(2), benefit: s.benefit.totalScore, risk: s.risk.score }))
    });
  }
}

module.exports = StrategyEngine;
