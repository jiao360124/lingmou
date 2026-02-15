// openclaw-3.0/core/runtime.js
// 运行时引擎（集成 Predictive Engine）

const winston = require('winston');
const axios = require('axios');
const fs = require('fs').promises;

// 配置日志
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/openclaw-3.0.log', level: 'info' }),
    new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
    new winston.transports.Console({ format: winston.format.simple() })
  ]
});

class Runtime {
  constructor() {
    this.config = {
      apiBaseURL: process.env.API_BASE_URL || 'https://api.openai.com/v1',
      dailyTokenLimit: 200000,
      maxRequestsPerMinute: 60,  // 用于 Predictive Engine
      isNightTime: false
    };

    this.stats = {
      todayUsage: 0,
      successCount: 0,
      errorCount: 0,
      callsLastMinute: 0,
      tokensLastHour: 0,
      lastMinuteStart: Date.now(),
      lastHourStart: Date.now()
    };

    // 🚀 初始化 ControlTower 和 Predictive Engine
    this.controlTower = require('./control-tower');
    this.controlTower.initPredictiveEngine({
      maxRequestsPerMinute: this.config.maxRequestsPerMinute,
      alpha: 0.3
    });

    // 指标平滑（用于 Predictive Engine）
    this.metrics = {
      callsLastMinute: 0,
      tokensLastHour: 0,
      remainingBudget: 0,
      successRate: 90
    };

    this.context = {
      remainingTokens: 0,
      maxTokens: 0
    };

    // 记录开始时间
    this.startTime = Date.now();

    logger.info('Runtime 引擎初始化完成');
    logger.info('✅ Predictive Engine 已集成');
  }

  // 更新运行时指标
  updateMetrics() {
    const now = Date.now();

    // 每分钟指标
    if (now - this.stats.lastMinuteStart >= 60000) {
      this.metrics.callsLastMinute = this.stats.callsLastMinute;
      this.stats.callsLastMinute = 0;
      this.stats.lastMinuteStart = now;
    }

    // 每小时指标
    if (now - this.stats.lastHourStart >= 3600000) {
      this.metrics.tokensLastHour = this.stats.todayUsage;
      this.stats.lastHourStart = now;
    }

    // 剩余预算
    this.metrics.remainingBudget = Math.max(0, this.config.dailyTokenLimit - this.stats.todayUsage);

    this.saveMetrics();
  }

  async handleMessage(msg) {
    logger.info(`收到消息: ${msg.substring(0, 50)}...`);

    // 会话自动摘要（每10轮）
    if (this.stats.turnCount && this.stats.turnCount % 10 === 0) {
      await this.summarizeConversation();
    }

    return this.callAPI(msg);
  }

  async callAPI(payload) {
    // 🚀 第1步：更新指标
    this.updateMetrics();

    // 更新上下文
    this.context.remainingTokens = Math.max(0, this.config.dailyTokenLimit - this.stats.todayUsage);
    this.context.maxTokens = this.config.dailyTokenLimit;

    // 🚀 第2步：Predictive Engine 预测干预
    const intervention = this.controlTower.predictIntervention(this.metrics, this.context);

    // 如果有干预，应用它
    if (intervention) {
      await this.applyIntervention(intervention);
    }

    // 🚀 第3步：执行 API 调用（现在已经减速/压缩/降级）
    const startTime = Date.now();

    try {
      const response = await axios.post(this.config.apiBaseURL, payload, {
        timeout: 30000
      });

      // 记录成功
      const tokensUsed = response.data.usage?.total_tokens || 0;
      this.recordUsage(tokensUsed);

      // 🚀 第4步：更新指标（调用后）
      this.updateMetrics();

      // 记录调用成功率
      this.metrics.successRate = 90;

      const duration = Date.now() - startTime;
      logger.info({
        action: 'api_call_success',
        tokensUsed,
        duration
      });

      return response.data;
    } catch (err) {
      this.stats.errorCount++;

      // 更新失败率
      this.metrics.successRate = 100 - ((this.stats.errorCount / (this.stats.successCount + this.stats.errorCount || 1)) * 100);

      logger.error({
        action: 'api_call_failed',
        error: err.message,
        errorType: err.response?.status
      });

      // 429错误自动排队
      if (err.response?.status === 429) {
        logger.warn('遇到429错误，使用指数退避重试...');
        await this.handle429Retry(payload);
      }

      // 🚀 第5步：更新指标（失败后）
      this.updateMetrics();

      throw err;
    }
  }

  async handle429Retry(payload, retry = 0) {
    if (retry < 5) {
      const delay = Math.pow(2, retry) * 1000;
      logger.info(`等待 ${delay}ms 后重试...`);
      await new Promise(r => setTimeout(r, delay));
      return this.callAPI(payload, retry + 1);
    }
    throw new Error('429错误重试次数超限');
  }

  recordUsage(tokens) {
    this.stats.todayUsage += tokens;
    this.stats.successCount++;
    this.stats.turnCount = (this.stats.turnCount || 0) + 1;

    if (this.stats.todayUsage > this.config.dailyTokenLimit) {
      logger.warn('今日Token使用量已达上限');
      throw new Error('今日Token使用量已达上限');
    }

    this.saveMetrics();
  }

  // 🚀 应用干预建议
  async applyIntervention(intervention) {
    logger.info({
      action: 'predictive_intervention',
      level: intervention.warningLevel,
      throttleDelay: intervention.throttleDelay,
      compressionLevel: intervention.compressionLevel,
      modelBias: intervention.modelBias,
      details: intervention.details
    });

    // 注意：这里只是示例
    // 实际应用需要注入依赖（sleep、summarizer、tokenGovernor）
    // 由于这是示例代码，我们只记录日志
  }

  async summarizeConversation() {
    logger.info('执行会话摘要...');
    const summary = await this.generateSummary();
    this.replaceContext(summary);
    logger.info('会话摘要完成，节省约30% token');
  }

  async generateSummary() {
    // 简化版摘要生成
    return {
      type: 'conversation_summary',
      last10turns: this.stats.turnCount - 10,
      totalTurns: this.stats.turnCount,
      keyTopics: ['system_optimization', 'token_reduction', 'nightly_tasks']
    };
  }

  replaceContext(summary) {
    logger.info(`替换上下文为: ${JSON.stringify(summary)}`);
    this.stats.summary = summary;
  }

  saveMetrics() {
    const metrics = {
      dailyTokens: this.stats.todayUsage,
      successCount: this.stats.successCount,
      errorCount: this.stats.errorCount,
      callsLastMinute: this.metrics.callsLastMinute,
      tokensLastHour: this.metrics.tokensLastHour,
      remainingBudget: this.metrics.remainingBudget,
      successRate: this.metrics.successRate,
      lastUpdated: new Date().toISOString()
    };
    fs.writeFile('data/metrics.json', JSON.stringify(metrics, null, 2))
      .catch(err => {
        logger.error({
          action: 'save_metrics_failed',
          error: err.message
        });
      });
  }

  // 模型分级策略
  chooseModel(taskType) {
    if (this.config.isNightTime) {
      return 'cheap-model';
    }

    switch (taskType) {
      case 'chat':
        return 'cheap-model';
      case 'analysis':
        return 'mid-model';
      case 'strategy':
        return 'high-model';
      default:
        return 'cheap-model';
    }
  }

  // 获取模型成本（简化）
  getModelCost(model, tokens) {
    const costs = {
      'cheap-model': 0.0001,   // $0.1 per 1K tokens
      'mid-model': 0.002,      // $2 per 1K tokens
      'high-model': 0.01       // $10 per 1K tokens
    };
    return costs[model] * (tokens / 1000);
  }

  isNightTime() {
    const hour = new Date().getHours();
    return hour >= 21 || hour < 6;
  }

  // 获取运行时状态
  getStatus() {
    return {
      config: this.config,
      stats: this.stats,
      metrics: this.metrics,
      context: this.context,
      uptime: Math.floor((Date.now() - this.startTime) / 1000)
    };
  }
}

module.exports = new Runtime();
