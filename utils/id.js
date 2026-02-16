/**
 * ID Generation Utils
 * 生成唯一ID的工具函数
 */

/**
 * 生成唯一ID
 * @param {string} prefix - ID前缀
 * @returns {string} 唯一ID
 */
function generateId(prefix = 'id') {
  const timestamp = Date.now().toString(36);
  const random = Math.random().toString(36).substring(2, 9);
  return `${prefix}_${timestamp}_${random}`;
}

/**
 * 生成UUID v4风格ID
 * @param {string} prefix - ID前缀
 * @returns {string} UUID
 */
function generateUuid(prefix = '') {
  const uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    const r = Math.random() * 16 | 0;
    const v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
  return prefix ? `${prefix}_${uuid}` : uuid;
}

/**
 * 生成简短ID
 * @param {number} length - 长度
 * @returns {string} 简短ID
 */
function generateShortId(length = 8) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

/**
 * 生成数字ID
 * @param {number} start - 起始值
 * @param {number} step - 步进
 * @param {number} prefix - 前缀
 * @returns {string} 数字ID
 */
function generateNumberId(start = 1, step = 1, prefix = '') {
  const id = prefix ? `${prefix}_${start}` : start.toString();
  return id;
}

module.exports = {
  generateId,
  generateUuid,
  generateShortId,
  generateNumberId
};
