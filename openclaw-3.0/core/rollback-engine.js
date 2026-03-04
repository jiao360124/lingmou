// openclaw-3.0/core/rollback-engine.js
// 差异回滚引擎 - 安全回滚保障

const fs = require('fs').promises;
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/rollback-engine.log' }),
    new winston.transports.Console({ format: winston.format.simple() })
  ]
});

class RollbackEngine {
  constructor() {
    this.currentConfig = null;
    this.loadCurrentConfig();
    logger.info('Rollback Engine 初始化完成');
  }

  /**
   * 加载当前配置
   */
  async loadCurrentConfig() {
    try {
      this.currentConfig = JSON.parse(await fs.readFile('config.json', 'utf8'));
      logger.info('当前配置已加载', {
        dailyBudget: this.currentConfig.dailyBudget,
        validationDays: this.currentConfig.validationDays
      });
    } catch (error) {
      logger.error('加载当前配置失败', error);
    }
  }

  /**
   * 对比配置差异
   * @param {Object} newConfig - 新配置
   * @returns {Object} 差异对象
   */
  compareConfigs(newConfig) {
    const diff = {
      added: {},
      removed: {},
      modified: {},
      unchanged: {}
    };

    const allKeys = new Set([
      ...Object.keys(this.currentConfig),
      ...Object.keys(newConfig)
    ]);

    for (const key of allKeys) {
      const currentValue = this.currentConfig[key];
      const newValue = newConfig[key];

      if (!Object.prototype.hasOwnProperty.call(newConfig, key)) {
        // 被移除
        diff.removed[key] = currentValue;
      } else if (!Object.prototype.hasOwnProperty.call(this.currentConfig, key)) {
        // 新增
        diff.added[key] = newValue;
      } else if (JSON.stringify(currentValue) !== JSON.stringify(newValue)) {
        // 修改
        diff.modified[key] = {
          old: currentValue,
          new: newValue
        };
      } else {
        // 未改变
        diff.unchanged[key] = newValue;
      }
    }

    return diff;
  }

  /**
   * 应用反向补丁
   * @param {Object} diff - 差异对象
   * @returns {Promise<Object>} 回滚结果
   */
  async applyReversePatch(diff) {
    logger.info('开始应用反向补丁...');

    const rollbackResults = {
      addedReverted: 0,
      removedRestored: 0,
      modifiedReverted: 0
    };

    try {
      // 恢复被移除的配置
      for (const key of Object.keys(diff.removed)) {
        this.currentConfig[key] = diff.removed[key];
        rollbackResults.removedRestored++;
        logger.info(`恢复配置: ${key} = ${diff.removed[key]}`);
      }

      // 回滚新增的配置
      for (const key of Object.keys(diff.added)) {
        delete this.currentConfig[key];
        rollbackResults.addedReverted++;
        logger.info(`删除配置: ${key}`);
      }

      // 回滚修改的配置
      for (const key of Object.keys(diff.modified)) {
        this.currentConfig[key] = diff.modified[key].old;
        rollbackResults.modifiedReverted++;
        logger.info(`回滚配置: ${key} = ${diff.modified[key].old}`);
      }

      // 保存新配置
      await fs.writeFile('config.json', JSON.stringify(this.currentConfig, null, 2));

      logger.info('✅ 反向补丁应用完成', rollbackResults);

      return {
        success: true,
        results: rollbackResults,
        finalConfig: this.currentConfig
      };

    } catch (error) {
      logger.error('❌ 应用反向补丁失败', error);
      return {
        success: false,
        error: error.message,
        rollbackResults
      };
    }
  }

  /**
   * 从快照回滚
   * @param {string} snapshotId - 快照ID
   * @returns {Promise<Object>} 回滚结果
   */
  async rollbackToSnapshot(snapshotId) {
    logger.info(`开始从快照回滚: ${snapshotId}`);

    try {
      // 加载快照
      const snapshotPath = `snapshots/${snapshotId}.json`;
      const snapshot = JSON.parse(await fs.readFile(snapshotPath, 'utf8'));

      logger.info('快照已加载', {
        snapshotId,
        snapshotState: snapshot.state,
        snapshotMode: snapshot.mode
      });

      // 加载当前配置
      await this.loadCurrentConfig();

      // 对比差异
      const diff = this.compareConfigs(snapshot);

      logger.info('配置差异已识别', {
        added: Object.keys(diff.added),
        removed: Object.keys(diff.removed),
        modified: Object.keys(diff.modified)
      });

      // 应用反向补丁
      const result = await this.applyReversePatch(diff);

      if (result.success) {
        logger.info(`✅ 成功从快照回滚: ${snapshotId}`);

        // 更新系统状态
        this.currentConfig = result.finalConfig;

        return {
          success: true,
          snapshotId,
          diff,
          results: result.results
        };
      } else {
        logger.error(`❌ 从快照回滚失败: ${snapshotId}`, result.error);
        return result;
      }

    } catch (error) {
      logger.error(`❌ 从快照回滚失败: ${snapshotId}`, error);
      return {
        success: false,
        snapshotId,
        error: error.message
      };
    }
  }

  /**
   * 紧急回滚（基于触发条件）
   * @param {Object} metrics - 指标数据
   * @returns {Promise<Object>} 回滚结果
   */
  async emergencyRollback(metrics) {
    logger.warn('⚠️  触发紧急回滚...');

    const conditions = {
      successDrop: metrics.successRate < 85,
      errorSpike: metrics.errorRate > 8
    };

    // 检查紧急回滚条件
    if (conditions.successDrop || conditions.errorSpike) {
      logger.warn('紧急回滚条件满足', conditions);

      // 获取最后一个稳定快照
      const snapshots = await this.listSnapshots();

      if (snapshots.length > 0) {
        const lastStableSnapshot = snapshots[snapshots.length - 1];
        return await this.rollbackToSnapshot(lastStableSnapshot.id);
      }
    }

    return {
      success: false,
      reason: 'No emergency rollback conditions met',
      conditions
    };
  }

  /**
   * 列出所有快照
   * @returns {Promise<Array>} 快照列表
   */
  async listSnapshots() {
    try {
      const snapshotsDir = 'snapshots';
      const files = await fs.readdir(snapshotsDir);

      const snapshots = [];

      for (const file of files) {
        if (file.endsWith('.json')) {
          const snapshotId = file.replace('.json', '');
          try {
            const snapshotPath = `${snapshotsDir}/${file}`;
            const snapshot = JSON.parse(await fs.readFile(snapshotPath, 'utf8'));

            snapshots.push({
              id: snapshotId,
              timestamp: snapshot.timestamp,
              type: snapshot.type,
              state: snapshot.state,
              mode: snapshot.mode
            });
          } catch (error) {
            logger.error(`读取快照失败: ${file}`, error);
          }
        }
      }

      // 按时间戳降序排序
      snapshots.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

      return snapshots;

    } catch (error) {
      logger.error('列出快照失败', error);
      return [];
    }
  }

  /**
   * 获取回滚引擎状态
   * @returns {Object}
   */
  getStatus() {
    return {
      hasCurrentConfig: this.currentConfig !== null,
      currentConfigKeys: this.currentConfig ? Object.keys(this.currentConfig).length : 0
    };
  }
}

module.exports = new RollbackEngine();
