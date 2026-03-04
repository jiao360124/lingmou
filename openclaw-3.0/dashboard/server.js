/**
 * Dashboard Server
 * 使用统一配置、日志、错误处理和缓存系统
 */

const express = require('express');
const config = require('../config/dashboard.config');
const logger = require('../utils/logger');
const errorHandler = require('../utils/error-handler');
const cache = require('../utils/cache');

const app = express();
const PORT = config.port;
const HOST = config.server.host;

// ==================== 中间件 ====================

// JSON 解析
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 请求日志
app.use((req, res, next) => {
  const start = Date.now();

  res.on('finish', () => {
    const duration = Date.now() - start;
    logger.request(req.method, req.url, res.statusCode, duration, {
      ip: req.ip,
      userAgent: req.get('user-agent'),
      method: req.method,
    });
  });

  next();
});

// 缓存中间件
if (config.cache.enabled) {
  logger.info('Cache middleware enabled', {
    ttl: `${config.cache.ttl}ms`,
    sizeLimit: `${config.cache.memoryLimit}MB`,
  });

  app.use(cache.middleware(config.cache.ttl));
} else {
  logger.debug('Cache middleware disabled');
}

// ==================== 路由 ====================

// 健康检查
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
  });
});

// API 端点
app.get('/api/stats', errorHandler.catchAsync(async (req, res, next) => {
  logger.debug('Stats API requested');

  const stats = {
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    timestamp: new Date().toISOString(),
  };

  res.json(stats);
}));

app.get('/api/dashboard', errorHandler.catchAsync(async (req, res, next) => {
  logger.debug('Dashboard data requested');

  const dashboardData = {
    system: await getSystemStats(),
    metrics: await getMetrics(),
    charts: await getChartData(),
  };

  res.json(dashboardData);
}));

// ==================== 辅助函数 ====================

async function getSystemStats() {
  return {
    cpu: process.cpuUsage(),
    memory: process.memoryUsage(),
    uptime: process.uptime(),
  };
}

async function getMetrics() {
  // TODO: 从实际数据源获取指标
  return {
    requests: 1234,
    errors: 12,
    successRate: 99.0,
    avgResponseTime: 150,
    totalRequests: 15000,
  };
}

async function getChartData() {
  // TODO: 从实际数据源获取图表数据
  return {
    cost: {
      labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      data: [120, 135, 128, 142, 130, 115, 125],
    },
    models: {
      labels: ['GLM-4', 'GPT-4', 'Claude'],
      data: [45, 30, 25],
    },
    fallbacks: {
      labels: ['1min', '5min', '15min', '30min', '1h'],
      data: [95, 92, 88, 85, 82],
    },
    latency: {
      labels: ['p50', 'p95', 'p99'],
      data: [120, 250, 380],
    },
  };
}

// ==================== 错误处理 ====================

// 404 处理
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Route ${req.method} ${req.url} not found`,
  });
});

// 全局错误处理
app.use((err, req, res, next) => {
  logger.errorWithStack(err, {
    url: req.url,
    method: req.method,
    ip: req.ip,
  });

  errorHandler.sendErrorResponse(res, err, 500);
});

// ==================== 启动 ====================

function startServer() {
  return new Promise((resolve, reject) => {
    const server = app.listen(PORT, HOST, () => {
      logger.info('Dashboard server started', {
        port: PORT,
        host: HOST,
        cacheEnabled: config.cache.enabled,
        refreshEnabled: config.refresh.enabled,
      });

      resolve(server);
    });

    server.on('error', (error) => {
      logger.error('Dashboard server failed to start', {
        error: error.message,
      });
      reject(error);
    });
  });
}

// Graceful shutdown
async function gracefulShutdown(signal) {
  logger.info('Graceful shutdown started', { signal });

  try {
    // 关闭服务器
    logger.info('Dashboard server stopped');
    process.exit(0);
  } catch (error) {
    logger.error('Error during shutdown', { error: error.message });
    process.exit(1);
  }
}

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// 导出
module.exports = {
  app,
  startServer,
};
