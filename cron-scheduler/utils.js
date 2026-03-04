/**
 * Cron Scheduler Utils
 * 通用工具函数
 */

const fs = require('fs');
const path = require('path');

const PROJECT_ROOT = path.join(__dirname, '..');

/**
 * 格式化日期
 */
function formatDate(date) {
  return date.toLocaleDateString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit'
  }).replace(/\//g, '-');
}

/**
 * 格式化时间
 */
function formatTime(date) {
  return date.toLocaleTimeString('zh-CN', {
    hour: '2-digit',
    minute: '2-digit'
  });
}

/**
 * 获取文件大小
 */
function getFileSize(filePath) {
  if (!fs.existsSync(filePath)) {
    return null;
  }
  const stats = fs.statSync(filePath);
  const bytes = stats.size;
  if (bytes < 1024) return bytes + ' B';
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(2) + ' KB';
  return (bytes / (1024 * 1024)).toFixed(2) + ' MB';
}

/**
 * 确保目录存在
 */
function ensureDirectoryExists(dirPath) {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
    return true;
  }
  return false;
}

/**
 * 读取JSON文件
 */
function readJsonFile(filePath) {
  try {
    if (!fs.existsSync(filePath)) {
      return null;
    }
    return JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch (error) {
    console.error(`Error reading JSON file ${filePath}:`, error.message);
    return null;
  }
}

/**
 * 写入JSON文件
 */
function writeJsonFile(filePath, data, indent = 2) {
  try {
    ensureDirectoryExists(path.dirname(filePath));
    fs.writeFileSync(filePath, JSON.stringify(data, null, indent), 'utf8');
    return true;
  } catch (error) {
    console.error(`Error writing JSON file ${filePath}:`, error.message);
    return false;
  }
}

/**
 * 格式化错误信息
 */
function formatError(error) {
  if (error.message) {
    return error.message;
  }
  if (error.stack) {
    return error.stack.split('\n')[0];
  }
  return String(error);
}

/**
 * 安全执行函数
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
 */
function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * 检查路径是否存在
 */
function pathExists(filePath) {
  return fs.existsSync(filePath);
}

/**
 * 检查文件是否存在
 */
function fileExists(filePath) {
  return fs.existsSync(filePath) && fs.statSync(filePath).isFile();
}

/**
 * 检查目录是否存在
 */
function directoryExists(dirPath) {
  return fs.existsSync(dirPath) && fs.statSync(dirPath).isDirectory();
}

/**
 * 获取文件扩展名
 */
function getFileExtension(filePath) {
  const parts = filePath.split('.');
  return parts.length > 1 ? parts.pop().toLowerCase() : '';
}

/**
 * 获取文件名（不含扩展名）
 */
function getFileName(filePath) {
  const parts = filePath.split(path.sep);
  const fileName = parts[parts.length - 1];
  return path.basename(fileName, `.${getFileExtension(fileName)}`);
}

/**
 * 生成唯一ID
 */
function generateId(prefix = 'id') {
  const timestamp = Date.now().toString(36);
  const random = Math.random().toString(36).substring(2, 9);
  return `${prefix}_${timestamp}_${random}`;
}

/**
 * 检查是否为空
 */
function isEmpty(value) {
  if (value === null || value === undefined) return true;
  if (typeof value === 'string' && value.trim() === '') return true;
  if (Array.isArray(value) && value.length === 0) return true;
  if (typeof value === 'object' && Object.keys(value).length === 0) return true;
  return false;
}

/**
 * 深拷贝对象
 */
function deepClone(obj) {
  if (obj === null || typeof obj !== 'object') return obj;
  if (obj instanceof Date) return new Date(obj);
  if (obj instanceof Array) return obj.map(item => deepClone(item));
  if (obj instanceof Object) {
    const cloned = {};
    for (const key in obj) {
      if (obj.hasOwnProperty(key)) {
        cloned[key] = deepClone(obj[key]);
      }
    }
    return cloned;
  }
  return obj;
}

/**
 * 合并对象（深拷贝）
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

module.exports = {
  formatDate,
  formatTime,
  getFileSize,
  ensureDirectoryExists,
  readJsonFile,
  writeJsonFile,
  formatError,
  safeExecute,
  delay,
  pathExists,
  fileExists,
  directoryExists,
  getFileExtension,
  getFileName,
  generateId,
  isEmpty,
  deepClone,
  mergeDeep
};
