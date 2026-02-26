/**
 * OpenClaw 3.3 - 策略引擎增强完整测试
 * 测试所有模块：场景模拟器、成本收益评分器、ROI分析器
 * 
 * @version 3.3.0
 * @author OpenClaw V3.3
 * @date 2026-02-22
 */

const StrategyEngineEnhanced = require('../strategy-engine-enhanced');

async function runTests() {
  console.log('═════════════════════════════════════════════════════════════');
  console.log('   OpenClaw 3.3 - 策略引擎增强测试');
  console.log('   Phase 3.3-1: 场景模拟器 + 成本收益评分');
  console.log('═════════════════════════════════════════════════════════════\n');

  let passedTests = 0;
  let failedTests = 0;
  let testsRun = 0;

  try {
    // 测试1: 策略引擎初始化
    console.log('测试 1/10: StrategyEngineEnhanced 初始化...');
    testsRun++;

    try {
      const engine = new StrategyEngineEnhanced({
        scenarioCount: 3,
        costWeight: {
          token: 0.3,
          time: 0.25,
          resource: 0.2,
          risk: 0.25
        }
      });

      if (engine && engine.name === 'StrategyEngineEnhanced') {
        console.log('✅ StrategyEngineEnhanced 初始化成功\n');
        passedTests++;
      } else {
        console.log('❌ StrategyEngineEnhanced 初始化失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ StrategyEngineEnhanced 初始化失败: ${error.message}\n`);
      failedTests++;
    }

    // 测试2: 场景生成器
    console.log('测试 2/10: 场景生成器...');
    testsRun++;

    try {
      const engine = new StrategyEngineEnhanced();
      const scenarios = await engine.scenarioGenerator.generateScenarios({}, 3);

      if (scenarios && scenarios.length > 0) {
        console.log(`✅ 场景生成器成功生成 ${scenarios.length} 个场景\n`);
        passedTests++;

        // 测试场景结构
        scenarios.forEach((scenario, i) => {
          console.log(`   场景 ${i + 1}: ${scenario.name}`);
          console.log(`     策略: ${scenario.strategyType}`);
          console.log(`     描述: ${scenario.description}`);
        });
      } else {
        console.log('❌ 场景生成器未生成场景\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 场景生成器失败: ${error.message}\n`);
      failedTests++;
    }

    // 测试3: 场景评估器
    console.log('测试 3/10: 场景评估器...');
    testsRun++;

    try {
      const engine = new StrategyEngineEnhanced();
      const scenarios = await engine.scenarioGenerator.generateScenarios({}, 2);
      const evaluatedScenarios = await engine.scenarioEvaluator.evaluateScenarios(scenarios, {});

      if (evaluatedScenarios && evaluatedScenarios.length > 0) {
        console.log(`✅ 场景评估器成功评估 ${evaluatedScenarios.length} 个场景\n`);
        passedTests++;

        // 测试评估数据
        evaluatedScenarios.forEach((scenario, i) => {
          console.log(`   场景 ${i + 1}: ${scenario.name}`);
          console.log(`     成本: ${scenario.cost.toFixed(2)}`);
          console.log(`     收益: ${scenario.benefit.toFixed(2)}`);
          console.log(`     ROI: ${scenario.roi.toFixed(2)}`);
          console.log(`     优先级评分: ${scenario.priorityScore.toFixed(2)}`);
        });
      } else {
        console.log('❌ 场景评估器未评估场景\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 场景评估器失败: ${error.message}\n`);
      failedTests++;
    }

    // 测试4: 成本计算器
    console.log('测试 4/10: 成本计算器...');
    testsRun++;

    try {
      const engine = new StrategyEngineEnhanced();
      const scenarios = await engine.scenarioGenerator.generateScenarios({}, 1);
      const cost = engine.costCalculator.calculateTotalCost(scenarios[0], {});

      if (cost && cost.totalCost > 0) {
        console.log(`✅ 成本计算器成功计算成本: ${cost.totalCost.toFixed(2)}\n`);
        passedTests++;

        console.log('   成本明细:');
        console.log(`     Token成本: ${cost.tokenCost.toFixed(2)}`);
        console.log(`     时间成本: ${cost.timeCost.toFixed(2)}`);
        console.log(`     资源成本: ${cost.resourceCost.toFixed(2)}`);
        console.log(`     风险成本: ${cost.riskCost.toFixed(2)}`);
      } else {
        console.log('❌ 成本计算器计算失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 成本计算器失败: ${error.message}\n`);
      failedTests++;
    }

    // 测试5: 收益计算器
    console.log('测试 5/10: 收益计算器...');
    testsRun++;

    try {
      const engine = new StrategyEngineEnhanced();
      const scenarios = await engine.scenarioGenerator.generateScenarios({}, 1);
      const benefit = engine.benefitCalculator.calculateTotalBenefit(scenarios[0], {});

      if (benefit && benefit.totalBenefit > 0) {
        console.log(`✅ 收益计算器成功计算收益: ${benefit.totalBenefit.toFixed(2)}\n`);
        passedTests++;

        console.log('   收益明细:');
        console.log(`     成功率收益: ${benefit.successBenefit.toFixed(2)}`);
        console.log(`     效率收益: ${benefit.efficiencyBenefit.toFixed(2)}`);
        console.log(`     用户满意度收益: ${benefit.satisfactionBenefit.toFixed(2)}`);
        console.log(`     长期收益: ${benefit.longTermBenefit.toFixed(2)}`);
      } else {
        console.log('❌ 收益计算器计算失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 收益计算器失败: ${error.message}\n`);
      failedTests++;
    }

    // 测试6: ROI分析器
    console.log('测试 6/10: ROI分析器...');
    testsRun++;

    try {
      const engine = new StrategyEngineEnhanced();
      const scenarios = await engine.scenarioGenerator.generateScenarios({}, 2);
      const evaluatedScenarios = await engine.scenarioEvaluator.evaluateScenarios(scenarios, {});

      const roiResults = evaluatedScenarios.map(s => engine.roiAnalyzer.calculateROI(s));
      const optimalScenario = engine.roiAnalyzer.selectOptimalScenario(evaluatedScenarios);

      if (optimalScenario && optimalScenario.name) {
        console.log(`✅ ROI分析器成功选择最优策略: ${optimalScenario.name}\n`);
        passedTests++;

        console.log('   ROI分析结果:');
        console.log(`     ROI: ${optimalScenario.roi.toFixed(2)}`);
        console.log(`     优先级评分: ${optimalScenario.priorityScore.toFixed(2)}`);
        console.log(`     ROI等级: ${optimalScenario.roiGrade}`);
      } else {
        console.log('❌ ROI分析器选择失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ ROI分析器失败: ${error.message}\n`);
      failedTests++;
    }

    // 测试7: 风险评估器
    console.log('测试 7/10: 风险评估器...');
    testsRun++;

    try {
      const engine = new StrategyEngineEnhanced();
      const scenarios = await engine.scenarioGenerator.generateScenarios({}, 1);
      const evaluatedScenarios = await engine.scenarioEvaluator.evaluateScenarios(scenarios, {});

      const riskAssessment = engine.riskAssessor.assessRisk(evaluatedScenarios[0]);

      if (riskAssessment !== undefined && riskAssessment >= 0 && riskAssessment <= 1) {
        console.log(`✅ 风险评估器成功评估风险: ${riskAssessment.toFixed(3)}\n`);
        passedTests++;
      } else {
        console.log('❌ 风险评估器评估失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 风险评估器失败: ${error.message}\n`);
      failedTests++;
    }

    // 测试8: 风险控制器
    console.log('测试 8/10: 风险控制器...');
    testsRun++;

    try {
      const engine = new StrategyEngineEnhanced();
      const scenarios = await engine.scenarioGenerator.generateScenarios({}, 1);
      const evaluatedScenarios = await engine.scenarioEvaluator.evaluateScenarios(scenarios, {});

      const riskAssessment = engine.riskAssessor.assessRisk(evaluatedScenarios[0]);
      const riskControl = engine.riskController.controlRisk(evaluatedScenarios[0], riskAssessment, {});

      if (riskControl) {
        console.log(`✅ 风险控制器成功控制风险: ${riskControl.method}\n`);
        passedTests++;

        console.log('   风险控制详情:');
        console.log(`     方法: ${riskControl.method}`);
        console.log(`     详细信息: ${riskControl.details}`);
      } else {
        console.log('❌ 风险控制器失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 风险控制器失败: ${error.message}\n`);
      failedTests++;
    }

    // 测试9: 风险调整评分器
    console.log('测试 9/10: 风险调整评分器...');
    testsRun++;

    try {
      const engine = new StrategyEngineEnhanced();
      const scenarios = await engine.scenarioGenerator.generateScenarios({}, 1);
      const evaluatedScenarios = await engine.scenarioEvaluator.evaluateScenarios(scenarios, {});

      const riskAssessment = engine.riskAssessor.assessRisk(evaluatedScenarios[0]);
      const riskAdjustedScore = engine.riskAdjustedScorer.calculateRiskAdjustedScore(
        evaluatedScenarios[0],
        riskAssessment
      );

      if (riskAdjustedScore !== undefined) {
        console.log(`✅ 风险调整评分器成功计算: ${riskAdjustedScore.toFixed(3)}\n`);
        passedTests++;
      } else {
        console.log('❌ 风险调整评分器计算失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 风险调整评分器失败: ${error.message}\n`);
      failedTests++;
    }

    // 测试10: 完整战略决策流程
    console.log('测试 10/10: 完整战略决策流程...');
    testsRun++;

    try {
      const engine = new StrategyEngineEnhanced();
      const decisionContext = {
        urgency: 'HIGH',
        priority: 'HIGH',
        successRate: 'HIGH',
        efficiency: 'HIGH',
        longTerm: 'HIGH'
      };

      const decisionReport = await engine.strategicDecision(decisionContext);

      if (decisionReport && decisionReport.summary) {
        console.log('✅ 完整战略决策流程成功\n');
        passedTests++;

        console.log('   决策摘要:');
        console.log(`     总策略数: ${decisionReport.summary.totalScenarios}`);
        console.log(`     评估后策略: ${decisionReport.summary.evaluatedScenarios}`);
        console.log(`     最优策略: ${decisionReport.summary.optimalScenario}`);
        console.log(`     预期ROI: ${decisionReport.summary.expectedROI}`);
      } else {
        console.log('❌ 完整战略决策流程失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 完整战略决策流程失败: ${error.message}\n`);
      failedTests++;
    }

  } catch (error) {
    console.error(`❌ 测试过程中发生错误: ${error.message}`);
    console.error(error.stack);
    failedTests++;
  }

  // 测试总结
  console.log('═════════════════════════════════════════════════════════════');
  console.log('   测试总结');
  console.log('═════════════════════════════════════════════════════════════');
  console.log(`  测试数: ${testsRun}`);
  console.log(`  通过: ${passedTests}`);
  console.log(`  失败: ${failedTests}`);
  console.log(`  通过率: ${((passedTests / testsRun) * 100).toFixed(1)}%`);
  console.log('═════════════════════════════════════════════════════════════\n');

  if (failedTests === 0) {
    console.log('🎉 所有测试通过！');
    console.log('✨ Phase 3.3-1: 场景模拟器 + 成本收益评分 - 完成！');
  } else {
    console.log('⚠️  部分测试失败，需要修复');
  }
}

// 运行测试
runTests().catch(console.error);
