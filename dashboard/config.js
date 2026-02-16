/**
 * Dashboard Configuration
 */

module.exports = {
  // 服务器配置
  port: process.env.DASHBOARD_PORT || 3000,
  apiPrefix: '/api',
  cacheTime: 5 * 60 * 1000, // 5分钟

  // 健康检查
  healthCheck: {
    enabled: true,
    path: '/health',
    interval: 30 * 1000 // 30秒
  },

  // 数据配置
  data: {
    refreshInterval: 60 * 1000, // 60秒
    maxRetries: 3,
    retryDelay: 1000 // 1秒
  },

  // 日志配置
  logging: {
    level: process.env.LOG_LEVEL || 'info',
    format: 'json'
  },

  // 错误处理
  errorHandling: {
    sendStacktrace: process.env.NODE_ENV === 'development',
    sendLogs: process.env.NODE_ENV === 'development'
  }
};
