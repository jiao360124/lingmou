/**
 * OpenClaw V3.2 - Risk Weight Model
 * 策略引擎核心模块：风险权重模型
 *
 * 功能：
 * - 评估每个策略的风险
 * - 生成风险调整系数
 * - 提供风险缓解建议
 *
 * @author OpenClaw V3.2
 * @date 2026-02-21
 */

class RiskWeightModel {
  constructor() {
    this.name = 'RiskWeightModel';
  }

  /**
   * 评估风险
   * @param {Object} params
   * @returns {Promise<RiskProfile>}
   */
  async assessRisk(params) {
    const { strategy, context } = params;

    console.log(`[RiskWeightModel] 评估策略: ${strategy.name}`);

    // 1. 评估技术风险
    const technicalRisk = await this.assessTechnicalRisk(strategy, context);

    // 2. 评估业务风险
    const businessRisk = await this.assessBusinessRisk(strategy, context);

    // 3. 评估用户风险
    const userRisk = await this.assessUserRisk(strategy, context);

    // 4. 综合风险评估
    const combinedRisk = this.combineRisks([technicalRisk, businessRisk, userRisk]);

    // 5. 生成缓解建议
    const mitigation = this.generateMitigation(strategy, combinedRisk);

    return {
      riskLevel: this.determineRiskLevel(combinedRisk.riskScore),
      probability: combinedRisk.probability,
      impact: combinedRisk.impact,
      riskScore: combinedRisk.riskScore,
      breakdown: [technicalRisk, businessRisk, userRisk],
      mitigation,
      weight: this.calculateRiskWeight(combinedRisk.riskScore),
      adjustedScore: combinedRisk.riskScore * this.calculateRiskWeight(combinedRisk.riskScore),
      timestamp: new Date()
    };
  }

  /**
   * 评估技术风险
   */
  async assessTechnicalRisk(strategy, context) {
    let probability = 0.1;
    let impact = 0.1;

    // 检查策略复杂度
    if (strategy.complexity > 0.7) {
      probability += 0.3;
      impact += 0.2;
      console.log(`[RiskWeightModel] 策略复杂度较高: ${strategy.complexity}`);
    }

    // 检查是否依赖未知模块
    if (strategy.hasUnresolvedDependencies) {
      probability += 0.4;
      impact += 0.3;
      console.log(`[RiskWeightModel] 存在未解析依赖`);
    }

    // 检查历史成功率
    if (strategy.historySuccessRate < 0.7) {
      probability += 0.2;
      impact += 0.2;
      console.log(`[RiskWeightModel] 历史成功率较低: ${strategy.historySuccessRate}`);
    }

    return {
      category: 'technical',
      probability,
      impact,
      description: '技术实现风险',
      factors: this.extractTechnicalFactors(strategy)
    };
  }

  /**
   * 提取技术风险因素
   */
  extractTechnicalFactors(strategy) {
    const factors = [];

    if (strategy.complexity > 0.7) {
      factors.push('高复杂度');
    }

    if (strategy.hasUnresolvedDependencies) {
      factors.push('未解析依赖');
    }

    if (strategy.historySuccessRate < 0.7) {
      factors.push('历史失败率高');
    }

    return factors;
  }

  /**
   * 评估业务风险
   */
  async assessBusinessRisk(strategy, context) {
    let probability = 0.1;
    let impact = 0.1;

    // 检查业务影响
    if (strategy.hasBusinessImpact) {
      probability += 0.3;
      impact += 0.4;
      console.log(`[RiskWeightModel] 策略有业务影响`);
    }

    // 检查业务流程依赖
    if (strategy.breaksBusinessFlow) {
      probability += 0.2;
      impact += 0.5;
      console.log(`[RiskWeightModel] 策略会中断业务流程`);
    }

    return {
      category: 'business',
      probability,
      impact,
      description: '业务流程风险',
      factors: this.extractBusinessFactors(strategy)
    };
  }

  /**
   * 提取业务风险因素
   */
  extractBusinessFactors(strategy) {
    const factors = [];

    if (strategy.hasBusinessImpact) {
      factors.push('有业务影响');
    }

    if (strategy.breaksBusinessFlow) {
      factors.push('中断业务流程');
    }

    if (strategy.requiresApproval) {
      factors.push('需要审批');
    }

    return factors;
  }

  /**
   * 评估用户风险
   */
  async assessUserRisk(strategy, context) {
    let probability = 0.1;
    let impact = 0.1;

    // 检查用户体验影响
    if (strategy.affectsUX) {
      probability += 0.2;
      impact += 0.3;
      console.log(`[RiskWeightModel] 策略影响用户体验`);
    }

    // 检查用户满意度影响
    if (strategy.decreasesSatisfaction) {
      probability += 0.1;
      impact += 0.4;
      console.log(`[RiskWeightModel] 策略会降低用户满意度`);
    }

    return {
      category: 'user',
      probability,
      impact,
      description: '用户体验风险',
      factors: this.extractUserFactors(strategy)
    };
  }

  /**
   * 提取用户风险因素
   */
  extractUserFactors(strategy) {
    const factors = [];

    if (strategy.affectsUX) {
      factors.push('影响用户体验');
    }

    if (strategy.decreasesSatisfaction) {
      factors.push('降低用户满意度');
    }

    if (strategy.delayExecution) {
      factors.push('延迟执行');
    }

    return factors;
  }

  /**
   * 综合风险评估
   */
  combineRisks(risks) {
    // 加权平均
    const weights = {
      technical: 0.4,
      business: 0.3,
      user: 0.3
    };

    const totalWeight = weights.technical + weights.business + weights.user;

    const probability = (
      risks[0].probability * weights.technical +
      risks[1].probability * weights.business +
      risks[2].probability * weights.user
    ) / totalWeight;

    const impact = (
      risks[0].impact * weights.technical +
      risks[1].impact * weights.business +
      risks[2].impact * weights.user
    ) / totalWeight;

    const riskScore = probability * impact;

    return {
      probability: Math.min(1, probability),
      impact: Math.min(1, impact),
      riskScore: Math.min(1, riskScore)
    };
  }

  /**
   * 确定风险等级
   */
  determineRiskLevel(riskScore) {
    if (riskScore < 0.2) return 'LOW';
    if (riskScore < 0.4) return 'MEDIUM';
    if (riskScore < 0.6) return 'HIGH';
    return 'CRITICAL';
  }

  /**
   * 计算风险权重系数
   */
  calculateRiskWeight(riskScore) {
    // 风险权重系数 = 1 - riskScore
    // 风险越低，权重越高
    return Math.max(0.2, 1 - riskScore);
  }

  /**
   * 生成缓解建议
   */
  generateMitigation(strategy, risk) {
    const recommendations = [];

    if (risk.riskLevel === 'CRITICAL' || risk.riskLevel === 'HIGH') {
      recommendations.push({
        priority: 'HIGH',
        action: '不要执行此策略',
        reason: '风险过高，可能造成严重影响'
      });
    }

    if (risk.riskLevel === 'HIGH' || risk.riskLevel === 'MEDIUM') {
      recommendations.push({
        priority: 'MEDIUM',
        action: '需要实施缓解措施',
        reason: '有一定风险，建议采取措施'
      });
    }

    if (risk.riskLevel === 'MEDIUM' || risk.riskLevel === 'LOW') {
      recommendations.push({
        priority: 'LOW',
        action: '保持监控',
        reason: '风险较低，建议继续监控'
      });
    }

    // 根据策略类型添加特定建议
    recommendations.push(...this.generateSpecificMitigation(strategy));

    return recommendations;
  }

  /**
   * 生成特定缓解建议
   */
  generateSpecificMitigation(strategy) {
    const recommendations = [];

    if (strategy.hasUnresolvedDependencies) {
      recommendations.push({
        priority: 'MEDIUM',
        action: '解决依赖问题后再执行',
        reason: '存在未解析的依赖，可能导致运行时错误'
      });
    }

    if (strategy.breaksBusinessFlow) {
      recommendations.push({
        priority: 'HIGH',
        action: '评估业务影响，准备回滚方案',
        reason: '此策略会中断业务流程，需要备用方案'
      });
    }

    if (strategy.affectsUX) {
      recommendations.push({
        priority: 'MEDIUM',
        action: '通知用户并收集反馈',
        reason: '策略会影响用户体验，需要透明沟通'
      });
    }

    return recommendations;
  }

  /**
   * 批量评估风险
   * @param {Array<Object>} strategies
   * @param {Object} context
   * @returns {Promise<Array<RiskProfile>>}
   */
  async batchAssessRisk(strategies, context) {
    console.log(`[RiskWeightModel] 批量评估 ${strategies.length} 个策略`);

    const riskProfiles = [];

    for (const strategy of strategies) {
      const profile = await this.assessRisk({ strategy, context });
      riskProfiles.push(profile);

      await new Promise(resolve => setTimeout(resolve, 5));
    }

    return riskProfiles;
  }

  /**
   * 获取低风险策略
   * @param {Array<RiskProfile>} riskProfiles
   * @returns {Array<RiskProfile>}
   */
  getLowRiskStrategies(riskProfiles) {
    return riskProfiles.filter(profile => profile.riskLevel === 'LOW');
  }

  /**
   * 获取高风险策略
   * @param {Array<RiskProfile>} riskProfiles
   * @returns {Array<RiskProfile>}
   */
  getHighRiskStrategies(riskProfiles) {
    return riskProfiles.filter(profile =>
      profile.riskLevel === 'HIGH' || profile.riskLevel === 'CRITICAL'
    );
  }
}

module.exports = RiskWeightModel;
