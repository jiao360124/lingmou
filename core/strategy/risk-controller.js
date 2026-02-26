/**
 * OpenClaw 3.3 - 风险控制器（Risk Controller）
 * 控制策略风险
 * 
 * @version 3.3.0
 * @author OpenClaw V3.3
 * @date 2026-02-22
 */

class RiskController {
  constructor(config) {
    this.name = 'RiskController';
    this.config = config;
    console.log('🛡️  RiskController 初始化完成\n');
  }

  /**
   * 控制风险
   * @param {Object} scenario - 场景对象
   * @param {Object} riskAssessment - 风险评估结果
   * @param {Object} context - 决策上下文
   * @returns {Object} 风险控制结果
   */
  controlRisk(scenario, riskAssessment, context) {
    const riskScore = riskAssessment.riskScore || 0.5;
    const riskLevel = this.config.riskControls?.maxRiskLevel || 'MEDIUM';

    // 如果风险超过阈值，需要控制
    if (riskScore > 0.7) {
      const method = this.selectRiskControlMethod(riskLevel);

      return {
        method: method,
        riskScore: riskScore,
        riskLevel: riskLevel,
        details: `风险${method} - 风险评分: ${riskScore.toFixed(3)}`,
        actionRequired: true
      };
    }

    // 风险在可控范围内
    return {
      method: 'MONITOR',
      riskScore: riskScore,
      riskLevel: riskLevel,
      details: `风险监控中 - 风险评分: ${riskScore.toFixed(3)}`,
      actionRequired: false
    };
  }

  /**
   * 选择风险控制方法
   * @param {String} maxRiskLevel - 最大允许风险等级
   * @returns {String} 控制方法
   */
  selectRiskControlMethod(maxRiskLevel) {
    const methods = {
      'LOW': 'ACCEPT',
      'MEDIUM': 'MITIGATE',
      'HIGH': 'AVOID'
    };
    return methods[maxRiskLevel] || 'MITIGATE';
  }

  /**
   * 获取系统状态
   * @returns {Object} 系统状态
   */
  getStatus() {
    return {
      name: this.name,
      config: this.config,
      capabilities: ['风险控制', '风险缓解']
    };
  }
}

module.exports = RiskController;
