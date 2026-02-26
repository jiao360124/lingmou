/**
 * OpenClaw 3.3 - 风险调整评分器（Risk-Adjusted Scorer）
 * 计算风险调整后的分数
 * 
 * @version 3.3.0
 * @author OpenClaw V3.3
 * @date 2026-02-22
 */

class RiskAdjustedScorer {
  constructor(config) {
    this.name = 'RiskAdjustedScorer';
    this.config = config;
    console.log('⚖️  RiskAdjustedScorer 初始化完成\n');
  }

  /**
   * 计算风险调整后分数
   * @param {Object} scenario - 场景对象
   * @param {Object} riskAssessment - 风险评估结果
   * @returns {Number} 风险调整后分数
   */
  calculateRiskAdjustedScore(scenario, riskAssessment) {
    const baseScore = scenario.priorityScore || 0;
    const riskScore = riskAssessment.riskScore || 0.5;

    // 风险调整：风险越高，分数越低
    const riskAdjustment = 1 - (riskScore * 0.5); // 最多降低50%

    const riskAdjustedScore = baseScore * riskAdjustment;

    return riskAdjustedScore;
  }

  /**
   * 获取系统状态
   * @returns {Object} 系统状态
   */
  getStatus() {
    return {
      name: this.name,
      config: this.config,
      capabilities: ['风险调整评分', '风险调整计算']
    };
  }
}

module.exports = RiskAdjustedScorer;
