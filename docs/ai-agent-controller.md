# AI Agent控制器

## 概述
AI Agent控制器是统一管理所有Agent（Copilot、Auto-GPT、LangChain Agent等）的中央控制器。

## 核心功能

### 1. Agent注册和发现

#### 1.1 Agent注册中心
```typescript
class AgentRegistry {
  private agents: Map<string, AgentController> = new Map();

  registerAgent(agent: AgentController): void {
    this.agents.set(agent.id, agent);
    console.log(`✅ Agent已注册: ${agent.name}`);
  }

  unregisterAgent(agentId: string): void {
    const agent = this.agents.get(agentId);
    if (agent) {
      agent.shutdown();
      this.agents.delete(agentId);
      console.log(`🗑️ Agent已卸载: ${agent.name}`);
    }
  }

  getAgent(agentId: string): AgentController | undefined {
    return this.agents.get(agentId);
  }

  getAllAgents(): AgentController[] {
    return Array.from(this.agents.values());
  }

  getAgentsByCapability(capability: string): AgentController[] {
    return Array.from(this.agents.values()).filter(
      agent => agent.capabilities.includes(capability)
    );
  }

  getAvailableCapabilities(): string[] {
    const capabilities = new Set<string>();
    for (const agent of this.agents.values()) {
      for (const capability of agent.capabilities) {
        capabilities.add(capability);
      }
    }
    return Array.from(capabilities);
  }
}
```

#### 1.2 Agent控制器
```typescript
class AgentController {
  readonly id: string;
  readonly name: string;
  readonly type: AgentType;
  readonly capabilities: string[];
  private llmProvider: LLMProviderManager;
  private memory: MemoryManager;
  private tools: Tool[] = [];
  private status: AgentStatus = 'idle';
  private lastUsed: Date = new Date();

  constructor(
    id: string,
    name: string,
    type: AgentType,
    llmProvider: LWTLMProviderManager,
    memory: MemoryManager
  ) {
    this.id = id;
    this.name = name;
    this.type = type;
    this.llmProvider = llmProvider;
    this.memory = memory;
  }

  async initialize(): Promise<void> {
    this.status = 'idle';
    console.log(`🤖 ${this.name} 已初始化`);
  }

  async shutdown(): Promise<void> {
    this.status = 'shutting_down';
    await this.cleanup();
    this.status = 'offline';
    console.log(`🔌 ${this.name} 已关闭`);
  }

  private async cleanup(): Promise<void> {
    // 清理资源
  }

  async addTool(tool: Tool): void {
    this.tools.push(tool);
    console.log(`🔧 为${this.name}添加工具: ${tool.name}`);
  }

  async execute(input: AgentInput): Promise<AgentOutput> {
    this.status = 'busy';
    this.lastUsed = new Date();

    const startTime = Date.now();

    try {
      // 1. 工具准备
      await this.prepareTools(input);

      // 2. 执行任务
      const result = await this.executeTask(input);

      // 3. 记录执行
      await this.recordExecution(input, result);

      const duration = Date.now() - startTime;

      return {
        success: true,
        data: result,
        metadata: {
          agentId: this.id,
          agentName: this.name,
          duration,
          timestamp: new Date().toISOString()
        }
      };
    } catch (error) {
      const duration = Date.now() - startTime;

      return {
        success: false,
        error: error.message,
        metadata: {
          agentId: this.id,
          agentName: this.name,
          duration,
          timestamp: new Date().toISOString()
        }
      };
    } finally {
      this.status = 'idle';
    }
  }

  private async prepareTools(input: AgentInput): Promise<void> {
    // 准备工具执行环境
  }

  private async executeTask(input: AgentInput): Promise<any> {
    throw new Error('executeTask方法必须实现');
  }

  private async recordExecution(input: AgentInput, result: any): Promise<void> {
    await this.memory.addMemory({
      type: 'agent_execution',
      content: {
        agent: this.id,
        input,
        result,
        timestamp: new Date().toISOString()
      },
      metadata: {
        agentName: this.name,
        duration: 0, // 会在recordExecution中设置
        success: result.success || false
      }
    });
  }

  getStatus(): AgentStatus {
    return this.status;
  }

  getLastUsed(): Date {
    return this.lastUsed;
  }

  getCapabilities(): string[] {
    return [...this.capabilities];
  }
}

enum AgentType {
  AUTONOMOUS = 'autonomous',
  ASSISTANT = 'assistant',
  SPECIALIZED = 'specialized',
  COLLABORATIVE = 'collaborative'
}

enum AgentStatus {
  idle = 'idle',
  busy = 'busy',
  error = 'error',
  shutting_down = 'shutting_down',
  offline = 'offline'
}
```

### 2. 任务分发系统

#### 2.1 任务队列
```typescript
class TaskQueue {
  private queue: Task[] = [];
  private priority: Map<string, number> = new Map();
  private running: Set<string> = new Set();
  private completed: Set<string> = new Set();

  add(task: Task, priority: number = 5): void {
    this.queue.push({ ...task, priority });
    // 按优先级排序
    this.queue.sort((a, b) => b.priority - a.priority);
  }

  async executeNext(registry: AgentRegistry): Promise<AgentExecutionResult | null> {
    // 找到下一个任务
    const task = this.queue.shift();
    if (!task) {
      return null;
    }

    try {
      // 分发给合适的Agent
      const result = await this.executeTask(task, registry);
      this.running.delete(task.id);
      this.completed.add(task.id);

      return result;
    } catch (error) {
      this.running.delete(task.id);
      throw error;
    }
  }

  async executeTask(
    task: Task,
    registry: AgentRegistry
  ): Promise<AgentExecutionResult> {
    // 1. 识别合适的Agent
    const agent = await this.findSuitableAgent(task, registry);

    if (!agent) {
      throw new Error(`找不到合适的Agent执行任务: ${task.id}`);
    }

    // 2. 标记为运行中
    this.running.add(task.id);

    // 3. 执行任务
    const input: AgentInput = {
      taskId: task.id,
      type: task.type,
      description: task.description,
      parameters: task.parameters,
      priority: task.priority
    };

    const result = await agent.execute(input);

    return {
      task: task.id,
      agent: agent.name,
      success: result.success,
      data: result.data,
      error: result.error,
      metadata: result.metadata
    };
  }

  private async findSuitableAgent(
    task: Task,
    registry: AgentRegistry
  ): Promise<AgentController | null> {
    // 根据任务类型和能力选择Agent
    const availableAgents = registry.getAgentsByCapability(task.type);

    // 优先选择最近使用的Agent
    availableAgents.sort((a, b) => {
      const aAge = Date.now() - a.getLastUsed().getTime();
      const bAge = Date.now() - b.getLastUsed().getTime();
      return aAge - bAge;
    });

    return availableAgents[0] || null;
  }

  getQueueSize(): number {
    return this.queue.length;
  }

  getRunningCount(): number {
    return this.running.size;
  }

  getCompletedCount(): number {
    return this.completed.size;
  }

  async cancel(taskId: string): Promise<boolean> {
    const taskIndex = this.queue.findIndex(t => t.id === taskId);
    if (taskIndex > -1) {
      this.queue.splice(taskIndex, 1);
      return true;
    }

    return false;
  }
}

interface Task {
  id: string;
  type: string;
  description: string;
  parameters: any;
  priority: number;
  createdAt: Date;
}

interface AgentInput {
  taskId: string;
  type: string;
  description: string;
  parameters: any;
  priority: number;
}

interface AgentOutput {
  success: boolean;
  data?: any;
  error?: string;
  metadata?: {
    agentId: string;
    agentName: string;
    duration: number;
    timestamp: string;
  };
}

interface AgentExecutionResult {
  task: string;
  agent: string;
  success: boolean;
  data?: any;
  error?: string;
  metadata?: any;
}
```

#### 2.2 任务调度器
```typescript
class TaskScheduler {
  private queue: TaskQueue = new TaskQueue();
  private registry: AgentRegistry;
  private running: boolean = false;
  private scheduleInterval: NodeJS.Timeout;

  constructor(registry: AgentRegistry) {
    this.registry = registry;
  }

  async start(): Promise<void> {
    if (this.running) {
      return;
    }

    this.running = true;
    console.log('🚀 任务调度器已启动');

    // 定期执行队列
    this.scheduleInterval = setInterval(async () => {
      await this.executeQueue();
    }, 5000); // 每5秒执行一次

    // 启动队列监控
    await this.startQueueMonitoring();
  }

  async stop(): Promise<void> {
    this.running = false;

    if (this.scheduleInterval) {
      clearInterval(this.scheduleInterval);
    }

    console.log('🛑 任务调度器已停止');
  }

  async addTask(task: Task, priority: number = 5): Promise<void> {
    this.queue.add(task, priority);
    console.log(`📋 任务已添加: ${task.id} (优先级: ${priority})`);
  }

  async executeQueue(): Promise<void> {
    if (this.queue.getRunningCount() >= 5) {
      return; // 限制并发执行数
    }

    const result = await this.queue.executeNext(this.registry);
    if (result) {
      console.log(`✅ 任务执行成功: ${result.task}`);
    }
  }

  async startQueueMonitoring(): Promise<void> {
    // 定期监控队列状态
    setInterval(async () => {
      await this.reportQueueStatus();
    }, 10000); // 每10秒报告一次
  }

  private async reportQueueStatus(): Promise<void> {
    console.log(`
📊 任务队列状态:
- 队列大小: ${this.queue.getQueueSize()}
- 执行中: ${this.queue.getRunningCount()}
- 已完成: ${this.queue.getCompletedCount()}
- 可用Agent: ${this.registry.getAllAgents().length}
    `);
  }

  getQueueStatus(): QueueStatus {
    return {
      total: this.queue.getQueueSize(),
      running: this.queue.getRunningCount(),
      completed: this.queue.getCompletedCount(),
      availableAgents: this.registry.getAllAgents().length
    };
  }
}

interface QueueStatus {
  total: number;
  running: number;
  completed: number;
  availableAgents: number;
}
```

### 3. 协作系统

#### 3.1 协作协调器
```typescript
class CollaborationCoordinator {
  private agents: AgentController[] = [];
  private collaborationHistory: CollaborationHistory[] = [];

  registerAgents(agents: AgentController[]): void {
    this.agents = agents;
    console.log(`🔗 已注册${agents.length}个Agent到协作系统`);
  }

  async executeCollaborativeTask(
    task: CollaborativeTask
  ): Promise<CollaborativeResult> {
    const startTime = Date.now();

    // 1. 任务分析
    const analysis = await this.analyzeTask(task);

    // 2. 分配角色
    const roles = await this.assignRoles(analysis);

    // 3. 执行协作任务
    const results = await this.executeCollaboration(roles, task);

    // 4. 结果聚合
    const aggregated = this.aggregateResults(results);

    const duration = Date.now() - startTime;

    return {
      success: aggregated.success,
      data: aggregated.data,
      results,
      roles,
      duration,
      metadata: {
        totalAgents: roles.length,
        successCount: results.filter(r => r.success).length
      }
    };
  }

  private async analyzeTask(task: CollaborativeTask): Promise<TaskAnalysis> {
    const systemPrompt = `
分析以下协作任务，识别需要的Agent角色和职责。

任务：${task.description}

请返回：
1. 需要的Agent类型列表
2. 每个Agent的职责
3. Agent之间的协作方式
4. 预期的输出结构
`;

    return await this.analyzeWithLLM(systemPrompt);
  }

  private async assignRoles(analysis: TaskAnalysis): Promise<AgentRole[]> {
    const roles: AgentRole[] = [];

    for (const agentType of analysis.agentTypes) {
      // 找到合适的Agent
      const agent = this.agents.find(a => a.type === agentType);

      if (agent) {
        roles.push({
          agentId: agent.id,
          agentName: agent.name,
          type: agentType,
          responsibilities: analysis.roles[agentType],
          assigned: true
        });
      }
    }

    return roles;
  }

  private async executeCollaboration(
    roles: AgentRole[],
    task: CollaborativeTask
  ): Promise<AgentResult[]> {
    const promises = roles.map(async (role) => {
      console.log(`🔄 执行角色: ${role.agentName}`);

      const input: AgentInput = {
        taskId: `${task.id}_role_${role.agentId}`,
        type: role.type,
        description: task.description,
        parameters: {
          role: role.responsibilities,
          context: task.context
        }
      };

      const agent = this.agents.find(a => a.id === role.agentId);
      if (!agent) {
        throw new Error(`Agent不存在: ${role.agentId}`);
      }

      return await agent.execute(input);
    });

    return await Promise.all(promises);
  }

  private aggregateResults(results: AgentResult[]): any {
    // 聚合所有Agent的结果
    const successful = results.filter(r => r.success);

    if (successful.length === 0) {
      return {
        success: false,
        error: '所有Agent都失败了'
      };
    }

    return {
      success: true,
      data: successful.map(r => r.data),
      summary: this.generateSummary(results),
      insights: this.generateInsights(results)
    };
  }

  private generateSummary(results: AgentResult[]): string {
    return results.map(r =>
      `Agent ${r.agent} 完成: ${r.success ? '成功' : '失败'}`
    ).join('\n');
  }

  private generateInsights(results: AgentResult[]): string[] {
    return results
      .filter(r => r.success)
      .flatMap(r => r.data?.insights || []);
  }

  async logCollaboration(
    task: CollaborativeTask,
    result: CollaborativeResult
  ): Promise<void> {
    this.collaborationHistory.push({
      taskId: task.id,
      taskDescription: task.description,
      roles: result.roles,
      results: result.results,
      success: result.success,
      duration: result.duration,
      timestamp: new Date().toISOString()
    });

    console.log(`💾 协作历史已记录: ${task.id}`);
  }
}

interface CollaborativeTask {
  id: string;
  description: string;
  context?: any;
  priority?: number;
}

interface CollaborativeResult {
  success: boolean;
  data?: any;
  results: AgentResult[];
  roles: AgentRole[];
  duration: number;
  metadata?: any;
}

interface AgentRole {
  agentId: string;
  agentName: string;
  type: AgentType;
  responsibilities: string[];
  assigned: boolean;
}

interface AgentResult {
  success: boolean;
  data?: any;
  error?: string;
  agent: string;
}

interface TaskAnalysis {
  agentTypes: string[];
  roles: Record<string, string[]>;
  collaborationPattern: string;
  outputStructure: any;
}

interface CollaborationHistory {
  taskId: string;
  taskDescription: string;
  roles: AgentRole[];
  results: AgentResult[];
  success: boolean;
  duration: number;
  timestamp: string;
}
```

### 4. 监控和告警

#### 4.1 Agent监控
```typescript
class AgentMonitor {
  private agents: AgentRegistry;
  private metrics: Map<string, AgentMetrics> = new Map();

  constructor(registry: AgentRegistry) {
    this.agents = registry;
  }

  async monitor(): Promise<void> {
    for (const agent of this.agents.getAllAgents()) {
      await this.monitorAgent(agent);
    }

    // 定期报告
    setInterval(async () => {
      await this.report();
    }, 30000); // 每30秒报告一次
  }

  private async monitorAgent(agent: AgentController): Promise<void> {
    const metrics: AgentMetrics = {
      agentId: agent.id,
      agentName: agent.name,
      status: agent.getStatus(),
      lastUsed: agent.getLastUsed(),
      capabilityCount: agent.getCapabilities().length,
      uptime: Date.now() - agent.getStartTime().getTime()
    };

    this.metrics.set(agent.id, metrics);
  }

  private async report(): Promise<void> {
    const report = {
      timestamp: new Date().toISOString(),
      agents: Array.from(this.metrics.values()),
      overallStatus: this.getOverallStatus(),
      alerts: this.getAlerts()
    };

    console.log('📊 Agent监控报告:', report);
  }

  private getOverallStatus(): 'healthy' | 'warning' | 'critical' {
    const statuses = Array.from(this.metrics.values()).map(m => m.status);

    const critical = statuses.filter(s => s === 'critical').length;
    const warning = statuses.filter(s => s === 'error').length;
    const healthy = statuses.filter(s => s === 'idle').length;

    if (critical > 0) return 'critical';
    if (warning > 0) return 'warning';
    return 'healthy';
  }

  private getAlerts(): string[] {
    const alerts: string[] = [];

    for (const [id, metrics] of this.metrics) {
      if (metrics.status === 'error') {
        alerts.push(`🚨 Agent ${metrics.agentName} 出错`);
      }

      if (Date.now() - metrics.lastUsed.getTime() > 3600000) {
        // 1小时未使用
        alerts.push(`⚠️ Agent ${metrics.agentName} 1小时未使用`);
      }
    }

    return alerts;
  }

  getAgentMetrics(agentId: string): AgentMetrics | undefined {
    return this.metrics.get(agentId);
  }

  getAllMetrics(): Map<string, AgentMetrics> {
    return new Map(this.metrics);
  }
}

interface AgentMetrics {
  agentId: string;
  agentName: string;
  status: AgentStatus;
  lastUsed: Date;
  capabilityCount: number;
  uptime: number;
}
```

## 使用示例

### 基础使用
```typescript
// 初始化LLM提供商
const llmProvider = new LLMProviderManager();
await llmProvider.initialize('openai', {
  apiKey: process.env.OPENAI_API_KEY!,
  model: 'gpt-4',
  temperature: 0.7
});

// 创建记忆管理器
const memory = new MemoryManager();

// 创建Agent注册中心
const registry = new AgentRegistry();

// 注册Agent
const copilotAgent = new CopilotAgent('copilot', llmProvider, memory);
const autoGPTAgent = new AutoGPTAgent('auto-gpt', llmProvider, memory);

registry.registerAgent(copilotAgent);
registry.registerAgent(autoGPTAgent);

// 创建任务调度器
const scheduler = new TaskScheduler(registry);
await scheduler.start();

// 添加任务
await scheduler.addTask({
  id: 'task_1',
  type: 'code-review',
  description: '审查这段React组件代码',
  parameters: {
    code: `// 代码内容`
  }
}, 8);
```

### 协作执行
```typescript
const coordinator = new CollaborationCoordinator();

coordinator.registerAgents([
  copilotAgent,
  autoGPTAgent,
  ragAgent
]);

const result = await coordinator.executeCollaborativeTask({
  id: 'collab_task_1',
  description: '生成一个Python爬虫并测试',
  context: {
    target: 'example.com',
    data: '爬取的数据'
  }
});

console.log('协作结果:', result);
```

### 监控
```typescript
const monitor = new AgentMonitor(registry);
await monitor.monitor();

// 获取Agent状态
const metrics = monitor.getAgentMetrics('copilot');
console.log('Copilot状态:', metrics);
```

## 最佳实践

1. **合理注册Agent**:
   - 只注册必要的Agent
   - 定期检查Agent状态
   - 及时清理不活跃的Agent

2. **任务优先级**:
   - 根据任务重要性设置优先级
   - 监控队列状态
   - 及时处理高优先级任务

3. **协作优化**:
   - 选择合适的Agent协作
   - 明确定义Agent职责
   - 优化结果聚合

4. **性能监控**:
   - 定期监控Agent状态
   - 及时发现和解决问题
   - 优化Agent配置

5. **资源管理**:
   - 限制并发Agent数量
   - 及时释放资源
   - 避免资源泄漏
