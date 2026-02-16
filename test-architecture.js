const ArchitectureAuditor = require('./core/architecture-auditor');

console.log('🧪 Architecture Auditor 测试\n');

const auditor = new ArchitectureAuditor({
  couplingThreshold: 3.0,
  redundancyThreshold: 0.05
});

// 模拟模块数据
const mockModules = new Map([
  ['core/strategy-engine.js', {
    path: 'core/strategy-engine.js',
    size: 10000,
    cyclomaticComplexity: 45,
    codeLines: 300,
    dependencies: ['core/predictive-engine.js'],
    lastModified: Date.now()
  }],
  ['core/predictive-engine.js', {
    path: 'core/predictive-engine.js',
    size: 8000,
    cyclomaticComplexity: 30,
    codeLines: 200,
    dependencies: ['core/metrics-tracker.js'],
    lastModified: Date.now()
  }],
  ['core/watchdog.js', {
    path: 'core/watchdog.js',
    size: 6000,
    cyclomaticComplexity: 20,
    codeLines: 150,
    dependencies: ['core/metrics-tracker.js'],
    lastModified: Date.now()
  }],
  ['core/rollback-engine.js', {
    path: 'core/rollback-engine.js',
    size: 7000,
    cyclomaticComplexity: 35,
    codeLines: 180,
    dependencies: ['core/metrics-tracker.js'],
    lastModified: Date.now()
  }],
  ['memory/cognitive-layer.js', {
    path: 'memory/cognitive-layer.js',
    size: 13000,
    cyclomaticComplexity: 55,
    codeLines: 400,
    dependencies: ['memory/system-memory.js'],
    lastModified: Date.now()
  }]
]);

auditor.modules = mockModules;

// 测试1: 耦合度分析
console.log('📊 测试1: 耦合度分析');
console.log('='.repeat(60));

const coupling = auditor.analyzeCoupling();

console.log('✅ 耦合度分析完成');
console.log('  平均耦合度:', coupling.averageCoupling);
console.log('  高耦合模块对数量:', coupling.highlyCoupledModules.length);

coupling.highlyCoupledModules.slice(0, 3).forEach(({ module, couplingWith, score }) => {
  console.log(`  - ${module} ↔ ${couplingWith}: ${score}`);
});

console.log('');

// 测试2: 冗余代码检测
console.log('📊 测试2: 冗余代码检测');
console.log('='.repeat(60));

const redundancy = auditor.detectRedundancy();

console.log('✅ 冗余代码检测完成');
console.log('  总代码行数:', redundancy.totalLines);
console.log('  冗余代码行数:', redundancy.redundantLines);
console.log('  冗余比例:', redundancy.redundantPercentage + '%');
console.log('  冗余模块:', Object.keys(redundancy.moduleRedundancy));

redundancy.redundantBlocks.slice(0, 3).forEach(block => {
  console.log(`  - ${block.path}: ${block.duplicateLines}×${block.uniqueLines} = ${block.totalLines} 行`);
});

console.log('');

// 测试3: 重复逻辑识别
console.log('📊 测试3: 重复逻辑识别');
console.log('='.repeat(60));

const duplicateLogic = auditor.findDuplicateLogic();

console.log('✅ 重复逻辑识别完成');
console.log('  相似代码对数量:', duplicateLogic.totalSimilarities);
console.log('  重复函数数量:', duplicateLogic.duplicateFunctions.length);

duplicateLogic.duplicateFunctions.slice(0, 3).forEach(func => {
  console.log(`  - ${func.key} (相似度 ${func.similarity}): ${func.count} 次`);
});

duplicateLogic.duplicateCodeSnippets.slice(0, 3).forEach(pair => {
  console.log(`  - ${pair.module1} ↔ ${pair.module2} (${pair.similarityPercentage}%)`);
});

console.log('');

// 测试4: 性能瓶颈扫描
console.log('📊 测试4: 性能瓶颈扫描');
console.log('='.repeat(60));

const performance = auditor.identifyBottlenecks();

console.log('✅ 性能瓶颈扫描完成');
console.log('  性能热点模块:', performance.performanceHotspots.length);
console.log('  慢速模块:', performance.slowModules.length);
console.log('  内存瓶颈:', performance.memoryUsageBottlenecks.length);

performance.performanceHotspots.slice(0, 3).forEach(hotspot => {
  console.log(`  - ${hotspot.module}: 复杂度=${hotspot.complexity} (${hotspot.severity})`);
});

performance.slowModules.slice(0, 3).forEach(slow => {
  console.log(`  - ${slow.module}: 大小=${slow.size}KB (严重=${slow.severity})`);
});

console.log('');

// 测试5: 重构建议生成
console.log('📊 测试5: 重构建议生成');
console.log('='.repeat(60));

const suggestions = auditor.generateRefactoringSuggestions({
  coupling,
  redundancy,
  duplicateLogic,
  performance
});

console.log(`✅ 生成了 ${suggestions.length} 条重构建议\n`);

suggestions.forEach((s, i) => {
  console.log(`${i + 1}. [${s.severity}] 优先级=${s.priority} - ${s.category}`);
  console.log(`   问题: ${s.problem}`);
  console.log(`   建议: ${s.recommendation}`);
  console.log('');
});

// 测试6: 模块拆分方案
console.log('📊 测试6: 模块拆分方案');
console.log('='.repeat(60));

const decomposition = auditor.proposeModuleDecomposition({
  coupling,
  redundancy,
  duplicateLogic,
  performance
});

console.log('✅ 模块拆分方案生成完成\n');

console.log('  需要拆分的模块:', decomposition.modulesAtRisk.length);
console.log('  拆分建议数量:', decomposition.decompositions.length);

decomposition.decompositions.forEach(decomp => {
  console.log(`\n  📦 ${decomp.module}`);
  console.log(`     原因: ${decomp.reason}`);
  console.log(`     建议: ${decomp.suggestedActions.join(', ')}`);
  console.log(`     预期影响:`);
  console.log(`       - 可维护性: ${decomp.estimatedImpact.maintainability}`);
  console.log(`       - 可测试性: ${decomp.estimatedImpact.testability}`);
  console.log(`       - 性能: ${decomp.estimatedImpact.performance}`);
});

console.log('\n  整体预估:');
console.log(`    风险模块: ${decomposition.estimatedImpact.totalRiskModules}`);
console.log(`    预期复杂度降低: ${decomposition.estimatedImpact.estimatedComplexityReduction}%`);
console.log(`    预期代码行数减少: ${decomposition.estimatedImpact.estimatedCodeLines}`);
console.log(`    预期测试覆盖率提升: ${decomposition.estimatedImpact.estimatedTestCoverage}`);

console.log('\n' + '='.repeat(60));
console.log('🎉 所有架构审计测试完成！');
console.log('='.repeat(60));
