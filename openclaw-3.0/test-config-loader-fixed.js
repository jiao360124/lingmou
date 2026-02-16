// test-config-loader-fixed.js - 配置加载器测试（修复版）

const fs = require('fs').promises;
const path = require('path');

// 简化的配置加载器
class ConfigLoader {
  constructor() {
    this.validateSchema = {
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

  async load(configPath = 'config.json') {
    try {
      const configPathResolved = path.join(__dirname, configPath);
      const configData = await fs.readFile(configPathResolved, 'utf-8');
      const config = JSON.parse(configData);

      console.log('📋 配置文件内容:');
      console.log(JSON.stringify(config, null, 2));
      console.log('\n');

      // 填充默认值
      const filledConfig = this.fillDefaults(config);

      console.log('📋 填充默认值后:');
      console.log(JSON.stringify(filledConfig, null, 2));
      console.log('\n');

      // 验证配置
      const validation = this.validateConfig(filledConfig);

      console.log('📋 验证结果:');
      console.log(`   有效性: ${validation.valid ? '✅ 通过' : '❌ 失败'}`);
      if (!validation.valid) {
        console.log(`   错误: ${validation.errors.join(', ')}`);
      }
      console.log('');

      if (!validation.valid) {
        throw new Error(`配置验证失败: ${validation.errors.join(', ')}`);
      }

      return filledConfig;
    } catch (err) {
      console.error(`❌ 配置加载失败: ${err.message}`);
      throw err;
    }
  }

  fillDefaults(config) {
    const filled = { ...config };

    for (const [key, schema] of Object.entries(this.validateSchema)) {
      if (filled[key] === undefined || filled[key] === null) {
        filled[key] = schema.default;
      }
    }

    return filled;
  }

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
}

// 运行测试
async function test() {
  console.log('🧪 测试配置加载器（修复版）...\n');

  const loader = new ConfigLoader();

  try {
    const config = await loader.load();
    console.log('🎉 配置加载成功！');
    console.log('\n最终配置:');
    console.log(JSON.stringify(config, null, 2));
  } catch (err) {
    console.error('❌ 测试失败');
    process.exit(1);
  }
}

test();
