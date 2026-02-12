/**
 * 目标识别模块
 * 自动识别系统需要提升的领域
 */

export interface Goal {
  id: string;
  type: 'feature-enhancement' | 'performance-optimization' | 'bug-fix' | 'documentation' | 'architecture';
  description: string;
  priority: 'P0' | 'P1' | 'P2' | 'P3';
  targetSkill?: string;
  estimatedEffort: string; // 'small' | 'medium' | 'large' | 'very-large'
  urgency: 'critical' | 'high' | 'medium' | 'low';
}

export interface SkillStats {
  skillName: string;
  usageCount: number;
  lastUsed: Date;
  successRate: number;
  performanceScore: number;
}

export interface DocIntegrity {
  skillName: string;
  hasDocumentation: boolean;
  documentationQuality: number; // 0-1
  lastUpdated: Date;
  missingSections: string[];
}

export interface PerformanceMetrics {
  skillName: string;
  avgResponseTime: number; // ms
  memoryUsage: number; // MB
  cpuUsage: number; // %
  errorRate: number;
}

export class GoalIdentifier {
  /**
   * 识别系统需要提升的领域
   */
  async identifyGoals(
    skillStats: SkillStats[],
    docIntegrity: DocIntegrity[],
    performanceMetrics: PerformanceMetrics[]
  ): Promise<Goal[]> {
    const goals: Goal[] = [];

    // 1. 分析技能覆盖度
    const skillCoverageGoals = await this.analyzeSkillCoverage(skillStats);
    goals.push(...skillCoverageGoals);

    // 2. 分析文档完整性
    const docGoals = await this.analyzeDocIntegrity(docIntegrity);
    goals.push(...docGoals);

    // 3. 分析性能瓶颈
    const perfGoals = await this.analyzePerformanceBottlenecks(performanceMetrics);
    goals.push(...perfGoals);

    // 4. 排序优先级
    return this.sortByPriority(goals);
  }

  /**
   * 分析技能覆盖度
   */
  private async analyzeSkillCoverage(skillStats: SkillStats[]): Promise<Goal[]> {
    const goals: Goal[] = [];
    const totalSkills = skillStats.length;
    const activeSkills = skillStats.filter(s => s.usageCount > 0).length;

    // 识别使用频率低的技能
    for (const skill of skillStats) {
      if (skill.usageCount === 0) {
        goals.push({
          id: this.generateId(),
          type: 'feature-enhancement',
          description: `技能 ${skill.skillName} 未使用`,
          priority: 'P3',
          targetSkill: skill.skillName,
          estimatedEffort: 'medium',
          urgency: 'low'
        });
      } else if (skill.usageCount < 5) {
        goals.push({
          id: this.generateId(),
          type: 'feature-enhancement',
          description: `技能 ${skill.skillName} 使用频率低`,
          priority: 'P2',
          targetSkill: skill.skillName,
          estimatedEffort: 'small',
          urgency: 'low'
        });
      } else if (skill.successRate < 0.7) {
        goals.push({
          id: this.generateId(),
          type: 'bug-fix',
          description: `技能 ${skill.skillName} 成功率低（${Math.round(skill.successRate * 100)}%）`,
          priority: 'P1',
          targetSkill: skill.skillName,
          estimatedEffort: 'medium',
          urgency: 'medium'
        });
      }
    }

    return goals;
  }

  /**
   * 分析文档完整性
   */
  private async analyzeDocIntegrity(docIntegrity: DocIntegrity[]): Promise<Goal[]> {
    const goals: Goal[] = [];

    for (const doc of docIntegrity) {
      if (!doc.hasDocumentation) {
        goals.push({
          id: this.generateId(),
          type: 'documentation',
          description: `技能 ${doc.skillName} 缺少文档`,
          priority: 'P1',
          targetSkill: doc.skillName,
          estimatedEffort: 'small',
          urgency: 'medium'
        });
      } else if (doc.documentationQuality < 0.6) {
        goals.push({
          id: this.generateId(),
          type: 'documentation',
          description: `技能 ${doc.skillName} 文档质量低`,
          priority: 'P2',
          targetSkill: doc.skillName,
          estimatedEffort: 'medium',
          urgency: 'medium'
        });
      } else if (doc.missingSections.length > 0) {
        goals.push({
          id: this.generateId(),
          type: 'documentation',
          description: `技能 ${doc.skillName} 缺少文档章节：${doc.missingSections.join(', ')}`,
          priority: 'P2',
          targetSkill: doc.skillName,
          estimatedEffort: 'medium',
          urgency: 'medium'
        });
      }
    }

    return goals;
  }

  /**
   * 分析性能瓶颈
   */
  private async analyzePerformanceBottlenecks(performanceMetrics: PerformanceMetrics[]): Promise<Goal[]> {
    const goals: Goal[] = [];

    for (const perf of performanceMetrics) {
      // 响应时间过长
      if (perf.avgResponseTime > 500) {
        goals.push({
          id: this.generateId(),
          type: 'performance-optimization',
          description: `技能 ${perf.skillName} 响应时间过长（${perf.avgResponseTime}ms）`,
          priority: 'P2',
          targetSkill: perf.skillName,
          estimatedEffort: 'medium',
          urgency: 'medium'
        });
      }

      // 内存使用过高
      if (perf.memoryUsage > 500) {
        goals.push({
          id: this.generateId(),
          type: 'performance-optimization',
          description: `技能 ${perf.skillName} 内存使用过高（${perf.memoryUsage}MB）`,
          priority: 'P2',
          targetSkill: perf.skillName,
          estimatedEffort: 'medium',
          urgency: 'medium'
        });
      }

      // CPU使用过高
      if (perf.cpuUsage > 80) {
        goals.push({
          id: this.generateId(),
          type: 'performance-optimization',
          description: `技能 ${perf.skillName} CPU使用过高（${perf.cpuUsage}%）`,
          priority: 'P2',
          targetSkill: perf.skillName,
          estimatedEffort: 'medium',
          urgency: 'medium'
        });
      }

      // 错误率高
      if (perf.errorRate > 0.1) {
        goals.push({
          id: this.generateId(),
          type: 'bug-fix',
          description: `技能 ${perf.skillName} 错误率高（${Math.round(perf.errorRate * 100)}%）`,
          priority: 'P0',
          targetSkill: perf.skillName,
          estimatedEffort: 'large',
          urgency: 'critical'
        });
      }
    }

    return goals;
  }

  /**
   * 按优先级排序
   */
  private sortByPriority(goals: Goal[]): Goal[] {
    const priorityOrder = { 'P0': 0, 'P1': 1, 'P2': 2, 'P3': 3 };
    return goals.sort((a, b) => {
      const priorityDiff = priorityOrder[a.priority] - priorityOrder[b.priority];
      if (priorityDiff !== 0) return priorityDiff;

      // 优先级相同，按紧急程度排序
      const urgencyOrder = { 'critical': 0, 'high': 1, 'medium': 2, 'low': 3 };
      return urgencyOrder[a.urgency] - urgencyOrder[b.urgency];
    });
  }

  /**
   * 生成唯一ID
   */
  private generateId(): string {
    return `goal-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }
}
