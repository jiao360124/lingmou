const fs = require('fs');
const path = require('path');
const moment = require('moment-timezone');

const PROJECT_ROOT = path.join(__dirname, '..');
const LOG_FILE = path.join(PROJECT_ROOT, 'logs', 'metrics-reset.log');

// Ensure logs directory exists
const logsDir = path.dirname(LOG_FILE);
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir, { recursive: true });
}

console.log(`[${moment().tz('Asia/Shanghai').format('YYYY-MM-DD HH:mm:ss')}] 开始重置每日指标...`);

try {
  const now = moment().tz('Asia/Shanghai');

  // Load existing metrics
  const metricsDir = path.join(PROJECT_ROOT, 'metrics');
  if (!fs.existsSync(metricsDir)) {
    fs.mkdirSync(metricsDir, { recursive: true });
  }

  const dashboardDataPath = path.join(metricsDir, 'dashboard-data.json');
  const dashboardData = fs.existsSync(dashboardDataPath) 
    ? JSON.parse(fs.readFileSync(dashboardDataPath, 'utf8'))
    : { metrics: {} };

  // Reset daily metrics
  const today = now.format('YYYY-MM-DD');
  if (!dashboardData.metrics[today]) {
    dashboardData.metrics[today] = {};
  }

  // Reset all daily metrics to baseline
  const baselineMetrics = {
    timestamp: now.toISOString(),
    status: 'reset',
    resetAt: now.format('YYYY-MM-DD HH:mm:ss'),
    baseline: true
  };

  dashboardData.metrics[today] = {
    ...dashboardData.metrics[today],
    ...baselineMetrics,
    cpu: { current: 0, average: 0, peak: 0, unit: '%' },
    memory: { current: 0, average: 0, peak: 0, unit: 'MB' },
    disk: { current: 0, average: 0, peak: 0, unit: 'GB' },
    network: { current: 0, average: 0, peak: 0, unit: 'MB/s' },
    responseTime: { current: 0, average: 0, peak: 0, unit: 'ms' }
  };

  // Update last updated timestamp
  dashboardData.lastUpdated = now.toISOString();

  // Save metrics
  fs.writeFileSync(dashboardDataPath, JSON.stringify(dashboardData, null, 2), 'utf8');

  console.log(`✓ 每日指标重置成功: ${today}`);
  console.log(`  - CPU指标: 重置为0`);
  console.log(`  - 内存指标: 重置为0`);
  console.log(`  - 磁盘指标: 重置为0`);
  console.log(`  - 网络指标: 重置为0`);

} catch (error) {
  console.error(`✗ 每日指标重置失败:`, error.message);
  throw error;
}
