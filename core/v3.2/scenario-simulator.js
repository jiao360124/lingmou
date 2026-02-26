/**
 * OpenClaw V3.2 - Scenario Simulator
 * 策略引擎核心模块：场景模拟器
 *
 * 功能：
 * - 模拟不同响应方案的长期影响
 * - 推演系统状态演化路径
 * - 评估方案优劣
 *
 * @author OpenClaw V3.2
 * @date 2026-02-21
 */

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

class ScenarioSimulator {
  constructor() {
    this.name = 'ScenarioSimulator';
  }

  /**
   * 模拟多个策略方案
   * @param {Object} input - 输入参数
   * @param {SystemState} input.currentState - 当前系统状态
   * @param {Array<StrategyConfig>} input.strategies - 策略配置列表
   * @param {number} input.timeHorizon - 推演步数
   * @returns {Promise<ScenarioOutput>}
   */
  async simulate(input) {
    const { currentState, strategies, timeHorizon = 10 } = input;

    console.log(`[ScenarioSimulator] 开始模拟 ${strategies.length} 个策略，步数: ${timeHorizon}`);

    const scenarios = [];

    for (const strategy of strategies) {
      console.log(`[ScenarioSimulator] 模拟策略: ${strategy.name}`);

      const result = await this.runSimulation({
        initialState: currentState,
        strategy: strategy,
        steps: timeHorizon
      });

      scenarios.push(result);

      // 模拟延迟，避免阻塞
      await sleep(10);
    }

    const summary = this.summarizeResults(scenarios);
    const recommendations = this.generateRecommendations(scenarios);

    return {
      scenarios,
      summary,
      recommendations,
      timestamp: new Date()
    };
  }

  /**
   * 运行单次模拟
   * @param {Object} params
   * @returns {Promise<ScenarioResult>}
   */
  async runSimulation({ initialState, strategy, steps }) {
    let currentState = this.initializeState(initialState);
    const history = [];
    let successfulSteps = 0;

    console.log(`[ScenarioSimulator] 运行 ${strategy.name}，步数: ${steps}`);

    for (let i = 0; i < steps; i++) {
      // 1. 应用策略
      currentState = this.applyStrategy(currentState, strategy);

      // 2. 检查停止条件
      if (this.shouldStop(currentState)) {
        console.log(`[ScenarioSimulator] ${strategy.name} 在第 ${i} 步停止`);
        break;
      }

      // 3. 模拟系统响应
      const response = await this.simulateSystemResponse(currentState);

      // 4. 记录状态
      history.push({
        step: i,
        state: this.cloneState(currentState),
        metrics: response.metrics,
        success: response.success
      });

      if (response.success) {
        successfulSteps++;
      }

      // 5. 额外延迟（模拟真实延迟）
      await sleep(5);
    }

    return {
      strategy: strategy.name,
      description: strategy.description || strategy.name,
      finalState: currentState,
      history,
      finalMetrics: history[history.length - 1]?.metrics || null,
      successRate: history.length > 0 ? successfulSteps / history.length : 0,
      totalSteps: history.length,
      warnings: this.generateWarnings(currentState, history)
    };
  }

  /**
   * 初始化模拟状态
   */
  initializeState(initialState) {
    return {
      tokens: { ...initialState.tokens },
      metrics: { ...initialState.metrics },
      errors: 0,
      success: 0
    };
  }

  /**
   * 克隆状态（深拷贝）
   */
  cloneState(state) {
    return {
      tokens: { ...state.tokens },
      metrics: { ...state.metrics },
      errors: state.errors,
      success: state.success
    };
  }

  /**
   * 应用策略到当前状态
   */
  applyStrategy(currentState, strategy) {
    let newState = this.cloneState(currentState);

    switch (strategy.type) {
      case 'COMPRESSION':
        newState = this.applyCompression(newState, strategy);
        break;
      case 'MODEL_CHANGE':
        newState = this.applyModelChange(newState, strategy);
        break;
      case 'DELAY':
        newState = this.applyDelay(newState, strategy);
        break;
      case 'FALLBACK':
        newState = this.applyFallback(newState, strategy);
        break;
      default:
        console.warn(`[ScenarioSimulator] 未知策略类型: ${strategy.type}`);
    }

    return newState;
  }

  /**
   * 应用压缩策略
   */
  applyCompression(currentState, strategy) {
    const level = strategy.level || 2;
    const maxTokens = strategy.maxTokens || 50000;

    let reduction = 0;

    switch (level) {
      case 0:
        reduction = 0;  // 不压缩
        break;
      case 1:
        reduction = 0.2;  // 减少 20%
        break;
      case 2:
        reduction = 0.4;  // 减少 40%
        break;
      case 3:
        reduction = 0.6;  // 减少 60%
        break;
      default:
        reduction = 0.5;
    }

    // 应用压缩
    const tokensBefore = currentState.tokens.remaining;
    const tokensAfter = Math.max(maxTokens, tokensBefore * (1 - reduction));
    const tokensUsed = tokensBefore - tokensAfter;

    return {
      ...currentState,
      tokens: {
        ...currentState.tokens,
        remaining: tokensAfter,
        lastUsed: tokensUsed
      }
    };
  }

  /**
   * 应用模型变更策略
   */
  applyModelChange(currentState, strategy) {
    const model = strategy.model || 'default';

    // 模拟模型切换影响
    let qualityChange = 0;
    let costChange = 0;

    switch (model) {
      case 'cheap':
        qualityChange = -0.15;  // 质量 -15%
        costChange = 0.5;  // 成本 +50%
        break;
      case 'mid':
        qualityChange = 0;  // 质量 0
        costChange = 0;  // 成常 0
        break;
      case 'high':
        qualityChange = +0.1;  // 质量 +10%
        costChange = 0.3;  // 成本 +30%
        break;
      default:
        qualityChange = 0;
        costChange = 0;
    }

    return {
      ...currentState,
      metrics: {
        ...currentState.metrics,
        currentModel: model,
        qualityChange,
        costChange
      }
    };
  }

  /**
   * 应用延迟策略
   */
  applyDelay(currentState, strategy) {
    const delayMs = strategy.delayMs || 100;

    // 延迟会减少实时压力，但可能影响用户体验
    return {
      ...currentState,
      metrics: {
        ...currentState.metrics,
        pendingDelay: delayMs
      }
    };
  }

  /**
   * 应用回退策略
   */
  applyFallback(currentState, strategy) {
    const fallback = strategy.fallback || 'simpler';

    return {
      ...currentState,
      metrics: {
        ...currentState.metrics,
        usingFallback: true,
        fallbackStrategy: fallback
      }
    };
  }

  /**
   * 检查是否应该停止模拟
   */
  shouldStop(currentState) {
    // 如果 Token 耗尽，停止
    if (currentState.tokens.remaining <= 0) {
      console.log(`[ScenarioSimulator] Token 耗尽，停止模拟`);
      return true;
    }

    // 如果错误率过高，停止
    if (currentState.metrics.errorRate > 0.8) {
      console.log(`[ScenarioSimulator] 错误率过高，停止模拟`);
      return true;
    }

    return false;
  }

  /**
   * 模拟系统响应
   */
  async simulateSystemResponse(currentState) {
    // 基于当前状态模拟响应
    const errorRate = currentState.metrics.errorRate || 0.05;
    const success = Math.random() > errorRate;

    let quality = 0.9;
    let tokensUsed = 5000;

    if (success) {
      // 成功的响应
      quality = 0.85 + Math.random() * 0.15;
      tokensUsed = 3000 + Math.random() * 4000;

      currentState.success++;
    } else {
      // 失败的响应
      quality = 0.4 + Math.random() * 0.2;
      tokensUsed = 2000 + Math.random() * 2000;

      currentState.errors++;
    }

    // 应用压缩影响
    if (currentState.metrics.compressionApplied) {
      quality *= 0.95;
    }

    return {
      success,
      metrics: {
        quality,
        tokensUsed,
        errorRate,
        remainingTokens: currentState.tokens.remaining - tokensUsed
      }
    };
  }

  /**
   * 总结模拟结果
   */
  summarizeResults(scenarios) {
    const totals = {
      totalSteps: 0,
      totalSuccessRate: 0,
      totalTokensUsed: 0,
      totalErrors: 0
    };

    for (const scenario of scenarios) {
      totals.totalSteps += scenario.totalSteps;
      totals.totalSuccessRate += scenario.successRate;
      totals.totalTokensUsed += scenario.finalMetrics?.tokensUsed || 0;
      totals.totalErrors += scenario.warnings?.length || 0;
    }

    const avgSuccessRate = scenarios.length > 0
      ? totals.totalSuccessRate / scenarios.length
      : 0;

    return {
      scenariosCount: scenarios.length,
      averageSuccessRate: avgSuccessRate.toFixed(2),
      bestStrategy: this.findBestStrategy(scenarios),
      worstStrategy: this.findWorstStrategy(scenarios),
      trends: this.analyzeTrends(scenarios)
    };
  }

  /**
   * 找到最佳策略
   */
  findBestStrategy(scenarios) {
    let best = null;

    for (const scenario of scenarios) {
      const score = this.calculateStrategyScore(scenario);

      if (!best || score > this.calculateStrategyScore(best)) {
        best = scenario;
      }
    }

    return best;
  }

  /**
   * 找到最差策略
   */
  findWorstStrategy(scenarios) {
    let worst = null;

    for (const scenario of scenarios) {
      const score = this.calculateStrategyScore(scenario);

      if (!worst || score < this.calculateStrategyScore(worst)) {
        worst = scenario;
      }
    }

    return worst;
  }

  /**
   * 计算策略评分
   */
  calculateStrategyScore(scenario) {
    if (!scenario.finalMetrics) return 0;

    const quality = scenario.finalMetrics.quality || 0;
    const successRate = scenario.successRate || 0;
    const tokensUsed = scenario.finalMetrics.tokensUsed || 0;

    // 评分：质量 40% + 成功率 30% + 效率 30%
    return quality * 0.4 + successRate * 0.3 + (100000 / (tokensUsed + 10000)) * 0.3;
  }

  /**
   * 分析趋势
   */
  analyzeTrends(scenarios) {
    const trends = {
      tokens: [],
      successRate: [],
      quality: []
    };

    for (const scenario of scenarios) {
      if (scenario.history && scenario.history.length > 0) {
        trends.tokens.push(scenario.history[scenario.history.length - 1]?.metrics?.tokensUsed || 0);
        trends.successRate.push(scenario.successRate || 0);
        trends.quality.push(scenario.finalMetrics?.quality || 0);
      }
    }

    return trends;
  }

  /**
   * 生成建议
   */
  generateRecommendations(scenarios) {
    const recommendations = [];

    const best = this.findBestStrategy(scenarios);
    const worst = this.findWorstStrategy(scenarios);

    if (best && worst) {
      recommendations.push({
        strategy: 'BEST',
        strategyName: best.strategy,
        description: `推荐使用 ${best.strategy} 策略`,
        metrics: {
          successRate: best.successRate,
          quality: best.finalMetrics?.quality,
          tokensUsed: best.finalMetrics?.tokensUsed
        }
      });

      recommendations.push({
        strategy: 'AVOID',
        strategyName: worst.strategy,
        description: `避免使用 ${worst.strategy} 策略`,
        reasons: [
          '成功率较低',
          '质量较差',
          '资源消耗较大'
        ]
      });
    }

    return recommendations;
  }

  /**
   * 生成警告
   */
  generateWarnings(currentState, history) {
    const warnings = [];

    // 检查 Token 使用情况
    if (currentState.tokens.remaining < 10000) {
      warnings.push({
        type: 'CRITICAL',
        message: `Token 剩余不足 10k，请及时补充`
      });
    }

    // 检查成功率
    if (history.length > 0) {
      const successRate = currentState.success / history.length;
      if (successRate < 0.7) {
        warnings.push({
          type: 'WARNING',
          message: `成功率低于 70%，可能需要调整策略`
        });
      }
    }

    return warnings;
  }
}

// 导出模块
module.exports = ScenarioSimulator;
