// openclaw-3.0/dashboard-server.js
// Dashboard Server - 集成真实数据源

const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const cors = require('cors');
const DataService = require('./data-service');

// Express 应用
const app = express();

// CORS 中间件
app.use(cors());

// Body 解析中间件
app.use(express.json());

// WebSocket 服务器
const server = http.createServer(app);

const wss = new WebSocket.Server({
  server,
  path: '/ws'
});

// 数据服务
const dataService = new DataService({
  cacheDuration: 30000 // 30秒缓存
});

// API 端点 - 状态
app.get('/api/status', async (req, res) => {
  try {
    const data = await dataService.updateCache();
    res.json({
      timestamp: Date.now(),
      uptime: data.status.uptime,
      requests: data.status.requests,
      performance: data.status.performance,
      models: data.status.models,
      switcher: data.status.switcher
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// API 端点 - 模型
app.get('/api/models', async (req, res) => {
  try {
    const data = await dataService.updateCache();
    res.json(data.models);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// API 端点 - 趋势
app.get('/api/trends', async (req, res) => {
  try {
    const data = await dataService.updateCache();
    res.json(data.trends);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// API 端点 - Fallbacks
app.get('/api/fallbacks', async (req, res) => {
  try {
    const data = await dataService.updateCache();
    res.json(data.fallbacks);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 保存日志到文件
app.post('/api/logs/save', async (req, res) => {
  try {
    const { filename } = req.body;
    await dataService.saveLogs(filename || 'dashboard-logs.json');
    res.json({ success: true, message: 'Logs saved successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// WebSocket 连接处理
wss.on('connection', (ws) => {
  console.log('🔗 New client connected');

  // 发送初始数据
  dataService.updateCache().then(data => {
    ws.send(JSON.stringify({
      type: 'init',
      data: data
    }));
  });

  // 定时推送更新
  const interval = setInterval(() => {
    if (ws.readyState === WebSocket.OPEN) {
      dataService.updateCache().then(data => {
        ws.send(JSON.stringify({
          type: 'update',
          data: data
        }));
      });
    }
  }, 60000); // 60秒

  // 连接关闭
  ws.on('close', () => {
    console.log('❌ Client disconnected');
    clearInterval(interval);
  });

  // 错误处理
  ws.on('error', (error) => {
    console.error('WebSocket error:', error);
  });
});

// 启动服务器
const PORT = process.env.PORT || 8080;

server.listen(PORT, () => {
  console.log('\n=================================================');
  console.log('🚀 Dashboard Server Started');
  console.log('=================================================');
  console.log(`📍 Dashboard: http://127.0.0.1:${PORT}/`);
  console.log(`📡 WebSocket: ws://127.0.0.1:${PORT}/ws`);
  console.log(`⏰ Update Interval: 60s`);
  console.log(`💾 Cache Duration: 30s`);
  console.log('=================================================\n');

  // 初始缓存更新
  dataService.updateCache().then(() => {
    console.log('✅ Initial data cache updated');
  }).catch(error => {
    console.error('❌ Failed to initialize cache:', error.message);
  });
});

// 优雅关闭
process.on('SIGTERM', () => {
  console.log('\n🛑 Shutting down gracefully...');
  server.close(() => {
    console.log('✅ Server closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('\n🛑 Shutting down gracefully...');
  server.close(() => {
    console.log('✅ Server closed');
    process.exit(0);
  });
});

module.exports = { app, server, dataService };
