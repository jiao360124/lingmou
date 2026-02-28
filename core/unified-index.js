// core/unified-index.js
// OpenClaw 3.0+3.2 - 统一智能入口点（修复版）

const winston = require('winston');
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/unified-index.log' }),
    new winston.transports.Console({ format: winston.format.simple() })
  ]
});

// ==========================================
// 1. 核心引擎层（Converged Engine Layer）
// ==========================================

// 预测引擎（V3.0）
const PredictiveEngine = require('./predictive-engine');

// 场景模拟器（V3.2）
const ScenarioGenerator = require('./strategy/scenario-generator');
const ScenarioEvaluator = require('./strategy/scenario-evaluator');

// 策略引擎（V3.2）
const StrategyEngine = require('./strategy/strategy-engine');

// 认知层（V3.2）
const CognitiveLayer = require('./cognitive-layer');

// 架构审计（V3.2）
const ArchitectureAuditor = require('./architecture-auditor');

// ==========================================
// 2. 自我保护层（V3.0）
// ==========================================

// 差异回滚引擎
const RollbackEngine = require('./rollback-engine');

// System Memory Layer
const SystemMemoryLayer = require('./system-memory');

// Watchdog 守护线程
const Watchdog = require('./watchdog');

// ==========================================
// 3. 调节能力层（V3.0 + V3.2）
// ==========================================

// Nightly Worker（预算控制）
const NightlyWorker = require('./nightly-worker');

// 性能监控模块
const PerformanceMonitor = require('./monitoring/performance-monitor');

// 内存监控模块
const MemoryMonitor = require('./monitoring/memory-monitor');

// API追踪模块
const APITracker = require('./monitoring/api-tracker');

// ==========================================
// 初始化所有模块
// ==========================================

class UnifiedIndex {
  constructor(config) {
    this.config = config;
    this.state = {
      initialized: false,
      modulesLoaded: [],
      lastCheck: null
    };

    logger.info('🚀 OpenClaw 统一索引启动');
    logger.info('📦 V3.0 + V3.2 完全集成模式');
  }

  /**
   * 初始化所有模块
   */
  async initialize() {
    logger.info('开始初始化统一系统...');

    try {
      // Phase 1: 初始化核心引擎层
      await this.initializeCoreEngine();

      // Phase 2: 初始化自我保护层
      await this.initializeProtectionLayer();

      // Phase 3: 初始化调节能力层
      await this.initializeRegulationLayer();

      // Phase 4: 启动守护线程
      await this.initializeWatchdog();

      this.state.initialized = true;
      this.state.modulesLoaded = [
        'predictive-engine',      // 预测引擎
        'scenario-generator',      // 场景模拟
        'scenario-evaluator',      // 场景评估
        'strategy-engine',        // 策略引擎
        'cognitive-layer',        // 认知层
        'architecture-auditor',   // 架构审计
        'rollback-engine',        // 回滚引擎
        'system-memory',          // 记忆层
        'watchdog',               // 守护线程
        'nightly-worker',         // 预算控制
        'performance-monitor',    // 性能监控
        'memory-monitor',         // 内存监控
        'api-tracker'             // API追踪
      ];

      logger.info('✅ 所有模块初始化完成');
      logger.info(`📊 已加载模块: ${this.state.modulesLoaded.length}个`);

      return {
        success: true,
        modules: this.state.modulesLoaded,
        modulesCount: this.state.modulesLoaded.length
      };

    } catch (error) {
      logger.error('❌ 模块初始化失败', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Phase 1: 初始化核心引擎层
   */
  async initializeCoreEngine() {
    logger.info('Phase 1: 初始化核心引擎层...');

    // 预测引擎
    this.predictive = new PredictiveEngine(this.config);
    logger.info('✅ 预测引擎已加载');

    // 场景模拟器
    this.scenarioGenerator = new ScenarioGenerator(this.config);
    this.scenarioEvaluator = new ScenarioEvaluator(this.config);

    // 策略引擎
    this.strategyEngine = new StrategyEngine(this.config);

    // 认知层
    this.cognitive = new CognitiveLayer(this.config);

    // 架构审计
    this.architectureAuditor = new ArchitectureAuditor();

    logger.info('✅ 核心引擎层初始化完成');
  }

  /**
   * Phase 2: 初始化自我保护层
   */
  async initializeProtectionLayer() {
    logger.info('Phase 2: 初始化自我保护层...');

    // 回滚引擎
    this.rollbackEngine = RollbackEngine;
    logger.info('✅ 差异回滚引擎已加载');

    // System Memory Layer
    this.systemMemory = SystemMemoryLayer;
    logger.info('✅ System Memory Layer 已加载');

    logger.info('✅ 自我保护层初始化完成');
  }

  /**
   * Phase 3: 初始化调节能力层
   */
  async initializeRegulationLayer() {
    logger.info('Phase 3: 初始化调节能力层...');

    // Nightly Worker
    this.nightlyWorker = NightlyWorker;
    logger.info('✅ Nightly Worker 已加载');

    // 性能监控
    this.performanceMonitor = PerformanceMonitor;
    this.memoryMonitor = MemoryMonitor;
    this.apiTracker = APITracker;

    logger.info('✅ 调节能力层初始化完成');
  }

  /**
   * Phase 4: 启动守护线程
   */
  async initializeWatchdog() {
    logger.info('Phase 4: 启动守护线程...');

    // 启动 Watchdog
    this.watchdog = new Watchdog();
    await this.watchdog.start();

    logger.info('✅ Watchdog 已启动');
  }

  /**
   * 智能决策入口
   * @param {Object} metrics - 当前指标数据
   * @param {Object} context - 上下文信息
   * @returns {Object} 决策结果
   */
  async makeDecision(metrics, context) {
    if (!this.state.initialized) {
      throw new Error('系统未初始化，请先调用 initialize()');
    }

    logger.info('🎯 执行智能决策...');

    // Step 1: 预测引擎评估压力
    const prediction = this.predictive.evaluate(metrics, context);

    // Step 2: 策略引擎选择最优策略
    const selectedStrategy = this.strategyEngine.selectBestStrategy(context);

    // Step 3: 认知层评估任务模式
    const taskPattern = this.cognitive.analyzeTask(context);

    // Step 4: System Memory Layer 记录历史
    this.systemMemory.recordOptimization(selectedStrategy);
    this.systemMemory.recordFailurePattern(context);

    // Step 5: 架构审计（定期执行）
    if (context.enableArchitectureAudit) {
      const auditResult = this.architectureAuditor.audit();
      logger.info('📊 架构审计结果', auditResult);
    }

    // Step 6: 返回完整决策
    return {
      prediction,
      selectedStrategy,
      taskPattern,
      decision: selectedStrategy.action,
      confidence: selectedStrategy.confidence
    };
  }

  /**
   * 获取系统状态
   * @returns {Object} 系统状态
   */
  getStatus() {
    if (!this.state.initialized) {
      return {
        initialized: false,
        modulesLoaded: []
      };
    }

    return {
      initialized: true,
      modulesLoaded: this.state.modulesLoaded,
      uptime: this.watchdog ? this.watchdog.getUptime() : null,
      memoryUsage: this.memoryMonitor ? this.memoryMonitor.getCurrentMemory() : null,
      successRate: this.apiTracker ? this.apiTracker.getSuccessRate() : null
    };
  }

  /**
   * 停止系统
   */
  async shutdown() {
    logger.info('🛑 开始关闭系统...');

    if (this.watchdog) {
      await this.watchdog.stop();
    }

    logger.info('✅ 系统已关闭');
  }
}

// ==========================================
// 导出统一入口点
// ==========================================

module.exports = UnifiedIndex;
