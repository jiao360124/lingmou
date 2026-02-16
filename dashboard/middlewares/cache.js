/**
 * Cache Middleware
 * 实现请求缓存机制
 */

const cache = require('memory-cache');

/**
 * 创建缓存中间件
 * @param {number} duration - 缓存持续时间（毫秒）
 * @returns {Function} Express中间件
 */
function cacheMiddleware(duration = 5 * 60 * 1000) {
  return (req, res, next) => {
    const key = `${req.method}:${req.originalUrl}`;
    const cached = cache.get(key);

    if (cached) {
      console.log(`[Cache] Serving from cache: ${key}`);
      return res.json({
        success: true,
        data: cached.data,
        cached: true,
        timestamp: cached.timestamp
      });
    }

    // 保存原始res.json方法
    const originalJson = res.json.bind(res);

    // 覆盖res.json方法
    res.json = (data) => {
      cache.put(key, {
        data,
        timestamp: Date.now()
      }, duration);

      console.log(`[Cache] Cached: ${key} (${duration}ms)`);
      return originalJson(data);
    };

    next();
  };
}

/**
 * 清除指定缓存
 * @param {string} key - 缓存键（可选，不提供则清除所有）
 */
function clearCache(key = null) {
  if (key) {
    cache.del(key);
    console.log(`[Cache] Cleared: ${key}`);
  } else {
    cache.clear();
    console.log('[Cache] Cleared all');
  }
}

/**
 * 获取缓存统计
 * @returns {Object} 缓存统计信息
 */
function getCacheStats() {
  return {
    size: cache.size(),
    keys: Array.from(cache.keys())
  };
}

module.exports = {
  cacheMiddleware,
  clearCache,
  getCacheStats
};
