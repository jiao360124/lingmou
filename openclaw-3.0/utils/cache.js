/**
 * 统一缓存系统
 * 基于 node-cache 实现，支持 TTL、内存限制
 */

const NodeCache = require('node-cache');
const logger = require('./logger');

class CacheManager {
  constructor(options = {}) {
    this.cache = new NodeCache({
      stdTTL: options.ttl || 300,
      checkperiod: options.checkperiod || 600,
      useClones: options.useClones || false,
      deleteOnExpire: options.deleteOnExpire !== false,
      maxKeys: options.maxKeys || 1000,
    });

    this.enabled = options.enabled !== false;
    this.defaultTTL = options.ttl || 300;

    logger.info('CacheManager initialized', {
      enabled: this.enabled,
      ttl: `${this.defaultTTL}s`,
      maxKeys: this.cache.maxKeys,
    });
  }

  /**
   * 设置缓存
   */
  set(key, value, ttl = null) {
    if (!this.enabled) return null;

    const actualTTL = ttl || this.defaultTTL;
    const result = this.cache.set(key, value, actualTTL);

    if (result) {
      logger.debug('Cache set', { key, ttl: `${actualTTL}s` });
    }

    return result;
  }

  /**
   * 获取缓存
   */
  get(key) {
    if (!this.enabled) return null;

    const value = this.cache.get(key);

    if (value !== undefined) {
      logger.debug('Cache hit', { key });
    } else {
      logger.debug('Cache miss', { key });
    }

    return value;
  }

  /**
   * 删除缓存
   */
  del(key) {
    if (!this.enabled) return false;

    const result = this.cache.del(key);

    if (result) {
      logger.debug('Cache deleted', { key });
    }

    return result;
  }

  /**
   * 批量删除缓存
   */
  delPattern(pattern) {
    if (!this.enabled) return 0;

    const keys = this.cache.keys();
    const patternRegex = new RegExp(pattern);
    const matchingKeys = keys.filter(key => patternRegex.test(key));

    const deleted = this.cache.del(...matchingKeys);

    logger.debug('Cache deleted pattern', {
      pattern,
      deleted,
    });

    return deleted;
  }

  /**
   * 清空缓存
   */
  flush() {
    if (!this.enabled) return 0;

    const result = this.cache.flushAll();

    logger.info('Cache flushed');

    return result;
  }

  /**
   * 获取缓存统计
   */
  getStats() {
    return this.cache.getStats();
  }

  /**
   * 获取缓存中的所有 key
   */
  keys() {
    return this.cache.keys();
  }

  /**
   * 检查 key 是否存在
   */
  has(key) {
    return this.cache.has(key);
  }

  /**
   * 缓存中间件
   */
  middleware(ttl) {
    return (req, res, next) => {
      const key = this.getCacheKey(req);
      const cachedData = this.get(key);

      if (cachedData) {
        logger.debug('Cache hit in middleware', { key });
        return res.json(cachedData);
      }

      logger.debug('Cache miss in middleware', { key });

      // 保存原始 json 函数
      const originalJson = res.json.bind(res);

      res.json = (data) => {
        this.set(key, data, ttl);
        return originalJson(data);
      };

      next();
    };
  }

  /**
   * 生成缓存 key
   */
  getCacheKey(req) {
    const query = req.query ? JSON.stringify(req.query) : '';
    return `${req.method}:${req.path}:${query}`;
  }

  /**
   * 生成数据缓存 key
   */
  getDataKey(prefix, id = null) {
    return `${prefix}:${id || 'all'}`;
  }
}

// 创建全局缓存实例
const cache = new CacheManager({
  enabled: true,
  ttl: 300,
  maxKeys: 1000,
});

module.exports = cache;
module.exports.CacheManager = CacheManager;
