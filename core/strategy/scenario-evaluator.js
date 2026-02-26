/**
 * OpenClaw 3.3 - 场景评估器（Scenario Evaluator）
 * 评估成本收益和ROI
 * 
 * @version 3.3.0
 * @author OpenClaw V3.3
 * @date 2026-02-22
 */

class ScenarioEvaluator {
  constructor(config) {
    this.name = 'ScenarioEvaluator';
    this.config = config;
    
    console.log('📊 ScenarioEvaluator 初始化完成\n');
  }

  /**
   * 评估场景（成本收益分析）
   * @param {Array} scenarios - 场景数组
   * @param {Object} context - 决策上下文
   * @returns {Promise<Array>} 评估后的场景数组
   */
  async evaluateScenarios(scenarios, context) {
    console.log(`\n📊 评估 ${scenarios.length} 个场景...\n`);

    const evaluatedScenarios = [];

    for (const scenario of scenarios) {
      const evaluation = await this.evaluateScenario(scenario, context);
      evaluatedScenarios.push(evaluation);
    }

    return evaluatedScenarios;
  }

  /**
   * 评估单个场景
   * @param {Object} scenario - 场景对象
   * @param {Object} context - 决策上下文
   * @returns {Promise<Object>} 评估结果
   */
  async evaluateScenario(scenario, context) {
    console.log(`  📋 评估场景: ${scenario.name}`);

    // 1. 计算成本
    const cost = this.calculateCost(scenario, context);
    console.log(`     成本: ${cost.toFixed(2)}`);

    // 2. 计算收益
    const benefit = this.calculateBenefit(scenario, context);
    console.log(`     收益: ${benefit.toFixed(2)}`);

    // 3. 计算ROI
    const roi = this.calculateROI(cost, benefit);
    console.log(`     ROI: ${roi.toFixed(2)}`);

    // 4. 计算优先级分数
    const priorityScore = this.calculatePriorityScore(scenario, cost, benefit, roi);
    console.log(`     优先级分数: ${priorityScore.toFixed(2)}`);

    // 5. 风险评估
    const riskScore = this.assessRisk(scenario);
    console.log(`     风险分数: ${riskScore.toFixed(2)}`);

    // 6. 成本收益评分
    const costBenefitScore = this.calculateCostBenefitScore(scenario, cost, benefit);
    console.log(`     成本收益评分: ${costBenefitScore.toFixed(2)}`);

    console.log();

    return {
      ...scenario,
      cost,
      benefit,
      roi,
      priorityScore,
      riskScore,
      costBenefitScore,
      evaluationDetails: {
        calculatedAt: Date.now(),
        method: 'COST_BENEFIT_ANALYSIS'
      }
    };
  }

  /**
   * 计算成本
   * @param {Object} scenario - 场景对象
   * @param {Object} context - 决策上下文
   * @returns {Number} 成本
   */
  calculateCost(scenario, context) {
    // 简化计算：基于Token预算和运行时间
    const parameters = scenario.parameters;
    const baseCost = parameters.tokenBudget;

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

    return baseCost * multiplier * randomFactor;
  }

  /**
   * 计算收益
   * @param {Object} scenario - 场景对象
   * @param {Object} context - 决策上下文
   * @returns {Number} 收益（0-100）
   */
  calculateBenefit(scenario, context) {
    // 简化计算：基于策略类型和历史数据
    const baseBenefits = {
      'FAST_RESPONSE': 60,
      'BALANCED': 80,
      'AGGRESSIVE': 95,
      'CONSERVATIVE': 70,
      'ADAPTIVE': 85
    };
    const baseBenefit = baseBenefits[scenario.strategyType] || 80;

    // 根据上下文调整
    let contextMultiplier = 1.0;

    // 检查紧急程度
    if (context.urgency === 'HIGH') {
      contextMultiplier *= 1.2;
    } else if (context.urgency === 'LOW') {
      contextMultiplier *= 0.8;
    }

    // 添加随机波动
    const randomFactor = 0.85 + Math.random() * 0.3;

    return baseBenefit * contextMultiplier * randomFactor;
  }

  /**
   * 计算ROI
   * @param {Number} cost - 成本
   * @param {Number} benefit - 收益
   * @returns {Number} ROI
   */
  calculateROI(cost, benefit) {
    if (cost === 0) return 0;
    return (benefit / cost) * 100;
  }

  /**
   * 计算优先级分数
   * @param {Object} scenario - 场景对象
   * @param {Number} cost - 成本
   * @param {Number} benefit - 收益
   * @param {Number} roi - ROI
   * @returns {Number} 优先级分数
   */
  calculatePriorityScore(scenario, cost, benefit, roi) {
    // 基于ROI和成本收益评分
    const roiWeight = 0.6;
    const costBenefitWeight = 0.4;

    const roiScore = this.normalizeScore(roi, 0, 100);
    const costBenefitScore = scenario.costBenefitScore || 0;

    const priorityScore = roiScore * roiWeight + costBenefitScore * costBenefitWeight;

    return priorityScore;
  }

  /**
   * 风险评估
   * @param {Object} scenario - 场景对象
   * @returns {Number} 风险分数（0-1）
   */
  assessRisk(scenario) {
    // 简化评估：基于策略类型
    const riskLevels = {
      'LOW': 0.3,
      'MEDIUM': 0.5,
      'HIGH': 0.8
    };
    const riskLevel = scenario.parameters.riskLevel || 'MEDIUM';
    
    // 添加随机波动
    const randomFactor = 0.9 + Math.random() * 0.2;

    return riskLevels[riskLevel] * randomFactor;
  }

  /**
   * 计算成本收益评分
   * @param {Object} scenario - 场景对象
   * @param {Number} cost - 成本
   * @param {Number} benefit - 收益
   * @returns {Number} 成本收益评分（0-100）
   */
  calculateCostBenefitScore(scenario, cost, benefit) {
    // 简化计算：基于ROI和风险
    const roi = scenario.roi || 0;
    const risk = scenario.riskScore || 0;

    const roiScore = this.normalizeScore(roi, 0, 100);
    const riskScore = (1 - risk) * 100; // 风险越低，分数越高

    const roiWeight = 0.7;
    const riskWeight = 0.3;

    const score = roiScore * roiWeight + riskScore * riskWeight;

    return Math.min(100, Math.max(0, score));
  }

  /**
   * 标准化分数
   * @param {Number} value - 值
   * @param {Number} min - 最小值
   * @param {Number} max - 最大值
   * @returns {Number} 标准化分数（0-1）
   */
  normalizeScore(value, min, max) {
    const normalized = (value - min) / (max - min);
    return Math.min(1, Math.max(0, normalized));
  }

  /**
   * 获取系统状态
   * @returns {Object} 系统状态
   */
  getStatus() {
    return {
      name: this.name,
      config: this.config,
      capabilities: ['成本计算', '收益计算', 'ROI分析', '优先级评分', '风险评估']
    };
  }
}

module.exports = ScenarioEvaluator;
