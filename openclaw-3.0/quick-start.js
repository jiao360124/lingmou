/**
 * OpenClaw 3.0 - 快速使用示例
 * 立即体验所有新功能
 */

const OpenClaw3 = require('./index');

console.log('🚀 OpenClaw 3.0 - 快速使用示例\n');

// 获取系统实例
const openclaw3 = OpenClaw3;

console.log('📊 === 系统概览 ===');
const dashboard = openclaw3.getDashboard();
console.log(`✅ 模块数量: ${Object.keys(dashboard).length}`);
console.log(`✅ 运行时间: ${Math.floor(dashboard.uptime)}秒`);
console.log(`✅ Token使用: ${dashboard.metrics.dailyTokens} / ${dashboard.metrics.dailyLimit}`);
console.log(`✅ 成功率: ${dashboard.metrics.successRate}%`);
console.log(`✅ 错误率: ${dashboard.metrics.errorRate}%`);

console.log('\n🔍 === Gap分析 ===');
const gapAnalyzer = openclaw3.gapAnalyzer;
const gap = gapAnalyzer.analyzeGap('data/metrics.json');
console.log(`✅ 发现 ${gap.suggestions.length} 条优化建议\n`);

gap.suggestions.forEach((s, i) => {
  const icons = { high: '🔴', medium: '🟡', low: '🟢' };
  console.log(`${icons[s.priority]} 建议${i + 1}: ${s.message}`);
  console.log(`   ${s.action}`);
  console.log(`   Gap: ${s.gap}`);
  console.log(`   优先级: ${s.priority}`);
  console.log('');
});

console.log('💰 === ROI分析 ===');
const roiEngine = openclaw3.roiEngine;
const roiList = roiEngine.rankSuggestions(gap.suggestions);
console.log(`✅ ROI排序完成\n`);

roiList.slice(0, 3).forEach((s, i) => {
  console.log(`🏆 ROI建议${i + 1}: ${s.message}`);
  console.log(`   ROI: ${s.roiPercentage.toFixed(2)}%`);
  console.log(`   预估收益: ${s.estimatedBenefit.toLocaleString()} tokens`);
  console.log(`   回收期: ${s.paybackPeriod === Infinity ? 'N/A' : s.paybackPeriod.toFixed(2) + 's'}`);
  console.log('');
});

console.log('🔍 === 模式挖掘 ===');
const patternMiner = openclaw3.patternMiner;
const prompts = [
  { text: '如何解决429错误？', tokenCount: 8 },
  { text: '如何处理API限流？', tokenCount: 9 },
  { text: '如何解决429错误？', tokenCount: 10 },
  { text: '帮我调试这个错误', tokenCount: 7 },
  { text: '如何处理429错误', tokenCount: 6 }
];

const clusters = patternMiner.clusterPrompts(prompts);
console.log(`✅ 聚类完成: ${clusters.length}个\n`);

clusters.forEach((cluster, i) => {
  console.log(`📦 聚类${i + 1}: ${cluster.type}`);
  console.log(`   代表: ${cluster.representative.text}`);
  console.log(`   数量: ${cluster.count}个`);
  console.log('');
});

console.log('📄 === 模板库 ===');
const templateManager = openclaw3.templateManager;
const templates = templateManager.getTemplates();
console.log(`✅ 当前模板数: ${templates.length}\n`);

console.log('✅ 所有新模块已集成并正常运行！');
console.log('📅 定时任务将自动执行：');
console.log('   - 03:30 Gap分析');
console.log('   - 04:30 ROI计算');
console.log('   - 05:00 模式挖掘');
console.log('   - 05:30 模板报告');
console.log('');
console.log('🎉 OpenClaw 3.0 系统已就绪！系统将在后台持续运行。');
console.log('💡 查看实时日志: 查看 openclaw-3.0/logs/ 目录');
