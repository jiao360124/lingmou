# 技能联动系统

## 概述
技能联动系统实现Auto-GPT自动调用其他技能的能力，实现跨技能协作，提升任务完成效率。

## 架构设计

### 核心组件

#### 1. 技能注册中心
```typescript
class SkillRegistry {
  private skills: Map<string, Skill> = new Map();

  registerSkill(skill: Skill) {
    this.skills.set(skill.name, skill);
  }

  getSkill(name: string): Skill | undefined {
    return this.skills.get(name);
  }

  getAvailableSkills(): Skill[] {
    return Array.from(this.skills.values());
  }
}
```

#### 2. 技能调用器
```typescript
class SkillCaller {
  private registry: SkillRegistry;

  async callSkill(
    skillName: string,
    params: SkillParams
  ): Promise<SkillResult> {
    const skill = this.registry.getSkill(skillName);

    if (!skill) {
      throw new Error(`技能 ${skillName} 不存在`);
    }

    // 验证参数
    await this.validateParams(skill, params);

    // 执行技能
    const result = await skill.execute(params);

    // 记录调用
    await this.logCall(skillName, params, result);

    return result;
  }

  private async validateParams(
    skill: Skill,
    params: SkillParams
  ): Promise<void> {
    if (!skill.validateParams) {
      return;
    }

    const isValid = await skill.validateParams(params);
    if (!isValid) {
      throw new Error('参数验证失败');
    }
  }

  private async logCall(
    skillName: string,
    params: SkillParams,
    result: SkillResult
  ): Promise<void> {
    // 记录调用日志
    console.log(`调用技能: ${skillName}`, {
      params,
      result,
      timestamp: new Date().toISOString()
    });
  }
}
```

#### 3. 协作流程引擎
```typescript
class CollaborationEngine {
  private caller: SkillCaller;
  private flowRegistry: Map<string, SkillFlow> = new Map();

  async executeFlow(flowName: string, context: FlowContext): Promise<FlowResult> {
    const flow = this.flowRegistry.get(flowName);

    if (!flow) {
      throw new Error(`流程 ${flowName} 不存在`);
    }

    const results: SkillResult[] = [];
    let currentContext = context;

    // 按顺序执行流程中的技能
    for (const step of flow.steps) {
      // 条件检查
      if (step.condition && !await step.condition(currentContext, results)) {
        continue;
      }

      // 调用技能
      const result = await this.caller.callSkill(step.skill, {
        ...currentContext,
        previousResults: results
      });

      results.push(result);

      // 更新上下文
      currentContext = await this.updateContext(currentContext, result, step);
    }

    return {
      success: true,
      results,
      finalContext: currentContext
    };
  }

  private async updateContext(
    context: FlowContext,
    result: SkillResult,
    step: FlowStep
  ): Promise<FlowContext> {
    // 根据步骤配置更新上下文
    const updatedContext = { ...context };

    if (step.contextUpdates) {
      Object.assign(updatedContext, step.contextUpdates);
    }

    return updatedContext;
  }
}
```

## 技能流程定义

### 示例1: 代码审查流程
```typescript
const codeReviewFlow: SkillFlow = {
  name: 'code-review-flow',
  steps: [
    {
      skill: 'copilot',
      condition: async (context) => context.hasCode,
      action: async (context) => ({
        params: {
          type: 'review',
          code: context.code,
          language: context.language
        }
      })
    },
    {
      skill: 'auto-gpt',
      condition: async (context, results) => {
        const copilotResult = results.find(r => r.skill === 'copilot');
        return copilotResult?.issues?.length > 0;
      },
      contextUpdates: {
        reviewResult: (context, results) => {
          const copilotResult = results.find(r => r.skill === 'copilot');
          return copilotResult?.result;
        }
      }
    },
    {
      skill: 'task-status',
      condition: async (context) => context.needsStatusReport,
      action: async (context) => ({
        params: {
          message: `代码审查完成，发现 ${context.reviewResult.issues?.length || 0} 个问题`
        }
      })
    }
  ]
};
```

### 示例2: 自动化测试流程
```typescript
const testAutomationFlow: SkillFlow = {
  name: 'test-automation-flow',
  steps: [
    {
      skill: 'auto-gpt',
      condition: async (context) => true,
      action: async (context) => ({
        params: {
          task: '运行所有单元测试并生成报告',
          outputPath: context.outputPath
        }
      })
    },
    {
      skill: 'copilot',
      condition: async (context, results) => {
        const testResult = results.find(r => r.skill === 'auto-gpt');
        return testResult?.failed || false;
      },
      action: async (context) => ({
        params: {
          type: 'debug',
          code: context.testCode,
          error: context.testError
        }
      })
    },
    {
      skill: 'rag',
      condition: async (context) => context.needsDocumentation,
      action: async (context) => ({
        query: `如何调试失败的单元测试？`,
        output: context.testDebugDoc
      })
    }
  ]
};
```

## 技能调用限制

### 1. 调用频率限制
```typescript
class RateLimiter {
  private calls: Map<string, number[]> = new Map();
  private maxCallsPerMinute: number = 60;

  async allowCall(skillName: string): Promise<boolean> {
    const now = Date.now();
    const calls = this.calls.get(skillName) || [];

    // 移除1分钟前的调用记录
    const recentCalls = calls.filter(time => now - time < 60000);

    if (recentCalls.length >= this.maxCallsPerMinute) {
      return false;
    }

    recentCalls.push(now);
    this.calls.set(skillName, recentCalls);

    return true;
  }
}
```

### 2. 依赖管理
```typescript
class DependencyManager {
  private dependencies: Map<string, string[]> = new Map();

  registerDependency(skillName: string, dependsOn: string[]) {
    this.dependencies.set(skillName, dependsOn);
  }

  async checkDependencies(skillName: string): Promise<boolean> {
    const dependsOn = this.dependencies.get(skillName) || [];

    for (const dep of dependsOn) {
      const isAvailable = await this.checkAvailability(dep);
      if (!isAvailable) {
        console.log(`缺少依赖: ${skillName} 需要 ${dep}`);
        return false;
      }
    }

    return true;
  }

  private async checkAvailability(skillName: string): Promise<boolean> {
    // 检查技能是否可用
    return true;
  }
}
```

### 3. 错误处理
```typescript
class ErrorRecovery {
  private failures: Map<string, number> = new Map();

  async handleCallError(
    skillName: string,
    error: Error
  ): Promise<RecoveryAction> {
    const failureCount = this.failures.get(skillName) || 0;

    // 记录失败次数
    this.failures.set(skillName, failureCount + 1);

    // 根据失败次数决定恢复策略
    if (failureCount < 3) {
      return {
        action: 'retry',
        delay: 1000 * (failureCount + 1)
      };
    } else if (failureCount < 5) {
      return {
        action: 'fallback',
        alternative: 'manual'
      };
    } else {
      return {
        action: 'abort',
        reason: '多次失败，终止调用'
      };
    }
  }
}
```

## 使用示例

### 基础调用
```typescript
// 调用Copilot进行代码审查
const result = await caller.callSkill('copilot', {
  type: 'review',
  code: reactComponentCode,
  language: 'typescript'
});

console.log('审查结果:', result);
```

### 流程执行
```typescript
// 执行代码审查流程
const flowResult = await engine.executeFlow('code-review-flow', {
  hasCode: true,
  code: code,
  language: 'typescript',
  needsStatusReport: true
});

console.log('流程结果:', flowResult);
```

### 复杂协作
```typescript
// 创建复杂协作任务
const complexTask = {
  steps: [
    // 步骤1: 使用Copilot进行代码分析
    {
      skill: 'copilot',
      params: { type: 'analyze', code }
    },
    // 步骤2: 如果有问题，使用Auto-GPT修复
    {
      condition: (context) => context.copilotResult.hasIssues,
      skill: 'auto-gpt',
      params: {
        task: '修复代码问题',
        code: context.copilotResult.code
      }
    },
    // 步骤3: 使用RAG获取相关文档
    {
      skill: 'rag',
      params: {
        query: 'React组件最佳实践',
        context: context.fixedCode
      }
    },
    // 步骤4: 使用Prompt-Engineering优化代码
    {
      skill: 'prompt-engineering',
      params: {
        template: 'code-review',
        code: context.fixedCode
      }
    }
  ]
};
```

## 性能优化

### 1. 并行执行
```typescript
class ParallelExecutor {
  async executeInParallel(
    steps: FlowStep[],
    context: FlowContext
  ): Promise<FlowResult> {
    const promises = steps.map(step => {
      if (!step.condition || await step.condition(context)) {
        return this.executeStep(step, context);
      }
      return Promise.resolve({ success: true, result: null });
    });

    const results = await Promise.all(promises);
    return { success: true, results };
  }
}
```

### 2. 结果缓存
```typescript
class ResultCache {
  private cache: Map<string, SkillResult> = new Map();

  async getCachedResult(
    skillName: string,
    params: any
  ): Promise<SkillResult | null> {
    const key = this.generateKey(skillName, params);
    return this.cache.get(key) || null;
  }

  async cacheResult(
    skillName: string,
    params: any,
    result: SkillResult
  ): Promise<void> {
    const key = this.generateKey(skillName, params);
    this.cache.set(key, result);
  }

  private generateKey(skillName: string, params: any): string {
    return `${skillName}:${JSON.stringify(params)}`;
  }
}
```

## 监控和调试

### 调用监控
```typescript
class SkillMonitor {
  async monitorCall(
    skillName: string,
    action: () => Promise<any>
  ): Promise<any> {
    const start = Date.now();

    try {
      const result = await action();
      const duration = Date.now() - start;

      this.logSuccess(skillName, duration);
      return result;
    } catch (error) {
      const duration = Date.now() - start;
      this.logFailure(skillName, error, duration);
      throw error;
    }
  }

  private logSuccess(skillName: string, duration: number): void {
    console.log(`✅ 技能 ${skillName} 执行成功`, {
      duration: `${duration}ms`
    });
  }

  private logFailure(skillName: string, error: Error, duration: number): void {
    console.error(`❌ 技能 ${skillName} 执行失败`, {
      error: error.message,
      duration: `${duration}ms`
    });
  }
}
```

## 最佳实践

1. **合理设计流程**: 避免过于复杂的技能链
2. **错误处理**: 为每个步骤添加错误处理
3. **性能监控**: 记录每个技能的执行时间
4. **参数验证**: 在调用前验证参数
5. **资源管理**: 及时释放资源，避免内存泄漏

## 扩展指南

开发者可以添加自定义技能：
```typescript
// 1. 创建技能实现
class CustomSkill implements Skill {
  name = 'custom-skill';

  async execute(params: any): Promise<SkillResult> {
    // 实现技能逻辑
    return { success: true, result: data };
  }

  async validateParams(params: any): Promise<boolean> {
    // 验证参数
    return true;
  }
}

// 2. 注册技能
registry.registerSkill(new CustomSkill());
```

## 未来改进

- [ ] 支持异步技能链
- [ ] 添加技能执行优先级
- [ ] 实现技能编排可视化
- [ ] 添加技能调用性能分析
- [ ] 支持技能插件系统
