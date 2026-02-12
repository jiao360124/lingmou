# Auto-GPT - 错误恢复机制增强

## 概述
增强的错误恢复机制提供更完善的错误分类、自动重试、备用方案和修复验证功能。

## 错误分类体系

### 1. 网络错误（NetworkError）

#### 类型
- `ConnectionFailed` - 连接失败
- `TimeoutError` - 超时
- `DNSResolutionError` - DNS解析失败
- `CertificateError` - SSL证书错误

#### 处理策略
```typescript
class NetworkErrorHandler {
  private static MAX_RETRIES = 3;
  private static RETRY_DELAY = 1000; // 1秒

  static async handleNetworkError(error: NetworkError, context: any): Promise<any> {
    // 指数退避重试
    for (let attempt = 0; attempt < this.MAX_RETRIES; attempt++) {
      try {
        await this.sleep(this.RETRY_DELAY * Math.pow(2, attempt));

        // 尝试重新连接
        return await this.retryWithExponentialBackoff(context);

      } catch (retryError) {
        // 最后一次尝试失败
        if (attempt === this.MAX_RETRIES - 1) {
          return this.handleFinalFailure(error, retryError, context);
        }

        // 记录重试日志
        log.warn(`Network error retry ${attempt + 1}/${this.MAX_RETRIES}`, {
          error: error.message,
          retryError: retryError.message,
          delay: this.RETRY_DELAY * Math.pow(2, attempt)
        });
      }
    }
  }

  private async retryWithExponentialBackoff(context: any): Promise<any> {
    // 实现重连逻辑
    return await context.execute();
  }

  private handleFinalFailure(
    originalError: NetworkError,
    retryError: any,
    context: any
  ): FailureResult {
    // 尝试备用方案
    if (context.hasOfflineMode) {
      return await this.useOfflineMode(context);
    }

    // 尝试切换网络
    if (context.canSwitchNetwork) {
      return await this.switchNetwork(context);
    }

    // 标记为失败
    return {
      success: false,
      error: new NetworkFailureError({
        message: 'All retry attempts failed',
        originalError,
        retryError
      }),
      context
    };
  }
}
```

#### 备用方案
1. **离线模式**：使用缓存的缓存数据
2. **切换网络**：尝试使用备用网络
3. **延迟重试**：等待一段时间后重试

### 2. 工具调用错误（ToolCallError）

#### 类型
- `ToolNotFoundError` - 工具不存在
- `ToolExecutionError` - 工具执行失败
- `ToolTimeoutError` - 工具执行超时
- `ToolPermissionError` - 权限不足

#### 处理策略
```typescript
class ToolErrorHandler {
  private static FALLBACK_HANDLERS = new Map<string, ToolFallbackHandler>();

  // 注册备用处理程序
  static registerFallbackHandler(
    toolName: string,
    handler: ToolFallbackHandler
  ) {
    this.FALLBACK_HANDLERS.set(toolName, handler);
  }

  static async handleToolError(
    error: ToolCallError,
    toolName: string,
    params: any
  ): Promise<FailureResult> {
    // 1. 尝试备用处理程序
    const fallbackHandler = this.FALLBACK_HANDLERS.get(toolName);
    if (fallbackHandler && fallbackHandler.canHandle(error)) {
      return await fallbackHandler.handle(error, params);
    }

    // 2. 如果没有备用程序，尝试使用替代工具
    const alternativeTools = this.findAlternativeTools(toolName, error);
    for (const altTool of alternativeTools) {
      try {
        return await this.executeAlternativeTool(altTool, params);
      } catch (altError) {
        log.warn(`Alternative tool ${altTool.name} failed`, {
          error: altError.message,
          primaryError: error.message
        });
      }
    }

    // 3. 最后尝试手动修复
    return await this.tryManualRepair(toolName, params, error);
  }

  private findAlternativeTools(
    toolName: string,
    error: ToolCallError
  ): Tool[] {
    // 查找可以替代的工具
    return [];
  }

  private async executeAlternativeTool(
    tool: Tool,
    params: any
  ): Promise<any> {
    return await tool.execute(params);
  }

  private async tryManualRepair(
    toolName: string,
    params: any,
    error: ToolCallError
  ): Promise<FailureResult> {
    // 生成手动修复建议
    const suggestion = await this.generateManualRepairSuggestion(
      toolName,
      params,
      error
    );

    return {
      success: false,
      error,
      suggestion,
      requiresManualIntervention: true
    };
  }
}

// 注册备用处理程序
ToolErrorHandler.registerFallbackHandler('file_write', {
  canHandle: (error) => error.code === 'EACCES',
  handle: async (error, params) => {
    return {
      success: false,
      error,
      suggestion: '请检查文件权限或使用不同的目录'
    };
  }
});
```

### 3. 数据验证错误（ValidationError）

#### 类型
- `InvalidFormatError` - 格式无效
- `MissingRequiredFieldError` - 缺少必填字段
- `OutOfRangeError` - 值超出范围
- `TypeMismatchError` - 类型不匹配

#### 处理策略
```typescript
class DataValidator {
  private static VALIDATION_RULES = new Map<string, ValidationRule>();

  static registerValidationRule(rule: ValidationRule) {
    this.VALIDATION_RULES.set(rule.name, rule);
  }

  static async validateData(
    data: any,
    schema: ValidationSchema
  ): Promise<ValidationResult> {
    const errors: ValidationError[] = [];

    for (const field of schema.fields) {
      const value = data[field.name];

      // 检查必填字段
      if (field.required && (value === undefined || value === null)) {
        errors.push(new MissingRequiredFieldError(field.name));
        continue;
      }

      // 跳过可选的空字段
      if (!field.required && value === undefined) {
        continue;
      }

      // 应用验证规则
      const rule = this.VALIDATION_RULES.get(field.validationRule);
      if (rule) {
        const result = await rule.validate(value, field.constraints);
        if (!result.valid) {
          errors.push(new ValidationError({
            field: field.name,
            message: result.message,
            value
          }));
        }
      }
    }

    return {
      valid: errors.length === 0,
      errors,
      data: errors.length === 0 ? data : undefined
    };
  }
}

// 注册验证规则
DataValidator.registerValidationRule({
  name: 'email',
  validate: (value, constraints) => {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(value)) {
      return { valid: false, message: 'Invalid email format' };
    }
    return { valid: true };
  }
});
```

#### 自动修复尝试
```typescript
class ValidationErrorHandler {
  private static AUTO_FIXERS = new Map<string, AutoFixer>();

  static registerAutoFixer(fixer: AutoFixer) {
    this.AUTO_FIXERS.set(fixer.fieldName, fixer);
  }

  static async handleValidationError(
    error: ValidationError,
    data: any
  ): Promise<AutoFixResult> {
    // 尝试自动修复
    const fixer = this.AUTO_FIXERS.get(error.field);
    if (fixer) {
      const fixedData = await fixer.fix(error, data);
      return {
        success: true,
        fixedData,
        method: fixer.method
      };
    }

    // 无法自动修复
    return {
      success: false,
      method: 'none',
      suggestion: this.generateRepairSuggestion(error)
    };
  }
}
```

### 4. 依赖问题错误（DependencyError）

#### 类型
- `MissingDependencyError` - 缺少依赖
- `VersionMismatchError` - 版本不匹配
- `CircularDependencyError` - 循环依赖
- `DependencyTimeoutError` - 依赖超时

#### 处理策略
```typescript
class DependencyManager {
  private static DEPENDENCY_CACHE = new Map<string, DependencyStatus>();
  private static MAX_DEPENDENCY_CHECKS = 100;

  static async checkDependencies(
    dependencies: Dependency[]
  ): Promise<DependencyCheckResult> {
    const result: DependencyCheckResult = {
      dependencies: [],
      allHealthy: true,
      issues: []
    };

    for (const dep of dependencies) {
      try {
        const status = await this.checkDependency(dep);
        result.dependencies.push(status);

        if (!status.healthy) {
          result.allHealthy = false;
          result.issues.push({
            dependency: dep.name,
            status: status.status,
            details: status.details
          });
        }

      } catch (error) {
        result.dependencies.push({
          name: dep.name,
          healthy: false,
          status: 'error',
          details: error.message
        });

        result.allHealthy = false;
        result.issues.push({
          dependency: dep.name,
          status: 'error',
          details: error.message
        });
      }
    }

    return result;
  }

  static async resolveDependencies(
    dependencies: Dependency[]
  ): Promise<DependencyResolutionResult> {
    // 检查循环依赖
    const circularDeps = this.detectCircularDependencies(dependencies);
    if (circularDeps.length > 0) {
      return {
        success: false,
        error: new CircularDependencyError(circularDeps)
      };
    }

    // 解析依赖
    const resolved = await this.resolveGraph(dependencies);

    // 检查版本兼容性
    const versionErrors = this.checkVersionCompatibility(resolved);
    if (versionErrors.length > 0) {
      return {
        success: false,
        error: new VersionMismatchError(versionErrors)
      };
    }

    return {
      success: true,
      dependencies: resolved
    };
  }

  private static detectCircularDependencies(
    dependencies: Dependency[]
  ): string[] {
    // 实现循环依赖检测
    return [];
  }

  private static async resolveGraph(
    dependencies: Dependency[]
  ): Promise<Dependency[]> {
    // 实现依赖图解析
    return [];
  }

  private static checkVersionCompatibility(
    dependencies: Dependency[]
  ): VersionError[] {
    // 实现版本兼容性检查
    return [];
  }
}
```

### 5. 约束违反错误（ConstraintViolationError）

#### 类型
- `MaxSizeViolationError` - 超过最大大小
- `MinSizeViolationError` - 小于最小大小
- `PatternViolationError` - 不符合模式
- `CustomConstraintError` - 自定义约束

#### 处理策略
```typescript
class ConstraintViolationHandler {
  private static CUSTOM_CONSTRAINTS = new Map<string, ConstraintChecker>();

  static registerConstraint(name: string, checker: ConstraintChecker) {
    this.CUSTOM_CONSTRAINTS.set(name, checker);
  }

  static async checkConstraint(
    value: any,
    constraint: Constraint
  ): Promise<ConstraintCheckResult> {
    // 检查大小约束
    if (constraint.type === 'size') {
      return this.checkSizeConstraint(value, constraint);
    }

    // 检查模式约束
    if (constraint.type === 'pattern') {
      return this.checkPatternConstraint(value, constraint);
    }

    // 检查自定义约束
    if (constraint.type === 'custom') {
      return this.checkCustomConstraint(value, constraint);
    }

    return {
      valid: true,
      message: ''
    };
  }

  private static checkSizeConstraint(
    value: any,
    constraint: Constraint
  ): ConstraintCheckResult {
    if (typeof value === 'string') {
      if (value.length > constraint.maxSize) {
        return {
          valid: false,
          message: `String exceeds maximum length of ${constraint.maxSize}`
        };
      }

      if (value.length < constraint.minSize) {
        return {
          valid: false,
          message: `String below minimum length of ${constraint.minSize}`
        };
      }
    }

    return { valid: true };
  }

  private static checkPatternConstraint(
    value: any,
    constraint: Constraint
  ): ConstraintCheckResult {
    if (value instanceof RegExp) {
      if (!value.test(value)) {
        return {
          valid: false,
          message: `Value does not match pattern: ${constraint.pattern}`
        };
      }
    }

    return { valid: true };
  }

  private static checkCustomConstraint(
    value: any,
    constraint: Constraint
  ): ConstraintCheckResult {
    const checker = this.CUSTOM_CONSTRAINTS.get(constraint.customName);
    if (!checker) {
      return { valid: true };
    }

    return checker.check(value);
  }
}
```

## 可视化进度面板

### 进度树可视化
```typescript
class ProgressVisualizer {
  private static progressBarId = 'progress-bar';

  static renderTaskTree(tasks: Task[]): string {
    const tree = this.buildTree(tasks);
    return this.visualizeTree(tree, 0);
  }

  private static buildTree(tasks: Task[], parentId: string = 'root'): TreeNode[] {
    const children = tasks.filter(t => t.parentId === parentId);
    const nodes: TreeNode[] = [];

    for (const child of children) {
      nodes.push({
        id: child.id,
        name: child.name,
        status: child.status,
        children: this.buildTree(tasks, child.id)
      });
    }

    return nodes;
  }

  static updateTaskStatus(taskId: string, status: TaskStatus): void {
    // 更新进度条UI
    const progressBar = document.getElementById(this.progressBarId);
    if (progressBar) {
      progressBar.style.width = `${status.progress}%`;
      progressBar.textContent = `进度: ${status.progress}%`;
    }
  }

  private static visualizeTree(node: TreeNode, level: number): string {
    const indent = '  '.repeat(level);
    const statusIcon = this.getStatusIcon(node.status);
    return `${indent}${statusIcon} ${node.name} ${this.getProgressPercent(node)}\n` +
           node.children.map(child => this.visualizeTree(child, level + 1)).join('');
  }
}
```

### 预计完成时间
```typescript
class ETACalculator {
  static calculateETA(tasks: Task[]): string {
    const totalTasks = tasks.length;
    const completedTasks = tasks.filter(t => t.status === 'completed').length;
    const remainingTasks = totalTasks - completedTasks;

    if (remainingTasks === 0) {
      return '任务已完成';
    }

    // 计算平均剩余时间
    const avgTimePerTask = this.calculateAverageTimePerTask(tasks);
    const estimatedRemainingTime = avgTimePerTask * remainingTasks;

    return this.formatDuration(estimatedRemainingTime);
  }

  private static calculateAverageTimePerTask(tasks: Task[]): number {
    let totalTime = 0;
    let completedTasks = 0;

    for (const task of tasks) {
      if (task.status === 'completed') {
        totalTime += task.duration;
        completedTasks++;
      }
    }

    return completedTasks > 0 ? totalTime / completedTasks : 0;
  }

  private static formatDuration(ms: number): string {
    const seconds = Math.floor(ms / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);

    if (hours > 0) {
      return `${hours}小时 ${minutes % 60}分钟`;
    } else if (minutes > 0) {
      return `${minutes}分钟 ${seconds % 60}秒`;
    } else {
      return `${seconds}秒`;
    }
  }
}
```

## 进度监控增强

### 实时进度条
```typescript
class ProgressMonitor {
  private taskId: string;
  private startTime: Date;
  private updateInterval: NodeJS.Timeout;
  private progressCallback: ProgressUpdateCallback;

  constructor(
    taskId: string,
    totalSteps: number,
    callback: ProgressUpdateCallback
  ) {
    this.taskId = taskId;
    this.startTime = new Date();
    this.updateInterval = setInterval(() => {
      this.updateProgress(callback);
    }, 1000);
  }

  private updateProgress(callback: ProgressUpdateCallback): void {
    const elapsed = Date.now() - this.startTime.getTime();
    const progress = this.calculateProgress(elapsed);

    callback({
      taskId: this.taskId,
      progress,
      elapsed,
      remainingTime: ETACalculator.calculateETA(progress.steps)
    });
  }

  private calculateProgress(elapsed: number): ProgressState {
    // 计算进度状态
    return {
      currentStep: this.getCurrentStep(),
      totalSteps: this.getTotalSteps(),
      progress: (this.getCurrentStep() / this.getTotalSteps()) * 100,
      elapsed,
      steps: this.getSteps()
    };
  }

  stop(): void {
    clearInterval(this.updateInterval);
  }
}
```

### 任务状态追踪
```typescript
interface TaskStatus {
  currentStep: number;
  totalSteps: number;
  progress: number;
  elapsed: number;
  remainingTime: string;
  steps: StepStatus[];
}

interface StepStatus {
  step: number;
  name: string;
  status: 'pending' | 'in-progress' | 'completed' | 'failed';
  startTime?: Date;
  endTime?: Date;
  duration?: number;
  error?: string;
}

class TaskTracker {
  static trackTask(
    taskId: string,
    steps: Step[]
  ): TaskStatus {
    const currentStep = this.getCurrentStep(tasks);
    const progress = (currentStep / steps.length) * 100;
    const elapsed = this.calculateElapsed(tasks);

    return {
      currentStep,
      totalSteps: steps.length,
      progress,
      elapsed,
      remainingTime: ETACalculator.calculateETA(steps),
      steps: steps.map((step, index) => ({
        step: index + 1,
        name: step.name,
        status: this.getStepStatus(steps, index)
      }))
    };
  }
}
```

## 使用示例

### 完整错误处理流程
```typescript
async function executeComplexTask() {
  try {
    // 执行任务
    const result = await doWork();

    // 返回成功结果
    return { success: true, result };

  } catch (error) {
    // 识别错误类型
    const errorType = this.identifyErrorType(error);

    // 应用对应的处理策略
    switch (errorType) {
      case 'network':
        return await NetworkErrorHandler.handleNetworkError(error);
      case 'tool':
        return await ToolErrorHandler.handleToolError(error, toolName, params);
      case 'validation':
        return await ValidationErrorHandler.handleValidationError(error, data);
      case 'dependency':
        return await DependencyManager.resolveDependencies(dependencies);
      default:
        return {
          success: false,
          error,
          suggestion: '请检查日志获取详细信息'
        };
    }
  }
}
```

### 可视化进度更新
```typescript
async function executeWithProgress() {
  const task = new ProgressMonitor(taskId, totalSteps, (progress) => {
    ProgressVisualizer.updateTaskStatus(taskId, progress);
  });

  try {
    // 执行步骤
    for (let i = 1; i <= totalSteps; i++) {
      await executeStep(i);
    }

    return { success: true };

  } catch (error) {
    task.stop();
    return this.handleTaskError(error);

  } finally {
    task.stop();
  }
}
```

---

## 错误分类总结

| 错误类型 | 类型 | 重试策略 | 备用方案 | 手动干预 |
|---------|------|---------|---------|---------|
| 网络错误 | NetworkError | 指数退避重试 | 离线模式、切换网络 | 否 |
| 工具调用错误 | ToolCallError | 重试、备用工具 | 替代工具 | 是 |
| 数据验证错误 | ValidationError | 自动修复 | 自动修复、替换数据 | 是 |
| 依赖问题错误 | DependencyError | 升级依赖、降级依赖 | 更换依赖版本 | 是 |
| 约束违反错误 | ConstraintViolationError | 自动修正 | 自动修正 | 否 |

---

*最后更新：2026-02-12*
*维护者：灵眸*
