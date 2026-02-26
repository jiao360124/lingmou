/**
 * 会话压缩模块完整测试
 * V3.2 核心功能测试
 */

const SessionCompressor = require('./utils/session-compressor');

console.log('🧹 V3.2 会话压缩模块完整测试\n');

// 创建模拟的会话消息
const generateSessionMessages = (count) => {
  const messages = [];
  const roles = ['user', 'assistant'];

  for (let i = 0; i < count; i++) {
    const hasDecision = i === 5 || i === 12 || i === 25;
    const hasError = i === 8 || i === 20;
    const role = i % 2 === 0 ? 'user' : 'assistant';

    messages.push({
      role,
      content: `这是消息 #${i + 1} - ${hasDecision ? '重要决策' : ''} ${hasError ? '错误' : ''} 的测试内容`,
      timestamp: Date.now() - (count - i) * 60000,
      hasDecision,
      hasError,
      isKey: hasDecision || hasError
    });
  }

  return messages;
};

// 测试1：轻度压缩
console.log('📋 测试1：轻度压缩策略');
console.log('─'.repeat(60));

const lightCompressor = new SessionCompressor({ compressionLevel: 1 });
const lightMessages = generateSessionMessages(20);

console.log(`原始消息数: ${lightMessages.length}`);
const lightStats = lightCompressor.getCompressionStats(lightMessages);
console.log(`压缩后: ${lightStats.compressedCount} 消息`);
console.log(`压缩比: ${lightStats.reductionRatio}%`);
console.log(`保留消息: ${lightStats.preservedCount}`);
console.log(`压缩片段: ${lightStats.compressedSegments}\n`);

// 测试2：中度压缩
console.log('📋 测试2：中度压缩策略');
console.log('─'.repeat(60));

const mediumCompressor = new SessionCompressor({ compressionLevel: 2 });
const mediumMessages = generateSessionMessages(50);

console.log(`原始消息数: ${mediumMessages.length}`);
const mediumStats = mediumCompressor.getCompressionStats(mediumMessages);
console.log(`压缩后: ${mediumStats.compressedCount} 消息`);
console.log(`压缩比: ${mediumStats.reductionRatio}%`);
console.log(`保留消息: ${mediumStats.preservedCount}`);
console.log(`压缩片段: ${mediumStats.compressedSegments}\n`);

// 测试3：重度压缩
console.log('📋 测试3：重度压缩策略');
console.log('─'.repeat(60));

const heavyCompressor = new SessionCompressor({ compressionLevel: 3 });
const heavyMessages = generateSessionMessages(30);

console.log(`原始消息数: ${heavyMessages.length}`);
const heavyStats = heavyCompressor.getCompressionStats(heavyMessages);
console.log(`压缩后: ${heavyStats.compressedCount} 消息`);
console.log(`压缩比: ${heavyStats.reductionRatio}%`);
console.log(`保留消息: ${heavyStats.preservedCount}`);
console.log(`压缩片段: ${heavyStats.compressedSegments}\n`);

// 测试4：实际压缩演示
console.log('📋 测试4：实际压缩演示（中度策略）');
console.log('─'.repeat(60));

const actualCompressor = new SessionCompressor({ compressionLevel: 2 });
const actualMessages = generateSessionMessages(15);

console.log('压缩前：');
actualMessages.forEach((msg, i) => {
  console.log(`  ${i + 1}. [${msg.role}] ${msg.content.substring(0, 50)}...`);
});

const compressed = actualCompressor.compressSession(actualMessages);

console.log('\n压缩后：');
console.log(`总消息数: ${compressed.total}`);
console.log(`压缩比: ${compressed.reductionRatio}%`);

console.log('\n保留的消息：');
compressed.compressed.slice(0, 5).forEach((msg, i) => {
  if (msg.role === 'system') {
    console.log(`  ${i + 1}. [系统] 摘要生成...`);
  } else {
    console.log(`  ${i + 1}. [${msg.role}] ${msg.content.substring(0, 50)}...`);
  }
});

// 测试5：不同策略对比
console.log('\n📊 测试5：不同策略对比总结');
console.log('─'.repeat(60));

const testMessages = generateSessionMessages(50);

console.log('消息数量 | 轻度压缩 | 中度压缩 | 重度压缩');
console.log('─'.repeat(50));

[1, 2, 3, 5, 10, 20, 50, 100].forEach(count => {
  const msgs = generateSessionMessages(count);
  console.log(`${String(count).padEnd(10)} | `);

  [1, 2, 3].forEach(level => {
    const comp = new SessionCompressor({ compressionLevel: level });
    const stats = comp.getCompressionStats(msgs);
    const compressed = (stats.compressedCount / count * 100).toFixed(1);
    process.stdout.write(`${String(compressed).padEnd(10)}% | `);
  });

  console.log('');
});

console.log('\n🎉 V3.2 会话压缩模块测试完成！');
console.log('\n✅ 核心功能:');
console.log('   1. 三种压缩策略（轻度/中度/重度）');
console.log('   2. 智能保留关键消息（决策/错误）');
console.log('   3. 相似内容合并');
console.log('   4. 自动摘要生成');
console.log('   5. 详细统计信息');
console.log('\n✅ 应用场景:');
console.log('   1. 长对话持久化');
console.log('   2. Token成本优化');
console.log('   3. 上下文管理');
console.log('   4. 性能提升');
console.log('   5. 智能分析');
