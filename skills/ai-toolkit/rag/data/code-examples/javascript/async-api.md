# 代码示例: 异步API调用

## 描述
使用fetch API进行异步HTTP请求，支持错误处理和响应解析

## 代码
```javascript
async function fetchData(url, options = {}) {
  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), options.timeout || 10000);

    const response = await fetch(url, {
      ...options,
      signal: controller.signal
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const contentType = response.headers.get('content-type');
    if (contentType?.includes('application/json')) {
      return await response.json();
    }

    return await response.text();
  } catch (error) {
    if (error.name === 'AbortError') {
      throw new Error('Request timeout');
    }
    console.error('Fetch error:', error);
    throw error;
  }
}
```

## 使用
```javascript
// 基本使用
fetchData('https://api.example.com/data')
  .then(data => console.log(data))
  .catch(error => console.error(error));

// 带超时和自定义请求
fetchData('https://api.example.com/users', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ name: 'John' }),
  timeout: 5000
})
  .then(response => console.log('Success:', response))
  .catch(error => console.error('Error:', error));

// Promise链式调用
(async () => {
  try {
    const user = await fetchData('https://api.example.com/users/1');
    const posts = await fetchData(`https://api.example.com/users/${user.id}/posts`);
    console.log('User:', user);
    console.log('Posts:', posts);
  } catch (error) {
    console.error('Failed:', error);
  }
})();
```

## 说明
- ✅ 异步处理防止阻塞
- ✅ 超时控制防止卡死
- ✅ 错误处理确保健壮性
- ✅ 支持JSON和文本响应
- ✅ 可重用的通用函数

## 最佳实践
1. 总是使用try-catch处理错误
2. 设置合理的超时时间
3. 根据Content-Type正确解析响应
4. 考虑添加重试逻辑
5. 使用AbortController实现超时
