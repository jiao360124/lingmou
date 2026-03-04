// 直接测试 ZAI GLM 模型

console.log('🚀 测试 ZAI GLM 模型\n');

const ZaiProvider = require('./providers/zai-provider.js');

// 创建 ZAI Provider 实例
const glm = new ZaiProvider({
  apiKey: 'BSAd4FWdcg5FrJayT__vdMet0vzcKHK'
});

console.log('📊 模型信息:');
console.log(JSON.stringify(glm.getModelInfo(), null, 2));

console.log('\n🔌 测试连接...');
(async () => {
  try {
    const testResult = await glm.testConnection();
    if (testResult) {
      console.log('\n✅ 连接测试成功！\n');

      console.log('💬 发送测试消息...');
      console.log('---\n');

      const response = await glm.chat([
        { role: 'user', content: 'Hello, please respond with a short greeting and tell me your name.' }
      ], { stream: false });

      if (response && response.choices && response.choices[0]) {
        console.log('✅ 响应成功！');
        console.log('\n📤 回复内容:');
        console.log(response.choices[0].message.content);
        console.log('\n---');

        if (response.usage) {
          console.log('\n📊 Token 使用:');
          console.log(`  输入: ${response.usage.prompt_tokens} tokens`);
          console.log(`  输出: ${response.usage.completion_tokens} tokens`);
          console.log(`  总计: ${response.usage.total_tokens} tokens`);
        }

        if (response.model) {
          console.log('\n🎯 使用的模型:', response.model);
        }
      }
    } else {
      console.log('\n❌ 连接测试失败');
    }
  } catch (error) {
    console.error('\n❌ 测试失败:', error.message);
    console.error('详细错误:', error);
  }

  console.log('\n🎉 ZAI GLM 模型测试完成！');
})();
