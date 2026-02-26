/**
 * 调试会话压缩模块
 */

const SessionCompressor = require('./utils/session-compressor');

console.log('🔍 调试会话压缩模块\n');

// 创建简单测试数据
const testMessages = [
  { role: 'user', content: 'Hello', hasDecision: false, isKey: false },
  { role: 'assistant', content: 'Hi there', hasDecision: false, isKey: false },
  { role: 'user', content: 'How are you?', hasDecision: false, isKey: false },
];

console.log('测试消息:', JSON.stringify(testMessages, null, 2));

const comp = new SessionCompressor({ compressionLevel: 2 });
console.log('\n尝试压缩...');

try {
  const result = comp.compressSession(testMessages);
  console.log('\n压缩结果:', result);
  console.log('\n总消息数:', result.total);
  console.log('压缩后:', result.compressed);
} catch (error) {
  console.error('\n错误:', error);
  console.error(error.stack);
}
