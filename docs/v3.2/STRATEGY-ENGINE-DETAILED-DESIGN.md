# 策略引擎详细设计 (V3.2)

**模块**: 策略引擎
**优先级**: P0
**预计工时**: 32h
**负责人**: 灵眸

---

## 📋 模块概述

策略引擎是 V3.2 的核心模块，将 OpenClaw 从"预测引擎"升级为"策略引擎"。通过场景模拟、成本收益分析、风险评估和自我博弈，实现从"反应型"到"规划型"的智能跃迁。

---

## 🎯 核心功能

### 1. 场景模拟器 (Scenario Simulator)

**功能描述**：
模拟不同响应方案的长期影响，推演系统状态演化路径。

#### 输入输出

**输入**：
```typescript
interface ScenarioInput {
  currentState: SystemState;
  strategy: StrategyConfig;
  timeHorizon: number;  // 推演步数: 1/5/10/30
  variables?: Map<string, number>;  // 可变参数
}
```

**输出**：
```typescript
interface ScenarioOutput {
  scenarios: ScenarioResult[];
  currentState: SystemState;
  predictions: PredictionMetrics;
}
```

#### 算法逻辑

```javascript
class ScenarioSimulator {
  async simulate(input) {
    const scenarios = [];

    for (const strategy of input.strategies) {
      const result = await this.runSimulation({
        initialState: input.currentState,
        strategy: strategy,
        steps: input.timeHorizon
      });

      scenarios.push(result);
    }

    return {
      scenarios,
      summary: this.summarizeResults(scenarios),
      recommendations: this.generateRecommendations(scenarios)
    };
  }

  async runSimulation({ initialState, strategy, steps }) {
    let currentState = initialState;
    const history = [];

    for (let i = 0; i < steps; i++) {
      // 1. 应用策略
      currentState = this.applyStrategy(currentState, strategy);

      // 2. 检查停止条件
      if (this.shouldStop(currentState)) {
        break;
      }

      // 3. 记录状态
      history.push({
        step: i,
        state: currentState,
        metrics: this.extractMetrics(currentState)
      });
    }

    return {
      strategy: strategy.name,
      finalState: currentState,
      history,
      finalMetrics: history[history.length - 1].metrics
    };
  }

  // ... 其他方法
}
```

#### 使用示例

```javascript
const simulator = new ScenarioSimulator();

const input = {
  currentState: {
    tokens: { remaining: 85000, total: 200000 },
    errorRate: 0.05,
    successRate: 0.88,
    metrics: {
      callsLastMinute: 8,
      contextPressure: 0.5
    }
  },
  strategies: [
    { name: "AGGRESSIVE_COMPRESS", level: 3 },
    { name: "MID_COMPRESS", level: 2 },
    { name: "NO_COMPRESS", level: 0 }
  ],
  timeHorizon: 10
};

const result = await simulator.simulate(input);

console.log(result.scenarios);
// [
//   {
//     strategy: "AGGRESSIVE_COMPRESS",
//     finalMetrics: {
//       remainingTokens: 72000,
//       successRate: 0.82,  // 略微下降
//       errorRate: 0.07     // 略微上升
//     }
//   },
//   // ... 其他策略结果
// ]
```

**文件位置**: `core/scenario-simulator.js`

---

### 2. 成本收益评分器 (Cost-Benefit Scorer)

**功能描述**：
计算每个策略的ROI，量化决策价值。

#### 评分模型

```typescript
interface StrategyScore {
  strategyName: string;
  cost: CostMetrics;
  benefit: BenefitMetrics;
  roi: number;
  riskScore: number;
  finalScore: number;
  details: {
    quality: number;      // 0-1
    successRate: number;  // 0-1
    userSatisfaction: number;  // 0-1
  };
}
```

#### 评分算法

```javascript
class CostBenefitScorer {
  async score(strategy, context) {
    // 1. 计算成本
    const cost = await this.calculateCost(strategy, context);

    // 2. 计算收益
    const benefit = await this.calculateBenefit(strategy, context);

    // 3. 计算ROI
    const roi = benefit.value / cost.value;

    // 4. 计算风险调整
    const riskScore = await this.calculateRiskScore(strategy, context);
    const adjustedScore = this.applyRiskAdjustment(roi, riskScore);

    // 5. 计算最终得分
    const finalScore = this.computeFinalScore(roi, riskScore, benefit.weight);

    return {
      strategyName: strategy.name,
      cost,
      benefit,
      roi,
      riskScore,
      finalScore,
      details: {
        quality: benefit.value / cost.value * 0.5,
        successRate: context.successRate,
        userSatisfaction: context.userSatisfaction || 0.85
      }
    };
  }

  async calculateCost(strategy, context) {
    const baseCost = strategy.tokensConsumed;
    const qualityCost = strategy.tokensConsumed * (1 - strategy.quality);
    const executionCost = strategy.executionTime * 0.001; // 时间成本

    return {
      value: baseCost + qualityCost + executionCost,
      breakdown: {
        tokens: baseCost,
        qualityPenalty: qualityCost,
        execution: executionCost
      },
      totalTokens: strategy.tokensConsumed,
      totalExecutionTime: strategy.executionTime
    };
  }

  async calculateBenefit(strategy, context) {
    const qualityGain = strategy.quality * 100;
    const successGain = (strategy.successRate - context.successRate) * 100;
    const satisfactionGain = strategy.userSatisfaction * 50;

    return {
      value: qualityGain + successGain + satisfactionGain,
      breakdown: {
        quality: qualityGain,
        successRate: successGain,
        userSatisfaction: satisfactionGain
      },
      weight: 1.0  // 可学习调整
    };
  }

  // ... 其他方法
}
```

#### 使用示例

```javascript
const scorer = new CostBenefitScorer();

const result = await scorer.score({
  name: "MID_COMPRESS",
  tokensConsumed: 5000,
  quality: 0.85,
  successRate: 0.92,
  executionTime: 150
}, {
  successRate: 0.88,
  userSatisfaction: 0.88,
  tokenCost: 0.0003  // $0.0003 per token
});

console.log(result);
/*
{
  strategyName: "MID_COMPRESS",
  cost: {
    value: 5550,
    breakdown: { tokens: 5000, qualityPenalty: 750, execution: 0.15 },
    totalTokens: 5000,
    totalExecutionTime: 150
  },
  benefit: {
    value: 99,
    breakdown: {
      quality: 85,
      successRate: 4,   // 92% - 88%
      userSatisfaction: 44
    },
    weight: 1.0
  },
  roi: 0.0178,
  riskScore: 0.15,
  finalScore: 0.54,
  details: {
    quality: 0.0095,
    successRate: 0.04,
    userSatisfaction: 0.49
  }
}
*/
```

**文件位置**: `core/cost-benefit-scorer.js`

---

### 3. 风险权重模型 (Risk Weight Model)

**功能描述**：
评估每个策略的风险，生成风险调整系数。

#### 风险模型

```typescript
interface RiskProfile {
  riskLevel: "LOW" | "MEDIUM" | "HIGH" | "CRITICAL";
  probability: number;       // 0-1
  impact: number;            // 0-1
  riskScore: number;         // 概率 × 影响度
  mitigation: string[];
  weight: number;            // 风险权重系数
  adjustedScore: number;     // 调整后的评分
}
```

#### 风险评估算法

```javascript
class RiskWeightModel {
  async assessRisk(strategy, context) {
    const risks = [];

    // 1. 技术风险
    const technicalRisk = await this.assessTechnicalRisk(strategy, context);
    risks.push(technicalRisk);

    // 2. 业务风险
    const businessRisk = await this.assessBusinessRisk(strategy, context);
    risks.push(businessRisk);

    // 3. 用户风险
    const userRisk = await this.assessUserRisk(strategy, context);
    risks.push(userRisk);

    // 4. 综合风险评估
    const combinedRisk = this.combineRisks(risks);

    return {
      riskLevel: this.determineRiskLevel(combinedRisk.riskScore),
      probability: combinedRisk.probability,
      impact: combinedRisk.impact,
      riskScore: combinedRisk.riskScore,
      breakdown: risks,
      mitigation: this.generateMitigation(strategy, context),
      weight: this.calculateRiskWeight(combinedRisk.riskScore),
      adjustedScore: combinedRisk.riskScore * this.calculateRiskWeight(combinedRisk.riskScore)
    };
  }

  async assessTechnicalRisk(strategy, context) {
    let probability = 0;
    let impact = 0;

    // 检查策略复杂度
    if (strategy.complexity > 0.7) {
      probability += 0.3;
      impact += 0.2;
    }

    // 检查是否依赖未知模块
    if (strategy.hasUnresolvedDependencies) {
      probability += 0.4;
      impact += 0.3;
    }

    // 检查历史成功率
    if (strategy.historySuccessRate < 0.7) {
      probability += 0.2;
      impact += 0.2;
    }

    return {
      category: "technical",
      probability,
      impact,
      description: "技术实现风险"
    };
  }

  async assessBusinessRisk(strategy, context) {
    let probability = 0;
    let impact = 0;

    // 检查业务影响
    if (strategy.hasBusinessImpact) {
      probability += 0.3;
      impact += 0.4;
    }

    // 检查业务流程依赖
    if (strategy.breaksBusinessFlow) {
      probability += 0.2;
      impact += 0.5;
    }

    return {
      category: "business",
      probability,
      impact,
      description: "业务流程风险"
    };
  }

  async assessUserRisk(strategy, context) {
    let probability = 0;
    let impact = 0;

    // 检查用户体验影响
    if (strategy.affectsUX) {
      probability += 0.2;
      impact += 0.3;
    }

    // 检查用户满意度影响
    if (strategy.decreasesSatisfaction) {
      probability += 0.1;
      impact += 0.4;
    }

    return {
      category: "user",
      probability,
      impact,
      description: "用户体验风险"
    };
  }

  combineRisks(risks) {
    const probability = risks.reduce((sum, r) => sum + r.probability, 0) / risks.length;
    const impact = risks.reduce((sum, r) => sum + r.impact, 0) / risks.length;

    return {
      probability,
      impact,
      riskScore: probability * impact
    };
  }

  // ... 其他方法
}
```

#### 风险等级定义

```javascript
const RISK_LEVELS = {
  LOW: {
    threshold: 0.1,
    color: "green",
    actions: ["proceed_with_caution"]
  },
  MEDIUM: {
    threshold: 0.3,
    color: "yellow",
    actions: ["mitigate_risk", "consider_alternatives"]
  },
  HIGH: {
    threshold: 0.5,
    color: "orange",
    actions: ["avoid", "implement_mitigation"]
  },
  CRITICAL: {
    threshold: 0.7,
    color: "red",
    actions: ["cancel", "emergency_planning"]
  }
};
```

#### 使用示例

```javascript
const riskModel = new RiskWeightModel();

const result = await riskModel.assessRisk({
  name: "AGGRESSIVE_COMPRESS",
  complexity: 0.85,
  hasUnresolvedDependencies: false,
  historySuccessRate: 0.75,
  hasBusinessImpact: false,
  breaksBusinessFlow: false,
  affectsUX: true,
  decreasesSatisfaction: true
}, {
  currentSuccessRate: 0.88,
  userSatisfaction: 0.88
});

console.log(result);
/*
{
  riskLevel: "MEDIUM",
  probability: 0.4,
  impact: 0.35,
  riskScore: 0.14,
  breakdown: [
    { category: "technical", probability: 0.5, impact: 0.4, description: "技术实现风险" },
    { category: "business", probability: 0, impact: 0, description: "业务流程风险" },
    { category: "user", probability: 0.3, impact: 0.3, description: "用户体验风险" }
  ],
  mitigation: [
    "Monitor user feedback closely",
    "Have rollback plan ready",
    "Start with small test group"
  ],
  weight: 0.14,
  adjustedScore: 0.0196
}
*/
```

**文件位置**: `core/risk-weight-model.js`

---

### 4. 自我博弈机制 (Self-Play Mechanism)

**功能描述**：
策略对决算法，学习最优策略。

#### 博弈逻辑

```javascript
class SelfPlayMechanism {
  constructor() {
    this.gameHistory = [];
    this.strategyStats = new Map();
  }

  async playMatch(strategyA, strategyB, rounds = 100) {
    const results = {
      strategyA: { wins: 0, losses: 0, draws: 0 },
      strategyB: { wins: 0, losses: 0, draws: 0 },
      matchResults: []
    };

    for (let i = 0; i < rounds; i++) {
      const result = await this.playRound(strategyA, strategyB);
      results.matchResults.push(result);

      if (result.winner === "A") {
        results.strategyA.wins++;
      } else if (result.winner === "B") {
        results.strategyB.wins++;
      } else {
        results.strategyA.draws++;
        results.strategyB.draws++;
      }
    }

    return {
      ...results,
      winner: this.determineWinner(results.strategyA, results.strategyB),
      learnings: this.extractLearnings(results)
    };
  }

  async playRound(strategyA, strategyB) {
    const scenario = await this.generateScenario();

    const resultA = await strategyA.execute(scenario);
    const resultB = await strategyB.execute(scenario);

    const scoreA = await this.calculateScore(resultA, scenario);
    const scoreB = await this.calculateScore(resultB, scenario);

    const winner = scoreA > scoreB ? "A" :
                   scoreB > scoreA ? "B" : "draw";

    return {
      round: results.matchResults.length + 1,
      scenario,
      resultA,
      resultB,
      scoreA,
      scoreB,
      winner
    };
  }

  async generateScenario() {
    // 生成测试场景
    return {
      complexity: Math.random(),
      contextLength: Math.random() * 50000,
      errorRate: Math.random(),
      // ... 其他场景参数
    };
  }

  async calculateScore(result, scenario) {
    // 评分标准
    return {
      quality: result.quality,
      successRate: result.successRate,
      userSatisfaction: result.userSatisfaction,
      efficiency: result.efficiency,
      finalScore: this.computeFinalScore({
        quality: result.quality,
        successRate: result.successRate,
        userSatisfaction: result.userSatisfaction,
        efficiency: result.efficiency
      })
    };
  }

  computeFinalScore(metrics) {
    const weights = {
      quality: 0.3,
      successRate: 0.3,
      userSatisfaction: 0.2,
      efficiency: 0.2
    };

    return (
      weights.quality * metrics.quality +
      weights.successRate * metrics.successRate +
      weights.userSatisfaction * metrics.userSatisfaction +
      weights.efficiency * metrics.efficiency
    );
  }

  determineWinner(statsA, statsB) {
    if (statsA.wins > statsB.wins) return "A";
    if (statsB.wins > statsA.wins) return "B";
    return "draw";
  }

  extractLearnings(results) {
    const learnings = [];

    // 分析胜率分布
    if (results.strategyA.wins > results.strategyB.wins) {
      learnings.push({
        strategy: "A",
        insight: "Proven to perform better in this context",
        evidence: results.strategyA.wins
      });
    }

    // 分析不同场景下的表现
    const scenarioByResult = this.groupByScenario(results.matchResults);

    // ... 提取学习见解

    return learnings;
  }

  // ... 其他方法
}
```

#### 策略注册

```javascript
class StrategyEngine {
  constructor() {
    this.strategies = new Map();
    this.selfPlay = new SelfPlayMechanism();
  }

  registerStrategy(strategy) {
    this.strategies.set(strategy.name, strategy);
  }

  async train(strategies, rounds = 100) {
    const allStrategies = Array.from(this.strategies.values());

    for (let i = 0; i < allStrategies.length; i++) {
      for (let j = i + 1; j < allStrategies.length; j++) {
        await this.selfPlay.playMatch(allStrategies[i], allStrategies[j], rounds);
      }
    }

    return this.selfPlay.getLearningResults();
  }

  selectBestStrategy(context) {
    // 评估所有策略
    const evaluations = [];

    for (const strategy of this.strategies.values()) {
      const evaluation = await this.evaluateStrategy(strategy, context);
      evaluations.push(evaluation);
    }

    // 选择最优策略
    const best = evaluations.sort((a, b) => b.finalScore - a.finalScore)[0];

    return {
      strategy: best.strategyName,
      score: best.finalScore,
      details: best
    };
  }
}
```

**文件位置**: `core/self-play-mechanism.js`

---

## 🔗 模块集成

### 集成到 Control Tower

```javascript
class EnhancedControlTower {
  constructor() {
    this.predictive = new PredictiveEngine();
    this.strategyEngine = new StrategyEngine();
    this.decisionLayer = new DecisionLayer();
    this.feedbackLayer = new FeedbackLayer();
  }

  async makeDecision(context) {
    // 1. 感知层：监控
    const currentState = this.predictive.getCurrentState(context);

    // 2. 预测层：风险评估
    const riskProfile = await this.predictive.evaluateRisk(currentState);

    // 3. 策略层：生成策略
    const strategies = await this.strategyEngine.generateStrategies(currentState);

    // 4. 决策层：选择最优策略
    const decision = await this.decisionLayer.makeDecision({
      currentState,
      strategies,
      riskProfile
    });

    // 5. 执行层：执行策略
    await this.executeStrategy(decision);

    // 6. 反馈层：追踪指标
    await this.feedbackLayer.track(decision);

    return decision;
  }
}
```

---

## 📊 性能指标

| 指标 | 目标值 | 当前值 | 状态 |
|------|--------|--------|------|
| 模拟延迟 | < 100ms | - | 📋 |
| 评分延迟 | < 50ms | - | 📋 |
| 风险评估延迟 | < 30ms | - | 📋 |
| 博弈训练延迟 | < 10s/回合 | - | 📋 |
| 策略选择延迟 | < 100ms | - | 📋 |

---

## 🧪 测试计划

### 单元测试

- 场景模拟器测试
- 成本收益评分器测试
- 风险权重模型测试
- 自我博弈机制测试

### 集成测试

- 策略层完整流程测试
- 与 Control Tower 集成测试
- 端到端决策测试

---

## 📚 文档

- `core/scenario-simulator.js` - 完整实现
- `core/cost-benefit-scorer.js` - 完整实现
- `core/risk-weight-model.js` - 完整实现
- `core/self-play-mechanism.js` - 完整实现
- `tests/strategy-engine.test.js` - 测试文件

---

## 🚀 实施顺序

1. **Week 1**:
   - Day 1-2: 场景模拟器
   - Day 3-4: 成本收益评分器
   - Day 5: 基础测试

2. **Week 2**:
   - Day 1-2: 风险权重模型
   - Day 3-4: 自我博弈机制
   - Day 5: 集成测试

---

**下一步**: 开始实施策略引擎？ 🎯
