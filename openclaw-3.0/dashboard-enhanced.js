// openclaw-3.0/dashboard-enhanced.js
// 增强版 Dashboard - 集成配置文件支持

const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const cors = require('cors');
const DataService = require('./data-service');
const ConfigManager = require('./config');

// Express 应用
const app = express();

// CORS 中间件
app.use(cors());

// Body 解析中间件
app.use(express.json());

// 配置管理
const configManager = new ConfigManager({
  configDir: path.join(process.cwd(), 'config'),
  configFile: 'dashboard.config.json'
});

// WebSocket 服务器
const server = http.createServer(app);

const wss = new WebSocket.Server({
  server,
  path: configManager.get('websocket.path')
});

// 数据服务
const dataService = new DataService({
  cacheDuration: configManager.get('cache.duration'),
  maxLogs: configManager.get('cache.maxLogs')
});

// API 端点 - 配置
app.get('/api/config', (req, res) => {
  try {
    const config = configManager.getConfig();
    res.json({
      success: true,
      config
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/config/validate', (req, res) => {
  try {
    const validation = configManager.validateConfig();
    res.json(validation);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/config', async (req, res) => {
  try {
    const { config } = req.body;
    if (!config) {
      return res.status(400).json({ error: '配置不能为空' });
    }

    await configManager.updateConfig(config);
    res.json({
      success: true,
      message: '配置更新成功',
      config: configManager.getConfig()
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/config/reload', async (req, res) => {
  try {
    const config = await configManager.reloadConfig();
    res.json({
      success: true,
      message: '配置重载成功',
      config
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
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
      switcher: data.status.switcher,
      config: configManager.getConfig()
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

// API 端点 - 导出
app.post('/api/logs/export', async (req, res) => {
  try {
    const { format = 'json' } = req.body;
    const summary = dataService.getSummary();
    const modelReport = dataService.logger.getModelUsageReport();
    const costTrend = dataService.logger.getCostTrendReport(24);
    const fallbackReport = dataService.logger.getFallbackReport();

    let content;

    if (format === 'json') {
      content = JSON.stringify({
        summary,
        models: modelReport,
        trends: costTrend,
        fallback: fallbackReport
      }, null, 2);
    } else if (format === 'csv') {
      // CSV 导出
      let csv = '模型,调用次数,成功,失败,成功率,平均延迟,总成本,Fallback\n';
      modelReport.forEach(m => {
        csv += `${m.name},${m.totalCalls},${m.successCalls},${m.failureCalls},${m.usageRate},${m.avgLatency},${m.totalCost},${m.fallbackCount}\n`;
      });
      content = csv;
    }

    res.setHeader('Content-Type', `text/${format}`);
    res.setHeader('Content-Disposition', `attachment; filename=dashboard-report.${format}`);
    res.send(content);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/export/:format', async (req, res) => {
  try {
    const { format } = req.params;

    // 读取最近的日志文件
    const logFile = path.join(process.cwd(), 'test-dashboard-logs-500.json');
    if (!await fs.access(logFile).then(() => true).catch(() => false)) {
      return res.status(404).json({ error: 'No log file found' });
    }

    const logs = JSON.parse(await fs.readFile(logFile, 'utf-8'));

    if (format === 'json') {
      res.setHeader('Content-Type', 'application/json');
      res.setHeader('Content-Disposition', 'attachment; filename=dashboard-logs.json');
      res.json(logs);
    } else if (format === 'csv') {
      let csv = 'RequestId,Model,Success,Latency,CostEstimate,FallbackCount,ErrorType,Timestamp\n';
      logs.forEach(log => {
        csv += `${log.requestId},${log.modelName},${log.success},${log.latency},${log.costEstimate},${log.fallbackCount},${log.errorType || 'NONE'},${log.timestamp}\n`;
      });
      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', 'attachment; filename=dashboard-logs.csv');
      res.send(csv);
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// WebSocket 连接
wss.on('connection', (ws) => {
  console.log('🔗 New client connected');

  dataService.updateCache().then(data => {
    ws.send(JSON.stringify({ type: 'init', data, config: configManager.getConfig() }));
  });

  const interval = setInterval(() => {
    if (ws.readyState === WebSocket.OPEN) {
      dataService.updateCache().then(data => {
        ws.send(JSON.stringify({ type: 'update', data, config: configManager.getConfig() }));
      });
    }
  }, configManager.get('websocket.interval'));

  ws.on('close', () => {
    console.log('❌ Client disconnected');
    clearInterval(interval);
  });

  ws.on('error', (error) => {
    console.error('WebSocket error:', error);
  });
});

// 启动服务器
const PORT = configManager.get('server.port');
const HOST = configManager.get('server.host');

server.listen(PORT, HOST, () => {
  console.log('\n=================================================');
  console.log('🚀 Enhanced Dashboard Server Started');
  console.log('=================================================');
  console.log(`📍 Dashboard: http://${HOST}:${PORT}/`);
  console.log(`📡 WebSocket: ws://${HOST}:${PORT}${configManager.get('websocket.path')}`);
  console.log(`⏰ Update Interval: ${configManager.get('websocket.interval')}ms`);
  console.log(`💾 Cache Duration: ${configManager.get('cache.duration')}ms`);
  console.log(`📄 Config File: ${configManager.getConfigPath()}`);
  console.log('=================================================\n');

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

module.exports = { app, server, dataService, configManager };
