/**
 * 策略引擎统一导出
 */

const strategyEngine = require('./strategy-engine');
const strategyEngineEnhanced = require('./strategy-engine-enhanced');
const scenarioGenerator = require('./scenario-generator');
const scenarioEvaluator = require('./scenario-evaluator');
const adversarySimulator = require('./adversary-simulator');
const multiPerspectiveEvaluator = require('./multi-perspective-evaluator');
const riskAssessor = require('./risk-assessor');
const riskController = require('./risk-controller');
const riskAdjustedScorer = require('./risk-adjusted-scorer');
const costCalculator = require('./cost-calculator');
const benefitCalculator = require('./benefit-calculator');
const roiAnalyzer = require('./roi-analyzer');

module.exports = {
  // 核心引擎
  strategyEngine,
  strategyEngineEnhanced,

  // 场景生成和评估
  scenarioGenerator,
  scenarioEvaluator,
  adversarySimulator,
  multiPerspectiveEvaluator,

  // 风险评估
  riskAssessor,
  riskController,
  riskAdjustedScorer,

  // 成本效益分析
  costCalculator,
  benefitCalculator,
  roiAnalyzer,

  /**
   * 初始化策略引擎
   */
  init(config = {}) {
    strategyEngine.init(config);
    strategyEngineEnhanced.init(config);
  },

  /**
   * 获取策略引擎实例
   */
  getEngine(type = 'standard') {
    return type === 'enhanced' ? strategyEngineEnhanced : strategyEngine;
  }
};
