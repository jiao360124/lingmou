// openclaw-3.0/value/nightly-worker.js
// Nightly Worker - 夜间任务执行

const fs = require('fs').promises;
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/nightly-worker.log' }),
    new winston.transports.Console({ format: winston.format.simple() })
  ]
});

// 加载指标追踪
const tracker = require('../metrics/tracker');
// 加载控制塔
const controlTower = require('./control-tower');

// 加载配置
const CONFIG = require('../config.json');

class NightlyWorker {
  constructor() {
    this.tasks = [];
    this.initTasks();

    // 夜间任务预算
    this.nightBudget = {
      tokens: CONFIG.nightBudgetTokens || 50000,
      calls: CONFIG.nightBudgetCalls || 10
    };

    this.nightUsage = {
      tokens: 0,
      calls: 0
    };

    logger.info('Nightly Worker 初始化完成', {
      budgetTokens: this.nightBudget.tokens,
      budgetCalls: this.nightBudget.calls
    });
  }

  /**
   * 初始化夜间任务
   */
  initTasks() {
    this.tasks = [
      {
        name: 'analyze_metrics',
        description: '分析当日指标',
        execute: async () => this.analyzeMetrics(),
        priority: 1,
        estimatedTokens: 5000,
        estimatedCalls: 1
      },
      {
        name: 'generate_templates',
        description: '生成常见模式模板',
        execute: async () => this.generateTemplates(),
        priority: 2,
        estimatedTokens: 10000,
        estimatedCalls: 3
      },
      {
        name: 'optimize_prompts',
        description: '优化Prompt策略',
        execute: async () => this.optimizePrompts(),
        priority: 3,
        estimatedTokens: 8000,
        estimatedCalls: 2
      },
      {
        name: 'update_goals',
        description: '更新目标设定',
        execute: async () => this.updateGoals(),
        priority: 4,
        estimatedTokens: 3000,
        estimatedCalls: 1
      }
    ];
  }

  /**
   * 分析当日指标
   */
  async analyzeMetrics() {
    logger.info('开始分析当日指标...');

    const metrics = tracker.getMetrics();
    const objective = require('../objective/objective-engine');

    // 记录夜间任务执行
    tracker.trackNightlyTask();

    logger.info('指标分析完成', {
      dailyTokens: metrics.dailyTokens,
      cost: metrics.cost,
      successRate: metrics.successRate,
      errorRate: (metrics.errorCount / metrics.successRate * 100).toFixed(1)
    });
  }

  /**
   * 生成常见模式模板
   */
  async generateTemplates() {
    logger.info('开始生成常见模式模板...');

    const commonPatterns = [
      {
        name: 'code_completion',
        description: '代码行级补全',
        template: `提供${parameter}参数的代码补全`,
        usage: 80
      },
      {
        name: 'error_analysis',
        description: '错误诊断',
        template: '分析错误原因并提供解决方案',
        usage: 75
      },
      {
        name: 'explanation',
        description: '技术解释',
        template: '解释${concept}的工作原理',
        usage: 70
      },
      {
        name: 'refactoring',
        description: '代码重构',
        template: '重构${code}以提高可读性和性能',
        usage: 60
      }
    ];

    // 保存模板
    const templatesDir = 'templates';
    for (const pattern of commonPatterns) {
      const templateFile = `${templatesDir}/${pattern.name}.md`;
      await fs.writeFile(templateFile, `# ${pattern.name}\n\n${pattern.description}\n\n## 使用\n\n${pattern.template}\n`, 'utf8');
      logger.info(`模板已生成: ${pattern.name}`);
    }

    tracker.trackTemplateGeneration();
    logger.info('常见模式模板生成完成');
  }

  /**
   * 优化Prompt策略
   */
  async optimizePrompts() {
    logger.info('开始优化Prompt策略...');

    const objective = require('../objective/objective-engine');
    const metrics = tracker.getMetrics();

    // 基于指标优化 Prompt
    if (metrics.errorRate > 10) {
      logger.info('优化Prompt以减少错误', {
        errorRate: metrics.errorRate,
        suggestion: '更清晰的指令, 上下文减少, 重试机制增强'
      });
    }

    if (metrics.dailyTokens > 180000) {
      logger.info('优化Prompt以减少Token使用', {
        dailyTokens: metrics.dailyTokens,
        suggestion: '减少上下文长度, 使用更简洁的指令'
      });
    }

    logger.info('Prompt策略优化完成');
  }

  /**
   * 更新目标设定
   */
  async updateGoals() {
    logger.info('开始更新目标设定...');

    const objective = require('../objective/objective-engine');
    const metrics = tracker.getMetrics();

    // 根据实际表现调整目标
    if (metrics.successRate < 90) {
      objective.updateGoal('successRate', metrics.successRate);
      logger.info('已调整成功率目标', {
        oldTarget: objective.getReport().goals.successRate,
        newTarget: metrics.successRate
      });
    }

    if (metrics.dailyTokens > 180000) {
      objective.updateGoal('tokenUsage', metrics.dailyTokens);
      logger.info('已调整Token使用目标', {
        oldTarget: objective.getReport().goals.tokenUsage,
        newTarget: metrics.dailyTokens
      });
    }

    logger.info('目标设定更新完成');
  }

  /**
   * 检查是否有足够预算
   * @param {Object} task - 任务
   * @returns {boolean}
   */
  hasBudget(task) {
    const tokenBudget = this.nightBudget.tokens - this.nightUsage.tokens;
    const callBudget = this.nightBudget.calls - this.nightUsage.calls;

    if (tokenBudget < task.estimatedTokens) {
      logger.warn(`⚠️  Token预算不足`, {
        task: task.name,
        estimatedTokens: task.estimatedTokens,
        usedTokens: this.nightUsage.tokens,
        availableTokens: tokenBudget
      });
      return false;
    }

    if (callBudget < task.estimatedCalls) {
      logger.warn(`⚠️  调用预算不足`, {
        task: task.name,
        estimatedCalls: task.estimatedCalls,
        usedCalls: this.nightUsage.calls,
        availableCalls: callBudget
      });
      return false;
    }

    return true;
  }

  /**
   * 记录任务执行
   * @param {Object} task - 任务
   */
  recordTask(task, actualTokens, actualCalls) {
    this.nightUsage.tokens += actualTokens;
    this.nightUsage.calls += actualCalls;

    logger.info(`📝 任务消耗已记录`, {
      task: task.name,
      actualTokens,
      actualCalls
    });
  }

  /**
   * 运行所有夜间任务
   */
  async runNightlyTasks() {
    logger.info('🌙 触发夜间任务执行...');

    // 检查系统模式（Evolution Gate）
    const status = controlTower.getStatus();
    if (status.currentState !== 'NORMAL') {
      logger.warn('⚠️  不在正常模式，跳过夜间任务');
      return;
    }

    // 检查验证窗口
    if (status.validationWindow.active) {
      logger.warn('⚠️  在验证窗口内，跳过夜间任务');
      return;
    }

    // 检查预算
    const totalEstimatedTokens = this.tasks.reduce((sum, task) => sum + task.estimatedTokens, 0);
    const totalEstimatedCalls = this.tasks.reduce((sum, task) => sum + task.estimatedCalls, 0);

    if (this.nightBudget.tokens < totalEstimatedTokens) {
      logger.warn('⚠️  夜间Token预算不足', {
        budget: this.nightBudget.tokens,
        estimatedTotal: totalEstimatedTokens
      });
      return;
    }

    if (this.nightBudget.calls < totalEstimatedCalls) {
      logger.warn('⚠️  夜间调用预算不足', {
        budget: this.nightBudget.calls,
        estimatedTotal: totalEstimatedCalls
      });
      return;
    }

    logger.info('📊 夜间预算检查通过', {
      budgetTokens: this.nightBudget.tokens,
      budgetCalls: this.nightBudget.calls,
      totalEstimatedTokens,
      totalEstimatedCalls
    });

    try {
      // 按优先级执行任务
      for (const task of this.tasks.sort((a, b) => a.priority - b.priority)) {
        logger.info(`执行任务: ${task.name}`);

        // 检查预算
        if (!this.hasBudget(task)) {
          logger.warn(`⏹️  停止执行，预算不足`);
          break;
        }

        await task.execute();

        // 记录预算使用
        this.recordTask(task, task.estimatedTokens, task.estimatedCalls);

        logger.info(`✅ 任务完成: ${task.name}`);
      }

      logger.info('🌙 夜间任务全部完成', {
        tokensUsed: this.nightUsage.tokens,
        callsUsed: this.nightUsage.calls
      });

    } catch (error) {
      logger.error('❌ 夜间任务执行失败', error);
    }
  }

  /**
   * 获取夜间任务报告
   * @returns {Object}
   */
  getReport() {
    const status = controlTower.getStatus();

    return {
      tasksExecuted: status.validationWindow.history.filter(h =>
        h.state.includes('NIGHTLY')
      ).length,
      lastExecution: null, // TODO: 记录最后执行时间
      isNightlyEnabled: status.currentState === 'NORMAL'
    };
  }
}

module.exports = new NightlyWorker();
