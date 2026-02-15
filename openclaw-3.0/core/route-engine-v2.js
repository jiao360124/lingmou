// openclaw-3.0/core/route-engine-v2.js
// 智能路由引擎 - 增强版（支持 Half-Open、动态评分）

const winston = require('winston');
const ScoreEngine = require('./score-engine');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/route-engine-v2.log', level: 'info' }),
    new winston.transports.Console({ format: winston.format.simple() })
  ]
});

class RouteEngine {
  constructor(config = {}) {
    this.models = config.models || [];
    this.providers = {};
    this.modelHealth = {};
    this.requestIdCounter = 1;
    this.lastRequestLogs = [];

    // 初始化 Provider
    this.initializeProviders();

    // 初始化模型健康状态
    this.initializeModelHealth();

    // 🚀 动态评分引擎
    this.scoreEngine = ScoreEngine;
  }

  /**
   * 初始化 Provider
   */
  initializeProviders() {
    const zaiConfig = {
      apiKey: process.env.ZAI_API_KEY || 'BSAd4FWdcg5FrJayT__vdMet0vzcKHK',
      baseUrl: 'https://api.zhipuai.cn/v4'
    };

    const openrouterConfig = {
      apiKey: process.env.OPENROUTER_API_KEY,
      model: 'arcee-ai/trinity-large-preview:free'
    };

    logger.info('🔧 Starting provider initialization...');

    try {
      const zaiProvider = require('./providers/zai-provider.js');
      this.providers['zai'] = {
        name: 'ZAI GLM',
        client: zaiProvider,
        config: zaiConfig
      };
      logger.info('✅ ZAI Provider initialized');
    } catch (error) {
      logger.error('❌ ZAI Provider initialization failed:', error.message);
    }

    try {
      const openrouterProvider = require('./providers/openrouter.js');
      this.providers['openrouter'] = {
        name: 'OpenRouter Trinity',
        client: openrouterProvider,
        config: openrouterConfig
      };
      logger.info('✅ OpenRouter Provider initialized');
    } catch (error) {
      logger.error('❌ OpenRouter Provider initialization failed:', error.message);
    }

    logger.info(`🔧 Provider initialization complete. Available providers: ${Object.keys(this.providers).join(', ')}`);
  }

  /**
   * 初始化模型健康状态
   */
  initializeModelHealth() {
    this.models.forEach(model => {
      this.modelHealth[model.id] = {
        isUnhealthy: false,
        isHalfOpen: false,
        lastCheck: Date.now(),
        lastFailTime: null,
        consecutiveFailures: 0,
        failureTimes: []
      };
    });
  }

  /**
   * 生成请求 ID
   * @returns {string} 请求 ID
   */
  generateRequestId() {
    return `req_${Date.now()}_${this.requestIdCounter++}`;
  }

  /**
   * 智能路由 - 增强版
   * @param {Array} messages - 消息数组
   * @param {Object} options - 选项
   * @returns {Promise<Object>} 响应
   */
  async routeChat(messages, options = {}) {
    const requestId = this.generateRequestId();
    let fallbackCount = 0;
    const fallbackChain = [];

    // 🚀 使用动态评分选择初始模型
    const initialModel = this.selectBestModelByScore();
    const modelsToTry = initialModel ? [initialModel, ...this.models.filter(m => m.id !== initialModel?.id)] : this.models;

    logger.info({
      action: 'route_chat_start',
      requestId,
      initialModel: initialModel?.id || 'none',
      messageCount: messages.length,
      modelsToTry: modelsToTry.map(m => m.id),
      taskType: options.taskType
    });

    // 按优先级尝试每个模型
    for (const modelConfig of modelsToTry) {
      try {
        const startTime = Date.now();
        const result = await this.tryModel(modelConfig, messages, options, requestId);
        const latency = Date.now() - startTime;

        fallbackCount = this.modelHealth[modelConfig.id]?.consecutiveFailures || 0;

        logger.info({
          action: 'route_chat_success',
          requestId,
          model: modelConfig.alias,
          provider: modelConfig.provider,
          fallbackCount,
          latency,
          costEstimate: this.estimateCost(modelConfig, messages.length)
        });

        // 🚀 记录请求日志
        this.scoreEngine.recordRequest({
          requestId,
          chosenModel: modelConfig.id,
          fallbackCount,
          latency,
          costEstimate: this.estimateCost(modelConfig, messages.length),
          errorType: null,
          success: true,
          taskType: options.taskType
        });

        // 🚀 记录模型使用
        this.scoreEngine.recordUsage(modelConfig.id, true, { latency });

        return result;
      } catch (error) {
        const errorMessage = error.message.toLowerCase();
        const errorType = this.detectErrorType(error);

        // 记录失败
        this.recordFailure(modelConfig.id, errorType);

        logger.warn({
          action: 'route_chat_failed',
          requestId,
          model: modelConfig.alias,
          provider: modelConfig.provider,
          error: error.message,
          errorType,
          fallbackCount,
          fallbackChain: [...fallbackChain, modelConfig.alias]
        });

        // 🚀 记录失败到日志
        this.scoreEngine.recordRequest({
          requestId,
          chosenModel: modelConfig.id,
          fallbackCount: this.modelHealth[modelConfig.id]?.consecutiveFailures || 0,
          latency: 0,
          costEstimate: 0,
          errorType,
          success: false,
          taskType: options.taskType
        });

        // 🚀 记录失败使用
        this.scoreEngine.recordUsage(modelConfig.id, false, { errorType });

        fallbackChain.push(modelConfig.alias);
        fallbackCount++;

        // 如果是免费模型失败，跳过
        if (modelConfig.provider === 'openrouter' && modelConfig.isFree) {
          logger.info({
            action: 'skip_free_model',
            model: modelConfig.alias,
            reason: 'free_model_already_failed'
          });
          continue;
        }

        continue;
      }
    }

    // 所有模型都失败
    logger.error({
      action: 'route_chat_all_failed',
      requestId,
      modelsTried: modelsToTry.map(m => m.alias),
      fallbackChain
    });

    throw new Error('All models failed');
  }

  /**
   * 使用动态评分选择最佳模型
   * @returns {Object|null} 最佳模型配置
   */
  selectBestModelByScore() {
    const models = this.models.filter(m => {
      // 只考虑健康的模型
      const health = this.modelHealth[m.id];
      return !health?.isUnhealthy && !health?.isHalfOpen;
    });

    if (models.length === 0) {
      logger.warn('No healthy models available');
      return null;
    }

    // 使用评分引擎选择最佳模型
    const bestModel = this.scoreEngine.selectBestModel(models);

    if (!bestModel) {
      logger.warn('No model selected by score engine');
      return null;
    }

    const modelConfig = models.find(m => m.id === bestModel);
    return modelConfig;
  }

  /**
   * 尝试调用单个模型
   */
  async tryModel(modelConfig, messages, options, requestId) {
    const provider = this.providers[modelConfig.provider];

    if (!provider) {
      throw new Error(`Provider ${modelConfig.provider} not found`);
    }

    logger.info({
      action: 'try_model',
      requestId,
      model: modelConfig.alias,
      provider: provider.name,
      tier: modelConfig.tier,
      isFallback: modelConfig.fallback
    });

    // 检查模型健康状态
    const health = this.modelHealth[modelConfig.id];

    if (health?.isUnhealthy && !health?.isHalfOpen) {
      throw new Error(`Model ${modelConfig.alias} is unhealthy`);
    }

    // 如果是 Half-Open 状态，允许尝试
    if (health?.isHalfOpen) {
      logger.info({
        action: 'model_half_open_attempt',
        model: modelConfig.alias,
        isHalfOpen: true
      });
    }

    // 调用 Provider
    const result = await provider.client.chat(messages, options);

    // 🚀 记录成功
    this.recordSuccess(modelConfig.id, requestId);

    return result;
  }

  /**
   * 记录失败
   */
  recordFailure(modelId, errorType) {
    const health = this.modelHealth[modelId];

    if (!health) return;

    health.consecutiveFailures++;
    health.failureTimes.push(Date.now());

    // 保留最近 10 次失败
    if (health.failureTimes.length > 10) {
      health.failureTimes.shift();
    }

    // 判断 Half-Open 状态
    if (health.consecutiveFailures >= 3) {
      health.isUnhealthy = true;
      health.isHalfOpen = false;

      // 🚀 Half-Open 恢复：10分钟后自动测试
      this.scheduleHalfOpenTest(modelId);
    }

    logger.warn({
      action: 'model_failed',
      modelId,
      errorType,
      consecutiveFailures: health.consecutiveFailures,
      isUnhealthy: health.isUnhealthy,
      isHalfOpen: health.isHalfOpen
    });
  }

  /**
   * 安排 Half-Open 恢复测试
   * @param {string} modelId - 模型ID
   */
  scheduleHalfOpenTest(modelId) {
    const health = this.modelHealth[modelId];

    if (!health) return;

    // 设置 10 分钟后半开测试
    const testTime = Date.now() + this.config.halfOpenRecoveryTime;

    logger.info({
      action: 'half_open_recovery_scheduled',
      modelId,
      testTime: new Date(testTime).toISOString(),
      delay: this.config.halfOpenRecoveryTime
    });

    // TODO: 使用定时任务执行 Half-Open 测试
    // 当前简化：立即尝试恢复
    this.tryHalfOpenRecovery(modelId);
  }

  /**
   * 尝试 Half-Open 恢复
   * @param {string} modelId - 模型ID
   */
  async tryHalfOpenRecovery(modelId) {
    const health = this.modelHealth[modelId];

    if (!health || !health.isUnhealthy) return;

    logger.info({
      action: 'half_open_recovery_attempt',
      modelId,
      isUnhealthy: health.isUnhealthy,
      isHalfOpen: health.isHalfOpen
    });

    try {
      health.isHalfOpen = true;

      const modelConfig = this.models.find(m => m.id === modelId);

      // 尝试简单测试
      const testMessages = [{ role: 'user', content: 'Hi' }];
      const result = await this.tryModel(modelConfig, testMessages, { stream: false }, this.generateRequestId());

      // 测试成功，恢复健康
      this.recordSuccess(modelId, this.generateRequestId());

      logger.info({
        action: 'half_open_recovery_success',
        modelId,
        newHealth: 'healthy'
      });
    } catch (error) {
      // 测试失败，继续保持不健康
      logger.warn({
        action: 'half_open_recovery_failed',
        modelId,
        error: error.message
      });
    }
  }

  /**
   * 记录成功
   */
  recordSuccess(modelId, requestId) {
    const health = this.modelHealth[modelId];

    if (!health) return;

    health.consecutiveFailures = 0;
    health.isUnhealthy = false;
    health.isHalfOpen = false;
    health.lastCheck = Date.now();

    logger.info({
      action: 'model_success',
      modelId,
      consecutiveFailures: 0,
      lastCheck: health.lastCheck
    });
  }

  /**
   * 检测错误类型
   * @param {Error} error - 错误对象
   * @returns {string} 错误类型
   */
  detectErrorType(error) {
    const message = error.message.toLowerCase();

    if (message.includes('rate limit') || message.includes('429')) {
      return 'rate_limit';
    } else if (message.includes('insufficient funds') || message.includes('balance')) {
      return 'insufficient_funds';
    } else if (message.includes('network') || message.includes('timeout')) {
      return 'network_error';
    } else {
      return 'other';
    }
  }

  /**
   * 估算成本
   * @param {Object} modelConfig - 模型配置
   * @param {number} messageCount - 消息数量
   * @returns {number} 估算成本（美元）
   */
  estimateCost(modelConfig, messageCount) {
    // 简化估算：输入 2000 tokens, 输出 500 tokens
    const inputTokens = 2000;
    const outputTokens = 500;
    const totalTokens = (inputTokens * messageCount) + outputTokens;

    // 不同模型的成本
    const costs = {
      'zai/glm-4.7-flash': 0.0001,   // $0.1 per 1K tokens
      'zai/glm-4.5-flash': 0.00005,  // $0.05 per 1K tokens
      'zai/glm-4-flash-250414': 0.00002, // $0.02 per 1K tokens
      'arcee-ai/trinity-large-preview:free': 0
    };

    const costPer1k = costs[modelConfig.id] || 0.0001;
    return (totalTokens / 1000) * costPer1k;
  }

  /**
   * 检查是否应该切换到 Trinity
   * @returns {boolean} 是否应该切换
   */
  shouldSwitchToTrinity() {
    const zaiHealth = this.modelHealth['zai/glm-4.7-flash'];

    // ZAI 健康度 < 50%，切换到 Trinity
    if (zaiHealth && zaiHealth.isUnhealthy) {
      return true;
    }

    return false;
  }

  /**
   * 获取路由引擎状态
   */
  getStatus() {
    return {
      models: this.models.map(m => ({
        id: m.id,
        alias: m.alias,
        provider: m.provider,
        tier: m.tier,
        isFree: m.isFree,
        health: this.modelHealth[m.id] || { isUnhealthy: false, isHalfOpen: false }
      })),
      providers: Object.keys(this.providers).map(p => ({
        name: this.providers[p].name
      })),
      modelHealth: this.modelHealth,
      scoreEngine: this.scoreEngine.getStatus(),
      shouldSwitchToTrinity: this.shouldSwitchToTrinity()
    };
  }

  /**
   * 获取请求日志
   */
  getRequestLogs(limit = 100) {
    return this.scoreEngine.getRequestLogs(limit);
  }

  /**
   * 获取模型使用统计
   */
  getModelStats() {
    return this.scoreEngine.getModelStats();
  }
}

module.exports = new RouteEngine();
