{
  "timestamp": "2026-03-05T01:36:17.649Z",
  "overview": "方法名统一规范",
  "modules": {
    "cost-calculator": {
      "calculate": "estimateCost",
      "calculateCost": "calculateTotalCost"
    },
    "benefit-calculator": {
      "calculateBenefit": "calculateTotalBenefit"
    },
    "risk-assessor": {
      "assess": "assessRisk",
      "getRisk": "getRiskLevel"
    },
    "risk-controller": {
      "control": "controlRisk",
      "selectRiskControl": "selectRiskControlMethod"
    },
    "risk-adjusted-scorer": {
      "calculate": "calculateRiskAdjustedScore"
    },
    "adversary-simulator": {
      "simulate": "simulateAdversary",
      "generateScenarios": "generateAdversaryScenarios"
    },
    "multi-perspective-evaluator": {
      "evaluate": "evaluatePerspectives",
      "evaluateScenario": "evaluatePerspectives"
    },
    "scenario-generator": {
      "generateScenarios": "generateScenarios",
      "createScenario": "createScenario"
    },
    "scenario-evaluator": {
      "evaluateScenario": "evaluateScenario",
      "calculate": "calculateCostBenefitScore"
    }
  },
  "parameterStructures": {
    "generateScenarios": {
      "require": [
        "strategies",
        "count"
      ]
    },
    "evaluateScenario": {
      "require": [
        "strategyType",
        "cost",
        "benefit",
        "risk"
      ]
    },
    "assessRisk": {
      "require": [
        "riskFactors"
      ]
    },
    "controlRisk": {
      "require": [
        "riskLevel",
        "action"
      ]
    }
  },
  "recommendations": [
    "所有公共方法使用 camelCase 或 snake_case，保持一致",
    "方法参数使用明确的类型和默认值",
    "所有方法返回结构化的结果对象",
    "添加错误处理和参数验证",
    "提供清晰的文档注释"
  ]
}