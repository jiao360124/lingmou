/**
 * 运行架构审计并输出报告
 */

const ArchitectureAuditor = require('../architecture-auditor');

(async () => {
  console.log('🔍 开始架构审计...\n');

  const auditor = new ArchitectureAuditor();
  const report = await auditor.audit(process.cwd());

  console.log('═════════════════════════════════════════════════════════════');
  console.log('                   架构审计报告');
  console.log('═════════════════════════════════════════════════════════════\n');

  // 基本信息
  console.log('📋 基本信息');
  console.log('   项目路径:', report.projectPath);
  console.log('   审计时间:', new Date(report.timestamp).toLocaleString());
  console.log('   扫描模块数:', report.modules.length);
  console.log();

  // 耦合度分析
  console.log('🔗 耦合度分析');
  if (report.coupling && report.coupling.modulePairCoupling) {
    console.log('   整体耦合度:', report.coupling.averageCoupling || 'N/A');
    console.log('   高耦合模块对数:', report.coupling.highlyCoupledModules?.length || 0);
    console.log('   高耦合模块:');
    report.coupling.highlyCoupledModules?.slice(0, 5).forEach(m => {
      console.log(`     - ${m.module} ⇄ ${m.couplingWith} (评分: ${m.score})`);
    });
  }
  console.log();

  // 冗余代码检测
  console.log('♻️  冗余代码检测');
  if (report.redundancy) {
    console.log('   冗余代码比例:', report.redundancy.redundantPercentage || 'N/A');
    console.log('   潜在冗余位置数:', report.redundancy.redundantBlocks?.length || 0);
    if (report.redundancy.redundantBlocks && report.redundancy.redundantBlocks.length > 0) {
      console.log('   前5个冗余代码块:');
      report.redundancy.redundantBlocks.slice(0, 5).forEach((block, i) => {
        console.log(`     ${i + 1}. ${block.path} - ${block.duplicateLines} 行冗余`);
      });
    }
  }
  console.log();

  // 重复逻辑检测
  console.log('🔁 重复逻辑检测');
  if (report.duplicateLogic) {
    console.log('   重复函数组数:', report.duplicateLogic.duplicateFunctions?.length || 0);
    console.log('   高相似度代码对数:', report.duplicateLogic.similarPairs?.length || 0);
    if (report.duplicateLogic.duplicateFunctions && report.duplicateLogic.duplicateFunctions.length > 0) {
      console.log('   前3个重复函数:');
      report.duplicateLogic.duplicateFunctions.slice(0, 3).forEach((func, i) => {
        console.log(`     ${i + 1}. ${func.key} (${func.count}次)`);
      });
    }
  }
  console.log();

  // 性能瓶颈扫描
  console.log('⚡ 性能瓶颈扫描');
  if (report.performance) {
    console.log('   性能热点数:', report.performance.performanceHotspots?.length || 0);
    console.log('   慢速模块数:', report.performance.slowModules?.length || 0);
    if (report.performance.performanceHotspots && report.performance.performanceHotspots.length > 0) {
      console.log('   前3个性能热点:');
      report.performance.performanceHotspots.slice(0, 3).forEach((spot, i) => {
        console.log(`     ${i + 1}. ${spot.module} - 圈复杂度: ${spot.complexity}`);
      });
    }
  }
  console.log();

  // 重构建议
  console.log('💡 重构建议');
  if (report.refactoringSuggestions) {
    console.log(`   建议总数: ${report.refactoringSuggestions.length}`);
    console.log('   前5个建议:');
    report.refactoringSuggestions.slice(0, 5).forEach((suggestion, i) => {
      console.log(`     ${i + 1}. [${suggestion.severity}] 优先级 ${suggestion.priority}`);
      console.log(`        ${suggestion.recommendation}`);
    });
  }
  console.log();

  // 模块拆分方案
  console.log('🏗️  模块拆分方案');
  if (report.decompositionPlan) {
    console.log('   需拆分模块数:', report.decompositionPlan.modulesAtRisk?.length || 0);
    if (report.decompositionPlan.decompositions && report.decompositionPlan.decompositions.length > 0) {
      console.log('   拆分建议:');
      report.decompositionPlan.decompositions.slice(0, 5).forEach((plan, i) => {
        console.log(`     ${i + 1}. ${plan.module}`);
        console.log(`        原因: ${plan.reason}`);
        console.log(`        建议: ${plan.suggestedActions.slice(0, 2).join(', ')}`);
      });
    }
  }
  console.log();

  console.log('═════════════════════════════════════════════════════════════');
  console.log('                   审计完成');
  console.log('═════════════════════════════════════════════════════════════');
})();
