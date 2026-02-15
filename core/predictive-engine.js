// core/predictive-engine.js
// OpenClaw 3.0 - Converged Predictive Engine
// 负责提前检测压力，生成干预建议（不直接执行）

class PredictiveEngine {
  constructor(config) {
    this.config = config;
    this.state = {
      smoothedRequestRate: 0,
      smoothedTokenRate: 0,
      lastUpdate: Date.now()
    };
  }

  // 平滑函数（阻尼）- 防止震荡
  smooth(previous, current, alpha = 0.3) {
    return previous * (1 - alpha) + current * alpha;
  }

  // 1️⃣ 速率压力评估
  evaluateRatePressure(metrics) {
    const currentRate = metrics.callsLastMinute;
    const limit = this.config.maxRequestsPerMinute;

    // 使用移动平均平滑速率
    this.state.smoothedRequestRate = this.smooth(
      this.state.smoothedRequestRate,
      currentRate
    );

    const pressure = this.state.smoothedRequestRate / limit;
    let throttleDelay = 0;
    let level = "NORMAL";

    // 基于压力值设置延迟
    if (pressure > 0.95) {
      throttleDelay = 800;  // 严重：延迟800ms
      level = "CRITICAL";
    } else if (pressure > 0.8) {
      throttleDelay = 400;  // 高：延迟400ms
      level = "HIGH";
    } else if (pressure > 0.6) {
      throttleDelay = 150;  // 中：延迟150ms
      level = "MEDIUM";
    }

    return { pressure, throttleDelay, level };
  }

  // 2️⃣ 上下文压力评估
  evaluateContextPressure(context) {
    const remainingRatio = context.remainingTokens / context.maxTokens;
    let compressionLevel = 0;
    let level = "NORMAL";

    // 基于剩余Token比例设置压缩等级
    if (remainingRatio < 0.15) {
      compressionLevel = 3;  // 强制压缩
      level = "CRITICAL";
    } else if (remainingRatio < 0.25) {
      compressionLevel = 2;  // 中等压缩
      level = "HIGH";
    } else if (remainingRatio < 0.35) {
      compressionLevel = 1;  // 轻度压缩
      level = "MEDIUM";
    }

    return { remainingRatio, compressionLevel, level };
  }

  // 3️⃣ 预算压力评估
  evaluateBudgetPressure(metrics) {
    const hourlyRate = metrics.tokensLastHour;
    const remaining = metrics.remainingBudget;

    // 使用移动平均平滑Token速率
    this.state.smoothedTokenRate = this.smooth(
      this.state.smoothedTokenRate,
      hourlyRate
    );

    const hoursLeft = remaining / (this.state.smoothedTokenRate || 1);
    let modelBias = "NORMAL";
    let level = "NORMAL";

    // 基于剩余预算时间设置模型偏置
    if (hoursLeft < 3) {
      modelBias = "CHEAP_ONLY";  // 只使用便宜模型
      level = "CRITICAL";
    } else if (hoursLeft < 6) {
      modelBias = "MID_ONLY";    // 只使用中等模型
      level = "HIGH";
    } else if (hoursLeft < 12) {
      modelBias = "REDUCE_HIGH"; // 降低使用高价模型
      level = "MEDIUM";
    }

    return { hoursLeft, modelBias, level };
  }

  // 🔥 核心输出：计算干预建议
  computeIntervention(metrics, context) {
    const rate = this.evaluateRatePressure(metrics);
    const ctx = this.evaluateContextPressure(context);
    const budget = this.evaluateBudgetPressure(metrics);

    return {
      throttleDelay: rate.throttleDelay,
      compressionLevel: ctx.compressionLevel,
      modelBias: budget.modelBias,
      warningLevel: this.maxLevel(rate.level, ctx.level, budget.level),
      details: {
        rate,
        ctx,
        budget
      }
    };
  }

  // 等级排序（从低到高）
  maxLevel(...levels) {
    const order = ["NORMAL", "MEDIUM", "HIGH", "CRITICAL"];
    return levels.sort((a, b) => order.indexOf(b) - order.indexOf(a))[0];
  }
}

module.exports = PredictiveEngine;
