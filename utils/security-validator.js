/**
 * OpenClaw Security Validator - 安全验证模块
 * 提供输入验证、SQL注入检测、XSS防护、CSRF防护功能
 */

class SecurityValidator {
  constructor(options = {}) {
    this.options = {
      maxInputLength: options.maxInputLength || 10000, // 最大输入长度
      allowSpecialChars: options.allowSpecialChars || false, // 是否允许特殊字符
      enableSqlInjectionCheck: options.enableSqlInjectionCheck !== false, // 是否启用SQL注入检测
      enableXssProtection: options.enableXssProtection !== false, // 是否启用XSS防护
      enableCsrffProtection: options.enableCsrffProtection !== false, // 是否启用CSRF防护
      ...options
    };
  }

  /**
   * 验证输入字符串
   * @param {string} input - 输入字符串
   * @param {Object} options - 验证选项
   * @returns {Object} 验证结果
   */
  validateInput(input, options = {}) {
    const result = {
      isValid: true,
      errors: [],
      warnings: [],
      cleanedInput: input
    };

    // 检查是否为空
    if (!this.isEmpty(input)) {
      result.errors.push('输入不能为空');
      result.isValid = false;
    }

    // 检查长度
    const maxLength = options.maxLength || this.options.maxInputLength;
    if (input.length > maxLength) {
      result.errors.push(`输入过长，最大允许 ${maxLength} 个字符`);
      result.isValid = false;
    }

    // 检查特殊字符（如果启用）
    if (!this.options.allowSpecialChars && !this.isAlphanumeric(input)) {
      result.warnings.push('输入包含特殊字符，可能存在安全风险');
    }

    // 检查SQL注入
    if (this.options.enableSqlInjectionCheck) {
      const sqlInjections = this.detectSqlInjection(input);
      if (sqlInjections.length > 0) {
        result.errors.push(`检测到SQL注入尝试: ${sqlInjections.join(', ')}`);
        result.isValid = false;
      }
    }

    // 检查XSS攻击
    if (this.options.enableXssProtection) {
      const xssPatterns = this.detectXSS(input);
      if (xssPatterns.length > 0) {
        result.errors.push(`检测到XSS攻击模式: ${xssPatterns.join(', ')}`);
        result.isValid = false;
      }
    }

    // 清理输入
    result.cleanedInput = this.cleanInput(input);

    return result;
  }

  /**
   * 验证邮箱
   * @param {string} email - 邮箱地址
   * @returns {Object} 验证结果
   */
  validateEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    const result = {
      isValid: false,
      email,
      errors: []
    };

    if (!email) {
      result.errors.push('邮箱不能为空');
      return result;
    }

    if (!emailRegex.test(email)) {
      result.errors.push('邮箱格式不正确');
    }

    result.isValid = result.errors.length === 0;
    return result;
  }

  /**
   * 验证URL
   * @param {string} url - URL地址
   * @returns {Object} 验证结果
   */
  validateUrl(url) {
    const result = {
      isValid: false,
      url,
      errors: []
    };

    if (!url) {
      result.errors.push('URL不能为空');
      return result;
    }

    try {
      new URL(url);
      result.isValid = true;
    } catch {
      result.errors.push('URL格式不正确');
    }

    return result;
  }

  /**
   * 验证整数
   * @param {string} value - 整数值
   * @param {Object} options - 选项
   * @returns {Object} 验证结果
   */
  validateInteger(value, options = {}) {
    const result = {
      isValid: false,
      value: null,
      errors: []
    };

    if (value === null || value === undefined) {
      result.errors.push('值不能为空');
      return result;
    }

    const num = Number(value);
    if (!Number.isInteger(num)) {
      result.errors.push('值必须为整数');
    }

    if (options.min !== undefined && num < options.min) {
      result.errors.push(`值不能小于 ${options.min}`);
    }

    if (options.max !== undefined && num > options.max) {
      result.errors.push(`值不能大于 ${options.max}`);
    }

    if (result.errors.length === 0) {
      result.isValid = true;
      result.value = num;
    }

    return result;
  }

  /**
   * 验证字符串长度
   * @param {string} value - 字符串值
   * @param {number} min - 最小长度
   * @param {number} max - 最大长度
   * @returns {Object} 验证结果
   */
  validateStringLength(value, min, max) {
    const result = {
      isValid: true,
      value,
      errors: []
    };

    if (value.length < min) {
      result.errors.push(`字符串过短，至少需要 ${min} 个字符`);
      result.isValid = false;
    }

    if (value.length > max) {
      result.errors.push(`字符串过长，最多允许 ${max} 个字符`);
      result.isValid = false;
    }

    return result;
  }

  /**
   * 检测SQL注入
   * @private
   */
  detectSqlInjection(input) {
    const sqlPatterns = [
      /'/g,
      /"/g,
      /;.*;/g,
      /\.\./g,
      /\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|UNION|WHERE|ORDER BY|GROUP BY)\b/gi,
      /\b(OR|AND)\b.*\b(1=1|1=0|true|false)\b/gi
    ];

    const injections = [];
    sqlPatterns.forEach(pattern => {
      const matches = input.match(pattern);
      if (matches) {
        injections.push(matches.join(', '));
      }
    });

    return injections;
  }

  /**
   * 检测XSS攻击
   * @private
   */
  detectXSS(input) {
    const xssPatterns = [
      /<script\b[^>]*>.*?<\/script>/gi,
      /javascript:/gi,
      /on\w+\s*=/gi,
      /<iframe\b[^>]*>.*?<\/iframe>/gi,
      /<object\b[^>]*>/gi,
      /<embed\b[^>]*>/gi,
      /<form\b[^>]*>/gi,
      /<input\b[^>]*>/gi,
      /<meta\b[^>]*>/gi,
      /<link\b[^>]*>/gi
    ];

    const attacks = [];
    xssPatterns.forEach(pattern => {
      const matches = input.match(pattern);
      if (matches) {
        attacks.push(...matches);
      }
    });

    return attacks;
  }

  /**
   * 清理输入
   * @private
   */
  cleanInput(input) {
    let cleaned = input;

    // HTML转义
    cleaned = this.escapeHtml(cleaned);

    // 移除脚本标签
    cleaned = cleaned.replace(/<script\b[^>]*>.*?<\/script>/gi, '');

    // 移除危险属性
    cleaned = cleaned.replace(/\s*on\w+\s*=/gi, '');

    return cleaned;
  }

  /**
   * HTML转义
   * @private
   */
  escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
  }

  /**
   * 验证CSRF Token
   * @param {string} token - Token
   * @param {string} expectedToken - 预期Token
   * @returns {boolean} 是否有效
   */
  validateCsrfToken(token, expectedToken) {
    if (!token || !expectedToken) {
      return false;
    }

    // 简单比较（实际应用中应该使用加密比较）
    return token === expectedToken;
  }

  /**
   * 生成CSRF Token
   * @returns {string} CSRF Token
   */
  generateCsrfToken() {
    return this.randomString(32);
  }

  /**
   * 验证JSON
   * @param {string} jsonString - JSON字符串
   * @param {Object} schema - JSON Schema
   * @returns {Object} 验证结果
   */
  validateJson(jsonString, schema = null) {
    const result = {
      isValid: false,
      data: null,
      errors: []
    };

    try {
      const data = JSON.parse(jsonString);
      result.data = data;
      result.isValid = true;
    } catch (error) {
      result.errors.push('JSON格式不正确');
      return result;
    }

    // 验证JSON Schema
    if (schema) {
      const validationErrors = this.validateSchema(data, schema);
      result.errors.push(...validationErrors);
      if (validationErrors.length > 0) {
        result.isValid = false;
      }
    }

    return result;
  }

  /**
   * 验证JSON Schema（简化版）
   * @private
   */
  validateSchema(data, schema) {
    const errors = [];

    if (schema.type && typeof data !== schema.type) {
      errors.push(`期望类型: ${schema.type}, 实际类型: ${typeof data}`);
    }

    if (schema.required && Array.isArray(schema.required)) {
      schema.required.forEach(key => {
        if (!(key in data)) {
          errors.push(`缺少必需字段: ${key}`);
        }
      });
    }

    if (schema.enum && !schema.enum.includes(data)) {
      errors.push(`值不在允许的枚举范围内: ${schema.enum.join(', ')}`);
    }

    if (schema.minLength !== undefined && data.length < schema.minLength) {
      errors.push(`长度不能小于 ${schema.minLength}`);
    }

    if (schema.maxLength !== undefined && data.length > schema.maxLength) {
      errors.push(`长度不能大于 ${schema.maxLength}`);
    }

    return errors;
  }

  /**
   * 检查字符串是否为字母数字
   * @private
   */
  isAlphanumeric(str) {
    return /^[a-zA-Z0-9]+$/.test(str);
  }

  /**
   * 检查是否为空
   * @private
   */
  isEmpty(value) {
    return value === null || value === undefined || value === '' ||
           (Array.isArray(value) && value.length === 0);
  }

  /**
   * 随机字符串
   * @private
   */
  randomString(length = 32) {
    let result = '';
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    for (let i = 0; i < length; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
  }

  /**
   * 哈希字符串
   * @param {string} str - 字符串
   * @returns {string} 哈希值
   */
  hashString(str) {
    const crypto = require('crypto');
    return crypto.createHash('sha256').update(str).digest('hex');
  }

  /**
   * 加密字符串
   * @param {string} str - 字符串
   * @returns {string} 加密后的字符串
   */
  encryptString(str) {
    const crypto = require('crypto');
    const algorithm = 'aes-256-cbc';
    const key = this.hashString(process.env.SECRET_KEY || 'default-key');
    const iv = crypto.randomBytes(16);

    const cipher = crypto.createCipheriv(algorithm, Buffer.from(key, 'hex'), iv);
    let encrypted = cipher.update(str, 'utf8', 'hex');
    encrypted += cipher.final('hex');

    return iv.toString('hex') + ':' + encrypted;
  }

  /**
   * 解密字符串
   * @param {string} encrypted - 加密后的字符串
   * @returns {string} 解密后的字符串
   */
  decryptString(encrypted) {
    const crypto = require('crypto');
    const algorithm = 'aes-256-cbc';
    const key = this.hashString(process.env.SECRET_KEY || 'default-key');

    const parts = encrypted.split(':');
    const iv = Buffer.from(parts[0], 'hex');
    const encryptedText = parts[1];

    const decipher = crypto.createDecipheriv(algorithm, Buffer.from(key, 'hex'), iv);
    let decrypted = decipher.update(encryptedText, 'hex', 'utf8');
    decrypted += decipher.final('utf8');

    return decrypted;
  }

  /**
   * 获取安全配置
   * @returns {Object} 安全配置
   */
  getSecurityConfig() {
    return {
      maxInputLength: this.options.maxInputLength,
      allowSpecialChars: this.options.allowSpecialChars,
      enableSqlInjectionCheck: this.options.enableSqlInjectionCheck,
      enableXssProtection: this.options.enableXssProtection,
      enableCsrffProtection: this.options.enableCsrffProtection
    };
  }
}

module.exports = SecurityValidator;
