/**
 * Copilot - 性能优化建议系统
 * 分析代码性能瓶颈并提供建议
 */

import { LanguageSupport } from './types';

/**
 * 性能报告
 */
export interface PerformanceReport {
  overallScore: number; // 0-100
  runtimeScore: number;
  memoryScore: number;
  efficiencyScore: number;
  scalabilityScore: number;

  issues: PerformanceIssue[];
  suggestions: PerformanceSuggestion[];
  metrics: PerformanceMetrics;
}

/**
 * 性能指标
 */
export interface PerformanceMetrics {
  estimatedRuntime: number; // ms
  estimatedMemory: number; // MB
  complexity: number; // O(n)
  loops: number;
  asyncOps: number;
  apiCalls: number;
}

/**
 * 性能问题
 */
export interface PerformanceIssue {
  type: 'critical' | 'high' | 'medium' | 'low';
  category: string;
  description: string;
  impact: 'runtime' | 'memory' | 'scalability';
  codeSnippet?: string;
}

/**
 * 性能建议
 */
export interface PerformanceSuggestion {
  priority: 'high' | 'medium' | 'low';
  category: string;
  description: string;
  codeExample?: string;
  expectedImprovement: string;
}

/**
 * 性能优化器
 */
export class PerformanceOptimizer {
  /**
   * 分析性能
   */
  analyzePerformance(
    code: string,
    language: LanguageSupport | string
  ): Promise<PerformanceReport> {
    const lang = typeof language === 'string'
      ? { name: language, extension: '', supported: true }
      : language;

    console.log(`开始分析${lang.name}性能...`);

    // 1. 计算指标
    const metrics = this.calculateMetrics(code, lang);

    // 2. 运行时评分
    const runtimeScore = this.calculateRuntimeScore(metrics);

    // 3. 内存评分
    const memoryScore = this.calculateMemoryScore(metrics, code);

    // 4. 效率评分
    const efficiencyScore = this.calculateEfficiencyScore(metrics, code);

    // 5. 可扩展性评分
    const scalabilityScore = this.calculateScalabilityScore(metrics, code);

    // 6. 综合评分
    const overallScore = this.calculateOverallScore([
      runtimeScore,
      memoryScore,
      efficiencyScore,
      scalabilityScore
    ]);

    // 7. 生成问题
    const issues = this.generateIssues(
      metrics,
      overallScore
    );

    // 8. 生成建议
    const suggestions = this.generateSuggestions(issues, overallScore);

    return {
      overallScore,
      runtimeScore,
      memoryScore,
      efficiencyScore,
      scalabilityScore,
      issues,
      suggestions,
      metrics
    };
  }

  /**
   * 计算性能指标
   */
  private calculateMetrics(
    code: string,
    language: LanguageSupport
  ): PerformanceMetrics {
    let loops = 0;
    let asyncOps = 0;
    let apiCalls = 0;
    let nestingDepth = 0;

    // 统计循环
    const loopPatterns = [
      /for\s*\(/g,
      /while\s*\(/g,
      /foreach\s+\w+\s+in/g,
      /map\s*\(/g,
      /filter\s*\(/g
    ];

    for (const pattern of loopPatterns) {
      const matches = code.match(pattern);
      if (matches) {
        loops += matches.length;
      }
    }

    // 统计异步操作
    const asyncPatterns = [
      /Promise\.all/g,
      /await\s+\w+\s*\(/g,
      /setTimeout/g,
      /setInterval/g,
      /fetch\s*\(/g,
      /axios\.get|axios\.post/g
    ];

    for (const pattern of asyncPatterns) {
      const matches = code.match(pattern);
      if (matches) {
        asyncOps += matches.length;
      }
    }

    // 统计API调用
    const apiPatterns = [
      /fetch\s*\(/g,
      /axios\.(get|post|put|delete)\s*\(/g,
      /db\.query\s*\(/g,
      /query\s*\(/g
    ];

    for (const pattern of apiPatterns) {
      const matches = code.match(pattern);
      if (matches) {
        apiCalls += matches.length;
      }
    }

    // 分析嵌套深度
    nestingDepth = this.analyzeNestingDepth(code);

    // 估算复杂度（简化版）
    const complexity = this.estimateComplexity(loops, apiCalls);

    // 估算运行时间（简化版）
    const estimatedRuntime = this.estimateRuntime(loops, asyncOps, apiCalls);

    // 估算内存使用（简化版）
    const estimatedMemory = this.estimateMemory(loops, apiCalls);

    return {
      estimatedRuntime,
      estimatedMemory,
      complexity,
      loops,
      asyncOps,
      apiCalls,
      nestingDepth
    };
  }

  /**
   * 分析嵌套深度
   */
  private analyzeNestingDepth(code: string): number {
    let maxDepth = 0;
    let currentDepth = 0;

    const indentRegex = /^[^\S]*[\{\(\[\n]/gm;

    for (const match of code.matchAll(indentRegex)) {
      currentDepth++;
      if (currentDepth > maxDepth) {
        maxDepth = currentDepth;
      }
    }

    return maxDepth;
  }

  /**
   * 估算复杂度
   */
  private estimateComplexity(loops: number, apiCalls: number): number {
    // 简单估算：每次循环增加复杂度，每次API调用增加复杂度
    return loops * 2 + apiCalls * 3 + 1;
  }

  /**
   * 估算运行时间
   */
  private estimateRuntime(loops: number, asyncOps: number, apiCalls: number): number {
    // 基础时间 + 循环时间 + 异步操作时间 + API调用时间
    const baseTime = 10; // ms
    const loopTime = loops * 1; // ms per loop
    const asyncTime = asyncOps * 50; // ms per async op
    const apiTime = apiCalls * 100; // ms per API call

    return baseTime + loopTime + asyncTime + apiTime;
  }

  /**
   * 估算内存使用
   */
  private estimateMemory(loops: number, apiCalls: number): number {
    // 基础内存 + 循环内存 + API调用内存
    const baseMemory = 10; // MB
    const loopMemory = loops * 0.5; // MB per loop
    const apiMemory = apiCalls * 2; // MB per API call

    return baseMemory + loopMemory + apiMemory;
  }

  /**
   * 计算运行时评分
   */
  private calculateRuntimeScore(metrics: PerformanceMetrics): number {
    let score = 100;

    // 复杂度影响
    if (metrics.complexity > 50) {
      score -= 20;
    } else if (metrics.complexity > 20) {
      score -= 10;
    }

    // 循环数量影响
    if (metrics.loops > 100) {
      score -= 15;
    } else if (metrics.loops > 50) {
      score -= 5;
    }

    // 异步操作数量影响
    if (metrics.asyncOps > 20) {
      score -= 10;
    }

    // API调用数量影响
    if (metrics.apiCalls > 10) {
      score -= 10;
    }

    return Math.max(0, Math.min(100, score));
  }

  /**
   * 计算内存评分
   */
  private calculateMemoryScore(metrics: PerformanceMetrics, code: string): number {
    let score = 100;

    // 检查内存泄漏风险
    if (this.detectMemoryLeaks(code)) {
      score -= 25;
    }

    // 循环内存使用
    if (metrics.loops > 50) {
      score -= 10;
    }

    // API调用内存
    if (metrics.apiCalls > 10) {
      score -= 10;
    }

    // 估算内存过高
    if (metrics.estimatedMemory > 100) {
      score -= 15;
    }

    return Math.max(0, Math.min(100, score));
  }

  /**
   * 检测内存泄漏
   */
  private detectMemoryLeaks(code: string): boolean {
    // 检查事件监听器未移除
    const hasEventListeners = /(addEventListener|attachEvent|on\w+=)/.test(code);

    // 检查闭包未清理
    const hasClosures = /\(\(\) => \{[\s\S]*?\}\)/.test(code);

    // 检查全局变量
    const hasGlobalVars = /\b(let|var|const)\s+\w+\s*=\s*\{[\s\S]*?\}/.test(code);

    return hasEventListeners && !code.includes('removeEventListener');
  }

  /**
   * 计算效率评分
   */
  private calculateEfficiencyScore(metrics: PerformanceMetrics, code: string): number {
    let score = 100;

    // 检查无效的循环
    if (this.detectInefficientLoops(code)) {
      score -= 20;
    }

    // 检查同步阻塞
    if (this.detectBlockingCalls(code)) {
      score -= 15;
    }

    // 检查重复计算
    if (this.detectRepeatedCalculations(code)) {
      score -= 10;
    }

    return Math.max(0, Math.min(100, score));
  }

  /**
   * 检测低效循环
   */
  private detectInefficientLoops(code: string): boolean {
    // 检测在循环内进行不必要的操作
    const patterns = [
      /for\s*\([^)]*\)\s*\{\s*if\s*\(.*\)\s*\{[\s\S]*?\}\s*\}/g,
      /while\s*\([^)]*\)\s*\{\s*if\s*\(.*\)\s*\{[\s\S]*?\}\s*\}/g
    ];

    for (const pattern of patterns) {
      if (pattern.test(code)) {
        return true;
      }
    }

    return false;
  }

  /**
   * 检测阻塞调用
   */
  private detectBlockingCalls(code: string): boolean {
    // 检测在循环内进行同步阻塞操作
    const patterns = [
      /for\s*\([^)]*\)\s*\{[\s\S]*?(console\.log|console\.error|document\.write|alert)\s*\(.*\)[\s\S]*?\}/g,
      /while\s*\([^)]*\)\s*\{[\s\S]*?(console\.log|console\.error|document\.write|alert)\s*\(.*\)[\s\S]*?\}/g
    ];

    for (const pattern of patterns) {
      if (pattern.test(code)) {
        return true;
      }
    }

    return false;
  }

  /**
   * 检测重复计算
   */
  private detectRepeatedCalculations(code: string): boolean {
    // 检测在循环内重复计算相同值
    const patterns = [
      /for\s*\([^)]*\)\s*\{[\s\S]*?Math\.sqrt\([^)]+\)\s*[\+\-\*\/]/g,
      /for\s*\([^)]*\)\s*\{[\s\S]*?Math\.pow\([^)]+\)\s*[\+\-\*\/]/g
    ];

    for (const pattern of patterns) {
      if (pattern.test(code)) {
        return true;
      }
    }

    return false;
  }

  /**
   * 计算可扩展性评分
   */
  private calculateScalabilityScore(metrics: PerformanceMetrics, code: string): number {
    let score = 100;

    // 嵌套深度影响可扩展性
    if (metrics.nestingDepth > 4) {
      score -= 15;
    } else if (metrics.nestingDepth > 3) {
      score -= 5;
    }

    // 复杂度影响可扩展性
    if (metrics.complexity > 30) {
      score -= 10;
    }

    // API调用数量影响可扩展性
    if (metrics.apiCalls > 5) {
      score -= 10;
    }

    return Math.max(0, Math.min(100, score));
  }

  /**
   * 计算综合评分
   */
  private calculateOverallScore(scores: number[]): number {
    const total = scores.reduce((sum, score) => sum + score, 0);
    return total / scores.length;
  }

  /**
   * 生成性能问题
   */
  private generateIssues(
    metrics: PerformanceMetrics,
    overallScore: number
  ): PerformanceIssue[] {
    const issues: PerformanceIssue[] = [];

    if (overallScore < 70) {
      issues.push({
        type: 'critical',
        category: 'runtime',
        description: '运行时性能严重不足'
      });
    }

    if (metrics.complexity > 30) {
      issues.push({
        type: 'high',
        category: 'complexity',
        description: `复杂度过高 (O(${metrics.complexity}))`
      });
    }

    if (metrics.apiCalls > 10) {
      issues.push({
        type: 'high',
        category: 'scalability',
        description: `API调用过多 (${metrics.apiCalls}次)`
      });
    }

    if (metrics.estimatedRuntime > 1000) {
      issues.push({
        type: 'critical',
        category: 'runtime',
        description: `预计运行时间过长 (${metrics.estimatedRuntime.toFixed(0)}ms)`
      });
    }

    return issues;
  }

  /**
   * 生成性能建议
   */
  private generateSuggestions(
    issues: PerformanceIssue[],
    overallScore: number
  ): PerformanceSuggestion[] {
    const suggestions: PerformanceSuggestion[] = [];

    if (overallScore < 80) {
      suggestions.push({
        priority: 'high',
        category: 'general',
        description: '整体性能需要优化',
        expectedImprovement: '提升20-30%'
      });
    }

    for (const issue of issues) {
      switch (issue.category) {
        case 'runtime':
          suggestions.push({
            priority: 'high',
            category: 'runtime',
            description: '优化运行时性能，减少计算时间',
            expectedImprovement: '提升30-50%'
          });
          break;

        case 'complexity':
          suggestions.push({
            priority: 'high',
            category: 'complexity',
            description: '降低代码复杂度，优化算法',
            expectedImprovement: '提升40-60%'
          });
          break;

        case 'scalability':
          suggestions.push({
            priority: 'medium',
            category: 'scalability',
            description: '提高代码可扩展性',
            expectedImprovement: '提升25-35%'
          });
          break;

        case 'memory':
          suggestions.push({
            priority: 'high',
            category: 'memory',
            description: '优化内存使用，减少内存泄漏',
            expectedImprovement: '减少30-50%内存使用'
          });
          break;
      }
    }

    return suggestions;
  }
}

// 导出默认实例
export default new PerformanceOptimizer();
