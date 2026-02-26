/**
 * OpenClaw 3.3 - ROI分析器（ROI Analyzer）
 * 计算ROI，优先级排序，最优策略选择
 * 
 * @version 3.3.0
 * @author OpenClaw V3.3
 * @date 2026-02-22
 */

class ROIAnalyzer {
  constructor(config) {
    this.name = 'ROIAnalyzer';
    this.config = config;
    
    // 成本权重
    this.costWeights = config.costWeight || {
      token: 0.3,
      time: 0.25,
      resource: 0.2,
      risk: 0.25
    };
    
    // 收益权重
    this.benefitWeights = config.benefitWeight || {
      success: 0.35,
      efficiency: 0.25,
      satisfaction: 0.2,
      longTerm: 0.2
    };
    
    // 优先级配置
    this.priorityConfig = {
      minimalScore: 50,      // 最低评分
      goodScore: 70,         // 良好评分
      excellentScore: 85     // 优秀评分
    };
    
    console.log('🎯 ROIAnalyzer 初始化完成\n');
  }

  /**
   * 计算ROI
   * @param {Object} scenario - 场景对象
   * @returns {Object} ROI结果
   */
  calculateROI(scenario) {
    const cost = scenario.cost || 0;
    const benefit = scenario.benefit || 0;
    
    // 计算ROI
    const roi = this.calculateROIValue(cost, benefit);
    
    // 计算成本收益评分
    const costBenefitScore = this.calculateCostBenefitScore(scenario, cost, benefit);
    
    // 计算风险调整后ROI
    const riskAdjustedROI = this.calculateRiskAdjustedROI(scenario, roi);
    
    // 优先级评分
    const priorityScore = this.calculatePriorityScore(scenario, roi, costBenefitScore);
    
    // ROI等级
    const roiGrade = this.getROIGrade(roi);
    
    console.log(`   ROI: ${roi.toFixed(2)}`);
    console.log(`   成本收益评分: ${costBenefitScore.toFixed(2)}`);
    console.log(`   优先级评分: ${priorityScore.toFixed(2)}`);
    console.log(`   ROI等级: ${roiGrade}`);

    return {
      roi,
      costBenefitScore,
      riskAdjustedROI,
      priorityScore,
      roiGrade
    };
  }

  /**
   * 计算ROI值
   * @param {Number} cost - 成本
   * @param {Number} benefit - 收益
   * @returns {Number} ROI
   */
  calculateROIValue(cost, benefit) {
    if (cost === 0) return 0;
    return (benefit / cost) * 100;
  }

  /**
   * 计算成本收益评分
   * @param {Object} scenario - 场景对象
   * @param {Number} cost - 成本
   * @param {Number} benefit - 收益
   * @returns {Number} 成本收益评分（0-100）
   */
  calculateCostBenefitScore(scenario, cost, benefit) {
    // 标准化成本和收益
    const normalizedCost = Math.min(1, cost / 10000); // 假设10000是最大成本
    const normalizedBenefit = Math.min(1, benefit / 100); // 假设100是最大收益
    
    // 计算成本收益比
    const costBenefitRatio = normalizedBenefit / (normalizedCost + 0.1);
    
    // 计算评分
    const score = this.normalizeScore(costBenefitRatio, 0, 2);
    
    return Math.min(100, Math.max(0, score * 100));
  }

  /**
   * 计算风险调整后ROI
   * @param {Object} scenario - 场景对象
   * @param {Number} roi - ROI值
   * @returns {Number} 风险调整后ROI
   */
  calculateRiskAdjustedROI(scenario, roi) {
    const riskScore = scenario.riskScore || 0.5;
    
    // 风险调整：风险越高，ROI越低
    const riskAdjustment = 1 - (riskScore * 0.3); // 最多降低30%
    
    return roi * riskAdjustment;
  }

  /**
   * 计算优先级评分
   * @param {Object} scenario - 场景对象
   * @param {Number} roi - ROI值
   * @param {Number} costBenefitScore - 成本收益评分
   * @returns {Number} 优先级评分
   */
  calculatePriorityScore(scenario, roi, costBenefitScore) {
    // ROI权重
    const roiWeight = 0.6;
    // 成本收益权重
    const costBenefitWeight = 0.4;
    
    // 标准化ROI和成本收益评分
    const normalizedROI = this.normalizeScore(roi, 0, 100);
    const normalizedCostBenefit = costBenefitScore / 100;
    
    // 计算优先级评分
    const priorityScore = normalizedROI * roiWeight + normalizedCostBenefit * costBenefitWeight;
    
    return priorityScore;
  }

  /**
   * 获取ROI等级
   * @param {Number} roi - ROI值
   * @returns {String} ROI等级
   */
  getROIGrade(roi) {
    if (roi >= this.priorityConfig.excellentScore) return 'EXCELLENT';
    if (roi >= this.priorityConfig.goodScore) return 'GOOD';
    if (roi >= this.priorityConfig.minimalScore) return 'FAIR';
    return 'POOR';
  }

  /**
   * 选择最优策略
   * @param {Array} scenarios - 场景数组
   * @returns {Object} 最优场景
   */
  selectOptimalScenario(scenarios) {
    if (!scenarios || scenarios.length === 0) {
      throw new Error('No scenarios to evaluate');
    }

    // 按优先级评分排序
    const sortedScenarios = [...scenarios].sort((a, b) => {
      const scoreA = a.priorityScore || 0;
      const scoreB = b.priorityScore || 0;
      return scoreB - scoreA;
    });

    // 返回最优策略
    const optimal = sortedScenarios[0];

    console.log(`\n🏆 最优策略: ${optimal.name}`);
    console.log(`   ROI: ${optimal.roi.toFixed(2)}`);
    console.log(`   优先级评分: ${optimal.priorityScore.toFixed(2)}`);
    console.log(`   成本: ${optimal.cost.toFixed(2)}`);
    console.log(`   收益: ${optimal.benefit.toFixed(2)}`);

    // 确保返回对象包含所有属性
    return {
      ...optimal,
      roiGrade: optimal.roiGrade || this.getROIGrade(optimal.roi)
    };
  }

  /**
   * 对比分析
   * @param {Array} scenarios - 场景数组
   * @returns {Object} 对比结果
   */
  compareScenarios(scenarios) {
    if (!scenarios || scenarios.length === 0) {
      throw new Error('No scenarios to compare');
    }

    const comparison = {
      totalScenarios: scenarios.length,
      scenarios: scenarios.map(s => ({
        name: s.name,
        roi: s.roi,
        priorityScore: s.priorityScore,
        cost: s.cost,
        benefit: s.benefit,
        riskScore: s.riskScore
      })),
      summary: {
        averageROI: 0,
        bestROI: 0,
        worstROI: 0,
        averageCost: 0,
        averageBenefit: 0
      }
    };

    // 计算平均值
    const rois = scenarios.map(s => s.roi || 0);
    comparison.summary.averageROI = this.average(rois);
    comparison.summary.bestROI = Math.max(...rois);
    comparison.summary.worstROI = Math.min(...rois);

    const costs = scenarios.map(s => s.cost || 0);
    comparison.summary.averageCost = this.average(costs);

    const benefits = scenarios.map(s => s.benefit || 0);
    comparison.summary.averageBenefit = this.average(benefits);

    console.log(`\n📊 对比分析结果:`);
    console.log(`   平均ROI: ${comparison.summary.averageROI.toFixed(2)}`);
    console.log(`   最佳ROI: ${comparison.summary.bestROI.toFixed(2)}`);
    console.log(`   最差ROI: ${comparison.summary.worstROI.toFixed(2)}`);

    return comparison;
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
   * 计算平均值
   * @param {Array} numbers - 数字数组
   * @returns {Number} 平均值
   */
  average(numbers) {
    if (numbers.length === 0) return 0;
    return numbers.reduce((sum, n) => sum + n, 0) / numbers.length;
  }

  /**
   * 获取系统状态
   * @returns {Object} 系统状态
   */
  getStatus() {
    return {
      name: this.name,
      config: this.config,
      capabilities: ['ROI计算', '优先级排序', '最优策略选择', '对比分析']
    };
  }
}

module.exports = ROIAnalyzer;
