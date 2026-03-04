/**
 * 统一错误处理系统
 * 提供错误分类、记录、通知等功能
 */

const { getConfig } = require('../config');
const logger = require('./logger');

// 错误类型
const ErrorType = {
  UNKNOWN: 'UNKNOWN',
  NETWORK: 'NETWORK',
  VALIDATION: 'VALIDATION',
  AUTHENTICATION: 'AUTHENTICATION',
  AUTHORIZATION: 'AUTHORIZATION',
  NOT_FOUND: 'NOT_FOUND',
  CONFLICT: 'CONFLICT',
  RATE_LIMIT: 'RATE_LIMIT',
  TIMEOUT: 'TIMEOUT',
  VALIDATION_ERROR: 'VALIDATION_ERROR',
  INTERNAL_ERROR: 'INTERNAL_ERROR',
  CONFIG_ERROR: 'CONFIG_ERROR',
  SERVICE_ERROR: 'SERVICE_ERROR',
};

// 错误严重程度
const ErrorSeverity = {
  LOW: 0,
  MEDIUM: 1,
  HIGH: 2,
  CRITICAL: 3,
};

// 错误分类器
class ErrorClassifier {
  static classify(error) {
    if (error.code === 'ECONNREFUSED' || error.code === 'ETIMEDOUT' ||
        error.code === 'ENOTFOUND' || error.code === 'ECONNRESET') {
      return ErrorType.NETWORK;
    }

    if (error.code === 'ETIMEDOUT') {
      return ErrorType.TIMEOUT;
    }

    if (error.code === 'ECONNREFUSED') {
      return ErrorType.NETWORK;
    }

    if (error.code === 401 || error.code === 'UNAUTHORIZED') {
      return ErrorType.AUTHENTICATION;
    }

    if (error.code === 403 || error.code === 'FORBIDDEN') {
      return ErrorType.AUTHORIZATION;
    }

    if (error.code === 404 || error.status === 404) {
      return ErrorType.NOT_FOUND;
    }

    if (error.code === 409 || error.code === 'CONFLICT') {
      return ErrorType.CONFLICT;
    }

    if (error.code === 429 || error.code === 'RATE_LIMIT') {
      return ErrorType.RATE_LIMIT;
    }

    if (error.name === 'ValidationError' || error.name === 'CastError') {
      return ErrorType.VALIDATION;
    }

    if (error.name === 'ConfigurationError' || error.name === 'ConfigError') {
      return ErrorType.CONFIG_ERROR;
    }

    if (error.name === 'ServiceError') {
      return ErrorType.SERVICE_ERROR;
    }

    return ErrorType.INTERNAL_ERROR;
  }

  static getSeverity(error) {
    const type = this.classify(error);

    const severityMap = {
      [ErrorType.VALIDATION]: ErrorSeverity.LOW,
      [ErrorType.NOT_FOUND]: ErrorSeverity.LOW,
      [ErrorType.TIMEOUT]: ErrorSeverity.MEDIUM,
      [ErrorType.RATE_LIMIT]: ErrorSeverity.LOW,
      [ErrorType.NETWORK]: ErrorSeverity.MEDIUM,
      [ErrorType.AUTHENTICATION]: ErrorSeverity.MEDIUM,
      [ErrorType.AUTHORIZATION]: ErrorSeverity.MEDIUM,
      [ErrorType.CONFLICT]: ErrorSeverity.LOW,
      [ErrorType.VALIDATION_ERROR]: ErrorSeverity.LOW,
      [ErrorType.CONFIG_ERROR]: ErrorSeverity.HIGH,
      [ErrorType.SERVICE_ERROR]: ErrorSeverity.HIGH,
      [ErrorType.INTERNAL_ERROR]: ErrorSeverity.CRITICAL,
      [ErrorType.UNKNOWN]: ErrorSeverity.MEDIUM,
    };

    return severityMap[type] || ErrorSeverity.MEDIUM;
  }
}

// 错误处理器
class ErrorHandler {
  constructor(options = {}) {
    this.emailEnabled = getConfig().errorHandler.sendEmail;
    this.emailRecipients = getConfig().errorHandler.emailRecipients;
    this.emailSubject = getConfig().errorHandler.emailSubject;
    this.emailSender = options.sender || 'noreply@openclaw.io';
  }

  /**
   * 处理错误
   */
  handle(error, context = {}) {
    const { type, severity, message, stack, details } = this.analyzeError(error);

    logger.errorWithStack(error, {
      type,
      severity,
      context,
      ...details,
    });

    // 发送邮件通知（仅关键错误）
    if (this.emailEnabled && severity >= ErrorSeverity.HIGH) {
      this.sendEmailNotification(error, type, severity, context);
    }

    return {
      type,
      severity,
      message,
      stack,
    };
  }

  /**
   * 分析错误
   */
  analyzeError(error) {
    const type = ErrorClassifier.classify(error);
    const severity = ErrorClassifier.getSeverity(error);

    return {
      type,
      severity,
      message: error.message || 'Unknown error',
      stack: error.stack || null,
      code: error.code || null,
      status: error.status || null,
      name: error.name || 'Error',
      details: this.extractDetails(error),
    };
  }

  /**
   * 提取错误详情
   */
  extractDetails(error) {
    const details = {};

    if (error.response) {
      details.response = {
        status: error.response.status,
        data: error.response.data,
      };
    }

    if (error.request) {
      details.request = {
        method: error.request.method,
        url: error.request.url,
      };
    }

    if (error.config) {
      details.config = {
        url: error.config.url,
        method: error.config.method,
      };
    }

    return details;
  }

  /**
   * 发送邮件通知
   */
  async sendEmailNotification(error, type, severity, context) {
    try {
      const subject = `[${ErrorSeverity[severity]}] ${this.emailSubject}: ${error.message}`;

      const htmlContent = `
        <html>
          <body>
            <h2>Error Notification</h2>
            <p><strong>Type:</strong> ${type}</p>
            <p><strong>Severity:</strong> ${ErrorSeverity[severity]}</p>
            <p><strong>Message:</strong> ${error.message}</p>
            ${error.stack ? `<pre><code>${error.stack}</code></pre>` : ''}
            ${context ? `<p><strong>Context:</strong> ${JSON.stringify(context)}</p>` : ''}
          </body>
        </html>
      `;

      // TODO: 实现邮件发送
      // await this.emailService.send({
      //   to: this.emailRecipients,
      //   subject,
      //   html: htmlContent,
      // });

      logger.info('Email notification sent', { type, severity });
    } catch (emailError) {
      logger.error('Failed to send email notification', {
        error: emailError.message,
      });
    }
  }

  /**
   * 创建自定义错误
   */
  createError(type, message, details = {}) {
    const error = new Error(message);
    error.type = type;
    error.severity = ErrorSeverity[ErrorSeverity[Object.keys(ErrorSeverity).find(k => ErrorSeverity[k] === ErrorSeverity.MEDIUM)]];
    error.code = details.code || null;
    error.status = details.status || null;
    error.name = details.name || type;

    Object.assign(error, details);

    return error;
  }

  /**
   * 验证必填字段
   */
  validateRequired(data, fields, entityName = 'Entity') {
    const missingFields = [];

    fields.forEach(field => {
      if (!data[field]) {
        missingFields.push(field);
      }
    });

    if (missingFields.length > 0) {
      const error = this.createError(
        ErrorType.VALIDATION,
        `${entityName} validation failed: missing fields: ${missingFields.join(', ')}`,
        { missingFields }
      );
      throw error;
    }

    return true;
  }

  /**
   * 请求验证
   */
  validateRequest(req, rules, entityName = 'Request') {
    const errors = [];

    Object.keys(rules).forEach(field => {
      const rule = rules[field];
      const value = req.body[field] || req.query[field] || req.params[field];

      if (rule.required && !value) {
        errors.push(`${field} is required`);
      }

      if (rule.type && value && typeof value !== rule.type) {
        errors.push(`${field} must be of type ${rule.type}`);
      }

      if (rule.minLength && value && value.length < rule.minLength) {
        errors.push(`${field} must be at least ${rule.minLength} characters`);
      }

      if (rule.maxLength && value && value.length > rule.maxLength) {
        errors.push(`${field} must be at most ${rule.maxLength} characters`);
      }

      if (rule.pattern && value && !rule.pattern.test(value)) {
        errors.push(`${field} does not match the required pattern`);
      }

      if (rule.enum && value && !rule.enum.includes(value)) {
        errors.push(`${field} must be one of: ${rule.enum.join(', ')}`);
      }
    });

    if (errors.length > 0) {
      const error = this.createError(
        ErrorType.VALIDATION_ERROR,
        `Validation failed: ${errors.join(', ')}`,
        { errors }
      );
      throw error;
    }

    return true;
  }

  /**
   * 捕获异步错误
   */
  async catchAsync(fn, context = {}) {
    return async (req, res, next) => {
      try {
        await fn(req, res, next);
      } catch (error) {
        this.handle(error, context);
        next(error);
      }
    };
  }

  /**
   * 错误响应
   */
  sendErrorResponse(res, error, statusCode = 500) {
    const { type, message, stack } = this.analyzeError(error);

    const response = {
      error: {
        type,
        message,
        timestamp: new Date().toISOString(),
      },
    };

    // 仅在开发环境返回堆栈跟踪
    if (process.env.NODE_ENV === 'development') {
      response.error.stack = stack;
    }

    res.status(statusCode).json(response);
  }
}

// 创建全局错误处理器实例
const errorHandler = new ErrorHandler();

module.exports = errorHandler;
module.exports.ErrorHandler = ErrorHandler;
module.exports.ErrorType = ErrorType;
module.exports.ErrorSeverity = ErrorSeverity;
