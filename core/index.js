/**
 * 灵眸 v3.2.6 核心模块统一导出
 *
 * 整合所有核心模块，提供统一的接口
 */

// 监控模块
const monitoring = require('./monitoring');

// 策略引擎
const strategy = require('./strategy');

// 核心功能
const controlTower = require('./control-tower');
const cognitiveLayer = require('./cognitive-layer');
const systemMemory = require('./system-memory');
const unifiedIndex = require('./unified-index');

// 系统工具
const apiTracker = require('./monitoring/api-tracker');
const architectureAuditor = require('./architecture-auditor');
const rollbackEngine = require('./rollback-engine');
const watchdog = require('./watchdog');
const nightlyWorker = require('./nightly-worker');
const performanceMonitor = require('./monitoring/performance-monitor');
const memoryMonitor = require('./monitoring/memory-monitor');
const predictiveEngine = require('./predictive-engine');

// 性能优化模块
const lazyLoader = require('./lazy-loader');
const asyncIO = require('./async-io');
const apiCache = require('./api-cache');
const optimizedStrategyEngine = require('./optimized-strategy-engine');

// 策略引擎模块
const scenarioGenerator = require('./strategy/scenario-generator');
const scenarioEvaluator = require('./strategy/scenario-evaluator');
const adversarySimulator = require('./strategy/adversary-simulator');
const multiPerspectiveEvaluator = require('./strategy/multi-perspective-evaluator');
const riskAssessor = require('./strategy/risk-assessor');
const riskController = require('./strategy/risk-controller');
const riskAdjustedScorer = require('./strategy/risk-adjusted-scorer');
const costCalculator = require('./strategy/cost-calculator');
const benefitCalculator = require('./strategy/benefit-calculator');
const roiAnalyzer = require('./strategy/roi-analyzer');

module.exports = {
  // 监控模块
  monitoring,

  // 策略引擎
  strategy,

  // 核心功能
  controlTower,
  cognitiveLayer,
  systemMemory,
  unifiedIndex,

  // 系统工具
  apiTracker,
  architectureAuditor,
  rollbackEngine,
  watchdog,
  nightlyWorker,
  performanceMonitor,
  memoryMonitor,
  predictiveEngine,

  // 策略引擎模块
  scenarioGenerator,
  scenarioEvaluator,
  adversarySimulator,
  multiPerspectiveEvaluator,
  riskAssessor,
  riskController,
  riskAdjustedScorer,
  costCalculator,
  benefitCalculator,
  roiAnalyzer,

  // 性能优化模块
  lazyLoader,
  asyncIO,
  apiCache,
  optimizedStrategyEngine,

  /**
   * 初始化所有核心模块
   */
  init(config = {}) {
    monitoring.init(config);
    strategy.init(config);
    controlTower.init(config);
    cognitiveLayer.init(config);
    systemMemory.init(config);
    unifiedIndex.init(config);

    // 初始化性能优化模块
    lazyLoader.init(config);
    apiCache.init(config);
    optimizedStrategyEngine.init(config);
  },

  /**
   * 获取版本信息
   */
  getVersion() {
    return require('./version-v3.2.6.json');
  }
};
