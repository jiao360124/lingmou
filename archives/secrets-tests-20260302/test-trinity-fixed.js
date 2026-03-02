// 直接测试 Trinity Free 模型

console.log('🚀 测试 Trinity Free 模型\n');

const OpenRouterProvider = require('../openclaw-3.0/providers/openrouter.js');

// 创建 OpenRouter Provider 实例
const trinity = new OpenRouterProvider({
  apiKey: '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',
  model: 'arcee-ai/trinity-large-preview:free'
});

console.log('📊 模型信息:');
console.log(JSON.stringify(trinity.getModelInfo(), null, 2));

console.log('\n🔌 测试连接...');
(async () => {
  try {
    const testResult = await trinity.testConnection();
    if (testResult) {
      console.log('\n✅ 连接测试成功！\n');

      console.log('💬 发送测试消息...');
      console.log('---\n');

      const response = await trinity.chat([
        { role: 'user', content: 'Hello, please respond with a short greeting and tell me your name. Keep it brief and professional.' }
      ], { stream: false });

      if (response && response.choices && response.choices[0]) {
        const content = response.choices[0].message.content;
        console.log('🤖 Trinity 响应:');
        console.log(content);
        console.log('\n---');
        console.log('✅ Trinity 模型测试成功完成！');
      } else {
        console.error('❌ 响应格式异常:', response);
      }
    } else {
      console.error('❌ 连接测试失败');
    }
  } catch (error) {
    console.error('❌ 测试失败:', error.message);
    console.error('错误详情:', error.response?.data || error);
  }
})();