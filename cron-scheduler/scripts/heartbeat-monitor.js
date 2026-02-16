const fs = require('fs');
const path = require('path');
const moment = require('moment-timezone');

const PROJECT_ROOT = path.join(__dirname, '..');
const LOG_FILE = path.join(PROJECT_ROOT, 'logs', 'heartbeat-monitor.log');

// Ensure logs directory exists
const logsDir = path.dirname(LOG_FILE);
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir, { recursive: true });
}

console.log(`[${moment().tz('Asia/Shanghai').format('YYYY-MM-DD HH:mm:ss')}] 开始心跳监控...`);

try {
  const now = moment().tz('Asia/Shanghai');

  // Health check results
  const healthCheck = {
    timestamp: now.toISOString(),
    date: now.format('YYYY-MM-DD'),
    checks: {}
  };

  // Check 1: File system health
  try {
    // Check if project root exists and is accessible
    if (fs.existsSync(PROJECT_ROOT)) {
      healthCheck.checks.fileSystem = {
        status: 'ok',
        message: '文件系统正常',
        lastCheck: now.format('HH:mm:ss')
      };
    } else {
      throw new Error('项目根目录不存在');
    }
  } catch (error) {
    healthCheck.checks.fileSystem = {
      status: 'error',
      message: error.message,
      lastCheck: now.format('HH:mm:ss')
    };
  }

  // Check 2: Logs directory health
  try {
    const logsDir = path.join(PROJECT_ROOT, 'logs');
    if (fs.existsSync(logsDir)) {
      const logFiles = fs.readdirSync(logsDir).length;
      healthCheck.checks.logs = {
        status: 'ok',
        message: `日志目录正常，包含 ${logFiles} 个文件`,
        lastCheck: now.format('HH:mm:ss')
      };
    } else {
      fs.mkdirSync(logsDir, { recursive: true });
      healthCheck.checks.logs = {
        status: 'warning',
        message: '日志目录已创建',
        lastCheck: now.format('HH:mm:ss')
      };
    }
  } catch (error) {
    healthCheck.checks.logs = {
      status: 'error',
      message: error.message,
      lastCheck: now.format('HH:mm:ss')
    };
  }

  // Check 3: Data directory health
  try {
    const dataDir = path.join(PROJECT_ROOT, 'data');
    if (fs.existsSync(dataDir)) {
      const dataFiles = fs.readdirSync(dataDir).length;
      healthCheck.checks.data = {
        status: 'ok',
        message: `数据目录正常，包含 ${dataFiles} 个文件`,
        lastCheck: now.format('HH:mm:ss')
      };
    } else {
      fs.mkdirSync(dataDir, { recursive: true });
      healthCheck.checks.data = {
        status: 'warning',
        message: '数据目录已创建',
        lastCheck: now.format('HH:mm:ss')
      };
    }
  } catch (error) {
    healthCheck.checks.data = {
      status: 'error',
      message: error.message,
      lastCheck: now.format('HH:mm:ss')
    };
  }

  // Check 4: Configuration files
  try {
    const configFiles = [
      path.join(PROJECT_ROOT, 'config', 'cron-config.json'),
      path.join(PROJECT_ROOT, 'config', 'scheduler-tasks.json')
    ];

    configFiles.forEach(configFile => {
      if (fs.existsSync(configFile)) {
        const stats = fs.statSync(configFile);
        healthCheck.checks.config = healthCheck.checks.config || {
          status: 'ok',
          message: '配置文件正常',
          lastCheck: now.format('HH:mm:ss')
        };
      } else {
        throw new Error(`配置文件不存在: ${configFile}`);
      }
    });
  } catch (error) {
    healthCheck.checks.config = {
      status: 'warning',
      message: '配置文件检查警告',
      lastCheck: now.format('HH:mm:ss')
    };
  }

  // Check 5: Disk space
  try {
    const stats = fs.statSync(PROJECT_ROOT);
    const totalSpace = stats.blocks * 512 / (1024 * 1024); // Convert to MB
    const freeSpace = stats.bavail * 512 / (1024 * 1024); // Convert to MB

    if (freeSpace < 100) {
      healthCheck.checks.disk = {
        status: 'warning',
        message: `磁盘空间不足: ${freeSpace.toFixed(2)} MB`,
        lastCheck: now.format('HH:mm:ss')
      };
    } else {
      healthCheck.checks.disk = {
        status: 'ok',
        message: `磁盘空间充足: ${freeSpace.toFixed(2)} MB 可用`,
        lastCheck: now.format('HH:mm:ss')
      };
    }
  } catch (error) {
    healthCheck.checks.disk = {
      status: 'error',
      message: error.message,
      lastCheck: now.format('HH:mm:ss')
    };
  }

  // Overall health status
  const failedChecks = Object.values(healthCheck.checks).filter(c => c.status === 'error').length;
  const warningChecks = Object.values(healthCheck.checks).filter(c => c.status === 'warning').length;

  if (failedChecks === 0 && warningChecks === 0) {
    healthCheck.overallStatus = 'healthy';
    healthCheck.message = '系统运行正常';
  } else if (failedChecks === 0) {
    healthCheck.overallStatus = 'warning';
    healthCheck.message = `系统运行基本正常，但有 ${warningChecks} 个警告`;
  } else {
    healthCheck.overallStatus = 'critical';
    healthCheck.message = `系统存在问题，${failedChecks} 个检查失败，${warningChecks} 个警告`;
  }

  // Save health check result
  const healthCheckPath = path.join(PROJECT_ROOT, 'data', 'health-check.json');
  if (!fs.existsSync(path.dirname(healthCheckPath))) {
    fs.mkdirSync(path.dirname(healthCheckPath), { recursive: true });
  }

  fs.writeFileSync(healthCheckPath, JSON.stringify(healthCheck, null, 2), 'utf8');

  // Log health check
  console.log(`✓ 心跳监控完成`);
  console.log(`  - 系统状态: ${healthCheck.overallStatus}`);
  console.log(`  - 消息: ${healthCheck.message}`);

  Object.entries(healthCheck.checks).forEach(([key, check]) => {
    const statusIcon = check.status === 'ok' ? '✓' : (check.status === 'warning' ? '⚠' : '✗');
    console.log(`  - ${key}: ${statusIcon} ${check.status} - ${check.message}`);
  });

} catch (error) {
  console.error(`✗ 心跳监控失败:`, error.message);
  throw error;
}
