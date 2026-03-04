// test-arcee-model.js - 测试 arcee-ai/trinity-large-preview:free 模型

const axios = require('axios');

async function testArceeModel() {
  console.log('🧪 测试 arcee-ai/trinity-large-preview:free 模型\n');

  try {
    // 1. 配置 API
    const config = {
      baseURL: process.env.API_BASE_URL || 'https://api.openai.com/v1',
      apiKey: process.env.API_KEY || process.env.ARCHEE_API_KEY,
      model: 'arcee-ai/trinity-large-preview:free'
    };

    console.log('📋 API 配置:');
    console.log(`   Base URL: ${config.baseURL}`);
    console.log(`   Model: ${config.model}`);
    console.log(`   API Key: ${config.apiKey ? '已配置' : '未配置'}\n`);

    if (!config.apiKey) {
      console.error('❌ API Key 未配置');
      console.log('\n💡 设置方法:');
      console.log('   export API_KEY=your_api_key_here');
      console.log('   或');
      console.log('   export ARCHEE_API_KEY=your_api_key_here\n');
      process.exit(1);
    }

    // 2. 测试 API 连接
    console.log('📋 测试 1: API 连接测试');
    try {
      const healthResponse = await axios.get(`${config.baseURL}/models`, {
        headers: {
          'Authorization': `Bearer ${config.apiKey}`
        },
        timeout: 10000
      });

      console.log('✅ API 连接成功');
      console.log(`   可用模型数量: ${healthResponse.data.data.length}`);

      // 查找目标模型
      const modelExists = healthResponse.data.data.find(m => m.id === config.model);
      if (modelExists) {
        console.log(`   ✅ 找到目标模型: ${modelExists.id}`);
      } else {
        console.log(`   ⚠️  未找到模型: ${config.model}`);
        console.log('\n   可用模型列表:');
        healthResponse.data.data.slice(0, 10).forEach(m => {
          console.log(`   - ${m.id}`);
        });
      }
      console.log('');
    } catch (err) {
      console.error('❌ API 连接失败:', err.message);
      if (err.response) {
        console.error('   状态码:', err.response.status);
        console.error('   错误:', err.response.data);
      }
      console.log('\n💡 提示:');
      console.log('   - 检查 API Key 是否正确');
      console.log('   - 检查 Base URL 是否正确');
      console.log('   - 检查网络连接\n');
      process.exit(1);
    }

    // 3. 测试模型调用
    console.log('📋 测试 2: 模型调用测试');

    const testPrompt = `你好！这是一个测试。
请用一句话介绍一下你自己。

回答：`;

    const startTime = Date.now();

    try {
      const response = await axios.post(
        `${config.baseURL}/chat/completions`,
        {
          model: config.model,
          messages: [
            {
              role: 'user',
              content: testPrompt
            }
          ],
          temperature: 0.7,
          max_tokens: 100
        },
        {
          headers: {
            'Authorization': `Bearer ${config.apiKey}`,
            'Content-Type': 'application/json'
          },
          timeout: 30000
        }
      );

      const duration = Date.now() - startTime;

      console.log('✅ 模型调用成功');
      console.log(`   执行时间: ${duration}ms`);
      console.log(`   使用的 Tokens: ${response.data.usage?.total_tokens || '未知'}`);
      console.log(`   模型响应: ${response.data.choices[0].message.content}\n`);

      // 4. 显示详细信息
      console.log('📋 测试 3: 详细信息');
      console.log('   模型:', response.data.model);
      console.log('   消息数量:', response.data.usage?.prompt_tokens + response.data.usage?.completion_tokens);
      console.log('   提示 Tokens:', response.data.usage?.prompt_tokens);
      console.log('   完成 Tokens:', response.data.usage?.completion_tokens);
      console.log('   总 Tokens:', response.data.usage?.total_tokens);
      console.log('   延迟:', duration + 'ms');
      console.log('   完成原因:', response.data.choices[0].finish_reason);
      console.log('');

      // 5. 多轮对话测试
      console.log('📋 测试 4: 多轮对话测试');

      const conversation = [
        {
          role: 'user',
          content: '请用中文说"你好"'
        },
        {
          role: 'assistant',
          content: '你好！很高兴为您服务。'
        },
        {
          role: 'user',
          content: '那请你再重复一遍'
        }
      ];

      const convResponse = await axios.post(
        `${config.baseURL}/chat/completions`,
        {
          model: config.model,
          messages: conversation
        },
        {
          headers: {
            'Authorization': `Bearer ${config.apiKey}`,
            'Content-Type': 'application/json'
          },
          timeout: 30000
        }
      );

      console.log('✅ 多轮对话成功');
      console.log('   回复:', convResponse.data.choices[0].message.content);
      console.log('');

      // 6. 性能测试
      console.log('📋 测试 5: 性能测试（3次调用）');

      const performanceResults = [];
      for (let i = 0; i < 3; i++) {
        const perfStart = Date.now();
        const perfResponse = await axios.post(
          `${config.baseURL}/chat/completions`,
          {
            model: config.model,
            messages: [
              { role: 'user', content: '测试' }
            ],
            max_tokens: 50
          },
          {
            headers: {
              'Authorization': `Bearer ${config.apiKey}`,
              'Content-Type': 'application/json'
            },
            timeout: 30000
          }
        );
        const perfDuration = Date.now() - perfStart;
        performanceResults.push({
          duration: perfDuration,
          tokens: perfResponse.data.usage?.total_tokens
        });
        console.log(`   尝试 ${i + 1}: ${perfDuration}ms (${perfResponse.data.usage?.total_tokens} tokens)`);
      }

      const avgDuration = Math.round(performanceResults.reduce((sum, r) => sum + r.duration, 0) / performanceResults.length);
      const avgTokens = Math.round(performanceResults.reduce((sum, r) => sum + r.tokens, 0) / performanceResults.length);

      console.log(`\n   平均延迟: ${avgDuration}ms`);
      console.log(`   平均 Tokens/次: ${avgTokens}`);
      console.log('');

      // 7. 成本估算
      console.log('📋 测试 6: 成本估算');
      const totalTokens = performanceResults.reduce((sum, r) => sum + r.tokens, 0);
      // 假设成本为 $0.0001 per 1K tokens
      const estimatedCost = (totalTokens / 1000) * 0.0001;

      console.log(`   测试总 Tokens: ${totalTokens}`);
      console.log(`   估算成本: $${estimatedCost.toFixed(4)} (按 $0.0001/1K tokens 计算)`);
      console.log('');

      console.log('🎉 所有测试通过！');
      console.log('\n💡 使用建议:');
      console.log('   1. 该模型是免费的，适合测试和开发');
      console.log('   2. 响应速度: ' + avgDuration + 'ms');
      console.log('   3. 可以用于生产环境，但要注意并发限制');
      console.log('   4. 配置方法:');
      console.log('      export API_BASE_URL=https://api.openai.com/v1');
      console.log('      export API_KEY=your_api_key_here\n');

    } catch (err) {
      console.error('❌ 模型调用失败:', err.message);
      if (err.response) {
        console.error('   状态码:', err.response.status);
        console.error('   错误:', JSON.stringify(err.response.data, null, 2));
      }
      process.exit(1);
    }

  } catch (err) {
    console.error('❌ 测试失败:', err.message);
    process.exit(1);
  }
}

// 运行测试
testArceeModel();
