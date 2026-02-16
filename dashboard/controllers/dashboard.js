/**
 * Dashboard Controller
 * 处理Dashboard相关业务逻辑
 */

const chartService = require('../services/chart');
const dataFetcher = require('../services/data-fetcher');

/**
 * 获取所有数据
 */
async function getAllData() {
  const [
    costData,
    modelData,
    fallbackData,
    latencyData
  ] = await Promise.all([
    chartService.getCostData(),
    chartService.getModelData(),
    chartService.getFallbackData(),
    chartService.getLatencyData()
  ]);

  return {
    cost: costData,
    model: modelData,
    fallback: fallbackData,
    latency: latencyData
  };
}

/**
 * 按类型获取数据
 */
async function getDataByType(dataType) {
  const data = await chartService[`${dataType}Data`]();

  if (!data) {
    throw new Error(`Data type '${dataType}' not found`);
  }

  return data;
}

/**
 * 获取实时数据
 */
async function getRealtimeData(dataType) {
  const realTimeData = await dataFetcher.getRealtimeData(dataType);

  if (!realTimeData) {
    throw new Error(`Realtime data for '${dataType}' not available`);
  }

  return realTimeData;
}

module.exports = {
  getAllData,
  getDataByType,
  getRealtimeData
};
