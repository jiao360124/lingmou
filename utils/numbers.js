/**
 * Number Utilities
 * 数值处理的工具函数
 */

/**
 * 限制值在指定范围内
 * @param {*} value - 要检查的值
 * @param {number} min - 最小值
 * @param {number} max - 最大值
 * @param {*} defaultValue - 默认值
 * @returns {number} 限制后的值
 */
function clamp(value, min, max, defaultValue = min) {
  if (value === null || value === undefined) {
    return defaultValue;
  }
  return Math.max(min, Math.min(max, value));
}

/**
 * 计算百分比
 * @param {number} value - 当前值
 * @param {number} total - 总值
 * @returns {number} 百分比
 */
function calculatePercentage(value, total) {
  if (total === 0) return 0;
  return Math.round((value / total) * 100 * 100) / 100;
}

/**
 * 格式化数字
 * @param {number} num - 数字
 * @param {number} decimals - 小数位数
 * @returns {string} 格式化后的字符串
 */
function formatNumber(num, decimals = 2) {
  return num.toFixed(decimals);
}

/**
 * 格式化文件大小
 * @param {number} bytes - 字节数
 * @returns {string} 格式化后的大小
 */
function formatFileSize(bytes) {
  if (bytes < 1024) return bytes + ' B';
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(2) + ' KB';
  if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(2) + ' MB';
  return (bytes / (1024 * 1024 * 1024)).toFixed(2) + ' GB';
}

/**
 * 比较两个数值
 * @param {number} a - 数值A
 * @param {number} b - 数值B
 * @param {number} tolerance - 容差
 * @returns {boolean} 是否相等
 */
function compareNumbers(a, b, tolerance = 0.0001) {
  return Math.abs(a - b) < tolerance;
}

/**
 * 四舍五入
 * @param {number} num - 数字
 * @param {number} decimals - 小数位数
 * @returns {number} 四舍五入后的值
 */
function round(num, decimals = 0) {
  const multiplier = Math.pow(10, decimals);
  return Math.round(num * multiplier) / multiplier;
}

/**
 * 取整
 * @param {number} num - 数字
 * @returns {number} 整数值
 */
function toInt(num) {
  return Math.floor(num);
}

/**
 * 取最大值
 * @param {...number} numbers - 数值列表
 * @returns {number} 最大值
 */
function max(...numbers) {
  return Math.max(...numbers);
}

/**
 * 取最小值
 * @param {...number} numbers - 数值列表
 * @returns {number} 最小值
 */
function min(...numbers) {
  return Math.min(...numbers);
}

/**
 * 数值范围
 * @param {number} min - 最小值
 * @param {number} max - 最大值
 * @returns {number} 范围内的随机数
 */
function randomRange(min, max) {
  return Math.random() * (max - min) + min;
}

module.exports = {
  clamp,
  calculatePercentage,
  formatNumber,
  formatFileSize,
  compareNumbers,
  round,
  toInt,
  max,
  min,
  randomRange
};
