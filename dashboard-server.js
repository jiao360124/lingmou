/**
 * 🔮 创新Dashboard Server - 实时数据可视化平台
 * 创新点：3D 动态背景 + 玻璃拟态 UI + AI 智能洞察 + 实时数据流
 */

const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const path = require('path');
const { performance } = require('perf_hooks');

// 初始化
const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: "*" }
});

// 配置
const PORT = 3000;
const API_CACHE_TTL = 5 * 60 * 1000; // 5分钟缓存
const UPDATE_INTERVAL = 2000; // 2秒更新一次

// 全局缓存
const apiCache = new Map();

// 生成模拟数据
function generateMetrics() {
  const now = new Date();
  const hour = now.getHours();
  const minute = now.getMinutes();
  const second = now.getSeconds();

  return {
    // Token 使用情况
    tokenUsage: {
      current: Math.floor(Math.random() * 50000) + 10000,
      max: 100000,
      hourly: Array.from({ length: 24 }, (_, i) => ({
        hour: i,
        value: Math.floor(Math.random() * 80000) + 10000
      }))
    },

    // 模型性能
    modelPerformance: [
      { name: 'GLM-4.7', successRate: Math.floor(Math.random() * 15) + 85 },
      { name: 'GLM-4.5', successRate: Math.floor(Math.random() * 15) + 85 },
      { name: 'Trinity', successRate: Math.floor(Math.random() * 15) + 85 },
      { name: 'Claude-3', successRate: Math.floor(Math.random() * 15) + 85 },
    ],

    // Fallback 使用
    fallbackUsage: {
      total: Math.floor(Math.random() * 100),
      current: Math.floor(Math.random() * 10),
      byModel: [
        { model: 'GLM-4.7', count: Math.floor(Math.random() * 50) },
        { model: 'GLM-4.5', count: Math.floor(Math.random() * 30) },
        { model: 'Trinity', count: Math.floor(Math.random() * 20) },
      ]
    },

    // 延迟情况
    latency: {
      current: Math.floor(Math.random() * 200) + 50,
      p95: Math.floor(Math.random() * 300) + 100,
      p99: Math.floor(Math.random() * 500) + 200,
      history: Array.from({ length: 60 }, () => ({
        timestamp: new Date(Date.now() - (59 - Math.random() * 59) * 1000),
        value: Math.floor(Math.random() * 300) + 50
      }))
    },

    // 系统健康度
    healthScore: {
      overall: Math.floor(Math.random() * 30) + 70,
      components: {
        stability: Math.floor(Math.random() * 20) + 80,
        cost: Math.floor(Math.random() * 30) + 70,
        performance: Math.floor(Math.random() * 20) + 80,
        security: Math.floor(Math.random() * 10) + 90
      }
    },

    // API 响应时间
    apiResponseTime: {
      avg: Math.floor(Math.random() * 50) + 10,
      min: Math.floor(Math.random() * 20) + 5,
      max: Math.floor(Math.random() * 100) + 50
    },

    // 智能洞察（AI分析）
    aiInsights: generateAIInsights(),

    // 3D 背景粒子数据
    particles: Array.from({ length: 100 }, (_, i) => ({
      id: i,
      x: Math.random() * 100,
      y: Math.random() * 100,
      z: Math.random() * 100,
      size: Math.random() * 3 + 1,
      speed: Math.random() * 0.5 + 0.5,
      color: getRandomColor()
    }))
  };
}

// 生成 AI 智能洞察
function generateAIInsights() {
  const insights = [];

  // Token 使用趋势
  const hourlyChange = Math.random() > 0.5 ? '上升' : '下降';
  if (hourlyChange === '上升') {
    insights.push({
      type: 'warning',
      icon: '📈',
      title: 'Token 使用量上升',
      description: `过去1小时 Token 使用量${hourlyChange}，当前使用率 ${Math.floor(Math.random() * 30) + 50}%`,
      recommendation: '考虑在非高峰时段执行批量任务'
    });
  } else {
    insights.push({
      type: 'info',
      icon: '✅',
      title: 'Token 使用量平稳',
      description: `过去1小时 Token 使用量${hourlyChange}，当前使用率 ${Math.floor(Math.random() * 30) + 50}%`,
      recommendation: null
    });
  }

  // 模型性能
  const bestModel = ['GLM-4.7', 'GLM-4.5', 'Trinity'][Math.floor(Math.random() * 3)];
  insights.push({
    type: 'success',
    icon: '🏆',
    title: `${bestModel} 性能最佳`,
    description: `该模型成功率最高 (${Math.floor(Math.random() * 5) + 90}%)`,
    recommendation: `建议将 ${bestModel} 作为默认模型`
  });

  // 延迟优化
  if (Math.random() > 0.7) {
    insights.push({
      type: 'tip',
      icon: '⚡',
      title: '延迟优化建议',
      description: 'P95 延迟较高，建议优化缓存策略',
      recommendation: '增加 Redis 缓存层'
    });
  }

  // 成本优化
  if (Math.random() > 0.6) {
    insights.push({
      type: 'money',
      icon: '💰',
      title: '成本优化机会',
      description: '非高峰时段 Token 成本可降低 30%',
      recommendation: '使用定价较低的模型处理批量任务'
    });
  }

  return insights;
}

// 获取随机颜色
function getRandomColor() {
  const colors = [
    { r: 99, g: 102, b: 241 },   // Indigo
    { r: 236, g: 72, b: 153 },   // Pink
    { r: 34, g: 197, b: 94 },    // Green
    { r: 59, g: 130, b: 246 },   // Blue
    { r: 245, g: 158, b: 11 },   // Amber
  ];
  return colors[Math.floor(Math.random() * colors.length)];
}

// 缓存管理
function getCachedMetrics() {
  const now = Date.now();
  for (const [key, value] of apiCache.entries()) {
    if (now - value.timestamp > API_CACHE_TTL) {
      apiCache.delete(key);
    }
  }

  if (apiCache.has('metrics')) {
    return apiCache.get('metrics').data;
  }

  return null;
}

function setCachedMetrics(data) {
  apiCache.set('metrics', {
    data,
    timestamp: Date.now()
  });
}

// REST API 端点
app.get('/api/metrics', (req, res) => {
  const cached = getCachedMetrics();
  if (cached) {
    return res.json(cached);
  }

  const metrics = generateMetrics();
  setCachedMetrics(metrics);
  res.json(metrics);
});

app.get('/api/health', (req, res) => {
  res.json({
    status: 'healthy',
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});

app.get('/api/insights', (req, res) => {
  res.json({
    insights: generateAIInsights(),
    timestamp: new Date().toISOString()
  });
});

app.get('/api/config', (req, res) => {
  res.json({
    theme: 'dark',
    updateInterval: UPDATE_INTERVAL,
    cacheTTL: API_CACHE_TTL
  });
});

// 前端路由
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'dashboard.html'));
});

app.get('/dashboard', (req, res) => {
  res.sendFile(path.join(__dirname, 'dashboard.html'));
});

// 静态文件
app.use(express.static(path.join(__dirname, 'public')));

// WebSocket 实时推送
let lastMetrics = null;
let updateTimer = null;

function startRealTimeUpdate() {
  // 立即更新一次
  updateMetrics();

  // 定时更新
  updateTimer = setInterval(() => {
    updateMetrics();
  }, UPDATE_INTERVAL);
}

function updateMetrics() {
  const metrics = generateMetrics();
  lastMetrics = metrics;

  // 广播给所有连接的客户端
  io.emit('metricsUpdate', metrics);

  // 更新缓存
  setCachedMetrics(metrics);
}

// WebSocket 连接处理
io.on('connection', (socket) => {
  console.log('🟢 Client connected:', socket.id);

  // 发送当前数据
  if (lastMetrics) {
    socket.emit('init', lastMetrics);
  } else {
    socket.emit('init', generateMetrics());
  }

  // 监听客户端事件
  socket.on('subscribe', (channel) => {
    socket.join(channel);
    console.log('📡 Client subscribed to:', channel);
  });

  socket.on('unsubscribe', (channel) => {
    socket.leave(channel);
    console.log('📤 Client unsubscribed from:', channel);
  });

  socket.on('disconnect', () => {
    console.log('🔴 Client disconnected:', socket.id);
  });
});

// 错误处理
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({ error: 'Internal Server Error' });
});

// 启动服务器
server.listen(PORT, () => {
  console.log(`
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║  🔮 创新Dashboard Server - 实时数据可视化平台            ║
║                                                            ║
║  🌐 访问地址: http://localhost:${PORT}                   ║
║  📊 API: http://localhost:${PORT}/api/metrics             ║
║  🔌 WebSocket: ws://localhost:${PORT}                     ║
║  ⚡ 更新间隔: ${UPDATE_INTERVAL}ms (${UPDATE_INTERVAL/1000}s) ║
║  💾 缓存 TTL: ${API_CACHE_TTL/60000}分钟                  ║
║                                                            ║
║  ✨ 创新特性:                                              ║
║    - 3D 动态背景                                          ║
║    - 玻璃拟态 UI                                          ║
║    - AI 智能洞察                                          ║
║    - 实时数据流                                           ║
║    - 可定制 Widgets                                       ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
  `);
});

// 优雅关闭
process.on('SIGINT', () => {
  console.log('\n🛑 Shutting down gracefully...');
  clearInterval(updateTimer);
  io.close();
  server.close(() => {
    console.log('✅ Server closed');
    process.exit(0);
  });
});

process.on('SIGTERM', () => {
  console.log('\n🛑 SIGTERM received, shutting down...');
  clearInterval(updateTimer);
  io.close();
  server.close(() => {
    console.log('✅ Server closed');
    process.exit(0);
  });
});

// 导出 API（用于测试）
module.exports = { app, server, io };
