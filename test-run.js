// 临时测试脚本

console.log('🧪 运行 Checkpoint 1 测试\n');

try {
  const apiHandler = require('./openclaw-3.0/core/api-handler');
  console.log('✅ API Handler 加载成功');
  console.log('   MAX_RETRIES:', apiHandler.MAX_RETRIES);

  const summarizer = require('./openclaw-3.0/core/session-summarizer');
  console.log('✅ Session Summarizer 加载成功');
  console.log('   TURN_THRESHOLD:', summarizer.TURN_THRESHOLD);

  const stateManager = require('./openclaw-3.0/core/state-manager');
  console.log('✅ State Manager 加载成功');
  console.log('   当前状态:', stateManager.getState());

  console.log('\n🎉 所有模块加载成功！');
} catch (error) {
  console.error('❌ 加载失败:', error);
}
