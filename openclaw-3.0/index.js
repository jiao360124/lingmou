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

// 新模块：Gap Analyzer
const GapAnalyzer = require('./objective/gapAnalyzer');
// 新模块：Pattern Miner
const PatternMiner = require('./value/patternMiner');
// 新模块：ROI Engine
const ROIEngine = require('./economy/roiEngine');
// 新模块：Template Manager
const TemplateManager = require('./value/templateManager');

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

    // 初始化新模块
    this.initializeNewModules();

    // 初始化模块
    this.initialize();

    // 设置定时任务
    this.setupScheduledTasks();

    // 启动监控
    this.startMonitoring();

    // 启动 Watchdog
    this.startWatchdog();
  }

  initializeNewModules() {
    logger.info('🆕 初始化新模块...');

    // 初始化Gap Analyzer
    this.gapAnalyzer = new GapAnalyzer('data/goals.json');
    logger.info('✅ Gap Analyzer 初始化完成');

    // 初始化Pattern Miner
    this.patternMiner = new PatternMiner('data/patterns.json');
    logger.info('✅ Pattern Miner 初始化完成');

    // 初始化ROI Engine
    this.roiEngine = new ROIEngine();
    logger.info('✅ ROI Engine 初始化完成');

    // 初始化Template Manager
    this.templateManager = new TemplateManager('templates/');
    logger.info('✅ Template Manager 初始化完成');
    logger.info('   已有模板: ' + this.templateManager.getTemplates().length + '个');

    logger.info('🆕 新模块初始化完成');
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

    // 每天凌晨3:30点执行Gap分析
    cron.schedule('30 3 * * *', async () => {
      logger.info('⏰ 触发Gap分析');
      await this.performGapAnalysis();
    });

    // 每天凌晨4:30点执行ROI计算
    cron.schedule('30 4 * * *', async () => {
      logger.info('⏰ 触发ROI计算');
      await this.calculateROI();
    });

    // 每天凌晨5点执行模式挖掘
    cron.schedule('0 5 * * *', async () => {
      logger.info('⏰ 触发模式挖掘');
      await this.performPatternMining();
    });

    // 每天凌晨5:30点生成模板报告
    cron.schedule('30 5 * * *', () => {
      logger.info('⏰ 生成模板报告');
      this.generateTemplateReport();
    });

    // 每天凌晨6点重置Token状态
    cron.schedule('0 6 * * *', () => {
      logger.info('⏰ 重置每日Token状态');
      tokenGovernor.resetDaily();
      tracker.resetDaily();
      sessionSummarizer.resetDaily();
    });

    // 每天凌晨7点生成每日报告
    cron.schedule('0 7 * * *', () => {
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

  // 🆕 新增：Gap分析
  async performGapAnalysis() {
    try {
      // 分析Gap
      const gap = this.gapAnalyzer.analyzeGap('data/metrics.json');

      if (gap.suggestions.length > 0) {
        logger.info(`🔍 Gap分析发现 ${gap.suggestions.length} 条优化建议`);

        // 保存最紧迫的建议
        const topSuggestion = gap.suggestions[0];
        this.gapAnalyzer.saveSuggestion(topSuggestion);

        logger.info('✅ 已保存最紧迫的建议');
        logger.info(`   优先级: ${topSuggestion.priority}`);
        logger.info(`   建议: ${topSuggestion.message}`);

        // 生成Gap报告
        const report = {
          timestamp: new Date().toISOString(),
          gap: gap,
          suggestionsCount: gap.suggestions.length
        };

        fs.writeFile('reports/gap-analysis-report.json', JSON.stringify(report, null, 2))
          .then(() => logger.info('✅ Gap报告已保存'))
          .catch(error => logger.error('❌ 保存Gap报告失败:', error));
      } else {
        logger.info('✅ 无Gap，系统运行良好');
      }

    } catch (error) {
      logger.error('❌ Gap分析失败:', error);
    }
  }

  // 🆕 新增：ROI计算
  async calculateROI() {
    try {
      // 获取Gap建议
      const suggestions = this.gapAnalyzer.getHistory();

      if (suggestions.length > 0) {
        logger.info(`💰 计算ROI: ${suggestions.length} 条建议`);

        // 计算ROI
        const roiList = this.roiEngine.rankSuggestions(suggestions);

        // 生成ROI报告
        const roiReport = this.roiEngine.saveROIReport(roiList, 'reports/roi-report.json');

        if (roiReport) {
          logger.info('✅ ROI报告已保存');
          logger.info(`   总ROI: ${roiReport.averageROI.toFixed(2)}%`);
          logger.info(`   总预估收益: ${roiReport.totalEstimatedSavings.toLocaleString()} tokens`);
        }

        // 生成ROI摘要
        const summary = this.roiEngine.generateSummary(roiList);
        logger.info('\n' + summary);

        // 获取高ROI建议
        const highROI = this.roiEngine.getHighROIList(suggestions);
        logger.info(`🎯 高ROI建议: ${highROI.length} 条`);
        highROI.forEach((s, i) => {
          logger.info(`   ${i + 1}. ${s.message} - ROI: ${s.roiPercentage.toFixed(2)}%`);
        });
      } else {
        logger.info('✅ 无历史建议，无法计算ROI');
      }

    } catch (error) {
      logger.error('❌ ROI计算失败:', error);
    }
  }

  // 🆕 新增：模式挖掘
  async performPatternMining() {
    try {
      logger.info('🔍 开始模式挖掘...');

      // 从日志中提取prompts
      const prompts = this.patternMiner.extractPromptsFromLogs('logs/openclaw-3.0.log');

      if (prompts.length > 0) {
        logger.info(`📊 提取到 ${prompts.length} 个prompts`);

        // 生成模板
        const templates = this.patternMiner.mineTemplates(prompts);

        logger.info(`✅ 生成 ${templates.length} 个模板`);

        // 导入模板
        let count = 0;
        for (const template of templates) {
          const saved = this.templateManager.saveTemplate(template);
          if (saved) count++;
        }

        logger.info(`✅ 已导入 ${count} 个模板到库`);

        // 保存patterns配置
        this.patternMiner.savePatterns();

        // 生成报告
        this.generateTemplateReport();

      } else {
        logger.info('✅ 未提取到prompts');
      }

    } catch (error) {
      logger.error('❌ 模式挖掘失败:', error);
    }
  }

  // 🆕 新增：模板报告
  generateTemplateReport() {
    try {
      const stats = this.templateManager.getTemplateStats();
      const report = this.templateManager.generateTemplateReport();

      logger.info('=== 模板库统计 ===');
      logger.info(report);

      // 保存报告
      fs.writeFile('reports/template-report.md', report, 'utf8')
        .then(() => logger.info('✅ 模板报告已保存'))
        .catch(error => logger.error('❌ 保存模板报告失败:', error));

    } catch (error) {
      logger.error('❌ 生成模板报告失败:', error);
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
      uptime: process.uptime(),
      // 🆕 新增：新模块信息
      newModules: {
        gapAnalyzer: {
          suggestionsCount: this.gapAnalyzer.getHistory().length,
          lastAnalysis: this.gapAnalyzer.getHistory().slice(-1)[0]?.timestamp || null
        },
        roiEngine: {
          roiList: this.roiEngine.getHighROIList(this.gapAnalyzer.getHistory()),
          averageROI: this.roiEngine.metrics.dailyTokens > 0 ? this.roiEngine.metrics.costReduction : 0
        },
        templateManager: {
          totalTemplates: this.templateManager.getTemplates().length,
          byType: this.templateManager.getTemplatesByType().reduce((acc, t) => {
            acc[t.type] = (acc[t.type] || 0) + 1;
            return acc;
          }, {})
        }
      }
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
