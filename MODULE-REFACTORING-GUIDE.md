# 模块重构指导 - Phase 2 依赖优化

## 目标
消除循环依赖，统一使用新的配置和工具系统

---

## 1. Dashboard 模块重构

### 1.1 当前问题
- 配置分散在多个文件中
- 没有统一的错误处理
- 没有日志系统
- 没有缓存机制

### 1.2 重构方案

#### 步骤 1: 引入配置系统
```javascript
// dashboard/server.js
const config = require('../config/dashboard.config');

// 端口配置
const PORT = config.port;

// 服务器配置
const HOST = config.server.host;
const TIMEOUT = config.server.timeout;

// 缓存配置
const CACHE_ENABLED = config.cache.enabled;
const CACHE_TTL = config.cache.ttl;

// 数据刷新配置
const REFRESH_ENABLED = config.refresh.enabled;
const REFRESH_INTERVAL = config.refresh.interval;

// API 配置
const API_ENABLED = config.api.enabled;
```

#### 步骤 2: 引入日志系统
```javascript
const logger = require('../utils/logger');

// 启动日志
logger.info('Dashboard server starting', {
  port: PORT,
  host: HOST,
  cacheEnabled: CACHE_ENABLED,
  refreshEnabled: REFRESH_ENABLED,
});

// 请求日志
app.use((req, res, next) => {
  const start = Date.now();

  res.on('finish', () => {
    const duration = Date.now() - start;
    logger.request(req.method, req.url, res.statusCode, duration);
  });

  next();
});

// 错误日志
app.use((err, req, res, next) => {
  logger.errorWithStack(err, {
    url: req.url,
    method: req.method,
  });
  next(err);
});
```

#### 步骤 3: 引入错误处理
```javascript
const errorHandler = require('../utils/error-handler');

// API 错误处理
app.get('/api/data', errorHandler.catchAsync(async (req, res, next) => {
  const data = await fetchData();
  res.json(data);
}));

// 错误响应
app.use((err, req, res, next) => {
  errorHandler.sendErrorResponse(res, err, 500);
});
```

#### 步骤 4: 引入缓存机制
```javascript
const NodeCache = require('node-cache');

// 创建缓存实例
const cache = new NodeCache({
  stdTTL: CACHE_TTL / 1000, // 转换为秒
  checkperiod: 600,
  useClones: false,
});

// 缓存中间件
function cacheMiddleware(duration) {
  return (req, res, next) => {
    const key = req.originalUrl;
    const cachedData = cache.get(key);

    if (cachedData) {
      logger.debug('Cache hit', { key });
      return res.json(cachedData);
    }

    logger.debug('Cache miss', { key });

    // 保存原始 json 函数
    const originalJson = res.json.bind(res);

    res.json = (data) => {
      cache.set(key, data, duration);
      return originalJson(data);
    };

    next();
  };
}

// 使用缓存
if (CACHE_ENABLED) {
  app.use(cacheMiddleware(CACHE_TTL));
}
```

### 1.3 重构后的代码结构

```javascript
// dashboard/server.js
const express = require('express');
const config = require('../config/dashboard.config');
const logger = require('../utils/logger');
const errorHandler = require('../utils/error-handler');
const cache = require('../utils/cache'); // 新建

const app = express();
const PORT = config.port;
const HOST = config.server.host;

// 中间件
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 缓存（如果启用）
if (config.cache.enabled) {
  app.use(cache.middleware(config.cache.ttl));
}

// 请求日志
app.use((req, res, next) => {
  logger.request(req.method, req.url, 200, 0);
  next();
});

// API 路由
app.get('/api/stats', errorHandler.catchAsync(async (req, res, next) => {
  const stats = await getStats();
  res.json(stats);
}));

// 错误处理
app.use((err, req, res, next) => {
  errorHandler.sendErrorResponse(res, err, 500);
});

// 启动服务器
app.listen(PORT, HOST, () => {
  logger.info('Dashboard server started', {
    port: PORT,
    host: HOST,
    cache: config.cache.enabled,
  });
});

module.exports = app;
```

---

## 2. Reports 模块重构

### 2.1 当前问题
- 配置分散
- 没有统一的错误处理
- 没有重试机制
- 邮件发送没有错误处理

### 2.2 重构方案

#### 步骤 1: 引入配置系统
```javascript
// report-sender.js
const config = require('../config/report.config');

// 报告发送配置
const SENDER_ENABLED = config.sender.enabled;
const RETRY_MAX_RETRIES = config.sender.retry.maxRetries;
const RETRY_DELAY = config.sender.retry.delay;
const RETRY_BACKOFF = config.sender.retry.backoff;

// Telegram 配置
const TELEGRAM_ENABLED = config.telegram.enabled;
const TELEGRAM_BOT_TOKEN = config.telegram.botToken;
const TELEGRAM_CHAT_ID = config.telegram.chatId;

// 邮件配置
const EMAIL_ENABLED = config.email.enabled;
const EMAIL_SMTP_HOST = config.email.smtp.host;
const EMAIL_SMTP_PORT = config.email.smtp.port;
const EMAIL_FROM = config.email.from;
```

#### 步骤 2: 引入重试机制
```javascript
const retryManager = require('../utils/retry');

// 重试发送报告
async function sendReport(report, retries = RETRY_MAX_RETRIES) {
  return retryManager.execute('report-sender', async () => {
    if (TELEGRAM_ENABLED) {
      return await sendTelegram(report);
    }

    if (EMAIL_ENABLED) {
      return await sendEmail(report);
    }

    throw new Error('No sender enabled');
  });
}

// Telegram 发送（带重试）
async function sendTelegram(report) {
  return retryManager.execute('telegram', async () => {
    const response = await fetch(`https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        chat_id: TELEGRAM_CHAT_ID,
        text: report,
        parse_mode: 'markdown',
      }),
    });

    const data = await response.json();

    if (!data.ok) {
      throw new Error(`Telegram API error: ${data.description}`);
    }

    return data;
  });
}
```

#### 步骤 3: 引入错误处理
```javascript
const errorHandler = require('../utils/error-handler');

// 发送报告
async function sendReport(report) {
  try {
    logger.info('Sending report', {
      telegramEnabled: TELEGRAM_ENABLED,
      emailEnabled: EMAIL_ENABLED,
    });

    // 发送报告
    await sendTelegram(report);

    logger.info('Report sent successfully');
  } catch (error) {
    // 记录错误
    logger.error('Failed to send report', {
      error: error.message,
      telegramEnabled: TELEGRAM_ENABLED,
      emailEnabled: EMAIL_ENABLED,
    });

    // 抛出错误供全局错误处理器捕获
    throw errorHandler.createError(
      ErrorType.SERVICE_ERROR,
      `Failed to send report: ${error.message}`,
      { error }
    );
  }
}
```

### 2.3 重构后的代码结构

```javascript
// report-sender.js
const logger = require('../utils/logger');
const errorHandler = require('../utils/error-handler');
const retryManager = require('../utils/retry');
const config = require('../config/report.config');

const TELEGRAM_ENABLED = config.telegram.enabled;
const EMAIL_ENABLED = config.email.enabled;

// Telegram 发送
async function sendTelegram(report) {
  return retryManager.execute('telegram-sender', async () => {
    const response = await fetch(`https://api.telegram.org/bot${config.telegram.botToken}/sendMessage`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        chat_id: config.telegram.chatId,
        text: report,
        parse_mode: 'markdown',
      }),
    });

    const data = await response.json();

    if (!data.ok) {
      throw new Error(`Telegram API error: ${data.description}`);
    }

    logger.info('Telegram report sent');
    return data;
  });
}

// 邮件发送
async function sendEmail(report) {
  // TODO: 使用 nodemailer 发送邮件
  logger.info('Email report sending not implemented');
}

// 主发送函数
async function sendReport(report) {
  try {
    if (TELEGRAM_ENABLED) {
      await sendTelegram(report);
    } else if (EMAIL_ENABLED) {
      await sendEmail(report);
    } else {
      throw errorHandler.createError(
        ErrorType.CONFIG_ERROR,
        'No sender configured (telegram or email)'
      );
    }

    logger.info('Report sent successfully');
  } catch (error) {
    logger.error('Failed to send report', {
      error: error.message,
      telegramEnabled: TELEGRAM_ENABLED,
      emailEnabled: EMAIL_ENABLED,
    });
    throw error;
  }
}

module.exports = { sendReport, sendTelegram, sendEmail };
```

---

## 3. Cron Scheduler 模块重构

### 3.1 当前问题
- 配置分散
- 没有统一的日志
- 没有错误处理
- 没有重试机制

### 3.2 重构方案

#### 步骤 1: 引入配置系统
```javascript
// cron-scheduler/index.js
const config = require('../config/cron.config');

// 调度器配置
const SCHEDULER_ENABLED = config.scheduler.enabled;
const SCHEDULER_TIMEZONE = config.scheduler.timezone;
const MAX_CONCURRENT_JOBS = config.scheduler.maxConcurrentJobs;

// Job 配置
const GATEWAY_CHECK_ENABLED = config.jobs.gatewayCheck.enabled;
const GATEWAY_CHECK_INTERVAL = config.jobs.gatewayCheck.interval;
const GATEWAY_CHECK_ALERT = config.jobs.gatewayCheck.alertOnFailure;

const HEARTBEAT_CHECK_ENABLED = config.jobs.heartbeatCheck.enabled;
const HEARTBEAT_CHECK_INTERVAL = config.jobs.heartbeatCheck.interval;

const DAILY_REPORT_ENABLED = config.jobs.dailyReport.enabled;
const DAILY_REPORT_SCHEDULE = config.jobs.dailyReport.schedule;
const DAILY_REPORT_TIMEZONE = config.jobs.dailyReport.timezone;

const WEEKLY_REPORT_ENABLED = config.jobs.weeklyReport.enabled;
const WEEKLY_REPORT_SCHEDULE = config.jobs.weeklyReport.schedule;
const WEEKLY_REPORT_TIMEZONE = config.jobs.weeklyReport.timezone;
```

#### 步骤 2: 引入日志系统
```javascript
const logger = require('../utils/logger');

// Job 执行日志
function logJobExecution(jobName, status, details = {}) {
  logger.info(`Job execution: ${jobName}`, {
    status,
    ...details,
  });
}

// 错误日志
function logJobError(jobName, error, context = {}) {
  logger.error(`Job failed: ${jobName}`, {
    error: error.message,
    ...context,
  });
}

// Job 成功日志
function logJobSuccess(jobName, duration, context = {}) {
  logger.info(`Job completed: ${jobName}`, {
    duration: `${duration}ms`,
    ...context,
  });
}
```

#### 步骤 3: 引入错误处理和重试
```javascript
const errorHandler = require('../utils/error-handler');
const retryManager = require('../utils/retry');

// Job 执行包装
async function executeJob(jobName, jobFn, context = {}) {
  const startTime = Date.now();

  try {
    logger.debug(`Job starting: ${jobName}`, { ...context });

    const result = await jobFn();

    const duration = Date.now() - startTime;
    logJobSuccess(jobName, duration, { ...context, result });

    return result;
  } catch (error) {
    const duration = Date.now() - startTime;
    logJobError(jobName, error, { ...context, duration });

    // 如果配置了错误通知，发送通知
    if (GATEWAY_CHECK_ALERT && jobName === 'gatewayCheck' && error.code === 'ECONNREFUSED') {
      await sendAlertNotification(error);
    }

    throw errorHandler.createError(
      ErrorType.SERVICE_ERROR,
      `Job ${jobName} failed: ${error.message}`,
      { error, ...context }
    );
  }
}

// 执行 Gateway 检查（带重试）
async function checkGateway() {
  return retryManager.execute('gateway-check', async () => {
    const result = await performGatewayCheck();
    return result;
  });
}
```

### 3.3 重构后的代码结构

```javascript
// cron-scheduler/index.js
const cron = require('node-cron');
const logger = require('../utils/logger');
const errorHandler = require('../utils/error-handler');
const retryManager = require('../utils/retry');
const config = require('../config/cron.config');

const SCHEDULER_ENABLED = config.scheduler.enabled;
const GATEWAY_CHECK_ENABLED = config.jobs.gatewayCheck.enabled;
const HEARTBEAT_CHECK_ENABLED = config.jobs.heartbeatCheck.enabled;

// 执行 Gateway 检查
async function performGatewayCheck() {
  try {
    const result = await fetchGatewayStatus();
    logger.info('Gateway check completed', result);
    return result;
  } catch (error) {
    logger.error('Gateway check failed', { error: error.message });
    throw error;
  }
}

// Gateway 检查 Job
function createGatewayCheckJob() {
  if (!GATEWAY_CHECK_ENABLED) return null;

  return cron.schedule(
    config.jobs.gatewayCheck.interval,
    async () => {
      logger.debug('Gateway check job triggered');
      await executeJob('gatewayCheck', performGatewayCheck);
    },
    { timezone: config.scheduler.timezone }
  );
}

// 心跳检查 Job
function createHeartbeatCheckJob() {
  if (!HEARTBEAT_CHECK_ENABLED) return null;

  return cron.schedule(
    config.jobs.heartbeatCheck.interval,
    async () => {
      logger.debug('Heartbeat check job triggered');
      await executeJob('heartbeatCheck', performHeartbeatCheck);
    },
    { timezone: config.scheduler.timezone }
  );
}

// 启动调度器
function startScheduler() {
  if (!SCHEDULER_ENABLED) {
    logger.warn('Cron scheduler disabled');
    return;
  }

  logger.info('Cron scheduler starting', {
    timezone: config.scheduler.timezone,
    jobs: {
      gatewayCheck: GATEWAY_CHECK_ENABLED,
      heartbeatCheck: HEARTBEAT_CHECK_ENABLED,
    },
  });

  // 创建 Job
  const gatewayJob = createGatewayCheckJob();
  const heartbeatJob = createHeartbeatCheckJob();

  return {
    gatewayJob,
    heartbeatJob,
    stop: () => {
      if (gatewayJob) gatewayJob.stop();
      if (heartbeatJob) heartbeatJob.stop();
      logger.info('Cron scheduler stopped');
    },
  };
}

module.exports = { startScheduler, executeJob, performGatewayCheck };
```

---

## 4. 统一中间件

### 4.1 错误处理中间件
```javascript
// middleware/error-handler.js
const errorHandler = require('../utils/error-handler');

function errorHandlerMiddleware() {
  return (err, req, res, next) => {
    errorHandler.sendErrorResponse(res, err, 500);
  };
}

function asyncHandler(fn) {
  return errorHandler.catchAsync(fn);
}

module.exports = { errorHandlerMiddleware, asyncHandler };
```

### 4.2 请求日志中间件
```javascript
// middleware/request-logger.js
const logger = require('../utils/logger');

function requestLoggerMiddleware() {
  return (req, res, next) => {
    const start = Date.now();

    res.on('finish', () => {
      const duration = Date.now() - start;
      logger.request(req.method, req.url, res.statusCode, duration, {
        ip: req.ip,
        userAgent: req.get('user-agent'),
      });
    });

    next();
  };
}

module.exports = { requestLoggerMiddleware };
```

---

## 5. 配置验证中间件

```javascript
// middleware/config-validator.js
const errorHandler = require('../utils/error-handler');
const ErrorType = errorHandler.ErrorType;

function validateConfig(config) {
  return (req, res, next) => {
    const errors = [];

    if (!config.apiKey) {
      errors.push('API key is required');
    }

    if (errors.length > 0) {
      const error = errorHandler.createError(
        ErrorType.CONFIG_ERROR,
        `Configuration validation failed: ${errors.join(', ')}`,
        { errors }
      );
      return next(error);
    }

    next();
  };
}

module.exports = { validateConfig };
```

---

## 6. 重构检查清单

### Dashboard 模块
- [ ] 引入配置系统（`dashboard.config.js`）
- [ ] 引入日志系统（`logger.js`）
- [ ] 引入错误处理（`error-handler.js`）
- [ ] 添加缓存机制
- [ ] 移除分散的配置
- [ ] 统一错误处理
- [ ] 添加请求日志

### Reports 模块
- [ ] 引入配置系统（`report.config.js`）
- [ ] 引入日志系统
- [ ] 引入错误处理
- [ ] 引入重试机制
- [ ] 重构 Telegram 发送
- [ ] 重构邮件发送
- [ ] 统一错误处理

### Cron Scheduler 模块
- [ ] 引入配置系统（`cron.config.js`）
- [ ] 引入日志系统
- [ ] 引入错误处理
- [ ] 引入重试机制
- [ ] 重构所有 Jobs
- [ ] 统一错误处理

---

## 7. 测试策略

### 7.1 单元测试
- 测试配置加载和验证
- 测试日志系统
- 测试错误处理
- 测试重试机制

### 7.2 集成测试
- 测试模块间的集成
- 测试端到端流程

### 7.3 性能测试
- 测试并发请求
- 测试缓存性能
- 测试错误处理性能

---

**文档版本**: 1.0
**更新时间**: 2026-02-16
**状态**: ✅ 重构指南完成
