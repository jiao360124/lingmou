/**
 * 数据获取服务
 * 从各种数据源获取系统指标、监控数据、统计信息
 */

const logger = require('../utils/logger');
const errorHandler = require('../utils/error-handler');
const retryManager = require('../utils/retry');
const { getConfig } = require('../config');

/**
 * 获取系统指标
 */
async function getSystemMetrics() {
  const startTime = Date.now();

  try {
    const metrics = {
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      cpu: {
        usage: process.cpuUsage(),
        loadAverage: process.cpuLoad ? process.cpuLoad() : null,
      },
      process: {
        pid: process.pid,
        version: process.version,
        platform: process.platform,
        arch: process.arch,
        uptime: process.uptime(),
      },
      node: {
        version: process.version,
        version: process.version,
        versions: process.versions,
      },
      env: {
        nodeEnv: process.env.NODE_ENV || 'development',
        nodeVersion: process.version,
      },
    };

    const duration = Date.now() - startTime;
    logger.performance('getSystemMetrics', duration);

    return metrics;
  } catch (error) {
    logger.errorWithStack(error, { operation: 'getSystemMetrics' });
    throw error;
  }
}

/**
 * 获取资源使用情况
 */
async function getResourceUsage() {
  const startTime = Date.now();

  try {
    const usage = {
      timestamp: new Date().toISOString(),
      memory: process.memoryUsage(),
      cpu: process.cpuUsage(),
    };

    // 获取系统级资源使用（如果可用）
    if (process.cpuLoad) {
      usage.cpuLoad = process.cpuLoad();
    }

    // 获取网络连接数（如果需要）
    usage.network = {
      connections: getNetworkConnections(),
      activeConnections: getActiveConnections(),
    };

    const duration = Date.now() - startTime;
    logger.performance('getResourceUsage', duration);

    return usage;
  } catch (error) {
    logger.errorWithStack(error, { operation: 'getResourceUsage' });
    throw error;
  }
}

/**
 * 获取进程列表
 */
async function getProcessList() {
  const startTime = Date.now();

  try {
    const processes = [];
    const pid = process.pid;

    // 获取当前进程信息
    processes.push({
      pid,
      name: process.title,
      cpu: process.cpuUsage(),
      memory: process.memoryUsage(),
    });

    // 尝试获取其他进程（需要适当的权限）
    try {
      const os = require('os');
      const cpus = os.cpus();
      processes.push({
        cpuCount: cpus.length,
        cpuModel: cpus[0].model,
      });
    } catch (error) {
      logger.warn('Could not get CPU info', { error: error.message });
    }

    const duration = Date.now() - startTime;
    logger.performance('getProcessList', duration);

    return processes;
  } catch (error) {
    logger.errorWithStack(error, { operation: 'getProcessList' });
    throw error;
  }
}

/**
 * 获取网络连接信息
 */
function getNetworkConnections() {
  try {
    const os = require('os');
    const net = require('net');
    const connections = net.connections();

    return {
      total: connections.length,
      sockets: connections.map(conn => ({
        localAddress: conn.localAddress,
        localPort: conn.localPort,
        remoteAddress: conn.remoteAddress,
        remotePort: conn.remotePort,
        type: conn.type,
        state: conn.state,
      })),
    };
  } catch (error) {
    logger.warn('Could not get network connections', { error: error.message });
    return { total: 0, sockets: [] };
  }
}

/**
 * 获取活跃连接数
 */
function getActiveConnections() {
  try {
    const os = require('os');
    const net = require('net');

    let activeCount = 0;
    net.Sockets().forEach(socket => {
      if (socket.state === 'ESTABLISHED') {
        activeCount++;
      }
    });

    return activeCount;
  } catch (error) {
    logger.warn('Could not get active connections', { error: error.message });
    return 0;
  }
}

/**
 * 获取系统负载
 */
async function getSystemLoad() {
  const startTime = Date.now();

  try {
    const os = require('os');

    const load = {
      timestamp: new Date().toISOString(),
      loadavg: os.loadavg(),
      cpus: os.cpus().length,
      uptime: os.uptime(),
    };

    // 获取 CPU 信息
    load.cpuModel = os.cpus()[0]?.model || 'Unknown';
    load.cpuSpeed = os.cpus()[0]?.speed || 0;

    // 获取内存信息
    const mem = os.totalmem();
    const freeMem = os.freemem();
    load.memory = {
      total: mem,
      free: freeMem,
      used: mem - freeMem,
      usagePercent: (freeMem / mem) * 100,
    };

    const duration = Date.now() - startTime;
    logger.performance('getSystemLoad', duration);

    return load;
  } catch (error) {
    logger.errorWithStack(error, { operation: 'getSystemLoad' });
    throw error;
  }
}

/**
 * 获取监控数据
 */
async function getMonitoringData() {
  const startTime = Date.now();

  try {
    const monitoring = {
      timestamp: new Date().toISOString(),
      system: await getSystemMetrics(),
      resources: await getResourceUsage(),
      load: await getSystemLoad(),
      processes: await getProcessList(),
    };

    const duration = Date.now() - startTime;
    logger.performance('getMonitoringData', duration);

    return monitoring;
  } catch (error) {
    logger.errorWithStack(error, { operation: 'getMonitoringData' });
    throw error;
  }
}

/**
 * 获取成本数据
 */
async function getCostData() {
  const startTime = Date.now();

  try {
    const config = getConfig();
    const costData = {
      timestamp: new Date().toISOString(),
      totalCost: await getTotalCost(),
      dailyCost: await getDailyCost(),
      hourlyCost: await getHourlyCost(),
      costByModel: await getCostByModel(),
      costByPeriod: await getCostByPeriod(),
    };

    const duration = Date.now() - startTime;
    logger.performance('getCostData', duration);

    return costData;
  } catch (error) {
    logger.errorWithStack(error, { operation: 'getCostData' });
    throw error;
  }
}

/**
 * 获取总成本
 */
async function getTotalCost() {
  try {
    const costFile = await getConfigFile('costs.json');
    const costs = costFile || {};

    // 计算总成本
    let total = 0;
    Object.values(costs).forEach(cost => {
      total += cost.amount || 0;
    });

    return {
      total,
      currency: 'USD',
      breakdown: costs,
    };
  } catch (error) {
    logger.errorWithStack(error, { operation: 'getTotalCost' });
    return { total: 0, currency: 'USD', breakdown: {} };
  }
}

/**
 * 获取每日成本
 */
async function getDailyCost() {
  try {
    const costFile = await getConfigFile('costs-daily.json');
    const today = new Date().toISOString().split('T')[0];

    return {
      today: costFile?.[today]?.amount || 0,
      previous: costFile?.[today] ? costFile[today - 1]?.amount || 0 : null,
      trend: costFile ? analyzeCostTrend(costFile) : null,
    };
  } catch (error) {
    logger.errorWithStack(error, { operation: 'getDailyCost' });
    return { today: 0, previous: null, trend: null };
  }
}

/**
 * 获取每小时成本
 */
async function getHourlyCost() {
  try {
    const costFile = await getConfigFile('costs-hourly.json');
    const now = new Date();
    const currentHour = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}:${String(now.getHours()).padStart(2, '0')}`;

    return {
      current: costFile?.[currentHour]?.amount || 0,
      previous: costFile?.[currentHour] ? costFile[`${currentHour}:00`]?.amount || 0 : null,
      trend: costFile ? analyzeCostTrend(costFile) : null,
    };
  } catch (error) {
    logger.errorWithStack(error, { operation: 'getHourlyCost' });
    return { current: 0, previous: null, trend: null };
  }
}

/**
 * 获取按模型的成本
 */
async function getCostByModel() {
  try {
    const costFile = await getConfigFile('costs-by-model.json');

    return {
      models: costFile || {},
      topSpenders: costFile ? getTopSpenders(costFile) : [],
    };
  } catch (error) {
    logger.errorWithStack(error, { operation: 'getCostByModel' });
    return { models: {}, topSpenders: [] };
  }
}

/**
 * 获取按时间段的成本
 */
async function getCostByPeriod() {
  try {
    const costFile = await getConfigFile('costs-by-period.json');

    return {
      periods: costFile || {},
      trends: costFile ? analyzeCostTrends(costFile) : null,
    };
  } catch (error) {
    logger.errorWithStack(error, { operation: 'getCostByPeriod' });
    return { periods: {}, trends: null };
  }
}

/**
 * 获取配置文件
 */
async function getConfigFile(filename) {
  try {
    const path = require('path');
    const fs = require('fs');

    const configDir = path.join(__dirname, '../../data');
    if (!fs.existsSync(configDir)) {
      fs.mkdirSync(configDir, { recursive: true });
    }

    const filePath = path.join(configDir, filename);
    if (fs.existsSync(filePath)) {
      return JSON.parse(fs.readFileSync(filePath, 'utf8'));
    }

    return null;
  } catch (error) {
    logger.errorWithStack(error, { filename });
    return null;
  }
}

/**
 * 分析成本趋势
 */
function analyzeCostTrend(costs) {
  const periods = Object.keys(costs).sort();
  if (periods.length < 2) {
    return null;
  }

  const values = periods.map(p => costs[p].amount || 0);
  const first = values[0];
  const last = values[values.length - 1];
  const change = ((last - first) / first) * 100;

  return {
    change,
    trend: change > 0 ? 'increasing' : change < 0 ? 'decreasing' : 'stable',
  };
}

/**
 * 获取前 N 名成本花费者
 */
function getTopSpenders(costs, topN = 5) {
  const sorted = Object.entries(costs)
    .sort((a, b) => (b[1].amount || 0) - (a[1].amount || 0))
    .slice(0, topN);

  return sorted.map(([model, data]) => ({
    model,
    amount: data.amount,
    count: data.count || 0,
  }));
}

/**
 * 分析成本趋势
 */
function analyzeCostTrends(costs) {
  const periods = Object.keys(costs).sort();
  if (periods.length < 2) {
    return null;
  }

  const values = periods.map(p => costs[p].amount || 0);
  const change = ((values[values.length - 1] - values[0]) / values[0]) * 100;

  return {
    change,
    trend: change > 0 ? 'increasing' : change < 0 ? 'decreasing' : 'stable',
  };
}

/**
 * 获取指标历史数据
 */
async function getMetricsHistory(days = 7) {
  const startTime = Date.now();

  try {
    const metricsFile = await getConfigFile('metrics-history.json');

    // 如果有历史数据，返回历史数据
    if (metricsFile && Object.keys(metricsFile).length > 0) {
      return {
        data: metricsFile,
        period: days,
      };
    }

    // 否则生成模拟数据
    const data = generateMockMetricsHistory(days);
    return {
      data,
      period: days,
    };
  } catch (error) {
    logger.errorWithStack(error, { operation: 'getMetricsHistory' });
    return { data: {}, period: days };
  }
}

/**
 * 生成模拟指标历史数据
 */
function generateMockMetricsHistory(days) {
  const data = {};
  const now = new Date();

  for (let i = 0; i < days; i++) {
    const date = new Date(now);
    date.setDate(date.getDate() - i);
    const dateStr = date.toISOString().split('T')[0];

    data[dateStr] = {
      timestamp: date.toISOString(),
      totalRequests: Math.floor(Math.random() * 5000) + 1000,
      errors: Math.floor(Math.random() * 50),
      successRate: (Math.random() * 5 + 94).toFixed(2),
      avgResponseTime: Math.floor(Math.random() * 200) + 100,
    };
  }

  return data;
}

module.exports = {
  getSystemMetrics,
  getResourceUsage,
  getProcessList,
  getNetworkConnections,
  getActiveConnections,
  getSystemLoad,
  getMonitoringData,
  getCostData,
  getTotalCost,
  getDailyCost,
  getHourlyCost,
  getCostByModel,
  getCostByPeriod,
  getMetricsHistory,
};
