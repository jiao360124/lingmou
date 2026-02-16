// openclaw-3.0/config.js
// 配置管理模块

const fs = require('fs').promises;
const path = require('path');

/**
 * 📋 配置管理器
 * 支持配置文件和环境变量
 */
class ConfigManager {
  constructor(options = {}) {
    this.configDir = options.configDir || path.join(process.cwd(), 'config');
    this.configFile = options.configFile || 'dashboard.config.json';
    this.defaultConfig = this.getDefaultConfig();
    this.currentConfig = null;

    // 从文件加载配置
    this.loadConfig().catch(error => {
      console.log('⚠️ 无法加载配置文件，使用默认配置');
      this.currentConfig = this.defaultConfig;
    });
  }

  /**
   * 📄 获取默认配置
   * @returns {Object} 默认配置
   */
  getDefaultConfig() {
    return {
      // 服务器配置
      server: {
        port: process.env.PORT || 8080,
        host: process.env.HOST || '127.0.0.1'
      },

      // 缓存配置
      cache: {
        duration: parseInt(process.env.CACHE_DURATION) || 30000, // 30秒
        maxLogs: parseInt(process.env.MAX_LOGS) || 10000
      },

      // WebSocket 配置
      websocket: {
        path: process.env.WS_PATH || '/ws',
        interval: parseInt(process.env.UPDATE_INTERVAL) || 60000 // 60秒
      },

      // 数据服务配置
      dataService: {
        logFile: process.env.LOG_FILE || 'logs/dashboard-logs.json',
        exportFormats: ['json', 'csv']
      },

      // Dashboard 配置
      dashboard: {
        title: 'OpenClaw Dashboard',
        refreshInterval: parseInt(process.env.REFRESH_INTERVAL) || 30000, // 30秒
        theme: 'light'
      },

      // 数据源配置
      dataSources: {
        requestLogger: true,
        circuitBreaker: false,
        modelScheduler: false,
        dynamicSwitcher: false
      },

      // 导出配置
      export: {
        enabled: true,
        formats: ['json', 'csv'],
        autoExport: false
      }
    };
  }

  /**
   * 📂 加载配置文件
   * @returns {Promise<Object>} 配置对象
   */
  async loadConfig() {
    try {
      const configPath = path.join(this.configDir, this.configFile);
      const content = await fs.readFile(configPath, 'utf-8');
      const config = JSON.parse(content);

      // 合并默认配置
      this.currentConfig = this.mergeConfig(this.defaultConfig, config);

      console.log(`✅ 配置文件加载成功: ${configPath}`);
      console.log(`📍 端口: ${this.currentConfig.server.port}`);
      console.log(`⏰ 缓存时长: ${this.currentConfig.cache.duration}ms`);
      console.log(`📡 WebSocket 路径: ${this.currentConfig.websocket.path}`);

      return this.currentConfig;
    } catch (error) {
      console.log('⚠️ 无法加载配置文件，使用默认配置');
      return this.defaultConfig;
    }
  }

  /**
   * 💾 保存配置文件
   * @param {Object} config - 配置对象
   * @returns {Promise<void>}
   */
  async saveConfig(config) {
    try {
      await fs.mkdir(this.configDir, { recursive: true });
      const configPath = path.join(this.configDir, this.configFile);
      const content = JSON.stringify(config, null, 2);
      await fs.writeFile(configPath, content, 'utf-8');

      console.log(`✅ 配置文件保存成功: ${configPath}`);
      this.currentConfig = config;
    } catch (error) {
      console.error(`❌ 配置文件保存失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 🔧 更新配置
   * @param {Object} updates - 配置更新
   * @returns {Promise<Object>} 更新后的配置
   */
  async updateConfig(updates) {
    const newConfig = this.mergeConfig(this.currentConfig || this.defaultConfig, updates);
    await this.saveConfig(newConfig);
    return newConfig;
  }

  /**
   * 📊 合并配置
   * @param {Object} base - 基础配置
   * @param {Object} overrides - 覆盖配置
   * @returns {Object} 合并后的配置
   */
  mergeConfig(base, overrides) {
    const result = { ...base };

    for (const key in overrides) {
      if (typeof overrides[key] === 'object' && !Array.isArray(overrides[key])) {
        result[key] = this.mergeConfig(base[key] || {}, overrides[key]);
      } else {
        result[key] = overrides[key];
      }
    }

    return result;
  }

  /**
   * 📖 获取配置
   * @param {string} path - 配置路径（如 "server.port"）
   * @returns {*} 配置值
   */
  get(path) {
    const keys = path.split('.');
    let value = this.currentConfig || this.defaultConfig;

    for (const key of keys) {
      if (value === null || value === undefined) {
        return undefined;
      }
      value = value[key];
    }

    return value;
  }

  /**
   * ✅ 验证配置
   * @returns {Object} 验证结果
   */
  validateConfig() {
    const errors = [];
    const config = this.currentConfig || this.defaultConfig;

    // 验证端口
    if (config.server.port < 1 || config.server.port > 65535) {
      errors.push('server.port 必须在 1-65535 范围内');
    }

    // 验证缓存时长
    if (config.cache.duration < 1000 || config.cache.duration > 3600000) {
      errors.push('cache.duration 必须在 1000-3600000ms 范围内');
    }

    // 验证 WebSocket 路径
    if (!config.websocket.path || config.websocket.path.length > 255) {
      errors.push('websocket.path 无效');
    }

    return {
      valid: errors.length === 0,
      errors
    };
  }

  /**
   * 🔄 热重载配置
   * @returns {Promise<Object>} 重载后的配置
   */
  async reloadConfig() {
    return this.loadConfig();
  }

  /**
   * 📋 获取当前配置
   * @returns {Object} 当前配置
   */
  getConfig() {
    return this.currentConfig || this.defaultConfig;
  }

  /**
   * 📝 获取配置路径
   * @returns {string} 配置文件路径
   */
  getConfigPath() {
    return path.join(this.configDir, this.configFile);
  }
}

module.exports = ConfigManager;
