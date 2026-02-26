/**
 * OpenClaw V3.2 - 示例策略
 * 展示如何创建自定义策略
 *
 * @author OpenClaw V3.2
 * @date 2026-02-21
 */

class ExampleStrategy {
  constructor() {
    this.name = 'ExampleStrategy';
    this.description = '示例策略，展示策略的基本结构';
  }

  /**
   * 执行策略
   * @param {Object} context - 执行上下文
   * @returns {Promise<StrategyResult>}
   */
  async execute(context) {
    console.log(`[ExampleStrategy] 执行策略: ${this.name}`);

    const startTime = Date.now();

    // 模拟策略执行
    const quality = this.calculateQuality(context);
    const successRate = this.calculateSuccessRate(context);
    const userSatisfaction = this.calculateSatisfaction(context);
    const efficiency = this.calculateEfficiency(context);

    const executionTime = Date.now() - startTime;

    return {
      quality,
      successRate,
      userSatisfaction,
      efficiency,
      tokensUsed: 5000,
      executionTime,
      timestamp: new Date()
    };
  }

  /**
   * 计算质量
   */
  calculateQuality(context) {
    // 基于上下文计算质量
    const contextPressure = context.tokensRemaining / context.tokensTotal;

    let quality = 0.9;

    // 上下文压力越大，质量可能下降
    if (contextPressure < 0.3) {
      quality = 0.85;
    } else if (contextPressure < 0.5) {
      quality = 0.88;
    } else if (contextPressure > 0.8) {
      quality = 0.82;
    }

    return quality;
  }

  /**
   * 计算成功率
   */
  calculateSuccessRate(context) {
    const baseRate = 0.9;
    const qualityAdjustment = this.lastQuality || 0.9;

    // 质量越高，成功率越高
    return baseRate * qualityAdjustment;
  }

  /**
   * 计算满意度
   */
  calculateSatisfaction(context) {
    // 基于用户的满意度记录
    return this.lastSatisfaction || 0.88;
  }

  /**
   * 计算效率
   */
  calculateEfficiency(context) {
    // 基于上下文大小
    const contextSize = context.tokensRemaining;

    let efficiency = 0.9;

    if (contextSize > 80000) {
      efficiency = 0.8;
    } else if (contextSize > 60000) {
      efficiency = 0.85;
    }

    return efficiency;
  }
}

/**
 * 中等压缩策略
 */
class MidCompressionStrategy extends ExampleStrategy {
  constructor() {
    super();
    this.name = 'MID_COMPRESS';
    this.description = '中等压缩策略，适用于大多数场景';
  }

  async execute(context) {
    const baseResult = await super.execute(context);

    // 应用压缩
    baseResult.tokensUsed *= 0.6;  // 减少 40%
    baseResult.quality *= 0.95;    // 质量下降 5%

    return baseResult;
  }
}

/**
 * 激进压缩策略
 */
class AggressiveCompressionStrategy extends ExampleStrategy {
  constructor() {
    super();
    this.name = 'AGGRESSIVE_COMPRESS';
    this.description = '激进压缩策略，大幅减少 token 消耗';
  }

  async execute(context) {
    const baseResult = await super.execute(context);

    // 应用激进压缩
    baseResult.tokensUsed *= 0.4;  // 减少 60%
    baseResult.quality *= 0.92;    // 质量下降 8%
    baseResult.successRate *= 0.95;  // 成功率下降 5%

    return baseResult;
  }
}

/**
 * 模型变更策略
 */
class ModelChangeStrategy extends ExampleStrategy {
  constructor() {
    super();
    this.name = 'MID_MODEL';
    this.description = '使用中等模型';
  }

  async execute(context) {
    const baseResult = await super.execute(context);

    // 模型变更
    baseResult.successRate = 0.92;  // 中等模型成功率

    return baseResult;
  }
}

/**
 * 延迟策略
 */
class DelayStrategy extends ExampleStrategy {
  constructor() {
    super();
    this.name = 'DELAY_200MS';
    this.description = '延迟 200ms 执行';
  }

  async execute(context) {
    // 模拟延迟
    await new Promise(resolve => setTimeout(resolve, 200));

    const baseResult = await super.execute(context);

    return {
      ...baseResult,
      executionTime: baseResult.executionTime + 200
    };
  }
}

module.exports = {
  ExampleStrategy,
  MidCompressionStrategy,
  AggressiveCompressionStrategy,
  ModelChangeStrategy,
  DelayStrategy
};
