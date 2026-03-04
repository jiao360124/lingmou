// data-source-adapter.js - 数据源适配器
// 统一数据源接口

const fs = require('fs').promises;
const path = require('path');

class DataSourceAdapter {
  constructor(config = {}) {
    this.config = config;
    this.sources = [];
    this.loadSources();
  }

  // 加载配置的数据源
  loadSources() {
    if (this.config.sources) {
      this.sources = this.config.sources.map(source => ({
        name: source.name,
        type: source.type,
        enabled: source.enabled !== false,
        config: source.config || {}
      }));
    }
  }

  // 获取所有数据源
  getSources() {
    return this.sources;
  }

  // 启用/禁用数据源
  toggleSource(name, enabled) {
    const source = this.sources.find(s => s.name === name);
    if (source) {
      source.enabled = enabled;
      return true;
    }
    return false;
  }

  // 添加数据源
  addSource(name, type, config = {}) {
    this.sources.push({
      name,
      type,
      enabled: true,
      config
    });
  }

  // 删除数据源
  removeSource(name) {
    this.sources = this.sources.filter(s => s.name !== name);
  }

  // 获取启用的数据源
  getEnabledSources() {
    return this.sources.filter(s => s.enabled);
  }

  // 导出配置
  exportConfig() {
    return {
      sources: this.sources.map(s => ({
        name: s.name,
        type: s.type,
        enabled: s.enabled,
        config: s.config
      }))
    };
  }

  // 导入配置
  async importConfig(config) {
    this.sources = config.sources || [];
    return true;
  }
}

// 默认数据源配置
const defaultConfig = {
  sources: [
    {
      name: 'local-file',
      type: 'local-file',
      enabled: true,
      config: {
        directory: 'data',
        file: 'metrics.json'
      }
    },
    {
      name: 'api-endpoint',
      type: 'api-endpoint',
      enabled: false,
      config: {
        url: 'https://api.example.com/metrics',
        method: 'GET',
        interval: 60000
      }
    },
    {
      name: 'database',
      type: 'database',
      enabled: false,
      config: {
        type: 'sqlite',
        database: 'openclaw.db'
      }
    }
  ]
};

module.exports = {
  DataSourceAdapter,
  defaultConfig
};
