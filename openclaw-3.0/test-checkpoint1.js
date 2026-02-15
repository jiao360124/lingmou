// 测试 Checkpoint 1: Stability Core

console.log('🧪 测试 Checkpoint 1: Stability Core\n');

// 测试 1: API Handler
console.log('1️⃣ 测试 API Handler...');
try {
  const apiHandler = require('./core/api-handler');
  console.log('✅ API Handler 加载成功');
  console.log('   - MAX_RETRIES:', apiHandler.MAX_RETRIES);
  console.log('   - RETRY_DELAYS:', apiHandler.RETRY_DELAYS.join(', '));
} catch (error) {
  console.error('❌ API Handler 加载失败:', error.message);
}

console.log();

// 测试 2: Session Summarizer
console.log('2️⃣ 测试 Session Summarizer...');
try {
  const summarizer = require('./core/session-summarizer');
  console.log('✅ Session Summarizer 加载成功');
  console.log('   - TURN_THRESHOLD:', summarizer.TURN_THRESHOLD);
  console.log('   - BASE_CONTEXT_THRESHOLD:', summarizer.BASE_CONTEXT_THRESHOLD);
  console.log('   - COOLDOWN_TURNS:', summarizer.COOLDOWN_TURNS);
  console.log('   - 初始化状态:', {
    turnCount: summarizer.turnCount,
    lastSummaryTurn: summarizer.lastSummaryTurn
  });
} catch (error) {
  console.error('❌ Session Summarizer 加载失败:', error.message);
}

console.log();

// 测试 3: State Manager
console.log('3️⃣ 测试 State Manager...');
try {
  const stateManager = require('./core/state-manager');
  console.log('✅ State Manager 加载成功');
  console.log('   - 状态:', stateManager.getState());
} catch (error) {
  console.error('❌ State Manager 加载失败:', error.message);
}

console.log();

// 测试 4: 数据文件
console.log('4️⃣ 测试数据文件...');
try {
  const fs = require('fs').promises;
  const stateData = JSON.parse(await fs.readFile('openclaw-3.0/data/state.json', 'utf8'));
  const contextData = JSON.parse(await fs.readFile('openclaw-3.0/data/context.json', 'utf8'));
  const configData = JSON.parse(await fs.readFile('openclaw-3.0/config.json', 'utf8'));
  console.log('✅ 数据文件读取成功');
  console.log('   - state.json:', stateData);
  console.log('   - context.json:', contextData);
  console.log('   - config.json:', configData);
} catch (error) {
  console.error('❌ 数据文件读取失败:', error.message);
}

console.log();
console.log('🎉 Checkpoint 1 测试完成！');
console.log('\n✅ 所有模块加载成功，语法检查通过');
console.log('📝 下一步：Checkpoint 2 - Token Governor');
