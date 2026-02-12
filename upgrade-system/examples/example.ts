/**
 * 智能升级系统使用示例
 */

import { IntelligentUpgradeSystem, exampleUsage } from '../core';

/**
 * 示例1：完整升级流程
 */
async function runCompleteUpgrade() {
  console.log('========== 示例1：完整升级流程 ==========\n');

  const system = new IntelligentUpgradeSystem();
  const report = await system.runUpgradeCycle();

  // 查看总体统计
  console.log('📊 升级流程结果');
  console.log(`⏰ 执行时间: ${report.timestamp.toLocaleString()}`);
  console.log(`🎯 识别目标: ${report.phases.identification.goals.length} 个`);
  console.log(`📚 收集知识: ${report.phases.knowledge.packages.length} 个包`);
  console.log(`📈 能力评估: ${report.phases.evaluation.reports.length} 份报告`);
  console.log(`💡 优化建议: ${report.phases.optimization.reports.length} 份报告`);

  // 显示高优先级建议
  console.log('\n🎯 高优先级优化建议（前5条）');
  const allSuggestions = report.phases.optimization.reports.flatMap(r => r.suggestions);
  const highPriority = allSuggestions
    .filter(s => s.priority === 'P0' || s.priority === 'P1')
    .slice(0, 5);

  for (const suggestion of highPriority) {
    console.log(`\n[${suggestion.priority}] ${suggestion.category}`);
    console.log(`   ${suggestion.description}`);
    console.log(`   工作量: ${suggestion.estimatedEffort}`);
    console.log(`   优先级: ${suggestion.urgency}`);
  }

  console.log('\n' + '='.repeat(50) + '\n');
}

/**
 * 示例2：单独使用各个模块
 */
async function runModuleExamples() {
  console.log('========== 示例2：单独使用模块 ==========\n');

  // 导入各个模块
  const { GoalIdentifier } = await import('../core');
  const { KnowledgeCollector } = await import('../core');
  const { CapabilityEvaluator } = await import('../core');
  const { OptimizationSuggester } = await import('../core');

  // 2.1 目标识别
  console.log('📌 目标识别示例');
  const identifier = new GoalIdentifier();

  // 模拟数据
  const skillStats = [
    { skillName: 'copilot', usageCount: 150, successRate: 0.85, performanceScore: 0.80 },
    { skillName: 'auto-gpt', usageCount: 80, successRate: 0.75, performanceScore: 0.70 },
    { skillName: 'rag', usageCount: 200, successRate: 0.90, performanceScore: 0.85 }
  ];

  const goals = await identifier.identifyGoals(skillStats, [], []);
  console.log(`✅ 识别到 ${goals.length} 个目标`);
  goals.slice(0, 3).forEach(g => {
    console.log(`   - [${g.priority}] ${g.description}`);
  });

  // 2.2 能力评估
  console.log('\n📈 能力评估示例');
  const evaluator = new CapabilityEvaluator();

  const skill = { name: 'copilot' };
  const report = await evaluator.evaluate(skill);

  console.log(`技能: ${report.skillName}`);
  console.log(`总分: ${(report.totalScore * 100).toFixed(1)}/100`);
  console.log('维度评分:');
  for (const [name, score] of Object.entries(report.dimensions)) {
    const status = score.score >= 0.8 ? '✅' : score.score >= 0.6 ? '⚠️' : '❌';
    console.log(`  ${status} ${name}: ${(score.score * 100).toFixed(1)}/100`);
  }

  // 2.3 优化建议
  console.log('\n💡 优化建议示例');
  const suggester = new OptimizationSuggester();
  const suggestions = await suggester.generateSuggestions(report);
  const suggestionReport = await suggester.generateReport(report.skillName, suggestions);

  console.log(suggestionReport.summary);
  console.log('\n建议列表:');
  suggestions.slice(0, 3).forEach((s, i) => {
    console.log(`   ${i + 1}. [${s.priority}] ${s.description}`);
  });

  console.log('\n' + '='.repeat(50) + '\n');
}

/**
 * 示例3：自定义评估维度
 */
async function runCustomEvaluation() {
  console.log('========== 示例3：自定义评估维度 ==========\n');

  const { CapabilityEvaluator } = await import('../core');

  const evaluator = new CapabilityEvaluator();

  // 自定义评估维度
  const customDimension = {
    name: '自定义维度',
    weight: 0.1,
    description: '测试自定义评估维度',
    criteria: [
      {
        name: '自定义标准',
        description: '测试自定义标准',
        weight: 1,
        evaluator: async () => {
          // 模拟评估
          return Math.random() * 100;
        }
      }
    ]
  };

  // 可以在 CapabilityEvaluator 中添加自定义维度（当前示例仅展示数据结构）
  console.log('✅ 自定义评估维度定义完成');
  console.log('   维度名称:', customDimension.name);
  console.log('   权重:', customDimension.weight);
  console.log('   标准:', customDimension.criteria.length, '个');
  console.log('   权重总和:', customDimension.criteria.reduce((sum, c) => sum + c.weight, 0));

  console.log('\n' + '='.repeat(50) + '\n');
}

/**
 * 示例4：知识收集
 */
async function runKnowledgeCollection() {
  console.log('========== 示例4：知识收集 ==========\n');

  const { KnowledgeCollector } = await import('../core');

  const collector = new KnowledgeCollector();

  // 收集知识
  const topics = ['性能优化', '文档编写', '错误处理'];
  const packages = await collector.collectKnowledge(topics, { limit: 8 });

  console.log(`✅ 收集了 ${packages.length} 个知识包`);

  for (const pkg of packages) {
    console.log(`\n📚 知识包: ${pkg.goals.join(', ')}`);
    console.log(`   资源数量: ${pkg.resources.length}`);
    console.log(`   学习步骤: ${pkg.learningPath.length}`);

    for (const step of pkg.learningPath) {
      console.log(`     步骤${step.step}: ${step.description}`);
      console.log(`       - 预计时间: ${step.expectedTime}`);
      console.log(`       - 预期成果: ${step.expectedOutcome}`);
    }
  }

  console.log('\n' + '='.repeat(50) + '\n');
}

/**
 * 主函数
 */
async function main() {
  console.log('\n🚀 智能升级系统使用示例\n');
  console.log('='.repeat(50) + '\n');

  // 运行各个示例
  await runCompleteUpgrade();
  await runModuleExamples();
  await runCustomEvaluation();
  await runKnowledgeCollection();

  console.log('🎉 所有示例运行完成！');
  console.log('\n' + '='.repeat(50));
}

// 运行主函数
main().catch(console.error);
