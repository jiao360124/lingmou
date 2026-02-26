/**
 * OpenClaw V3.2 - Core Strategy Engine
 * 策略层核心：预测→多策略生成→收益评估→最优选择→执行→复盘
 * 从"反应型智能"升级为"规划型智能"
 *
 * @author OpenClaw V3.2
 * @date 2026-02-22
 */

const fs = require('fs');
const path = require('path');

/**
 * 策略类型枚举
 */
const StrategyType = {
  AGGRESSIVE: 'AGGRESSIVE',
  CONSERVATIVE: 'CONSERVATIVE',
  BALANCED: 'BALANCED',
  EXPLORATORY: 'EXPLORATORY'
};

/**
 * 策略类型定义
 */
const STRATEGY_TYPES = {
  [StrategyType.AGGRESSIVE]: {
    label: '激进型',
    desc: '快速响应，高消耗，高收益',
    delayRange: [0, 50],
    compressionRange: [1, 3],
    modelBias: 'CHEAP_ONLY'
  },
  [StrategyType.CONSERVATIVE]: {
    label: '保守型',
    desc: '缓慢响应，低消耗，低风险',
    delayRange: [300, 500],
    compressionRange: [0, 1],
    modelBias: 'MID_ONLY'
  },
  [StrategyType.BALANCED]: {
    label: '平衡型',
    desc: '中等响应，中等消耗，平衡收益',
    delayRange: [50, 200],
    compressionRange: [0, 2],
    modelBias: 'NORMAL'
  },
  [StrategyType.EXPLORATORY]: {
    label: '探索型',
    desc: '尝试新方法，探索未知收益',
    delayRange: [0, 100],
    compressionRange: [0, 2],
    modelBias: 'NORMAL'
  }
};

class CoreStrategyEngine {
  constructor(config = {}) {
    this.name = 'CoreStrategyEngine';
    this.config = {
      riskWeight: config.riskWeight || 0.3,                // 风险权重系数
      benefitWeight: config.benefitWeight || 0.7,          // 收益权重系数
      strategyTypes: config.strategyTypes || STRATEGY_TYPES,
      ...config
    };

    // 策略注册表
    this.strategies = new Map();

    // 学习历史
    this.learnings = new Map();

    // 数据目录 - 使用配置的 dataDir，如果没有则使用默认值
    this.dataDir = config.dataDir || path.join(__dirname, '../data');
    this.ensureDataDir();

    // 加载历史学习数据
    this.loadLearnings();

    console.log(`[CoreStrategyEngine] 初始化完成，配置:`, this.config);
  }

  /**
   * 确保数据目录存在
   */
  ensureDataDir() {
    if (!fs.existsSync(this.dataDir)) {
      fs.mkdirSync(this.dataDir, { recursive: true });
      console.log(`[CoreStrategyEngine] 创建数据目录: ${this.dataDir}`);
    }
  }

  /**
   * 加载历史学习数据
   */
  loadLearnings() {
    const learningFile = path.resolve(this.dataDir, 'strategy-engine-learnings.json');

    if (fs.existsSync(learningFile)) {
      try {
        const data = JSON.parse(fs.readFileSync(learningFile, 'utf8'));
        this.learnings = new Map(data);
        console.log(`[CoreStrategyEngine] 加载历史学习数据: ${this.learnings.size} 条记录 <- ${learningFile}`);
      } catch (error) {
        console.error(`[CoreStrategyEngine] 加载历史数据失败: ${error.message}`);
      }
    }
  }

  /**
   * 保存学习数据
   */
  saveLearnings() {
    const learningFile = path.resolve(this.dataDir, 'strategy-engine-learnings.json');

    try {
      const data = Array.from(this.learnings.entries());
      fs.writeFileSync(learningFile, JSON.stringify(data, null, 2));
      console.log(`[CoreStrategyEngine] 保存学习数据: ${data.length} 条记录 -> ${learningFile}`);
    } catch (error) {
      console.error(`[CoreStrategyEngine] 保存学习数据失败: ${error.message}`);
      console.error(`[CoreStrategyEngine] 数据目录: ${this.dataDir}`);
    }
  }

  /**
   * 注册策略
   * @param {Object} strategy - 策略对象
   */
  registerStrategy(strategy) {
    this.strategies.set(strategy.id || strategy.type, strategy);
    console.log(`[CoreStrategyEngine] 注册策略: ${strategy.id || strategy.type}`);
  }

  /**
   * 主入口：生成策略池并选择最优策略
   * @param {Object} metrics - 指标数据
   * @param {Object} context - 上下文数据
   * @param {Object} constraints - 约束条件
   * @returns {Promise<StrategyRecommendation>}
   */
  async generateAndSelectStrategy(metrics, context, constraints = {}) {
    const startTime = Date.now();

    console.log(`[CoreStrategyEngine] 开始生成策略`);

    // 1. 场景模拟：生成多个响应策略
    console.log('[CoreStrategyEngine] 步骤 1/5: 场景模拟');
    const strategies = this.simulateScenarios(metrics, context, constraints);

    if (strategies.length === 0) {
      throw new Error('No strategies generated');
    }

    console.log(`[CoreStrategyEngine] 生成 ${strategies.length} 个策略`);

    // 2. 评估每个策略的收益和风险
    console.log('[CoreStrategyEngine] 步骤 2/5: 评估策略');
    const evaluated = strategies.map(s => ({
      ...s,
      benefit: this.evaluateBenefit(s, metrics, context),
      risk: this.evaluateRisk(s, metrics, context),
      combinedScore: this.calculateCombinedScore(s, metrics, context)
    }));

    // 3. 选择最优策略
    console.log('[CoreStrategyEngine] 步骤 3/5: 选择最优策略');
    const best = this.selectOptimalStrategy(evaluated, metrics, context);

    // 4. 记录学习数据
    console.log('[CoreStrategyEngine] 步骤 4/5: 记录学习数据');
    this.recordLearning(best, evaluated, metrics, context);

    // 5. 保存学习数据
    console.log('[CoreStrategyEngine] 步骤 5/5: 持久化学习数据');
    this.saveLearnings();

    const duration = Date.now() - startTime;

    console.log(`[CoreStrategyEngine] 策略选择完成，耗时: ${duration}ms`);

    return {
      selected: best,
      allEvaluated: evaluated,
      metrics,
      context,
      constraints,
      executionTime: duration,
      timestamp: new Date()
    };
  }

  /**
   * 场景模拟器：生成多个响应策略
   * @param {Object} metrics - 指标数据
   * @param {Object} context - 上下文数据
   * @param {Object} constraints - 约束条件
   * @returns {Array<Strategy>}
   */
  simulateScenarios(metrics, context, constraints) {
    const strategies = [];

    // 根据压力水平决定生成多少策略
    const pressure = this.assessOverallPressure(metrics, context);

    // 基础策略：保守型、平衡型、激进型
    strategies.push(this.createConservativeStrategy(metrics, context, constraints));
    strategies.push(this.createBalancedStrategy(metrics, context, constraints));
    strategies.push(this.createAggressiveStrategy(metrics, context, constraints));

    // 高压场景添加探索型策略
    if (pressure.pressure > 0.6) {
      strategies.push(this.createExploratoryStrategy(metrics, context, constraints));
    }

    // 如果用户注册了自定义策略，也加入池中
    for (const [strategyId, strategy] of this.strategies) {
      // 限制只加入最多 5 个策略
      if (strategies.length >= 5) break;
      strategies.push(strategy);
    }

    return strategies;
  }

  /**
   * 创建保守型策略
   */
  createConservativeStrategy(metrics, context, constraints) {
    const delay = Math.min(500, this.calculateDelay(0.4));
    const compression = Math.max(0, context.compressionLevel - 1);
    const model = this.selectModelByBudget(0.8);

    return {
      id: this.genId(StrategyType.CONSERVATIVE),
      type: StrategyType.CONSERVATIVE,
      label: this.config.strategyTypes[StrategyType.CONSERVATIVE].label,
      delay,
      compressionLevel: compression,
      modelBias: model,
      estimatedCost: this.estimateCost({ delay, compression, model }, metrics),
      expectedSuccessRate: Math.min(0.99, 0.97 + context.compressionLevel * 0.005),
      risks: ['响应延迟较高', '资源消耗低'],
      benefits: ['风险最低', '成本最低', '适合稳定环境']
    };
  }

  /**
   * 创建激进型策略
   */
  createAggressiveStrategy(metrics, context, constraints) {
    const delay = Math.min(50, this.calculateDelay(0.95));
    const compression = Math.min(3, context.compressionLevel + 1);
    const model = this.selectModelByBudget(0.2);

    return {
      id: this.genId(StrategyType.AGGRESSIVE),
      type: StrategyType.AGGRESSIVE,
      label: this.config.strategyTypes[StrategyType.AGGRESSIVE].label,
      delay,
      compressionLevel: compression,
      modelBias: model,
      estimatedCost: this.estimateCost({ delay, compression, model }, metrics),
      expectedSuccessRate: Math.min(0.95, 0.93 - context.compressionLevel * 0.005),
      risks: ['响应速度快但错误率高', '成本较高'],
      benefits: ['响应最快', '处理能力最强', '适合紧急场景']
    };
  }

  /**
   * 创建平衡型策略
   */
  createBalancedStrategy(metrics, context, constraints) {
    return {
      id: this.genId(StrategyType.BALANCED),
      type: StrategyType.BALANCED,
      label: this.config.strategyTypes[StrategyType.BALANCED].label,
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

  /**
   * 创建探索型策略
   */
  createExploratoryStrategy(metrics, context, constraints) {
    return {
      id: this.genId(StrategyType.EXPLORATORY),
      type: StrategyType.EXPLORATORY,
      label: this.config.strategyTypes[StrategyType.EXPLORATORY].label,
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

  /**
   * 评估收益
   */
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

  /**
   * 评估风险
   */
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

  /**
   * 计算组合评分
   */
  calculateCombinedScore(strategy, metrics, context) {
    const benefit = this.evaluateBenefit(strategy, metrics, context);
    const risk = this.evaluateRisk(strategy, metrics, context);

    return (benefit.totalScore - risk.score * this.config.riskWeight) * this.config.benefitWeight;
  }

  /**
   * 选择最优策略
   */
  selectOptimalStrategy(evaluated, metrics, context) {
    // 创建带有约束检查的过滤列表
    const filtered = evaluated.filter(strategy => this.checkConstraints(strategy, context));

    if (filtered.length === 0) {
      console.warn('[CoreStrategyEngine] 没有策略满足约束条件，使用原始列表');
      return evaluated[0];
    }

    // 从满足约束的策略中选择最优
    const sorted = [...filtered].sort((a, b) => b.combinedScore - a.combinedScore);

    return sorted[0];
  }

  /**
   * 检查策略是否满足约束
   */
  checkConstraints(strategy, context) {
    const maxDelayConstraints = context.constraints?.maxDelay;
    const maxCostConstraints = context.budgetConstraints?.maxCost;

    // 检查延迟约束
    if (maxDelayConstraints !== undefined && strategy.delay > maxDelayConstraints) {
      return false;
    }

    // 检查成本约束
    if (maxCostConstraints !== undefined && strategy.estimatedCost > maxCostConstraints) {
      return false;
    }

    return true;
  }

  /**
   * 计算延迟
   */
  calculateDelay(pressure) {
    if (pressure < 0.4) return 300;
    if (pressure < 0.6) return 150;
    if (pressure < 0.8) return 50;
    return 0;
  }

  /**
   * 根据预算选择模型
   */
  selectModelByBudget(budgetRatio) {
    if (budgetRatio < 0.3) return 'CHEAP_ONLY';
    if (budgetRatio < 0.7) return 'MID_ONLY';
    if (budgetRatio < 0.9) return 'REDUCE_HIGH';
    return 'NORMAL';
  }

  /**
   * 估算成本
   */
  estimateCost(params, metrics) {
    let cost = params.delay * 0.1 + params.compression * 100;
    if (params.model === 'CHEAP_ONLY') cost *= 0.5;
    else if (params.model === 'MID_ONLY') cost *= 0.7;
    else if (params.model === 'REDUCE_HIGH') cost *= 0.85;
    return Math.round(cost * 10) / 10;
  }

  /**
   * 计算成本影响
   */
  calculateCostImpact(metrics) { return metrics.currentCost || 1000; }

  /**
   * 计算延迟影响
   */
  calculateDelayImpact(metrics) { return metrics.currentDelay || 200; }

  /**
   * 计算模型得分
   */
  calculateModelScore(model) {
    if (model === 'CHEAP_ONLY') return 70;
    if (model === 'MID_ONLY') return 85;
    if (model === 'REDUCE_HIGH') return 90;
    return 95;
  }

  /**
   * 计算模型风险
   */
  calculateModelRisk(model) {
    if (model === 'CHEAP_ONLY') return 20;
    if (model === 'MID_ONLY') return 10;
    if (model === 'REDUCE_HIGH') return 15;
    return 5;
  }

  /**
   * 生成唯一ID
   */
  genId(type) { return `${type}_${Date.now()}_${Math.floor(Math.random() * 1000)}`; }

  /**
   * 评估总体压力
   */
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

  /**
   * 评估速率压力
   */
  evaluateRatePressure(metrics) {
    const p = (metrics.callsLastMinute || 0) / 100;
    return {
      pressure: Math.round(p * 100) / 100,
      delay: p > 0.9 ? 800 : p > 0.7 ? 400 : p > 0.4 ? 150 : 0,
      level: p > 0.9 ? 'CRITICAL' : p > 0.7 ? 'HIGH' : p > 0.4 ? 'MEDIUM' : 'NORMAL'
    };
  }

  /**
   * 评估上下文压力
   */
  evaluateContextPressure(context) {
    const r = context.remainingTokens / context.maxTokens;
    let comp = 0;
    if (r < 0.25) comp = 2;
    if (r < 0.15) comp = 3;
    return { remainingRatio: Math.round(r * 100) / 100, compressionLevel: comp };
  }

  /**
   * 评估预算压力
   */
  evaluateBudgetPressure(metrics) {
    const hoursLeft = metrics.remainingBudget / metrics.dailyBudget;
    if (hoursLeft < 0.125) return { hoursLeft: Math.round(hoursLeft * 10) / 10, modelBias: 'CHEAP_ONLY', level: 'CRITICAL' };
    if (hoursLeft < 0.25) return { hoursLeft: Math.round(hoursLeft * 10) / 10, modelBias: 'MID_ONLY', level: 'HIGH' };
    if (hoursLeft < 0.5) return { hoursLeft: Math.round(hoursLeft * 10) / 10, modelBias: 'REDUCE_HIGH', level: 'MEDIUM' };
    return { hoursLeft: Math.round(hoursLeft * 10) / 10, modelBias: 'NORMAL', level: 'NORMAL' };
  }

  /**
   * 记录学习数据
   */
  recordLearning(selected, all, metrics, context) {
    const key = `strategy_${selected.type}_${selected.id}`;
    this.learnings.set(key, {
      strategy: selected,
      allStrategies: all,
      metrics: {
        ...metrics,
        timestamp: new Date().toISOString()
      },
      context: {
        ...context,
        timestamp: new Date().toISOString()
      },
      selectionReason: this.generateSelectionReason(selected, all)
    });
  }

  /**
   * 生成选择理由
   */
  generateSelectionReason(selected, all) {
    const reasons = [];

    reasons.push(`选择 ${selected.label} 策略，组合得分 ${selected.combinedScore.toFixed(2)}`);
    reasons.push(`收益得分: ${selected.benefit.totalScore.toFixed(2)}，风险得分: ${selected.risk.score.toFixed(2)}`);

    if (selected.risk.level !== 'LOW') {
      reasons.push(`⚠️ 风险等级: ${selected.risk.level}`);
    }

    return reasons.join('; ');
  }

  /**
   * 获取所有学习数据
   */
  getAllLearnings() {
    return Array.from(this.learnings.values());
  }

  /**
   * 清空学习数据
   */
  clearLearnings() {
    this.learnings.clear();
    this.saveLearnings();
  }
}

module.exports = {
  CoreStrategyEngine,
  StrategyType,
  STRATEGY_TYPES
};
