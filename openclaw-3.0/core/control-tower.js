// openclaw-3.0/core/control-tower.js
// 控制塔 - 唯一决策中枢

const fs = require('fs').promises;
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/control-tower.log' }),
    new winston.transports.Console({ format: winston.format.simple() })
  ]
});

class ControlTower {
  constructor() {
    // 系统模式（4种 - 已废弃，使用权重模式）
    this.modes = {
      NORMAL: { name: 'NORMAL', description: '正常运行' },
      WARNING: { name: 'WARNING', description: '轻微异常' },
      LIMITED: { name: 'LIMITED', description: '资源受限' },
      RECOVERY: { name: 'RECOVERY', description: '恢复模式' }
    };
    this.currentMode = 'NORMAL';

    // 权重模式（核心）
    this.weights = {
      stabilityScore: 0.5,      // 稳定性得分 (0-1)
      costPressureScore: 0.3,   // 成本压力得分 (0-1)
      failurePressureScore: 0.2 // 失败压力得分 (0-1)
    };

    // 验证窗口状态机
    this.validationStates = {
      NORMAL: { name: 'NORMAL', desc: '正常模式' },
      OPTIMIZED: { name: 'OPTIMIZED', desc: '优化完成，等待验证' },
      VALIDATION_DAY_1: { name: 'VALIDATION_DAY_1', desc: '验证日 1' },
      VALIDATION_DAY_2: { name: 'VALIDATION_DAY_2', desc: '验证日 2' },
      VALIDATION_DAY_3: { name: 'VALIDATION_DAY_3', desc: '验证日 3' }
    };
    this.currentState = 'NORMAL';

    // 配置
    this.config = {
      errorRateThresholds: {
        warning: 3,      // 3%
        recovery: 8      // 8%
      },
      tokenUsageThresholds: {
        limited: 0.85    // 85%
      },
      validationDays: 3,
      cooldownDays: 1,
      snapshotRetentionDays: 30
    };

    // 状态管理
    this.validationWindow = {
      active: false,
      optimizedAt: null,
      history: []
    };

    // 熔断器
    this.circuitBreaker = {
      isOpen: false,
      failures: 0,
      maxFailures: 5,
      lastFailure: null,
      resetTimeout: 5 * 60 * 1000 // 5分钟
    };

    logger.info('Control Tower 初始化完成');
  }

  /**
   * 更新系统模式（自动判断）
   * @deprecated 使用 updateWeightedMode 代替
   */
  updateSystemMode(errorRate, tokenUsageRatio, recentFailures) {
    const { warning: warningRate, recovery: recoveryRate } = this.config.errorRateThresholds;

    // 紧急情况：连续失败5次
    if (recentFailures >= this.circuitBreaker.maxFailures) {
      this.setMode('RECOVERY');
      return;
    }

    // 恢复模式：错误率 > 8%
    if (errorRate > recoveryRate) {
      this.setMode('RECOVERY');
      return;
    }

    // 受限模式：Token 使用 > 85%
    if (tokenUsageRatio > this.config.tokenUsageThresholds.limited) {
      this.setMode('LIMITED');
      return;
    }

    // 警告模式：错误率 > 3%
    if (errorRate > warningRate) {
      this.setMode('WARNING');
      return;
    }

    // 正常模式：默认
    this.setMode('NORMAL');
  }

  /**
   * 更新权重模式（权重驱动）
   */
  updateWeightedMode(errorRate, tokenUsageRatio, recentFailures) {
    // 计算各维度得分（0-1）
    const stabilityScore = 1 - (errorRate / 100); // 错误率越低越稳定
    const costPressureScore = tokenUsageRatio; // Token使用越高压力越大
    const failurePressureScore = recentFailures / this.circuitBreaker.maxFailures; // 失败越多压力越大

    // 限制在0-1之间
    this.weights.stabilityScore = Math.max(0, Math.min(1, stabilityScore));
    this.weights.costPressureScore = Math.max(0, Math.min(1, costPressureScore));
    this.weights.failurePressureScore = Math.max(0, Math.min(1, failurePressureScore));

    // 计算综合压力分数
    const totalPressure = (
      this.weights.stabilityScore * 0.4 +
      this.weights.costPressureScore * 0.3 +
      this.weights.failurePressureScore * 0.3
    );

    logger.info({
      action: 'weighted_mode_updated',
      scores: this.weights,
      totalPressure: totalPressure.toFixed(2),
      stabilityScore: this.weights.stabilityScore.toFixed(2),
      costPressureScore: this.weights.costPressureScore.toFixed(2),
      failurePressureScore: this.weights.failurePressureScore.toFixed(2)
    });

    // 根据综合压力决定模式
    if (totalPressure > 0.8) {
      this.setMode('RECOVERY');
    } else if (totalPressure > 0.6) {
      this.setMode('LIMITED');
    } else if (totalPressure > 0.4) {
      this.setMode('WARNING');
    } else {
      this.setMode('NORMAL');
    }
  }

  /**
   * 设置模式
   * @param {string} modeName - 模式名称
   */
  setMode(modeName) {
    if (!this.modes[modeName]) {
      logger.error(`❌ 无效的模式: ${modeName}`);
      return;
    }

    const oldMode = this.currentMode;
    this.currentMode = modeName;

    logger.info({
      action: 'mode_changed',
      from: oldMode,
      to: modeName,
      description: this.modes[modeName].description
    });
  }

  /**
   * 获取当前模式
   * @returns {Object}
   */
  getCurrentMode() {
    return this.modes[this.currentMode];
  }

  /**
   * 检查模式是否允许调用
   * @returns {boolean}
   */
  isCallAllowed() {
    // 检查熔断器
    if (this.circuitBreaker.isOpen) {
      logger.warn('⚠️  熔断器开启，禁止调用');
      return false;
    }

    // 检查模式限制
    const mode = this.getCurrentMode();
    switch (mode.name) {
      case 'NORMAL':
        return true; // 全功能
      case 'WARNING':
        // 降低并发，允许调用但减少参数
        return true;
      case 'LIMITED':
        // 强制低成本模型
        return true;
      case 'RECOVERY':
        // 停止优化，仅保留核心调用
        return true;
      default:
        return true;
    }
  }

  /**
   * 执行优化决策（Evolution Gate）
   * @returns {Object} 优化提议
   */
  makeOptimizationDecision(metrics, goals) {
    // 每天最多 1 次优化
    if (this.currentState !== 'NORMAL') {
      return {
        allowed: false,
        reason: 'not_in_normal_mode',
        currentState: this.currentState
      };
    }

    // 检查是否在验证窗口
    if (this.validationWindow.active) {
      return {
        allowed: false,
        reason: 'in_validation_window',
        validationDaysLeft: this.getValidationDaysLeft()
      };
    }

    // 成本-风险联合判断矩阵
    const costTrend = this.analyzeCostTrend(metrics.dailyTokens, 7);
    const successRate = metrics.successRate || 90;

    const decision = this.costRiskDecisionMatrix(costTrend, successRate);

    if (!decision.allowOptimization) {
      return {
        allowed: false,
        reason: decision.reason,
        costTrend,
        successRate
      };
    }

    // 风险评分
    const riskScore = this.calculateRiskScore(decision.proposedChanges, metrics);

    if (riskScore > 0.6) {
      return {
        allowed: false,
        reason: 'high_risk',
        riskScore: riskScore.toFixed(2)
      };
    }

    // 生成优化提议
    const proposal = {
      allowed: true,
      reason: 'optimization_proposed',
      proposedChanges: decision.proposedChanges,
      riskScore: riskScore.toFixed(2),
      validationDays: this.config.validationDays
    };

    // 创建快照
    const snapshotId = this.createSnapshot('optimization', proposal);

    proposal.snapshotId = snapshotId;

    logger.info({
      action: 'optimization_decision',
      proposal,
      costTrend,
      successRate
    });

    return proposal;
  }

  /**
   * 成本-风险联合判断矩阵
   * @param {number} costTrend - 成本趋势（百分比）
   * @param {number} successRate - 成功率
   * @returns {Object}
   */
  costRiskDecisionMatrix(costTrend, successRate) {
    // 优先级：稳定 > 成功率 > 成本

    if (successRate < 85) {
      // 成功率过低，优先修复
      return {
        allowOptimization: true,
        priority: 'success_rate',
        reason: 'success_rate_low',
        proposedChanges: ['fix_prompt', 'reduce_context_length']
      };
    }

    if (costTrend > 10) {
      // 成本上升，可以优化
      return {
        allowOptimization: true,
        priority: 'cost_control',
        reason: 'cost_increasing',
        proposedChanges: ['reduce_tokens', 'switch_to_cheap_model']
      };
    }

    if (costTrend < 0) {
      // 成本下降，观察
      return {
        allowOptimization: false,
        priority: 'monitoring',
        reason: 'cost_decreasing',
        proposedChanges: []
      };
    }

    // 成本稳定，观察
    return {
      allowOptimization: false,
      priority: 'monitoring',
      reason: 'stable_cost',
      proposedChanges: []
    };
  }

  /**
   * 计算风险评分
   * @param {Array} changes - 变更列表
   * @param {Object} metrics - 指标数据
   * @returns {number}
   */
  calculateRiskScore(changes, metrics) {
    // 简化公式
    // risk_score = (change_scope * 0.4) + (recent_instability * 0.3) + (system_load * 0.3)

    let changeScope = 0;
    if (changes.includes('reduce_tokens')) changeScope += 0.3;
    if (changes.includes('switch_to_cheap_model')) changeScope += 0.4;
    if (changes.includes('fix_prompt')) changeScope += 0.3;

    const recentInstability = (1 - (metrics.successRate || 90) / 100) * 0.3;

    const systemLoad = (metrics.dailyTokens || 0) / 200000 * 0.3;

    const riskScore = changeScope * 0.4 + recentInstability * 0.3 + systemLoad * 0.3;

    return Math.min(riskScore, 1.0);
  }

  /**
   * 分析成本趋势
   * @param {number} currentTokens - 当前token
   * @param {number} days - 对比天数
   * @returns {number} 趋势（百分比）
   */
  analyzeCostTrend(currentTokens, days = 7) {
    // TODO: 从历史数据读取
    // 这里返回示例值
    return 0;
  }

  /**
   * 进入验证窗口
   * @param {Object} proposal - 优化提议
   */
  enterValidationWindow(proposal) {
    this.currentState = 'OPTIMIZED';
    this.validationWindow.active = true;
    this.validationWindow.optimizedAt = new Date().toISOString();
    this.validationWindow.proposal = proposal;

    // 创建验证窗口历史记录
    this.validationWindow.history.push({
      date: new Date().toISOString(),
      state: 'OPTIMIZED',
      snapshotId: proposal.snapshotId
    });

    logger.info({
      action: 'validation_window_started',
      state: 'OPTIMIZED',
      snapshotId: proposal.snapshotId
    });
  }

  /**
   * 获取剩余验证天数
   * @returns {number}
   */
  getValidationDaysLeft() {
    if (!this.validationWindow.active) return 0;

    const optimizedTime = new Date(this.validationWindow.optimizedAt).getTime();
    const now = new Date().getTime();
    const elapsedDays = Math.floor((now - optimizedTime) / (24 * 60 * 60 * 1000));

    return Math.max(0, this.config.validationDays - elapsedDays);
  }

  /**
   * 进入验证日
   */
  enterValidationDay(day) {
    this.currentState = `VALIDATION_DAY_${day}`;
    logger.info({
      action: 'validation_day',
      day: day,
      state: this.currentState
    });
  }

  /**
   * 验证结果处理
   * @param {Object} result - 验证结果（true=成功，false=失败）
   */
  processValidationResult(result) {
    const daysLeft = this.getValidationDaysLeft();

    if (!result) {
      // 失败：回滚
      logger.warn('⚠️  验证失败，执行回滚');
      this.rollbackToSnapshot();
    } else {
      // 成功：固化
      if (daysLeft === 0) {
        logger.info('✅ 验证通过，固化配置');
        this.currentState = 'NORMAL';
        this.validationWindow.active = false;
        this.validationWindow.history.push({
          date: new Date().toISOString(),
          state: 'COMMITTED',
          snapshotId: this.validationWindow.proposal.snapshotId
        });
      }
    }
  }

  /**
   * 创建快照
   * @param {string} type - 快照类型
   * @param {Object} context - 快照上下文
   * @returns {string} 快照ID
   */
  createSnapshot(type, context) {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const snapshotId = `${timestamp}_v${this.getNextVersion()}`;

    const snapshot = {
      id: snapshotId,
      type,
      timestamp: new Date().toISOString(),
      context,
      state: this.currentState,
      mode: this.currentMode
    };

    // 保存到 snapshots 目录
    const filename = `${snapshotId}.json`;
    const filepath = `snapshots/${filename}`;

    fs.writeFile(filepath, JSON.stringify(snapshot, null, 2))
      .then(() => {
        logger.info({
          action: 'snapshot_created',
          id: snapshotId,
          type,
          filepath
        });
      })
      .catch(error => {
        logger.error({
          action: 'snapshot_save_failed',
          id: snapshotId,
          error: error.message
        });
      });

    return snapshotId;
  }

  /**
   * 回滚到快照
   */
  rollbackToSnapshot() {
    logger.warn('⚠️  开始回滚...');

    // TODO: 实现回滚逻辑
    logger.warn('❌ 回滚功能待实现');
  }

  /**
   * 获取下一个版本号
   * @returns {number}
   */
  getNextVersion() {
    if (!this.validationWindow.history.length) return 1;

    const lastState = this.validationWindow.history[this.validationWindow.history.length - 1];
    const match = lastState.state.match(/v(\d+)/);
    return match ? parseInt(match[1]) + 1 : 1;
  }

  /**
   * 更新熔断器状态
   * @param {boolean} failure - 是否失败
   */
  updateCircuitBreaker(failure) {
    if (failure) {
      this.circuitBreaker.failures++;
      this.circuitBreaker.lastFailure = new Date().toISOString();

      if (this.circuitBreaker.failures >= this.circuitBreaker.maxFailures) {
        this.circuitBreaker.isOpen = true;
        logger.warn('⚠️  熔断器已打开');
      }
    } else {
      // 成功调用，重置
      this.circuitBreaker.failures = 0;
      if (this.circuitBreaker.isOpen) {
        const elapsed = Date.now() - new Date(this.circuitBreaker.lastFailure).getTime();
        if (elapsed > this.circuitBreaker.resetTimeout) {
          this.circuitBreaker.isOpen = false;
          logger.info('✅ 熔断器已关闭');
        }
      }
    }
  }

  /**
   * 获取控制塔状态
   * @returns {Object}
   */
  getStatus() {
    return {
      currentMode: this.getCurrentMode(),
      currentState: this.currentState,
      validationWindow: {
        active: this.validationWindow.active,
        daysLeft: this.getValidationDaysLeft(),
        history: this.validationWindow.history
      },
      circuitBreaker: {
        isOpen: this.circuitBreaker.isOpen,
        failures: this.circuitBreaker.failures,
        maxFailures: this.circuitBreaker.maxFailures
      },
      config: this.config
    };
  }
}

module.exports = new ControlTower();
