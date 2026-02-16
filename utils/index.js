/**
 * OpenClaw Utils - 通用工具函数库
 * 提供跨模块使用的通用工具函数
 */

/**
 * 生成唯一ID
 * @param {string} prefix - ID前缀
 * @returns {string} 唯一ID
 */
function generateId(prefix) {
  return `${prefix}_${Date.now()}_${Math.floor(Math.random() * 10000)}`;
}

/**
 * 确保值在指定范围内
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
 * 安全执行函数，捕获错误
 * @param {Function} fn - 要执行的函数
 * @param {*} defaultValue - 错误时的默认值
 * @returns {*} 函数执行结果或默认值
 */
function safeExecute(fn, defaultValue = null) {
  try {
    return fn();
  } catch (error) {
    return defaultValue;
  }
}

/**
 * 延迟执行
 * @param {number} ms - 延迟毫秒数
 * @returns {Promise<void>}
 */
function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * 防抖函数
 * @param {Function} fn - 防抖的函数
 * @param {number} wait - 等待时间（毫秒）
 * @returns {Function} 防抖后的函数
 */
function debounce(fn, wait = 300) {
  let timeout;
  return function (...args) {
    clearTimeout(timeout);
    timeout = setTimeout(() => fn.apply(this, args), wait);
  };
}

/**
 * 节流函数
 * @param {Function} fn - 节流函数
 * @param {number} interval - 间隔时间（毫秒）
 * @returns {Function} 节流后的函数
 */
function throttle(fn, interval = 300) {
  let lastTime = 0;
  return function (...args) {
    const now = Date.now();
    if (now - lastTime >= interval) {
      lastTime = now;
      return fn.apply(this, args);
    }
  };
}

/**
 * 深拷贝对象
 * @param {*} obj - 要拷贝的对象
 * @returns {*} 拷贝后的对象
 */
function deepClone(obj) {
  if (obj === null || typeof obj !== 'object') {
    return obj;
  }

  if (obj instanceof Date) {
    return new Date(obj);
  }

  if (obj instanceof Array) {
    return obj.map(item => deepClone(item));
  }

  if (obj instanceof Object) {
    const cloned = {};
    for (const key in obj) {
      if (obj.hasOwnProperty(key)) {
        cloned[key] = deepClone(obj[key]);
      }
    }
    return cloned;
  }
}

/**
 * 合并对象（深拷贝）
 * @param {...Object} objects - 要合并的对象
 * @returns {Object} 合并后的对象
 */
function mergeDeep(...objects) {
  return objects.reduce((acc, obj) => {
    if (!obj) return acc;
    Object.keys(obj).forEach(key => {
      if (obj[key] !== null && typeof obj[key] === 'object' &&
          acc[key] !== null && typeof acc[key] === 'object') {
        acc[key] = mergeDeep(acc[key], obj[key]);
      } else {
        acc[key] = obj[key];
      }
    });
    return acc;
  }, {});
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
 * 截断字符串
 * @param {string} str - 字符串
 * @param {number} maxLength - 最大长度
 * @param {string} suffix - 后缀
 * @returns {string} 截断后的字符串
 */
function truncate(str, maxLength, suffix = '...') {
  if (str.length <= maxLength) return str;
  return str.substring(0, maxLength - suffix.length) + suffix;
}

/**
 * 验证邮箱格式
 * @param {string} email - 邮箱地址
 * @returns {boolean} 是否有效
 */
function isValidEmail(email) {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

/**
 * 验证URL格式
 * @param {string} url - URL地址
 * @returns {boolean} 是否有效
 */
function isValidUrl(url) {
  try {
    new URL(url);
    return true;
  } catch {
    return false;
  }
}

/**
 * 判断是否为空值
 * @param {*} value - 要检查的值
 * @returns {boolean} 是否为空
 */
function isEmpty(value) {
  return value === null || value === undefined || value === '' ||
         (Array.isArray(value) && value.length === 0) ||
         (typeof value === 'object' && Object.keys(value).length === 0);
}

/**
 * 判断是否为有效值
 * @param {*} value - 要检查的值
 * @returns {boolean} 是否有效
 */
function isValid(value) {
  return !isEmpty(value);
}

/**
 * 统计对象属性数量
 * @param {Object} obj - 对象
 * @returns {number} 属性数量
 */
function getObjectKeysCount(obj) {
  return obj ? Object.keys(obj).length : 0;
}

/**
 * 统计对象属性值数量
 * @param {Object} obj - 对象
 * @returns {number} 值数量
 */
function getObjectValuesCount(obj) {
  return obj ? Object.values(obj).length : 0;
}

/**
 * 对象转查询字符串
 * @param {Object} obj - 对象
 * @returns {string} 查询字符串
 */
function objectToQueryString(obj) {
  return Object.keys(obj)
    .filter(key => obj[key] !== null && obj[key] !== undefined)
    .map(key => `${encodeURIComponent(key)}=${encodeURIComponent(obj[key])}`)
    .join('&');
}

/**
 * 查询字符串转对象
 * @param {string} queryString - 查询字符串
 * @returns {Object} 对象
 */
function queryStringToObject(queryString) {
  const params = {};
  if (!queryString || queryString.startsWith('?')) {
    queryString = queryString.substring(1);
  }
  queryString.split('&').forEach(pair => {
    const [key, value] = pair.split('=');
    if (key) {
      params[decodeURIComponent(key)] = decodeURIComponent(value || '');
    }
  });
  return params;
}

/**
 * 格式化日期
 * @param {Date|string|number} date - 日期
 * @param {string} format - 格式
 * @returns {string} 格式化后的日期
 */
function formatDate(date, format = 'YYYY-MM-DD HH:mm:ss') {
  const d = new Date(date);
  if (isNaN(d.getTime())) return '';

  const year = d.getFullYear();
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  const hours = String(d.getHours()).padStart(2, '0');
  const minutes = String(d.getMinutes()).padStart(2, '0');
  const seconds = String(d.getSeconds()).padStart(2, '0');

  return format
    .replace('YYYY', year)
    .replace('MM', month)
    .replace('DD', day)
    .replace('HH', hours)
    .replace('mm', minutes)
    .replace('ss', seconds);
}

/**
 * 计算两个日期的差值
 * @param {Date|string|number} date1 - 日期1
 * @param {Date|string|number} date2 - 日期2
 * @returns {number} 差值（毫秒）
 */
function dateDiff(date1, date2) {
  const d1 = new Date(date1);
  const d2 = new Date(date2);
  return d2.getTime() - d1.getTime();
}

/**
 * 计算日期差值（天数）
 * @param {Date|string|number} date1 - 日期1
 * @param {Date|string|number} date2 - 日期2
 * @returns {number} 差值（天数）
 */
function dateDiffDays(date1, date2) {
  return Math.floor(dateDiff(date1, date2) / (1000 * 60 * 60 * 24));
}

/**
 * 随机整数
 * @param {number} min - 最小值
 * @param {number} max - 最大值
 * @returns {number} 随机整数
 */
function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

/**
 * 随机字符串
 * @param {number} length - 长度
 * @param {string} chars - 字符集
 * @returns {string} 随机字符串
 */
function randomString(length = 16, chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789') {
  let result = '';
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

/**
 * 随机数组元素
 * @param {Array} array - 数组
 * @returns {*} 随机元素
 */
function randomArrayItem(array) {
  if (!Array.isArray(array) || array.length === 0) {
    return null;
  }
  return array[Math.floor(Math.random() * array.length)];
}

/**
 * 洗牌数组
 * @param {Array} array - 数组
 * @returns {Array} 洗牌后的数组
 */
function shuffleArray(array) {
  const shuffled = [...array];
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
  }
  return shuffled;
}

/**
 * 分割数组
 * @param {Array} array - 数组
 * @param {number} size - 每组大小
 * @returns {Array<Array>} 分组后的数组
 */
function chunkArray(array, size = 10) {
  const result = [];
  for (let i = 0; i < array.length; i += size) {
    result.push(array.slice(i, i + size));
  }
  return result;
}

/**
 * 去重数组
 * @param {Array} array - 数组
 * @param {string} key - 去重键
 * @returns {Array} 去重后的数组
 */
function uniqueArray(array, key = null) {
  if (!key) {
    return [...new Set(array)];
  }
  const seen = new Set();
  return array.filter(item => {
    const value = key ? item[key] : item;
    if (seen.has(value)) {
      return false;
    }
    seen.add(value);
    return true;
  });
}

/**
 * 数组分组
 * @param {Array} array - 数组
 * @param {Function|string} keyFn - 分组键函数或属性名
 * @returns {Object<Object>} 分组后的对象
 */
function groupBy(array, keyFn) {
  return array.reduce((result, item) => {
    const key = typeof keyFn === 'function' ? keyFn(item) : item[keyFn];
    if (!result[key]) {
      result[key] = [];
    }
    result[key].push(item);
    return result;
  }, {});
}

/**
 * 扁平化数组
 * @param {Array} array - 数组
 * @param {number} depth - 深度
 * @returns {Array} 扁平化后的数组
 */
function flattenArray(array, depth = Infinity) {
  if (depth === 0) {
    return array;
  }

  return array.reduce((result, item) => {
    if (Array.isArray(item)) {
      return [...result, ...flattenArray(item, depth - 1)];
    }
    return [...result, item];
  }, []);
}

/**
 * 映射数组
 * @param {Array} array - 数组
 * @param {Function} fn - 映射函数
 * @returns {Array} 映射后的数组
 */
function mapArray(array, fn) {
  return array.map(fn);
}

/**
 * 过滤数组
 * @param {Array} array - 数组
 * @param {Function} fn - 过滤函数
 * @returns {Array} 过滤后的数组
 */
function filterArray(array, fn) {
  return array.filter(fn);
}

/**
 * 减少数组
 * @param {Array} array - 数组
 * @param {Function} fn - 减少函数
 * @param {*} initialValue - 初始值
 * @returns {*} 减少后的值
 */
function reduceArray(array, fn, initialValue) {
  return array.reduce(fn, initialValue);
}

/**
 * 防止XSS攻击
 * @param {string} str - 字符串
 * @returns {string} 转义后的字符串
 */
function escapeHtml(str) {
  const div = document.createElement('div');
  div.textContent = str;
  return div.innerHTML;
}

/**
 * JSON序列化（处理循环引用）
 * @param {*} obj - 对象
 * @param {number} space - 缩进空格
 * @returns {string} JSON字符串
 */
function stringifySafe(obj, space = 2) {
  const seen = new WeakSet();
  return JSON.stringify(obj, (key, value) => {
    if (typeof value === 'object' && value !== null) {
      if (seen.has(value)) {
        return '[Circular]';
      }
      seen.add(value);
    }
    return value;
  }, space);
}

/**
 * JSON解析（带错误处理）
 * @param {string} str - JSON字符串
 * @param {*} defaultValue - 错误时的默认值
 * @returns {Object} 解析后的对象
 */
function parseJsonSafe(str, defaultValue = null) {
  try {
    return JSON.parse(str);
  } catch {
    return defaultValue;
  }
}

/**
 * 压缩字符串（GZIP - 简化版）
 * @param {string} str - 字符串
 * @returns {string} 压缩后的字符串
 */
function compressString(str) {
  // 这里简化处理，实际应该使用gzip/zlib
  // 返回简化的压缩（实际应用中应使用真实的压缩算法）
  if (str.length < 10) return str;
  return str.substring(0, 5) + '...' + str.substring(str.length - 5);
}

/**
 * 解压缩字符串
 * @param {string} compressed - 压缩后的字符串
 * @returns {string} 解压缩后的字符串
 */
function decompressString(compressed) {
  if (!compressed || compressed.length <= 10) return compressed;
  return compressed.substring(0, 5) + compressed.substring(compressed.length - 5);
}

module.exports = {
  // ID生成
  generateId,

  // 数值处理
  clamp,
  calculatePercentage,
  formatNumber,

  // 字符串处理
  truncate,
  escapeHtml,

  // 日期处理
  formatDate,
  dateDiff,
  dateDiffDays,

  // 数组处理
  delay,
  debounce,
  throttle,
  deepClone,
  mergeDeep,
  randomInt,
  randomString,
  randomArrayItem,
  shuffleArray,
  chunkArray,
  uniqueArray,
  groupBy,
  flattenArray,
  mapArray,
  filterArray,
  reduceArray,

  // 对象处理
  isEmpty,
  isValid,
  getObjectKeysCount,
  getObjectValuesCount,
  objectToQueryString,
  queryStringToObject,

  // 数据验证
  isValidEmail,
  isValidUrl,

  // 安全处理
  safeExecute,
  parseJsonSafe,
  stringifySafe,
  compressString,
  decompressString
};
