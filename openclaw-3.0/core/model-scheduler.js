// openclaw-3.0/core/model-scheduler.js
// 自适应模型调度系统 - 基于评分的智能路由

const winston = require('winston');

// 日志配置
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/model-scheduler.log' }),
    new winston.transports.Console({ format: winston.format.simple() })
  ]
});

/**
 * 🎯 模型评分引擎
 * 基于质量、成本、延迟、失败率计算总分
 */
class ModelScorer {
  constructor(options = {}) {
    // 权重配置
    this.weights = {
      quality: options.qualityWeight || 0.4,
      cost: options.costWeight || 0.3,
      latency: options.latencyWeight || 0.2,
      failure: options.failureWeight || 0.1
    };

    // 归一化因子（用于标准化不同维度的分数）
    this.normalizers = {
      quality: options.qualityNormalizer || 1.0,
      cost: options.costNormalizer || 1.0,
      latency: options.latencyNormalizer || 1.0,
      failure: options.failureNormalizer || 1.0
    };

    logger.info(`Model Scorer initialized with weights:`, this.weights);
  }

  /**
   * 📊 计算模型分数
   * @param {Object} metrics - 模型指标
   * @param {number} metrics.quality - 质量评分 (0-10)
   * @param {number} metrics.cost - 成本评分 (0-1)
   * @param {number} metrics.latency - 延迟 (ms)
   * @param {number} metrics.failRate - 失败率 (0-1)
   * @returns {Object} { score, details }
   */
  calculateScore(metrics) {
    // 质量评分 (0-10 → 0-10)
    const qualityScore = metrics.quality * this.normalizers.quality;

    // 成本评分 (0-1 → 0-10)
    const costScore = metrics.cost * this.normalizers.cost * 10;

    // 延迟惩罚 (100ms → 10分, 1000ms → 0分)
    const latencyScore = Math.max(0, 10 - (metrics.latency / 100));

    // 失败率惩罚 (0% → 10分, 50% → 0分)
    const failureScore = (1 - metrics.failRate) * 10 * this.normalizers.failure;

    // 综合分数（加权求和）
    const score = (
      qualityScore * this.weights.quality +
      costScore * this.weights.cost +
      latencyScore * this.weights.latency +
      failureScore * this.weights.failure
    );

    const details = {
      qualityScore,
      costScore,
      latencyScore,
      failureScore,
      rawScore: score
    };

    return { score, details };
  }

  /**
   * 📊 评估模型分数等级
   * @param {number} score - 模型分数
   * @returns {string} 分数等级
   */
  evaluateScore(score) {
    if (score >= 9.0) return 'EXCELLENT';
    if (score >= 7.5) return 'GOOD';
    if (score >= 6.0) return 'ACCEPTABLE';
    if (score >= 4.0) return 'POOR';
    return 'CRITICAL';
  }
}

/**
 * 📈 模型健康追踪器
 * 实时追踪每个模型的性能指标
 */
class ModelHealthTracker {
  constructor(options = {}) {
    // 健康度配置
    this.config = {
      historyLength: options.historyLength || 100,
      latencyWindowMs: options.latencyWindowMs || 3600000, // 1 小时
      successWindowMs: options.successWindowMs || 3600000   // 1 小时
    };

    // 模型数据存储
    this.models = new Map();

    // 历史记录（用于趋势分析）
    this.history = [];

    logger.info('Model Health Tracker initialized');
  }

  /**
   * 📝 注册模型
   * @param {string} modelName - 模型名称
   * @param {Object} initialMetrics - 初始指标
   */
  registerModel(modelName, initialMetrics = {}) {
    const now = Date.now();

    const modelData = {
      name: modelName,
      metrics: {
        quality: initialMetrics.quality || 8.0,
        cost: initialMetrics.cost || 0.2,
        latency: initialMetrics.latency || 100,
        failRate: initialMetrics.failRate || 0.02
      },
      stats: {
        successCount: 0,
        failureCount: 0,
        totalLatency: 0,
        callsCount: 0,
        lastSuccessTime: null,
        lastFailureTime: null
      },
      circuitBreaker: null, // 后续连接 Circuit Breaker
      health: 100
    };

    this.models.set(modelName, modelData);

    logger.info(`Model registered: ${modelName}`);
  }

  /**
   * 📡 更新模型指标（成功/失败）
   * @param {string} modelName - 模型名称
   * @param {boolean} success - 是否成功
   * @param {number} latency - 延迟（ms）
   * @param {Error} error - 错误对象
   */
  updateModelMetrics(modelName, success, latency, error = null) {
    const model = this.models.get(modelName);
    if (!model) {
      logger.warn(`Model not found: ${modelName}`);
      return;
    }

    // 更新统计数据
    if (success) {
      model.stats.successCount++;
      model.stats.totalLatency += latency;
      model.stats.callsCount++;
      model.stats.lastSuccessTime = Date.now();
      model.metrics.failRate = Math.max(0, model.metrics.failRate - 0.01); // 成功时降低失败率
    } else {
      model.stats.failureCount++;
      model.stats.callsCount++;
      model.stats.lastFailureTime = Date.now();
      model.metrics.failRate = Math.min(1, model.metrics.failRate + 0.05); // 失败时增加失败率
    }

    // 更新健康度
    this.updateHealth(model);

    // 记录历史
    this.history.push({
      modelName,
      success,
      latency,
      failRate: model.metrics.failRate,
      timestamp: Date.now()
    });

    // 保持历史长度
    if (this.history.length > this.config.historyLength) {
      this.history.shift();
    }

    logger.debug(`Model ${modelName} metrics updated: success=${success}, latency=${latency}ms, failRate=${model.metrics.failRate.toFixed(2)}`);
  }

  /**
   * 📊 更新模型健康度
   * @param {Object} model - 模型数据
   */
  updateHealth(model) {
    // 基础健康度：基于失败率（0-100）
    let health = Math.max(0, 100 - (model.metrics.failRate * 100));

    // 延迟惩罚：延迟 > 500ms 扣分
    if (model.stats.callsCount > 10) {
      const avgLatency = model.stats.totalLatency / model.stats.successCount;
      if (avgLatency > 500) {
        health -= (avgLatency - 500) / 10; // 每超过 500ms 扣 1 分
      }
    }

    model.health = Math.max(0, Math.min(100, health));
  }

  /**
   * 📊 计算模型的综合评分
   * @param {string} modelName - 模型名称
   * @returns {Object} { score, details, level }
   */
  calculateScore(modelName) {
    const model = this.models.get(modelName);
    if (!model) {
      return null;
    }

    // 计算平均指标（考虑历史窗口）
    const recentHistory = this.history.filter(h => h.modelName === modelName);
    const avgLatency = recentHistory.length > 0
      ? recentHistory.reduce((sum, h) => sum + h.latency, 0) / recentHistory.length
      : model.metrics.latency;

    const avgFailRate = recentHistory.length > 0
      ? recentHistory.reduce((sum, h) => sum + h.failRate, 0) / recentHistory.length
      : model.metrics.failRate;

    const scoreResult = scorer.calculateScore({
      quality: model.metrics.quality,
      cost: model.metrics.cost,
      latency: avgLatency,
      failRate: avgFailRate
    });

    return {
      ...scoreResult,
      level: scorer.evaluateScore(scoreResult.score),
      health: model.health,
      metrics: {
        quality: model.metrics.quality,
        cost: model.metrics.cost,
        latency: avgLatency,
        failRate: avgFailRate
      }
    };
  }

  /**
   * 📊 获取所有模型的评分
   * @returns {Array} 模型评分列表
   */
  getAllScores() {
    const scores = [];

    for (const [name, model] of this.models) {
      const score = this.calculateScore(name);
      if (score) {
        scores.push({
          name,
          ...score
        });
      }
    }

    // 按分数排序
    return scores.sort((a, b) => b.score - a.score);
  }

  /**
   * 🎯 选择最佳模型
   * @param {Array} availableModels - 可用模型列表
   * @returns {Object} { model, score, fallback }
   */
  selectBestModel(availableModels) {
    if (availableModels.length === 0) {
      return null;
    }

    const scores = this.getAllScores();
    const selected = scores.find(s => availableModels.includes(s.name));

    // 如果没有找到（可能不在 scores 中），返回第一个
    if (!selected) {
      return {
        model: availableModels[0],
        score: 0,
        fallback: true
      };
    }

    return selected;
  }

  /**
   * 📊 获取模型统计
   * @param {string} modelName - 模型名称
   * @returns {Object} 模型统计
   */
  getModelStats(modelName) {
    const model = this.models.get(modelName);
    if (!model) {
      return null;
    }

    return {
      name: modelName,
      metrics: { ...model.metrics },
      stats: { ...model.stats },
      health: model.health
    };
  }

  /**
   * 📊 获取所有模型列表
   * @returns {Array} 模型列表
   */
  getAllModels() {
    const models = [];

    for (const model of this.models.values()) {
      models.push({
        name: model.name,
        metrics: { ...model.metrics },
        stats: { ...model.stats },
        health: model.health
      });
    }

    return models;
  }

  /**
   * 📝 更新模型配置
   * @param {string} modelName - 模型名称
   * @param {Object} config - 新配置
   */
  updateModelConfig(modelName, config) {
    const model = this.models.get(modelName);
    if (!model) {
      logger.warn(`Model not found: ${modelName}`);
      return;
    }

    if (config.quality) model.metrics.quality = config.quality;
    if (config.cost) model.metrics.cost = config.cost;
    if (config.latency) model.metrics.latency = config.latency;
    if (config.failRate) model.metrics.failRate = config.failRate;

    logger.info(`Model ${modelName} config updated:`, config);
  }

  /**
   * 📊 导出健康报告
   * @returns {Object} 完整报告
   */
  getHealthReport() {
    const models = this.getAllModels();
    const scores = this.getAllScores();

    return {
      timestamp: Date.now(),
      models: models.map(m => ({
        name: m.name,
        metrics: m.metrics,
        stats: m.stats,
        health: m.health
      })),
      scores: scores
    };
  }
}

// 创建全局 scorer 和 tracker
const scorer = new ModelScorer();
const tracker = new ModelHealthTracker();

module.exports = {
  ModelScorer,
  ModelHealthTracker,
  scorer,
  tracker
};
