/**
 * 重试机制单元测试
 */

const assert = require('assert');
const { RetryManager, RetryStrategy } = require('../../utils/retry');

describe('RetryManager', () => {
  let retryManager;

  beforeEach(() => {
    retryManager = new RetryManager();
  });

  afterEach(() => {
    // Clear all strategies
    retryManager.strategies.clear();
  });

  describe('getStrategy', () => {
    it('should create new strategy on first call', () => {
      const strategy = retryManager.getStrategy('test', {
        maxRetries: 3,
        baseDelay: 100,
      });

      assert.ok(strategy);
      assert.strictEqual(retryManager.strategies.size, 1);
      assert.strictEqual(strategy.maxRetries, 3);
    });

    it('should return existing strategy', () => {
      const strategy1 = retryManager.getStrategy('test', { maxRetries: 3 });
      const strategy2 = retryManager.getStrategy('test', { maxRetries: 5 });

      assert.strictEqual(strategy1, strategy2);
      assert.strictEqual(strategy1.maxRetries, 3);
    });

    it('should merge options correctly', () => {
      const strategy = retryManager.getStrategy('test', {
        maxRetries: 3,
        baseDelay: 100,
        backoff: true,
      });

      assert.strictEqual(strategy.maxRetries, 3);
      assert.strictEqual(strategy.baseDelay, 100);
      assert.strictEqual(strategy.backoff, true);
    });
  });

  describe('execute', () => {
    it('should execute successfully on first try', async () => {
      const result = await retryManager.execute('test', async () => {
        return 'success';
      });

      assert.strictEqual(result, 'success');
    });

    it('should retry on failure', async () => {
      let attemptCount = 0;
      const result = await retryManager.execute('test', async () => {
        attemptCount++;
        if (attemptCount < 3) {
          throw new Error('Temporary failure');
        }
        return 'success';
      });

      assert.strictEqual(result, 'success');
      assert.strictEqual(attemptCount, 3);
    });

    it('should stop after max retries', async () => {
      let attemptCount = 0;
      const result = await retryManager.execute('test', async () => {
        attemptCount++;
        throw new Error('Permanent failure');
      }, {
        maxRetries: 2,
      });

      assert.strictEqual(attemptCount, 3); // 1 initial + 2 retries
      assert.fail('Should have thrown an error');
    });

    it('should use default max retries if not specified', async () => {
      let attemptCount = 0;
      const result = await retryManager.execute('test', async () => {
        attemptCount++;
        throw new Error('Temporary failure');
      });

      assert.strictEqual(attemptCount, 4); // 1 initial + 3 retries (default)
      assert.fail('Should have thrown an error');
    });
  });

  describe('executeSync', () => {
    it('should execute synchronously on first try', () => {
      const result = retryManager.executeSync('test', () => {
        return 'success';
      });

      assert.strictEqual(result, 'success');
    });

    it('should retry on failure', () => {
      let attemptCount = 0;
      const result = retryManager.executeSync('test', () => {
        attemptCount++;
        if (attemptCount < 3) {
          throw new Error('Temporary failure');
        }
        return 'success';
      });

      assert.strictEqual(result, 'success');
      assert.strictEqual(attemptCount, 3);
    });

    it('should stop after max retries', () => {
      let attemptCount = 0;
      const result = retryManager.executeSync('test', () => {
        attemptCount++;
        throw new Error('Permanent failure');
      }, {
        maxRetries: 2,
      });

      assert.strictEqual(attemptCount, 3);
      assert.fail('Should have thrown an error');
    });
  });

  describe('shouldRetry', () => {
    it('should retry network errors', () => {
      const strategy = retryManager.getStrategy('test');
      const error = new Error('ECONNREFUSED');
      error.code = 'ECONNREFUSED';

      assert.strictEqual(strategy.shouldRetry(error), true);
    });

    it('should retry timeout errors', () => {
      const strategy = retryManager.getStrategy('test');
      const error = new Error('ETIMEDOUT');
      error.code = 'ETIMEDOUT';

      assert.strictEqual(strategy.shouldRetry(error), true);
    });

    it('should not retry non-retryable errors', () => {
      const strategy = retryManager.getStrategy('test');
      const error = new Error('Not Found');
      error.code = 404;

      assert.strictEqual(strategy.shouldRetry(error), false);
    });

    it('should not retry after max retries', async () => {
      let attemptCount = 0;
      const strategy = retryManager.getStrategy('test', {
        maxRetries: 2,
      });

      try {
        await strategy.execute(async () => {
          attemptCount++;
          throw new Error('Error');
        });
        assert.fail('Should have thrown an error');
      } catch (error) {
        // Expected
      }
    });
  });

  describe('custom shouldRetry', () => {
    it('should use custom shouldRetry function', async () => {
      const customShouldRetry = jest.fn((error) => {
        return error.message === 'Special Error';
      });

      const strategy = new RetryStrategy({
        maxRetries: 5,
        shouldRetry: customShouldRetry,
      });

      let attemptCount = 0;
      try {
        await strategy.execute(async () => {
          attemptCount++;
          if (attemptCount < 3) {
            throw new Error('Other Error');
          }
          throw new Error('Special Error');
        });
        assert.fail('Should have thrown an error');
      } catch (error) {
        // Expected
      }

      assert.strictEqual(customShouldRetry.mock.calls.length, 3);
    });

    it('should pass error to shouldRetry', async () => {
      const customShouldRetry = jest.fn((error) => {
        return error.message.includes('test');
      });

      const strategy = new RetryStrategy({
        maxRetries: 3,
        shouldRetry: customShouldRetry,
      });

      let attemptCount = 0;
      try {
        await strategy.execute(async () => {
          attemptCount++;
          throw new Error(`Test error ${attemptCount}`);
        });
        assert.fail('Should have thrown an error');
      } catch (error) {
        // Expected
      }

      // Should call shouldRetry for each retry attempt
      assert.strictEqual(customShouldRetry.mock.calls.length, 3);
    });
  });

  describe('onRetry callback', () => {
    it('should call onRetry callback', async () => {
      const onRetry = jest.fn();

      const strategy = new RetryStrategy({
        maxRetries: 3,
        baseDelay: 10,
        onRetry: onRetry,
      });

      let attemptCount = 0;
      try {
        await strategy.execute(async () => {
          attemptCount++;
          if (attemptCount < 3) {
            throw new Error('Error');
          }
          throw new Error('Success');
        });
        assert.fail('Should have thrown an error');
      } catch (error) {
        // Expected
      }

      assert.strictEqual(onRetry.mock.calls.length, 2); // 2 retries
    });

    it('should pass retry count to onRetry', async () => {
      const onRetry = jest.fn();

      const strategy = new RetryStrategy({
        maxRetries: 3,
        baseDelay: 10,
        onRetry: onRetry,
      });

      let attemptCount = 0;
      try {
        await strategy.execute(async () => {
          attemptCount++;
          if (attemptCount < 3) {
            throw new Error('Error');
          }
          throw new Error('Success');
        });
        assert.fail('Should have thrown an error');
      } catch (error) {
        // Expected
      }

      assert.strictEqual(onRetry.mock.calls.length, 2);
      assert.strictEqual(onRetry.mock.calls[0][0], 1); // First retry
      assert.strictEqual(onRetry.mock.calls[1][0], 2); // Second retry
    });
  });

  describe('backoff strategy', () => {
    it('should use exponential backoff by default', async () => {
      const delays = [];
      let attemptCount = 0;

      const strategy = new RetryStrategy({
        maxRetries: 2,
        baseDelay: 100,
        backoff: true,
        onRetry: (retryCount, delay) => {
          delays.push(delay);
        },
      });

      try {
        await strategy.execute(async () => {
          attemptCount++;
          throw new Error('Error');
        });
        assert.fail('Should have thrown an error');
      } catch (error) {
        // Expected
      }

      // Should have 2 retries with increasing delays
      assert.strictEqual(delays.length, 2);
      assert.ok(delays[0] >= 100); // First retry
      assert.ok(delays[1] >= 200); // Second retry (2x base delay)
    });

    it('should use fixed delay when backoff is disabled', async () => {
      const delays = [];
      let attemptCount = 0;

      const strategy = new RetryStrategy({
        maxRetries: 2,
        baseDelay: 100,
        backoff: false,
        onRetry: (retryCount, delay) => {
          delays.push(delay);
        },
      });

      try {
        await strategy.execute(async () => {
          attemptCount++;
          throw new Error('Error');
        });
        assert.fail('Should have thrown an error');
      } catch (error) {
        // Expected
      }

      // Should have 2 retries with the same delay
      assert.strictEqual(delays.length, 2);
      assert.strictEqual(delays[0], delays[1]);
    });

    it('should add jitter to delay', async () => {
      const strategy = new RetryStrategy({
        maxRetries: 2,
        baseDelay: 100,
        backoff: true,
        jitter: true,
      });

      let attemptCount = 0;
      try {
        await strategy.execute(async () => {
          attemptCount++;
          throw new Error('Error');
        });
        assert.fail('Should have thrown an error');
      } catch (error) {
        // Expected
      }
    });
  });

  describe('decorate', () => {
    it('should create a retry-decorated function', async () => {
      const fn = async () => {
        return 'success';
      };

      const decoratedFn = retryManager.decorate('test', fn, {
        maxRetries: 3,
      });

      const result = await decoratedFn();
      assert.strictEqual(result, 'success');
    });

    it('should retry decorated function', async () => {
      const fn = async () => {
        throw new Error('Error');
      };

      const decoratedFn = retryManager.decorate('test', fn, {
        maxRetries: 2,
      });

      let attemptCount = 0;
      try {
        await decoratedFn();
        assert.fail('Should have thrown an error');
      } catch (error) {
        assert.strictEqual(attemptCount, 3); // 1 initial + 2 retries
      }
    });
  });

  describe('concurrent executions', () => {
    it('should handle multiple concurrent executions', async () => {
      const results = await Promise.all([
        retryManager.execute('test1', async () => 'result1'),
        retryManager.execute('test2', async () => 'result2'),
        retryManager.execute('test3', async () => 'result3'),
      ]);

      assert.deepStrictEqual(results, ['result1', 'result2', 'result3']);
    });

    it('should handle concurrent retries', async () => {
      const results = await Promise.all([
        retryManager.execute('test', async () => {
          throw new Error('Error');
        }),
        retryManager.execute('test', async () => {
          throw new Error('Error');
        }),
        retryManager.execute('test', async () => {
          throw new Error('Error');
        }),
      ]);

      // All should have 3 attempts (1 initial + 2 retries)
      results.forEach(result => {
        assert.fail('Should have thrown an error');
      });
    });
  });
});
