/**
 * 智能任务调度器 - 增强
 * 多技能调度协调、智能资源分配
 */

import { Task, Skill, Dependency, Resource } from './types';

/**
 * 任务调度器配置
 */
export interface SchedulerConfig {
  maxParallelTasks: number;
  resourceCapacity: number;
  priorityStrategy: 'static' | 'dynamic';
  loadBalancing: 'round-robin' | 'least-loaded' | 'adaptive';
  timeout: number;
  retryAttempts: number;
  queueSize: number;
}

/**
 * 默认配置
 */
const DEFAULT_CONFIG: SchedulerConfig = {
  maxParallelTasks: 5,
  resourceCapacity: 100,
  priorityStrategy: 'dynamic',
  loadBalancing: 'adaptive',
  timeout: 300000, // 5分钟
  retryAttempts: 3,
  queueSize: 100
};

/**
 * 任务优先级
 */
export enum TaskPriority {
  CRITICAL = 0,
  HIGH = 1,
  MEDIUM = 2,
  LOW = 3
}

/**
 * 任务状态
 */
export enum TaskStatus {
  PENDING = 'pending',
  RUNNING = 'running',
  PAUSED = 'paused',
  COMPLETED = 'completed',
  FAILED = 'failed',
  CANCELLED = 'cancelled'
}

/**
 * 任务详情
 */
export interface TaskDetail extends Task {
  status: TaskStatus;
  priority: TaskPriority;
  startTime?: Date;
  endTime?: Date;
  duration?: number;
  retryCount: number;
  result?: any;
  error?: Error;
  dependencies: string[];
  estimatedDuration: number;
  actualDuration?: number;
}

/**
 * 调度决策
 */
export interface SchedulingDecision {
  action: 'schedule' | 'queue' | 'skip' | 'wait';
  task: Task;
  reason: string;
  estimatedStartTime: Date;
}

/**
 * 智能任务调度器
 */
export class IntelligentTaskScheduler {
  private tasks: Map<string, TaskDetail> = new Map();
  private skillQueue: Map<string, Skill> = new Map();
  private resourcePool: ResourcePool;
  private dependencyGraph: DependencyGraph;
  private config: SchedulerConfig;

  constructor(config?: Partial<SchedulerConfig>) {
    this.config = { ...DEFAULT_CONFIG, ...config };
    this.resourcePool = new ResourcePool(this.config.resourceCapacity);
    this.dependencyGraph = new DependencyGraph();
  }

  /**
   * 注册技能
   */
  registerSkill(skill: Skill): void {
    this.skillQueue.set(skill.name, skill);
  }

  /**
   * 注册任务
   */
  registerTask(task: Task): void {
    const detail: TaskDetail = {
      ...task,
      status: TaskStatus.PENDING,
      priority: task.priority || TaskPriority.MEDIUM,
      retryCount: 0,
      dependencies: task.dependencies || [],
      estimatedDuration: task.estimatedDuration || this.estimateDuration(task)
    };

    this.tasks.set(task.id, detail);
    this.dependencyGraph.addTask(task.id, task.dependencies || []);
  }

  /**
   * 调度任务
   */
  async scheduleTask(taskId: string): Promise<SchedulingDecision | null> {
    const task = this.tasks.get(taskId);
    if (!task) {
      return null;
    }

    // 检查依赖是否完成
    if (!this.checkDependencies(taskId)) {
      return {
        action: 'wait',
        task,
        reason: 'Dependencies not completed',
        estimatedStartTime: this.calculateNextScheduleTime(taskId)
      };
    }

    // 检查资源是否可用
    if (!this.resourcePool.hasResources(task.estimatedDuration)) {
      return {
        action: 'queue',
        task,
        reason: 'Resources not available',
        estimatedStartTime: this.calculateNextScheduleTime(taskId)
      };
    }

    // 检查并行任务限制
    if (this.getRunningTaskCount() >= this.config.maxParallelTasks) {
      return {
        action: 'queue',
        task,
        reason: 'Max parallel tasks reached',
        estimatedStartTime: this.calculateNextScheduleTime(taskId)
      };
    }

    // 调度任务
    return {
      action: 'schedule',
      task,
      reason: 'Task ready to run',
      estimatedStartTime: new Date()
    };
  }

  /**
   * 执行任务
   */
  async executeTask(taskId: string): Promise<any> {
    const task = this.tasks.get(taskId);
    if (!task || task.status !== TaskStatus.PENDING) {
      throw new Error(`Task ${taskId} not ready for execution`);
    }

    // 标记为运行中
    task.status = TaskStatus.RUNNING;
    task.startTime = new Date();

    try {
      // 分配资源
      this.resourcePool.allocate(task.estimatedDuration);

      // 执行任务
      const skill = this.skillQueue.get(task.skillName);
      if (!skill) {
        throw new Error(`Skill ${task.skillName} not registered`);
      }

      const result = await skill.execute(task.params);

      // 任务完成
      task.status = TaskStatus.COMPLETED;
      task.endTime = new Date();
      task.actualDuration = task.endTime.getTime() - task.startTime.getTime();
      task.result = result;

      // 释放资源
      this.resourcePool.release(task.estimatedDuration);

      return result;

    } catch (error) {
      // 任务失败
      task.status = TaskStatus.FAILED;
      task.error = error as Error;
      task.retryCount++;

      // 释放资源
      this.resourcePool.release(task.estimatedDuration);

      // 重试逻辑
      if (task.retryCount < this.config.retryAttempts) {
        // 排队等待重试
        task.status = TaskStatus.PENDING;
        console.log(`Task ${taskId} will retry (${task.retryCount}/${this.config.retryAttempts})`);
      }

      throw error;
    }
  }

  /**
   * 检查依赖
   */
  private checkDependencies(taskId: string): boolean {
    const task = this.tasks.get(taskId);
    if (!task) return false;

    const dependencies = task.dependencies || [];
    for (const depId of dependencies) {
      const depTask = this.tasks.get(depId);
      if (!depTask || depTask.status !== TaskStatus.COMPLETED) {
        return false;
      }
    }

    return true;
  }

  /**
   * 计算下次调度时间
   */
  private calculateNextScheduleTime(taskId: string): Date {
    const task = this.tasks.get(taskId);
    if (!task) return new Date();

    // 基于依赖任务完成时间
    const dependencies = task.dependencies || [];
    let nextTime = new Date();

    for (const depId of dependencies) {
      const depTask = this.tasks.get(depId);
      if (depTask && depTask.endTime) {
        const depTime = new Date(depTask.endTime);
        if (depTime > nextTime) {
          nextTime = depTime;
        }
      }
    }

    // 加上延迟
    nextTime = new Date(nextTime.getTime() + 1000); // 1秒延迟

    return nextTime;
  }

  /**
   * 获取运行中的任务数量
   */
  private getRunningTaskCount(): number {
    let count = 0;
    for (const task of this.tasks.values()) {
      if (task.status === TaskStatus.RUNNING) {
        count++;
      }
    }
    return count;
  }

  /**
   * 估算任务耗时
   */
  private estimateDuration(task: Task): number {
    // 基于技能平均执行时间估算
    const skill = this.skillQueue.get(task.skillName);
    if (skill && skill.avgExecutionTime) {
      return skill.avgExecutionTime;
    }

    // 基于任务复杂度估算
    const complexity = this.estimateTaskComplexity(task);
    const baseDuration = 1000; // 1秒基础时间

    return baseDuration * complexity;
  }

  /**
   * 估算任务复杂度
   */
  private estimateTaskComplexity(task: Task): number {
    let complexity = 1;

    // 参数复杂度
    if (task.params && Object.keys(task.params).length > 10) {
      complexity += 1;
    }

    // 依赖数量
    if (task.dependencies && task.dependencies.length > 3) {
      complexity += task.dependencies.length * 0.5;
    }

    // 预期耗时
    if (task.estimatedDuration) {
      complexity = task.estimatedDuration / 1000;
    }

    return Math.min(complexity, 10); // 最大10倍复杂度
  }

  /**
   * 调度所有任务
   */
  async scheduleAllTasks(): Promise<void> {
    // 获取所有待处理任务
    const pendingTasks = Array.from(this.tasks.values())
      .filter(t => t.status === TaskStatus.PENDING)
      .sort((a, b) => this.comparePriority(a, b));

    // 按优先级调度
    for (const task of pendingTasks) {
      const decision = await this.scheduleTask(task.id);
      if (decision && decision.action === 'schedule') {
        await this.executeTask(task.id);
      }
    }
  }

  /**
   * 比较任务优先级
   */
  private comparePriority(a: TaskDetail, b: TaskDetail): number {
    // 首先比较优先级
    if (a.priority !== b.priority) {
      return a.priority - b.priority;
    }

    // 优先级相同，比较依赖数量
    if (a.dependencies.length !== b.dependencies.length) {
      return a.dependencies.length - b.dependencies.length;
    }

    // 优先级相同，比较耗时
    return a.estimatedDuration - b.estimatedDuration;
  }

  /**
   * 获取调度报告
   */
  getSchedulingReport(): any {
    return {
      totalTasks: this.tasks.size,
      pendingTasks: this.tasks.filter(t => t.status === TaskStatus.PENDING).length,
      runningTasks: this.tasks.filter(t => t.status === TaskStatus.RUNNING).length,
      completedTasks: this.tasks.filter(t => t.status === TaskStatus.COMPLETED).length,
      failedTasks: this.tasks.filter(t => t.status === TaskStatus.FAILED).length,
      queueSize: this.tasks.filter(t => t.status === TaskStatus.PENDING && this.checkDependencies(t.id)).length,
      resourcesAvailable: this.resourcePool.getAvailableCapacity(),
      totalResourceUsed: this.resourcePool.getTotalUsed(),
      avgExecutionTime: this.calculateAvgExecutionTime(),
      throughput: this.calculateThroughput()
    };
  }

  /**
   * 计算平均执行时间
   */
  private calculateAvgExecutionTime(): number {
    const completedTasks = Array.from(this.tasks.values())
      .filter(t => t.status === TaskStatus.COMPLETED && t.actualDuration);

    if (completedTasks.length === 0) return 0;

    const totalDuration = completedTasks.reduce((sum, t) => sum + t.actualDuration!, 0);
    return totalDuration / completedTasks.length;
  }

  /**
   * 计算吞吐量
   */
  private calculateThroughput(): number {
    const completedTasks = this.tasks.filter(t => t.status === TaskStatus.COMPLETED);
    if (completedTasks.length === 0) return 0;

    const totalDuration = completedTasks.reduce((sum, t) =>
      sum + (t.actualDuration || t.estimatedDuration), 0
    );

    return completedTasks.length / (totalDuration / 1000); // 任务数/秒
  }
}

/**
 * 资源池
 */
class ResourcePool {
  private available: number;
  private used: number;
  private max: number;

  constructor(maxCapacity: number) {
    this.max = maxCapacity;
    this.available = maxCapacity;
    this.used = 0;
  }

  /**
   * 分配资源
   */
  allocate(duration: number): boolean {
    if (this.available >= duration) {
      this.available -= duration;
      this.used += duration;
      return true;
    }
    return false;
  }

  /**
   * 释放资源
   */
  release(duration: number): void {
    this.available += duration;
    this.used -= duration;
    this.available = Math.max(0, this.available);
    this.used = Math.max(0, this.used);
  }

  /**
   * 检查资源是否足够
   */
  hasResources(duration: number): boolean {
    return this.available >= duration;
  }

  /**
   * 获取可用容量
   */
  getAvailableCapacity(): number {
    return this.available;
  }

  /**
   * 获取已用容量
   */
  getTotalUsed(): number {
    return this.used;
  }

  /**
   * 获取使用率
   */
  getUsageRate(): number {
    return this.used / this.max;
  }
}

/**
 * 依赖图
 */
class DependencyGraph {
  private dependencies: Map<string, string[]> = new Map();

  /**
   * 添加任务及其依赖
   */
  addTask(taskId: string, dependencies: string[]): void {
    this.dependencies.set(taskId, dependencies);
  }

  /**
   * 检查是否有循环依赖
   */
  hasCycle(taskId: string, visited: Set<string> = new Set(), recursionStack: Set<string> = new Set()): boolean {
    if (recursionStack.has(taskId)) {
      return true;
    }

    if (visited.has(taskId)) {
      return false;
    }

    visited.add(taskId);
    recursionStack.add(taskId);

    const deps = this.dependencies.get(taskId) || [];
    for (const dep of deps) {
      if (this.hasCycle(dep, visited, recursionStack)) {
        return true;
      }
    }

    recursionStack.delete(taskId);
    return false;
  }

  /**
   * 获取所有依赖项
   */
  getDependencies(taskId: string): string[] {
    return this.dependencies.get(taskId) || [];
  }

  /**
   * 获取所有任务ID
   */
  getAllTaskIds(): string[] {
    return Array.from(this.dependencies.keys());
  }
}
