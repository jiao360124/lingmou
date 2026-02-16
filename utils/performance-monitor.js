/**
 * OpenClaw Performance Monitor - 性能监控模块
 * 提供API响应时间追踪、CPU使用监控、性能指标统计功能
 */

class PerformanceMonitor {
  constructor(options = {}) {
    this.options = {
      apiLatencyWarningThreshold: options.apiLatencyWarningThreshold || 500, // API延迟警告阈值
      apiLatencyCriticalThreshold: options.apiLatencyCriticalThreshold || 1000, // API延迟严重阈值
      cpuWarningThreshold: options.cpuWarningThreshold || 80, // CPU警告阈值
      cpuCriticalThreshold: options.cpuCriticalThreshold || 90, // CPU严重阈值
      monitorInterval: options.monitorInterval || 10000, // 监控间隔（毫秒）
      ...options
    };

    this.apiMetrics = new Map();
    this.cpuHistory = [];
    this.maxCpuHistory = options.maxCpuHistory || 100;
    this.memoryHistory = [];
    this.maxMemoryHistory = options.maxMemoryHistory || 100;
    this.performanceAlerts = [];
    this.running = false;
    this.monitorTimer = null;
    this.startTime = Date.now();
  }

  /**
   * 记录API调用性能
   * @param {string} apiName - API名称
   * @param {number} duration - 响应时间（毫秒）
   * @param {Object} metadata - 元数据
   * @returns {Object} 性能记录
   */
  recordApiPerformance(apiName, duration, metadata = {}) {
    const record = {
      timestamp: Date.now(),
      apiName,
      duration,
      memoryUsage: process.memoryUsage().heapUsed,
      ...metadata
    };

    if (!this.apiMetrics.has(apiName)) {
      this.apiMetrics.set(apiName, []);
    }

    const history = this.apiMetrics.get(apiName);
    history.push(record);

    // 保留最近100条记录
    if (history.length > 100) {
      history.shift();
    }

    // 检查性能阈值
    this.checkApiThreshold(duration);

    // 更新内存历史
    this.updateMemoryHistory();

    return record;
  }

  /**
   * 检查API性能阈值
   * @private
   */
  checkApiThreshold(duration) {
    const { apiLatencyWarningThreshold, apiLatencyCriticalThreshold } = this.options;

    if (duration >= apiLatencyCriticalThreshold) {
      this.alert('critical', `API响应过慢: ${duration}ms (阈值: ${apiLatencyCriticalThreshold}ms)`);
      this.performanceAlerts.push({
        type: 'api-latency',
        level: 'critical',
        message: `API响应过慢: ${duration}ms`,
        duration,
        threshold: apiLatencyCriticalThreshold,
        timestamp: Date.now()
      });
    } else if (duration >= apiLatencyWarningThreshold) {
      this.alert('warning', `API响应较慢: ${duration}ms (阈值: ${apiLatencyWarningThreshold}ms)`);
      this.performanceAlerts.push({
        type: 'api-latency',
        level: 'warning',
        message: `API响应较慢: ${duration}ms`,
        duration,
        threshold: apiLatencyWarningThreshold,
        timestamp: Date.now()
      });
    }
  }

  /**
   * 获取API性能统计
   * @param {string} apiName - API名称（可选）
   * @returns {Object|Array} 性能统计
   */
  getApiPerformanceStats(apiName = null) {
    if (apiName && !this.apiMetrics.has(apiName)) {
      return { error: 'API not found', apiName };
    }

    if (apiName) {
      const history = this.apiMetrics.get(apiName);
      return this.calculateStats(history);
    }

    // 返回所有API的统计
    const stats = {};
    this.apiMetrics.forEach((history, name) => {
      stats[name] = this.calculateStats(history);
    });

    return stats;
  }

  /**
   * 计算统计数据
   * @private
   */
  calculateStats(history) {
    if (history.length === 0) {
      return { count: 0, avgDuration: 0, minDuration: 0, maxDuration: 0, p50: 0, p90: 0, p95: 0, p99: 0 };
    }

    const durations = history.map(h => h.duration).sort((a, b) => a - b);
    const count = durations.length;
    const avgDuration = durations.reduce((a, b) => a + b, 0) / count;
    const minDuration = durations[0];
    const maxDuration = durations[count - 1];

    // 计算百分位数
    const p50 = this.getPercentile(durations, 50);
    const p90 = this.getPercentile(durations, 90);
    const p95 = this.getPercentile(durations, 95);
    const p99 = this.getPercentile(durations, 99);

    return {
      count,
      avgDuration: Math.round(avgDuration),
      minDuration,
      maxDuration,
      p50,
      p90,
      p95,
      p99
    };
  }

  /**
   * 获取百分位数
   * @private
   */
  getPercentile(sortedArray, percentile) {
    const index = Math.ceil((percentile / 100) * sortedArray.length) - 1;
    return sortedArray[index];
  }

  /**
   * 更新CPU和历史记录
   * @private
   */
  updateCpuHistory() {
    const cpuUsage = process.cpuUsage();
    const currentUsage = ((cpuUsage.user + cpuUsage.system) / 1000000).toFixed(2);
    const history = parseFloat(currentUsage);

    this.cpuHistory.push(history);

    if (this.cpuHistory.length > this.maxCpuHistory) {
      this.cpuHistory.shift();
    }

    this.checkCpuThreshold(history);
  }

  /**
   * 更新内存历史
   * @private
   */
  updateMemoryHistory() {
    const memoryUsage = process.memoryUsage().heapUsed;
    this.memoryHistory.push(memoryUsage);

    if (this.memoryHistory.length > this.maxMemoryHistory) {
      this.memoryHistory.shift();
    }
  }

  /**
   * 检查CPU阈值
   * @private
   */
  checkCpuThreshold(cpuUsage) {
    const { cpuWarningThreshold, cpuCriticalThreshold } = this.options;

    if (cpuUsage >= cpuCriticalThreshold) {
      this.alert('critical', `CPU使用过高: ${cpuUsage}% (阈值: ${cpuCriticalThreshold}%)`);
      this.performanceAlerts.push({
        type: 'cpu',
        level: 'critical',
        message: `CPU使用过高: ${cpuUsage}%`,
        cpuUsage,
        threshold: cpuCriticalThreshold,
        timestamp: Date.now()
      });
    } else if (cpuUsage >= cpuWarningThreshold) {
      this.alert('warning', `CPU使用偏高: ${cpuUsage}% (阈值: ${cpuWarningThreshold}%)`);
      this.performanceAlerts.push({
        type: 'cpu',
        level: 'warning',
        message: `CPU使用偏高: ${cpuUsage}%`,
        cpuUsage,
        threshold: cpuWarningThreshold,
        timestamp: Date.now()
      });
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

    this.monitorTimer = setInterval(() => {
      this.updateCpuHistory();
      this.updateMemoryHistory();
    }, this.options.monitorInterval);

    this.alert('info', '性能监控已启动');
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

    this.alert('info', '性能监控已停止');
  }

  /**
   * 获取性能统计
   * @returns {Object} 性能统计
   */
  getStatistics() {
    const { apiLatencyWarningThreshold, apiLatencyCriticalThreshold, cpuWarningThreshold, cpuCriticalThreshold } = this.options;
    const apiStats = this.getApiPerformanceStats();
    const cpuStats = this.getCpuStats();
    const memoryStats = this.getMemoryStats();
    const alerts = this.getAlerts();

    return {
      uptime: Date.now() - this.startTime,
      apis: apiStats,
      cpu: cpuStats,
      memory: memoryStats,
      alerts,
      thresholds: {
        apiLatencyWarning: apiLatencyWarningThreshold,
        apiLatencyCritical: apiLatencyCriticalThreshold,
        cpuWarning: cpuWarningThreshold,
        cpuCritical: cpuCriticalThreshold
      }
    };
  }

  /**
   * 获取CPU统计
   * @returns {Object} CPU统计
   */
  getCpuStats() {
    if (this.cpuHistory.length === 0) {
      return { avg: 0, max: 0, min: 0, current: 0 };
    }

    const current = this.cpuHistory[this.cpuHistory.length - 1];
    const avg = this.cpuHistory.reduce((a, b) => a + b, 0) / this.cpuHistory.length;
    const max = Math.max(...this.cpuHistory);
    const min = Math.min(...this.cpuHistory);

    return {
      avg: avg.toFixed(2),
      max,
      min,
      current
    };
  }

  /**
   * 获取内存统计
   * @returns {Object} 内存统计
   */
  getMemoryStats() {
    if (this.memoryHistory.length === 0) {
      return { avg: 0, max: 0, min: 0, current: 0 };
    }

    const current = this.memoryHistory[this.memoryHistory.length - 1];
    const avg = this.memoryHistory.reduce((a, b) => a + b, 0) / this.memoryHistory.length;
    const max = Math.max(...this.memoryHistory);
    const min = Math.min(...this.memoryHistory);

    return {
      avg: Math.round(avg),
      max: Math.round(max),
      min: Math.round(min),
      current: Math.round(current)
    };
  }

  /**
   * 获取告警列表
   * @returns {Array} 告警列表
   */
  getAlerts() {
    // 只保留最近的20条告警
    return this.performanceAlerts.slice(-20);
  }

  /**
   * 清除告警
   */
  clearAlerts() {
    this.performanceAlerts = [];
  }

  /**
   * 获取当前状态
   * @returns {Object} 状态对象
   */
  getStatus() {
    return {
      running: this.running,
      apiMetricsCount: this.apiMetrics.size,
      cpuHistoryCount: this.cpuHistory.length,
      memoryHistoryCount: this.memoryHistory.length,
      currentCpu: this.getCpuStats().current,
      currentMemory: this.getMemoryStats().current,
      activeAlerts: this.getAlerts().filter(a => a.level === 'critical' || a.level === 'warning').length
    };
  }

  /**
   * 告警
   * @private
   */
  alert(level, message) {
    console.log(`[PerformanceMonitor] [${level.toUpperCase()}] ${message}`);
  }

  /**
   * 获取所有性能指标
   * @returns {Object} 性能指标
   */
  getAllMetrics() {
    const apis = [];
    this.apiMetrics.forEach((history, name) => {
      const stats = this.calculateStats(history);
      apis.push({
        name,
        ...stats,
        count: history.length
      });
    });

    return {
      apis,
      cpu: this.getCpuStats(),
      memory: this.getMemoryStats(),
      alerts: this.getAlerts(),
      uptime: Date.now() - this.startTime
    };
  }

  /**
   * 重置监控
   */
  reset() {
    this.apiMetrics.clear();
    this.cpuHistory = [];
    this.memoryHistory = [];
    this.performanceAlerts = [];
    this.startTime = Date.now();
  }
}

module.exports = PerformanceMonitor;
