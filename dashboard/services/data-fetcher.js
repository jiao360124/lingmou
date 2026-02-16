/**
 * Data Fetcher Service
 * 获取Dashboard所需数据
 */

const dataCache = new Map();
const CACHE_DURATION = 60 * 1000; // 60秒

/**
 * 获取实时数据
 */
async function getRealtimeData(dataType) {
  const cacheKey = `realtime:${dataType}`;

  // 检查缓存
  if (dataCache.has(cacheKey)) {
    const cached = dataCache.get(cacheKey);
    if (Date.now() - cached.timestamp < CACHE_DURATION) {
      return cached.data;
    }
  }

  // 模拟获取实时数据
  const data = generateRealtimeData(dataType);

  // 缓存数据
  dataCache.set(cacheKey, {
    data,
    timestamp: Date.now()
  });

  return data;
}

/**
 * 生成实时数据
 */
function generateRealtimeData(dataType) {
  const now = Date.now();
  const randomFactor = Math.random() * 20 - 10;

  switch (dataType) {
    case 'cost':
      return {
        labels: ['00:00', '04:00', '08:00', '12:00', '16:00', '20:00', '24:00'],
        values: [10 + randomFactor, 8 + randomFactor, 12 + randomFactor, 15 + randomFactor, 14 + randomFactor, 11 + randomFactor, 9 + randomFactor],
        current: 13 + randomFactor,
        unit: 'Tokens'
      };

    case 'model':
      return {
        labels: ['glm-4.7-flash', 'gpt-4', 'claude-3', 'gemini-pro'],
        values: [45 + randomFactor, 30 + randomFactor, 15 + randomFactor, 10 + randomFactor],
        current: 35 + randomFactor,
        unit: 'Count'
      };

    case 'fallback':
      return {
        labels: ['00:00', '04:00', '08:00', '12:00', '16:00', '20:00', '24:00'],
        values: [2 + randomFactor, 1 + randomFactor, 3 + randomFactor, 5 + randomFactor, 4 + randomFactor, 2 + randomFactor, 1 + randomFactor],
        current: 3 + randomFactor,
        unit: 'Count'
      };

    case 'latency':
      return {
        labels: ['00:00', '04:00', '08:00', '12:00', '16:00', '20:00', '24:00'],
        values: [50 + randomFactor, 45 + randomFactor, 55 + randomFactor, 60 + randomFactor, 58 + randomFactor, 52 + randomFactor, 48 + randomFactor],
        current: 54 + randomFactor,
        unit: 'ms'
      };

    default:
      return null;
  }
}

/**
 * 获取所有图表数据
 */
async function getAllData() {
  return Promise.all([
    getCostData(),
    getModelData(),
    getFallbackData(),
    getLatencyData()
  ]);
}

/**
 * 获取成本数据
 */
async function getCostData() {
  return {
    labels: ['周一', '周二', '周三', '周四', '周五', '周六', '周日'],
    values: [10, 12, 11, 15, 14, 8, 9],
    current: 11,
    unit: 'Tokens'
  };
}

/**
 * 获取模型数据
 */
async function getModelData() {
  return {
    labels: ['glm-4.7-flash', 'gpt-4', 'claude-3', 'gemini-pro'],
    values: [45, 30, 15, 10],
    current: 35,
    unit: 'Count'
  };
}

/**
 * 获取Fallback数据
 */
async function getFallbackData() {
  return {
    labels: ['周一', '周二', '周三', '周四', '周五', '周六', '周日'],
    values: [2, 3, 2, 5, 4, 1, 2],
    current: 3,
    unit: 'Count'
  };
}

/**
 * 获取延迟数据
 */
async function getLatencyData() {
  return {
    labels: ['周一', '周二', '周三', '周四', '周五', '周六', '周日'],
    values: [50, 55, 45, 60, 58, 52, 48],
    current: 54,
    unit: 'ms'
  };
}

/**
 * 清除数据缓存
 */
function clearCache(dataType = null) {
  if (dataType) {
    dataCache.delete(`realtime:${dataType}`);
  } else {
    dataCache.clear();
  }
}

/**
 * 获取缓存统计
 */
function getCacheStats() {
  return {
    size: dataCache.size()
  };
}

module.exports = {
  getRealtimeData,
  getAllData,
  getCostData,
  getModelData,
  getFallbackData,
  getLatencyData,
  clearCache,
  getCacheStats
};
