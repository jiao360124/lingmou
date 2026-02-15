// openclaw-3.0/core/state-manager.js
// 状态管理 - 会话状态和上下文持久化

const fs = require('fs').promises;
const path = require('path');
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/state-manager.log' }),
    new winston.transports.Console({ format: winston.format.simple() })
  ]
});

class StateManager {
  constructor() {
    this.STATE_FILE = path.join(__dirname, '../../data/state.json');
    this.CONTEXT_FILE = path.join(__dirname, '../../data/context.json');
    this.sessionState = {
      turnCount: 0,
      lastUpdate: null,
      context: []
    };
    this.sessionContext = [];
  }

  /**
   * 初始化状态
   */
  async initialize() {
    await this.loadState();
    logger.info('StateManager 初始化完成');
  }

  /**
   * 加载会话状态
   */
  async loadState() {
    try {
      const data = await fs.readFile(this.STATE_FILE, 'utf8');
      this.sessionState = JSON.parse(data);
      logger.info('会话状态已加载', this.sessionState);
    } catch (error) {
      if (error.code === 'ENOENT') {
        // 文件不存在，使用默认状态
        logger.info('会话状态文件不存在，使用默认状态');
        await this.saveState();
      } else {
        logger.error('加载会话状态失败', error);
      }
    }
  }

  /**
   * 保存会话状态
   */
  async saveState() {
    try {
      this.sessionState.lastUpdate = new Date().toISOString();
      await fs.writeFile(this.STATE_FILE, JSON.stringify(this.sessionState, null, 2));
    } catch (error) {
      logger.error('保存会话状态失败', error);
    }
  }

  /**
   * 加载上下文
   */
  async loadContext() {
    try {
      const data = await fs.readFile(this.CONTEXT_FILE, 'utf8');
      this.sessionContext = JSON.parse(data);
      logger.info('会话上下文已加载', {
        contextLength: this.sessionContext.length
      });
    } catch (error) {
      if (error.code === 'ENOENT') {
        logger.info('会话上下文文件不存在');
        this.sessionContext = [];
      } else {
        logger.error('加载会话上下文失败', error);
      }
    }
  }

  /**
   * 保存上下文
   */
  async saveContext() {
    try {
      await fs.writeFile(this.CONTEXT_FILE, JSON.stringify(this.sessionContext, null, 2));
    } catch (error) {
      logger.error('保存会话上下文失败', error);
    }
  }

  /**
   * 更新上下文
   * @param {Object} message - 消息对象
   */
  async updateContext(message) {
    this.sessionContext.push({
      turn: this.sessionState.turnCount + 1,
      timestamp: new Date().toISOString(),
      role: message.role,
      content: message.content
    });

    // 限制上下文长度（最多保留最近 10 轮）
    if (this.sessionContext.length > 10) {
      this.sessionContext = this.sessionContext.slice(-10);
    }

    await this.saveContext();
  }

  /**
   * 获取最近上下文
   * @param {number} count - 获取数量
   * @returns {Array}
   */
  getContext(count = 3) {
    return this.sessionContext.slice(-count);
  }

  /**
   * 清空上下文
   */
  async clearContext() {
    this.sessionContext = [];
    await this.saveContext();
    logger.info('会话上下文已清空');
  }

  /**
   * 增加 turn 计数
   */
  incrementTurn() {
    this.sessionState.turnCount++;
  }

  /**
   * 获取当前状态
   * @returns {Object}
   */
  getState() {
    return { ...this.sessionState };
  }
}

module.exports = new StateManager();
