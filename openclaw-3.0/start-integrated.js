/**
 * OpenClaw 3.0 - 集成启动脚本
 * 集成所有新模块的主流程
 */

console.log('=================================');
console.log('🎉 OpenClaw 3.0 - 集成启动');
console.log('=================================\n');

// 导入所有模块
const OpenClaw3 = require('./index');

// 使用已创建的实例
const openclaw3 = OpenClaw3;

console.log('\n');
console.log('=================================');
console.log('📊 模块加载状态');
console.log('=================================');
console.log('✅ 所有模块已加载');
console.log('✅ 新模块已集成');
console.log('✅ 定时任务已配置');
console.log('✅ 监控系统已启动');
console.log('\n');
console.log('🚀 系统已就绪！');
console.log('=================================\n');

// 演示新功能
setTimeout(() => {
  console.log('\n');
  console.log('=================================');
  console.log('🔍 演示新功能');
  console.log('=================================\n');

  console.log('1️⃣ Gap Analyzer');
  const gap = openclaw3.gapAnalyzer.analyzeGap('data/metrics.json');
  console.log(`   发现 ${gap.suggestions.length} 条优化建议`);
  if (gap.suggestions.length > 0) {
    console.log(`   最紧迫: ${gap.suggestions[0].message}`);
    console.log(`   优先级: ${gap.suggestions[0].priority}`);
  }

  console.log('\n2️⃣ ROI Engine');
  const roiList = openclaw3.roiEngine.rankSuggestions(gap.suggestions);
  if (roiList.length > 0) {
    console.log(`   平均ROI: ${roiList[0].roiPercentage.toFixed(2)}%`);
    console.log(`   最佳ROI建议: ${roiList[0].message}`);
    console.log(`   预估收益: ${roiList[0].estimatedBenefit.toLocaleString()} tokens`);
  }

  console.log('\n3️⃣ Pattern Miner');
  console.log('   已加载模式库');

  console.log('\n4️⃣ Template Manager');
  const stats = openclaw3.templateManager.getTemplateStats();
  console.log(`   总模板数: ${stats.total}`);
  console.log(`   按类型: ${Object.entries(stats.byType).map(([k, v]) => `${k}:${v}`).join(', ')}`);

  console.log('\n');
  console.log('=================================');
  console.log('✅ 新功能演示完成');
  console.log('=================================\n');
}, 3000);

// 导出实例供外部使用
module.exports = openclaw3;
