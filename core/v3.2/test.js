/**
 * OpenClaw V3.2 - 策略引擎测试
 * 测试策略引擎各模块功能
 *
 * @author OpenClaw V3.2
 * @date 2026-02-21
 */

const StrategyEngine = require('./strategy-engine');
const {
  ExampleStrategy,
  MidCompressionStrategy,
  AggressiveCompressionStrategy,
  ModelChangeStrategy,
  DelayStrategy
} = require('./example-strategy');

async function runTests() {
  console.log('═════════════════════════════════════════════════════════════');
  console.log('   OpenClaw V3.2 策略引擎测试');
  console.log('═════════════════════════════════════════════════════════════\n');

  let passedTests = 0;
  let failedTests = 0;

  try {
    // 测试 1: 策略注册
    console.log('测试 1/6: 策略注册...');
    const engine = new StrategyEngine({
      timeHorizon: 5,
      roundsPerMatch: 10
    });

    engine.registerStrategy(new ExampleStrategy());
    engine.registerStrategy(new MidCompressionStrategy());
    engine.registerStrategy(new AggressiveCompressionStrategy());

    const strategies = engine.getAllStrategies();
    if (strategies.length === 3) {
      console.log('✅ 策略注册成功\n');
      passedTests++;
    } else {
      console.log('❌ 策略注册失败\n');
      failedTests++;
    }

    // 测试 2: 场景模拟
    console.log('测试 2/6: 场景模拟...');
    const context = {
      tokensRemaining: 70000,
      tokensTotal: 200000,
      errorRate: 0.05,
      successRate: 0.88,
      callsLastMinute: 8,
      tokensLastUsed: 6000
    };

    try {
      const simulation = await engine.scenarioSimulator.simulate({
        currentState: engine.extractCurrentState(context),
        strategies: strategies,
        timeHorizon: 5
      });

      if (simulation.scenarios.length === 3) {
        console.log('✅ 场景模拟成功\n');
        passedTests++;
      } else {
        console.log('❌ 场景模拟失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 场景模拟失败: ${error.message}\n`);
      failedTests++;
    }

    // 测试 3: 成本收益评分
    console.log('测试 3/6: 成本收益评分...');
    try {
      const scoredStrategies = await engine.costBenefitScorer.batchScore(
        strategies,
        context
      );

      if (scoredStrategies.length === 3) {
        console.log(`✅ 成本收益评分成功，共 ${scoredStrategies.length} 个策略\n`);
        passedTests++;

        // 显示评分结果
        scoredStrategies.forEach((s, i) => {
          console.log(`  策略 ${i + 1}: ${s.strategyName}`);
          console.log(`    - 得分: ${s.finalScore.toFixed(4)}`);
          console.log(`    - ROI: ${s.roi.toFixed(4)}`);
          const riskLevel = s.riskProfile?.riskLevel || 'UNKNOWN';
          console.log(`    - 风险等级: ${riskLevel}`);
          console.log(`    - 成本: $${s.cost.totalCostUsd.toFixed(4)}\n`);
        });
      } else {
        console.log('❌ 成本收益评分失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 成本收益评分失败: ${error.message}\n`);
      failedTests++;
    }

    // 测试 4: 风险评估
    console.log('测试 4/6: 风险评估...');
    try {
      const riskProfiles = await engine.riskWeightModel.batchAssessRisk(
        strategies,
        context
      );

      if (riskProfiles.length === 3) {
        console.log(`✅ 风险评估成功，共 ${riskProfiles.length} 个策略\n`);
        passedTests++;

        riskProfiles.forEach((profile, i) => {
          console.log(`  策略 ${i + 1}: ${profile.breakdown[0].description}`);
          console.log(`    - 风险等级: ${profile.riskLevel}`);
          console.log(`    - 风险分数: ${profile.riskScore.toFixed(4)}`);
          console.log(`    - 概率: ${profile.probability.toFixed(4)}\n`);
        });
      } else {
        console.log('❌ 风险评估失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 风险评估失败: ${error.message}\n`);
      failedTests++;
    }

    // 测试 5: 策略生成
    console.log('测试 5/6: 策略生成...');
    try {
      const decision = await engine.generateStrategies(context);

      if (decision.finalRecommendation) {
        console.log('✅ 策略生成成功\n');
        passedTests++;

        console.log('最终建议:');
        console.log(`  策略: ${decision.finalRecommendation.strategyName}`);
        console.log(`  得分: ${decision.finalRecommendation.score.toFixed(4)}`);
        console.log(`  ROI: ${decision.finalRecommendation.roi.toFixed(4)}`);
        console.log(`  风险等级: ${decision.finalRecommendation.riskLevel}`);
        console.log(`  成本: $${decision.finalRecommendation.cost.totalCostUsd.toFixed(4)}`);
        console.log(`  执行时间: ${decision.executionTime}ms`);
        console.log(`  理由数量: ${decision.finalRecommendation.reasons.length}`);

        console.log('\n建议理由:');
        decision.finalRecommendation.reasons.forEach((reason, i) => {
          console.log(`  ${i + 1}. [${reason.type}] ${reason.message}`);
        });
      } else {
        console.log('❌ 策略生成失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 策略生成失败: ${error.message}\n`);
      failedTests++;
    }

    // 测试 6: 策略执行
    console.log('测试 6/6: 策略执行...');
    try {
      const execution = await engine.executeStrategy('ExampleStrategy', context);

      if (execution.strategyName === 'ExampleStrategy') {
        console.log('✅ 策略执行成功\n');
        passedTests++;

        console.log('执行结果:');
        console.log(`  质量评分: ${execution.result.quality.toFixed(4)}`);
        console.log(`  成功率: ${execution.result.successRate.toFixed(4)}`);
        console.log(`  用户满意度: ${execution.result.userSatisfaction.toFixed(4)}`);
        console.log(`  效率: ${execution.result.efficiency.toFixed(4)}`);
        console.log(`  执行时间: ${execution.executionTime}ms`);
      } else {
        console.log('❌ 策略执行失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 策略执行失败: ${error.message}\n`);
      failedTests++;
    }

  } catch (error) {
    console.log(`❌ 测试过程中发生错误: ${error.message}`);
    console.log(error.stack);
    failedTests++;
  }

  // 测试总结
  console.log('═════════════════════════════════════════════════════════════');
  console.log('   测试总结');
  console.log('═════════════════════════════════════════════════════════════');
  console.log(`  通过: ${passedTests}/6`);
  console.log(`  失败: ${failedTests}/6`);
  console.log(`  通过率: ${((passedTests / 6) * 100).toFixed(1)}%`);
  console.log('═════════════════════════════════════════════════════════════\n');

  if (failedTests === 0) {
    console.log('🎉 所有测试通过！');
  } else {
    console.log('⚠️  部分测试失败，请检查错误信息。');
  }
}

// 运行测试
runTests().catch(console.error);
