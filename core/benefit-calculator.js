/**
 * OpenClaw 3.3 - 收益计算器（Benefit Calculator）
 * 计算成功率收益、效率收益、用户满意度收益、长期收益
 * 
 * @version 3.3.0
 * @author OpenClaw V3.3
 * @date 2026-02-22
 */

class BenefitCalculator {
  constructor(config) {
    this.name = 'BenefitCalculator';
    this.config = config;
    
    // 收益权重配置
    this.benefitWeights = config.benefitWeight || {
      success: 0.35,
      efficiency: 0.25,
      satisfaction: 0.2,
      longTerm: 0.2
    };
    
    // 用户满意度基准
    this.satisfactionBenchmarks = {
      'LOW': 40,
      'MEDIUM': 60,
      'HIGH': 80
    };
    
    // 长期收益配置
    this.longTermMultiplier = {
      'FAST_RESPONSE': 0.8,
      'BALANCED': 1.0,
      'AGGRESSIVE': 1.2,
      'CONSERVATIVE': 1.3,
      'ADAPTIVE': 1.1
    };
    
    console.log('📈 BenefitCalculator 初始化完成\n');
  }

  /**
   * 计算总收益
   * @param {Object} scenario - 场景对象
   * @param {Object} context - 决策上下文
   * @returns {Object} 收益明细
   */
  calculateTotalBenefit(scenario, context) {
    console.log(`\n📈 计算场景收益: ${scenario.name}`);

    // 1. 成功率收益
    const successBenefit = this.calculateSuccessBenefit(scenario, context);

    // 2. 效率收益
    const efficiencyBenefit = this.calculateEfficiencyBenefit(scenario, context);

    // 3. 用户满意度收益
    const satisfactionBenefit = this.calculateSatisfactionBenefit(scenario, context);

    // 4. 长期收益
    const longTermBenefit = this.calculateLongTermBenefit(scenario, context);

    // 总收益
    const totalBenefit = successBenefit + efficiencyBenefit + satisfactionBenefit + longTermBenefit;

    console.log(`   成功率收益: ${successBenefit.toFixed(2)}`);
    console.log(`   效率收益: ${efficiencyBenefit.toFixed(2)}`);
    console.log(`   用户满意度收益: ${satisfactionBenefit.toFixed(2)}`);
    console.log(`   长期收益: ${longTermBenefit.toFixed(2)}`);
    console.log(`   总收益: ${totalBenefit.toFixed(2)}`);

    return {
      successBenefit,
      efficiencyBenefit,
      satisfactionBenefit,
      longTermBenefit,
      totalBenefit
    };
  }

  /**
   * 计算成功率收益
   * @param {Object} scenario - 场景对象
   * @param {Object} context - 决策上下文
   * @returns {Number} 成功率收益
   */
  calculateSuccessBenefit(scenario, context) {
    // 基础成功率
    const baseSuccessRate = {
      'FAST_RESPONSE': 0.85,
      'BALANCED': 0.90,
      'AGGRESSIVE': 0.95,
      'CONSERVATIVE': 0.88,
      'ADAPTIVE': 0.92
    };
    const successRate = baseSuccessRate[scenario.strategyType] || 0.90;

    // 根据上下文调整
    let contextMultiplier = 1.0;

    if (context.successRate === 'HIGH') {
      contextMultiplier *= 1.1;
    } else if (context.successRate === 'LOW') {
      contextMultiplier *= 0.9;
    }

    // 添加随机波动
    const randomFactor = 0.9 + Math.random() * 0.2;

    // 收益 = 成功率 × 权重 × 100
    const benefit = successRate * 100 * contextMultiplier * randomFactor;

    return benefit;
  }

  /**
   * 计算效率收益
   * @param {Object} scenario - 场景对象
   * @param {Object} context - 决策上下文
   * @returns {Number} 效率收益
   */
  calculateEfficiencyBenefit(scenario, context) {
    // 基础效率评分
    const baseEfficiency = {
      'FAST_RESPONSE': 70,
      'BALANCED': 80,
      'AGGRESSIVE': 85,
      'CONSERVATIVE': 75,
      'ADAPTIVE': 82
    };
    const efficiency = baseEfficiency[scenario.strategyType] || 80;

    // 根据上下文调整
    let contextMultiplier = 1.0;

    if (context.efficiency === 'HIGH') {
      contextMultiplier *= 1.15;
    } else if (context.efficiency === 'LOW') {
      contextMultiplier *= 0.85;
    }

    // 添加随机波动
    const randomFactor = 0.9 + Math.random() * 0.2;

    // 收益 = 效率 × 权重 × 100
    const benefit = efficiency * contextMultiplier * randomFactor;

    return benefit;
  }

  /**
   * 计算用户满意度收益
   * @param {Object} scenario - 场景对象
   * @param {Object} context - 决策上下文
   * @returns {Number} 用户满意度收益
   */
  calculateSatisfactionBenefit(scenario, context) {
    // 基础满意度
    const baseSatisfaction = this.satisfactionBenchmarks[scenario.parameters.riskLevel] || 60;

    // 根据策略类型调整
    const typeMultiplier = {
      'FAST_RESPONSE': 0.9,
      'BALANCED': 1.0,
      'AGGRESSIVE': 0.95,
      'CONSERVATIVE': 1.05,
      'ADAPTIVE': 1.0
    };
    const multiplier = typeMultiplier[scenario.strategyType] || 1.0;

    // 添加随机波动
    const randomFactor = 0.9 + Math.random() * 0.2;

    // 收益 = 满意度 × 权重 × 100
    const benefit = baseSatisfaction * multiplier * randomFactor;

    return benefit;
  }

  /**
   * 计算长期收益
   * @param {Object} scenario - 场景对象
   * @param {Object} context - 决策上下文
   * @returns {Number} 长期收益
   */
  calculateLongTermBenefit(scenario, context) {
    // 基础长期收益
    const baseLongTerm = {
      'FAST_RESPONSE': 50,
      'BALANCED': 70,
      'AGGRESSIVE': 80,
      'CONSERVATIVE': 60,
      'ADAPTIVE': 75
    };
    const longTerm = baseLongTerm[scenario.strategyType] || 70;

    // 根据策略类型调整
    const typeMultiplier = this.longTermMultiplier[scenario.strategyType] || 1.0;

    // 根据上下文调整
    let contextMultiplier = 1.0;

    if (context.longTerm === 'HIGH') {
      contextMultiplier *= 1.2;
    } else if (context.longTerm === 'LOW') {
      contextMultiplier *= 0.8;
    }

    // 添加随机波动
    const randomFactor = 0.9 + Math.random() * 0.2;

    // 收益 = 长期收益 × 权重 × 100
    const benefit = longTerm * contextMultiplier * randomFactor;

    return benefit;
  }

  /**
   * 收益分析
   * @param {Object} scenario - 场景对象
   * @param {Object} context - 决策上下文
   * @returns {Object} 收益分析结果
   */
  analyzeBenefit(scenario, context) {
    const benefits = this.calculateTotalBenefit(scenario, context);
    
    // 计算各项收益占比
    const total = benefits.totalBenefit;
    const analysis = {
      ...benefits,
      breakdown: {
        success: (benefits.successBenefit / total * 100).toFixed(2) + '%',
        efficiency: (benefits.efficiencyBenefit / total * 100).toFixed(2) + '%',
        satisfaction: (benefits.satisfactionBenefit / total * 100).toFixed(2) + '%',
        longTerm: (benefits.longTermBenefit / total * 100).toFixed(2) + '%'
      }
    };

    return analysis;
  }

  /**
   * 获取系统状态
   * @returns {Object} 系统状态
   */
  getStatus() {
    return {
      name: this.name,
      config: this.config,
      capabilities: ['成功率收益', '效率收益', '用户满意度收益', '长期收益', '收益分析']
    };
  }
}

module.exports = BenefitCalculator;
