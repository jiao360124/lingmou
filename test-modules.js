// 模块加载测试

const apiHandler = require('./openclaw-3.0/core/api-handler');
const summarizer = require('./openclaw-3.0/core/session-summarizer');
const stateManager = require('./openclaw-3.0/core/state-manager');

console.log('🧪 模块加载测试\n');
console.log('✅ API Handler:', apiHandler.constructor.name);
console.log('   - MAX_RETRIES:', apiHandler.MAX_RETRIES);
console.log('   - RETRY_DELAYS:', apiHandler.RETRY_DELAYS.join(', '));

console.log('\n✅ Session Summarizer:', summarizer.constructor.name);
console.log('   - TURN_THRESHOLD:', summarizer.TURN_THRESHOLD);
console.log('   - BASE_CONTEXT_THRESHOLD:', summarizer.BASE_CONTEXT_THRESHOLD);
console.log('   - COOLDOWN_TURNS:', summarizer.COOLDOWN_TURNS);

console.log('\n✅ State Manager:', stateManager.constructor.name);
console.log('   - 初始化状态:', stateManager.getState());

console.log('\n🎉 Checkpoint 1 完成！');
console.log('✅ 三个核心模块加载成功');
console.log('✅ 语法检查通过');
console.log('\n📝 准备进入 Checkpoint 2: Token Governor');
