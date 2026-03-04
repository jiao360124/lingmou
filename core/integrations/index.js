/**
 * 灵眸 v3.2.6 整合管理器
 *
 * 提供核心整合功能的管理接口
 */

const fs = require('fs');
const path = require('path');

class IntegrationManager {
  constructor() {
    this.integrations = new Map();
    this.loadIntegrations();
  }

  /**
   * 加载所有整合配置
   */
  loadIntegrations() {
    const integrationDirs = [
      path.join(__dirname, 'monitoring'),
      path.join(__dirname, 'strategy')
    ];

    integrationDirs.forEach(dir => {
      if (fs.existsSync(dir)) {
        const files = fs.readdirSync(dir);
        files.forEach(file => {
          if (file.endsWith('.js') && file !== 'index.js') {
            const integrationName = path.basename(file, '.js');
            this.integrations.set(integrationName, {
              path: path.join(dir, file),
              loaded: false
            });
          }
        });
      }
    });
  }

  /**
   * 加载指定整合
   */
  loadIntegration(name) {
    if (!this.integrations.has(name)) {
      throw new Error(`Integration "${name}" not found`);
    }

    const integration = this.integrations.get(name);
    if (integration.loaded) {
      return integration;
    }

    try {
      const module = require(integration.path);
      integration.loaded = true;
      integration.module = module;
      return module;
    } catch (error) {
      throw new Error(`Failed to load integration "${name}": ${error.message}`);
    }
  }

  /**
   * 执行整合功能
   */
  async execute(name, action, params = {}) {
    try {
      const integration = this.loadIntegration(name);

      if (typeof integration[action] !== 'function') {
        throw new Error(`Action "${action}" not found in integration "${name}"`);
      }

      return await integration[action](params);
    } catch (error) {
      throw new Error(`Execution failed: ${error.message}`);
    }
  }

  /**
   * 获取所有可用整合
   */
  getAvailableIntegrations() {
    return Array.from(this.integrations.keys());
  }

  /**
   * 获取整合状态
   */
  getStatus(name) {
    if (!this.integrations.has(name)) {
      return null;
    }

    return {
      name,
      loaded: this.integrations.get(name).loaded
    };
  }
}

// 导出单例
module.exports = new IntegrationManager();
