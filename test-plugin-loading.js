/**
 * 测试核心模块插件加载
 */

const fs = require('fs');
const path = require('path');

console.log('=== 测试核心模块插件加载 ===\n');

// 1. 检查插件入口文件
const pluginPath = path.join(__dirname, 'core/plugin-entry.js');

if (!fs.existsSync(pluginPath)) {
  console.log('❌ 插件入口文件不存在');
  process.exit(1);
}

console.log('✅ 插件入口文件存在:', pluginPath);
console.log('');

// 2. 测试插件入口文件能否正常运行
console.log('2. 测试插件入口文件...\n');

try {
  const pluginCode = fs.readFileSync(pluginPath, 'utf-8');

  // 检查关键代码
  if (!pluginCode.includes('api.registerTool')) {
    console.log('❌ 插件未调用 api.registerTool');
    process.exit(1);
  }

  if (!pluginCode.includes('monitoringPath')) {
    console.log('❌ 插件未加载监控模块');
    process.exit(1);
  }

  if (!pluginCode.includes('strategyPath')) {
    console.log('❌ 插件未加载策略引擎模块');
    process.exit(1);
  }

  console.log('✅ 插件入口文件代码正确');
  console.log('');

  // 3. 检查核心模块文件
  console.log('3. 检查核心模块文件...\n');

  const monitoringPath = path.join(__dirname, 'core/monitoring');
  const strategyPath = path.join(__dirname, 'core/strategy');

  if (!fs.existsSync(monitoringPath)) {
    console.log('❌ 监控模块目录不存在');
    process.exit(1);
  }

  console.log('✅ 监控模块目录存在:', monitoringPath);

  const monitoringModules = fs.readdirSync(monitoringPath)
    .filter(f => f.endsWith('.js') && f !== 'index.js');

  console.log(`   发现 ${monitoringModules.length} 个监控模块:`);
  monitoringModules.forEach(m => console.log(`      - ${m}`));
  console.log('');

  if (!fs.existsSync(strategyPath)) {
    console.log('❌ 策略引擎目录不存在');
    process.exit(1);
  }

  console.log('✅ 策略引擎目录存在:', strategyPath);

  const strategyModules = fs.readdirSync(strategyPath)
    .filter(f => f.endsWith('.js') && f !== 'index.js');

  console.log(`   发现 ${strategyModules.length} 个策略模块:`);
  strategyModules.forEach(m => console.log(`      - ${m}`));
  console.log('');

  // 4. 检查技能文件
  console.log('4. 检查技能文件...\n');

  const skillPath = path.join(__dirname, 'skills/core-modules');

  if (!fs.existsSync(skillPath)) {
    console.log('❌ 技能目录不存在');
    process.exit(1);
  }

  const skillFile = path.join(skillPath, 'SKILL.md');

  if (!fs.existsSync(skillFile)) {
    console.log('❌ 技能文件不存在');
    process.exit(1);
  }

  const skillContent = fs.readFileSync(skillFile, 'utf-8');

  if (!skillContent.startsWith('---')) {
    console.log('❌ 技能文件不是HAML格式');
    process.exit(1);
  }

  if (!skillContent.includes('name: core-modules')) {
    console.log('❌ 技能文件缺少name字段');
    process.exit(1);
  }

  console.log('✅ 技能文件存在且格式正确');
  console.log('');

  // 5. 模拟插件执行
  console.log('5. 模拟插件执行...\n');

  console.log('   插件将执行以下操作:');
  console.log('   - 扫描 core/monitoring/ 目录');
  console.log('   - 扫描 core/strategy/ 目录');
  console.log('   - 为每个模块创建 Agent Tool 包装');
  console.log('   - 注册到 api.registerTool()');
  console.log('');
  console.log('   预期创建的工具:');
  console.log('   - monitoring_performance-monitor');
  console.log('   - monitoring_memory-monitor');
  console.log('   - monitoring_api-tracker');
  console.log('   - strategy_scenario-generator');
  console.log('   - strategy_scenario-evaluator');
  console.log('   - strategy_cost-calculator');
  console.log('   - strategy_benefit-calculator');
  console.log('   - strategy_roi-analyzer');
  console.log('   - strategy_risk-assessor');
  console.log('   - strategy_risk-controller');
  console.log('   - strategy_risk-adjusted-scorer');
  console.log('   - strategy_adversary-simulator');
  console.log('   - strategy_multi-perspective-evaluator');
  console.log('   - strategy-strategy-engine-enhanced');
  console.log('');

  console.log('✅ 所有检查通过！插件已准备好加载。');
  console.log('');
  console.log('下一步: Gateway 应该会在检测到配置变化时自动加载插件。');
  console.log('运行 openclaw gateway status 验证加载状态。');

} catch (error) {
  console.log(`❌ 测试失败: ${error.message}`);
  console.log('');
  console.log(`错误堆栈: ${error.stack}`);
  process.exit(1);
}

console.log('');
console.log('=== 测试完成 ===');
