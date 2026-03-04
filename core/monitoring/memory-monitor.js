// core/memory-monitor.js
// 内存监控模块 - V3.0+V3.2 集成版

const winston = require('winston');
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/memory-monitor.log' }),
    new winston.transports.Console({ format: winston.format.simple() })
  ]
});

class MemoryMonitor {
  constructor(config = {}) {
    this.config = {
      checkInterval: config.checkInterval || 60000, // 60秒
      warningThreshold: config.warningThreshold || 0.75, // 75%
      criticalThreshold: config.criticalThreshold || 0.85, // 85%
      maxMemoryHistory: config.maxMemoryHistory || 100
    };

    this.memoryHistory = [];
    this.gcStats = {
      totalGC: 0,
      lastGCTime: null
    };

    this.startMonitoring();
  }

  /**
   * 开始监控
   */
  startMonitoring() {
    logger.info('💾 内存监控模块启动');
    logger.info(`📊 检查间隔: ${this.config.checkInterval}ms`);

    // 定期检查
    setInterval(() => {
      this.check();
    }, this.config.checkInterval);
  }

  /**
   * 获取当前内存使用情况
   */
  getCurrentMemory() {
    const usage = process.memoryUsage();

    return {
      heapUsed: usage.heapUsed / 1024 / 1024, // MB
      heapTotal: usage.heapTotal / 1024 / 1024, // MB
      rss: usage.rss / 1024 / 1024, // MB
      external: usage.external / 1024 / 1024, // MB
      arrayBuffers: usage.arrayBuffers / 1024 / 1024, // MB
      heapUsagePercentage: (usage.heapUsed / usage.heapTotal) * 100,
      uptime: Date.now()
    };
  }

  /**
   * 检查内存使用情况
   */
  check() {
    const memory = this.getCurrentMemory();

    logger.info('📊 内存检查', {
      heapUsed: memory.heapUsed.toFixed(2) + ' MB',
      heapTotal: memory.heapTotal.toFixed(2) + ' MB',
      heapUsage: memory.heapUsagePercentage.toFixed(2) + '%',
      rss: memory.rss.toFixed(2) + ' MB'
    });

    // 记录历史
    this.memoryHistory.push({
      timestamp: Date.now(),
      ...memory
    });

    // 限制历史记录数量
    if (this.memoryHistory.length > this.config.maxMemoryHistory) {
      this.memoryHistory.shift();
    }

    // 检查警告阈值
    if (memory.heapUsagePercentage > this.config.warningThreshold) {
      logger.warn('⚠️  警告：内存使用率过高', {
        current: memory.heapUsagePercentage.toFixed(2) + '%',
        threshold: this.config.warningThreshold.toFixed(2) + '%'
      });
    }

    // 检查严重阈值
    if (memory.heapUsagePercentage > this.config.criticalThreshold) {
      logger.error('🚨 严重：内存使用率过高', {
        current: memory.heapUsagePercentage.toFixed(2) + '%',
        threshold: this.config.criticalThreshold.toFixed(2) + '%'
      });
    }
  }

  /**
   * 检测内存泄漏
   */
  detectLeak() {
    if (this.memoryHistory.length < 2) {
      return {
        hasLeak: false,
        reason: '数据不足'
      };
    }

    const recent = this.memoryHistory.slice(-20);
    const oldest = this.memoryHistory.slice(-40, -20);

    const recentAvg = recent.reduce((sum, m) => sum + m.heapUsed, 0) / recent.length;
    const oldestAvg = oldest.reduce((sum, m) => sum + m.heapUsed, 0) / oldest.length;

    const increase = recentAvg - oldestAvg;
    const percentageIncrease = (increase / oldestAvg) * 100;

    logger.info('🔍 内存泄漏检测', {
      recentAvg: recentAvg.toFixed(2) + ' MB',
      oldestAvg: oldestAvg.toFixed(2) + ' MB',
      increase: increase.toFixed(2) + ' MB',
      percentageIncrease: percentageIncrease.toFixed(2) + '%'
    });

    // 如果内存使用率超过5%，可能存在泄漏
    const hasLeak = percentageIncrease > 5;

    return {
      hasLeak,
      reason: hasLeak ? '内存持续增长' : '内存使用稳定',
      recentAvg,
      oldestAvg,
      increase,
      percentageIncrease
    };
  }

  /**
   * 获取内存使用趋势
   */
  getMemoryTrend() {
    if (this.memoryHistory.length < 2) {
      return null;
    }

    const history = this.memoryHistory.slice(-30);
    const first = history[0];
    const last = history[history.length - 1];

    const startUsed = first.heapUsed;
    const endUsed = last.heapUsed;
    const increase = endUsed - startUsed;
    const percentageChange = (increase / startUsed) * 100;

    const direction = increase > 0 ? 'increasing' : increase < 0 ? 'decreasing' : 'stable';

    return {
      startUsed: startUsed.toFixed(2) + ' MB',
      endUsed: endUsed.toFixed(2) + ' MB',
      increase: increase.toFixed(2) + ' MB',
      percentageChange: percentageChange.toFixed(2) + '%',
      direction
    };
  }

  /**
   * 清理缓存
   */
  clearCache() {
    logger.info('🧹 开始清理缓存...');

    // 这里可以实现自定义的缓存清理逻辑
    // 例如：清除 Node.js 缓存
    if (global.gc) {
      global.gc();
      this.gcStats.totalGC++;
      this.gcStats.lastGCTime = Date.now();

      logger.info('✅ 缓存已清理（使用 global.gc）');
    } else {
      logger.warn('⚠️  global.gc 不可用，请手动启用');
    }
  }

  /**
   * 强制触发垃圾回收（需要手动启用）
   */
  forceGC() {
    logger.warn('⚠️  警告：强制GC可能影响性能');

    if (global.gc) {
      global.gc();
      this.gcStats.totalGC++;
      this.gcStats.lastGCTime = Date.now();

      logger.info('✅ 强制GC已执行', {
        totalGC: this.gcStats.totalGC,
        lastGCTime: new Date(this.gcStats.lastGCTime).toISOString()
      });

      return {
        success: true,
        totalGC: this.gcStats.totalGC
      };
    } else {
      logger.error('❌ global.gc 不可用');
      return {
        success: false,
        reason: 'global.gc not available'
      };
    }
  }

  /**
   * 获取GC统计
   */
  getGCStats() {
    return {
      totalGC: this.gcStats.totalGC,
      lastGCTime: this.gcStats.lastGCTime ? new Date(this.gcStats.lastGCTime).toISOString() : null,
      avgGCInterval: this.gcStats.lastGCTime && this.gcStats.totalGC > 1
        ? ((this.gcStats.lastGCTime - this.memoryHistory[0].timestamp) / (this.gcStats.totalGC - 1))
        : null
    };
  }

  /**
   * 获取状态
   */
  getStatus() {
    const memory = this.getCurrentMemory();
    const leakDetection = this.detectLeak();
    const memoryTrend = this.getMemoryTrend();

    let status = 'OK';
    if (memory.heapUsagePercentage > this.config.criticalThreshold) {
      status = 'CRITICAL';
    } else if (memory.heapUsagePercentage > this.config.warningThreshold) {
      status = 'WARNING';
    }

    return {
      status,
      ...memory,
      leakDetection,
      memoryTrend,
      gcStats: this.getGCStats()
    };
  }
}

module.exports = MemoryMonitor;
