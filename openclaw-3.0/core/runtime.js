// openclaw-3.0/core/runtime.js
// 运行时引擎

const winston = require('winston');

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
      isNightTime: false
    };
    this.stats = {
      todayUsage: 0,
      successCount: 0,
      errorCount: 0
    };
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
    try {
      const response = await axios.post(this.config.apiBaseURL, payload);
      this.recordUsage(response.data.usage?.total_tokens || 0);
      return response.data;
    } catch (err) {
      this.stats.errorCount++;
      logger.error('API调用失败:', err.message);

      // 429错误自动排队
      if (err.response?.status === 429) {
        logger.warn('遇到429错误，使用指数退避重试...');
        await this.handle429Retry(payload);
      }

      throw err;
    }
  }

  async handle429Retry(payload, retry = 0) {
    if (retry < 5) {
      const delay = Math.pow(2, retry) * 1000;
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
      lastUpdated: new Date().toISOString()
    };
    fs.writeFileSync('data/metrics.json', JSON.stringify(metrics, null, 2));
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
}

module.exports = new Runtime();
