// openclaw-3.0/core/session-summarizer.js
// 会话摘要 - 防止上下文膨胀

const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/session-summary.log' }),
    new winston.transports.Console({ format: winston.format.simple() })
  ]
});

class SessionSummarizer {
  constructor() {
    this.TURN_THRESHOLD = 10;
    this.BASE_CONTEXT_THRESHOLD = 40000;
    this.COOLDOWN_TURNS = 3;
    this.DAILY_BUDGET = 200000;

    // 状态
    this.turnCount = 0;
    this.lastSummaryTurn = -1;
    this.dailyTokenUsed = 0;
    this.dailyBudget = this.DAILY_BUDGET;

    logger.info('Session Summarizer 初始化完成');
  }

  /**
   * 更新 Token 使用统计
   * @param {number} tokens - 使用的 Token 数量
   */
  updateTokenUsage(tokens) {
    this.dailyTokenUsed += tokens;
  }

  /**
   * 获取当前剩余预算比例
   * @returns {number} 0.0 - 1.0
   */
  getBudgetRatio() {
    return Math.max(0, this.dailyTokenUsed / this.dailyBudget);
  }

  /**
   * 根据预算比例获取 Context 阈值
   * @returns {number}
   */
  getContextThreshold() {
    const ratio = this.getBudgetRatio();

    // 预算压缩机制
    if (ratio >= 0.7) return 40000;
    if (ratio >= 0.5) return 35000;
    if (ratio >= 0.3) return 30000;
    return 25000;
  }

  /**
   * 检查是否需要触发摘要
   * @returns {boolean}
   */
  shouldTrigger() {
    // 冷却机制：3 轮内不再触发
    if (this.turnCount - this.lastSummaryTurn < this.COOLDOWN_TURNS) {
      return false;
    }

    // 硬触发：turn >= 10
    if (this.turnCount >= this.TURN_THRESHOLD) {
      return true;
    }

    // Context 阈值触发
    // 注意：这里需要传入 context tokens，暂时假设有方法获取
    // 实际实现中会在 handleMessage 中传入
    return false;
  }

  /**
   * 触发摘要
   * @param {number} contextTokens - 当前上下文 token 数量
   * @returns {Promise<Object>} 摘要结果
   */
  async triggerSummary(contextTokens = 0) {
    const threshold = this.getContextThreshold();

    logger.info({
      action: 'session_summary_trigger',
      turn: this.turnCount,
      contextTokens,
      threshold,
      budgetRatio: this.getBudgetRatio().toFixed(2)
    });

    // 执行摘要（实际实现中会调用 AI 生成摘要）
    const summary = await this.generateSummary(contextTokens);

    // 更新状态
    this.lastSummaryTurn = this.turnCount;

    logger.info({
      action: 'session_summary_completed',
      turn: this.turnCount,
      summaryLength: summary.length,
      tokensSaved: contextTokens
    });

    return summary;
  }

  /**
   * 生成摘要（占位实现）
   * @param {number} contextTokens
   * @returns {Promise<string>}
   */
  async generateSummary(contextTokens) {
    // TODO: 调用 AI 生成摘要
    // 当前返回占位内容
    return `Session summary: Turn ${this.turnCount}, Context ${contextTokens} tokens. This is a placeholder summary.`;
  }

  /**
   * 重置状态（每日调用）
   */
  resetDaily() {
    this.turnCount = 0;
    this.dailyTokenUsed = 0;
    this.lastSummaryTurn = -1;
    logger.info('Session Summarizer 状态已重置');
  }

  /**
   * 增加 turn 计数
   */
  incrementTurn() {
    this.turnCount++;
  }
}

module.exports = new SessionSummarizer();
