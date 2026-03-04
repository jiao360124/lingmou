// openclaw-3.0/core/score-engine.js
// 动态评分引擎 - 自适应模型调度

const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/score-engine.log', level: 'info' }),
    new winston.transports.Console({ format: winston.format.simple() })
  ]
});

class ScoreEngine {
  constructor(config = {}) {
    this.config = {
      qualityWeight: config.qualityWeight || 0.35,     // 质量权重
      costWeight: config.costWeight || 0.25,           // 成本权重
      latencyWeight: config.latencyWeight || 0.20,     // 延迟权重
      failureWeight: config.failureWeight || 0.20,     // 失败权重
      halfOpenRecoveryTime: config.halfOpenRecoveryTime || 10 * 60 * 1000, // 10分钟
      healthThreshold: config.healthThreshold || 0.5,  // 健康度阈值 50%
      dynamicTier: config.dynamicTier !== false        // 动态 Tier
    };

    this.modelScores = {};
    this.requestLogs = [];

    // 初始化
    this.initializeScores();
  }

  /**
   * 初始化模型分数
   */
  initializeScores() {
    // 默认分数（运行时动态更新）
    this.modelScores = {
      'zai/glm-4.7-flash': {
        score: 80,
        quality: 0.85,
        cost: 0.90,
        latency: 0.85,
        failure: 0.90,
        health: 1.0,
        useCount: 0,
        successCount: 0,
        failureCount: 0
      },
      'zai/glm-4.5-flash': {
        score: 75,
        quality: 0.82,
        cost: 0.95,
        latency: 0.82,
        failure: 0.85,
        health: 1.0,
        useCount: 0,
        successCount: 0,
        failureCount: 0
      },
      'zai/glm-4-flash-250414': {
        score: 70,
        quality: 0.78,
        cost: 1.0,
        latency: 0.78,
        failure: 0.80,
        health: 1.0,
        useCount: 0,
        successCount: 0,
        failureCount: 0
      },
      'arcee-ai/trinity-large-preview:free': {
        score: 85,
        quality: 0.88,
        cost: 1.0,  // 免费成本
        latency: 0.75,  // 稍慢
        failure: 0.95,
        health: 1.0,
        useCount: 0,
        successCount: 0,
        failureCount: 0
      }
    };
  }

  /**
   * 计算模型得分
   * @param {string} modelId - 模型ID
   * @returns {number} 得分（0-100）
   */
  calculateScore(modelId) {
    const model = this.modelScores[modelId];

    if (!model) {
      logger.warn(`Model ${modelId} not found in score engine`);
      return 0;
    }

    // 应用权重
    const score = (
      model.quality * this.config.qualityWeight +
      model.cost * this.config.costWeight +
      model.latency * this.config.latencyWeight +
      model.failure * this.config.failureWeight
    );

    // 如果动态 Tier，考虑健康度
    if (this.config.dynamicTier) {
      const healthyScore = score * model.health;
      logger.info({
        action: 'model_score_calculated',
        modelId,
        score: score.toFixed(2),
        healthyScore: healthyScore.toFixed(2),
        health: model.health
      });
      return healthyScore;
    }

    return score;
  }

  /**
   * 选择最佳模型
   * @param {Array} models - 模型列表
   * @returns {string|null} 最佳模型ID
   */
  selectBestModel(models) {
    if (!models || models.length === 0) {
      logger.warn('No models available for selection');
      return null;
    }

    let bestModel = null;
    let highestScore = -1;

    for (const model of models) {
      const score = this.calculateScore(model.id);
      logger.info({
        action: 'model_score_for_selection',
        modelId: model.id,
        alias: model.alias,
        score: score.toFixed(2)
      });

      if (score > highestScore) {
        highestScore = score;
        bestModel = model.id;
      }
    }

    logger.info({
      action: 'best_model_selected',
      modelId: bestModel,
      score: highestScore.toFixed(2)
    });

    return bestModel;
  }

  /**
   * 记录模型使用结果
   * @param {string} modelId - 模型ID
   * @param {boolean} success - 是否成功
   * @param {Object} metrics - 性能指标
   */
  recordUsage(modelId, success, metrics = {}) {
    const model = this.modelScores[modelId];

    if (!model) {
      logger.warn(`Model ${modelId} not found`);
      return;
    }

    model.useCount++;
    model.health = Math.max(0, Math.min(1, model.health)); // 限制在 0-1

    if (success) {
      model.successCount++;
      // 成功后恢复健康度
      model.health = Math.min(1, model.health + 0.05);
    } else {
      model.failureCount++;

      // 记录失败
      const failureFactors = {
        rate_limit: 0.1,
        insufficient_funds: 0.2,
        network_error: 0.05,
        other: 0.15
      };

      const factor = failureFactors[metrics.errorType] || failureFactors.other;
      model.health = Math.max(0, model.health - factor);

      logger.warn({
        action: 'model_usage_recorded',
        modelId,
        success,
        newHealth: model.health.toFixed(2),
        useCount: model.useCount,
        successCount: model.successCount,
        failureCount: model.failureCount
      });
    }

    // 更新分数
    this.updateScore(modelId);
  }

  /**
   * 更新模型分数
   * @param {string} modelId - 模型ID
   */
  updateScore(modelId) {
    const model = this.modelScores[modelId];

    if (!model) return;

    // 质量评分（基于成功率）
    const successRate = model.useCount > 0
      ? model.successCount / model.useCount
      : 1.0;
    model.quality = 0.5 + (successRate * 0.5); // 0.5-1.0

    // 成本评分（越高越好）
    model.cost = model.cost || 0.9;

    // 延迟评分（ms，越高越慢）
    const latency = metrics.latency || 1000;
    model.latency = Math.max(0, 1 - (latency / 5000)); // 0-1

    // 失败惩罚
    model.failure = model.health; // 失败率 = 健康度

    // 计算最终得分
    const score = this.calculateScore(modelId);
    model.score = score;
  }

  /**
   * 记录请求日志
   * @param {Object} log - 日志数据
   */
  recordRequest(log) {
    const requestLog = {
      requestId: log.requestId,
      timestamp: new Date().toISOString(),
      chosenModel: log.chosenModel,
      fallbackCount: log.fallbackCount || 0,
      latency: log.latency,
      costEstimate: log.costEstimate,
      errorType: log.errorType,
      success: log.success !== false,
      taskType: log.taskType
    };

    this.requestLogs.push(requestLog);

    // 限制日志数量（保留最近 1000 条）
    if (this.requestLogs.length > 1000) {
      this.requestLogs.shift();
    }

    logger.info({
      action: 'request_logged',
      requestId: log.requestId,
      model: log.chosenModel,
      success: log.success,
      latency: log.latency
    });
  }

  /**
   * 获取评分引擎状态
   * @returns {Object} 状态信息
   */
  getStatus() {
    const avgScores = [];

    for (const [modelId, model] of Object.entries(this.modelScores)) {
      avgScores.push({
        id: modelId,
        score: model.score,
        health: model.health,
        useCount: model.useCount
      });
    }

    return {
      config: this.config,
      modelScores: this.modelScores,
      requestLogCount: this.requestLogs.length,
      avgScores
    };
  }

  /**
   * 获取请求日志
   * @param {number} limit - 限制数量
   * @returns {Array} 日志列表
   */
  getRequestLogs(limit = 100) {
    return this.requestLogs.slice(-limit);
  }

  /**
   * 获取模型使用统计
   * @returns {Object} 统计数据
   */
  getModelStats() {
    const stats = {};

    for (const [modelId, model] of Object.entries(this.modelScores)) {
      stats[modelId] = {
        useCount: model.useCount,
        successCount: model.successCount,
        failureCount: model.failureCount,
        successRate: model.useCount > 0
          ? (model.successCount / model.useCount * 100).toFixed(2) + '%'
          : 'N/A',
        avgHealth: model.health.toFixed(2)
      };
    }

    return stats;
  }
}

module.exports = new ScoreEngine();
