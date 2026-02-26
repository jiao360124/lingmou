/**
 * OpenClaw V3.2 - Cost-Benefit Scorer
 * 策略引擎核心模块：成本收益评分器
 *
 * 功能：
 * - 计算每个策略的 ROI
 * - 分析 Token 成本 vs 质量收益
 * - 量化决策价值
 *
 * @author OpenClaw V3.2
 * @date 2026-02-21
 */

class CostBenefitScorer {
  constructor() {
    this.name = 'CostBenefitScorer';
    this.tokenCost = 0.0003; // $0.0003 per token (GPT-4 level)
    this.qualityWeight = 0.4; // 质量 40%
    this.successWeight = 0.3; // 成功率 30%
    this.efficiencyWeight = 0.3; // 效率 30%
  }

  /**
   * 评分策略
   * @param {Object} params
   * @returns {Promise<StrategyScore>}
   */
  async score(params) {
    const { strategy, context } = params;

    console.log(`[CostBenefitScorer] 评分策略: ${strategy.name}`);

    // 1. 计算成本
    const cost = await this.calculateCost(strategy, context);

    // 2. 计算收益
    const benefit = await this.calculateBenefit(strategy, context);

    // 3. 计算ROI
    const roi = this.calculateROI(cost, benefit);

    // 4. 计算风险调整
    const riskScore = await this.calculateRiskScore(strategy, context);

    // 5. 计算最终得分
    const finalScore = this.computeFinalScore(roi, riskScore, benefit.weight);

    return {
      strategyName: strategy.name,
      description: strategy.description || '',
      cost,
      benefit,
      roi,
      riskScore,
      finalScore,
      details: {
        quality: benefit.value / (cost.value + 1), // 避免除以0
        successRate: context.successRate || 0.85,
        userSatisfaction: context.userSatisfaction || 0.88
      },
      timestamp: new Date()
    };
  }

  /**
   * 计算成本
   */
  async calculateCost(strategy, context) {
    const baseCost = strategy.tokensConsumed || 5000;
    const qualityPenalty = this.calculateQualityPenalty(strategy);
    const executionCost = this.calculateExecutionCost(strategy);

    const totalCost = baseCost + qualityPenalty + executionCost;

    // 计算 Token 成本
    const tokenCost = baseCost * this.tokenCost;

    // 计算质量惩罚成本
    const penaltyCost = qualityPenalty * this.tokenCost;

    // 计算执行成本（时间成本）
    const timeCost = executionCost * 0.0001; // 假设每毫秒 $0.0001

    return {
      value: totalCost,
      tokenCost,
      qualityPenaltyCost: penaltyCost,
      executionCost: timeCost,
      totalTokens: baseCost,
      totalExecutionTime: executionCost,
      totalCostUsd: tokenCost + penaltyCost + timeCost,
      breakdown: {
        baseTokens: baseCost,
        qualityPenalty: qualityPenalty,
        executionTime: executionCost
      }
    };
  }

  /**
   * 计算质量惩罚
   */
  calculateQualityPenalty(strategy) {
    // 质量惩罚 = 基础成本 * (1 - 质量)
    const baseTokens = strategy.tokensConsumed || 5000;
    const quality = strategy.quality || 0.9;

    return baseTokens * (1 - quality);
  }

  /**
   * 计算执行成本
   */
  calculateExecutionCost(strategy) {
    // 执行成本 = 执行时间
    return strategy.executionTime || 100;
  }

  /**
   * 计算收益
   */
  async calculateBenefit(strategy, context) {
    const qualityGain = this.calculateQualityGain(strategy);
    const successGain = this.calculateSuccessGain(strategy, context);
    const satisfactionGain = this.calculateSatisfactionGain(strategy);

    const totalBenefit = qualityGain + successGain + satisfactionGain;

    // 计算 ROI = 收益 / 成本
    const cost = await this.calculateCost(strategy, context);
    const roi = cost.totalTokens > 0 ? totalBenefit / cost.totalTokens : 0;

    return {
      value: totalBenefit,
      roi,
      breakdown: {
        quality: qualityGain,
        successRate: successGain,
        userSatisfaction: satisfactionGain
      },
      weight: strategy.weight || 1.0
    };
  }

  /**
   * 计算质量增益
   */
  calculateQualityGain(strategy) {
    // 质量增益 = 基础质量 * 100
    const baseQuality = strategy.quality || 0.9;

    // 如果有质量提升
    const improvement = strategy.qualityImprovement || 0;

    return (baseQuality + improvement) * 100;
  }

  /**
   * 计算成功率增益
   */
  calculateSuccessGain(strategy, context) {
    // 成功率增益 = (新成功率 - 旧成功率) * 100
    const newSuccessRate = strategy.successRate || 0.9;
    const oldSuccessRate = context.successRate || 0.85;

    return (newSuccessRate - oldSuccessRate) * 100;
  }

  /**
   * 计算满意度增益
   */
  calculateSatisfactionGain(strategy) {
    // 满意度增益 = 满意度 * 50
    const satisfaction = strategy.userSatisfaction || 0.88;

    return satisfaction * 50;
  }

  /**
   * 计算 ROI
   */
  calculateROI(cost, benefit) {
    // ROI = 收益值 / 成本值
    return cost.value > 0 ? benefit.value / cost.value : 0;
  }

  /**
   * 计算风险评分
   */
  async calculateRiskScore(strategy, context) {
    // 风险评分 = 基础风险 + 复杂度风险 + 历史风险
    let riskScore = 0.1; // 基础风险

    // 复杂度风险
    riskScore += strategy.complexity * 0.2 || 0;

    // 历史风险
    riskScore += (1 - (strategy.historySuccessRate || 0.85)) * 0.2;

    // Token 消耗风险
    if (strategy.tokensConsumed > 100000) {
      riskScore += 0.15;
    }

    // 限制在 0-1 之间
    riskScore = Math.max(0, Math.min(1, riskScore));

    return {
      riskScore,
      riskLevel: this.getRiskLevel(riskScore),
      breakdown: {
        complexity: strategy.complexity || 0.1,
        history: strategy.historySuccessRate || 0.85,
        tokenUsage: strategy.tokensConsumed > 100000
      }
    };
  }

  /**
   * 获取风险等级
   */
  getRiskLevel(riskScore) {
    if (riskScore < 0.2) return 'LOW';
    if (riskScore < 0.4) return 'MEDIUM';
    if (riskScore < 0.6) return 'HIGH';
    return 'CRITICAL';
  }

  /**
   * 计算最终得分
   */
  computeFinalScore(roi, riskScore, benefitWeight) {
    // 最终得分 = ROI * 质量权重 * (1 - 风险权重) * 满意度调整
    const qualityScore = this.qualityWeight;
    const efficiencyScore = this.efficiencyWeight;
    const successScore = this.successWeight;

    // ROI 已经包含了质量，这里简化计算
    const qualityPart = qualityScore * (roi * 100);
    const efficiencyPart = efficiencyScore * (1 / (roi * 100 + 1));
    const successPart = successScore * benefitWeight;

    return qualityPart + efficiencyPart + successPart;
  }

  /**
   * 批量评分
   * @param {Array<Object>} strategies - 策略列表
   * @param {Object} context - 上下文
   * @returns {Promise<Array<StrategyScore>>}
   */
  async batchScore(strategies, context) {
    console.log(`[CostBenefitScorer] 批量评分 ${strategies.length} 个策略`);

    const scores = [];

    for (const strategy of strategies) {
      const score = await this.score({ strategy, context });
      scores.push(score);

      // 延迟避免阻塞
      await new Promise(resolve => setTimeout(resolve, 5));
    }

    return scores;
  }

  /**
   * 获取最优策略
   * @param {Array<StrategyScore>} scores
   * @returns {Object|null}
   */
  getBestStrategy(scores) {
    if (scores.length === 0) return null;

    return scores.reduce((best, current) => {
      const riskLevel = current.riskProfile?.riskLevel || 'LOW';
      const bestRiskLevel = best.riskProfile?.riskLevel || 'LOW';

      // 优先选择风险等级低的策略
      if (riskLevel !== bestRiskLevel) {
        return riskLevel < bestRiskLevel ? current : best;
      }

      // 风险等级相同，选择得分高的
      return current.finalScore > best.finalScore ? current : best;
    });
  }

  /**
   * 获取最差策略
   * @param {Array<StrategyScore>} scores
   * @returns {Object|null}
   */
  getWorstStrategy(scores) {
    if (scores.length === 0) return null;

    return scores.reduce((worst, current) => {
      return current.finalScore < worst.finalScore ? current : worst;
    });
  }
}

module.exports = CostBenefitScorer;
