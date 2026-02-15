// 简单测试 Route Engine

console.log('🔧 Testing Route Engine initialization...\n');

// 模拟配置文件
const config = {
  models: [
    {
      "id": "zai/glm-4.7-flash",
      "alias": "GLM",
      "provider": "zai",
      "tier": 1
    },
    {
      "id": "zai/glm-4.5-flash",
      "alias": "GLM-450",
      "provider": "zai",
      "tier": 2
    },
    {
      "id": "zai/glm-4-flash-250414",
      "alias": "GLM-4-2504",
      "provider": "zai",
      "tier": 3
    },
    {
      "id": "arcee-ai/trinity-large-preview:free",
      "alias": "TRINITY-FREE",
      "provider": "openrouter",
      "tier": 4,
      "fallback": true
    }
  ]
};

console.log('Testing Route Engine with configuration...');
console.log('Models:', JSON.stringify(config.models, null, 2));
