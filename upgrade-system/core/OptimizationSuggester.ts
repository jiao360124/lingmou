/**
 * 优化建议生成模块
 * 基于评估结果生成改进建议
 */

export interface Suggestion {
  id: string;
  category: 'feature-enhancement' | 'performance-optimization' | 'bug-fix' | 'documentation' | 'architecture';
  priority: 'P0' | 'P1' | 'P2' | 'P3';
  dimension: string;
  description: string;
  details?: string;
  estimatedEffort: 'small' | 'medium' | 'large' | 'very-large';
  urgency: 'critical' | 'high' | 'medium' | 'low';
  implementationPath?: string[];
  estimatedTime?: string;
}

export interface OptimizationReport {
  skillName: string;
  timestamp: Date;
  totalSuggestions: number;
  byCategory: Record<string, number>;
  byPriority: Record<string, number>;
  byDimension: Record<string, number>;
  suggestions: Suggestion[];
  summary: string;
}

export class OptimizationSuggester {
  /**
   * 生成优化建议
   */
  async generateSuggestions(report: CapabilityReport): Promise<Suggestion[]> {
    const suggestions: Suggestion[] = [];

    // 1. 基于低分维度生成建议
    const lowScoringDimensions = this.findLowScoringDimensions(report);
    for (const dim of lowScoringDimensions) {
      const dimSuggestions = await this.generateDimensionSuggestions(dim, report);
      suggestions.push(...dimSuggestions);
    }

    // 2. 基于能力评估的其他分析生成建议
    const additionalSuggestions = await this.generateAdditionalSuggestions(report);
    suggestions.push(...additionalSuggestions);

    // 3. 排序和建议分组
    return this.sortAndGroupSuggestions(suggestions);
  }

  /**
   * 查找低分维度
   */
  private findLowScoringDimensions(report: CapabilityReport): EvaluationDimension[] {
    return this.dimensions.filter(dimension => {
      const score = report.dimensions[dimension.name]?.score || 0;
      return score < 0.6; // 低于60分
    });
  }

  /**
   * 为低分维度生成建议
   */
  private async generateDimensionSuggestions(
    dimension: EvaluationDimension,
    report: CapabilityReport
  ): Promise<Suggestion[]> {
    const suggestions: Suggestion[] = [];
    const dimensionScore = report.dimensions[dimension.name]?.score || 0;

    // 根据分数生成不同层级的建议
    if (dimensionScore < 0.4) {
      // 危急：需要立即解决
      suggestions.push({
        id: this.generateId(),
        category: this.getCategoryFromDimension(dimension.name),
        priority: 'P0',
        dimension: dimension.name,
        description: `在${dimension.name}维度得分极低（${Math.round(dimensionScore * 100)}%），严重影响整体表现，建议优先改进`,
        estimatedEffort: 'large',
        urgency: 'critical'
      });
    } else if (dimensionScore < 0.6) {
      // 重要：需要改进
      suggestions.push({
        id: this.generateId(),
        category: this.getCategoryFromDimension(dimension.name),
        priority: 'P1',
        dimension: dimension.name,
        description: `在${dimension.name}维度得分偏低（${Math.round(dimensionScore * 100)}%），建议重点改进`,
        estimatedEffort: dimensionScore < 0.5 ? 'large' : 'medium',
        urgency: 'high'
      });
    } else if (dimensionScore < 0.8) {
      // 改进：可以优化
      suggestions.push({
        id: this.generateId(),
        category: this.getCategoryFromDimension(dimension.name),
        priority: 'P2',
        dimension: dimension.name,
        description: `在${dimension.name}维度表现良好但可进一步优化，当前得分${Math.round(dimensionScore * 100)}%`,
        estimatedEffort: 'medium',
        urgency: 'medium'
      });
    } else {
      // 优秀：无需改进
      return [];
    }

    // 为每个维度生成具体建议
    for (const criterion of dimension.criteria) {
      const criteriaScore = this.getCriteriaScore(report, dimension.name, criterion.name);
      if (criteriaScore < 0.5) {
        suggestions.push({
          id: this.generateId(),
          category: this.getCategoryFromDimension(dimension.name),
          priority: dimensionScore < 0.6 ? 'P1' : 'P2',
          dimension: dimension.name,
          description: `${dimension.name} - ${criterion.name}表现不佳（${Math.round(criteriaScore * 100)}%）`,
          details: criterion.description,
          estimatedEffort: 'medium',
          urgency: dimensionScore < 0.6 ? 'high' : 'medium'
        });
      }
    }

    return suggestions;
  }

  /**
   * 生成额外建议
   */
  private async generateAdditionalSuggestions(report: CapabilityReport): Promise<Suggestion[]> {
    const suggestions: Suggestion[] = [];

    // 检查总体得分
    if (report.totalScore < 0.6) {
      suggestions.push({
        id: this.generateId(),
        category: 'architecture',
        priority: 'P0',
        dimension: 'overall',
        description: '整体能力得分较低，建议进行全面评估和优化',
        estimatedEffort: 'very-large',
        urgency: 'critical'
      });
    }

    // 检查是否有严重问题
    const criticalProblems = this.findCriticalProblems(report);
    if (criticalProblems.length > 0) {
      suggestions.push({
        id: this.generateId(),
        category: 'bug-fix',
        priority: 'P0',
        dimension: 'overall',
        description: `发现${criticalProblems.length}个严重问题，需要优先处理`,
        details: criticalProblems.join('; '),
        estimatedEffort: 'large',
        urgency: 'critical'
      });
    }

    return suggestions;
  }

  /**
   * 获取特定评估标准的得分
   */
  private getCriteriaScore(
    report: CapabilityReport,
    dimensionName: string,
    criterionName: string
  ): number {
    const dimension = report.dimensions[dimensionName];
    if (!dimension) return 0;

    // TODO: 实现从dimension.criteriaScores中获取具体得分
    // 目前返回维度平均分
    return dimension.score * 100;
  }

  /**
   * 查找严重问题
   */
  private findCriticalProblems(report: CapabilityReport): string[] {
    const problems: string[] = [];

    for (const [name, score] of Object.entries(report.dimensions)) {
      if (score.score < 0.3) {
        problems.push(`${name}维度得分极低（${Math.round(score.score * 100)}%）`);
      }
    }

    return problems;
  }

  /**
   * 按类别分组
   */
  private sortAndGroupSuggestions(suggestions: Suggestion[]): Suggestion[] {
    // 按优先级排序
    const priorityOrder = { 'P0': 0, 'P1': 1, 'P2': 2, 'P3': 3 };
    const urgencyOrder = { 'critical': 0, 'high': 1, 'medium': 2, 'low': 3 };

    return suggestions.sort((a, b) => {
      const priorityDiff = priorityOrder[a.priority] - priorityOrder[b.priority];
      if (priorityDiff !== 0) return priorityDiff;

      const urgencyDiff = urgencyOrder[a.urgency] - urgencyOrder[b.urgency];
      if (urgencyDiff !== 0) return urgencyDiff;

      return a.category.localeCompare(b.category);
    });
  }

  /**
   * 生成报告
   */
  async generateReport(
    skillName: string,
    suggestions: Suggestion[]
  ): Promise<OptimizationReport> {
    return {
      skillName,
      timestamp: new Date(),
      totalSuggestions: suggestions.length,
      byCategory: this.groupByCategory(suggestions),
      byPriority: this.groupByPriority(suggestions),
      byDimension: this.groupByDimension(suggestions),
      suggestions,
      summary: this.generateSummary(suggestions)
    };
  }

  /**
   * 按类别分组
   */
  private groupByCategory(suggestions: Suggestion[]): Record<string, number> {
    const groups: Record<string, number> = {};

    for (const suggestion of suggestions) {
      groups[suggestion.category] = (groups[suggestion.category] || 0) + 1;
    }

    return groups;
  }

  /**
   * 按优先级分组
   */
  private groupByPriority(suggestions: Suggestion[]): Record<string, number> {
    const groups: Record<string, number> = {};

    for (const suggestion of suggestions) {
      groups[suggestion.priority] = (groups[suggestion.priority] || 0) + 1;
    }

    return groups;
  }

  /**
   * 按维度分组
   */
  private groupByDimension(suggestions: Suggestion[]): Record<string, number> {
    const groups: Record<string, number> = {};

    for (const suggestion of suggestions) {
      groups[suggestion.dimension] = (groups[suggestion.dimension] || 0) + 1;
    }

    return groups;
  }

  /**
   * 生成总结
   */
  private generateSummary(suggestions: Suggestion[]): string {
    if (suggestions.length === 0) {
      return '当前无需优化建议，系统表现良好！';
    }

    const p0 = suggestions.filter(s => s.priority === 'P0').length;
    const p1 = suggestions.filter(s => s.priority === 'P1').length;
    const p2 = suggestions.filter(s => s.priority === 'P2').length;

    let summary = `共${suggestions.length}条优化建议：`;
    summary += ` ${p0}条P0紧急，${p1}条P1重要，${p2}条P2改进`;

    if (p0 > 0) {
      summary += '；请优先处理P0紧急问题';
    }

    return summary;
  }

  /**
   * 从维度名称获取建议类别
   */
  private getCategoryFromDimension(dimensionName: string): Suggestion['category'] {
    if (['功能完整性', '性能表现', '可靠性', '可扩展性', '安全性'].includes(dimensionName)) {
      return 'performance-optimization';
    }

    if (['易用性'].includes(dimensionName)) {
      return 'feature-enhancement';
    }

    if (['社区反馈度', '创新性'].includes(dimensionName)) {
      return 'architecture';
    }

    return 'feature-enhancement';
  }

  /**
   * 生成唯一ID
   */
  private generateId(): string {
    return `suggestion-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }

  private dimensions: EvaluationDimension[] = [
    {
      name: '功能完整性',
      weight: 0.25,
      description: '评估技能功能覆盖度和边界情况处理',
      criteria: []
    },
    {
      name: '性能表现',
      weight: 0.20,
      description: '评估执行速度和资源使用效率',
      criteria: []
    },
    {
      name: '可靠性',
      weight: 0.15,
      description: '评估错误率、恢复能力和稳定性',
      criteria: []
    },
    {
      name: '可扩展性',
      weight: 0.15,
      description: '评估代码结构和模块化程度',
      criteria: []
    },
    {
      name: '安全性',
      weight: 0.15,
      description: '评估漏洞和安全实践',
      criteria: []
    },
    {
      name: '易用性',
      weight: 0.10,
      description: '评估文档质量、接口设计和学习曲线',
      criteria: []
    }
  ];
}
