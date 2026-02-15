// openclaw-3.0/core/runtime-v2.js
// 运行时引擎（集成 Predictive Engine + Route Engine）

const winston = require('winston');
const fs = require('fs').promises;

// 配置日志
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/openclaw-v2.log', level: 'info' }),
    new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
    new winston.transports.Console({ format: winston.format.simple() })
  ]
});

class Runtime {
  constructor() {
    this.config = {
      apiBaseURL: process.env.API_BASE_URL || 'https://api.zhipuai.cn/v4',
      dailyTokenLimit: 200000,
      maxRequestsPerMinute: 60,
      isNightTime: false
    };

    this.stats = {
      todayUsage: 0,
      successCount: 0,
      errorCount: 0,
      callsLastMinute: 0,
      tokensLastHour: 0,
      lastMinuteStart: Date.now(),
      lastHourStart: Date.now(),
      monthlyCost: 0
    };

    // 🚀 初始化控制塔和预测引擎
    this.controlTower = require('./control-tower');
    this.controlTower.initPredictiveEngine({
      maxRequestsPerMinute: this.config.maxRequestsPerMinute,
      alpha: 0.3
    });

    // 🚀 初始化路由引擎
    const RouteEngineClass = require('./route-engine').RouteEngineClass;

    // 定义模型配置
    const models = [
      {
        id: 'zai/glm-4.7-flash',
        alias: 'GLM',
        provider: 'zai',
        tier: 1
      },
      {
        id: 'zai/glm-4.5-flash',
        alias: 'GLM-450',
        provider: 'zai',
        tier: 2
      },
      {
        id: 'zai/glm-4-flash-250414',
        alias: 'GLM-4-2504',
        provider: 'zai',
        tier: 3
      },
      {
        id: 'arcee-ai/trinity-large-preview:free',
        alias: 'TRINITY-FREE',
        provider: 'openrouter',
        tier: 4,
        fallback: true
      }
    ];

    this.routeEngine = new RouteEngineClass({
      models: models,
      costThreshold: 100,
      taskRoutingRules: {
        long_reasoning: {
          models: ['zai/glm-4.5-flash', 'arcee-ai/trinity-large-preview:free'],
          reason: '适合长文本推理'
        },
        tool_call: {
          models: ['zai/glm-4.7-flash', 'zai/glm-4.5-flash'],
          reason: '快速工具调用'
        },
        default: {
          models: ['zai/glm-4.7-flash', 'zai/glm-4.5-flash'],
          reason: '通用任务'
        }
      }
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

    logger.info('Runtime v2 引擎初始化完成');
    logger.info('✅ Predictive Engine 已集成');
    logger.info('✅ Route Engine 已集成（Trinity 多供应商架构）');
  }

  /**
   * 更新运行时指标
   */
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

  /**
   * 消息处理（使用路由引擎）
   * @param {string} msg - 消息内容
   * @param {Object} options - 选项
   * @returns {Promise<Object>} 响应
   */
  async handleMessage(msg, options = {}) {
    logger.info(`收到消息: ${msg.substring(0, 50)}...`);

    // 更新指标
    this.updateMetrics();

    // 上下文设置
    this.context.remainingTokens = Math.max(0, this.config.dailyTokenLimit - this.stats.todayUsage);
    this.context.maxTokens = this.config.dailyTokenLimit;

    // 🚀 第1步：预测干预
    const intervention = this.controlTower.predictIntervention(this.metrics, this.context);

    // 如果有干预，应用它
    if (intervention) {
      await this.applyIntervention(intervention);
    }

    // 🚀 第2步：智能路由（使用路由引擎）
    try {
      const response = await this.routeEngine.routeChat(
        [{ role: 'user', content: msg }],
        {
          taskType: options.taskType || 'default',
          ...options
        }
      );

      // 记录成功
      const tokensUsed = this.extractTokens(response);
      this.recordUsage(tokensUsed);

      // 🚀 第3步：更新指标（调用后）
      this.updateMetrics();

      // 记录调用成功率
      this.metrics.successRate = 90;

      logger.info({
        action: 'message_processed',
        model: response.model || 'unknown',
        tokensUsed
      });

      return this.formatResponse(response);
    } catch (error) {
      this.stats.errorCount++;

      // 更新失败率
      this.metrics.successRate = 100 - ((this.stats.errorCount / (this.stats.successCount + this.stats.errorCount || 1)) * 100);

      logger.error({
        action: 'message_processing_failed',
        error: error.message
      });

      throw error;
    }
  }

  /**
   * 格式化响应
   * @param {Object} response - 原始响应
   * @returns {Object} 格式化后的响应
   */
  formatResponse(response) {
    if (response.choices && response.choices[0]) {
      return {
        content: response.choices[0].message.content,
        model: response.model,
        usage: response.usage
      };
    }
    return response;
  }

  /**
   * 提取 Token 使用量
   * @param {Object} response - 响应
   * @returns {number} Token 数量
   */
  extractTokens(response) {
    if (response.usage && response.usage.total_tokens) {
      return response.usage.total_tokens;
    }
    // 估算：假设输入2000 token，输出根据内容估算
    return 2000 + response.content?.length * 0.5 || 2000;
  }

  /**
   * 保存指标
   */
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

  /**
   * 记录使用量
   * @param {number} tokens - Token 数量
   */
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

  /**
   * 应用干预建议
   */
  async applyIntervention(intervention) {
    logger.info({
      action: 'predictive_intervention',
      level: intervention.warningLevel,
      throttleDelay: intervention.throttleDelay,
      compressionLevel: intervention.compressionLevel,
      modelBias: intervention.modelBias
    });
  }

  /**
   * 获取运行时状态
   * @returns {Object} 状态信息
   */
  getStatus() {
    return {
      config: this.config,
      stats: this.stats,
      metrics: this.metrics,
      context: this.context,
      routeEngine: this.routeEngine.getStatus(),
      controlTower: this.controlTower.getStatus(),
      uptime: Math.floor((Date.now() - this.startTime) / 1000)
    };
  }
}

module.exports = new Runtime();
