# Prompt-Engineering质量检查器

## 概述
Prompt质量检查器用于评估和优化提示词的质量，确保生成的提示词清晰、完整、有效。

## 质量维度

### 1. 清晰性 (Clarity)
**评分标准**:
- 指令明确：90-100%
- 无歧义：85-95%
- 语言简洁：90-100%

**检查点**:
- 是否使用简单清晰的语言
- 是否有歧义的表达
- 是否可以快速理解
- 是否使用专业术语但不过度

### 2. 完整性 (Completeness)
**评分标准**:
- 包含所有必要信息：90-100%
- 提供足够上下文：85-95%
- 指令完整：90-100%

**检查点**:
- 是否包含任务描述
- 是否提供背景信息
- 是否说明输出格式
- 是否列出约束条件

### 3. 针对性 (Relevance)
**评分标准**:
- 针对特定任务：90-100%
- 符合用户意图：85-95%
- 目标明确：90-100%

**检查点**:
- 是否针对特定场景
- 是否符合用户目标
- 是否有明确的输出期望
- 是否避免了无关内容

### 4. 可执行性 (Actionability)
**评分标准**:
- 可以直接执行：90-100%
- 步骤清晰：85-95%
- 资源充足：90-100%

**检查点**:
- 指令是否具体可执行
- 是否有明确的步骤
- 是否提供必要的资源
- 是否限制在合理范围内

### 5. 可扩展性 (Scalability)
**评分标准**:
- 可以重复使用：90-100%
- 易于调整：85-95%
- 适合多种场景：85-95%

**检查点**:
- 是否可以应用到类似任务
- 是否易于修改和调整
- 是否有通用模板结构
- 是否保留扩展空间

## 质量检查器实现

```typescript
class PromptQualityChecker {
  private qualityDimensions: Map<string, QualityDimension>;

  constructor() {
    this.qualityDimensions = new Map([
      ['clarity', new QualityDimension('清晰性', 90, 100)],
      ['completeness', new QualityDimension('完整性', 85, 100)],
      ['relevance', new QualityDimension('针对性', 85, 100)],
      ['actionability', new QualityDimension('可执行性', 85, 100)],
      ['scalability', new QualityDimension('可扩展性', 85, 100)]
    ]);
  }

  async check(prompt: Prompt): Promise<PromptQuality> {
    const scores = new Map<string, number>();

    for (const [dimension, checker] of this.qualityDimensions) {
      const score = await checker.check(prompt);
      scores.set(dimension, score);
    }

    const averageScore = this.calculateAverage(scores);
    const issues = this.findIssues(prompt, scores);

    return {
      scores,
      averageScore,
      issues,
      status: this.getStatus(averageScore),
      recommendations: this.generateRecommendations(issues)
    };
  }

  private calculateAverage(scores: Map<string, number>): number {
    let sum = 0;
    for (const score of scores.values()) {
      sum += score;
    }
    return sum / scores.size;
  }

  private findIssues(prompt: Prompt, scores: Map<string, number>): Issue[] {
    const issues: Issue[] = [];

    for (const [dimension, score] of scores) {
      if (score < this.qualityDimensions.get(dimension)!.min) {
        issues.push({
          dimension,
          score,
          severity: this.getSeverity(score),
          message: `${dimension}评分过低 (${score})`
        });
      }
    }

    return issues;
  }

  private getStatus(score: number): PromptStatus {
    if (score >= 90) return 'excellent';
    if (score >= 80) return 'good';
    if (score >= 70) return 'acceptable';
    if (score >= 60) return 'poor';
    return 'very_poor';
  }

  private generateRecommendations(issues: Issue[]): Recommendation[] {
    const recommendations: Recommendation[] = [];

    for (const issue of issues) {
      switch (issue.dimension) {
        case 'clarity':
          recommendations.push({
            score: issue.score,
            message: '使用更清晰的语言，避免专业术语'
          });
          break;
        case 'completeness':
          recommendations.push({
            score: issue.score,
            message: '补充背景信息和约束条件'
          });
          break;
        case 'relevance':
          recommendations.push({
            score: issue.score,
            message: '明确任务目标和使用场景'
          });
          break;
        case 'actionability':
          recommendations.push({
            score: issue.score,
            message: '提供更具体的执行步骤'
          });
          break;
        case 'scalability':
          recommendations.push({
            score: issue.score,
            message: '保留模板结构，便于调整'
          });
          break;
      }
    }

    return recommendations;
  }
}
```

## 检查实现

### 1. 清晰性检查器
```typescript
class ClarityChecker {
  async check(prompt: Prompt): Promise<number> {
    const complexity = this.calculateComplexity(prompt);
    const ambiguity = this.detectAmbiguity(prompt);
    const conciseness = this.calculateConciseness(prompt);

    // 清晰性评分 = (1 - 复杂度) * (1 - 歧义) * 简洁度
    const score = (1 - complexity * 0.3) *
                 (1 - ambiguity * 0.4) *
                 conciseness;

    return Math.min(100, Math.max(0, score * 100));
  }

  private calculateComplexity(prompt: Prompt): number {
    // 计算复杂度：句子长度、专业术语数量等
    return 0;
  }

  private detectAmbiguity(prompt: Prompt): number {
    // 检测歧义词汇和模糊表达
    const ambiguousWords = ['大概', '可能', '应该', '某些'];
    return this.countOccurrences(prompt, ambiguousWords) / prompt.length;
  }

  private calculateConciseness(prompt: Prompt): number {
    // 计算简洁度：信息密度
    return 0.8; // 默认值
  }
}
```

### 2. 完整性检查器
```typescript
class CompletenessChecker {
  async check(prompt: Prompt): Promise<number> {
    const checks = [
      this.checkTaskDescription,
      this.checkContext,
      this.checkOutputFormat,
      this.checkConstraints,
      this.checkResources
    ];

    const results = await Promise.all(checks.map(check => check(prompt)));
    const score = this.calculateScore(results);

    return score;
  }

  private async checkTaskDescription(prompt: Prompt): Promise<boolean> {
    return prompt.task !== undefined && prompt.task.trim().length > 0;
  }

  private async checkContext(prompt: Prompt): Promise<boolean> {
    return prompt.context !== undefined &&
           prompt.context.trim().length > 0;
  }

  private async checkOutputFormat(prompt: Prompt): Promise<boolean> {
    return prompt.outputFormat !== undefined &&
           prompt.outputFormat.trim().length > 0;
  }

  private async checkConstraints(prompt: Prompt): Promise<boolean> {
    return prompt.constraints === undefined ||
           prompt.constraints.length > 0;
  }

  private async checkResources(prompt: Prompt): Promise<boolean> {
    return prompt.resources === undefined ||
           prompt.resources.length > 0;
  }

  private calculateScore(results: boolean[]): number {
    const score = results.filter(r => r).length / results.length;
    return score * 100;
  }
}
```

### 3. 针对性检查器
```typescript
class RelevanceChecker {
  async check(prompt: Prompt): Promise<number> {
    const relevanceScore = this.analyzeRelevance(prompt);
    const specificity = this.analyzeSpecificity(prompt);
    const goalAlignment = this.analyzeGoalAlignment(prompt);

    return (relevanceScore * 0.4 +
            specificity * 0.3 +
            goalAlignment * 0.3);
  }

  private analyzeRelevance(prompt: Prompt): number {
    // 分析与任务的相关性
    return 0.85;
  }

  private analyzeSpecificity(prompt: Prompt): number {
    // 分析具体程度
    return 0.9;
  }

  private analyzeGoalAlignment(prompt: Prompt): number {
    // 分析与用户目标的对齐度
    return 0.9;
  }
}
```

### 4. 可执行性检查器
```typescript
class ActionabilityChecker {
  async check(prompt: Prompt): Promise<number> {
    const steps = this.extractSteps(prompt);
    const resources = this.checkResources(prompt);
    const constraints = this.checkConstraints(prompt);

    const score = steps * 0.5 + resources * 0.25 + constraints * 0.25;

    return Math.min(100, Math.max(0, score * 100));
  }

  private extractSteps(prompt: Prompt): number {
    // 提取可执行步骤
    return prompt.steps ? prompt.steps.length : 0;
  }

  private checkResources(prompt: Prompt): number {
    // 检查是否提供必要资源
    return prompt.hasResources ? 1 : 0.5;
  }

  private checkConstraints(prompt: Prompt): number {
    // 检查约束是否合理
    return prompt.constraintsValid ? 1 : 0.7;
  }
}
```

### 5. 可扩展性检查器
```typescript
class ScalabilityChecker {
  async check(prompt: Prompt): Promise<number> {
    const reusability = this.checkReusability(prompt);
    const adaptability = this.checkAdaptability(prompt);
    const templateStructure = this.checkTemplateStructure(prompt);

    return (reusability * 0.4 +
            adaptability * 0.3 +
            templateStructure * 0.3);
  }

  private checkReusability(prompt: Prompt): number {
    // 检查可重用性
    return 0.85;
  }

  private checkAdaptability(prompt: Prompt): number {
    // 检查可调整性
    return 0.9;
  }

  private checkTemplateStructure(prompt: Prompt): number {
    // 检查模板结构
    return 0.8;
  }
}
```

## 质量报告生成

```typescript
class QualityReportGenerator {
  generateReport(checkResult: PromptQuality): QualityReport {
    return {
      prompt: checkResult.prompt,
      scores: checkResult.scores,
      averageScore: checkResult.averageScore,
      status: checkResult.status,
      issues: checkResult.issues,
      recommendations: checkResult.recommendations,
      improvementSuggestions: this.generateImprovementSuggestions(checkResult)
    };
  }

  private generateImprovementSuggestions(checkResult: PromptQuality): string[] {
    const suggestions: string[] = [];

    for (const issue of checkResult.issues) {
      switch (issue.dimension) {
        case 'clarity':
          suggestions.push('使用更简单的语言，避免专业术语');
          suggestions.push('使用清晰的动词和名词');
          break;
        case 'completeness':
          suggestions.push('补充背景信息');
          suggestions.push('明确输出格式');
          break;
        case 'relevance':
          suggestions.push('明确任务目标');
          suggestions.push('说明使用场景');
          break;
        case 'actionability':
          suggestions.push('提供具体步骤');
          suggestions.push('列出必要资源');
          break;
        case 'scalability':
          suggestions.push('保留模板结构');
          suggestions.push('便于参数调整');
          break;
      }
    }

    return suggestions;
  }
}
```

## 使用示例

### 基本使用
```typescript
const checker = new PromptQualityChecker();
const result = await checker.check(userPrompt);

console.log(`平均分: ${result.averageScore}`);
console.log(`状态: ${result.status}`);
console.log(`问题: ${result.issues.length}个`);
console.log(`建议: ${result.recommendations.length}条`);
```

### 获取详细报告
```typescript
const report = new QualityReportGenerator();
const qualityReport = report.generateReport(result);

console.log('质量报告:');
console.log(JSON.stringify(qualityReport, null, 2));
```

### 批量检查
```typescript
const prompts = [prompt1, prompt2, prompt3];
const results = await Promise.all(
  prompts.map(p => checker.check(p))
);

const summary = this.generateSummary(results);
console.log(summary);
```

## 质量改进建议

### 1. 逐步改进
```
1. 识别问题
2. 制定改进计划
3. 重新检查
4. 验证改进效果
```

### 2. 最佳实践
1. **从简单开始**: 先创建基本提示，逐步添加细节
2. **迭代优化**: 根据反馈持续改进
3. **记录改进**: 记录改进过程和效果
4. **建立标准**: 建立高质量提示的标准

### 3. 常见问题
- **问题**: 指令过于复杂
  - **解决**: 简化语言，分步骤说明

- **问题**: 缺少上下文
  - **解决**: 提供背景信息和约束条件

- **问题**: 输出格式不明确
  - **解决**: 明确说明期望的输出格式

- **问题**: 目标不清晰
  - **解决**: 明确任务目标和期望结果
