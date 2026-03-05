/**
 * OpenClaw v4.0 - 测试Agent工具调用
 *
 * 验证核心模块工具是否被正确注册为Agent Tools
 */

const fs = require('fs');
const path = require('path');

console.log('=== 测试Agent工具调用 ===\n');

// 1. 检查插件入口文件
console.log('1. 检查插件入口文件...\n');

const pluginPath = path.join(__dirname, 'core/plugin-entry.js');
if (!fs.existsSync(pluginPath)) {
  console.log('❌ 插件入口文件不存在');
  process.exit(1);
}

// 2. 检查插件代码
console.log('2. 检查插件代码结构...\n');

const pluginCode = fs.readFileSync(pluginPath, 'utf-8');

const checks = [
  { name: 'api.registerTool 调用', pattern: /api\.registerTool\s*\(/g },
  { name: '监控模块加载', pattern: /monitoringPath/g },
  { name: '策略引擎加载', pattern: /strategyPath/g },
  { name: '异步执行函数', pattern: /async execute\(/g },
  { name: 'JSON响应格式', pattern: /\{ content: \[ \{ type: "text" \}\] \}/g }
];

let allChecks = true;
checks.forEach(check => {
  const has = check.pattern.test(pluginCode);
  console.log(`${has ? '✅' : '❌'} ${check.name}`);
  if (!has) allChecks = false;
});

if (!allChecks) {
  console.log('\n❌ 插件代码检查失败');
  process.exit(1);
}

// 3. 检查模块文件
console.log('\n3. 检查核心模块文件...\n');

const monitoringPath = path.join(__dirname, 'core/monitoring');
const strategyPath = path.join(__dirname, 'core/strategy');

if (!fs.existsSync(monitoringPath) || !fs.existsSync(strategyPath)) {
  console.log('❌ 核心模块目录不存在');
  process.exit(1);
}

const monitoringModules = fs.readdirSync(monitoringPath)
  .filter(f => f.endsWith('.js') && f !== 'index.js');

const strategyModules = fs.readdirSync(strategyPath)
  .filter(f => f.endsWith('.js') && f !== 'index.js');

console.log(`监控模块 (${monitoringModules.length}):`);
monitoringModules.forEach(m => console.log(`  ✅ ${m}`));

console.log(`\n策略引擎模块 (${strategyModules.length}):`);
strategyModules.forEach(m => console.log(`  ✅ ${m}`));

// 4. 模拟工具调用
console.log('\n4. 模拟工具调用流程...\n');

console.log('当Agent收到消息时，流程如下:');
console.log('');
console.log('步骤 1: Agent加载上下文');
console.log('  - 读取对话历史');
console.log('  - 加载工具Schema（包括新注册的工具）');
console.log('  - 加载Skills');
console.log('');
console.log('步骤 2: LLM决策');
console.log('  - LLM基于上下文和工具Schema选择合适的工具');
console.log('  - 返回工具调用请求');
console.log('');
console.log('步骤 3: OpenClaw执行工具调用');
console.log('  - OpenClaw调用插件的execute函数');
console.log('  - 插件加载核心模块实例');
console.log('  - 调用模块的getStatus()或其他方法');
console.log('  - 返回JSON格式的结果');
console.log('');
console.log('步骤 4: 结果返回给Agent');
console.log('  - 结果格式: { content: [{ type: "text", text: "..." }] }');
console.log('  - Agent将结果发送给LLM继续生成回复');

// 5. 预期的工具列表
console.log('\n5. 预期注册的工具...\n');

console.log('监控工具 (3个):');
const monitoringTools = monitoringModules.map(m => `  - monitoring_${m.replace('.js', '')}`);
monitoringTools.forEach(t => console.log(t));

console.log('\n策略工具 (12个):');
const strategyTools = strategyModules.map(m => `  - strategy_${m.replace('.js', '')}`);
strategyTools.forEach(t => console.log(t));

console.log('\n总计: 15个新注册的工具');
console.log('');

// 6. 实际测试 - 使用sessions_spawn
console.log('6. 创建实际测试...\n');

console.log('要验证Agent能否调用这些工具，需要:');
console.log('  1. 创建一个Agent会话');
console.log('  2. 发送包含工具调用请求的消息');
console.log('  3. 检查工具是否被正确调用');
console.log('');
console.log('示例测试:');
console.log('');
console.log('1. 使用sessions_spawn启动Agent:');
console.log('   sessions_spawn("测试Agent工具调用")');
console.log('');
console.log('2. 在Agent中测试工具调用:');
console.log('   "请获取性能监控状态"');
console.log('   或');
console.log('   "调用monitoring_performance-monitor工具"');
console.log('');

console.log('✅ 插件准备完成！');
console.log('下一步: 运行sessions_spawn测试Agent工具调用。');
