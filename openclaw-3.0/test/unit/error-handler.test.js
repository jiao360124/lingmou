/**
 * 错误处理系统单元测试
 */

const assert = require('assert');
const { ErrorHandler, ErrorType, ErrorSeverity } = require('../../utils/error-handler');

describe('ErrorHandler', () => {
  let errorHandler;

  beforeEach(() => {
    errorHandler = new ErrorHandler();
  });

  describe('Error Classifier', () => {
    it('should classify network errors', () => {
      const error = new Error('ECONNREFUSED');
      error.code = 'ECONNREFUSED';

      const type = errorHandler.classify(error);
      assert.strictEqual(type, ErrorType.NETWORK);
    });

    it('should classify timeout errors', () => {
      const error = new Error('ETIMEDOUT');
      error.code = 'ETIMEDOUT';

      const type = errorHandler.classify(error);
      assert.strictEqual(type, ErrorType.TIMEOUT);
    });

    it('should classify 404 errors', () => {
      const error = { code: 404 };
      const type = errorHandler.classify(error);
      assert.strictEqual(type, ErrorType.NOT_FOUND);
    });

    it('should classify 401 errors', () => {
      const error = { code: 401 };
      const type = errorHandler.classify(error);
      assert.strictEqual(type, ErrorType.AUTHENTICATION);
    });

    it('should classify 403 errors', () => {
      const error = { code: 403 };
      const type = errorHandler.classify(error);
      assert.strictEqual(type, ErrorType.AUTHORIZATION);
    });

    it('should classify validation errors', () => {
      const error = new Error('ValidationError');
      error.name = 'ValidationError';

      const type = errorHandler.classify(error);
      assert.strictEqual(type, ErrorType.VALIDATION);
    });

    it('should classify config errors', () => {
      const error = new Error('ConfigurationError');
      error.name = 'ConfigurationError';

      const type = errorHandler.classify(error);
      assert.strictEqual(type, ErrorType.CONFIG_ERROR);
    });

    it('should classify internal errors', () => {
      const error = new Error('Internal error');
      error.name = 'Error';

      const type = errorHandler.classify(error);
      assert.strictEqual(type, ErrorType.INTERNAL_ERROR);
    });

    it('should classify unknown errors', () => {
      const error = new Error('Unknown error');

      const type = errorHandler.classify(error);
      assert.strictEqual(type, ErrorType.UNKNOWN);
    });
  });

  describe('Severity Assessment', () => {
    it('should assess validation errors as LOW', () => {
      const error = { code: 400 };
      const severity = errorHandler.getSeverity(error);
      assert.strictEqual(severity, ErrorSeverity.LOW);
    });

    it('should assess timeout errors as MEDIUM', () => {
      const error = { code: 'ETIMEDOUT' };
      const severity = errorHandler.getSeverity(error);
      assert.strictEqual(severity, ErrorSeverity.MEDIUM);
    });

    it('should assess network errors as MEDIUM', () => {
      const error = { code: 'ECONNREFUSED' };
      const severity = errorHandler.getSeverity(error);
      assert.strictEqual(severity, ErrorSeverity.MEDIUM);
    });

    it('should assess config errors as HIGH', () => {
      const error = { name: 'ConfigurationError' };
      const severity = errorHandler.getSeverity(error);
      assert.strictEqual(severity, ErrorSeverity.HIGH);
    });

    it('should assess service errors as HIGH', () => {
      const error = { name: 'ServiceError' };
      const severity = errorHandler.getSeverity(error);
      assert.strictEqual(severity, ErrorSeverity.HIGH);
    });

    it('should assess internal errors as CRITICAL', () => {
      const error = { name: 'Error' };
      const severity = errorHandler.getSeverity(error);
      assert.strictEqual(severity, ErrorSeverity.CRITICAL);
    });

    it('should assess unknown errors as MEDIUM', () => {
      const error = new Error('Unknown');
      const severity = errorHandler.getSeverity(error);
      assert.strictEqual(severity, ErrorSeverity.MEDIUM);
    });
  });

  describe('Error Analysis', () => {
    it('should analyze error with message', () => {
      const error = new Error('Test error');
      const analysis = errorHandler.analyzeError(error);

      assert.strictEqual(analysis.type, ErrorType.UNKNOWN);
      assert.strictEqual(analysis.severity, ErrorSeverity.MEDIUM);
      assert.strictEqual(analysis.message, 'Test error');
      assert.ok(analysis.stack);
      assert.strictEqual(analysis.name, 'Error');
    });

    it('should analyze error with details', () => {
      const error = {
        message: 'Test error',
        code: 404,
        status: 404,
        name: 'NotFoundError',
      };

      const analysis = errorHandler.analyzeError(error);

      assert.strictEqual(analysis.type, ErrorType.NOT_FOUND);
      assert.strictEqual(analysis.severity, ErrorSeverity.LOW);
      assert.strictEqual(analysis.code, 404);
      assert.strictEqual(analysis.status, 404);
      assert.strictEqual(analysis.name, 'NotFoundError');
    });
  });

  describe('Error Creation', () => {
    it('should create custom error', () => {
      const error = errorHandler.createError(
        ErrorType.VALIDATION,
        'Invalid email format',
        { field: 'email' }
      );

      assert.ok(error);
      assert.strictEqual(error.message, 'Invalid email format');
      assert.strictEqual(error.type, ErrorType.VALIDATION);
      assert.strictEqual(error.field, 'email');
    });

    it('should create error with all options', () => {
      const error = errorHandler.createError(
        ErrorType.AUTHENTICATION,
        'Unauthorized',
        {
          code: 'UNAUTHORIZED',
          status: 401,
          name: 'AuthenticationError',
          retryable: true,
        }
      );

      assert.strictEqual(error.message, 'Unauthorized');
      assert.strictEqual(error.type, ErrorType.AUTHENTICATION);
      assert.strictEqual(error.code, 'UNAUTHORIZED');
      assert.strictEqual(error.status, 401);
      assert.strictEqual(error.name, 'AuthenticationError');
      assert.strictEqual(error.retryable, true);
    });
  });

  describe('Validation', () => {
    it('should validate required fields', () => {
      const data = { name: 'Test', age: 25 };
      const fields = ['name', 'age', 'email'];

      assert.doesNotThrow(() => {
        errorHandler.validateRequired(data, fields);
      });
    });

    it('should throw error for missing fields', () => {
      const data = { name: 'Test' };
      const fields = ['name', 'email'];

      assert.throws(() => {
        errorHandler.validateRequired(data, fields);
      });
    });

    it('should return detailed error for missing fields', () => {
      const data = { name: 'Test' };
      const fields = ['name', 'email', 'phone'];

      try {
        errorHandler.validateRequired(data, fields);
        assert.fail('Should have thrown an error');
      } catch (error) {
        assert.ok(error.message.includes('missing fields'));
        assert.ok(error.missingFields);
        assert.ok(Array.isArray(error.missingFields));
      }
    });
  });

  describe('Request Validation', () => {
    it('should validate email field', () => {
      const req = { body: { email: 'test@example.com', age: 25 } };

      assert.doesNotThrow(() => {
        errorHandler.validateRequest(req, {
          email: { required: true, type: 'string', pattern: /^.+@.+\..+$/ },
        });
      });
    });

    it('should validate age field', () => {
      const req = { body: { name: 'Test', age: 25 } };

      assert.doesNotThrow(() => {
        errorHandler.validateRequest(req, {
          age: { required: true, type: 'number', min: 18, max: 120 },
        });
      });
    });

    it('should throw error for invalid type', () => {
      const req = { body: { email: 123, age: 'twenty' } };

      assert.throws(() => {
        errorHandler.validateRequest(req, {
          email: { required: true, type: 'string' },
          age: { required: true, type: 'number' },
        });
      });
    });

    it('should throw error for invalid pattern', () => {
      const req = { body: { email: 'invalid-email' } };

      assert.throws(() => {
        errorHandler.validateRequest(req, {
          email: { required: true, type: 'string', pattern: /^.+@.+\..+$/ },
        });
      });
    });

    it('should throw error for out of range values', () => {
      const req = { body: { age: 10 } };

      assert.throws(() => {
        errorHandler.validateRequest(req, {
          age: { required: true, type: 'number', min: 18, max: 120 },
        });
      });
    });

    it('should throw error for enum violation', () => {
      const req = { body: { status: 'pending' } };

      assert.throws(() => {
        errorHandler.validateRequest(req, {
          status: { required: true, type: 'string', enum: ['active', 'inactive', 'pending'] },
        });
      });
    });
  });

  describe('Error Response', () => {
    it('should format error response for JSON format', () => {
      const error = errorHandler.createError(
        ErrorType.VALIDATION,
        'Invalid input',
        { errors: ['field1', 'field2'] }
      );

      const response = errorHandler.sendErrorResponse({}, error, 400);

      assert.ok(response);
      assert.ok(response.error);
      assert.strictEqual(response.error.type, ErrorType.VALIDATION);
      assert.strictEqual(response.error.message, 'Invalid input');
      assert.strictEqual(response.error.timestamp);
      assert.ok(response.error.errors);
    });

    it('should include stack in development', () => {
      const originalEnv = process.env.NODE_ENV;
      process.env.NODE_ENV = 'development';

      const error = errorHandler.createError(
        ErrorType.VALIDATION,
        'Invalid input'
      );

      const response = errorHandler.sendErrorResponse({}, error, 400);

      assert.ok(response.error.stack);

      process.env.NODE_ENV = originalEnv;
    });

    it('should not include stack in production', () => {
      const originalEnv = process.env.NODE_ENV;
      process.env.NODE_ENV = 'production';

      const error = errorHandler.createError(
        ErrorType.VALIDATION,
        'Invalid input'
      );

      const response = errorHandler.sendErrorResponse({}, error, 400);

      assert.ok(response.error);
      assert.ok(!response.error.stack);

      process.env.NODE_ENV = originalEnv;
    });
  });

  describe('Async Handler', () => {
    it('should catch async errors', async () => {
      const handler = errorHandler.catchAsync(async () => {
        throw new Error('Test error');
      });

      try {
        await handler({}, {}, () => {});
        assert.fail('Should have thrown an error');
      } catch (error) {
        assert.strictEqual(error.message, 'Test error');
      }
    });

    it('should not catch synchronous errors', async () => {
      const handler = errorHandler.catchAsync(async () => {
        throw new Error('Test error');
      });

      try {
        await handler({}, {}, () => {});
        assert.fail('Should have thrown an error');
      } catch (error) {
        assert.strictEqual(error.message, 'Test error');
      }
    });
  });
});
