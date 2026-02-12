# LangChain使用示例

## 概述
本目录包含LangChain技能的详细使用示例和最佳实践。

## 1. 基础使用示例

### 1.1 简单对话Agent

```typescript
import { LLMProviderManager, MessageManager, ReactAgent } from './langchain';

// 初始化LLM提供商
const llmProvider = new LLMProviderManager();
await llmProvider.initialize('openai', {
  apiKey: process.env.OPENAI_API_KEY!,
  model: 'gpt-4',
  temperature: 0.7
});

// 创建Agent
const agent = new ReactAgent(
  'Simple Assistant',
  'react',
  llmProvider,
  new MemoryManager()
);

// 运行对话
const response = await agent.run('你好！你能帮我做什么？');

console.log(response);
// 输出: 成功完成，包含对话历史和总结
```

### 1.2 代码生成Agent

```typescript
const codingAgent = new ReactAgent(
  'Code Generator',
  'react',
  llmProvider,
  new MemoryManager()
);

// 生成代码
const codeResult = await codingAgent.run(`
  请生成一个React组件，功能是：
  1. 显示用户列表
  2. 支持搜索功能
  3. 支持按角色过滤
  4. 使用TypeScript
  5. 添加错误处理
`);

if (codeResult.success) {
  console.log('生成的代码:', codeResult.data);
}
```

## 2. Chain使用示例

### 2.1 串行Chain - 文档生成

```typescript
import { SequentialChain, ChainType } from './langchain';

const documentChain = new SequentialChain(
  'Document Generator',
  ChainType.SEQUENTIAL,
  llmProvider,
  new MemoryManager()
);

// 添加Chain步骤
documentChain.addChain({
  name: 'Topic Analysis',
  type: 'function',
  async execute(input) {
    return `已分析主题: ${input.topic}`;
  },
  validate(input) {
    return !!input.topic;
  }
});

documentChain.addChain({
  name: 'Content Generation',
  type: 'function',
  async execute(input) {
    return `生成内容: ${input.topic}的详细介绍`;
  },
  validate(input) {
    return !!input.content;
  }
});

documentChain.addChain({
  name: 'Format Final',
  type: 'function',
  async execute(input) {
    return {
      title: input.topic,
      content: input.content,
      format: 'markdown',
      timestamp: new Date().toISOString()
    };
  },
  validate(input) {
    return input.title && input.content;
  }
});

// 执行Chain
const result = await documentChain.execute({
  topic: '人工智能',
  content: '关于AI的详细介绍'
});

console.log(result);
```

### 2.2 并行Chain - 多渠道内容生成

```typescript
import { ParallelChain } from './langchain';

const contentChain = new ParallelChain(
  'Multi-Channel Content',
  ChainType.PARALLEL,
  llmProvider,
  new MemoryManager()
);

// 添加多个生成步骤
contentChain.addChain({
  name: 'Twitter Post',
  type: 'function',
  async execute(input) {
    return {
      platform: 'twitter',
      content: `关于${input.topic}的简短介绍: ${input.shortDescription}`
    };
  },
  validate(input) {
    return input.topic && input.shortDescription;
  }
});

contentChain.addChain({
  name: 'LinkedIn Article',
  type: 'function',
  async execute(input) {
    return {
      platform: 'linkedin',
      content: `深度分析${input.topic}: ${input.detailedDescription}`
    };
  },
  validate(input) {
    return input.topic && input.detailedDescription;
  }
});

contentChain.addChain({
  name: 'Blog Post',
  type: 'function',
  async execute(input) {
    return {
      platform: 'blog',
      content: `详细的${input.topic}指南\n\n${input.guideline}`
    };
  },
  validate(input) {
    return input.topic && input.guideline;
  }
});

// 执行并行Chain
const result = await contentChain.execute({
  topic: 'LangChain',
  shortDescription: '强大的LLM框架',
  detailedDescription: '基于Prompt-Engineering和Auto-GPT的增强版框架',
  guideline: '使用清晰的步骤和例子'
});

console.log(result.summary);
// 输出: 总共3个Chain，全部成功
```

### 2.3 条件Chain - 智能路由

```typescript
import { ConditionalChain, ChainType } from './langchain';

const smartChain = new ConditionalChain(
  'Smart Routing',
  ChainType.CONDITIONAL,
  llmProvider,
  new MemoryManager()
);

// 添加条件
smartChain.addCondition({
  name: 'Code Generation Condition',
  async evaluate(input) {
    // 检查是否包含代码相关关键词
    const codeKeywords = ['代码', 'function', 'component', 'script'];
    const hasCodeKeywords = codeKeywords.some(keyword =>
      input.query.toLowerCase().includes(keyword)
    );

    return {
      passed: hasCodeKeywords,
      input,
      chain: codeChain,
      reason: hasCodeKeywords ? '检测到代码生成请求' : '非代码生成请求'
    };
  }
});

smartChain.addCondition({
  name: 'Question Answering',
  async evaluate(input) {
    return {
      passed: true,
      input,
      chain: qaChain,
      reason: '通用问答请求'
    };
  }
});

// 执行智能路由Chain
const result = await smartChain.execute({
  query: '如何创建一个React组件？'
});

console.log(result);
```

## 3. 工具集成示例

### 3.1 文件操作工具

```typescript
import { FileTool } from './langchain';

const fileTool = new FileTool(llmProvider);

// 读取文件
const readFileResult = await fileTool.execute({
  action: 'read',
  path: 'README.md'
});

if (readFileResult.success) {
  console.log('文件内容:', readFileResult.data);
}

// 写入文件
const writeFileResult = await fileTool.execute({
  action: 'write',
  path: 'output.md',
  content: '# 输出文件\n\n这是自动生成的文件。'
});

if (writeFileResult.success) {
  console.log('文件已写入');
}

// 列出文件
const listResult = await fileTool.execute({
  action: 'list',
  path: './'
});

if (listResult.success) {
  console.log('文件列表:', listResult.data);
}
```

### 3.2 搜索工具

```typescript
import { SearchTool } from './langchain';

const searchTool = new SearchTool(llmProvider);

// 网络搜索
const webSearchResult = await searchTool.execute({
  query: 'LangChain最新功能',
  source: 'web'
});

console.log('网络搜索结果:', webSearchResult.data);

// 本地搜索
const localSearchResult = await searchTool.execute({
  query: '如何优化LLM性能',
  source: 'local'
});

console.log('本地搜索结果:', localSearchResult.data);
```

### 3.3 自定义工具

```typescript
class CalculatorTool extends BaseTool {
  constructor(llmProvider: LLMProviderManager) {
    super('calculator', '计算器工具', llmProvider);
  }

  async execute(params: ToolParams): Promise<ToolResult> {
    const { expression } = params;

    try {
      // 安全地执行计算
      const result = Function('"use strict"; return (' + expression + ')')();

      if (isNaN(result) || !isFinite(result)) {
        throw new Error('无效的计算结果');
      }

      return {
        success: true,
        data: {
          expression,
          result
        },
        tool: this.name,
        action: 'calculate'
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
        tool: this.name,
        action: 'calculate'
      };
    }
  }

  validate(params: ToolParams): boolean {
    const { expression } = params;
    if (!expression) return false;

    // 简单的验证，实际应该更严格
    try {
      new Function('"use strict"; return (' + expression + ')');
      return true;
    } catch {
      return false;
    }
  }
}

// 使用自定义工具
const calculatorTool = new CalculatorTool(llmProvider);
agent.addTool(calculatorTool);

const calcResult = await agent.run('计算 123 + 456');
console.log(calcResult);
```

## 4. 记忆管理示例

### 4.1 记忆存储和检索

```typescript
const memory = new MemoryManager();

// 存储记忆
memory.addMemory({
  type: 'user_preference',
  content: { theme: 'dark', language: 'zh-CN' },
  metadata: {
    timestamp: new Date().toISOString(),
    userId: 'user123'
  }
});

memory.addMemory({
  type: 'conversation',
  content: { message: '你好', response: '你好！有什么可以帮你？' },
  metadata: {
    timestamp: new Date().toISOString(),
    chain: 'greeting'
  }
});

// 检索记忆
const relevantMemories = await memory.retrieveMemory('偏好设置', 5);
console.log('相关记忆:', relevantMemories);

// 获取最近记忆
const recentMemories = await memory.getRecentMemories(10, 7);
console.log('最近7天记忆:', recentMemories);

// 记忆统计
const stats = memory.getMemoryStats();
console.log('记忆统计:', stats);
```

### 4.2 长期记忆管理

```typescript
class LongTermMemory extends MemoryManager {
  private storage: Map<string, Memory[]> = new Map();

  async saveToStorage(userId: string): Promise<void> {
    if (!this.storage.has(userId)) {
      this.storage.set(userId, []);
    }

    const userMemories = this.storage.get(userId)!;
    userMemories.push(...this.memories);

    // 限制每个用户的记忆数量
    if (userMemories.length > 1000) {
      userMemories.splice(0, userMemories.length - 1000);
    }
  }

  async loadFromStorage(userId: string): Promise<void> {
    const userMemories = this.storage.get(userId) || [];
    this.memories = [...this.memories, ...userMemories];
  }
}
```

## 5. 高级用法示例

### 5.1 多Agent协作

```typescript
// 创建多个Agent
const plannerAgent = new ReactAgent(
  'Planner',
  'react',
  llmProvider,
  new MemoryManager()
);

const executorAgent = new ReactAgent(
  'Executor',
  'react',
  llmProvider,
  new MemoryManager()
);

// Planner负责规划
const plan = await plannerAgent.plan('写一个Python爬虫');
console.log('计划:', plan);

// Executor负责执行
for (const step of plan) {
  const result = await executorAgent.execute(step);
  console.log(`步骤 ${step} 完成:`, result);
}
```

### 5.2 流式执行

```typescript
for await (const step of streamingChainExecution(chain)) {
  console.log(`进度: ${step.progress}%`);
  console.log(`步骤: ${step.step}`);
  console.log(`结果:`, step.result);

  // 实时显示结果
  // 可以发送到前端或其他UI
}
```

### 5.3 自定义Agent模式

```typescript
class CustomAgent extends BaseAgent {
  async plan(input: string): Promise<string[]> {
    // 自定义规划逻辑
    return ['分析', '设计', '实现', '测试'];
  }

  async execute(step: string): Promise<any> {
    // 自定义执行逻辑
    if (step === '设计') {
      return this.designArchitecture(input);
    } else if (step === '实现') {
      return this.implement(input);
    }
    // ...
  }

  protected async observe(result: any): Promise<void> {
    // 自定义反思逻辑
    const reflection = await this.llmProvider.chat([
      MessageManager.system('反思结果并给出建议')
    ]);
    console.log('反思:', reflection);
  }
}
```

## 6. 性能优化示例

### 6.1 缓存优化

```typescript
const cache = new LLMCache();

async function smartChat(messages: Message[]): Promise<string> {
  // 生成缓存键
  const cacheKey = generateCacheKey(messages);

  // 先检查缓存
  const cached = await cache.get(cacheKey);
  if (cached) {
    return cached;
  }

  // 缓存未命中，调用LLM
  const response = await llmProvider.chat(messages);

  // 存入缓存
  await cache.set(cacheKey, response);

  return response;
}
```

### 6.2 并行执行优化

```typescript
async function batchExecute(chains: Chain[], input: any) {
  const promises = chains.map(chain => chain.execute(input));
  const results = await Promise.all(promises);

  return {
    results,
    summary: {
      total: results.length,
      successful: results.filter(r => r.success).length,
      failed: results.filter(r => !r.success).length
    }
  };
}
```

## 7. 错误处理示例

### 7.1 完整的错误处理

```typescript
async function safeChainExecution(chain: Chain, input: any) {
  try {
    const result = await chain.execute(input);

    if (result.success) {
      return {
        status: 'success',
        data: result.data,
        metadata: result.metadata
      };
    } else {
      return {
        status: 'partial_failure',
        error: result.error,
        intermediateResults: result.intermediateResults,
        metadata: result.metadata
      };
    }
  } catch (error) {
    return {
      status: 'failure',
      error: error.message,
      stack: error.stack,
      metadata: {
        chain: chain.name,
        input,
        timestamp: new Date().toISOString()
      }
    };
  }
}
```

## 8. 监控和日志示例

### 8.1 执行监控

```typescript
class ChainMonitor {
  private executions: ExecutionLog[] = [];

  async monitor(chain: Chain, input: any) {
    const start = Date.now();
    const result = await chain.execute(input);
    const duration = Date.now() - start;

    const log: ExecutionLog = {
      chainName: chain.name,
      input,
      result,
      duration,
      timestamp: new Date().toISOString()
    };

    this.executions.push(log);
    this.analyze(log);
  }

  private analyze(log: ExecutionLog) {
    // 执行分析
    if (log.result.success) {
      console.log(`✅ ${log.chainName} 成功 (${log.duration}ms)`);
    } else {
      console.log(`❌ ${log.chainName} 失败 (${log.duration}ms)`);
    }
  }

  getStats(): ExecutionStats {
    return {
      totalExecutions: this.executions.length,
      successRate: this.executions.filter(e => e.result.success).length / this.executions.length,
      averageDuration: this.executions.reduce((sum, e) => sum + e.duration, 0) / this.executions.length
    };
  }
}
```

## 最佳实践

1. **合理分解任务**: 将复杂任务分解为可管理的步骤
2. **使用适当的Chain类型**: 串行、并行、条件Chain各有所长
3. **有效使用工具**: 根据需求选择合适的工具
4. **管理记忆**: 及时存储和检索相关记忆
5. **错误处理**: 为每个步骤添加错误处理
6. **性能监控**: 监控执行时间和资源使用
7. **缓存优化**: 对重复请求使用缓存
8. **安全第一**: 验证所有输入和输出
