// openclaw-3.0/dashboard-server.js
// Dashboard Server - 实时监控仪表板

const express = require('express');
const http = require('http');
const { WebSocketServer } = require('ws');
const fs = require('fs').promises;
const path = require('path');

const observability = require('./core/observability');
const circuitBreaker = require('./core/circuit-breaker');
const { tracker } = require('./core/model-scheduler');

const app = express();
const server = http.createServer(app);
const wss = new WebSocketServer({ server });

// 配置
const CONFIG = {
  port: process.env.PORT || 8080,
  cacheDuration: 5 * 60 * 1000, // 5 分钟缓存
  interval: 60000, // 60 秒更新
  dashboardPath: path.join(__dirname, 'dashboard')
};

// 缓存数据
let cache = {
  lastUpdate: 0,
  status: null,
  models: null,
  trends: null,
  fallbacks: null
};

/**
 * 📊 获取核心状态
 */
function getStatus() {
  const summary = observability.getSummary();
  const switcher = require('./core/dynamic-primary-switcher');
  const status = switcher.getStatus();

  return {
    timestamp: Date.now(),
    uptime: summary.uptime,
    requests: {
      total: summary.totalRequests,
      success: summary.totalRequests - summary.totalFailures,
      failures: summary.totalFailures,
      fallbacks: summary.totalFallbacks,
      successRate: summary.totalRequests > 0
        ? ((summary.totalRequests - summary.totalFailures) / summary.totalRequests * 100).toFixed(2) + '%'
        : '0%'
    },
    performance: {
      avgLatency: summary.averageLatency.toFixed(0) + 'ms',
      tokenUsage: `${summary.cost.toFixed(4)} tokens`
    },
    models: {
      total: Object.keys(summary.modelUsage).length,
      details: summary.modelUsage
    },
    switcher: {
      primaryModel: status.primaryModel,
      isSwitched: status.isSwitched,
      zaiHealth: status.zaiHealth
    }
  };
}

/**
 * 📊 获取模型使用数据
 */
function getModelUsage() {
  const report = observability.getModelUsageReport();
  return {
    timestamp: Date.now(),
    models: report
  };
}

/**
 * 📊 获取成本趋势数据
 */
function getCostTrend(hours = 24) {
  const trend = observability.getCostTrendReport(hours);
  return {
    timestamp: Date.now(),
    hours,
    trend: trend
  };
}

/**
 * 📊 获取 Fallback 数据
 */
function getFallbacks() {
  const report = observability.getFallbackReport();
  return {
    timestamp: Date.now(),
    totalFallbacks: report.totalFallbacks,
    fallbackLogs: report.fallbackLogs.slice(-50), // 最近 50 条
    fallbackByModel: report.fallbackByModel,
    fallbackByError: report.fallbackByError
  };
}

/**
 * 📊 获取 Circuit Breaker 状态
 */
function getCircuitBreakerStatus() {
  const cbStatus = {};
  for (const [name, cb] of circuitBreaker.circuitBreakers) {
    cbStatus[name] = cb.getStatus();
  }
  return cbStatus;
}

/**
 * 🔄 更新缓存数据
 */
async function updateCache() {
  cache.lastUpdate = Date.now();

  cache.status = getStatus();
  cache.models = getModelUsage();
  cache.trends = getCostTrend(24);
  cache.fallbacks = getFallbacks();

  console.log(`[Dashboard] Cache updated at ${new Date().toISOString()}`);
}

/**
 * 📡 WebSocket 连接处理
 */
wss.on('connection', (ws) => {
  console.log('[Dashboard] Client connected');

  // 发送初始数据
  ws.send(JSON.stringify({
    type: 'init',
    data: cache
  }));

  // 定时推送更新
  const interval = setInterval(() => {
    if (ws.readyState === WebSocketServer.OPEN) {
      ws.send(JSON.stringify({
        type: 'update',
        data: cache
      }));
    } else {
      clearInterval(interval);
    }
  }, CONFIG.interval);

  // 客户端关闭连接
  ws.on('close', () => {
    console.log('[Dashboard] Client disconnected');
    clearInterval(interval);
  });

  // 错误处理
  ws.on('error', (error) => {
    console.error('[Dashboard] WebSocket error:', error);
  });
});

/**
 * 🌐 API 路由
 */

// 根路径：仪表板
app.get('/', async (req, res) => {
  try {
    // 读取仪表板 HTML
    const html = await fs.readFile(path.join(CONFIG.dashboardPath, 'index.html'), 'utf-8');
    res.send(html);
  } catch (error) {
    console.error('[Dashboard] Failed to load dashboard:', error);
    res.status(500).send('Failed to load dashboard');
  }
});

// 核心状态 API
app.get('/api/status', (req, res) => {
  res.json(cache.status);
});

// 模型使用 API
app.get('/api/models', (req, res) => {
  res.json(cache.models);
});

// 成本趋势 API
app.get('/api/trends', (req, res) => {
  const hours = parseInt(req.query.hours) || 24;
  res.json(getCostTrend(hours));
});

// Fallback API
app.get('/api/fallbacks', (req, res) => {
  res.json(cache.fallbacks);
});

// Circuit Breaker API
app.get('/api/circuit-breaker', (req, res) => {
  res.json(getCircuitBreakerStatus());
});

// 初始化缓存
updateCache();

// 启动定时更新
setInterval(updateCache, CONFIG.interval);

// 启动服务器
server.listen(CONFIG.port, () => {
  console.log('');
  console.log('=================================================');
  console.log('🚀 Dashboard Server Started');
  console.log('=================================================');
  console.log(`📍 Dashboard: http://127.0.0.1:${CONFIG.port}/`);
  console.log(`📡 WebSocket: ws://127.0.0.1:${CONFIG.port}/`);
  console.log(`⏰ Update Interval: ${CONFIG.interval / 1000}s`);
  console.log(`💾 Cache Duration: ${CONFIG.cacheDuration / 1000}s`);
  console.log('=================================================');
  console.log('');
});

module.exports = { app, server };
