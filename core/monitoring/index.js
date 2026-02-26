/**
 * 监控模块统一导出
 */

const performanceMonitor = require('./performance-monitor');
const memoryMonitor = require('./memory-monitor');
const apiTracker = require('./api-tracker');

module.exports = {
  performanceMonitor,
  memoryMonitor,
  apiTracker,

  /**
   * 统一初始化监控
   */
  init(config = {}) {
    performanceMonitor.init(config.performance || {});
    memoryMonitor.init(config.memory || {});
    apiTracker.init(config.api || {});
  },

  /**
   * 统一停止监控
   */
  stop() {
    performanceMonitor.stop();
    memoryMonitor.stop();
    apiTracker.stop();
  }
};
