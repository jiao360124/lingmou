// openclaw-3.0/core/route-engine.js
// 智能路由引擎 - 跨 Provider Fallback

const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/route-engine.log', level: 'info' }),
    new winston.transports.Console({ format: winston.format.simple() })
  ]
});

class RouteEngine {
  constructor(config = {}) {
    this.models = config.models || [];
    this.providers = {};
    this.modelHealth = {};
    this.costThreshold = config.costThreshold || 100; // 月成本阈值（$）
    this.taskRoutingRules = config.taskRoutingRules || {};

    // 初始化
    this.initializeProviders();
    this.initializeModelHealth();
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

    // 初始化 ZAI Provider
    try {
      const zaiProvider = require('../providers/zai-provider.js');
      this.providers['zai'] = {
        name: 'ZAI GLM',
        client: zaiProvider,
        config: zaiConfig
      };
      logger.info('✅ ZAI Provider initialized');
    } catch (error) {
      logger.error('❌ ZAI Provider initialization failed:', {
        message: error.message,
        stack: error.stack
      });
    }

    // 初始化 OpenRouter Provider
    try {
      const openrouterProvider = require('../providers/openrouter.js');
      this.providers['openrouter'] = {
        name: 'OpenRouter Trinity',
        client: openrouterProvider,
        config: openrouterConfig
      };
      logger.info('✅ OpenRouter Provider initialized');
    } catch (error) {
      logger.error('❌ OpenRouter Provider initialization failed:', {
        message: error.message,
        stack: error.stack
      });
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
        lastCheck: null,
        failureCount: 0,
        consecutiveFailures: 0
      };
    });
  }

  /**
   * 智能路由 - 跨 Provider Fallback
   * @param {Array} messages - 消息数组
   * @param {Object} options - 选项
   * @returns {Promise<Object>} 响应
   */
  async routeChat(messages, options = {}) {
    // 1. 根据任务类型选择基础模型
    const selectedModels = this.selectModelsByTask(options.taskType);

    logger.info({
      action: 'route_chat_start',
      messageCount: messages.length,
      selectedModels: selectedModels.map(m => m.alias),
      taskType: options.taskType
    });

    // 2. 按优先级尝试每个模型
    for (const modelConfig of selectedModels) {
      try {
        const result = await this.tryModel(modelConfig, messages, options);
        logger.info({
          action: 'route_chat_success',
          model: modelConfig.alias,
          provider: modelConfig.provider,
          fallbackChain: options.fallbackChain
        });
        return result;
      } catch (error) {
        const errorMessage = error.message.toLowerCase();

        // 记录失败
        this.recordFailure(modelConfig.id, errorMessage);

        logger.warn({
          action: 'route_chat_failed',
          model: modelConfig.alias,
          provider: modelConfig.provider,
          error: error.message || 'Unknown error',
          errorType: error.code || 'N/A'
        });

        // 如果是免费模型失败，跳过（不重试免费模型）
        if (modelConfig.provider === 'openrouter' && modelConfig.isFree) {
          logger.info({
            action: 'skip_free_model',
            model: modelConfig.alias,
            reason: 'free_model_already_failed'
          });
          continue;
        }

        // 继续尝试下一个模型
        continue;
      }
    }

    // 3. 所有模型都失败
    logger.error({
      action: 'route_chat_all_failed',
      selectedModels: selectedModels.map(m => m.alias),
      fallbackChain: options.fallbackChain
    });

    throw new Error('All models failed');
  }

  /**
   * 根据任务类型选择模型
   * @param {string} taskType - 任务类型
   * @returns {Array} 模型配置数组
   */
  selectModelsByTask(taskType) {
    const rules = this.taskRoutingRules;
    let selectedModels = [];

    if (rules[taskType]) {
      // 使用自定义路由规则
      const modelIds = rules[taskType].models || [];
      selectedModels = this.models.filter(m => modelIds.includes(m.id));
    } else {
      // 使用默认路由（按 Tier 降级）
      selectedModels = this.models
        .filter(m => m.tier <= 2) // 默认只使用 Tier 1-2
        .sort((a, b) => a.tier - b.tier);
    }

    return selectedModels;
  }

  /**
   * 尝试调用单个模型
   * @param {Object} modelConfig - 模型配置
   * @param {Array} messages - 消息数组
   * @param {Object} options - 选项
   * @returns {Promise<Object>} 响应
   */
  async tryModel(modelConfig, messages, options = {}) {
    const provider = this.providers[modelConfig.provider];

    if (!provider) {
      throw new Error(`Provider ${modelConfig.provider} not found`);
    }

    logger.info({
      action: 'try_model',
      model: modelConfig.alias,
      provider: provider.name,
      tier: modelConfig.tier,
      isFallback: modelConfig.fallback
    });

    // 检查模型健康状态
    if (this.modelHealth[modelConfig.id]?.isUnhealthy) {
      throw new Error(`Model ${modelConfig.alias} is unhealthy`);
    }

    // 调用 Provider
    const result = await provider.client.chat(messages, options);

    // 记录成功
    this.recordSuccess(modelConfig.id);

    return result;
  }

  /**
   * 记录失败
   * @param {string} modelId - 模型ID
   * @param {string} errorMessage - 错误消息
   */
  recordFailure(modelId, errorMessage) {
    const health = this.modelHealth[modelId];

    if (health) {
      health.failureCount++;
      health.consecutiveFailures++;

      // 连续失败3次，标记为不健康
      if (health.consecutiveFailures >= 3) {
        health.isUnhealthy = true;
        logger.warn({
          action: 'model_marked_unhealthy',
          modelId,
          consecutiveFailures: health.consecutiveFailures
        });
      }
    }

    logger.warn({
      action: 'model_failed',
      modelId,
      error: errorMessage,
      failureCount: health?.failureCount || 0
    });
  }

  /**
   * 记录成功
   * @param {string} modelId - 模型ID
   */
  recordSuccess(modelId) {
    const health = this.modelHealth[modelId];

    if (health) {
      health.consecutiveFailures = 0;
      health.isUnhealthy = false;
      health.lastCheck = new Date().toISOString();
    }

    logger.info({
      action: 'model_success',
      modelId,
      lastCheck: health?.lastCheck
    });
  }

  /**
   * 检查成本是否超过阈值
   * @returns {boolean} 是否超过阈值
   */
  isCostThresholdExceeded() {
    // TODO: 实现成本检测
    return false;
  }

  /**
   * 获取路由引擎状态
   * @returns {Object} 状态信息
   */
  getStatus() {
    return {
      models: this.models.map(m => ({
        id: m.id,
        alias: m.alias,
        provider: m.provider,
        tier: m.tier,
        isFree: m.isFree,
        isFallback: m.fallback,
        health: this.modelHealth[m.id] || { isUnhealthy: false }
      })),
      providers: Object.keys(this.providers).map(p => ({
        name: this.providers[p].name
      })),
      modelHealth: this.modelHealth,
      costThreshold: this.costThreshold,
      taskRoutingRules: this.taskRoutingRules
    };
  }
}

module.exports = new RouteEngine();
module.exports.RouteEngineClass = RouteEngine;
