/**
 * String Utilities
 * 字符串处理的工具函数
 */

/**
 * 截断字符串
 * @param {string} str - 字符串
 * @param {number} maxLength - 最大长度
 * @param {string} suffix - 后缀
 * @returns {string} 截断后的字符串
 */
function truncate(str, maxLength, suffix = '...') {
  if (!str || str.length <= maxLength) return str;
  return str.substring(0, maxLength - suffix.length) + suffix;
}

/**
 * HTML转义
 * @param {string} str - 字符串
 * @returns {string} 转义后的字符串
 */
function escapeHtml(str) {
  if (!str) return '';
  const div = document.createElement('div');
  div.textContent = str;
  return div.innerHTML;
}

/**
 * 防止XSS攻击
 * @param {string} str - 字符串
 * @returns {string} 转义后的字符串
 */
function sanitizeHtml(str) {
  const div = document.createElement('div');
  div.textContent = str;
  return div.innerHTML;
}

/**
 * 防止SQL注入
 * @param {string} str - 字符串
 * @returns {string} 转义后的字符串
 */
function escapeSql(str) {
  if (!str) return '';
  return str.replace(/'/g, "''").replace(/"/g, '&quot;');
}

/**
 * 首字母大写
 * @param {string} str - 字符串
 * @returns {string} 首字母大写
 */
function capitalize(str) {
  if (!str) return '';
  return str.charAt(0).toUpperCase() + str.slice(1);
}

/**
 * 首字母小写
 * @param {string} str - 字符串
 * @returns {string} 首字母小写
 */
function uncapitalize(str) {
  if (!str) return '';
  return str.charAt(0).toLowerCase() + str.slice(1);
}

/**
 * 大小写转换
 * @param {string} str - 字符串
 * @returns {string} 大写后的字符串
 */
function toUpperCase(str) {
  return str ? str.toUpperCase() : '';
}

/**
 * 小写转换
 * @param {string} str - 字符串
 * @returns {string} 小写后的字符串
 */
function toLowerCase(str) {
  return str ? str.toLowerCase() : '';
}

/**
 * 驼峰命名转短横线
 * @param {string} str - 驼峰命名字符串
 * @returns {string} 短横线命名字符串
 */
function camelToKebab(str) {
  if (!str) return '';
  return str.replace(/[A-Z]/g, letter => '-' + letter.toLowerCase());
}

/**
 * 短横线转驼峰命名
 * @param {string} str - 短横线命名字符串
 * @returns {string} 驼峰命名字符串
 */
function kebabToCamel(str) {
  if (!str) return '';
  return str.replace(/-([a-z])/g, (match, letter) => letter.toUpperCase());
}

/**
 * 移除字符串中的特殊字符
 * @param {string} str - 字符串
 * @param {string} chars - 要移除的字符
 * @returns {string} 清理后的字符串
 */
function removeSpecialChars(str, chars = ' !@#$%^&*()_+=[]{}|;:,.<>?') {
  if (!str) return '';
  return str.split('').filter(char => !chars.includes(char)).join('');
}

/**
 * 去除字符串两端的空白
 * @param {string} str - 字符串
 * @returns {string} 清理后的字符串
 */
function trim(str) {
  return str ? str.trim() : '';
}

/**
 * 去除字符串两端的空白和换行
 * @param {string} str - 字符串
 * @returns {string} 清理后的字符串
 */
function trimLines(str) {
  if (!str) return '';
  return str.split('\n').map(line => trim(line)).filter(line => line).join('\n');
}

/**
 * 统计字符数量
 * @param {string} str - 字符串
 * @returns {number} 字符数量
 */
function countChars(str) {
  return str ? str.length : 0;
}

/**
 * 统计单词数量
 * @param {string} str - 字符串
 * @returns {number} 单词数量
 */
function countWords(str) {
  if (!str) return 0;
  return str.trim().split(/\s+/).length;
}

/**
 * 反转字符串
 * @param {string} str - 字符串
 * @returns {string} 反转后的字符串
 */
function reverse(str) {
  return str ? str.split('').reverse().join('') : '';
}

/**
 * 重复字符串
 * @param {string} str - 字符串
 * @param {number} times - 重复次数
 * @returns {string} 重复后的字符串
 */
function repeat(str, times) {
  return str ? str.repeat(times) : '';
}

/**
 * 统计中文字符数量
 * @param {string} str - 字符串
 * @returns {number} 中文字符数量
 */
function countChineseChars(str) {
  if (!str) return 0;
  const chineseChars = /[\u4e00-\u9fa5]/g;
  const matches = str.match(chineseChars);
  return matches ? matches.length : 0;
}

module.exports = {
  truncate,
  escapeHtml,
  sanitizeHtml,
  escapeSql,
  capitalize,
  uncapitalize,
  toUpperCase,
  toLowerCase,
  camelToKebab,
  kebabToCamel,
  removeSpecialChars,
  trim,
  trimLines,
  countChars,
  countWords,
  reverse,
  repeat,
  countChineseChars
};
