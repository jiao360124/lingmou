# 自我诊断与修复机制 - 设计文档

## 概述
自我诊断与修复机制是灵眸的"健康系统"，能够自动检测系统健康状态、识别问题并执行修复，确保持续稳定运行。

## 系统架构

### 核心组件

#### 1. 健康度自检器（HealthChecker）
**功能**：全面检查系统健康状态

**检查维度**：
1. **技能完整性**
   - 检查所有技能文件是否存在
   - 检查技能实现是否完整
   - 检查技能API是否可用

2. **文档完整性**
   - 检查技能文档是否存在
   - 检查文档是否最新
   - 检查文档链接是否有效

3. **配置有效性**
   - 检查配置文件是否存在
   - 检查配置格式是否正确
   - 检查配置项是否完整

4. **性能指标**
   - 检查响应时间
   - 检查资源使用率
   - 检查并发处理能力

5. **依赖关系**
   - 检查技能依赖是否满足
   - 检查API依赖是否可用
   - 检查外部服务连接

6. **安全性**
   - 检查权限设置
   - 检查敏感信息泄露
   - 检查安全漏洞

**实现逻辑**：
```typescript
class HealthChecker {
  async checkSystemHealth(): Promise<HealthReport> {
    const report: HealthReport = {
      timestamp: new Date(),
      skills: {},
      documents: {},
      config: {},
      performance: {},
      dependencies: {},
      security: {},
      overallHealth: 'unknown'
    };

    // 并行执行所有检查
    const results = await Promise.allSettled([
      this.checkSkills(report),
      this.checkDocuments(report),
      this.checkConfig(report),
      this.checkPerformance(report),
      this.checkDependencies(report),
      this.checkSecurity(report)
    ]);

    // 处理检查结果
    for (const result of results) {
      if (result.status === 'fulfilled') {
        // 检查成功，更新报告
      } else {
        // 检查失败，记录错误
      }
    }

    // 计算总体健康度
    report.overallHealth = this.calculateOverallHealth(report);

    return report;
  }

  private async checkSkills(report: HealthReport): Promise<void> {
    const skills = await this.getSkillList();
    for (const skill of skills) {
      const status = await this.checkSkillHealth(skill);
      report.skills[skill.name] = status;
    }
  }

  private async checkSkillHealth(skill: Skill): Promise<SkillHealthStatus> {
    // 1. 检查文件是否存在
    const fileExists = await this.fileExists(skill.filePath);
    if (!fileExists) {
      return { status: 'missing', file: skill.filePath };
    }

    // 2. 检查实现完整性
    const implementationComplete = await this.checkImplementationComplete(skill);
    if (!implementationComplete) {
      return { status: 'incomplete', file: skill.filePath };
    }

    // 3. 检查API可用性
    const apiAvailable = await this.checkAPIAvailable(skill);
    if (!apiAvailable) {
      return { status: 'unavailable', file: skill.filePath };
    }

    // 4. 检查性能
    const performance = await this.checkPerformance(skill);
    if (performance.failed) {
      return { status: 'performance_issue', file: skill.filePath, performance };
    }

    return { status: 'healthy', file: skill.filePath };
  }

  private async checkPerformance(skill: Skill): Promise<PerformanceMetrics> {
    const start = Date.now();
    try {
      // 执行一次测试调用
      await skill.execute({ test: true });
      const duration = Date.now() - start;
      return { success: true, duration, maxDuration: 1000 };
    } catch (error) {
      return { success: false, duration: Date.now() - start, error };
    }
  }

  private calculateOverallHealth(report: HealthReport): HealthLevel {
    const totalChecks = Object.keys(report.skills).length +
                       Object.keys(report.documents).length +
                       Object.keys(report.config).length +
                       Object.keys(report.performance).length +
                       Object.keys(report.dependencies).length +
                       Object.keys(report.security).length;

    const passedChecks = Object.values(report.skills).filter(s => s.status === 'healthy').length +
                       Object.values(report.documents).filter(d => d.status === 'healthy').length +
                       Object.values(report.config).filter(c => c.status === 'healthy').length +
                       Object.values(report.performance).filter(p => p.success).length +
                       Object.values(report.dependencies).filter(d => d.available).length +
                       Object.values(report.security).filter(s => s.safe).length;

    const passedRate = passedChecks / totalChecks;

    if (passedRate >= 0.95) return 'excellent';
    if (passedRate >= 0.8) return 'good';
    if (passedRate >= 0.6) return 'fair';
    if (passedRate >= 0.4) return 'poor';
    return 'critical';
  }
}
```

**健康等级**：
- **Excellent（优秀）**：95%以上检查通过
- **Good（良好）**：80%以上检查通过
- **Fair（一般）**：60%以上检查通过
- **Poor（较差）**：40%以上检查通过
- **Critical（危急）**：低于40%检查通过

---

#### 2. 问题识别器（ProblemIdentifier）
**功能**：从日志、指标、反馈中识别问题

**问题来源**：
1. **日志分析**
   - 错误日志
   - 警告日志
   - 异常堆栈

2. **性能监控**
   - 响应时间过长
   - 资源使用异常
   - 并发瓶颈

3. **用户反馈**
   - 功能问题报告
   - 性能抱怨
   - Bug反馈

4. **社区反馈**
   - 技能使用问题
   - 文档问题
   - API问题

**实现逻辑**：
```typescript
class ProblemIdentifier {
  async identifyProblems(): Promise<Problem[]> {
    const problems: Problem[] = [];

    // 1. 从日志中识别问题
    const logProblems = await this.analyzeLogs();
    problems.push(...logProblems);

    // 2. 从性能指标中识别问题
    const metricProblems = await this.analyzeMetrics();
    problems.push(...metricProblems);

    // 3. 从用户反馈中识别问题
    const feedbackProblems = await this.analyzeFeedback();
    problems.push(...feedbackProblems);

    // 4. 去重和分类
    return this.deduplicateAndClassify(problems);
  }

  private async analyzeLogs(): Promise<Problem[]> {
    const problems: Problem[] = [];
    const logs = await this.getLogEntries(last24Hours);

    // 检查错误日志
    const errors = logs.filter(l => l.level === 'error');
    for (const error of errors) {
      const problem = await this.identifyFromLog(error);
      if (problem) {
        problems.push(problem);
      }
    }

    // 检查警告日志
    const warnings = logs.filter(l => l.level === 'warning');
    for (const warning of warnings) {
      const problem = await this.identifyFromWarning(warning);
      if (problem) {
        problems.push(problem);
      }
    }

    return problems;
  }

  private async identifyFromLog(error: LogEntry): Promise<Problem | null> {
    // 分析错误类型和原因
    const errorType = this.classifyError(error);
    const severity = this.calculateSeverity(error);
    const affectedComponent = this.findAffectedComponent(error);

    // 检查是否已存在
    const existing = await this.findSimilarProblem(error);
    if (existing) {
      existing.count++;
      return null;
    }

    return {
      id: this.generateProblemId(),
      type: errorType,
      severity,
      component: affectedComponent,
      description: this.formatDescription(error),
      details: error,
      firstOccurrence: error.timestamp,
      lastOccurrence: error.timestamp,
      count: 1,
      status: 'open'
    };
  }

  private async analyzeMetrics(): Promise<Problem[]> {
    const problems: Problem[] = [];
    const metrics = await this.getPerformanceMetrics(lastHour);

    // 检查响应时间
    for (const metric of metrics) {
      if (metric.responseTime > 1000) {
        problems.push({
          id: this.generateProblemId(),
          type: 'performance',
          severity: 'medium',
          component: metric.component,
          description: `组件 ${metric.component} 响应时间过长（${metric.responseTime}ms）`,
          details: metric,
          firstOccurrence: metric.timestamp,
          lastOccurrence: metric.timestamp,
          count: 1,
          status: 'open'
        });
      }
    }

    return problems;
  }

  private async analyzeFeedback(): Promise<Problem[]> {
    const problems: Problem[] = [];
    const feedbacks = await this.getUserFeedback(lastWeek);

    for (const feedback of feedbacks) {
      const problem = await this.identifyFromFeedback(feedback);
      if (problem) {
        problems.push(problem);
      }
    }

    return problems;
  }
}
```

**问题分类**：
- **性能问题**：响应慢、资源占用高
- **功能问题**：功能异常、bug
- **文档问题**：文档错误、过时
- **配置问题**：配置错误、缺失
- **依赖问题**：依赖不可用、版本不兼容

**问题严重程度**：
- **Critical（危急）**：系统无法正常运行
- **High（高）**：影响核心功能
- **Medium（中）**：影响部分功能
- **Low（低）**：轻微影响，不紧急

---

#### 3. 修复执行器（RepairExecutor）
**功能**：执行修复方案

**修复策略**：
1. **自动修复**：完全自动化修复
2. **半自动修复**：需要用户确认的修复
3. **手动修复**：需要人工介入的修复
4. **回滚方案**：修复失败后回滚

**实现逻辑**：
```typescript
class RepairExecutor {
  async executeRepair(problem: Problem): Promise<RepairResult> {
    console.log(`开始修复问题: ${problem.id} (${problem.type})`);

    // 1. 确定修复策略
    const strategy = await this.determineStrategy(problem);
    console.log(`修复策略: ${strategy}`);

    try {
      switch (strategy) {
        case 'auto':
          return await this.executeAutoRepair(problem);
        case 'semi-auto':
          return await this.executeSemiAutoRepair(problem);
        case 'manual':
          return await this.promptForManualRepair(problem);
        case 'rollback':
          return await this.executeRollback(problem);
        default:
          throw new Error(`未知的修复策略: ${strategy}`);
      }
    } catch (error) {
      console.error(`修复失败: ${error}`);
      return {
        success: false,
        error: error.message,
        problemId: problem.id,
        timestamp: new Date()
      };
    }
  }

  private async determineStrategy(problem: Problem): Promise<RepairStrategy> {
    // 根据问题类型和严重程度确定策略
    switch (problem.type) {
      case 'performance':
        return 'auto';
      case 'documentation':
        return 'semi-auto';
      case 'configuration':
        return 'manual';
      case 'dependency':
        return 'semi-auto';
      default:
        return 'manual';
    }
  }

  private async executeAutoRepair(problem: Problem): Promise<RepairResult> {
    // 完全自动修复
    const repairScript = await this.generateAutoRepairScript(problem);
    const success = await this.runRepairScript(repairScript);

    if (success) {
      await this.verifyRepair(problem);
      return {
        success: true,
        method: 'auto',
        problemId: problem.id,
        timestamp: new Date()
      };
    } else {
      return {
        success: false,
        method: 'auto',
        error: '自动修复失败',
        problemId: problem.id,
        timestamp: new Date()
      };
    }
  }

  private async executeSemiAutoRepair(problem: Problem): Promise<RepairResult> {
    // 生成修复方案，需要用户确认
    const repairScript = await this.generateSemiAutoRepairScript(problem);

    // 生成修复预览
    const preview = this.generateRepairPreview(repairScript, problem);

    // 显示给用户确认
    const confirmed = await this.promptUserConfirmation(preview);
    if (!confirmed) {
      return {
        success: false,
        method: 'semi-auto',
        error: '用户取消修复',
        problemId: problem.id,
        timestamp: new Date()
      };
    }

    // 执行修复
    const success = await this.runRepairScript(repairScript);

    if (success) {
      await this.verifyRepair(problem);
      return {
        success: true,
        method: 'semi-auto',
        problemId: problem.id,
        timestamp: new Date()
      };
    } else {
      return {
        success: false,
        method: 'semi-auto',
        error: '修复执行失败',
        problemId: problem.id,
        timestamp: new Date()
      };
    }
  }

  private async executeRollback(problem: Problem): Promise<RepairResult> {
    // 回滚到上一个稳定状态
    const rollbackScript = await this.generateRollbackScript(problem);

    if (rollbackScript) {
      const success = await this.runRepairScript(rollbackScript);
      if (success) {
        return {
          success: true,
          method: 'rollback',
          problemId: problem.id,
          timestamp: new Date()
        };
      }
    }

    return {
      success: false,
      method: 'rollback',
      error: '回滚失败',
      problemId: problem.id,
      timestamp: new Date()
    };
  }

  private async verifyRepair(problem: Problem): Promise<boolean> {
    // 执行验证测试
    const tests = await this.getVerificationTests(problem);
    const results = await Promise.all(tests.map(t => t.run()));

    const allPassed = results.every(r => r.passed);
    return allPassed;
  }
}
```

**修复验证**：
- 重新执行健康检查
- 执行单元测试
- 执行集成测试
- 验证功能是否正常

---

#### 4. 报告生成器（ReportGenerator）
**功能**：生成诊断和修复报告

**报告类型**：
1. **健康报告**：系统健康状态摘要
2. **问题报告**：识别的问题列表
3. **修复报告**：修复操作和结果
4. **分析报告**：长期趋势和统计

**实现逻辑**：
```typescript
class ReportGenerator {
  async generateHealthReport(): Promise<HealthReport> {
    return await healthChecker.checkSystemHealth();
  }

  async generateProblemReport(): Promise<ProblemReport> {
    const problems = await problemIdentifier.identifyProblems();
    return {
      timestamp: new Date(),
      totalProblems: problems.length,
      bySeverity: this.groupBySeverity(problems),
      byType: this.groupByType(problems),
      byComponent: this.groupByComponent(problems),
      problems
    };
  }

  async generateRepairReport(problemId: string): Promise<RepairReport> {
    const problem = await problemIdentifier.findProblem(problemId);
    if (!problem) {
      throw new Error(`问题不存在: ${problemId}`);
    }

    const repair = await repairExecutor.executeRepair(problem);

    return {
      timestamp: new Date(),
      problemId,
      repair,
      healthBefore: await healthChecker.checkSystemHealth(),
      healthAfter: repair.success ? await healthChecker.checkSystemHealth() : null
    };
  }

  async generateAnalysisReport(period: string): Promise<AnalysisReport> {
    const problems = await problemIdentifier.identifyProblems();
    const repairs = await this.getRepairs(period);

    return {
      timestamp: new Date(),
      period,
      totalProblems: problems.length,
      totalRepairs: repairs.length,
      problemsBySeverity: this.groupBySeverity(problems),
      repairSuccessRate: this.calculateSuccessRate(repairs),
      trends: this.analyzeTrends(problems, repairs)
    };
  }

  private groupBySeverity(problems: Problem[]): Record<HealthLevel, number> {
    const groups: Record<HealthLevel, number> = {
      critical: 0,
      high: 0,
      medium: 0,
      low: 0
    };

    for (const problem of problems) {
      groups[problem.severity]++;
    }

    return groups;
  }

  private groupByType(problems: Problem[]): Record<string, number> {
    const groups: Record<string, number> = {};

    for (const problem of problems) {
      groups[problem.type] = (groups[problem.type] || 0) + 1;
    }

    return groups;
  }

  private groupByComponent(problems: Problem[]): Record<string, number> {
    const groups: Record<string, number> = {};

    for (const problem of problems) {
      groups[problem.component] = (groups[problem.component] || 0) + 1;
    }

    return groups;
  }

  private calculateSuccessRate(repairs: Repair[]): number {
    const total = repairs.length;
    const success = repairs.filter(r => r.success).length;
    return total > 0 ? success / total : 0;
  }

  private analyzeTrends(problems: Problem[], repairs: Repair[]): TrendAnalysis {
    return {
      problemFrequency: this.analyzeProblemFrequency(problems),
      repairEffectiveness: this.analyzeRepairEffectiveness(repairs),
      mostCommonProblems: this.getMostCommonProblems(problems, 5),
      improvementRate: this.calculateImprovementRate(problems, repairs)
    };
  }
}
```

---

## 使用示例

### 执行健康检查

```powershell
# 查看系统健康状态
自我诊断: 检查系统健康

# 查看详细报告
自我诊断: 查看详细健康报告

# 定时检查（设置cron）
自我诊断: 设置定时检查，每天凌晨2点执行
```

### 查看问题

```powershell
# 查看所有识别的问题
自我诊断: 查看所有问题

# 查看特定类型的问题
自我诊断: 查看性能问题

# 查看严重问题
自我诊断: 查看危急和高优先级问题
```

### 执行修复

```powershell
# 自动修复所有问题
自我诊断: 自动修复所有问题

# 修复特定问题
自我诊断: 修复问题 "skill-doc-not-found"

# 手动修复（需要确认）
自我诊断: 手动修复 "配置错误"
```

### 查看报告

```powershell
# 查看健康报告
自我诊断: 查看健康报告

# 查看问题报告
自我诊断: 查看问题报告

# 查看修复报告
自我诊断: 查看修复报告

# 查看分析报告
自我诊断: 查看分析报告（最近7天）
```

---

## 配置和管理

### 配置文件
```json
{
  "selfDiagnosis": {
    "enabled": true,
    "checkInterval": "1h",
    "checkTime": "02:00",
    "autoRepair": {
      "enabled": true,
      "maxAttempts": 3,
      "onFailureStrategy": "rollback"
    },
    "problemTypes": {
      "performance": {
        "severity": "medium",
        "autoRepair": true
      },
      "documentation": {
        "severity": "low",
        "autoRepair": false
      },
      "configuration": {
        "severity": "high",
        "autoRepair": false
      }
    },
    "reporting": {
      "enabled": true,
      "reportTypes": ["health", "problem", "repair", "analysis"],
      "reportFrequency": "daily"
    }
  }
}
```

### 日志记录
```
diagnosis-logs/
├── health-checks/
│   ├── 2026-02-12.log
│   ├── 2026-02-13.log
│   └── ...
├── problems/
│   ├── identified-2026-02-12.json
│   ├── identified-2026-02-13.json
│   └── ...
├── repairs/
│   ├── repair-2026-02-12.log
│   ├── repair-2026-02-13.log
│   └── ...
└── reports/
    ├── health-report-2026-02-12.md
    ├── problem-report-2026-02-12.md
    └── analysis-report-2026-02-12.md
```

---

## 技术实现

### 核心类
1. **HealthChecker**：健康度自检器
2. **ProblemIdentifier**：问题识别器
3. **RepairExecutor**：修复执行器
4. **ReportGenerator**：报告生成器

### 数据结构
- **HealthReport**：健康报告
- **HealthLevel**：健康等级
- **Problem**：问题定义
- **RepairResult**：修复结果
- **AnalysisReport**：分析报告

---

## 安全考虑

1. **权限控制**：只执行有权限的修复
2. **备份机制**：修复前创建备份
3. **回滚机制**：修复失败时回滚
4. **用户确认**：高风险修复需要用户确认
5. **日志记录**：完整记录所有操作

---

## 性能考虑

1. **异步执行**：并行执行健康检查
2. **增量检查**：只检查变化的部分
3. **缓存机制**：缓存检查结果
4. **批处理**：批量处理报告生成
5. **延迟加载**：延迟加载非关键组件

---

## 扩展性

### 添加新的检查维度
```typescript
const newDimension: HealthDimension = {
  name: 'custom-dimension',
  checkFunction: async () => {
    // 自定义检查逻辑
  }
};
```

### 添加新的问题类型
```typescript
const newProblemType: ProblemType = {
  name: 'new-type',
  severity: 'medium',
  autoRepair: false
};
```

---

## 总结

自我诊断与修复机制为灵眸提供了完整的健康保障，确保系统持续稳定运行。通过自动化的检测、识别和修复，大大减少了人工维护的成本和风险。

**关键特性**：
- ✅ 全面的健康检查
- ✅ 智能的问题识别
- ✅ 灵活的修复策略
- ✅ 完善的验证机制
- ✅ 详细的报告系统
- ✅ 安全的修复过程

**使用建议**：
1. 定期执行健康检查
2. 及时修复识别出的问题
3. 定期查看分析报告
4. 学习和改进修复策略
5. 持续优化系统健康度
