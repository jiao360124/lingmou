# LangChain - LLM框架集成

## 概述
LangChain是你的LLM框架集成系统，基于现有的prompt-engineering和Auto-GPT能力，提供完整的LLM应用开发框架。

## 核心能力

### 1. LLM集成

#### 1.1 多提供商支持
```typescript
class LLMProviderManager {
  private providers: Map<string, LLMProvider> = new Map();
  private currentProvider: string = 'openai';

  registerProvider(provider: LLMProvider): void {
    this.providers.set(provider.name, provider);
  }

  async initialize(providerName: string, config: LLMConfig): Promise<void> {
    this.currentProvider = providerName;
    const provider = this.providers.get(providerName);

    if (!provider) {
      throw new Error(`提供商 ${providerName} 未注册`);
    }

    await provider.initialize(config);
  }

  async chat(messages: Message[]): Promise<string> {
    const provider = this.providers.get(this.currentProvider);
    if (!provider) {
      throw new Error('LLM提供商未初始化');
    }

    return await provider.chat(messages);
  }

  async streamingChat(messages: Message[]): Promise<AsyncIterator<string>> {
    const provider = this.providers.get(this.currentProvider);
    if (!provider) {
      throw new Error('LLM提供商未初始化');
    }

    return await provider.streamingChat(messages);
  }

  async getProviderStatus(): Promise<ProviderStatus> {
    const provider = this.providers.get(this.currentProvider);
    return await provider.getStatus();
  }
}

// 支持的提供商
enum ProviderType {
  OPENAI = 'openai',
  ANTHROPIC = 'anthropic',
  GOOGLE = 'google',
  AZURE = 'azure',
  CUSTOM = 'custom'
}

interface LLMConfig {
  apiKey?: string;
  baseUrl?: string;
  model?: string;
  temperature?: number;
  maxTokens?: number;
  timeout?: number;
}

interface ProviderStatus {
  provider: string;
  connected: boolean;
  model: string;
  availableTokens: number;
  estimatedCostPerToken: number;
}
```

#### 1.2 消息管理
```typescript
class MessageManager {
  // 系统消息
  static system(content: string): Message {
    return {
      role: 'system',
      content
    };
  }

  // 用户消息
  static user(content: string): Message {
    return {
      role: 'user',
      content
    };
  }

  // 助手消息
  static assistant(content: string): Message {
    return {
      role: 'assistant',
      content
    };
  }

  // 消息历史管理
  static createMessageHistory(): Message[] {
    return [];
  }

  static addToHistory(
    history: Message[],
    message: Message
  ): Message[] {
    return [...history, message];
  }

  static truncateHistory(
    history: Message[],
    maxTokens: number
  ): Message[] {
    let tokens = 0;
    const truncated: Message[] = [];

    for (const message of history) {
      const messageTokens = this.countTokens(message);
      if (tokens + messageTokens <= maxTokens) {
        truncated.push(message);
        tokens += messageTokens;
      } else {
        break;
      }
    }

    return truncated;
  }

  private static countTokens(message: Message): number {
    // 简单的token估算（实际应该使用更精确的方法）
    return Math.ceil(message.content.length / 4);
  }
}
```

### 2. Chain管理

#### 2.1 Chain基础类
```typescript
interface Chain {
  name: string;
  type: ChainType;
  execute(input: any): Promise<ChainResult>;
  validate(input: any): boolean;
}

enum ChainType {
  SEQUENTIAL = 'sequential',
  PARALLEL = 'parallel',
  CONDITIONAL = 'conditional',
  COMPOSITE = 'composite'
}

class BaseChain implements Chain {
  name: string;
  type: ChainType;
  llmProvider: LLMProviderManager;
  memory: MemoryManager;

  constructor(
    name: string,
    type: ChainType,
    llmProvider: LLMProviderManager,
    memory: MemoryManager
  ) {
    this.name = name;
    this.type = type;
    this.llmProvider = llmProvider;
    this.memory = memory;
  }

  async execute(input: any): Promise<ChainResult> {
    throw new Error('execute方法必须实现');
  }

  validate(input: any): boolean {
    return true;
  }
}
```

#### 2.2 串行Chain
```typescript
class SequentialChain extends BaseChain {
  private chains: Chain[] = [];

  addChain(chain: Chain): void {
    this.chains.push(chain);
  }

  async execute(input: any): Promise<ChainResult> {
    let currentInput = input;
    const results: ChainResult[] = [];

    try {
      for (const chain of this.chains) {
        if (!chain.validate(currentInput)) {
          throw new Error(`${chain.name} 验证失败`);
        }

        const result = await chain.execute(currentInput);
        results.push(result);

        // 更新输入供下一个链使用
        currentInput = result;

        // 记忆到上下文中
        await this.memory.addMemory({
          type: 'chain',
          chain: chain.name,
          input,
          result,
          timestamp: new Date().toISOString()
        });
      }

      return {
        success: true,
        data: currentInput,
        results,
        intermediateResults: results
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
        results
      };
    }
  }

  validate(input: any): boolean {
    return this.chains.every(chain => chain.validate(input));
  }
}
```

#### 2.3 并行Chain
```typescript
class ParallelChain extends BaseChain {
  private chains: Chain[] = [];

  addChain(chain: Chain): void {
    this.chains.push(chain);
  }

  async execute(input: any): Promise<ChainResult> {
    const promises = this.chains.map(async (chain) => {
      try {
        if (!chain.validate(input)) {
          throw new Error(`${chain.name} 验证失败`);
        }

        const result = await chain.execute(input);
        return {
          chainName: chain.name,
          success: true,
          result
        };
      } catch (error) {
        return {
          chainName: chain.name,
          success: false,
          error: error.message
        };
      }
    });

    const results = await Promise.all(promises);
    const successful = results.filter(r => r.success);
    const failed = results.filter(r => !r.success);

    return {
      success: successful.length > 0,
      data: results,
      intermediateResults: results,
      summary: {
        total: results.length,
        successful,
        failed
      }
    };
  }

  validate(input: any): boolean {
    return this.chains.every(chain => chain.validate(input));
  }
}
```

#### 2.4 条件Chain
```typescript
class ConditionalChain extends BaseChain {
  private conditions: Condition[] = [];

  addCondition(condition: Condition): void {
    this.conditions.push(condition);
  }

  async execute(input: any): Promise<ChainResult> {
    for (const condition of this.conditions) {
      const result = await condition.evaluate(input);

      if (result.passed) {
        return await this.executeCondition(result);
      }
    }

    return {
      success: false,
      error: '没有匹配的条件'
    };
  }

  private async executeCondition(
    conditionResult: ConditionResult
  ): Promise<ChainResult> {
    const chain = conditionResult.chain;
    return await chain.execute(conditionResult.input);
  }
}

interface Condition {
  evaluate(input: any): Promise<ConditionResult>;
  name: string;
}

interface ConditionResult {
  passed: boolean;
  input: any;
  chain: Chain;
}
```

### 3. Agent实现

#### 3.1 Agent基础类
```typescript
interface Agent {
  name: string;
  type: AgentType;
  plan(input: string): Promise<string[]>;
  execute(step: string): Promise<any>;
  observe(result: any): void;
}

enum AgentType {
  PLANNING = 'planning',
  REFLEXIVE = 'reflexive',
  SELF_REFLECTIVE = 'self-reflexive',
  REACT = 'react'
}

class BaseAgent implements Agent {
  name: string;
  type: AgentType;
  llmProvider: LLMProviderManager;
  memory: MemoryManager;
  tools: Tool[] = [];

  constructor(
    name: string,
    type: AgentType,
    llmProvider: LLMProviderManager,
    memory: MemoryManager
  ) {
    this.name = name;
    this.type = type;
    this.llmProvider = llllmProvider;
    this.memory = memory;
  }

  async plan(input: string): Promise<string[]> {
    throw new Error('plan方法必须实现');
  }

  async execute(step: string): Promise<any> {
    throw new Error('execute方法必须实现');
  }

  async run(input: string): Promise<AgentResult> {
    const steps: string[] = await this.plan(input);
    const results: any[] = [];

    for (let i = 0; i < steps.length; i++) {
      try {
        const stepResult = await this.execute(steps[i]);
        results.push(stepResult);

        // 反思观察结果
        await this.observe(stepResult);

        // 更新记忆
        await this.memory.addMemory({
          type: 'agent',
          agent: this.name,
          step: steps[i],
          result: stepResult,
          timestamp: new Date().toISOString()
        });
      } catch (error) {
        return {
          success: false,
          error: error.message,
          steps: steps.slice(0, i),
          results: results.slice(0, i),
          failedStep: steps[i]
        };
      }
    }

    return {
      success: true,
      data: results,
      steps,
      summary: this.generateSummary(results)
    };
  }

  protected async observe(result: any): Promise<void> {
    // Agent可以在这里添加反思逻辑
  }

  protected generateSummary(results: any[]): string {
    return `成功完成${results.length}个步骤`;
  }

  addTool(tool: Tool): void {
    this.tools.push(tool);
  }
}
```

#### 3.2 Planning Agent
```typescript
class PlanningAgent extends BaseAgent {
  async plan(input: string): Promise<string[]> {
    const systemPrompt = `
你是一个规划者。你的任务是分析用户请求并分解成可执行的步骤。

用户请求：${input}

请返回一个步骤列表，每一步都是明确的、可执行的。
格式：
1. [步骤1描述]
2. [步骤2描述]
3. [步骤3描述]
...（不要超过10个步骤）
`;

    const response = await this.llmProvider.chat([
      MessageManager.system(systemPrompt),
      MessageManager.user(input)
    ]);

    // 解析步骤
    return this.parseSteps(response);
  }

  private parseSteps(response: string): string[] {
    const steps: string[] = [];
    const lines = response.split('\n');

    for (const line of lines) {
      const match = line.match(/^(\d+)\.\s*(.+)$/);
      if (match) {
        steps.push(match[2].trim());
      }
    }

    return steps;
  }

  async execute(step: string): Promise<any> {
    // 执行单个步骤
    return {
      step,
      status: 'completed',
      timestamp: new Date().toISOString()
    };
  }
}
```

#### 3.3 ReACT Agent
```typescript
class ReactAgent extends BaseAgent {
  private thoughtPattern: string = `
你是一个反思型Agent（ReACT）。请按照以下模式思考：
1. Thought: 分析当前状态和问题
2. Action: 决定采取什么行动
3. Observation: 执行行动并获得观察结果
4. Thought: 基于观察结果继续思考

开始分析：${input}
`;

  async plan(input: string): Promise<string[]> {
    return ['分析输入', '确定行动', '执行行动', '观察结果', '总结'];
  }

  async execute(step: string): Promise<any> {
    const actions = {
      '分析输入': async () => {
        return {
          step,
          action: 'analyze',
          result: '已分析输入，理解用户意图'
        };
      },
      '确定行动': async () => {
        return {
          step,
          action: 'determine_action',
          result: '已确定执行计划'
        };
      },
      '执行行动': async () => {
        return {
          step,
          action: 'execute',
          result: '行动已执行'
        };
      },
      '观察结果': async () => {
        return {
          step,
          action: 'observe',
          result: '结果已观察'
        };
      },
      '总结': async () => {
        return {
          step,
          action: 'summarize',
          result: '任务完成'
        };
      }
    };

    const action = actions[step as keyof typeof actions];
    return await action?.() || { step, error: '未知步骤' };
  }

  protected async observe(result: any): Promise<void> {
    // 反思观察结果
    const systemPrompt = `
观察结果：${JSON.stringify(result)}

请评估结果的质量，并给出下一步建议。
`;

    const reflection = await this.llmProvider.chat([
      MessageManager.system(systemPrompt)
    ]);

    console.log('反思:', reflection);
  }
}
```

### 4. 工具集成

#### 4.1 工具基础类
```typescript
interface Tool {
  name: string;
  description: string;
  execute(params: ToolParams): Promise<ToolResult>;
  validate(params: ToolParams): boolean;
}

class BaseTool implements Tool {
  name: string;
  description: string;
  llmProvider: LLMProviderManager;

  constructor(name: string, description: string, llmProvider: LLMProviderManager) {
    this.name = name;
    this.description = description;
    this.llmProvider = llmProvider;
  }

  async execute(params: ToolParams): Promise<ToolResult> {
    throw new Error('execute方法必须实现');
  }

  validate(params: ToolParams): boolean {
    return true;
  }
}
```

#### 4.2 文件工具
```typescript
class FileTool extends BaseTool {
  constructor(llmProvider: LLMProviderManager) {
    super('file', '文件操作工具', llmProvider);
  }

  async execute(params: ToolParams): Promise<ToolResult> {
    const { action, path, content } = params;

    try {
      switch (action) {
        case 'read':
          return await this.readFile(path);

        case 'write':
          return await this.writeFile(path, content);

        case 'append':
          return await this.appendFile(path, content);

        case 'list':
          return await this.listFiles(path);

        case 'delete':
          return await this.deleteFile(path);

        default:
          throw new Error(`未知操作: ${action}`);
      }
    } catch (error) {
      return {
        success: false,
        error: error.message,
        tool: this.name,
        action
      };
    }
  }

  async readFile(path: string): Promise<ToolResult> {
    const content = await fs.promises.readFile(path, 'utf-8');
    return {
      success: true,
      data: content,
      tool: this.name,
      action: 'read'
    };
  }

  async writeFile(path: string, content: string): Promise<ToolResult> {
    await fs.promises.writeFile(path, content, 'utf-8');
    return {
      success: true,
      data: { path, bytesWritten: content.length },
      tool: this.name,
      action: 'write'
    };
  }

  validate(params: ToolParams): boolean {
    const { action, path } = params;

    if (!action || !path) {
      return false;
    }

    const validActions = ['read', 'write', 'append', 'list', 'delete'];
    if (!validActions.includes(action)) {
      return false;
    }

    return true;
  }
}
```

#### 4.3 搜索工具
```typescript
class SearchTool extends BaseTool {
  constructor(llmProvider: LLMProviderManager) {
    super('search', '搜索工具', llmProvider);
  }

  async execute(params: ToolParams): Promise<ToolResult> {
    const { query, source = 'web' } = params;

    try {
      if (source === 'web') {
        return await this.searchWeb(query);
      } else if (source === 'local') {
        return await this.searchLocal(query);
      } else {
        throw new Error(`不支持的搜索源: ${source}`);
      }
    } catch (error) {
      return {
        success: false,
        error: error.message,
        tool: this.name,
        query
      };
    }
  }

  private async searchWeb(query: string): Promise<ToolResult> {
    const results = await webSearch({ query, count: 10 });
    return {
      success: true,
      data: results,
      tool: this.name,
      action: 'search_web'
    };
  }

  private async searchLocal(query: string): Promise<ToolResult> {
    const results = await rag.searchKnowledge(query, { topK: 5 });
    return {
      success: true,
      data: results,
      tool: this.name,
      action: 'search_local'
    };
  }

  validate(params: ToolParams): boolean {
    const { query, source } = params;

    if (!query || query.trim().length === 0) {
      return false;
    }

    if (source && !['web', 'local'].includes(source)) {
      return false;
    }

    return true;
  }
}
```

### 5. 记忆管理

#### 5.1 记忆管理器
```typescript
class MemoryManager {
  private memories: Memory[] = [];
  private maxMemorySize: number = 100;

  addMemory(memory: Memory): void {
    this.memories.push(memory);

    // 限制记忆大小
    if (this.memories.length > this.maxMemorySize) {
      // 移除最旧的记忆
      this.memories.shift();
    }
  }

  async retrieveMemory(
    query: string,
    limit: number = 10
  ): Promise<Memory[]> {
    // 使用RAG检索相关记忆
    const results = await rag.searchKnowledge(query, { topK: limit });
    return results.map(r => ({
      type: 'memory',
      content: r,
      timestamp: r.metadata.timestamp
    }));
  }

  async getRecentMemories(
    limit: number = 10,
    days: number = 7
  ): Promise<Memory[]> {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - days);

    return this.memories.filter(m => m.timestamp > cutoff)
      .slice(-limit);
  }

  async clearMemory(type?: string): Promise<void> {
    if (type) {
      this.memories = this.memories.filter(m => m.type !== type);
    } else {
      this.memories = [];
    }
  }

  getMemoryStats(): MemoryStats {
    return {
      total: this.memories.length,
      types: this.countByType()
    };
  }

  private countByType(): Record<string, number> {
    const counts: Record<string, number> = {};

    for (const memory of this.memories) {
      const type = memory.type;
      counts[type] = (counts[type] || 0) + 1;
    }

    return counts;
  }
}
```

#### 5.2 记忆类型
```typescript
interface Memory {
  type: string;
  content: any;
  metadata?: {
    timestamp?: string;
    chain?: string;
    agent?: string;
    step?: string;
  };
  timestamp?: number;
}

interface MemoryStats {
  total: number;
  types: Record<string, number>;
}
```

### 6. 使用示例

#### 6.1 基础使用
```typescript
// 初始化LLM提供商
const llmProvider = new LLMProviderManager();
await llmProvider.registerProvider(new OpenAIProvider());
await llmProvider.initialize('openai', {
  apiKey: process.env.OPENAI_API_KEY,
  model: 'gpt-4',
  temperature: 0.7
});

// 创建记忆管理器
const memory = new MemoryManager();

// 创建Agent
const agent = new ReactAgent('Code Assistant', AgentType.REACT, llmProvider, memory);

// 添加工具
agent.addTool(new FileTool(llmProvider));
agent.addTool(new SearchTool(llmProvider));

// 运行Agent
const result = await agent.run('帮我写一个Python函数计算斐波那契数列');
console.log(result);
```

#### 6.2 使用Chain
```typescript
// 创建链
const chain = new SequentialChain(
  'text-generation-chain',
  ChainType.SEQUENTIAL,
  llmProvider,
  memory
);

// 添加链步骤
chain.addChain(new PromptTemplateChain(llmProvider));
chain.addChain(new LLMChain(llmProvider));
chain.addChain(new ResponseFormatter());

// 执行链
const result = await chain.execute({
  prompt: '生成一个Python代码示例',
  format: 'markdown'
});

console.log(result);
```

## 工具集成示例

### 集成现有技能
```typescript
// 将Auto-GPT作为工具
class AutoGPTTool extends BaseTool {
  constructor(private autoGPT: AutoGPT) {
    super('auto-gpt', 'Auto-GPT自动化工具', autoGPT.llmProvider);
  }

  async execute(params: ToolParams): Promise<ToolResult> {
    const { task } = params;

    const result = await this.autoGPT.execute(task);

    return {
      success: result.success,
      data: result,
      tool: this.name,
      action: 'execute_task'
    };
  }
}

// 将RAG作为工具
class RAGTool extends BaseTool {
  constructor(private rag: RAG) {
    super('rag', '知识检索工具', rag.llmProvider);
  }

  async execute(params: ToolParams): Promise<ToolResult> {
    const { query, topK = 5 } = params;

    const results = await rag.queryKnowledge(query, topK);

    return {
      success: true,
      data: results,
      tool: this.name,
      action: 'search'
    };
  }
}
```

## 性能优化

### 1. 缓存机制
```typescript
class LLMCache {
  private cache: Map<string, { response: string; timestamp: number }> = new Map();
  private ttl: number = 3600000; // 1小时

  async get(cacheKey: string): Promise<string | undefined> {
    const entry = this.cache.get(cacheKey);

    if (!entry) {
      return undefined;
    }

    // 检查是否过期
    if (Date.now() - entry.timestamp > this.ttl) {
      this.cache.delete(cacheKey);
      return undefined;
    }

    return entry.response;
  }

  async set(cacheKey: string, response: string): Promise<void> {
    this.cache.set(cacheKey, {
      response,
      timestamp: Date.now()
    });
  }
}
```

### 2. 流式处理
```typescript
async* streamingChainExecution(chain: Chain): AsyncGenerator<ChainStep> {
  const steps = chain.plan();

  for (const step of steps) {
    const result = await chain.executeStep(step);

    yield {
      step,
      result,
      progress: this.calculateProgress(steps.indexOf(step), steps.length)
    };
  }
}
```

## 最佳实践

1. **合理的Chain设计**: 将复杂任务分解为简单的步骤
2. **工具选择**: 根据需求选择合适的工具
3. **记忆管理**: 及时清理和检索记忆
4. **错误处理**: 为每个步骤添加错误处理
5. **性能监控**: 监控执行时间和资源使用
6. **成本控制**: 限制token使用，监控API调用成本

## 扩展指南

开发者可以添加：
- 新的LLM提供商集成
- 自定义Chain类型
- 新的工具实现
- 高级Agent模式
- 记忆压缩和检索优化
