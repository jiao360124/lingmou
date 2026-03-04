/**
 * 统一日志系统
 * 支持多种格式（JSON/TXT）、日志级别、日志轮转
 */

const fs = require('fs');
const path = require('path');
const { getConfig } = require('../config');

// 日志级别
const LogLevel = {
  TRACE: 0,
  DEBUG: 1,
  INFO: 2,
  WARN: 3,
  ERROR: 4,
  FATAL: 5,
};

// 日志级别名称
const LogLevelNames = {
  [LogLevel.TRACE]: 'TRACE',
  [LogLevel.DEBUG]: 'DEBUG',
  [LogLevel.INFO]: 'INFO',
  [LogLevel.WARN]: 'WARN',
  [LogLevel.ERROR]: 'ERROR',
  [LogLevel.FATAL]: 'FATAL',
};

// 日志级别颜色
const LogLevelColors = {
  [LogLevel.TRACE]: '\x1b[36m', // Cyan
  [LogLevel.DEBUG]: '\x1b[36m', // Cyan
  [LogLevel.INFO]: '\x1b[32m',  // Green
  [LogLevel.WARN]: '\x1b[33m',  // Yellow
  [LogLevel.ERROR]: '\x1b[31m', // Red
  [LogLevel.FATAL]: '\x1b[35m', // Magenta
};

const Reset = '\x1b[0m';

class Logger {
  constructor(moduleName = 'System') {
    this.moduleName = moduleName;
    this.currentLevel = this.getLevelFromConfig();
    this.enabled = this.currentLevel !== LogLevel.FATAL;
    this.jsonFormat = this.getFormatFromConfig();
  }

  getLevelFromConfig() {
    const config = getConfig();
    const level = config.log.level.toLowerCase();

    const levelMap = {
      trace: LogLevel.TRACE,
      debug: LogLevel.DEBUG,
      info: LogLevel.INFO,
      warn: LogLevel.WARN,
      error: LogLevel.ERROR,
      fatal: LogLevel.FATAL,
    };

    return levelMap[level] || LogLevel.INFO;
  }

  getFormatFromConfig() {
    const config = getConfig();
    return config.log.format.toLowerCase() === 'json';
  }

  formatTimestamp() {
    const now = new Date();
    return now.toISOString();
  }

  formatJSON(level, message, meta = {}) {
    const logEntry = {
      timestamp: this.formatTimestamp(),
      level: LogLevelNames[level],
      module: this.moduleName,
      message,
      ...meta,
    };

    return JSON.stringify(logEntry);
  }

  formatText(level, message, meta = {}) {
    const colors = LogLevelColors[level] || '';
    const colorReset = level !== 5 ? Reset : '';
    const timestamp = this.formatTimestamp();

    let formatted = `[${timestamp}] ${colors}[${LogLevelNames[level]}]${colorReset} [${this.moduleName}] ${message}`;

    if (Object.keys(meta).length > 0) {
      formatted += ' ' + JSON.stringify(meta);
    }

    return formatted;
  }

  log(level, message, meta = {}) {
    if (level > this.currentLevel) {
      return;
    }

    const formatted = this.jsonFormat
      ? this.formatJSON(level, message, meta)
      : this.formatText(level, message, meta);

    // 写入文件
    this.writeToFile(formatted);

    // 输出到控制台
    console.log(formatted);
  }

  writeToFile(message) {
    try {
      const config = getConfig();
      const logDir = config.log.dir;
      const date = new Date().toISOString().split('T')[0];

      if (!fs.existsSync(logDir)) {
        fs.mkdirSync(logDir, { recursive: true });
      }

      const logFile = path.join(logDir, `${date}.log`);

      fs.appendFileSync(logFile, message + '\n', 'utf-8');
    } catch (error) {
      // 文件写入失败，只输出到控制台
      console.error('Failed to write to log file:', error.message);
    }
  }

  trace(message, meta = {}) {
    this.log(LogLevel.TRACE, message, meta);
  }

  debug(message, meta = {}) {
    this.log(LogLevel.DEBUG, message, meta);
  }

  info(message, meta = {}) {
    this.log(LogLevel.INFO, message, meta);
  }

  warn(message, meta = {}) {
    this.log(LogLevel.WARN, message, meta);
  }

  error(message, meta = {}) {
    this.log(LogLevel.ERROR, message, meta);
  }

  fatal(message, meta = {}) {
    this.log(LogLevel.FATAL, message, meta);
  }

  // 请求日志
  request(method, url, status, duration, meta = {}) {
    this.info('HTTP Request', {
      method,
      url,
      status,
      duration: `${duration}ms`,
      ...meta,
    });
  }

  // 错误日志
  errorWithStack(error, meta = {}) {
    this.error(error.message, {
      stack: error.stack,
      ...meta,
    });
  }

  // 性能日志
  performance(operation, duration, meta = {}) {
    this.debug(`Performance: ${operation}`, {
      duration: `${duration}ms`,
      ...meta,
    });
  }

  // 清理旧日志
  cleanOldLogs() {
    try {
      const config = getConfig();
      const logDir = config.log.dir;
      const retentionDays = 14; // 默认保留 14 天

      const files = fs.readdirSync(logDir);
      const now = new Date();
      const retentionDate = new Date(now.getTime() - retentionDays * 24 * 60 * 60 * 1000);

      files.forEach(file => {
        if (!file.endsWith('.log')) return;

        const filePath = path.join(logDir, file);
        const stats = fs.statSync(filePath);
        const fileDate = new Date(stats.mtime);

        if (fileDate < retentionDate) {
          fs.unlinkSync(filePath);
          this.info('Cleaned old log file', { file, date: fileDate.toISOString() });
        }
      });
    } catch (error) {
      this.error('Failed to clean old logs', { error: error.message });
    }
  }
}

// 创建全局 logger 实例
const logger = new Logger();

module.exports = logger;
module.exports.Logger = Logger;
module.exports.LogLevel = LogLevel;
