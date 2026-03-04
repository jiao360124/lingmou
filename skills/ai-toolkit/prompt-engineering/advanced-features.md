# LangChain高级功能

## 概述
扩展LangChain技能，添加更多高级功能和实用工具。

## 1. 高级Chain类型

### 1.1 Self-Improving Chain（自我改进Chain）
```typescript
class SelfImprovingChain extends BaseChain {
  private improvementHistory: Improvement[] = [];

  async execute(input: any): Promise<ChainResult> {
    let currentInput = input;
    const iterations: any[] = [];
    const maxIterations = 5;

    for (let i = 0; i < maxIterations; i++) {
      // 1. 执行当前链
      const result = await this.executeCurrentChain(currentInput);

      // 2. 检查结果质量
      const quality = await this.evaluateQuality(result);

      // 3. 如果质量不够，改进
      if (!quality.sufficient) {
        // 4. 自我反思和改进
        const improvement = await this.improveChain(result, quality);

        // 5. 更新链配置
        this.applyImprovement(improvement);

        // 6. 记录改进
        this.improvementHistory.push(improvement);
      } else {
        // 质量足够，完成
        return result;
      }

      iterations.push({
        iteration: i + 1,
        result,
        quality
      });

      // 避免无限循环
      if (iterations.length >= maxIterations) {
        break;
      }
    }

    return {
      success: true,
      data: iterations[iterations.length - 1]?.result || iterations[0]?.result,
      results: iterations,
      metadata: {
        iterations: iterations.length,
        improvements: this.improvementHistory.length,
        totalImprovements: this.improvementHistory
      }
    };
  }

  private async improveChain(
    result: any,
    quality: QualityMetrics
  ): Promise<Improvement> {
    // 使用LLM生成改进建议
    const systemPrompt = `
你是一个链改进专家。请分析以下结果的质量，并提出改进建议。

当前结果：
${JSON.stringify(result, null, 2)}

质量指标：
- ${quality.score}/100
- 优点：${quality.strengths.join(', ')}
- 缺点：${quality.weaknesses.join(', ')}

请提出具体的改进建议，包括：
1. 改进方向
2. 具体措施
3. 预期效果
`;

    const response = await this.llmProvider.chat([
      MessageManager.system(systemPrompt)
    ]);

    return {
      timestamp: new Date().toISOString(),
      score: quality.score,
      strengths: quality.strengths,
      weaknesses: quality.weaknesses,
      improvement: this.parseImprovement(response),
      applied: false
    };
  }

  private async evaluateQuality(result: any): Promise<QualityMetrics> {
    const metrics: QualityMetrics = {
      score: 0,
      strengths: [],
      weaknesses: [],
      criteria: ['accuracy', 'completeness', 'relevance']
    };

    // 使用LLM评估质量
    const response = await this.llmProvider.chat([
      MessageManager.system('请评估以下结果的质量，并给出具体指标。'),
      MessageManager.user(JSON.stringify(result))
    ]);

    return this.parseQualityMetrics(response, metrics);
  }
}

interface Improvement {
  timestamp: string;
  score: number;
  strengths: string[];
  weaknesses: string[];
  improvement: ImprovementPlan;
  applied: boolean;
}

interface ImprovementPlan {
  direction: string;
  measures: string[];
  expectedEffect: string;
}

interface QualityMetrics {
  score: number;
  strengths: string[];
  weaknesses: string[];
  criteria: string[];
}
```

### 1.2 Memory-Augmented Chain（记忆增强Chain）
```typescript
class MemoryAugmentedChain extends BaseChain {
  private memoryManager: MemoryManager;
  private memoryRetention: number = 0.7; // 记忆保留率

  async execute(input: any): Promise<ChainResult> {
    // 1. 检索相关记忆
    const relevantMemory = await this.memoryManager.retrieveMemory(
      this.getMemoryQuery(input),
      5
    );

    // 2. 将记忆注入到输入中
    const augmentedInput = this.injectMemory(input, relevantMemory);

    // 3. 执行链
    const result = await this.executeCoreChain(augmentedInput);

    // 4. 保存结果到记忆
    await this.saveToMemory(input, result);

    // 5. 更新记忆保留率
    await this.updateMemoryRetention();

    return result;
  }

  private getMemoryQuery(input: any): string {
    // 从输入生成查询
    return JSON.stringify(input);
  }

  private injectMemory(input: any, memory: Memory[]): any {
    // 将记忆注入到输入中
    return {
      ...input,
      context: {
        relevantMemory: memory.map(m => m.content),
        memoryCount: memory.length
      }
    };
  }

  private async saveToMemory(input: any, result: any): Promise<void> {
    await this.memoryManager.addMemory({
      type: 'chain_result',
      content: {
        input,
        result,
        timestamp: new Date().toISOString()
      },
      metadata: {
        chain: this.name,
        quality: await this.evaluateQuality(result)
      }
    });
  }

  private async updateMemoryRetention(): Promise<void> {
    // 根据结果质量调整记忆保留率
    const quality = await this.memoryManager.getStats();
    this.memoryRetention = Math.min(0.9, quality.accuracy * 0.9 + 0.1);
  }
}
```

### 1.3 Multi-Agent Chain（多Agent Chain）
```typescript
class MultiAgentChain extends BaseChain {
  private agents: Agent[] = [];

  addAgent(agent: Agent): void {
    this.agents.push(agent);
  }

  async execute(input: any): Promise<ChainResult> {
    const agentResults: AgentResult[] = [];

    // 并行执行所有Agent
    const promises = this.agents.map(async (agent, index) => {
      console.log(`Agent ${index + 1}/${this.agents.length}: ${agent.name}`);

      const result = await agent.run(input);
      agentResults.push({
        agentName: agent.name,
        result
      });

      return result;
    });

    await Promise.all(promises);

    // 汇总结果
    const summary = await this.aggregateResults(agentResults);

    return {
      success: summary.success,
      data: summary,
      results: agentResults,
      metadata: {
        agentCount: this.agents.length,
        successCount: agentResults.filter(r => r.result.success).length
      }
    };
  }

  private async aggregateResults(results: AgentResult[]): Promise<any> {
    const successful = results.filter(r => r.result.success);
    const failed = results.filter(r => !r.result.success);

    if (successful.length === 0) {
      return {
        success: false,
        error: '所有Agent都失败了',
        results
      };
    }

    return {
      success: true,
      data: successful.map(r => r.result.data),
      summary: {
        successfulAgents: successful.map(r => r.agentName),
        failedAgents: failed.map(r => r.agentName),
        aggregatedData: this.mergeAgentData(successful.map(r => r.result.data))
      }
    };
  }

  private mergeAgentData(data: any[]): any {
    // 合并多个Agent的结果
    return data.reduce((merged, data) => {
      return { ...merged, ...data };
    }, {});
  }
}
```

### 1.4 Iterative Refinement Chain（迭代精炼Chain）
```typescript
class IterativeRefinementChain extends BaseChain {
  private iterations: Iteration[] = [];

  async execute(input: any): Promise<ChainResult> {
    let currentResult = input;
    let qualityScore = 0;

    for (let i = 0; i < 3; i++) {
      console.log(`迭代 ${i + 1}/3`);

      // 1. 执行当前迭代
      const iterationResult = await this.executeIteration(currentResult);

      // 2. 评估质量
      const iterationQuality = await this.evaluateQuality(iterationResult);

      // 3. 记录迭代
      const iteration: Iteration = {
        iteration: i + 1,
        result: iterationResult,
        quality: iterationQuality
      };

      this.iterations.push(iteration);

      // 4. 如果质量足够，停止
      if (iterationQuality.score >= 80) {
        console.log(`✅ 质量足够，迭代${i + 1}完成`);
        break;
      }

      // 5. 使用LLM生成精炼建议
      const refinement = await this.refine(iterationResult, iterationQuality);
      currentResult = refinement;
    }

    // 返回最终结果
    return {
      success: true,
      data: currentResult,
      results: this.iterations.map(i => i.result),
      metadata: {
        iterations: this.iterations.length,
        averageQuality: this.getAverageQuality(),
        bestIteration: this.getBestIteration()
      }
    };
  }

  private async refine(
    result: any,
    quality: QualityMetrics
  ): Promise<any> {
    const systemPrompt = `
你是一个结果精炼专家。请根据以下反馈精炼结果。

当前结果：
${JSON.stringify(result, null, 2)}

质量反馈：
- 评分：${quality.score}/100
- 优点：${quality.strengths.join(', ')}
- 缺点：${quality.weaknesses.join(', ')}

请提供精炼后的结果：
`;

    return await this.llmProvider.chat([
      MessageManager.system(systemPrompt)
    ]);
  }

  private async evaluateQuality(result: any): Promise<QualityMetrics> {
    // 使用LLM评估质量
    const response = await this.llmProvider.chat([
      MessageManager.system('评估以下结果的质量，0-100分'),
      MessageManager.user(JSON.stringify(result))
    ]);

    return this.parseQualityScore(response);
  }
}

interface Iteration {
  iteration: number;
  result: any;
  quality: QualityMetrics;
}
```

## 2. 高级工具

### 2.1 RAG工具
```typescript
class RAGTool extends BaseTool {
  private rag: RAG;

  constructor(rag: RAG) {
    super('rag', '检索增强生成', rag.llmProvider);
    this.rag = rag;
  }

  async execute(params: ToolParams): Promise<ToolResult> {
    const { query, topK = 5 } = params;

    const results = await this.rag.queryKnowledge(query, {
      topK,
      filters: params.filters
    });

    return {
      success: true,
      data: results,
      tool: this.name,
      action: 'search'
    };
  }

  validate(params: ToolParams): boolean {
    const { query } = params;
    return !!query && query.trim().length > 0;
  }
}
```

### 2.2 计算工具
```typescript
class CalculatorTool extends BaseTool {
  constructor(llmProvider: LLMProviderManager) {
    super('calculator', '计算器工具', llmProvider);
  }

  async execute(params: ToolParams): Promise<ToolResult> {
    const { expression } = params;

    try {
      // 安全执行计算
      const result = Function('"use strict"; return (' + expression + ')')();

      if (isNaN(result) || !isFinite(result)) {
        throw new Error('无效的计算结果');
      }

      return {
        success: true,
        data: {
          expression,
          result,
          numericResult: Number(result)
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

    try {
      new Function('"use strict"; return (' + expression + ')');
      return true;
    } catch {
      return false;
    }
  }
}
```

### 2.3 文件分析工具
```typescript
class FileAnalysisTool extends BaseTool {
  constructor(llmProvider: LLMProviderManager) {
    super('file-analysis', '文件分析工具', llmProvider);
  }

  async execute(params: ToolParams): Promise<ToolResult> {
    const { action, path } = params;

    try {
      switch (action) {
        case 'analyze':
          return await this.analyzeFile(path);

        case 'extract-code':
          return await this.extractCode(path);

        case 'summarize':
          return await this.summarizeFile(path);

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

  private async analyzeFile(path: string): Promise<ToolResult> {
    const content = await fs.promises.readFile(path, 'utf-8');
    const stats = await fs.promises.stat(path);

    // 使用LLM分析文件
    const analysis = await this.analyzeWithLLM(content, path);

    return {
      success: true,
      data: {
        path,
        size: stats.size,
        language: this.detectLanguage(path),
        analysis
      },
      tool: this.name,
      action: 'analyze'
    };
  }

  private async extractCode(path: string): Promise<ToolResult> {
    const content = await fs.promises.readFile(path, 'utf-8');
    const code = this.extractCodeBlocks(content);

    return {
      success: true,
      data: {
        path,
        codeBlocks: code
      },
      tool: this.name,
      action: 'extract_code'
    };
  }

  private async summarizeFile(path: string): Promise<ToolResult> {
    const content = await fs.promises.readFile(path, 'utf-8');
    const summary = await this.summarizeWithLLM(content);

    return {
      success: true,
      data: {
        path,
        summary
      },
      tool: this.name,
      action: 'summarize'
    };
  }

  private async analyzeWithLLM(content: string, path: string): Promise<FileAnalysis> {
    const systemPrompt = `
你是一个文件分析专家。请分析以下文件内容。

文件路径：${path}

内容：
${content}
`;

    const response = await this.llmProvider.chat([
      MessageManager.system(systemPrompt)
    ]);

    return this.parseFileAnalysis(response);
  }

  private async summarizeWithLLM(content: string): Promise<string> {
    const response = await this.llmProvider.chat([
      MessageManager.system('请总结以下文件内容，简洁明了'),
      MessageManager.user(content)
    ]);

    return response;
  }

  private detectLanguage(path: string): string {
    const ext = path.split('.').pop();
    const langMap: Record<string, string> = {
      'js': 'JavaScript',
      'ts': 'TypeScript',
      'py': 'Python',
      'java': 'Java',
      'go': 'Go',
      'rs': 'Rust',
      'tsx': 'TypeScript React',
      'jsx': 'JavaScript React'
    };

    return langMap[ext?.toLowerCase() || 'unknown'] || 'Unknown';
  }

  private extractCodeBlocks(content: string): CodeBlock[] {
    // 使用正则表达式提取代码块
    const codeBlockRegex = /```(\w*)\n([\s\S]*?)```/g;
    const blocks: CodeBlock[] = [];
    let match;

    while ((match = codeBlockRegex.exec(content)) !== null) {
      blocks.push({
        language: match[1] || 'unknown',
        code: match[2]
      });
    }

    return blocks;
  }

  private parseFileAnalysis(response: string): FileAnalysis {
    // 解析LLM返回的分析结果
    return {
      structure: [],
      dependencies: [],
      complexity: 0,
      recommendations: []
    };
  }
}

interface FileAnalysis {
  structure: any[];
  dependencies: string[];
  complexity: number;
  recommendations: string[];
}

interface CodeBlock {
  language: string;
  code: string;
}
```

## 3. 高级记忆管理

### 3.1 向量记忆
```typescript
class VectorMemory {
  private vectorStore: Map<string, VectorMemoryEntry> = new Map();

  async addVector(
    id: string,
    content: string,
    vector: number[]
  ): Promise<void> {
    this.vectorStore.set(id, {
      content,
      vector,
      timestamp: new Date().toISOString()
    });
  }

  async search(query: string, topK: number = 5): Promise<VectorMemoryEntry[]> {
    const queryVector = await this.embedQuery(query);

    let results: VectorMemoryEntry[] = [];

    for (const [id, entry] of this.vectorStore) {
      const similarity = this.cosineSimilarity(queryVector, entry.vector);
      results.push({ ...entry, similarity });
    }

    // 按相似度排序
    results.sort((a, b) => b.similarity - a.similarity);

    return results.slice(0, topK);
  }

  private cosineSimilarity(a: number[], b: number[]): number {
    let dotProduct = 0;
    let normA = 0;
    let normB = 0;

    for (let i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    return dotProduct / (Math.sqrt(normA) * Math.sqrt(normB));
  }

  private async embedQuery(query: string): Promise<number[]> {
    // 使用LLM生成向量表示
    const systemPrompt = `
你是一个文本向量生成器。请将以下文本转换为向量表示。
向量维度：768

文本：${query}
`;

    const response = await llmProvider.chat([
      MessageManager.system(systemPrompt)
    ]);

    return this.parseVector(response);
  }
}

interface VectorMemoryEntry {
  content: string;
  vector: number[];
  timestamp: string;
  similarity: number;
}
```

### 3.2 记忆压缩
```typescript
class MemoryCompressor {
  async compressMemory(memory: Memory[]): Promise<CompressedMemory[]> {
    const compressed: CompressedMemory[] = [];

    for (const memory of memory) {
      compressed.push({
        id: memory.id,
        summary: await this.summarizeMemory(memory),
        keyPoints: await this.extractKeyPoints(memory),
        embedding: await this.generateEmbedding(memory)
      });
    }

    return compressed;
  }

  private async summarizeMemory(memory: Memory): Promise<string> {
    const systemPrompt = `
请总结以下记忆内容，保持关键信息，去除冗余。

内容：${JSON.stringify(memory)}
`;

    return await llmProvider.chat([
      MessageManager.system(systemPrompt)
    ]);
  }

  private async extractKeyPoints(memory: Memory): Promise<string[]> {
    const systemPrompt = `
从以下记忆中提取关键点，每点一句话。

内容：${JSON.stringify(memory)}
`;

    const response = await llmProvider.chat([
      MessageManager.system(systemPrompt)
    ]);

    return this.parseKeyPoints(response);
  }

  private async generateEmbedding(memory: Memory): Promise<number[]> {
    // 生成记忆的向量表示
    const content = JSON.stringify(memory);
    const systemPrompt = `
生成以下文本的向量表示。维度：384

文本：${content}
`;

    const response = await llmProvider.chat([
      MessageManager.system(systemPrompt)
    ]);

    return this.parseVector(response);
  }
}

interface CompressedMemory {
  id: string;
  summary: string;
  keyPoints: string[];
  embedding: number[];
}
```

## 4. 性能优化

### 4.1 缓存优化
```typescript
class LLMAggregatedCache {
  private cache: Map<string, CacheEntry> = new Map();
  private defaultTTL: number = 3600000; // 1小时

  async get(key: string): Promise<any | null> {
    const entry = this.cache.get(key);

    if (!entry) {
      return null;
    }

    // 检查是否过期
    if (Date.now() - entry.timestamp > this.defaultTTL) {
      this.cache.delete(key);
      return null;
    }

    // 更新访问时间
    entry.lastAccess = Date.now();
    return entry.value;
  }

  async set(key: string, value: any): Promise<void> {
    this.cache.set(key, {
      value,
      timestamp: Date.now(),
      lastAccess: Date.now()
    });
  }

  async bulkGet(keys: string[]): Promise<Record<string, any>> {
    const results: Record<string, any> = {};

    for (const key of keys) {
      results[key] = await this.get(key);
    }

    return results;
  }

  async bulkSet(entries: Array<{ key: string; value: any }>): Promise<void> {
    for (const entry of entries) {
      await this.set(entry.key, entry.value);
    }
  }

  clear(): void {
    this.cache.clear();
  }
}
```

### 4.2 并行执行优化
```typescript
async function parallelChainExecution(
  chains: Chain[],
  input: any,
  maxConcurrency: number = 3
): Promise<ParallelResult> {
  const results: ChainResult[] = [];
  const queue = [...chains];
  const active: Promise<void>[] = [];

  while (queue.length > 0 || active.length > 0) {
    // 填充队列
    while (active.length < maxConcurrency && queue.length > 0) {
      const chain = queue.shift()!;
      const promise = executeChain(chain, input).then(result => {
        results.push(result);
      });
      active.push(promise);
    }

    // 等待一个完成
    if (active.length > 0) {
      await Promise.race(active);
      active.splice(
        active.findIndex(p => p === active[0]),
        1
      );
    }
  }

  return {
    results,
    summary: {
      total: chains.length,
      success: results.filter(r => r.success).length,
      failed: results.filter(r => !r.success).length
    }
  };
}
```

## 5. 监控和日志

### 5.1 Chain监控
```typescript
class ChainMonitor {
  private executions: ExecutionLog[] = [];

  async monitor(chain: Chain, input: any): Promise<ChainResult> {
    const start = Date.now();
    const memoryBefore = process.memoryUsage();

    try {
      const result = await chain.execute(input);
      const duration = Date.now() - start;
      const memoryAfter = process.memoryUsage();

      const log: ExecutionLog = {
        chainName: chain.name,
        input,
        result,
        duration,
        memoryUsed: memoryAfter.heapUsed - memoryBefore.heapUsed,
        success: result.success,
        timestamp: new Date().toISOString()
      };

      this.executions.push(log);
      this.analyzeLog(log);

      return result;
    } catch (error) {
      const duration = Date.now() - start;
      const memoryAfter = process.memoryUsage();

      throw error;
    }
  }

  private analyzeLog(log: ExecutionLog): void {
    if (log.success) {
      console.log(`✅ ${log.chainName} 成功 (${log.duration}ms)`);
    } else {
      console.log(`❌ ${log.chainName} 失败 (${log.duration}ms)`);
    }

    if (log.memoryUsed > 10 * 1024 * 1024) {
      console.warn(`⚠️ ${log.chainName} 内存使用过高 (${log.memoryUsed} bytes)`);
    }
  }

  getStats(): ExecutionStats {
    const successful = this.executions.filter(e => e.success);
    const failed = this.executions.filter(e => !e.success);

    return {
      total: this.executions.length,
      successRate: successful.length / this.executions.length,
      avgDuration: this.executions.reduce((sum, e) => sum + e.duration, 0) / this.executions.length,
      avgMemory: this.executions.reduce((sum, e) => sum + e.memoryUsed, 0) / this.executions.length,
      failed: failed.length,
      failures: failed
    };
  }
}
```

## 使用示例

### 自我改进Chain
```typescript
const selfImprovingChain = new SelfImprovingChain(
  'Smart Writer',
  'sequential',
  llmProvider,
  new MemoryManager()
);

const result = await selfImprovingChain.execute({
  topic: '写一篇关于人工智能的文章'
});
```

### 记忆增强Chain
```typescript
const memoryChain = new MemoryAugmentedChain(
  'Context-Aware Assistant',
  'sequential',
  llmProvider,
  new MemoryManager()
);

const result = await memoryChain.execute({
  task: '分析这段代码'
});
```

### 多Agent Chain
```typescript
const multiAgentChain = new MultiAgentChain(
  'Collaborative Solver',
  'parallel',
  llmProvider,
  new MemoryManager()
);

multiAgentChain.addAgent(new PlanningAgent(...));
multiAgentChain.addAgent(new ExecutorAgent(...));
multiAgentChain.addAgent(new ReviewerAgent(...));

const result = await multiAgentChain.execute({
  problem: '解决一个复杂问题'
});
```

### 迭代精炼Chain
```typescript
const refinementChain = new IterativeRefinementChain(
  'Quality Optimizer',
  'sequential',
  llmProvider,
  new MemoryManager()
);

const result = await refinementChain.execute({
  content: '初始草稿'
});
```

### RAG工具
```typescript
const ragTool = new RAGTool(rag);

const result = await ragTool.execute({
  action: 'search',
  query: '如何优化代码性能'
});
```

### 文件分析工具
```typescript
const fileTool = new FileAnalysisTool(llmProvider);

const result = await fileTool.execute({
  action: 'analyze',
  path: './src/index.ts'
});
```

## 最佳实践

1. **选择合适的Chain类型**:
   - Self-Improving Chain: 需要高质量输出的任务
   - Memory-Augmented Chain: 需要上下文信息的任务
   - Multi-Agent Chain: 复杂多步骤任务
   - Iterative Refinement Chain: 需要多次优化的任务

2. **合理使用工具**:
   - RAG工具: 需要知识检索的任务
   - 计算工具: 需要计算的任务
   - 文件分析工具: 需要分析文件的任务

3. **优化性能**:
   - 使用缓存减少重复计算
   - 控制并发数避免资源耗尽
   - 监控执行状态及时发现问题

4. **质量保证**:
   - 定期检查执行结果
   - 记录和分析执行日志
   - 持续优化Chain配置
