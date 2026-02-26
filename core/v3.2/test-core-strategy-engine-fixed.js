/**
 * OpenClaw V3.2 - Core Strategy Engine 测试（修复版）
 * 测试核心策略引擎各模块功能
 *
 * @author OpenClaw V3.2
 * @date 2026-02-22
 */

const {
  CoreStrategyEngine,
  StrategyType
} = require('./core-strategy-engine');

const fs = require('fs');
const path = require('path');

// 测试配置
const testDataDir = path.join(__dirname, 'test-data');

// 清理测试数据
if (fs.existsSync(testDataDir)) {
  fs.rmSync(testDataDir, { recursive: true, force: true });
}
fs.mkdirSync(testDataDir, { recursive: true });

async function runTests() {
  console.log('═════════════════════════════════════════════════════════════');
  console.log('   OpenClaw V3.2 Core Strategy Engine 测试（修复版）');
  console.log('═════════════════════════════════════════════════════════════\n');

  let passedTests = 0;
  let failedTests = 0;
  let testsRun = 0;

  let engine, result, selected, learnings;
  let testMetrics, testContext, constraints;

  try {
    // 测试 1: 引擎初始化
    console.log('测试 1/10: 引擎初始化...');
    testsRun++;

    engine = new CoreStrategyEngine({
      riskWeight: 0.3,
      benefitWeight: 0.7,
      dataDir: testDataDir
    });

    if (engine && engine.name === 'CoreStrategyEngine') {
      console.log('✅ 引擎初始化成功\n');
      passedTests++;
    } else {
      console.log('❌ 引擎初始化失败\n');
      failedTests++;
    }

    // 测试 2: 策略类型枚举
    console.log('测试 2/10: 策略类型枚举...');
    testsRun++;

    if (Object.keys(StrategyType).length >= 4) {
      console.log(`✅ 策略类型枚举正确 (${Object.keys(StrategyType).length} 种)\n`);
      console.log('  策略类型:');
      Object.values(StrategyType).forEach(type => {
        const info = engine.config.strategyTypes[type];
        console.log(`    - ${type}: ${info?.label || 'N/A'} (${info?.desc || 'N/A'})`);
      });
      console.log();
      passedTests++;
    } else {
      console.log('❌ 策略类型枚举错误\n');
      failedTests++;
    }

    // 初始化测试数据
    testMetrics = {
      callsLastMinute: 10,
      successRate: 0.95,
      costRate: 0.9,
      delayRate: 0.9,
      compressionLevel: 1,
      remainingBudget: 150000,
      dailyBudget: 200000,
      currentCost: 1000,
      currentDelay: 200
    };

    testContext = {
      tokensRemaining: 70000,
      tokensTotal: 200000,
      compressionLevel: 1
    };

    constraints = {
      maxDelay: 500
    };

    // 测试 3: 保守型策略生成
    console.log('测试 3/10: 保守型策略生成...');
    testsRun++;

    try {
      result = await engine.generateAndSelectStrategy(testMetrics, testContext, constraints);
      selected = result.selected;

      if (result && selected && selected.type === StrategyType.CONSERVATIVE) {
        console.log('✅ 保守型策略生成成功\n');
        console.log(`  策略类型: ${selected.label}`);
        console.log(`  延迟: ${selected.delay}ms`);
        console.log(`  压缩等级: ${selected.compressionLevel}`);
        console.log(`  模型偏置: ${selected.modelBias}`);
        console.log(`  估算成本: ${selected.estimatedCost}`);
        console.log(`  预期成功率: ${(selected.expectedSuccessRate * 100).toFixed(2)}%`);
        console.log(`  风险等级: ${selected.risk.level}`);
        console.log(`  综合得分: ${selected.combinedScore.toFixed(2)}`);
        console.log();
        passedTests++;
      } else {
        console.log('❌ 保守型策略生成失败\n');
        console.log('  结果:', JSON.stringify(result, null, 2));
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 保守型策略生成失败: ${error.message}\n`);
      console.log(error.stack);
      failedTests++;
    }

    // 测试 4: 激进型策略生成
    console.log('测试 4/10: 激进型策略生成...');
    testsRun++;

    try {
      // 高压场景
      const highPressureMetrics = {
        callsLastMinute: 90,
        successRate: 0.9,
        costRate: 0.95,
        delayRate: 0.95,
        compressionLevel: 1,
        remainingBudget: 180000,
        dailyBudget: 200000,
        currentCost: 1000,
        currentDelay: 200
      };

      const highPressureContext = {
        tokensRemaining: 40000,
        tokensTotal: 200000,
        compressionLevel: 1
      };

      result = await engine.generateAndSelectStrategy(highPressureMetrics, highPressureContext, constraints);
      selected = result.selected;

      if (result && selected && selected.type === StrategyType.AGGRESSIVE) {
        console.log('✅ 激进型策略生成成功\n');
        console.log(`  策略类型: ${selected.label}`);
        console.log(`  延迟: ${selected.delay}ms`);
        console.log(`  压缩等级: ${selected.compressionLevel}`);
        console.log(`  模型偏置: ${selected.modelBias}`);
        console.log(`  估算成本: ${selected.estimatedCost}`);
        console.log(`  预期成功率: ${(selected.expectedSuccessRate * 100).toFixed(2)}%`);
        console.log(`  风险等级: ${selected.risk.level}`);
        console.log();
        passedTests++;
      } else {
        console.log('❌ 激进型策略生成失败\n');
        console.log('  结果:', JSON.stringify(result, null, 2));
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 激进型策略生成失败: ${error.message}\n`);
      console.log(error.stack);
      failedTests++;
    }

    // 测试 5: 平衡型策略生成
    console.log('测试 5/10: 平衡型策略生成...');
    testsRun++;

    try {
      const balancedMetrics = {
        callsLastMinute: 20,
        successRate: 0.95,
        costRate: 0.85,
        delayRate: 0.85,
        compressionLevel: 0,
        remainingBudget: 150000,
        dailyBudget: 200000,
        currentCost: 1000,
        currentDelay: 200
      };

      const balancedContext = {
        tokensRemaining: 100000,
        tokensTotal: 200000,
        compressionLevel: 0
      };

      result = await engine.generateAndSelectStrategy(balancedMetrics, balancedContext, constraints);
      selected = result.selected;

      if (result && selected && selected.type === StrategyType.BALANCED) {
        console.log('✅ 平衡型策略生成成功\n');
        console.log(`  策略类型: ${selected.label}`);
        console.log(`  延迟: ${selected.delay}ms`);
        console.log(`  压缩等级: ${selected.compressionLevel}`);
        console.log(`  模型偏置: ${selected.modelBias}`);
        console.log(`  估算成本: ${selected.estimatedCost}`);
        console.log(`  预期成功率: ${(selected.expectedSuccessRate * 100).toFixed(2)}%`);
        console.log(`  风险等级: ${selected.risk.level}`);
        console.log(`  综合得分: ${selected.combinedScore.toFixed(2)}`);
        console.log();
        passedTests++;
      } else {
        console.log('❌ 平衡型策略生成失败\n');
        console.log('  结果:', JSON.stringify(result, null, 2));
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 平衡型策略生成失败: ${error.message}\n`);
      console.log(error.stack);
      failedTests++;
    }

    // 测试 6: 成本收益评估
    console.log('测试 6/10: 成本收益评估...');
    testsRun++;

    try {
      result = await engine.generateAndSelectStrategy(testMetrics, testContext, constraints);
      selected = result.selected;

      if (selected.benefit && selected.benefit.totalScore >= 0 && selected.benefit.totalScore <= 100) {
        console.log('✅ 成本收益评估成功\n');
        console.log(`  总分: ${selected.benefit.totalScore.toFixed(2)}`);
        console.log(`  收益详情:`);
        console.log(`    - 成功率增益: ${selected.benefit.details.successRateGain.toFixed(4)}`);
        console.log(`    - 成本减少: ${selected.benefit.details.costReduction.toFixed(4)}`);
        console.log(`    - 延迟改善: ${selected.benefit.details.delayImprovement.toFixed(4)}`);
        console.log(`    - 压缩改善: ${selected.benefit.details.compressionImprovement.toFixed(4)}`);
        console.log(`    - 模型得分: ${selected.benefit.details.modelScore.toFixed(4)}`);
        console.log();
        passedTests++;
      } else {
        console.log('❌ 成本收益评估失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 成本收益评估失败: ${error.message}\n`);
      console.log(error.stack);
      failedTests++;
    }

    // 测试 7: 风险评估
    console.log('测试 7/10: 风险评估...');
    testsRun++;

    try {
      result = await engine.generateAndSelectStrategy(testMetrics, testContext, constraints);
      selected = result.selected;

      if (selected.risk && selected.risk.score >= 0 && selected.risk.score <= 100) {
        console.log('✅ 风险评估成功\n');
        console.log(`  风险分数: ${selected.risk.score.toFixed(2)}`);
        console.log(`  风险等级: ${selected.risk.level}`);
        console.log(`  风险详情:`);
        console.log(`    - 成功率风险: ${selected.risk.details.successRateRisk.toFixed(4)}`);
        console.log(`    - 成本比率: ${selected.risk.details.costRatio.toFixed(4)}`);
        console.log(`    - 延迟比率: ${selected.risk.details.delayRatio.toFixed(4)}`);
        console.log(`    - 压缩等级: ${selected.risk.details.compression}`);
        console.log();
        passedTests++;
      } else {
        console.log('❌ 风险评估失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 风险评估失败: ${error.message}\n`);
      console.log(error.stack);
      failedTests++;
    }

    // 测试 8: 约束检查
    console.log('测试 8/10: 约束检查...');
    testsRun++;

    try {
      const maxDelayConstraint = {
        maxDelay: 100
      };

      result = await engine.generateAndSelectStrategy(testMetrics, testContext, maxDelayConstraint);
      selected = result.selected;

      if (selected && selected.delay <= 100) {
        console.log('✅ 约束检查成功\n');
        console.log(`  延迟: ${selected.delay}ms (约束: ≤100ms)`);
        console.log();
        passedTests++;
      } else {
        console.log('❌ 约束检查失败\n');
        console.log(`  结果延迟: ${selected?.delay}ms, 约束: 100ms`);
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 约束检查失败: ${error.message}\n`);
      console.log(error.stack);
      failedTests++;
    }

    // 测试 9: 学习数据持久化
    console.log('测试 9/10: 学习数据持久化...');
    testsRun++;

    try {
      result = await engine.generateAndSelectStrategy(testMetrics, testContext, constraints);
      learnings = engine.getAllLearnings();

      if (learnings.length > 0 && fs.existsSync(path.join(testDataDir, 'strategy-engine-learnings.json'))) {
        console.log('✅ 学习数据持久化成功\n');
        console.log(`  学习记录数: ${learnings.length}`);
        console.log(`  文件已创建: ${path.join(testDataDir, 'strategy-engine-learnings.json')}`);
        console.log();
        passedTests++;
      } else {
        console.log('❌ 学习数据持久化失败\n');
        console.log(`  学习记录数: ${learnings.length}`);
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 学习数据持久化失败: ${error.message}\n`);
      console.log(error.stack);
      failedTests++;
    }

    // 测试 10: 学习数据读取
    console.log('测试 10/10: 学习数据读取...');
    testsRun++;

    try {
      result = await engine.generateAndSelectStrategy(testMetrics, testContext, constraints);
      learnings = engine.getAllLearnings();

      if (learnings.length > 0) {
        const latest = learnings[learnings.length - 1];

        console.log('✅ 学习数据读取成功\n');
        console.log(`  最新策略类型: ${latest.strategy.type}`);
        console.log(`  最新策略标签: ${latest.strategy.label}`);
        console.log(`  选择理由: ${latest.selectionReason}`);
        console.log();
        passedTests++;
      } else {
        console.log('❌ 学习数据读取失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 学习数据读取失败: ${error.message}\n`);
      console.log(error.stack);
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
  console.log(`  测试数: ${testsRun}`);
  console.log(`  通过: ${passedTests}`);
  console.log(`  失败: ${failedTests}`);
  console.log(`  通过率: ${((passedTests / testsRun) * 100).toFixed(1)}%`);
  console.log('═════════════════════════════════════════════════════════════\n');

  if (failedTests === 0) {
    console.log('🎉 所有测试通过！');
  } else {
    console.log('⚠️  部分测试失败，请检查错误信息。');
  }

  // 清理测试数据
  if (fs.existsSync(testDataDir)) {
    fs.rmSync(testDataDir, { recursive: true, force: true });
    console.log('\n🗑️  已清理测试数据');
  }
}

// 运行测试
runTests().catch(console.error);
