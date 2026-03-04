# 统一API接口

## 概述
统一API接口提供统一的系统访问方式，屏蔽底层实现细节，提供一致的调用体验。

## API架构

### 核心组件

#### 1. API网关
```typescript
class APIGateway {
  private handlers: Map<string, APIHandler> = new Map();
  private middleware: Middleware[] = [];

  registerHandler(path: string, handler: APIHandler): void {
    this.handlers.set(path, handler);
  }

  registerMiddleware(middleware: Middleware): void {
    this.middleware.push(middleware);
  }

  async handle(request: APIRequest): Promise<APIResponse> {
    // 执行中间件
    let context = { request };
    for (const mw of this.middleware) {
      context = await mw(context);
    }

    // 路由到对应处理器
    const handler = this.handlers.get(context.request.path);
    if (!handler) {
      return {
        success: false,
        error: 'Route not found',
        statusCode: 404
      };
    }

    // 执行处理器
    return await handler(context.request, context.state);
  }
}
```

#### 2. 统一请求格式
```typescript
interface APIRequest {
  // 请求元数据
  metadata: {
    timestamp: number;
    requestId: string;
    version: string;
    language: string;
  };

  // 路由信息
  path: string;
  method: string;

  // 请求参数
  params: Record<string, any>;
  query: Record<string, any>;
  body: any;

  // 用户上下文
  user?: {
    id: string;
    role: string;
    permissions: string[];
  };

  // 调用上下文
  context: CallContext;
}

interface CallContext {
  sessionId: string;
  startTime: number;
  source: string;
  traceId?: string;
}
```

#### 3. 统一响应格式
```typescript
interface APIResponse<T = any> {
  success: boolean;
  data?: T;
  error?: APIError;
  metadata?: {
    requestId: string;
    timestamp: number;
    duration: number;
    version: string;
  };
}

interface APIError {
  code: string;
  message: string;
  details?: any;
  statusCode?: number;
  suggestions?: string[];
}

type SuccessResponse<T> = APIResponse<T> & { success: true; data: T };
type ErrorResponse = APIResponse<never> & { success: false };
```

#### 4. 中间件系统
```typescript
interface Middleware {
  name: string;
  async execute(context: MiddlewareContext): Promise<MiddlewareContext>;
}

// 示例中间件
class AuthenticationMiddleware implements Middleware {
  name = 'authentication';

  async execute(context: MiddlewareContext): Promise<MiddlewareContext> {
    // 验证身份
    if (!context.user) {
      throw new UnauthorizedError('未授权访问');
    }

    // 检查权限
    const hasPermission = context.request.user?.permissions?.includes(
      context.request.metadata.permission
    );

    if (!hasPermission) {
      throw new ForbiddenError('权限不足');
    }

    return context;
  }
}

class LoggingMiddleware implements Middleware {
  name = 'logging';

  async execute(context: MiddlewareContext): Promise<MiddlewareContext> {
    const start = Date.now();

    try {
      const result = await this.next(context);
      const duration = Date.now() - start;

      this.logRequest(context, duration);
      return result;
    } catch (error) {
      const duration = Date.now() - start;
      this.logError(context, error, duration);
      throw error;
    }
  }

  private logRequest(context: MiddlewareContext, duration: number): void {
    console.log('请求日志', {
      method: context.request.method,
      path: context.request.path,
      requestId: context.request.metadata.requestId,
      duration: `${duration}ms`,
      user: context.request.user?.id
    });
  }

  private logError(
    context: MiddlewareContext,
    error: Error,
    duration: number
  ): void {
    console.error('错误日志', {
      method: context.request.method,
      path: context.request.path,
      requestId: context.request.metadata.requestId,
      duration: `${duration}ms`,
      error: error.message,
      stack: error.stack
    });
  }
}
```

## 核心接口

### 1. 系统状态接口
```typescript
class SystemStatusAPI {
  @apiHandler('GET', '/system/status')
  async getStatus(request: APIRequest): Promise<SuccessResponse<SystemStatus>> {
    return {
      success: true,
      data: {
        version: '1.0.0',
        uptime: process.uptime(),
        memory: process.memoryUsage(),
        cpu: process.cpuUsage(),
        services: this.getServiceStatus(),
        timestamp: new Date().toISOString()
      }
    };
  }

  @apiHandler('GET', '/system/services')
  async getServices(request: APIRequest): Promise<SuccessResponse<ServiceStatus[]>> {
    return {
      success: true,
      data: await this.getAllServicesStatus()
    };
  }

  private async getServiceStatus(): Promise<ServiceStatus> {
    return {
      copilot: await this.checkCopilotStatus(),
      autoGpt: await this.checkAutoGptStatus(),
      rag: await this.checkRagStatus(),
      promptEngineering: await this.checkPromptEngineeringStatus()
    };
  }
}
```

### 2. 任务管理接口
```typescript
class TaskManagementAPI {
  @apiHandler('POST', '/tasks')
  async createTask(request: APIRequest): Promise<SuccessResponse<Task>> {
    const task: Task = request.body;

    // 验证任务
    this.validateTask(task);

    // 创建任务
    const createdTask = await this.taskService.create(task);

    // 通知用户
    await this.notifyUser(task);

    return {
      success: true,
      data: createdTask
    };
  }

  @apiHandler('GET', '/tasks/:id')
  async getTask(request: APIRequest): Promise<SuccessResponse<Task>> {
    const task = await this.taskService.findById(request.params.id);

    if (!task) {
      return {
        success: false,
        error: { code: 'TASK_NOT_FOUND', message: '任务不存在' },
        statusCode: 404
      };
    }

    return { success: true, data: task };
  }

  @apiHandler('GET', '/tasks')
  async listTasks(request: APIRequest): Promise<SuccessResponse<Task[]>> {
    const { status, priority, limit, offset } = request.query;

    const tasks = await this.taskService.find({
      status,
      priority,
      limit: Number(limit),
      offset: Number(offset)
    });

    return { success: true, data: tasks };
  }
}
```

### 3. 技能调用接口
```typescript
class SkillCallingAPI {
  @apiHandler('POST', '/skills/:skillName')
  async callSkill(request: APIRequest): Promise<SuccessResponse<any>> {
    const { skillName } = request.params;
    const params = request.body;

    // 调用技能
    const result = await this.skillCaller.call(skillName, params);

    return {
      success: true,
      data: result,
      metadata: {
        skillName,
        executionTime: result.metadata?.executionTime
      }
    };
  }

  @apiHandler('GET', '/skills')
  async listSkills(request: APIRequest): Promise<SuccessResponse<SkillInfo[]>> {
    const skills = this.skillRegistry.getAvailableSkills();

    return {
      success: true,
      data: skills.map(skill => ({
        name: skill.name,
        description: skill.description,
        version: skill.version,
        enabled: skill.enabled
      }))
    };
  }
}
```

### 4. 知识检索接口
```typescript
class KnowledgeRetrievalAPI {
  @apiHandler('POST', '/knowledge/query')
  async queryKnowledge(request: APIRequest): Promise<SuccessResponse<RetrievalResult>> {
    const { query, topK = 5, filters } = request.body;

    const results = await this.ragEngine.search({
      query,
      topK,
      filters,
      context: request.context
    });

    return {
      success: true,
      data: {
        results: results.documents,
        metadata: {
          queryTime: results.metadata.queryTime,
          totalResults: results.documents.length
        }
      }
    };
  }

  @apiHandler('GET', '/knowledge/documents')
  async listDocuments(request: APIRequest): Promise<SuccessResponse<DocumentInfo[]>> {
    const { category, limit, offset } = request.query;

    const documents = await this.ragEngine.listDocuments({
      category,
      limit: Number(limit),
      offset: Number(offset)
    });

    return {
      success: true,
      data: documents
    };
  }
}
```

### 5. 配置管理接口
```typescript
class ConfigurationAPI {
  @apiHandler('GET', '/config')
  async getConfig(request: APIRequest): Promise<Success<Config>> {
    // 返回配置（排除敏感信息）
    return {
      success: true,
      data: this.configService.getPublicConfig()
    };
  }

  @apiHandler('PUT', '/config')
  async updateConfig(request: APIRequest): Promise<Success<Config>> {
    const updates = request.body;

    // 验证更新
    this.validateConfigUpdates(updates);

    // 更新配置
    const updatedConfig = await this.configService.update(updates);

    return {
      success: true,
      data: updatedConfig
    };
  }

  @apiHandler('GET', '/config/validate')
  async validateConfig(request: APIRequest): Promise<Success<ValidationResult>> {
    const config = request.body;

    const result = await this.configService.validate(config);

    return {
      success: true,
      data: {
        valid: result.valid,
        errors: result.errors,
        warnings: result.warnings
      }
    };
  }
}
```

## 错误处理

### 统一错误类
```typescript
class APIError extends Error {
  constructor(
    public code: string,
    public message: string,
    public statusCode: number = 500,
    public suggestions: string[] = []
  ) {
    super(message);
    this.name = 'APIError';
  }
}

class ValidationError extends APIError {
  constructor(message: string, details?: any) {
    super('VALIDATION_ERROR', message, 400, [
      '检查输入参数',
      '确保数据格式正确'
    ]);
    this.details = details;
  }
}

class UnauthorizedError extends APIError {
  constructor(message: string = '未授权访问') {
    super('UNAUTHORIZED', message, 401, [
      '请先登录',
      '检查认证信息'
    ]);
  }
}

class ForbiddenError extends APIError {
  constructor(message: string = '权限不足') {
    super('FORBIDDEN', message, 403, [
      '检查用户权限',
      '联系管理员'
    ]);
  }
}

class NotFoundError extends APIError {
  constructor(resource: string) {
    super('NOT_FOUND', `${resource}不存在`, 404, [
      '检查资源ID',
      '确认资源是否存在'
    ]);
  }
}

class ConflictError extends APIError {
  constructor(message: string = '资源冲突') {
    super('CONFLICT', message, 409, [
      '检查资源状态',
      '确认是否已存在'
    ]);
  }
}
```

### 错误响应
```typescript
function createErrorResponse(error: Error): ErrorResponse {
  return {
    success: false,
    error: {
      code: error instanceof APIError ? error.code : 'INTERNAL_ERROR',
      message: error.message,
      statusCode: error instanceof APIError ? error.statusCode : 500,
      suggestions: error instanceof APIError ? error.suggestions : []
    },
    metadata: {
      requestId: context.requestId,
      timestamp: new Date().toISOString()
    }
  };
}
```

## 调用示例

### REST API调用
```bash
# 创建任务
curl -X POST http://localhost:3000/tasks \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer token" \
  -d '{
    "name": "代码审查",
    "description": "审查React组件",
    "priority": "high"
  }'

# 查询系统状态
curl http://localhost:3000/system/status

# 调用技能
curl -X POST http://localhost:3000/skills/copilot \
  -H "Content-Type: application/json" \
  -d '{
    "type": "review",
    "code": "const x = 1 + 2;"
  }'

# 查询知识库
curl -X POST http://localhost:3000/knowledge/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "如何配置自动备份",
    "topK": 3
  }'
```

### TypeScript调用
```typescript
// 使用统一的客户端
const client = new UnifiedClient('http://localhost:3000');

// 调用系统状态
const status = await client.system.getStatus();

// 创建任务
const task = await client.tasks.create({
  name: '代码审查',
  priority: 'high'
});

// 调用技能
const result = await client.skills.call('copilot', {
  type: 'review',
  code: componentCode
});

// 查询知识库
const knowledge = await client.knowledge.query({
  query: 'React组件最佳实践'
});

// 更新配置
await client.config.update({
  copilot: { enabled: true }
});
```

## 性能优化

### 1. 响应缓存
```typescript
class CachedAPIHandler implements APIHandler {
  constructor(
    private handler: APIHandler,
    private cache: Cache,
    private ttl: number = 60000
  ) {}

  async handle(request: APIRequest, state: CallState): Promise<APIResponse> {
    const cacheKey = this.generateCacheKey(request);

    // 检查缓存
    const cached = await this.cache.get(cacheKey);
    if (cached) {
      return cached;
    }

    // 执行处理器
    const result = await this.handler.handle(request, state);

    // 缓存结果
    await this.cache.set(cacheKey, result, this.ttl);

    return result;
  }

  private generateCacheKey(request: APIRequest): string {
    return `${request.method}:${request.path}:${JSON.stringify(request.body)}`;
  }
}
```

### 2. 批量请求
```typescript
class BatchRequestHandler {
  @apiHandler('POST', '/batch')
  async handleBatch(request: APIRequest): Promise<SuccessResponse<BatchResponse>> {
    const { requests } = request.body;

    const results = await Promise.all(
      requests.map(req => this.executeRequest(req))
    );

    return {
      success: true,
      data: {
        results,
        summary: this.generateSummary(results)
      }
    };
  }

  private async executeRequest(req: BatchRequest): Promise<BatchResult> {
    try {
      const response = await this.gateway.handle(req);
      return {
        success: true,
        response
      };
    } catch (error) {
      return {
        success: false,
        error: error.message
      };
    }
  }
}
```

### 3. 流式响应
```typescript
class StreamingAPIHandler implements APIHandler {
  @apiHandler('GET', '/stream')
  async stream(request: APIRequest, state: CallState): Promise<void> {
    const stream = new TransformStream();

    // 发送流式响应
    request.res.writeHead(200, {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache'
    });

    const writer = stream.writable.getWriter();

    // 模拟流式数据
    for (const chunk of this.generateStreamData()) {
      await writer.write(`data: ${JSON.stringify(chunk)}\n\n`);
      await delay(1000);
    }

    await writer.close();
  }

  private async *generateStreamData(): AsyncGenerator<any> {
    yield { progress: 10, message: '开始处理...' };
    yield { progress: 30, message: '正在分析...' };
    yield { progress: 60, message: '正在生成...' };
    yield { progress: 90, message: '完成！' };
    yield { progress: 100, message: '全部完成' };
  }
}
```

## 监控和日志

### 请求追踪
```typescript
class TracingMiddleware implements Middleware {
  async execute(context: MiddlewareContext): Promise<MiddlewareContext> {
    const traceId = this.generateTraceId();
    context.request.metadata.traceId = traceId;

    // 发送追踪信息
    this.traceService.send({
      traceId,
      service: 'api-gateway',
      endpoint: context.request.path,
      method: context.request.method,
      duration: 0,
      status: 'started'
    });

    return context;
  }

  private generateTraceId(): string {
    return `trace-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }
}
```

## 安全性

### 输入验证
```typescript
class ValidationMiddleware implements Middleware {
  async execute(context: MiddlewareContext): Promise<MiddlewareContext> {
    // 验证请求格式
    this.validateRequestFormat(context.request);

    // 验证参数
    this.validateParameters(context.request);

    // 验证权限
    await this.validatePermissions(context.request);

    return context;
  }

  private validateRequestFormat(request: APIRequest): void {
    if (!request.metadata?.requestId) {
      throw new ValidationError('缺少请求ID');
    }

    if (!request.path || !request.method) {
      throw new ValidationError('缺少路径或方法');
    }
  }

  private validateParameters(request: APIRequest): void {
    // 参数类型验证
    if (request.body) {
      this.validateBody(request.body);
    }
  }

  private async validatePermissions(request: APIRequest): Promise<void> {
    // 权限验证逻辑
  }
}
```

### 响应压缩
```typescript
class CompressionMiddleware implements Middleware {
  async execute(context: MiddlewareContext): Promise<MiddlewareContext> {
    const acceptEncoding = context.request.headers['accept-encoding'];

    if (acceptEncoding?.includes('gzip')) {
      context.response.headers['Content-Encoding'] = 'gzip';
      context.useCompression = true;
    }

    return context;
  }
}
```

## 使用建议

1. **统一错误处理**: 所有错误都返回统一的格式
2. **详细的元数据**: 包含请求ID、时间戳等
3. **性能监控**: 记录所有请求的执行时间
4. **安全第一**: 始终验证输入和权限
5. **文档齐全**: 为每个端点提供详细文档

## 扩展指南

开发者可以添加新的API端点：
```typescript
// 创建新的处理器
class MyAPIHandler implements APIHandler {
  @apiHandler('GET', '/my-endpoint')
  async handle(request: APIRequest, state: CallState): Promise<APIResponse> {
    // 实现逻辑
    return { success: true, data: result };
  }
}

// 注册处理器
gateway.registerHandler('/my-endpoint', new MyAPIHandler());
```
