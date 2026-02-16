/**
 * 日志系统单元测试
 */

const assert = require('assert');
const { LogLevel, Logger } = require('../../utils/logger');

describe('Logger', () => {
  let logger;

  beforeEach(() => {
    logger = new Logger('TestModule');
  });

  afterEach(() => {
    // Clean up logs
    if (logger && logger.cleanOldLogs) {
      logger.cleanOldLogs();
    }
  });

  describe('Log Levels', () => {
    it('should log at TRACE level', () => {
      const originalLevel = logger.currentLevel;
      logger.currentLevel = LogLevel.TRACE;

      const consoleSpy = jest.spyOn(console, 'log').mockImplementation(() => {});

      logger.trace('Test trace message');

      expect(consoleSpy).toHaveBeenCalled();
      consoleSpy.mockRestore();
      logger.currentLevel = originalLevel;
    });

    it('should log at DEBUG level', () => {
      const originalLevel = logger.currentLevel;
      logger.currentLevel = LogLevel.DEBUG;

      const consoleSpy = jest.spyOn(console, 'log').mockImplementation(() => {});

      logger.debug('Test debug message');

      expect(consoleSpy).toHaveBeenCalled();
      consoleSpy.mockRestore();
      logger.currentLevel = originalLevel;
    });

    it('should log at INFO level', () => {
      const originalLevel = logger.currentLevel;
      logger.currentLevel = LogLevel.INFO;

      const consoleSpy = jest.spyOn(console, 'log').mockImplementation(() => {});

      logger.info('Test info message');

      expect(consoleSpy).toHaveBeenCalled();
      consoleSpy.mockRestore();
      logger.currentLevel = originalLevel;
    });

    it('should log at WARN level', () => {
      const originalLevel = logger.currentLevel;
      logger.currentLevel = LogLevel.WARN;

      const consoleSpy = jest.spyOn(console, 'log').mockImplementation(() => {});

      logger.warn('Test warn message');

      expect(consoleSpy).toHaveBeenCalled();
      consoleSpy.mockRestore();
      logger.currentLevel = originalLevel;
    });

    it('should log at ERROR level', () => {
      const originalLevel = logger.currentLevel;
      logger.currentLevel = LogLevel.ERROR;

      const consoleSpy = jest.spyOn(console, 'log').mockImplementation(() => {});

      logger.error('Test error message');

      expect(consoleSpy).toHaveBeenCalled();
      consoleSpy.mockRestore();
      logger.currentLevel = originalLevel;
    });

    it('should log at FATAL level', () => {
      const originalLevel = logger.currentLevel;
      logger.currentLevel = LogLevel.FATAL;

      const consoleSpy = jest.spyOn(console, 'log').mockImplementation(() => {});

      logger.fatal('Test fatal message');

      expect(consoleSpy).toHaveBeenCalled();
      consoleSpy.mockRestore();
      logger.currentLevel = originalLevel;
    });
  });

  describe('Error Handling', () => {
    it('should log error with stack trace', () => {
      const originalLevel = logger.currentLevel;
      logger.currentLevel = LogLevel.ERROR;

      const consoleSpy = jest.spyOn(console, 'log').mockImplementation(() => {});

      const error = new Error('Test error');
      logger.errorWithStack(error);

      expect(consoleSpy).toHaveBeenCalled();
      consoleSpy.mockRestore();
      logger.currentLevel = originalLevel;
    });

    it('should accept error context', () => {
      const originalLevel = logger.currentLevel;
      logger.currentLevel = LogLevel.ERROR;

      const consoleSpy = jest.spyOn(console, 'log').mockImplementation(() => {});

      const error = new Error('Test error');
      logger.errorWithStack(error, { userId: 123, action: 'test' });

      expect(consoleSpy).toHaveBeenCalled();
      consoleSpy.mockRestore();
      logger.currentLevel = originalLevel;
    });
  });

  describe('Request Logging', () => {
    it('should log HTTP requests', () => {
      const consoleSpy = jest.spyOn(console, 'log').mockImplementation(() => {});

      logger.request('GET', '/api/data', 200, 150, { ip: '127.0.0.1' });

      expect(consoleSpy).toHaveBeenCalled();
      consoleSpy.mockRestore();
    });
  });

  describe('Performance Logging', () => {
    it('should log performance metrics', () => {
      const originalLevel = logger.currentLevel;
      logger.currentLevel = LogLevel.DEBUG;

      const consoleSpy = jest.spyOn(console, 'log').mockImplementation(() => {});

      logger.performance('Database Query', 1250);

      expect(consoleSpy).toHaveBeenCalled();
      consoleSpy.mockRestore();
      logger.currentLevel = originalLevel;
    });
  });

  describe('Log Format', () => {
    it('should support JSON format', () => {
      const originalLevel = logger.currentLevel;
      logger.currentLevel = LogLevel.INFO;
      logger.jsonFormat = true;

      const consoleSpy = jest.spyOn(console, 'log').mockImplementation(() => {});

      logger.info('Test message');

      expect(consoleSpy).toHaveBeenCalled();
      consoleSpy.mockRestore();
      logger.currentLevel = originalLevel;
    });

    it('should support text format', () => {
      const originalLevel = logger.currentLevel;
      logger.currentLevel = LogLevel.INFO;
      logger.jsonFormat = false;

      const consoleSpy = jest.spyOn(console, 'log').mockImplementation(() => {});

      logger.info('Test message');

      expect(consoleSpy).toHaveBeenCalled();
      consoleSpy.mockRestore();
      logger.currentLevel = originalLevel;
    });
  });

  describe('Cache Management', () => {
    it('should clean old logs', () => {
      const originalLevel = logger.currentLevel;
      logger.currentLevel = LogLevel.TRACE;

      const spy = jest.spyOn(logger, 'cleanOldLogs').mockImplementation(() => {});

      logger.cleanOldLogs();

      expect(spy).toHaveBeenCalled();
      spy.mockRestore();
      logger.currentLevel = originalLevel;
    });
  });

  describe('Module Name', () => {
    it('should use module name', () => {
      const logger1 = new Logger('Module1');
      const logger2 = new Logger('Module2');

      const consoleSpy = jest.spyOn(console, 'log').mockImplementation(() => {});

      logger1.info('Test');
      logger2.info('Test');

      expect(consoleSpy).toHaveBeenCalled();
      consoleSpy.mockRestore();
    });
  });

  describe('Log Level Management', () => {
    it('should set log level', () => {
      logger.currentLevel = LogLevel.DEBUG;
      expect(logger.currentLevel).toBe(LogLevel.DEBUG);
    });

    it('should only log messages at or above current level', () => {
      logger.currentLevel = LogLevel.INFO;

      const consoleSpy = jest.spyOn(console, 'log').mockImplementation(() => {});

      // These should be logged
      logger.info('Info message');
      logger.warn('Warn message');
      logger.error('Error message');

      // These should NOT be logged
      logger.debug('Debug message'); // Should not log
      logger.trace('Trace message'); // Should not log

      // Check that trace and debug were not called
      expect(consoleSpy).toHaveBeenCalledTimes(3);
      consoleSpy.mockRestore();
    });
  });
});
