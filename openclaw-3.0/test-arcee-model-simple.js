// test-arcee-model-simple.js - 简化版测试（使用命令行参数）

const axios = require('axios');

async function testArceeModel() {
  const args = process.argv.slice(2);

  // 获取 API Key（从参数或环境变量）
  const apiKey = args.find(arg => arg.startsWith('key='))?.split('=')[1] ||
                 process.env.API_KEY ||
                 process.env.ARCHEE_API_KEY;

  const model = args.find(arg => arg.startsWith('model='))?.split('=')[1] ||
                'arcee-ai/trinity-large-preview:free';
  const baseURL = args.find(arg => arg.startsWith('url='))?.split('=')[1] ||
                  'https://api.openai.com/v1';

  if (!apiKey) {
    console.log('❌ API Key 未配置');
    console.log('\n💡 使用方法:');
    console.log('   node test-arcee-model-simple.js key=YOUR_API_KEY [model=MODEL_NAME] [url=BASE_URL]\n');
    console.log('   示例:');
    console.log('   node test-arcee-model-simple.js key=sk-xxx');
    console.log('   node test-arcee-model-simple.js key=sk-xxx model=gpt-4');
    console.log('   node test-arcee-model-simple.js key=sk-xxx url=https://api.openai.com/v1\n');
    process.exit(1);
  }

  console.log('🧪 测试模型:', model);
  console.log('🔗 Base URL:', baseURL);
  console.log('🔑 API Key:', apiKey.substring(0, 8) + '...');

  try {
    // 测试 API 连接
    console.log('\n📡 测试 API 连接...');
    const modelsResponse = await axios.get(`${baseURL}/models`, {
      headers: { 'Authorization': `Bearer ${apiKey}` },
      timeout: 10000
    });

    const modelExists = modelsResponse.data.data.find(m => m.id === model);
    if (modelExists) {
      console.log(`   ✅ 找到模型: ${model}`);
    } else {
      console.log(`   ⚠️  模型不存在: ${model}`);
      console.log('\n   可用模型:');
      modelsResponse.data.data.slice(0, 20).forEach(m => {
        console.log(`   - ${m.id}`);
      });
    }

    // 发送测试消息
    console.log('\n💬 发送测试消息...');
    const startTime = Date.now();

    const response = await axios.post(
      `${baseURL}/chat/completions`,
      {
        model: model,
        messages: [
          { role: 'user', content: '请用一句话回答：什么是人工智能？' }
        ],
        max_tokens: 100
      },
      {
        headers: {
          'Authorization': `Bearer ${apiKey}`,
          'Content-Type': 'application/json'
        },
        timeout: 30000
      }
    );

    const duration = Date.now() - startTime;

    console.log(`   ✅ 响应成功 (${duration}ms)`);
    console.log(`   🤖 回复: ${response.data.choices[0].message.content}`);
    console.log(`   📊 Tokens: ${response.data.usage?.total_tokens || '未知'}`);
    console.log(`   📈 延迟: ${duration}ms`);

  } catch (err) {
    console.error('\n❌ 测试失败:', err.message);
    if (err.response) {
      console.error('   状态码:', err.response.status);
      console.error('   错误:', JSON.stringify(err.response.data, null, 2));
    }
    process.exit(1);
  }
}

// 运行
testArceeModel();
