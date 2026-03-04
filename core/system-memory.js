// openclaw-3.0/memory/system-memory.js
// System Memory Layer - 长期行为学习

const fs = require('fs').promises;
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/system-memory.log' }),
    new winston.transports.Console({ format: winston.format.simple() })
  ]
});

class SystemMemory {
  constructor() {
    // 文件路径
    this.paths = {
      optimizationHistory: 'data/optimization-history.json',
      failurePatterns: 'data/failure-patterns.json',
      costTrends: 'data/cost-trends.json'
    };

    // 内存缓存
    this.memory = {
      optimizationHistory: [],
      failurePatterns: [],
      costTrends: []
    };

    // 加载记忆
    this.loadMemory();
    logger.info('System Memory Layer 初始化完成');
  }

  /**
   * 加载记忆
   */
  async loadMemory() {
    try {
      // 加载优化历史
      if (await this.fileExists(this.paths.optimizationHistory)) {
        const history = JSON.parse(await fs.readFile(this.paths.optimizationHistory, 'utf8'));
        this.memory.optimizationHistory = history;
        logger.info('优化历史已加载', { count: history.length });
      }

      // 加载失败模式
      if (await this.fileExists(this.paths.failurePatterns)) {
        const patterns = JSON.parse(await fs.readFile(this.paths.failurePatterns, 'utf8'));
        this.memory.failurePatterns = patterns;
        logger.info('失败模式已加载', { count: patterns.length });
      }

      // 加载成本趋势
      if (await this.fileExists(this.paths.costTrends)) {
        const trends = JSON.parse(await fs.readFile(this.paths.costTrends, 'utf8'));
        this.memory.costTrends = trends;
        logger.info('成本趋势已加载', { count: trends.length });
      }
    } catch (error) {
      logger.error('加载记忆失败', error);
    }
  }

  /**
   * 保存记忆
   */
  async saveMemory() {
    try {
      // 保存优化历史
      await fs.writeFile(
        this.paths.optimizationHistory,
        JSON.stringify(this.memory.optimizationHistory, null, 2)
      );

      // 保存失败模式
      await fs.writeFile(
        this.paths.failurePatterns,
        JSON.stringify(this.memory.failurePatterns, null, 2)
      );

      // 保存成本趋势
      await fs.writeFile(
        this.paths.costTrends,
        JSON.stringify(this.memory.costTrends, null, 2)
      );

      logger.info('记忆已保存');
    } catch (error) {
      logger.error('保存记忆失败', error);
    }
  }

  /**
   * 检查文件是否存在
   * @param {string} path
   * @returns {Promise<boolean>}
   */
  async fileExists(path) {
    try {
      await fs.access(path);
      return true;
    } catch {
      return false;
    }
  }

  /**
   * 记录优化历史
   * @param {Object} optimization - 优化信息
   */
  recordOptimization(optimization) {
    const record = {
      timestamp: new Date().toISOString(),
      optimizationType: optimization.type,
      description: optimization.description,
      changes: optimization.changes,
      result: optimization.result,
      success: optimization.success,
      riskScore: optimization.riskScore,
      snapshotId: optimization.snapshotId
    };

    this.memory.optimizationHistory.push(record);

    // 只保留最近100条记录
    if (this.memory.optimizationHistory.length > 100) {
      this.memory.optimizationHistory = this.memory.optimizationHistory.slice(-100);
    }

    this.saveMemory();

    logger.info('优化历史已记录', {
      type: optimization.type,
      success: optimization.success
    });
  }

  /**
   * 检测是否重复优化
   * @param {string} optimizationType - 优化类型
   * @returns {boolean}
   */
  isDuplicateOptimization(optimizationType) {
    const recentOptimizations = this.memory.optimizationHistory.filter(
      o => o.optimizationType === optimizationType && o.success === true
    ).slice(-5); // 最近5次成功的

    // 如果5次中有3次以上成功，认为是重复
    return recentOptimizations.length >= 3;
  }

  /**
   * 记录失败模式
   * @param {Object} failurePattern - 失败模式
   */
  recordFailurePattern(failurePattern) {
    const pattern = {
      timestamp: new Date().toISOString(),
      type: failurePattern.type,
      description: failurePattern.description,
      triggerCondition: failurePattern.triggerCondition,
      errorType: failurePattern.errorType,
      recoveryAction: failurePattern.recoveryAction,
      frequency: failurePattern.frequency || 1
    };

    // 检查是否已存在相似模式
    const existingIndex = this.memory.failurePatterns.findIndex(
      p =>
        p.type === pattern.type &&
        p.triggerCondition === pattern.triggerCondition
    );

    if (existingIndex !== -1) {
      // 增加频率
      this.memory.failurePatterns[existingIndex].frequency++;
      logger.info('失败模式频率已更新', {
        type: pattern.type,
        newFrequency: this.memory.failurePatterns[existingIndex].frequency
      });
    } else {
      // 添加新模式
      this.memory.failurePatterns.push(pattern);
      logger.info('新失败模式已记录', {
        type: pattern.type,
        frequency: pattern.frequency
      });
    }

    this.saveMemory();
  }

  /**
   * 获取高频失败模式
   * @returns {Array}
   */
  getHighFrequencyFailures() {
    return this.memory.failurePatterns
      .filter(p => p.frequency >= 3)
      .sort((a, b) => b.frequency - a.frequency);
  }

  /**
   * 记录成本趋势
   * @param {Object} costData - 成本数据
   */
  recordCostTrend(costData) {
    const trend = {
      timestamp: new Date().toISOString(),
      dailyTokens: costData.dailyTokens,
      cost: costData.cost,
      successRate: costData.successRate,
      optimizationCount: costData.optimizationCount
    };

    this.memory.costTrends.push(trend);

    // 只保留最近30天
    const now = Date.now();
    const thirtyDaysAgo = now - 30 * 24 * 60 * 60 * 1000;

    this.memory.costTrends = this.memory.costTrends.filter(
      t => new Date(t.timestamp).getTime() > thirtyDaysAgo
    );

    this.saveMemory();

    logger.info('成本趋势已记录');
  }

  /**
   * 分析成本趋势
   * @returns {Object}
   */
  analyzeCostTrend() {
    if (this.memory.costTrends.length < 2) {
      return { trend: 'not_enough_data', change: 0 };
    }

    const recent = this.memory.costTrends.slice(-7);
    const oldest = recent[0];
    const latest = recent[recent.length - 1];

    const tokenChange = ((latest.dailyTokens - oldest.dailyTokens) / oldest.dailyTokens * 100).toFixed(2);
    const costChange = ((latest.cost - oldest.cost) / oldest.cost * 100).toFixed(2);

    return {
      trend: tokenChange > 10 ? 'increasing' : tokenChange < -10 ? 'decreasing' : 'stable',
      tokenChange,
      costChange,
      latest: latest.dailyTokens,
      oldest: oldest.dailyTokens
    };
  }

  /**
   * 获取优化历史摘要
   * @returns {Object}
   */
  getOptimizationSummary() {
    const total = this.memory.optimizationHistory.length;
    const successful = this.memory.optimizationHistory.filter(o => o.success).length;
    const failed = total - successful;

    const byType = {};
    for (const opt of this.memory.optimizationHistory) {
      if (!byType[opt.optimizationType]) {
        byType[opt.optimizationType] = { total: 0, success: 0 };
      }
      byType[opt.optimizationType].total++;
      if (opt.success) {
        byType[opt.optimizationType].success++;
      }
    }

    return {
      total,
      successful,
      failed,
      successRate: ((successful / total) * 100).toFixed(2),
      byType
    };
  }

  /**
   * 获取失败模式摘要
   * @returns {Object}
   */
  getFailureSummary() {
    const highFrequency = this.getHighFrequencyFailures();

    return {
      total: this.memory.failurePatterns.length,
      highFrequency: highFrequency.length,
      topFailures: highFrequency.slice(0, 5)
    };
  }

  /**
   * 检测"伪优化"（失败率高且重复）
   * @returns {Array}
   */
  detectPseudoOptimizations() {
    const pseudoOptimizations = [];

    for (const opt of this.memory.optimizationHistory) {
      if (!opt.success) continue;

      // 查找后续失败
      const subsequentFailures = this.memory.optimizationHistory.filter(
        o =>
          o.optimizationType === opt.optimizationType &&
          o.timestamp > opt.timestamp &&
          !o.success
      );

      // 如果有2次以上后续失败，标记为伪优化
      if (subsequentFailures.length >= 2) {
        pseudoOptimizations.push({
          optimizationType: opt.optimizationType,
          description: opt.description,
          riskScore: opt.riskScore,
          subsequentFailures: subsequentFailures.length,
          totalOptimizations: this.memory.optimizationHistory.filter(
            o => o.optimizationType === opt.optimizationType
          ).length
        });
      }
    }

    return pseudoOptimizations;
  }
}

module.exports = new SystemMemory();
