# 集中配置管理

## 概述
集中配置管理系统提供统一的配置管理方式，支持多环境配置、配置版本管理、配置验证等功能。

## 配置架构

### 核心组件

#### 1. 配置管理器
```typescript
class ConfigurationManager {
  private config: Config = {};
  private environments: Map<string, Config> = new Map();
  private currentEnvironment: string = 'development';
  private validators: ConfigValidator[] = [];
  private changeListeners: ChangeListener[] = [];

  constructor(initialConfig: Config) {
    this.config = { ...initialConfig };
  }

  // 环境管理
  setCurrentEnvironment(env: string): void {
    if (!this.environments.has(env)) {
      throw new Error(`环境 ${env} 不存在`);
    }
    this.currentEnvironment = env;
    this.notifyChange('environment-changed', { environment: env });
  }

  loadEnvironment(env: string): void {
    const envConfig = this.environments.get(env);
    if (!envConfig) {
      throw new Error(`环境 ${env} 不存在`);
    }

    this.config = { ...envConfig };
    this.currentEnvironment = env;
    this.notifyChange('environment-loaded', { environment: env });
  }

  addEnvironment(env: string, config: Config): void {
    this.environments.set(env, { ...config });
    this.notifyChange('environment-added', { environment: env });
  }

  getEnvironments(): string[] {
    return Array.from(this.environments.keys());
  }

  // 配置访问
  get<T = any>(key: string, defaultValue?: T): T {
    return this.config[key] ?? defaultValue;
  }

  set(key: string, value: any): void {
    this.config[key] = value;
    this.notifyChange('config-updated', { key, value });
    this.save();
  }

  getFullConfig(): Config {
    return { ...this.config };
  }

  // 配置验证
  addValidator(validator: ConfigValidator): void {
    this.validators.push(validator);
  }

  validate(config?: Config): ValidationResult {
    const toValidate = config || this.config;
    const errors: ValidationError[] = [];
    const warnings: ValidationWarning[] = [];

    for (const validator of this.validators) {
      const result = validator.validate(toValidate);
      errors.push(...result.errors);
      warnings.push(...result.warnings);
    }

    return {
      valid: errors.length === 0,
      errors,
      warnings
    };
  }

  // 监听器
  onChange(listener: ChangeListener): void {
    this.changeListeners.push(listener);
  }

  notifyChange(event: string, data: any): void {
    for (const listener of this.changeListeners) {
      listener(event, data);
    }
  }

  // 持久化
  save(): void {
    // 保存到配置文件
    this.saveToFile();
    // 保存到数据库
    this.saveToDatabase();
  }

  private saveToFile(): void {
    // 实现文件持久化
  }

  private saveToDatabase(): void {
    // 实现数据库持久化
  }

  // 版本控制
  getVersion(): number {
    return this.config.version || 1;
  }

  createVersion(): number {
    this.config.version = (this.config.version || 1) + 1;
    return this.config.version;
  }
}
```

#### 2. 配置文件格式
```typescript
interface Config {
  // 应用配置
  app: {
    name: string;
    version: string;
    environment: 'development' | 'staging' | 'production';
    debug: boolean;
  };

  // Copilot配置
  copilot: {
    enabled: boolean;
    language: string;
    maxTokens: number;
    cacheSize: number;
  };

  // Auto-GPT配置
  autoGpt: {
    enabled: boolean;
    maxTasks: number;
    timeout: number;
    cacheSize: number;
  };

  // RAG配置
  rag: {
    enabled: boolean;
    knowledgePath: string;
    retrievalTopK: number;
    cacheSize: number;
  };

  // Prompt-Engineering配置
  promptEngineering: {
    enabled: boolean;
    templateLibrary: string;
    qualityCheckEnabled: boolean;
  };

  // Telegram配置
  telegram: {
    enabled: boolean;
    botToken: string;
    chatId: string;
    notificationEnabled: boolean;
  };

  // 数据库配置
  database: {
    url: string;
    type: 'sqlite' | 'postgresql' | 'mysql';
    maxConnections: number;
    connectionTimeout: number;
  };

  // 性能配置
  performance: {
    maxConcurrentRequests: number;
    requestTimeout: number;
    cacheTTL: number;
  };

  // 日志配置
  logging: {
    level: 'error' | 'warn' | 'info' | 'debug';
    file: string;
    maxSize: number;
    maxBackups: number;
  };
}
```

#### 3. 环境配置文件
```typescript
// config/development.ts
export const developmentConfig: Config = {
  app: {
    name: 'AutoClaw',
    version: '1.0.0',
    environment: 'development',
    debug: true
  },

  copilot: {
    enabled: true,
    language: 'typescript',
    maxTokens: 4096,
    cacheSize: 100
  },

  autoGpt: {
    enabled: true,
    maxTasks: 10,
    timeout: 3600000, // 1 hour
    cacheSize: 50
  },

  rag: {
    enabled: true,
    knowledgePath: './knowledge',
    retrievalTopK: 5,
    cacheSize: 30
  },

  promptEngineering: {
    enabled: true,
    templateLibrary: './prompt-templates',
    qualityCheckEnabled: true
  },

  telegram: {
    enabled: false, // 开发环境不启用
    botToken: '',
    chatId: '',
    notificationEnabled: false
  },

  database: {
    url: 'sqlite::memory:',
    type: 'sqlite',
    maxConnections: 10,
    connectionTimeout: 5000
  },

  performance: {
    maxConcurrentRequests: 10,
    requestTimeout: 30000,
    cacheTTL: 60000
  },

  logging: {
    level: 'debug',
    file: './logs/development.log',
    maxSize: 10485760, // 10MB
    maxBackups: 5
  }
};
```

```typescript
// config/production.ts
export const productionConfig: Config = {
  app: {
    name: 'AutoClaw',
    version: '1.0.0',
    environment: 'production',
    debug: false
  },

  copilot: {
    enabled: true,
    language: 'typescript',
    maxTokens: 8192,
    cacheSize: 500
  },

  autoGpt: {
    enabled: true,
    maxTasks: 50,
    timeout: 7200000, // 2 hours
    cacheSize: 200
  },

  rag: {
    enabled: true,
    knowledgePath: './knowledge',
    retrievalTopK: 10,
    cacheSize: 100
  },

  promptEngineering: {
    enabled: true,
    templateLibrary: './prompt-templates',
    qualityCheckEnabled: true
  },

  telegram: {
    enabled: true,
    botToken: process.env.TELEGRAM_BOT_TOKEN!,
    chatId: process.env.TELEGRAM_CHAT_ID!,
    notificationEnabled: true
  },

  database: {
    url: process.env.DATABASE_URL!,
    type: 'postgresql',
    maxConnections: 100,
    connectionTimeout: 10000
  },

  performance: {
    maxConcurrentRequests: 100,
    requestTimeout: 60000,
    cacheTTL: 300000 // 5 minutes
  },

  logging: {
    level: 'info',
    file: './logs/production.log',
    maxSize: 52428800, // 50MB
    maxBackups: 10
  }
};
```

#### 4. 配置验证器
```typescript
interface ConfigValidator {
  name: string;
  validate(config: Config): ValidationResult;
}

class RequiredValidator implements ConfigValidator {
  name = 'required';

  validate(config: Config): ValidationResult {
    const errors: ValidationError[] = [];
    const warnings: ValidationWarning[] = [];

    const requiredKeys: (keyof Config)[] = [
      'app.name',
      'app.version',
      'copilot.enabled',
      'autoGpt.enabled',
      'rag.enabled',
      'database.url',
      'logging.level'
    ];

    for (const key of requiredKeys) {
      const value = this.getNestedValue(config, key);
      if (!value) {
        errors.push(new ValidationError(`缺少必需配置: ${key}`));
      }
    }

    return { valid: errors.length === 0, errors, warnings };
  }

  private getNestedValue(obj: any, path: string): any {
    return path.split('.').reduce((acc, part) => acc?.[part], obj);
  }
}

class TypeValidator implements ConfigValidator {
  name = 'type';

  validate(config: Config): ValidationResult {
    const errors: ValidationError[] = [];
    const warnings: ValidationWarning[] = [];

    const typeChecks = [
      { key: 'app.version', expectedType: 'string' },
      { key: 'copilot.maxTokens', expectedType: 'number' },
      { key: 'autoGpt.maxTasks', expectedType: 'number' },
      { key: 'rag.retrievalTopK', expectedType: 'number' },
      { key: 'performance.maxConcurrentRequests', expectedType: 'number' }
    ];

    for (const check of typeChecks) {
      const value = this.getNestedValue(config, check.key);
      const actualType = typeof value;
      const expectedType = check.expectedType;

      if (actualType !== expectedType) {
        errors.push(new ValidationError(
          `配置类型错误: ${check.key} 期望 ${expectedType}，实际 ${actualType}`
        ));
      }
    }

    return { valid: errors.length === 0, errors, warnings };
  }

  private getNestedValue(obj: any, path: string): any {
    return path.split('.').reduce((acc, part) => acc?.[part], obj);
  }
}

class RangeValidator implements ConfigValidator {
  name = 'range';

  validate(config: Config): ValidationResult {
    const errors: ValidationError[] = [];
    const warnings: ValidationWarning[] = [];

    const rangeChecks = [
      { key: 'copilot.maxTokens', min: 100, max: 16384 },
      { key: 'autoGpt.maxTasks', min: 1, max: 100 },
      { key: 'performance.maxConcurrentRequests', min: 1, max: 1000 }
    ];

    for (const check of rangeChecks) {
      const value = this.getNestedValue(config, check.key);
      if (value !== undefined && (value < check.min || value > check.max)) {
        errors.push(new ValidationError(
          `配置值超出范围: ${check.key} 需要在 ${check.min}-${check.max} 之间`
        ));
      }
    }

    return { valid: errors.length === 0, errors, warnings };
  }

  private getNestedValue(obj: any, path: string): any {
    return path.split('.').reduce((acc, part) => acc?.[part], obj);
  }
}

class DatabaseUrlValidator implements ConfigValidator {
  name = 'database-url';

  validate(config: Config): ValidationResult {
    const errors: ValidationError[] = [];
    const warnings: ValidationWarning[] = [];

    if (config.database.url) {
      const protocol = new URL(config.database.url).protocol;
      const validProtocols = ['sqlite:', 'postgresql:', 'mysql:'];

      if (!validProtocols.includes(protocol)) {
        errors.push(new ValidationError(
          `数据库URL协议不支持: ${protocol}. 支持: ${validProtocols.join(', ')}`
        ));
      }
    }

    return { valid: errors.length === 0, errors, warnings };
  }
}
```

## 使用示例

### 初始化配置
```typescript
import { developmentConfig } from './config/development';
import { productionConfig } from './config/production';

// 创建配置管理器
const configManager = new ConfigurationManager(developmentConfig);

// 添加验证器
configManager.addValidator(new RequiredValidator());
configManager.addValidator(new TypeValidator());
configManager.addValidator(new RangeValidator());
configManager.addValidator(new DatabaseUrlValidator());

// 验证配置
const validation = configManager.validate();
console.log('配置验证:', validation);

if (!validation.valid) {
  console.error('配置错误:', validation.errors);
  process.exit(1);
}
```

### 环境切换
```typescript
// 切换到生产环境
configManager.loadEnvironment('production');

// 验证生产环境配置
const prodValidation = configManager.validate();
if (!prodValidation.valid) {
  console.error('生产环境配置错误:', prodValidation.errors);
  // 处理错误
}

// 访问配置
const maxTasks = configManager.get('autoGpt.maxTasks', 10);
console.log('最大任务数:', maxTasks);
```

### 配置访问
```typescript
// 单独访问配置项
const copilotEnabled = configManager.get('copilot.enabled', false);
const telegramEnabled = configManager.get('telegram.enabled', false);

// 获取完整配置
const fullConfig = configManager.getFullConfig();
console.log('完整配置:', JSON.stringify(fullConfig, null, 2));

// 监听配置变化
configManager.onChange((event, data) => {
  console.log(`配置变化: ${event}`, data);

  if (event === 'config-updated') {
    console.log(`配置项 ${data.key} 已更新为`, data.value);
  }

  if (event === 'environment-changed') {
    console.log(`切换到环境: ${data.environment}`);
  }
});

// 更新配置
configManager.set('copilot.maxTokens', 8192);
```

### 环境配置文件
```typescript
// 在应用启动时加载环境配置
async function loadConfig(environment: string): Promise<Config> {
  switch (environment) {
    case 'development':
      return await import('./config/development').then(m => m.developmentConfig);

    case 'staging':
      return await import('./config/staging').then(m => m.stagingConfig);

    case 'production':
      return await import('./config/production').then(m => m.productionConfig);

    default:
      throw new Error(`未知环境: ${environment}`);
  }
}

// 初始化应用
async function initializeApp() {
  const env = process.env.NODE_ENV || 'development';
  const config = await loadConfig(env);
  const configManager = new ConfigurationManager(config);

  // 验证配置
  const validation = configManager.validate();
  if (!validation.valid) {
    throw new Error('配置验证失败');
  }

  return configManager;
}

const configManager = await initializeApp();
```

## 配置同步

### 多环境同步
```typescript
class ConfigSynchronizer {
  constructor(private configManager: ConfigurationManager) {}

  syncToAllEnvironments(): void {
    const fullConfig = this.configManager.getFullConfig();

    for (const env of this.configManager.getEnvironments()) {
      if (env !== this.configManager.currentEnvironment) {
        this.syncToEnvironment(env, fullConfig);
      }
    }
  }

  private syncToEnvironment(env: string, config: Config): void {
    // 检查是否需要同步
    const envConfig = this.configManager.environments.get(env);
    const needsSync = this.needsSync(envConfig, config);

    if (needsSync) {
      this.configManager.loadEnvironment(env);
      this.configManager.setFullConfig(config);
      this.configManager.save();
      console.log(`已同步到环境: ${env}`);
    }
  }

  private needsSync(envConfig: Config, currentConfig: Config): boolean {
    // 检查是否需要同步
    return true;
  }
}
```

## 配置备份

### 配置版本管理
```typescript
class ConfigBackup {
  private backups: Map<string, ConfigBackupEntry> = new Map();

  backupConfig(configManager: ConfigurationManager): void {
    const entry: ConfigBackupEntry = {
      timestamp: Date.now(),
      config: configManager.getFullConfig(),
      version: configManager.getVersion(),
      environment: configManager.currentEnvironment
    };

    const key = this.generateKey(configManager.currentEnvironment, entry.version);
    this.backups.set(key, entry);

    // 限制备份数量
    this.limitBackups();
  }

  restoreConfig(environment: string, version: number): void {
    const key = this.generateKey(environment, version);
    const backup = this.backups.get(key);

    if (!backup) {
      throw new Error(`备份不存在: ${environment} v${version}`);
    }

    // 恢复配置
    this.restoreTo(backup.config);
  }

  private generateKey(environment: string, version: number): string {
    return `${environment}-v${version}`;
  }

  private limitBackups(): void {
    const backups = Array.from(this.backups.values())
      .sort((a, b) => b.timestamp - a.timestamp);

    // 保留最近10个备份
    if (backups.length > 10) {
      backups.slice(10).forEach(b => this.backups.delete(this.generateKey(
        b.environment,
        b.version
      )));
    }
  }
}
```

## 配置导出和导入

### 导出配置
```typescript
class ConfigExporter {
  async exportConfig(configManager: ConfigurationManager): Promise<Buffer> {
    const config = configManager.getFullConfig();
    const exportData = {
      exportDate: new Date().toISOString(),
      environment: configManager.currentEnvironment,
      version: configManager.getVersion(),
      config
    };

    return Buffer.from(JSON.stringify(exportData, null, 2), 'utf-8');
  }
}
```

### 导入配置
```typescript
class ConfigImporter {
  async importConfig(buffer: Buffer): Promise<Config> {
    const exportData = JSON.parse(buffer.toString('utf-8'));

    // 验证导出数据
    if (!exportData.config || !exportData.version) {
      throw new Error('无效的配置导出数据');
    }

    return exportData.config;
  }
}
```

## 最佳实践

1. **环境隔离**: 为每个环境维护独立的配置文件
2. **敏感信息**: 将敏感信息放在环境变量中
3. **配置验证**: 始终验证配置的有效性
4. **版本管理**: 保存配置的历史版本
5. **变更通知**: 监听配置变化并通知相关组件
6. **文档齐全**: 为每个配置项提供详细的文档

## 使用建议

1. **开发环境**: 使用 `development.ts`
2. **测试环境**: 使用 `staging.ts`
3. **生产环境**: 使用 `production.ts`
4. **配置导入**: 使用 `.env` 文件
5. **配置验证**: 启动时验证所有配置

## 扩展指南

开发者可以添加自定义验证器：
```typescript
class CustomValidator implements ConfigValidator {
  name = 'custom';

  validate(config: Config): ValidationResult {
    const errors: ValidationError[] = [];
    const warnings: ValidationWarning[] = [];

    // 自定义验证逻辑
    if (config.myCustomSetting > 100) {
      errors.push(new ValidationError('自定义设置超出范围'));
    }

    return { valid: errors.length === 0, errors, warnings };
  }
}

// 注册自定义验证器
configManager.addValidator(new CustomValidator());
```
