/**
 * OpenClaw 3.3 - 成本计算器（Cost Calculator）
 * 计算Token成本、时间成本、资源成本、风险成本
 * 
 * @version 3.3.0
 * @author OpenClaw V3.3
 * @date 2026-02-22
 */

class CostCalculator {
  constructor(config) {
    this.name = 'CostCalculator';
    this.config = config;
    
    // Token价格配置（简化）
    this.tokenPrices = {
      'GLM-4': {
        cheap: 0.0001,  // 每1000 tokens
        mid: 0.0002,
        high: 0.0003
      },
      'GPT-4': {
        cheap: 0.0005,
        mid: 0.001,
        high: 0.002
      }
    };
    
    // 时间成本配置（简化）
    this.timeCostConfig = {
      perMs: 0.001,  // 每毫秒成本
      priorityMultiplier: {
        'HIGH': 2.0,
        'MEDIUM': 1.0,
        'LOW': 0.5
      }
    };
    
    // 资源成本配置
    this.resourceCostConfig = {
      cpuPer100ms: 0.01,
      memoryPerMB: 0.0001,
      networkPerByte: 0.00001
    };
    
    console.log('💰 CostCalculator 初始化完成\n');
  }

  /**
   * 计算总成本
   * @param {Object} scenario - 场景对象
   * @param {Object} context - 决策上下文
   * @returns {Object} 成本明细
   */
  calculateTotalCost(scenario, context) {
    console.log(`\n💰 计算场景成本: ${scenario.name}`);

    // 1. Token成本
    const tokenCost = this.calculateTokenCost(scenario, context);

    // 2. 时间成本
    const timeCost = this.calculateTimeCost(scenario, context);

    // 3. 资源成本
    const resourceCost = this.calculateResourceCost(scenario, context);

    // 4. 风险成本
    const riskCost = this.calculateRiskCost(scenario, context);

    // 总成本
    const totalCost = tokenCost + timeCost + resourceCost + riskCost;

    console.log(`   Token成本: ${tokenCost.toFixed(2)}`);
    console.log(`   时间成本: ${timeCost.toFixed(2)}`);
    console.log(`   资源成本: ${resourceCost.toFixed(2)}`);
    console.log(`   风险成本: ${riskCost.toFixed(2)}`);
    console.log(`   总成本: ${totalCost.toFixed(2)}`);

    return {
      tokenCost,
      timeCost,
      resourceCost,
      riskCost,
      totalCost
    };
  }

  /**
   * 计算Token成本
   * @param {Object} scenario - 场景对象
   * @param {Object} context - 决策上下文
   * @returns {Number} Token成本
   */
  calculateTokenCost(scenario, context) {
    const parameters = scenario.parameters;
    
    // 基础成本
    let baseCost = parameters.tokenBudget;

    // 根据策略类型调整
    const typeMultiplier = {
      'FAST_RESPONSE': 0.8,
      'BALANCED': 1.0,
      'AGGRESSIVE': 1.3,
      'CONSERVATIVE': 0.6,
      'ADAPTIVE': 1.1
    };
    const multiplier = typeMultiplier[scenario.strategyType] || 1.0;

    // 添加随机波动
    const randomFactor = 0.9 + Math.random() * 0.2;

    const cost = baseCost * multiplier * randomFactor;

    return cost;
  }

  /**
   * 计算时间成本
   * @param {Object} scenario - 场景对象
   * @param {Object} context - 决策上下文
   * @returns {Number} 时间成本
   */
  calculateTimeCost(scenario, context) {
    // 简化计算：基于运行时间
    const runTime = scenario.details?.runTime || 300; // 默认300ms
    const priorityMultiplier = this.timeCostConfig.priorityMultiplier[context.priority || 'MEDIUM'] || 1.0;
    const cost = runTime * this.timeCostConfig.perMs * priorityMultiplier;

    return cost;
  }

  /**
   * 计算资源成本
   * @param {Object} scenario - 场景对象
   * @param {Object} context - 决策上下文
   * @returns {Number} 资源成本
   */
  calculateResourceCost(scenario, context) {
    // 简化计算：基于复杂度
    const complexityCosts = {
      'LOW': 10,
      'MEDIUM': 20,
      'HIGH': 40
    };
    const baseCost = complexityCosts[scenario.parameters.complexityLevel] || 20;

    // 添加随机波动
    const randomFactor = 0.9 + Math.random() * 0.2;

    return baseCost * randomFactor;
  }

  /**
   * 计算风险成本
   * @param {Object} scenario - 场景对象
   * @param {Object} context - 决策上下文
   * @returns {Number} 风险成本
   */
  calculateRiskCost(scenario, context) {
    const riskScore = scenario.riskScore || 0.5; // 默认0.5
    const riskMultiplier = 1 + riskScore * 2; // 风险成本 = 基础成本 * (1 + 2*risk)

    // 基础风险成本
    const baseRiskCost = 50; // 基础风险成本

    return baseRiskCost * riskMultiplier;
  }

  /**
   * 估算成本（简化版）
   * @param {Object} scenario - 场景对象
   * @returns {Number} 估算成本
   */
  estimateCost(scenario) {
    // 简化估算：基于Token预算
    return scenario.parameters.tokenBudget * 0.1; // 估算为Token预算的10%
  }

  /**
   * 成本预算检查
   * @param {Object} scenario - 场景对象
   * @param {Number} budget - 预算
   * @returns {Object} 检查结果
   */
  checkBudget(scenario, budget) {
    const cost = this.estimateCost(scenario);
    const withinBudget = cost <= budget;
    const percentage = (cost / budget) * 100;

    return {
      withinBudget,
      cost,
      budget,
      percentage: percentage.toFixed(2) + '%'
    };
  }

  /**
   * 获取系统状态
   * @returns {Object} 系统状态
   */
  getStatus() {
    return {
      name: this.name,
      config: this.config,
      capabilities: ['Token成本', '时间成本', '资源成本', '风险成本', '总成本']
    };
  }
}

module.exports = CostCalculator;
