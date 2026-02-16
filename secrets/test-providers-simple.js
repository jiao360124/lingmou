// 简单测试 providers 初始化

console.log('🔧 Testing provider initialization...\n');

// 测试 ZAI Provider
console.log('1. Testing ZAI Provider...');
try {
  const ZaiProvider = require('./providers/zai-provider.js');
  console.log('✅ ZAI Provider loaded successfully');
  console.log('  Constructor:', typeof ZaiProvider);

  const zai = new ZaiProvider({
    apiKey: 'BSAd4FWdcg5FrJayT__vdMet0vzcKHK'
  });
  console.log('✅ ZAI Provider instance created');
} catch (error) {
  console.error('❌ ZAI Provider error:', error.message);
  console.error('Stack:', error.stack);
}

console.log('\n2. Testing OpenRouter Provider...');
try {
  const OpenRouterProvider = require('./providers/openrouter.js');
  console.log('✅ OpenRouter Provider loaded successfully');
  console.log('  Constructor:', typeof OpenRouterProvider);

  const openrouter = new OpenRouterProvider({
    apiKey: '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'
  });
  console.log('✅ OpenRouter Provider instance created');
} catch (error) {
  console.error('❌ OpenRouter Provider error:', error.message);
  console.error('Stack:', error.stack);
}

console.log('\n🎉 Provider test complete');
