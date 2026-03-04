/**
 * 调试会话压缩模块 - V2
 */

const SessionCompressor = require('./utils/session-compressor');

console.log('🔍 调试会话压缩模块 - V2\n');

// 创建包含决策点的测试消息
const testMessages = [
  { role: 'user', content: 'Hello', hasDecision: false, isKey: false },
  { role: 'assistant', content: 'Hi there', hasDecision: false, isKey: false },
  { role: 'user', content: 'How are you?', hasDecision: true, isKey: true },  // 带决策
  { role: 'assistant', content: 'I am fine', hasDecision: false, isKey: false },
];

console.log('测试消息:', JSON.stringify(testMessages, null, 2));

const comp = new SessionCompressor({ compressionLevel: 2 });
console.log('\n尝试压缩...');

try {
  const result = comp.compressSession(testMessages);
  console.log('\n压缩结果:', result);
  console.log('\ntotal 字段:', result.total);
  console.log('类型:', typeof result.total);
  console.log('preserved.length:', result.preservedCount);
  console.log('compressed.length:', result.compressedCount);
} catch (error) {
  console.error('\n错误:', error);
  console.error(error.stack);
}
