// config-loader.js - 配置加载器（带验证）
// 用于加载、验证和管理系统配置

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
    new winston.transports.File({ filename: 'logs/openclaw-3.0.log', level: 'info' }),
    new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
    new winston.transports.Console({ format: winston.format.simple() })
  ]
});

class ConfigLoader {
  constructor() {
    this.config = null;
    this.validateSchema = this.getConfigSchema();
  }

  // 获取默认配置 Schema
  getConfigSchema() {
    return {
      apiBaseURL: {
        type: 'string',
        required: true,
        default: 'https://api.openai.com/v1',
        pattern: /^https?:\/\/.+$/
      },
      dailyBudget: {
        type: 'integer',
        required: true,
        default: 200000,
        min: 10000,
        max: 1000000
      },
      turnThreshold: {
        type: 'integer',
        required: true,
        default: 10,
        min: 1,
        max: 50
      },
      baseContextThreshold: {
        type: 'integer',
        required: true,
        default: 40000,
        min: 10000,
        max: 100000
      },
      cooldownTurns: {
        type: 'integer',
        required: true,
        default: 3,
        min: 0,
        max: 20
      },
      nightBudgetTokens: {
        type: 'integer',
        required: true,
        default: 50000,
        min: 0,
        max: 500000
      },
      nightBudgetCalls: {
        type: 'integer',
        required: true,
        default: 10,
        min: 0,
        max: 100
      },
      maxRequestsPerMinute: {
        type: 'integer',
        required: true,
        default: 60,
        min: 10,
        max: 200
      },
      nightlyTaskTime: {
        type: 'string',
        required: false,
        default: '03:00',
        pattern: /^([01]?[0-9]|2[0-3]):([0-5][0-9])$/
      },
      enableMonitoring: {
        type: 'boolean',
        required: false,
        default: true
      },
      enableLogging: {
        type: 'boolean',
        required: false,
        default: true
      },
      logLevel: {
        type: 'string',
        required: false,
        default: 'info',
        enum: ['error', 'warn', 'info', 'debug']
      },
      debugMode: {
        type: 'boolean',
        required: false,
        default: false
      },
      timeout: {
        type: 'integer',
        required: false,
        default: 30000,
        min: 5000,
        max: 120000
      },
      retryAttempts: {
        type: 'integer',
        required: false,
        default: 5,
        min: 1,
        max: 10
      }
    };
  }

  // 加载配置文件
  async load(configPath = 'config.json') {
    try {
      const configPathResolved = path.join(__dirname, configPath);
      const configData = await fs.readFile(configPathResolved, 'utf-8');
      const config = JSON.parse(configData);

      logger.info('配置文件加载成功');

      // 填充默认值
      const filledConfig = this.fillDefaults(config);

      // 验证配置
      const validation = this.validateConfig(filledConfig);

      if (!validation.valid) {
        throw new Error(`配置验证失败: ${validation.errors.join(', ')}`);
      }

      this.config = filledConfig;
      logger.info('配置验证通过');

      return this.config;
    } catch (err) {
      logger.error(`配置加载失败: ${err.message}`);
      throw err;
    }
  }

  // 填充默认值
  fillDefaults(config) {
    const filled = { ...config };

    for (const [key, schema] of Object.entries(this.validateSchema)) {
      if (filled[key] === undefined || filled[key] === null) {
        filled[key] = schema.default;
      }
    }

    return filled;
  }

  // 验证配置
  validateConfig(config) {
    const errors = [];

    for (const [key, schema] of Object.entries(this.validateSchema)) {
      const value = config[key];

      // 检查必需字段
      if (schema.required && value === undefined && schema.default === undefined) {
        errors.push(`${key} 是必需字段`);
        continue;
      }

      // 跳过可选字段且未设置且无默认值
      if (!schema.required && value === undefined && schema.default === undefined) {
        continue;
      }

      // 使用默认值
      const actualValue = value !== undefined ? value : schema.default;

      // 类型检查
      if (schema.type === 'integer' && typeof actualValue !== 'number') {
        errors.push(`${key} 必须是整数`);
      } else if (schema.type === 'boolean' && typeof actualValue !== 'boolean') {
        errors.push(`${key} 必须是布尔值`);
      } else if (schema.type === 'string' && typeof actualValue !== 'string') {
        errors.push(`${key} 必须是字符串`);
      }

      // 数值范围检查
      if (actualValue !== undefined && actualValue !== null) {
        if (schema.min !== undefined && actualValue < schema.min) {
          errors.push(`${key} 必须 >= ${schema.min}`);
        }
        if (schema.max !== undefined && actualValue > schema.max) {
          errors.push(`${key} 必须 <= ${schema.max}`);
        }
      }

      // 枚举检查
      if (schema.enum && schema.enum.length > 0 && actualValue !== undefined && actualValue !== null) {
        if (!schema.enum.includes(actualValue)) {
          errors.push(`${key} 必须是以下值之一: ${schema.enum.join(', ')}`);
        }
      }

      // 正则检查
      if (schema.pattern && typeof actualValue === 'string' && actualValue !== null) {
        if (!schema.pattern.test(actualValue)) {
          errors.push(`${key} 格式不正确`);
        }
      }
    }

    return {
      valid: errors.length === 0,
      errors
    };
  }

  // 获取配置
  get(key) {
    if (!this.config) {
      throw new Error('配置尚未加载');
    }
    return this.config[key];
  }

  // 获取完整配置
  getConfig() {
    return this.config;
  }

  // 保存配置
  async save(configPath = 'config.json') {
    if (!this.config) {
      throw new Error('配置尚未加载');
    }

    const configPathResolved = path.join(__dirname, configPath);
    await fs.writeFile(configPathResolved, JSON.stringify(this.config, null, 2), 'utf-8');

    logger.info(`配置已保存到 ${configPathResolved}`);
  }

  // 获取配置摘要
  getConfigSummary() {
    return {
      apiBaseURL: this.config.apiBaseURL,
      dailyBudget: this.config.dailyBudget,
      tokenUsage: this.config.dailyBudget - this.config.remainingTokens,
      remainingTokens: this.config.remainingTokens,
      successRate: this.config.successRate,
      maxRequestsPerMinute: this.config.maxRequestsPerMinute,
      nightlyTaskTime: this.config.nightlyTaskTime,
      isNightTime: this.config.isNightTime
    };
  }
}

// 导出单例
module.exports = new ConfigLoader();
