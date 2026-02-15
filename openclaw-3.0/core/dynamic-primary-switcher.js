// openclaw-3.0/core/dynamic-primary-switcher.js
// 动态主模型切换系统 - Trinity 真正的"逃生舱"

const winston = require('winston');
const fs = require('fs').promises;

// 日志配置
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/dynamic-primary-switcher.log' }),
    new winston.transports.File({ filename: 'logs/dynamic-primary-switcher-errors.log', level: 'error' }),
    new winston.transports.Console({ format: winston.format.simple() })
  ]
});

/**
 * 🚀 动态主模型切换器
 * 当主模型（ZAI）健康度下降时，自动切换到备用模型（Trinity）
 * 当主模型恢复时，自动切换回主模型
 */
class DynamicPrimarySwitcher {
  constructor(options = {}) {
    // 配置
    this.config = {
      zaiHealthThreshold: options.zaiHealthThreshold || 50, // ZAI 健康度阈值（50%）
      recoveryThreshold: options.recoveryThreshold || 80,   // 恢复阈值（80%）
      healthCheckInterval: options.healthCheckInterval || 60000, // 健康检查间隔（60秒）
      switchCooldown: options.switchCooldown || 5 * 60 * 1000 // 切换冷却时间（5分钟）
    };

    // 状态
    this.primaryModel = 'ZAI'; // 当前主模型
    this.backupModel = 'Trinity'; // 备用模型
    this.switchCount = 0;
    this.lastSwitchTime = null;
    this.isSwitched = false;
    this.switchHistory = [];

    // ZAI 健康度状态
    this.zaiHealth = 100;
    this.zaiFailureCount = 0;
    this.lastZaiCheckTime = null;

    // 监控定时器
    this.monitorInterval = null;

    // 历史记录
    this.switchHistory = [];

    logger.info('Dynamic Primary Switcher initialized');
    logger.info(`Config: ZAI threshold=${this.config.zaiHealthThreshold}%, recovery=${this.config.recoveryThreshold}%`);
  }

  /**
   * 🔄 启动监控
   */
  startMonitoring() {
    if (this.monitorInterval) {
      clearInterval(this.monitorInterval);
    }

    this.monitorInterval = setInterval(() => {
      this.checkZAIHealth();
    }, this.config.healthCheckInterval);

    logger.info(`Health monitoring started (${this.config.healthCheckInterval}ms)`);
  }

  /**
   * 📊 检查 ZAI 健康度
   */
  checkZAIHealth() {
    const now = Date.now();
    this.lastZaiCheckTime = now;

    // 如果已经切换到 Trinity，不需要检查 ZAI
    if (this.isSwitched) {
      return;
    }

    // 如果最近刚切换过，冷却时间内不检查
    if (this.lastSwitchTime && now - this.lastSwitchTime < this.config.switchCooldown) {
      logger.debug('Switch cooldown active, skipping health check');
      return;
    }

    // 计算健康度（这里简化，实际应该从健康度跟踪器获取）
    // 模拟：健康度 = 100 - 失败率 * 100
    const health = this.zaiHealth;
    this.zaiHealth = health;

    logger.debug(`ZAI health check: ${health.toFixed(1)}%`);

    // 切换逻辑
    if (health < this.config.zaiHealthThreshold) {
      logger.warn(`🚨 ZAI health is low (${health.toFixed(1)}% < ${this.config.zaiHealthThreshold}%), switching to Trinity`);
      this.switchPrimaryModel();
    } else if (health > this.config.recoveryThreshold && this.isSwitched) {
      logger.info(`✅ ZAI health recovered (${health.toFixed(1)}% > ${this.config.recoveryThreshold}%), switching back to ZAI`);
      this.switchBack();
    }
  }

  /**
   * 🔄 切换主模型
   */
  switchPrimaryModel() {
    // 如果已经在 Trinity，不需要切换
    if (this.primaryModel === this.backupModel) {
      return;
    }

    const previousPrimary = this.primaryModel;
    this.primaryModel = this.backupModel;
    this.isSwitched = true;
    this.lastSwitchTime = Date.now();
    this.switchCount++;

    // 记录历史
    this.switchHistory.push({
      timestamp: Date.now(),
      from: previousPrimary,
      to: this.primaryModel,
      reason: `ZAI health dropped below ${this.config.zaiHealthThreshold}%`
    });

    logger.info(`🔄 Primary model switched: ${previousPrimary} → ${this.primaryModel}`);
    logger.info(`   Total switches: ${this.switchCount}`);
  }

  /**
   * 🔄 切换回主模型
   */
  switchBack() {
    // 如果已经在 ZAI，不需要切换
    if (this.primaryModel === 'ZAI') {
      return;
    }

    const previousPrimary = this.primaryModel;
    this.primaryModel = 'ZAI';
    this.isSwitched = false;
    this.lastSwitchTime = Date.now();

    // 记录历史
    this.switchHistory.push({
      timestamp: Date.now(),
      from: previousPrimary,
      to: this.primaryModel,
      reason: 'ZAI health recovered'
    });

    logger.info(`✅ Primary model switched back: ${previousPrimary} → ZAI`);
    logger.info(`   Total switches: ${this.switchCount}`);
  }

  /**
   * 📊 更新 ZAI 健康度
   * @param {number} health - 健康度（0-100）
   */
  updateZAIHealth(health) {
    this.zaiHealth = health;
    this.zaiFailureCount = 0;
    logger.debug(`ZAI health updated: ${health.toFixed(1)}%`);
  }

  /**
   * 📊 记录 ZAI 失败
   */
  recordZAIFailure() {
    this.zaiFailureCount++;
    // 简单的平滑计算
    this.zaiHealth = Math.max(0, this.zaiHealth - 10);
    logger.debug(`ZAI failure recorded (failures: ${this.zaiFailureCount}, health: ${this.zaiHealth.toFixed(1)}%)`);
  }

  /**
   * 📊 记录 ZAI 成功
   */
  recordZAISuccess() {
    // 简单的平滑恢复
    this.zaiHealth = Math.min(100, this.zaiHealth + 5);
    logger.debug(`ZAI success recorded (health: ${this.zaiHealth.toFixed(1)}%)`);
  }

  /**
   * 📊 获取当前配置的 Tier 系统映射
   * @returns {Object} Tier 映射
   */
  getTierMapping() {
    if (this.isSwitched) {
      return {
        Tier1: this.primaryModel,
        Tier2: this.backupModel,
        Tier3: 'Anthropic',
        Tier4: 'OPENAI'
      };
    } else {
      return {
        Tier1: 'ZAI',
        Tier2: 'Trinity',
        Tier3: 'Anthropic',
        Tier4: 'OPENAI'
      };
    }
  }

  /**
   * 🎯 获取可用的模型列表（用于路由）
   * @returns {Array} 可用模型列表
   */
  getAvailableModels() {
    if (this.isSwitched) {
      return [this.primaryModel, this.backupModel];
    } else {
      return ['ZAI', 'Trinity', 'Anthropic', 'OPENAI'];
    }
  }

  /**
   * 📊 获取状态
   * @returns {Object} 当前状态
   */
  getStatus() {
    return {
      primaryModel: this.primaryModel,
      backupModel: this.backupModel,
      isSwitched: this.isSwitched,
      switchCount: this.switchCount,
      lastSwitchTime: this.lastSwitchTime,
      zaiHealth: this.zaiHealth,
      zaiFailureCount: this.zaiFailureCount,
      config: {
        zaiHealthThreshold: this.config.zaiHealthThreshold,
        recoveryThreshold: this.config.recoveryThreshold,
        healthCheckInterval: this.config.healthCheckInterval,
        switchCooldown: this.config.switchCooldown
      },
      tierMapping: this.getTierMapping()
    };
  }

  /**
   * 📊 获取切换历史
   * @param {number} limit - 返回数量
   * @returns {Array} 切换历史
   */
  getSwitchHistory(limit = 10) {
    return this.switchHistory.slice(-limit);
  }

  /**
   * 📊 获取健康度报告
   * @returns {Object} 健康度报告
   */
  getHealthReport() {
    return {
      zaiHealth: this.zaiHealth,
      isSwitched: this.isSwitched,
      primaryModel: this.primaryModel,
      currentTierMapping: this.getTierMapping(),
      switchCount: this.switchCount,
      lastSwitchTime: this.lastSwitchTime,
      status: this.isSwitched ? 'EMERGENCY_MODE' : 'NORMAL_MODE'
    };
  }

  /**
   * 📝 保存状态到文件
   */
  async saveState() {
    const state = {
      primaryModel: this.primaryModel,
      backupModel: this.backupModel,
      isSwitched: this.isSwitched,
      switchCount: this.switchCount,
      lastSwitchTime: this.lastSwitchTime,
      zaiHealth: this.zaiHealth,
      zaiFailureCount: this.zaiFailureCount,
      switchHistory: this.switchHistory,
      config: this.config,
      timestamp: Date.now()
    };

    try {
      await fs.mkdir('data', { recursive: true });
      await fs.writeFile('data/dynamic-primary-switcher.json', JSON.stringify(state, null, 2));
    } catch (error) {
      logger.error('Failed to save switcher state:', error);
    }
  }

  /**
   * 📝 加载状态从文件
   */
  async loadState() {
    try {
      const data = await fs.readFile('data/dynamic-primary-switcher.json', 'utf-8');
      const state = JSON.parse(data);

      this.primaryModel = state.primaryModel;
      this.backupModel = state.backupModel;
      this.isSwitched = state.isSwitched;
      this.switchCount = state.switchCount;
      this.lastSwitchTime = state.lastSwitchTime;
      this.zaiHealth = state.zaiHealth;
      this.zaiFailureCount = state.zaiFailureCount;
      this.switchHistory = state.switchHistory || [];
      this.config = state.config || this.config;

      logger.info('Dynamic Primary Switcher state loaded');
      logger.info(`Current primary: ${this.primaryModel}, switched: ${this.isSwitched}`);
    } catch (error) {
      logger.info('No saved state found, starting fresh');
    }
  }

  /**
   * 🎯 强制切换主模型
   * @param {string} newPrimary - 新的主模型
   */
  forceSwitch(newPrimary) {
    const previousPrimary = this.primaryModel;
    this.primaryModel = newPrimary;
    this.isSwitched = true;
    this.lastSwitchTime = Date.now();
    this.switchCount++;

    this.switchHistory.push({
      timestamp: Date.now(),
      from: previousPrimary,
      to: newPrimary,
      reason: 'Force switch'
    });

    logger.warn(`⚠️ Force switch: ${previousPrimary} → ${newPrimary}`);
  }

  /**
   * 🎯 强制恢复主模型
   */
  forceSwitchBack() {
    if (!this.isSwitched) {
      return;
    }

    const previousPrimary = this.primaryModel;
    this.primaryModel = 'ZAI';
    this.isSwitched = false;
    this.lastSwitchTime = Date.now();

    this.switchHistory.push({
      timestamp: Date.now(),
      from: previousPrimary,
      to: 'ZAI',
      reason: 'Force switch back'
    });

    logger.warn(`⚠️ Force switch back: ${previousPrimary} → ZAI`);
  }

  /**
   * 🎯 手动切换模式
   * @param {string} mode - 'normal' 或 'emergency'
   */
  setMode(mode) {
    if (mode === 'normal') {
      this.forceSwitchBack();
    } else if (mode === 'emergency') {
      this.forceSwitch(this.backupModel);
    } else {
      logger.warn(`Invalid mode: ${mode}`);
    }
  }

  /**
   * 📊 导出配置（用于配置文件）
   */
  exportConfig() {
    return {
      zaiHealthThreshold: this.config.zaiHealthThreshold,
      recoveryThreshold: this.config.recoveryThreshold,
      healthCheckInterval: this.config.healthCheckInterval,
      switchCooldown: this.config.switchCooldown
    };
  }
}

module.exports = DynamicPrimarySwitcher;
