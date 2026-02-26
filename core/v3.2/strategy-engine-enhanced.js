/**
 * OpenClaw 3.3 - 策略引擎增强（Strategy Engine Enhanced）
 * 从"预测 → 干预"升级为"预测 → 生成多策略 → 评估收益 → 选择最优 → 执行 → 复盘"
 * 
 * @version 3.3.0
 * @author OpenClaw V3.3
 * @date 2026-02-22
 */

const ScenarioGenerator = require('./v3.2/scenario-generator');
const ScenarioEvaluator = require('./v3.2/scenario-evaluator');
const CostCalculator = require('./v3.2/cost-calculator');
const BenefitCalculator = require('./v3.2/benefit-calculator');
const ROIAnalyzer = require('./v3.2/roi-analyzer');
const RiskAssessor = require('./v3.2/risk-assessor');
const RiskController = require('./v3.2/risk-controller');
const RiskAdjustedScorer = require('./v3.2/risk-adjusted-scorer');
const AdversarySimulator = require('./v3.2/adversary-simulator');
const MultiPerspectiveEvaluator = require('./v3.2/multi-perspective-evaluator');
const GameOptimizer = require('./v3.2/game-optimizer');

class StrategyEngineEnhanced {
  constructor(config = {}) {
    this.name = 'StrategyEngineEnhanced';
    this.config = {
      // 场景模拟器配置
      scenarioCount: 3,              // 场景数量
      scenarioGenerationTimeout: 5000, // 场景生成超时（ms）
      scenarioEvaluationTimeout: 3000, // 场景评估超时（ms）
      
      // 成本收益配置
      costWeight: {
        token: 0.3,
        time: 0.25,
        resource: 0.2,
        risk: 0.25
      },
      benefitWeight: {
        success: 0.35,
        efficiency: 0.25,
        satisfaction: 0.2,
        longTerm: 0.2
      },
      
      // 风险权重配置
      riskThreshold: 0.7,            // 风险评分阈值
      riskControls: {
        maxRiskLevel: 'HIGH',         // 最大允许风险等级
        mitigationRequired: true      // 是否需要缓解措施
      },
      
      // 博弈配置
      adversaryScenarios: 5,         // 对抗场景数量
      perspectiveCount: 4,           // 视角数量
      
      ...config
    };

    // 初始化各模块
    this.scenarioGenerator = new ScenarioGenerator(this.config);
    this.scenarioEvaluator = new ScenarioEvaluator(this.config);
    this.costCalculator = new CostCalculator(this.config);
    this.benefitCalculator = new BenefitCalculator(this.config);
    this.roiAnalyzer = new ROIAnalyzer(this.config);
    this.riskAssessor = new RiskAssessor(this.config);
    this.riskController = new RiskController(this.config);
    this.riskAdjustedScorer = new RiskAdjustedScorer(this.config);
    this.adversarySimulator = new AdversarySimulator(this.config);
    this.multiPerspectiveEvaluator = new MultiPerspectiveEvaluator(this.config);
    this.gameOptimizer = new GameOptimizer(this.config);

    console.log('🧠 StrategyEngineEnhanced 初始化完成\n');
  }

  /**
   * 战略决策主流程
   * @param {Object} context - 决策上下文
   * @returns {Promise<Object>} 决策结果
   */
  async strategicDecision(context) {
    console.log('═════════════════════════════════════════════════════════════');
    console.log('              🎯 战略决策流程开始');
    console.log('═════════════════════════════════════════════════════════════\n');

    try {
      // 1. 场景生成（多方案生成）
      console.log('📊 步骤1: 场景生成（多方案生成）');
      const scenarios = await this.scenarioGenerator.generateScenarios(
        context,
        this.config.scenarioCount
      );
      console.log(`✅ 生成 ${scenarios.length} 个策略方案\n`);

      // 2. 场景评估（成本收益评估）
      console.log('📊 步骤2: 场景评估（成本收益评估）');
      const evaluatedScenarios = await this.scenarioEvaluator.evaluateScenarios(scenarios, context);
      console.log(`✅ 评估完成\n`);

      // 3. 风险评估和调整
      console.log('📊 步骤3: 风险评估和调整');
      for (const scenario of evaluatedScenarios) {
        // 3.1 风险评估
        const riskAssessment = this.riskAssessor.assessRisk(scenario, context);
        scenario.riskAssessment = riskAssessment;
        
        // 3.2 风险控制
        if (riskAssessment.riskScore > this.config.riskThreshold) {
          const riskControl = this.riskController.controlRisk(scenario, riskAssessment, context);
          scenario.riskControl = riskControl;
        }

        // 3.3 风险调整评分
        const riskAdjustedScore = this.riskAdjustedScorer.calculateRiskAdjustedScore(
          scenario,
          riskAssessment
        );
        scenario.riskAdjustedScore = riskAdjustedScore;
      }
      console.log(`✅ 风险评估完成\n`);

      // 4. 多视角评估
      console.log('📊 步骤4: 多视角评估');
      for (const scenario of evaluatedScenarios) {
        const perspectives = this.multiPerspectiveEvaluator.evaluatePerspectives(scenario, context);
        scenario.perspectives = perspectives;
      }
      console.log(`✅ 多视角评估完成\n`);

      // 5. 自我博弈分析
      console.log('📊 步骤5: 自我博弈分析');
      const gameAnalysis = this.gameOptimizer.analyzeGame(evaluatedScenarios, context);
      console.log(`✅ 博弈分析完成\n`);

      // 6. ROI分析和最优策略选择
      console.log('📊 步骤6: ROI分析和最优策略选择');
      const roiResults = this.roiAnalyzer.calculateROI(evaluatedScenarios);
      const optimalScenario = this.roiAnalyzer.selectOptimalScenario(roiResults);
      console.log(`✅ 最优策略选择完成\n`);

      // 7. 生成决策报告
      const decisionReport = this.generateDecisionReport(
        scenarios,
        evaluatedScenarios,
        roiResults,
        optimalScenario,
        gameAnalysis,
        context
      );

      console.log('═════════════════════════════════════════════════════════════');
      console.log('              ✅ 战略决策流程完成');
      console.log('═════════════════════════════════════════════════════════════\n');

      return decisionReport;

    } catch (error) {
      console.error('❌ 战略决策流程失败:', error.message);
      throw error;
    }
  }

  /**
   * 生成决策报告
   * @param {Array} scenarios - 所有策略方案
   * @param {Array} evaluatedScenarios - 评估后的方案
   * @param {Object} roiResults - ROI分析结果
   * @param {Object} optimalScenario - 最优策略
   * @param {Object} gameAnalysis - 博弈分析结果
   * @param {Object} context - 决策上下文
   * @returns {Object} 决策报告
   */
  generateDecisionReport(scenarios, evaluatedScenarios, roiResults, optimalScenario, gameAnalysis, context) {
    return {
      timestamp: Date.now(),
      decisionContext: context,
      summary: {
        totalScenarios: scenarios.length,
        evaluatedScenarios: evaluatedScenarios.length,
        optimalScenario: optimalScenario.name,
        expectedROI: optimalScenario.roi.toFixed(2)
      },
      scenarios: evaluatedScenarios,
      roiResults: roiResults,
      optimalScenario: optimalScenario,
      gameAnalysis: gameAnalysis,
      recommendations: this.generateRecommendations(optimalScenario, gameAnalysis, context)
    };
  }

  /**
   * 生成建议
   * @param {Object} optimalScenario - 最优策略
   * @param {Object} gameAnalysis - 博弈分析
   * @param {Object} context - 决策上下文
   * @returns {Array} 建议
   */
  generateRecommendations(optimalScenario, gameAnalysis, context) {
    const recommendations = [];

    // 基于最优策略
    recommendations.push({
      type: 'strategic',
      priority: 'HIGH',
      description: `选择策略: ${optimalScenario.name}`,
      details: optimalScenario.details
    });

    // 基于风险控制
    if (optimalScenario.riskControl) {
      recommendations.push({
        type: 'risk',
        priority: 'MEDIUM',
        description: `风险控制: ${optimalScenario.riskControl.method}`,
        details: optimalScenario.riskControl.details
      });
    }

    // 基于博弈分析
    if (gameAnalysis.adversaryInsights) {
      recommendations.push({
        type: 'adversarial',
        priority: 'MEDIUM',
        description: `对抗策略: ${gameAnalysis.adversaryInsights}`,
        details: gameAnalysis.adversaryDetails
      });
    }

    // 基于多视角评估
    if (optimalScenario.perspectives) {
      const avgSatisfaction = optimalScenario.perspectives.reduce((sum, p) => sum + p.satisfaction, 0) / optimalScenario.perspectives.length;
      recommendations.push({
        type: 'perspective',
        priority: 'LOW',
        description: `用户满意度: ${avgSatisfaction.toFixed(2)}`,
        details: optimalScenario.perspectives
      });
    }

    return recommendations;
  }

  /**
   * 获取系统状态
   * @returns {Object} 系统状态
   */
  getStatus() {
    return {
      name: this.name,
      config: this.config,
      modules: {
        scenarioGenerator: this.scenarioGenerator.getStatus(),
        scenarioEvaluator: this.scenarioEvaluator.getStatus(),
        costCalculator: this.costCalculator.getStatus(),
        benefitCalculator: this.benefitCalculator.getStatus(),
        roiAnalyzer: this.roiAnalyzer.getStatus(),
        riskAssessor: this.riskAssessor.getStatus(),
        riskController: this.riskController.getStatus(),
        riskAdjustedScorer: this.riskAdjustedScorer.getStatus(),
        adversarySimulator: this.adversarySimulator.getStatus(),
        multiPerspectiveEvaluator: this.multiPerspectiveEvaluator.getStatus(),
        gameOptimizer: this.gameOptimizer.getStatus()
      }
    };
  }
}

module.exports = StrategyEngineEnhanced;
