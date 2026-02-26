// 测试 Trinity 网络连接和基本功能

console.log('🚀 Trinity 网络连接测试\n');

const https = require('https');
const http = require('http');

// 测试 1: 直接 HTTP 请求测试 Trinity API
console.log('🔍 测试1: 直接HTTP请求测试 Trinity API\n');

const options = {
  hostname: 'openrouter.ai',
  port: 443,
  path: '/api/v1/chat/completions',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer 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'
  }
};

const postData = JSON.stringify({
  model: 'arcee-ai/trinity-large-preview:free',
  messages: [
    {
      role: 'user',
      content: 'Hello, can you tell me your name and what model you are? Keep it very brief.'
    }
  ],
  max_tokens: 100
});

const req = https.request(options, (res) => {
  console.log(`状态码: ${res.statusCode}`);
  console.log(`响应头: ${JSON.stringify(res.headers)}`);
  
  let responseData = '';
  res.on('data', (chunk) => {
    responseData += chunk;
  });
  
  res.on('end', () => {
    try {
      const response = JSON.parse(responseData);
      console.log('\n✅ API 响应:');
      if (response.choices && response.choices[0] && response.choices[0].message) {
        console.log('🤖 Trinity:', response.choices[0].message.content);
        console.log('📊 模型:', response.model || 'unknown');
      } else {
        console.log('❌ 响应格式异常:', response);
      }
    } catch (error) {
      console.error('❌ 解析响应失败:', error);
      console.error('原始响应:', responseData);
    }
  });
});

req.on('error', (error) => {
  console.error('❌ 请求失败:', error);
});

req.write(postData);
req.end();

console.log('\n🔍 测试2: 测试简短响应\n');
setTimeout(() => {
  console.log('如果长时间没有响应，可能是网络或API Key问题');
  console.log('建议检查:');
  console.log('1. API Key 是否有效');
  console.log('2. 网络连接是否正常');
  console.log('3. OpenRouter 服务是否可用');
}, 5000);