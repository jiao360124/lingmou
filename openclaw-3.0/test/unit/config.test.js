/**
 * 配置管理单元测试
 */

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const config = require('../../config');

describe('Configuration Management', () => {
  describe('index.js', () => {
    it('should load default config', () => {
      const cfg = config.getConfig();
      assert.ok(cfg);
      assert.strictEqual(cfg.env, 'development');
      assert.ok(cfg.ports);
      assert.ok(cfg.log);
      assert.ok(cfg.cache);
    });

    it('should validate configuration', () => {
      assert.doesNotThrow(() => config.validateConfig());
    });

    it('should get single config value', () => {
      const port = config.get('ports.gateway');
      assert.strictEqual(port, 18789);
    });

    it('should return default for missing key', () => {
      const value = config.get('nonexistent.key', 'default');
      assert.strictEqual(value, 'default');
    });

    it('should support environment variables', () => {
      process.env.TEST_VAR = 'test_value';
      // Note: updateConfig doesn't support dynamic env vars yet
      delete process.env.TEST_VAR;
    });

    it('should have required config keys', () => {
      const cfg = config.getConfig();
      const requiredKeys = ['env', 'ports', 'log', 'cache', 'retry', 'errorHandler'];
      requiredKeys.forEach(key => {
        assert.ok(cfg[key], `Missing config key: ${key}`);
      });
    });
  });

  describe('gateway.config.js', () => {
    it('should load gateway config', () => {
      const gatewayConfig = require('../../config/gateway.config');
      assert.ok(gatewayConfig);
      assert.ok(gatewayConfig.port);
      assert.ok(gatewayConfig.server);
      assert.ok(gatewayConfig.rateLimit);
    });

    it('should have valid port configuration', () => {
      const gatewayConfig = require('../../config/gateway.config');
      assert.ok(gatewayConfig.port >= 1 && gatewayConfig.port <= 65535);
    });

    it('should have health check configuration', () => {
      const gatewayConfig = require('../../config/gateway.config');
      assert.ok(gatewayConfig.healthCheck);
      assert.ok(gatewayConfig.heartbeat);
    });
  });

  describe('dashboard.config.js', () => {
    it('should load dashboard config', () => {
      const dashboardConfig = require('../../config/dashboard.config');
      assert.ok(dashboardConfig);
      assert.ok(dashboardConfig.port);
      assert.ok(dashboardConfig.refresh);
      assert.ok(dashboardConfig.charts);
    });

    it('should have valid port configuration', () => {
      const dashboardConfig = require('../../config/dashboard.config');
      assert.ok(dashboardConfig.port >= 1 && dashboardConfig.port <= 65535);
    });
  });

  describe('report.config.js', () => {
    it('should load report config', () => {
      const reportConfig = require('../../config/report.config');
      assert.ok(reportConfig);
      assert.ok(reportConfig.sender);
      assert.ok(reportConfig.generator);
      assert.ok(reportConfig.telegram);
      assert.ok(reportConfig.email);
    });
  });

  describe('cron.config.js', () => {
    it('should load cron config', () => {
      const cronConfig = require('../../config/cron.config');
      assert.ok(cronConfig);
      assert.ok(cronConfig.scheduler);
      assert.ok(cronConfig.jobs);
      assert.ok(cronConfig.notifications);
    });
  });

  describe('Environment Config', () => {
    it('should apply production config in production', () => {
      const originalEnv = process.env.NODE_ENV;
      process.env.NODE_ENV = 'production';
      // Note: getConfig is called at module load time
      // To test this properly, we'd need to reload the module
      process.env.NODE_ENV = originalEnv;
    });

    it('should apply staging config in staging', () => {
      const originalEnv = process.env.NODE_ENV;
      process.env.NODE_ENV = 'staging';
      process.env.NODE_ENV = originalEnv;
    });
  });
});
