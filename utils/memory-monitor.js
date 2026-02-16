/**
 * OpenClaw Memory Monitor - 内存监控模块
 * 提供内存使用追踪、泄漏检测、缓存清理功能
 */

class MemoryMonitor {
  constructor(options = {}) {
    this.options = {
      warnThreshold: options.warnThreshold || 80, // 警告阈值（%）
      criticalThreshold: options.criticalThreshold || 90, // 严重阈值（%）
      monitorInterval: options.monitorInterval || 60000, // 监控间隔（毫秒）
      ...options
    };

    this.memoryUsage = new Map();
    this.leaks = new Map();
    this.history = [];
    this.maxHistory = options.maxHistory || 1000;
    this.running = false;
    this.monitorTimer = null;
  }

  /**
   * 获取当前内存使用情况
   * @returns {Object} 内存使用对象
   */
  getCurrentMemoryUsage() {
    const usage = process.memoryUsage();
    return {
      rss: usage.rss, // 常驻内存（字节）
      heapTotal: usage.heapTotal, // 堆内存总量（字节）
      heapUsed: usage.heapUsed, // 堆内存使用（字节）
      external: usage.external, // 外部内存（字节）
      arrayBuffers: usage.arrayBuffers, // 数组缓冲区（字节）
      heapUsedPercentage: this.calculatePercentage(usage.heapUsed, usage.heapTotal)
    };
  }

  /**
   * 计算百分比
   * @private
   */
  calculatePercentage(value, total) {
    if (total === 0) return 0;
    return Math.round((value / total) * 100 * 100) / 100;
  }

  /**
   * 记录内存使用
   * @param {string} name - 监控名称
   * @param {Object} metadata - 元数据
   */
  recordMemoryUsage(name, metadata = {}) {
    const usage = this.getCurrentMemoryUsage();
    const record = {
      timestamp: Date.now(),
      name,
      ...usage,
      ...metadata
    };

    this.memoryUsage.set(name, usage);
    this.history.push(record);

    // 限制历史记录数量
    if (this.history.length > this.maxHistory) {
      this.history.shift();
    }

    // 检查内存使用阈值
    this.checkThreshold(usage);

    return record;
  }

  /**
   * 检查内存使用阈值
   * @private
   */
  checkThreshold(usage) {
    const { warnThreshold, criticalThreshold } = this.options;

    if (usage.heapUsedPercentage >= criticalThreshold) {
      this.alert('critical', `内存使用过高: ${usage.heapUsedPercentage.toFixed(2)}%`);
      this.leaks.set('critical', {
        timestamp: Date.now(),
        usage: usage.heapUsedPercentage
      });
    } else if (usage.heapUsedPercentage >= warnThreshold) {
      this.alert('warning', `内存使用偏高: ${usage.heapUsedPercentage.toFixed(2)}%`);
      this.leaks.set('warning', {
        timestamp: Date.now(),
        usage: usage.heapUsedPercentage
      });
    } else {
      this.leaks.delete(usage.heapUsedPercentage >= warnThreshold ? 'warning' : 'critical');
    }
  }

  /**
   * 获取内存使用历史
   * @param {number} limit - 限制数量
   * @returns {Array} 内存使用历史
   */
  getMemoryHistory(limit = 100) {
    return this.history.slice(-limit);
  }

  /**
   * 获取内存泄漏检测
   * @returns {Object} 泄漏检测报告
   */
  getLeakDetection() {
    // 简化的泄漏检测逻辑
    const recentHistory = this.getMemoryHistory(100);
    if (recentHistory.length < 50) {
      return {
        hasLeak: false,
        severity: 'none',
        message: '历史数据不足，无法进行泄漏检测'
      };
    }

    // 计算内存增长趋势
    const start = recentHistory[0];
    const end = recentHistory[recentHistory.length - 1];
    const growth = end.heapUsed - start.heapUsed;
    const growthPercentage = ((growth / start.heapUsed) * 100);

    let severity = 'none';
    let message = '内存使用稳定';

    if (growthPercentage > 20) {
      severity = 'warning';
      message = `检测到内存泄漏嫌疑: ${growthPercentage.toFixed(2)}% 增长`;
    } else if (growthPercentage > 10) {
      severity = 'warning';
      message = `内存使用可能增长: ${growthPercentage.toFixed(2)}% 增长`;
    } else if (growthPercentage > 5) {
      severity = 'info';
      message = `内存使用略有增长: ${growthPercentage.toFixed(2)}% 增长`;
    }

    return {
      hasLeak: severity !== 'none',
      severity,
      message,
      growthPercentage,
      startMemory: start.heapUsed,
      endMemory: end.heapUsed
    };
  }

  /**
   * 清理缓存
   * @param {string} name - 缓存名称
   */
  clearCache(name) {
    if (name) {
      this.memoryUsage.delete(name);
    } else {
      this.memoryUsage.clear();
    }

    // 清理历史记录
    this.history = [];
  }

  /**
   * 强制垃圾回收（仅在非生产环境）
   */
  forceGC() {
    if (process.env.NODE_ENV !== 'production') {
      if (global.gc) {
        global.gc();
        return true;
      } else {
        console.warn('Global GC not available');
        return false;
      }
    } else {
      console.warn('GC can only be called in non-production environment');
      return false;
    }
  }

  /**
   * 启动监控
   */
  start() {
    if (this.running) {
      return;
    }

    this.running = true;
    this.recordMemoryUsage('initial');

    this.monitorTimer = setInterval(() => {
      this.recordMemoryUsage('periodic');
    }, this.options.monitorInterval);

    this.alert('info', '内存监控已启动');
  }

  /**
   * 停止监控
   */
  stop() {
    if (!this.running) {
      return;
    }

    this.running = false;

    if (this.monitorTimer) {
      clearInterval(this.monitorTimer);
      this.monitorTimer = null;
    }

    this.alert('info', '内存监控已停止');
  }

  /**
   * 获取当前状态
   * @returns {Object} 状态对象
   */
  getStatus() {
    const usage = this.getCurrentMemoryUsage();
    const leakDetection = this.getLeakDetection();

    return {
      running: this.running,
      currentMemory: usage,
      historyCount: this.history.length,
      leakDetection,
      options: {
        warnThreshold: this.options.warnThreshold,
        criticalThreshold: this.options.criticalThreshold,
        monitorInterval: this.options.monitorInterval
      }
    };
  }

  /**
   * 告警
   * @private
   */
  alert(level, message) {
    console.log(`[MemoryMonitor] [${level.toUpperCase()}] ${message}`);
    // 可以扩展为发送到监控系统
  }

  /**
   * 获取内存使用统计
   * @returns {Object} 统计信息
   */
  getStatistics() {
    const recentHistory = this.getMemoryHistory(100);
    if (recentHistory.length === 0) {
      return {
        avgHeapUsed: 0,
        maxHeapUsed: 0,
        minHeapUsed: 0,
        currentHeapUsed: 0
      };
    }

    const heaps = recentHistory.map(h => h.heapUsed);
    const avgHeapUsed = heaps.reduce((a, b) => a + b, 0) / heaps.length;
    const maxHeapUsed = Math.max(...heaps);
    const minHeapUsed = Math.min(...heaps);
    const currentHeapUsed = heaps[heaps.length - 1];

    return {
      avgHeapUsed: Math.round(avgHeapUsed),
      maxHeapUsed: Math.round(maxHeapUsed),
      minHeapUsed: Math.round(minHeapUsed),
      currentHeapUsed: Math.round(currentHeapUsed)
    };
  }
}

module.exports = MemoryMonitor;
