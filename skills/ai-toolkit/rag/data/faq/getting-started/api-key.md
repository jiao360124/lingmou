# FAQ: 如何使用API密钥？

## Question
如何在应用程序中使用API密钥？

## Answer
使用API密钥时，请遵循以下步骤：

### 1. 获取API密钥
- 登录到控制台
- 进入API密钥管理页面
- 创建新密钥

### 2. 安全配置
```javascript
// ✅ 正确方式：使用环境变量
const API_KEY = process.env.API_KEY || '';

// ❌ 错误方式：硬编码（不要这样做！）
const API_KEY = 'your-secret-key';
```

### 3. 发送请求
```javascript
// 在请求头中包含密钥
fetch('https://api.example.com/data', {
  headers: {
    'Authorization': `Bearer ${API_KEY}`,
    'Content-Type': 'application/json'
  }
});
```

## Keywords
- API密钥
- Authorization
- Bearer token
- 环境变量
- 安全配置

## Tags
- authentication
- security
- API
- best-practices

## 常见问题

### Q: API密钥泄露了怎么办？
**A**: 立即在控制台删除泄露的密钥并生成新的密钥。不要尝试在代码中隐藏泄露的密钥。

### Q: API密钥可以共享吗？
**A**: 不可以。每个API密钥应保持私密，不要在公共代码仓库中分享。

### Q: API密钥有效期多久？
**A**: 大多数API密钥是长期有效的，除非你手动删除或修改。建议定期轮换密钥。

### Q: 可以在客户端使用API密钥吗？
**A**: 一般不推荐。客户端应用容易暴露API密钥。建议使用代理服务器来处理API请求。

## 安全提示
- ✅ 使用环境变量存储密钥
- ✅ 不要提交密钥到版本控制
- ✅ 定期轮换密钥
- ✅ 使用服务端代理
- ✅ 启用API密钥限制（IP、频率）
