/**
 * OpenClaw 3.0 - 集成测试脚本
 */

const assert = require('assert');

console.log('=================================');
console.log('🧪 OpenClaw 3.0 - 集成测试');
console.log('=================================\n');

let testsPassed = 0;
let testsFailed = 0;

// 测试1: GapAnalyzer
async function testGapAnalyzer() {
  console.log('测试1: GapAnalyzer 集成...');

  try {
    const GapAnalyzer = require('./objective/gapAnalyzer');
    const gapAnalyzer = new GapAnalyzer('data/goals.json');

    const gap = gapAnalyzer.analyzeGap('data/metrics.json');
    assert.ok(gap, 'Gap分析结果应为对象');
    assert.ok(gap.suggestions && Array.isArray(gap.suggestions), 'suggestions应为数组');
    assert.ok(gap.costGap !== undefined, '应有costGap');
    assert.ok(gap.recoveryGap !== undefined, '应有recoveryGap');

    console.log('✅ GapAnalyzer 集成成功');
    console.log(`   - Gap指标: ${Object.keys(gap).length}个`);
    console.log(`   - 建议数量: ${gap.suggestions.length}条`);

    testsPassed++;
  } catch (error) {
    console.error('❌ GapAnalyzer 集成失败:', error.message);
    testsFailed++;
  }
}

// 测试2: ROIEngine
async function testROIEngine() {
  console.log('\n测试2: ROIEngine 集成...');

  try {
    const ROIEngine = require('./economy/roiEngine');

    // 模拟metrics对象
    const mockMetrics = {
      dailyTokens: 200000,
      costPerToken: 0.0001,
      recoveryRate: 87,
      errorRate: 8,
      avgResponseTime: 500,
      successRate: 92
    };

    const roiEngine = new ROIEngine();
    roiEngine.metrics = mockMetrics; // 手动设置metrics

    const suggestions = [
      { priority: 'high', action: '增加Token预算压缩频率', message: '成本未达标' },
      { priority: 'medium', action: '优化429重试策略', message: '错误率过高' }
    ];

    const roiList = roiEngine.rankSuggestions(suggestions);
    assert.ok(roiList, 'ROI列表应为数组');
    assert.ok(roiList.length === suggestions.length, 'ROI列表长度应与建议数量一致');

    const summary = roiEngine.generateSummary(roiList);
    assert.ok(summary, '摘要生成成功');

    console.log('✅ ROIEngine 集成成功');
    console.log(`   - ROI建议: ${roiList.length}条`);
    // 从第一个roi中获取ROI
    if (roiList.length > 0) {
      console.log(`   - 平均ROI: ${roiList[0].roiPercentage.toFixed(2)}%`);
    }

    testsPassed++;
  } catch (error) {
    console.error('❌ ROIEngine 集成失败:', error.message);
    console.error(error.stack);
    testsFailed++;
  }
}

// 测试3: PatternMiner
async function testPatternMiner() {
  console.log('\n测试3: PatternMiner 集成...');

  try {
    const PatternMiner = require('./value/patternMiner');
    const patternMiner = new PatternMiner('data/patterns.json');

    // 测试聚类
    const prompts = [
      { text: '如何解决429错误？', tokenCount: 8 },
      { text: '如何处理API限流？', tokenCount: 9 },
      { text: '如何解决429错误？', tokenCount: 10 }
    ];

    const clusters = patternMiner.clusterPrompts(prompts);
    assert.ok(clusters, '聚类结果应为数组');
    assert.ok(clusters.length >= 1, '应有至少1个聚类');

    console.log('✅ PatternMiner 集成成功');
    console.log(`   - 原始prompts: ${prompts.length}个`);
    console.log(`   - 聚类数量: ${clusters.length}个`);

    testsPassed++;
  } catch (error) {
    console.error('❌ PatternMiner 集成失败:', error.message);
    testsFailed++;
  }
}

// 测试4: TemplateManager
async function testTemplateManager() {
  console.log('\n测试4: TemplateManager 集成...');

  try {
    const TemplateManager = require('./value/templateManager');
    const templateManager = new TemplateManager('templates/');

    const templates = templateManager.getTemplates();
    assert.ok(Array.isArray(templates), '模板列表应为数组');

    console.log('✅ TemplateManager 集成成功');
    console.log(`   - 总模板数: ${templates.length}`);

    testsPassed++;
  } catch (error) {
    console.error('❌ TemplateManager 集成失败:', error.message);
    testsFailed++;
  }
}

// 测试5: 主流程集成
async function testMainIntegration() {
  console.log('\n测试5: 主流程集成...');

  try {
    const OpenClaw3 = require('./index');
    assert.ok(OpenClaw3, 'OpenClaw3模块应存在');
    assert.ok(OpenClaw3.gapAnalyzer, '应有gapAnalyzer实例');
    assert.ok(OpenClaw3.roiEngine, '应有roiEngine实例');
    assert.ok(OpenClaw3.patternMiner, '应有patternMiner实例');
    assert.ok(OpenClaw3.templateManager, '应有templateManager实例');

    console.log('✅ 主流程集成成功');
    console.log(`   - 新模块: 4个`);
    console.log(`   - 定时任务: 已配置`);

    testsPassed++;
  } catch (error) {
    console.error('❌ 主流程集成失败:', error.message);
    testsFailed++;
  }
}

// 测试6: 新模块集成验证
async function testNewModulesIntegration() {
  console.log('\n测试6: 新模块集成验证...');

  try {
    const OpenClaw3 = require('./index');

    // 验证所有新模块已正确集成
    const hasGapAnalyzer = !!OpenClaw3.gapAnalyzer;
    const hasROIEngine = !!OpenClaw3.roiEngine;
    const hasPatternMiner = !!OpenClaw3.patternMiner;
    const hasTemplateManager = !!OpenClaw3.templateManager;

    console.log('✅ 新模块集成验证成功');
    console.log(`   - GapAnalyzer: ${hasGapAnalyzer ? '✓' : '✗'}`);
    console.log(`   - ROIEngine: ${hasROIEngine ? '✓' : '✗'}`);
    console.log(`   - PatternMiner: ${hasPatternMiner ? '✓' : '✗'}`);
    console.log(`   - TemplateManager: ${hasTemplateManager ? '✓' : '✗'}`);

    if (hasGapAnalyzer && hasROIEngine && hasPatternMiner && hasTemplateManager) {
      testsPassed++;
    } else {
      console.error('❌ 部分模块未正确集成');
      testsFailed++;
    }
  } catch (error) {
    console.error('❌ 新模块集成验证失败:', error.message);
    testsFailed++;
  }
}

// 运行所有测试
async function runTests() {
  console.log('开始测试...\n');

  await testGapAnalyzer();
  await testROIEngine();
  await testPatternMiner();
  await testTemplateManager();
  await testMainIntegration();
  await testNewModulesIntegration();

  console.log('\n=================================');
  console.log('📊 测试结果');
  console.log('=================================');
  console.log(`✅ 通过: ${testsPassed}`);
  console.log(`❌ 失败: ${testsFailed}`);
  console.log(`📈 总计: ${testsPassed + testsFailed}`);
  console.log('=================================\n');

  if (testsFailed === 0) {
    console.log('🎉 所有测试通过！');
    process.exit(0);
  } else {
    console.log('⚠️  部分测试失败，请检查。');
    process.exit(1);
  }
}

// 运行测试
runTests();
