/**
 * 缓存系统单元测试
 */

const assert = require('assert');
const { CacheManager } = require('../../utils/cache');

describe('CacheManager', () => {
  let cache;

  beforeEach(() => {
    cache = new CacheManager({
      enabled: true,
      ttl: 60,
      maxKeys: 100,
    });
  });

  afterEach(() => {
    if (cache) {
      cache.flush();
    }
  });

  describe('Initialization', () => {
    it('should initialize with default config', () => {
      assert.ok(cache);
      assert.strictEqual(cache.enabled, true);
      assert.ok(cache.cache);
    });

    it('should support custom TTL', () => {
      const customCache = new CacheManager({
        enabled: true,
        ttl: 300,
      });

      assert.strictEqual(customCache.defaultTTL, 300);
    });

    it('should support custom maxKeys', () => {
      const customCache = new CacheManager({
        enabled: true,
        maxKeys: 1000,
      });

      assert.strictEqual(customCache.cache.maxKeys, 1000);
    });
  });

  describe('set', () => {
    it('should set cache value', () => {
      const result = cache.set('key', 'value', 60);
      assert.strictEqual(result, true);
    });

    it('should use default TTL when not specified', () => {
      cache.set('key', 'value');

      assert.strictEqual(cache.get('key'), 'value');
    });

    it('should override existing value', () => {
      cache.set('key', 'value1', 60);
      cache.set('key', 'value2', 60);

      assert.strictEqual(cache.get('key'), 'value2');
    });

    it('should handle empty values', () => {
      const result = cache.set('empty', '', 60);
      assert.strictEqual(result, true);

      assert.strictEqual(cache.get('empty'), '');
    });

    it('should handle null values', () => {
      const result = cache.set('null', null, 60);
      assert.strictEqual(result, true);

      assert.strictEqual(cache.get('null'), null);
    });

    it('should handle undefined values', () => {
      const result = cache.set('undefined', undefined, 60);
      assert.strictEqual(result, true);

      assert.strictEqual(cache.get('undefined'), undefined);
    });

    it('should handle complex objects', () => {
      const obj = { name: 'test', value: 123 };
      cache.set('complex', obj, 60);

      const retrieved = cache.get('complex');
      assert.deepStrictEqual(retrieved, obj);
    });

    it('should handle arrays', () => {
      const arr = [1, 2, 3];
      cache.set('array', arr, 60);

      const retrieved = cache.get('array');
      assert.deepStrictEqual(retrieved, arr);
    });

    it('should handle nested objects', () => {
      const nested = { level1: { level2: { value: 'deep' } } };
      cache.set('nested', nested, 60);

      const retrieved = cache.get('nested');
      assert.deepStrictEqual(retrieved, nested);
    });
  });

  describe('get', () => {
    it('should get cached value', () => {
      cache.set('key', 'value', 60);
      const result = cache.get('key');

      assert.strictEqual(result, 'value');
    });

    it('should return undefined for missing key', () => {
      const result = cache.get('nonexistent');
      assert.strictEqual(result, undefined);
    });

    it('should return null for empty key', () => {
      cache.set('', 'value', 60);
      const result = cache.get('');

      assert.strictEqual(result, 'value');
    });

    it('should return undefined immediately after flush', () => {
      cache.set('key', 'value', 60);
      cache.flush();
      const result = cache.get('key');

      assert.strictEqual(result, undefined);
    });

    it('should return undefined after TTL expires', async () => {
      cache.set('temp', 'value', 1); // 1 second TTL
      await new Promise(resolve => setTimeout(resolve, 1000)); // Wait for TTL
      const result = cache.get('temp');

      assert.strictEqual(result, undefined);
    });
  });

  describe('del', () => {
    it('should delete single key', () => {
      cache.set('key', 'value', 60);
      const result = cache.del('key');

      assert.strictEqual(result, true);
      assert.strictEqual(cache.get('key'), undefined);
    });

    it('should return false for non-existent key', () => {
      const result = cache.del('nonexistent');
      assert.strictEqual(result, false);
    });

    it('should handle empty key', () => {
      cache.set('', 'value', 60);
      const result = cache.del('');

      assert.strictEqual(result, true);
      assert.strictEqual(cache.get(''), undefined);
    });

    it('should delete multiple keys', () => {
      cache.set('key1', 'value1', 60);
      cache.set('key2', 'value2', 60);
      cache.set('key3', 'value3', 60);

      const result = cache.del('key1', 'key2');

      assert.strictEqual(result, true);
      assert.strictEqual(cache.get('key1'), undefined);
      assert.strictEqual(cache.get('key2'), undefined);
      assert.strictEqual(cache.get('key3'), 'value3');
    });
  });

  describe('delPattern', () => {
    it('should delete keys matching pattern', () => {
      cache.set('user:1', 'value1', 60);
      cache.set('user:2', 'value2', 60);
      cache.set('post:1', 'value3', 60);
      cache.set('post:2', 'value4', 60);
      cache.set('other:1', 'value5', 60);

      const deleted = cache.delPattern('user:*');

      assert.strictEqual(deleted, 2);
      assert.strictEqual(cache.get('user:1'), undefined);
      assert.strictEqual(cache.get('user:2'), undefined);
      assert.strictEqual(cache.get('post:1'), 'value3');
      assert.strictEqual(cache.get('post:2'), 'value4');
      assert.strictEqual(cache.get('other:1'), 'value5');
    });

    it('should handle no matches', () => {
      cache.set('user:1', 'value1', 60);
      cache.set('user:2', 'value2', 60);

      const deleted = cache.delPattern('post:*');

      assert.strictEqual(deleted, 0);
      assert.strictEqual(cache.get('user:1'), 'value1');
      assert.strictEqual(cache.get('user:2'), 'value2');
    });

    it('should handle empty pattern', () => {
      cache.set('key1', 'value1', 60);
      cache.set('key2', 'value2', 60);

      const deleted = cache.delPattern('');

      assert.strictEqual(deleted, 0);
    });
  });

  describe('flush', () => {
    it('should clear all cache', () => {
      cache.set('key1', 'value1', 60);
      cache.set('key2', 'value2', 60);
      cache.set('key3', 'value3', 60);

      cache.flush();

      assert.strictEqual(cache.get('key1'), undefined);
      assert.strictEqual(cache.get('key2'), undefined);
      assert.strictEqual(cache.get('key3'), undefined);
    });

    it('should return 0 after flush', () => {
      cache.set('key1', 'value1', 60);
      cache.set('key2', 'value2', 60);

      const result = cache.flush();

      assert.strictEqual(result, 0);
    });
  });

  describe('getStats', () => {
    it('should return cache statistics', () => {
      cache.set('key1', 'value1', 60);
      cache.set('key2', 'value2', 60);
      cache.set('key3', 'value3', 60);

      const stats = cache.getStats();

      assert.ok(stats);
      assert.ok(stats.keys);
      assert.strictEqual(stats.keys, 3);
      assert.ok(stats.hits);
      assert.strictEqual(stats.hits, 0);
      assert.ok(stats.misses);
      assert.strictEqual(stats.misses, 0);
    });

    it('should return 0 for empty cache', () => {
      const stats = cache.getStats();

      assert.strictEqual(stats.keys, 0);
      assert.strictEqual(stats.hits, 0);
      assert.strictEqual(stats.misses, 0);
    });
  });

  describe('keys', () => {
    it('should return all keys', () => {
      cache.set('key1', 'value1', 60);
      cache.set('key2', 'value2', 60);
      cache.set('key3', 'value3', 60);

      const keys = cache.keys();

      assert.ok(Array.isArray(keys));
      assert.strictEqual(keys.length, 3);
      assert.ok(keys.includes('key1'));
      assert.ok(keys.includes('key2'));
      assert.ok(keys.includes('key3'));
    });

    it('should return empty array for empty cache', () => {
      const keys = cache.keys();

      assert.ok(Array.isArray(keys));
      assert.strictEqual(keys.length, 0);
    });
  });

  describe('has', () => {
    it('should return true for existing key', () => {
      cache.set('key', 'value', 60);

      const result = cache.has('key');

      assert.strictEqual(result, true);
    });

    it('should return false for non-existent key', () => {
      const result = cache.has('nonexistent');

      assert.strictEqual(result, false);
    });
  });

  describe('middleware', () => {
    it('should cache responses', async () => {
      let callCount = 0;

      const fn = async (req, res, next) => {
        callCount++;
        res.json({ data: 'response', key: req.originalUrl });
      };

      const middleware = cache.middleware(60);

      // First call - cache miss
      const response1 = await fn({}, {}, () => {});
      middleware({}, { json: response1.json.bind(response1) }, () => {});
      const cached1 = cache.get(response1.key);

      assert.ok(cached1);
      assert.strictEqual(callCount, 1);

      // Second call - should hit cache
      callCount = 0;
      const response2 = await fn({}, { json: cached1 }, () => {});
      const cached2 = cache.get(response2.key);

      assert.ok(cached2);
      assert.strictEqual(callCount, 0);
    });

    it('should handle middleware with different TTL', async () => {
      const fn = async (req, res, next) => {
        res.json({ data: 'response', key: req.originalUrl });
      };

      // Middleware with 60s TTL
      const middleware1 = cache.middleware(60);
      const response1 = await fn({}, {}, () => {});
      middleware1({}, { json: response1.json.bind(response1) }, () => {});
      const cached1 = cache.get(response1.key);

      // Middleware with 120s TTL
      const middleware2 = cache.middleware(120);
      const response2 = await fn({}, {}, () => {});
      middleware2({}, { json: response2.json.bind(response2) }, () => {});
      const cached2 = cache.get(response2.key);

      assert.ok(cached1);
      assert.ok(cached2);
    });
  });

  describe('getCacheKey', () => {
    it('should generate cache key from request', () => {
      const req = {
        method: 'GET',
        path: '/api/data',
        query: { page: 1, limit: 10 },
      };

      const key = cache.getCacheKey(req);
      assert.ok(key);
      assert.ok(key.startsWith('GET:'));
    });

    it('should handle request without query', () => {
      const req = {
        method: 'POST',
        path: '/api/create',
      };

      const key = cache.getCacheKey(req);
      assert.ok(key);
      assert.ok(key.startsWith('POST:'));
    });

    it('should include query in key', () => {
      const req1 = {
        method: 'GET',
        path: '/api/data',
        query: { page: 1, limit: 10 },
      };

      const req2 = {
        method: 'GET',
        path: '/api/data',
        query: { page: 2, limit: 10 },
      };

      const key1 = cache.getCacheKey(req1);
      const key2 = cache.getCacheKey(req2);

      assert.notStrictEqual(key1, key2);
    });
  });

  describe('getDataKey', () => {
    it('should generate data cache key', () => {
      const key1 = cache.getDataKey('users');
      const key2 = cache.getDataKey('users', 123);
      const key3 = cache.getDataKey('users', 'all');

      assert.ok(key1);
      assert.ok(key2);
      assert.ok(key3);
    });

    it('should include prefix and id', () => {
      const key = cache.getDataKey('users', 123);
      assert.ok(key.startsWith('users:'));
      assert.ok(key.includes('123'));
    });

    it('should use "all" when no id provided', () => {
      const key = cache.getDataKey('users');
      assert.ok(key.includes('all'));
    });
  });

  describe('disabled cache', () => {
    it('should not set values when disabled', () => {
      const disabledCache = new CacheManager({ enabled: false });

      const result = disabledCache.set('key', 'value', 60);

      assert.strictEqual(result, null);
      assert.strictEqual(disabledCache.get('key'), undefined);
    });

    it('should not get values when disabled', () => {
      const disabledCache = new CacheManager({ enabled: false });

      const result = disabledCache.get('key');

      assert.strictEqual(result, undefined);
    });
  });

  describe('memory limit', () => {
    it('should respect maxKeys limit', () => {
      const limitCache = new CacheManager({ maxKeys: 10 });

      for (let i = 0; i < 20; i++) {
        limitCache.set(`key${i}`, `value${i}`, 60);
      }

      const keys = limitCache.keys();
      assert.strictEqual(keys.length, 10);
    });

    it('should handle key rotation', () => {
      const limitCache = new CacheManager({ maxKeys: 3 });

      for (let i = 0; i < 10; i++) {
        limitCache.set(`key${i}`, `value${i}`, 60);
      }

      const keys = limitCache.keys();
      assert.strictEqual(keys.length, 3);
      assert.ok(!keys.includes('key0'));
      assert.ok(keys.includes('key7'));
    });
  });
});
