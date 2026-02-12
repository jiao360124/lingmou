# 统一API客户端

## 功能
- 统一API请求接口
- 标准化请求/响应格式
- 错误处理和重试
- 请求超时管理

## 使用方法

### 基础调用
```powershell
.\api-client.ps1 -Action call -Endpoint "copilot/analyze" -Payload @{
    code = "function example() { ... }"
    language = "javascript"
}
```

### 同步调用（等待结果）
```powershell
.\api-client.ps1 -Action call -Endpoint "rag/search" -Payload @{
    query = "如何使用async/await"
    limit = 5
}
```

### 异步调用（后台执行）
```powershell
.\api-client.ps1 -Action call -Async -Endpoint "auto-gpt/run" -Payload @{
    task = "分析代码质量"
}
```

### 批量调用
```powershell
.\api-client.ps1 -Action batch -Endpoints @(
    @{ endpoint = "copilot/analyze"; payload = @{ code = "..." } },
    @{ endpoint = "rag/search"; payload = @{ query = "..." } }
)
```

## API端点列表

### Copilot
- `copilot/analyze` - 代码分析
- `copilot/complement` - 代码补全
- `copilot/refactor` - 代码重构

### RAG
- `rag/search` - 知识库检索
- `rag/index` - 文档索引
- `rag/faq` - FAQ查询

### Auto-GPT
- `auto-gpt/run` - 执行任务
- `auto-gpt/stop` - 停止任务
- `auto-gpt/status` - 查询状态

## 参数说明

### 必需参数
- `Action`: 操作类型
- `Endpoint`: API端点

### 可选参数
- `Payload`: 请求负载（JSON格式）
- `Async`: 是否异步执行
- `Timeout`: 超时时间（秒）
- `Retry`: 重试次数

## 错误处理

系统会自动处理以下错误：
- 网络超时
- API错误
- 参数验证失败
- 资源不可用

错误详情会通过返回对象传递：
```powershell
{
    success = $false
    error = "Error message"
    details = { ... }
}
```
