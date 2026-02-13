/**
 * Copilot - 代码质量评分系统
 * 分析代码质量并生成评分报告
 */

import { LanguageSupport } from './types';

/**
 * 代码质量报告
 */
export interface QualityReport {
  overallScore: number; // 0-100
  readabilityScore: number;
  complexityScore: number;
  maintainabilityScore: number;
  bestPracticesScore: number;
  performanceScore: number;

  issues: QualityIssue[];
  suggestions: QualitySuggestion[];
  metrics: CodeMetrics;
}

/**
 * 代码指标
 */
export interface CodeMetrics {
  lineCount: number;
  functionCount: number;
  classCount: number;
  commentCount: number;
  blankLineCount: number;
  averageLineLength: number;
  maxLineLength: number;
}

/**
 * 质量问题
 */
export interface QualityIssue {
  type: 'warning' | 'error' | 'info';
  severity: 'low' | 'medium' | 'high';
  message: string;
  line: number;
  codeSnippet?: string;
}

/**
 * 质量建议
 */
export interface QualitySuggestion {
  category: string;
  priority: 'high' | 'medium' | 'low';
  message: string;
  codeExample?: string;
}

/**
 * 代码质量评分器
 */
export class CodeQualityScorer {
  /**
   * 分析代码质量
   */
  async analyzeCode(
    code: string,
    language: LanguageSupport | string
  ): Promise<QualityReport> {
    const lang = typeof language === 'string'
      ? { name: language, extension: '', supported: true }
      : language;

    console.log(`开始分析${lang.name}代码质量...`);

    // 1. 计算指标
    const metrics = this.calculateMetrics(code);

    // 2. 读取性评分
    const readabilityScore = this.calculateReadabilityScore(code, metrics);

    // 3. 复杂度评分
    const complexityScore = this.calculateComplexityScore(code, metrics);

    // 4. 可维护性评分
    const maintainabilityScore = this.calculateMaintainabilityScore(code, metrics);

    // 5. 最佳实践评分
    const bestPracticesScore = this.calculateBestPracticesScore(code, lang);

    // 6. 性能评分
    const performanceScore = this.calculatePerformanceScore(code, lang);

    // 7. 综合评分
    const overallScore = this.calculateOverallScore([
      readabilityScore,
      complexityScore,
      maintainabilityScore,
      bestPracticesScore,
      performanceScore
    ]);

    // 8. 生成问题列表
    const issues = this.generateIssues(
      code,
      readabilityScore,
      complexityScore,
      maintainabilityScore,
      bestPracticesScore
    );

    // 9. 生成建议
    const suggestions = this.generateSuggestions(
      issues,
      overallScore
    );

    return {
      overallScore,
      readabilityScore,
      complexityScore,
      maintainabilityScore,
      bestPracticesScore,
      performanceScore,
      issues,
      suggestions,
      metrics
    };
  }

  /**
   * 计算代码指标
   */
  private calculateMetrics(code: string): CodeMetrics {
    const lines = code.split('\n');
    let functionCount = 0;
    let classCount = 0;
    let commentCount = 0;
    let blankLineCount = 0;
    let totalLineLength = 0;
    let maxLineLength = 0;

    const functionRegex = /\b(function|const|let|var|class|interface|type)\s+\w+\s*\(/g;
    const classRegex = /\b(class|interface|type)\s+\w+/g;
    const commentRegex = /(\/\/.*|\/\*[\s\S]*?\*\/|#[^\n]*)/g;

    // 统计函数
    let match;
    while ((match = functionRegex.exec(code)) !== null) {
      functionCount++;
    }

    // 统计类
    match = null;
    while ((match = classRegex.exec(code)) !== null) {
      classCount++;
    }

    // 统计注释
    const comments = code.match(commentRegex);
    if (comments) {
      commentCount = comments.length;
    }

    // 统计空行
    blankLineCount = lines.filter(line => line.trim() === '').length;

    // 统计行长度
    for (const line of lines) {
      const length = line.length;
      totalLineLength += length;
      if (length > maxLineLength) {
        maxLineLength = length;
      }
    }

    return {
      lineCount: lines.length,
      functionCount,
      classCount,
      commentCount,
      blankLineCount,
      averageLineLength: lines.length > 0 ? totalLineLength / lines.length : 0,
      maxLineLength
    };
  }

  /**
   * 计算可读性评分
   */
  private calculateReadabilityScore(
    code: string,
    metrics: CodeMetrics
  ): number {
    let score = 100;
    const issues: QualityIssue[] = [];

    // 检查最大行长度
    if (metrics.maxLineLength > 120) {
      const penalty = Math.min((metrics.maxLineLength - 120) * 0.5, 30);
      score -= penalty;
      issues.push({
        type: 'warning',
        severity: 'medium',
        message: `最大行长度过长 (${metrics.maxLineLength}字符)`,
        line: this.findLineNumber(code, metrics.maxLineLength)
      });
    } else if (metrics.maxLineLength > 100) {
      score -= 10;
    }

    // 检查平均行长度
    if (metrics.averageLineLength > 80) {
      score -= 5;
    }

    // 检查空行比例
    const blankLineRatio = metrics.blankLineCount / metrics.lineCount;
    if (blankLineRatio > 0.3) {
      score -= 5;
    }

    return Math.max(0, Math.min(100, score));
  }

  /**
   * 计算复杂度评分
   */
  private calculateComplexityScore(
    code: string,
    metrics: CodeMetrics
  ): number {
    let score = 100;
    const issues: QualityIssue[] = [];

    // 基于函数数量估算复杂度
    const complexityFactor = Math.min(metrics.functionCount / 20, 3);
    score -= complexityFactor * 10;

    // 检查深层嵌套
    const nestedDepth = this.analyzeNestingDepth(code);
    if (nestedDepth > 4) {
      score -= (nestedDepth - 4) * 5;
      issues.push({
        type: 'warning',
        severity: 'high',
        message: `过深的嵌套层级 (${nestedDepth}层)`,
        codeSnippet: this.findDeepNestingExample(code)
      });
    }

    return Math.max(0, Math.min(100, score));
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
   * 计算可维护性评分
   */
  private calculateMaintainabilityScore(
    code: string,
    metrics: CodeMetrics
  ): number {
    let score = 100;

    // 检查注释比例
    const commentRatio = metrics.commentCount / metrics.lineCount;
    if (commentRatio < 0.1) {
      score -= 20;
    } else if (commentRatio < 0.2) {
      score -= 10;
    }

    // 检查函数数量
    if (metrics.functionCount > 50) {
      score -= 15;
    } else if (metrics.functionCount > 30) {
      score -= 5;
    }

    // 检查类数量
    if (metrics.classCount > 20) {
      score -= 10;
    }

    return Math.max(0, Math.min(100, score));
  }

  /**
   * 计算最佳实践评分
   */
  private calculateBestPracticesScore(
    code: string,
    language: LanguageSupport
  ): number {
    let score = 100;
    const issues: QualityIssue[] = [];

    // 检查错误处理
    const errorHandlingPatterns = {
      typescript: /try\s*\{[\s\S]*?\}(\s*catch\s*\(\w+\s*\)|$)/g,
      javascript: /try\s*\{[\s\S]*?\}(\s*catch\s*\(\w+\s*\)|$)/g,
      python: /try:\s*\n[\s\S]*?(except\s+\w+\s*:|$)/g
    };

    const hasErrorHandling = this.checkErrorHandling(code, language.name);
    if (!hasErrorHandling) {
      score -= 25;
      issues.push({
        type: 'error',
        severity: 'high',
        message: '缺少错误处理'
      });
    }

    // 检查console.log
    if (code.includes('console.log')) {
      score -= 10;
      issues.push({
        type: 'warning',
        severity: 'low',
        message: '包含console.log（调试代码）',
        codeSnippet: 'console.log'
      });
    }

    // 检查魔法数字
    if (/\b\d{4,}\b/.test(code)) {
      score -= 15;
      issues.push({
        type: 'warning',
        severity: 'medium',
        message: '可能存在魔法数字'
      });
    }

    return Math.max(0, Math.min(100, score));
  }

  /**
   * 检查错误处理
   */
  private checkErrorHandling(code: string, language: string): boolean {
    if (language === 'typescript' || language === 'javascript') {
      // 检查try-catch
      return /try\s*\{[\s\S]*?\}(\s*catch\s*\(\w+\s*\)|$)/.test(code);
    } else if (language === 'python') {
      // 检查try-except
      return /try:\s*\n[\s\S]*?(except\s+\w+\s*:|$)/.test(code);
    } else {
      // 其他语言假设有错误处理
      return true;
    }
  }

  /**
   * 计算性能评分
   */
  private calculatePerformanceScore(
    code: string,
    language: LanguageSupport
  ): number {
    let score = 100;
    const issues: QualityIssue[] = [];

    // 检查同步阻塞调用
    if (language === 'typescript' || language === 'javascript') {
      if (/new\s+Promise\(|async\s+function/.test(code)) {
        // 如果使用Promise但没有await，性能问题
        if (/\)\s*;\s*$/m.test(code) && code.includes('Promise') && !code.includes('await')) {
          score -= 20;
          issues.push({
            type: 'warning',
            severity: 'medium',
            message: 'Promise未使用await，可能导致性能问题'
          });
        }
      }
    }

    // 检查内存泄漏风险（TODO: 更复杂的分析）
    if (code.includes('setInterval') || code.includes('setTimeout')) {
      score -= 5;
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
   * 生成质量问题
   */
  private generateIssues(
    code: string,
    readabilityScore: number,
    complexityScore: number,
    maintainabilityScore: number,
    bestPracticesScore: number
  ): QualityIssue[] {
    const issues: QualityIssue[] = [];

    // 读取性问题
    if (readabilityScore < 70) {
      issues.push({
        type: 'warning',
        severity: 'medium',
        message: '代码可读性较差'
      });
    }

    // 复杂度问题
    if (complexityScore < 70) {
      issues.push({
        type: 'warning',
        severity: 'medium',
        message: '代码复杂度过高'
      });
    }

    // 可维护性问题
    if (maintainabilityScore < 70) {
      issues.push({
        type: 'warning',
        severity: 'medium',
        message: '代码可维护性较差'
      });
    }

    // 最佳实践问题
    if (bestPracticesScore < 70) {
      issues.push({
        type: 'error',
        severity: 'high',
        message: '违反最佳实践'
      });
    }

    return issues;
  }

  /**
   * 生成改进建议
   */
  private generateSuggestions(
    issues: QualityIssue[],
    overallScore: number
  ): QualitySuggestion[] {
    const suggestions: QualitySuggestion[] = [];

    if (overallScore < 70) {
      suggestions.push({
        category: 'readability',
        priority: 'high',
        message: '建议：优化代码结构，提高可读性'
      });
    }

    if (overallScore < 80) {
      suggestions.push({
        category: 'complexity',
        priority: 'high',
        message: '建议：降低代码复杂度，简化逻辑'
      });
    }

    // 为每个问题生成建议
    for (const issue of issues) {
      if (issue.severity === 'high') {
        suggestions.push({
          category: 'best-practices',
          priority: 'high',
          message: issue.message
        });
      } else if (issue.severity === 'medium') {
        suggestions.push({
          category: 'readability',
          priority: 'medium',
          message: issue.message
        });
      }
    }

    return suggestions;
  }

  /**
   * 查找行号
   */
  private findLineNumber(code: string, maxLength: number): number {
    const lines = code.split('\n');
    for (let i = 0; i < lines.length; i++) {
      if (lines[i].length >= maxLength) {
        return i + 1;
      }
    }
    return 1;
  }

  /**
   * 查找深层嵌套示例
   */
  private findDeepNestingExample(code: string): string | undefined {
    const lines = code.split('\n');
    for (let i = 0; i < lines.length; i++) {
      if (lines[i].includes('if') || lines[i].includes('for') || lines[i].includes('while')) {
        return lines[i].trim().substring(0, 50) + '...';
      }
    }
    return undefined;
  }
}

// 导出默认实例
export default new CodeQualityScorer();
