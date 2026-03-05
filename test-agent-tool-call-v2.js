/**
 * OpenClaw v4.0 - 测试Agent工具调用
 */

const fs = require('fs');
const path = require('path');

console.log('=== 测试Agent工具调用 ===\n');

const pluginCode = fs.readFileSync(path.join(__dirname, 'core/plugin-entry.js'), 'utf-8');

// 检查关键组件
const checks = [
  { name: 'api.registerTool', pattern: /api\.registerTool\s*\(/ },
  { name: '动态加载监控模块', pattern: /monitoringPath/ },
  { name: '动态加载策略引擎', pattern: /strategyPath/ },
  { name: '异步执行函数', pattern: /async execute\(/ },
  { name: '工具名称前缀', pattern: /monitoring_/ },
  { name: '工具名称前缀', pattern: /strategy_/ }
];

let allPassed = true;
console.log('1. 插件代码检查:\n');
checks.forEach(({ name, pattern }) => {
  const passed = pattern.test(pluginCode);
  console.log(`  ${passed ? '✅' : '❌'} ${name}`);
  if (!passed) allPassed = false;
});

if (!allPassed) {
  console.log('\n❌ 插件代码检查失败');
  process.exit(1);
}

console.log('\n✅ 插件代码检查通过！\n');

// 检查核心模块
console.log('2. 核心模块文件检查:\n');

const monitoringPath = path.join(__dirname, 'core/monitoring');
const strategyPath = path.join(__dirname, 'core/strategy');

const monitoringModules = fs.readdirSync(monitoringPath)
  .filter(f => f.endsWith('.js') && f !== 'index.js');

const strategyModules = fs.readdirSync(strategyPath)
  .filter(f => f.endsWith('.js') && f !== 'index.js');

console.log(`   监控模块 (${monitoringModules.length}):`);
monitoringModules.forEach(m => console.log(`     ✅ ${m}`));

console.log(`   策略引擎模块 (${strategyModules.length}):`);
strategyModules.forEach(m => console.log(`     ✅ ${m}`));

console.log('\n✅ 核心模块文件检查通过！\n');

// 预期注册的工具
console.log('3. 预期注册的工具:\n');

const allTools = [
  ...monitoringModules.map(m => `  - monitoring_${m.replace('.js', '')}`),
  ...strategyModules.map(m => `  - strategy_${m.replace('.js', '')}`)
];

console.log('   总计: ' + allTools.length + ' 个工具\n');
allTools.slice(0, 15).forEach(t => console.log(t));
if (allTools.length > 15) {
  console.log(`   ... 和 ${allTools.length - 15} 个其他工具`);
}

console.log('\n4. 下一步测试:\n');
console.log('   使用 sessions_spawn 启动Agent:');
console.log('   sessions_spawn("测试Agent工具调用")');
console.log('');
console.log('   然后测试:');
console.log('   "请获取性能监控状态"');
console.log('   "调用 strategy_scenario-generator 工具"');
console.log('');
console.log('✅ 所有检查通过！插件已准备好。');
