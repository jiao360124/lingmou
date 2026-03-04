# 📊 arcee-ai/trinity-large-preview:free 模型测试指南

**模型信息**:
- 模型名称: arcee-ai/trinity-large-preview:free
- 类型: OpenAI 兼容模型
- 定价: 免费
- 位置: https://arcee.ai/

---

## 🔑 步骤1: 获取 API Key

### 方式1: 注册 arcee.ai
1. 访问 https://arcee.ai/
2. 注册账号（免费）
3. 进入 API Dashboard
4. 生成 API Key

### 方式2: 使用现有 API Key
如果你有 OpenAI API Key 或其他兼容 API Key，可以直接使用。

---

## 🧪 步骤2: 测试模型

### 命令行测试
```bash
# 设置 API Key
export API_KEY=your_api_key_here

# 运行测试
cd openclaw-3.0
node test-arcee-model.js
```

### 带参数测试
```bash
node test-arcee-model.js
```

### 使用 curl 测试
```bash
curl https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "model": "arcee-ai/trinity-large-preview:free",
    "messages": [
      {"role": "user", "content": "你好，请介绍一下自己"}
    ],
    "max_tokens": 100
  }'
```

---

## 📊 预期测试结果

### 测试内容
1. ✅ API 连接测试
2. ✅ 模型可用性检查
3. ✅ 单次消息响应测试
4. ✅ 多轮对话测试
5. ✅ 性能测试（3次调用）
6. ✅ 成本估算

### 成功指标
- API 连接成功
- 模型响应正常
- 延迟合理（通常 < 5000ms）
- Token 计数准确

---

## 💡 使用示例

### 在代码中使用
```javascript
const axios = require('axios');

const response = await axios.post('https://api.openai.com/v1/chat/completions', {
  model: 'arcee-ai/trinity-large-preview:free',
  messages: [
    { role: 'user', content: '你好' }
  ]
}, {
  headers: {
    'Authorization': 'Bearer YOUR_API_KEY'
  }
});

console.log(response.data.choices[0].message.content);
```

### 在 OpenClaw 3.0 中使用
修改 `config.json`:
```json
{
  "apiBaseURL": "https://api.openai.com/v1",
  "apiKey": "your_api_key_here"
}
```

---

## ⚠️ 注意事项

1. **免费限制**: 该模型有调用限制
2. **速率限制**: 注意并发请求限制
3. **网络连接**: 需要访问 api.openai.com 或 arcee API
4. **API Key 安全**: 不要将 API Key 提交到版本控制系统

---

## 🔧 故障排查

### 问题1: API Key 无效
**解决**: 检查 API Key 是否正确，是否过期

### 问题2: 模型不存在
**解决**: 检查模型名称是否正确，或使用列表接口查询可用模型

### 问题3: 网络连接失败
**解决**:
- 检查网络连接
- 确认 API 端点可访问
- 可能需要使用代理

### 问题4: 请求超时
**解决**: 增加超时时间或检查网络状况

---

## 📞 获取帮助

- arcee.ai 官网: https://arcee.ai/
- API 文档: https://arcee.ai/docs
- GitHub Issues: https://github.com/arcee-ai

---

**祝测试顺利！** 🚀
