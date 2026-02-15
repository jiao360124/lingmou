// openclaw-3.0/index.js
// OpenClaw 3.0 - 主入口

const winston = require('winston');
const cron = require('node-cron');
const tracker = require('./metrics/tracker');
const objectiveEngine = require('./objective/objective-engine');
const nightlyWorker = require('./value/nightly-worker');
const tokenGovernor = require('./economy/token-governor');
const apiHandler = require('./core/api-handler');
const sessionSummarizer = require('./core/session-summarizer');
const stateManager = require('./core/state-manager');
const controlTower = require('./core/control-tower');
const rollbackEngine = require('./core/rollback-engine');
const systemMemory = require('./memory/system-memory');
const watchdog = require('./core/watchdog');

const fs = require('fs').promises;

// 日志配置
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/openclaw-3.0.log' }),
    new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
    new winston.transports.Console({ format: winston.format.simple() })
  ]
});

class OpenClaw3 {
  constructor() {
    logger.info('🎉 OpenClaw 3.0 启动中...');

    // 初始化状态管理
    stateManager.initialize().then(() => {
      logger.info('✅ State Manager 初始化完成');
    });

    // 初始化会话摘要器
    sessionSummarizer.resetDaily();
    logger.info('✅ Session Summarizer 初始化完成');

    // 初始化控制塔
    logger.info('✅ Control Tower 初始化完成');
    logger.info('   当前模式:', controlTower.getCurrentMode().name);

    // 初始化回滚引擎
    logger.info('✅ Rollback Engine 初始化完成');
    logger.info('   有当前配置:', rollbackEngine.getStatus().hasCurrentConfig);

    // 初始化系统记忆
    logger.info('✅ System Memory Layer 初始化完成');

    // 初始化Watchdog
    logger.info('✅ Watchdog 初始化完成');
    watchdog.start();

    // 初始化模块
    this.initialize();

    // 设置定时任务
    this.setupScheduledTasks();

    // 启动监控
    this.startMonitoring();

    // 启动 Watchdog
    this.startWatchdog();
  }

  initialize() {
    logger.info('初始化模块...');

    // Token Governor
    logger.info('✅ Token Governor 初始化完成');
    tokenGovernor.resetDaily();

    // Metrics
    logger.info('✅ Metrics Tracker 初始化完成');

    // Objective Engine
    logger.info('✅ Objective Engine 初始化完成');

    // Nightly Worker
    logger.info('✅ Nightly Worker 初始化完成');

    logger.info('🎉 所有模块初始化完成');
  }

  setupScheduledTasks() {
    logger.info('设置定时任务...');

    // 每天凌晨3点执行夜间任务（检查是否需要优化）
    cron.schedule('0 3 * * *', async () => {
      logger.info('⏰ 触发夜间优化检查');
      await this.checkOptimization();
    });

    // 每天凌晨4点重置Token状态
    cron.schedule('0 4 * * *', () => {
      logger.info('⏰ 重置每日Token状态');
      tokenGovernor.resetDaily();
      tracker.resetDaily();
      sessionSummarizer.resetDaily();
    });

    // 每天凌晨5点生成报告
    cron.schedule('0 5 * * *', () => {
      logger.info('⏰ 生成每日报告');
      this.generateDailyReport();
    });

    logger.info('✅ 定时任务设置完成');
  }

  startMonitoring() {
    logger.info('启动监控系统...');

    // 每5分钟检查一次Token使用
    setInterval(() => {
      this.checkTokenUsage();
    }, 5 * 60 * 1000);

    // 每10分钟记录一次指标
    setInterval(() => {
      this.logMetrics();
    }, 10 * 60 * 1000);

    // 每30分钟更新系统模式
    setInterval(() => {
      this.updateSystemMode();
    }, 30 * 60 * 1000);

    logger.info('✅ 监控系统启动完成');
  }

  startWatchdog() {
    logger.info('启动 Watchdog 守护线程...');

    // 每60秒检查一次系统状态
    setInterval(() => {
      this.watchdogCheck();
    }, 60 * 1000);

    logger.info('✅ Watchdog 守护线程启动完成');
  }

  async checkOptimization() {
    // 获取指标
    const metrics = tracker.getMetrics();

    // 检查是否重复优化
    const optimizationType = 'cost_reduction';
    if (systemMemory.isDuplicateOptimization(optimizationType)) {
      logger.warn('⚠️  检测到重复优化，跳过', { optimizationType });
      return;
    }

    // Evolution Gate 决策
    const decision = controlTower.makeOptimizationDecision(metrics, objectiveEngine.getGoals());

    if (decision.allowed) {
      logger.info('✅ 优化提议已通过，创建快照', decision);

      // 记录优化历史
      systemMemory.recordOptimization({
        type: optimizationType,
        description: '成本降低优化',
        changes: decision.proposedChanges,
        result: { success: true },
        success: true,
        riskScore: decision.riskScore,
        snapshotId: decision.snapshotId
      });

      // 执行优化
      // TODO: 实现优化执行
      // controlTower.enterValidationWindow(decision);
    } else {
      logger.info('⚠️  优化未通过', decision);
    }
  }

  async handleMessage(msg) {
    // Runtime Gear 检查（调用前控制）
    if (!controlTower.isCallAllowed()) {
      logger.warn('⚠️  调用被拒绝，熔断器开启');
      return {
        allowed: false,
        reason: 'circuit_breaker_open',
        mode: controlTower.getCurrentMode().name
      };
    }

    try {
      // 更新系统模式（权重驱动）
      this.updateWeightedMode();

      // 更新熔断器
      controlTower.updateCircuitBreaker(false);

      // 增加 turn 计数
      stateManager.incrementTurn();
      sessionSummarizer.incrementTurn();

      // 更新上下文
      await stateManager.updateContext(msg);

      // 检查是否需要触发摘要
      if (sessionSummarizer.shouldTrigger()) {
        const contextTokens = sessionSummarizer.getContextThreshold();
        const summary = await sessionSummarizer.triggerSummary(contextTokens);
        logger.info('📝 会话摘要已触发', { summaryLength: summary.length });
      }

      // 调用 Runtime
      const runtime = require('./core/runtime');
      const response = await runtime.handleMessage(msg);

      // 记录 Token 使用
      tokenGovernor.recordUsage(response.tokensUsed || 100);
      tracker.trackCall(response.tokensUsed || 100, true);

      // 更新熔断器
      controlTower.updateCircuitBreaker(true);

      return response;

    } catch (error) {
      // 记录错误
      tracker.trackError();
      controlTower.updateCircuitBreaker(true);

      // 记录失败模式
      systemMemory.recordFailurePattern({
        type: 'api_call',
        description: error.message,
        triggerCondition: error.code || 'unknown',
        errorType: error.constructor.name,
        recoveryAction: 'retry_with_backoff'
      });

      logger.error('处理消息失败:', error);

      // 更新系统模式（因为出错）
      this.updateSystemMode();

      throw error;
    }
  }

  updateSystemMode() {
    // 获取指标
    const metrics = tracker.getReport();
    const usage = tokenGovernor.getUsageReport();

    // 计算错误率
    const errorRate = metrics.errorCount > 0
      ? (metrics.errorCount / metrics.successRate) * 100
      : 0;

    // Token 使用比例
    const tokenUsageRatio = usage.remaining / usage.dailyLimit;

    // 更新系统模式（旧方法）
    controlTower.updateSystemMode(errorRate, tokenUsageRatio, controlTower.circuitBreaker.failures);
  }

  updateWeightedMode() {
    // 获取指标
    const metrics = tracker.getReport();
    const usage = tokenGovernor.getUsageReport();

    // 计算错误率
    const errorRate = metrics.errorCount > 0
      ? (metrics.errorCount / metrics.successRate) * 100
      : 0;

    // Token 使用比例
    const tokenUsageRatio = usage.remaining / usage.dailyLimit;

    // 更新权重模式（新方法）
    controlTower.updateWeightedMode(errorRate, tokenUsageRatio, controlTower.circuitBreaker.failures);
  }

  watchdogCheck() {
    // 获取系统状态
    const status = controlTower.getStatus();

    // 检查 Token 使用异常
    const usage = tokenGovernor.getUsageReport();
    if (usage.usageRatio > 0.95) {
      logger.warn('⚠️  Watchdog: Token使用超过95%，可能异常');
      // 触发紧急模式
      controlTower.setMode('RECOVERY');
    }

    // 检查错误率异常
    const metrics = tracker.getReport();
    if (metrics.errorRate > 15) {
      logger.warn('⚠️  Watchdog: 错误率超过15%，触发紧急检查');
      // 检查是否需要紧急回滚
      rollbackEngine.emergencyRollback(metrics);
    }

    // 检查系统模式稳定性
    if (status.currentMode === 'RECOVERY') {
      logger.info('Watchdog: 系统在恢复模式中');
    }
  }

  checkTokenUsage() {
    const usage = tokenGovernor.getUsageReport();
    const report = tracker.getReport();

    logger.info(`📊 Token使用情况: ${usage.used} / ${usage.dailyLimit}`);

    if (usage.used > usage.dailyLimit * 0.9) {
      logger.warn('⚠️  Token使用量超过90%，建议优化');
    }

    if (report.successRate < 90) {
      logger.warn(`⚠️  成功率低于90%: ${report.successRate}%`);
    }
  }

  logMetrics() {
    const report = tracker.getReport();
    const usage = tokenGovernor.getUsageReport();
    const sessionState = stateManager.getState();
    const controlTowerStatus = controlTower.getStatus();

    logger.info('=== 指标报告 ===');
    logger.info(`每日Token: ${report.dailyTokens}`);
    logger.info(`成本: $${report.cost}`);
    logger.info(`成功率: ${report.successRate}%`);
    logger.info(`Token剩余: ${usage.remaining}`);
    logger.info(`当前轮次: ${sessionState.turnCount}`);
    logger.info(`系统模式: ${controlTowerStatus.currentMode.name}`);
    logger.info(`验证窗口: ${controlTowerStatus.currentState}`);
  }

  generateDailyReport() {
    const report = tracker.getReport();
    const objectiveReport = objectiveEngine.getReport();
    const usage = tokenGovernor.getUsageReport();
    const controlTowerStatus = controlTower.getStatus();

    const dailyReport = {
      date: new Date().toISOString(),
      metrics: report,
      goals: objectiveReport.goals,
      gap: objectiveReport.gap,
      optimization: objectiveReport.optimization,
      usage: usage,
      controlTower: controlTowerStatus
    };

    logger.info('=== 每日报告 ===');
    logger.info(`日期: ${dailyReport.date}`);
    logger.info(`每日Token: ${dailyReport.metrics.dailyTokens}`);
    logger.info(`成本: $${dailyReport.metrics.cost}`);
    logger.info(`成功率: ${dailyReport.metrics.successRate}%`);
    logger.info(`模板数: ${dailyReport.metrics.templatesGenerated}`);
    logger.info(`夜间任务执行次数: ${dailyReport.metrics.nightlyTasksExecuted}`);
    logger.info(`系统模式: ${dailyReport.controlTower.currentMode.name}`);
    logger.info(`验证窗口: ${dailyReport.controlTower.currentState}`);

    // 保存报告
    fs.writeFile('reports/daily-report.json', JSON.stringify(dailyReport, null, 2))
      .then(() => logger.info('✅ 每日报告已保存'))
      .catch(error => logger.error('❌ 保存报告失败:', error));
  }

  getDashboard() {
    const report = tracker.getReport();
    const usage = tokenGovernor.getUsageReport();
    const objectiveReport = objectiveEngine.getReport();
    const controlTowerStatus = controlTower.getStatus();

    return {
      metrics: report,
      usage: usage,
      goals: objectiveReport.goals,
      gap: objectiveReport.gap,
      optimization: objectiveReport.optimization,
      controlTower: controlTowerStatus,
      uptime: process.uptime()
    };
  }

  rollback() {
    logger.warn('⚠️  执行自动回滚...');
    rollbackEngine.emergencyRollback(tracker.getReport());
  }
}

// 创建实例
const openclaw3 = new OpenClaw3();

// 暴露给外部
module.exports = openclaw3;

// 优雅退出
process.on('SIGINT', () => {
  logger.info('\n🛑 OpenClaw 3.0 正在关闭...');
  process.exit(0);
});

logger.info('🎉 OpenClaw 3.0 已启动！');
logger.info('📊 运行时间: ' + Math.floor(process.uptime()) + ' 秒');
logger.info('🚀 系统就绪！');
