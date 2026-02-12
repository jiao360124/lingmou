/**
 * 数据可视化面板
 * 系统性能监控、任务统计、技能使用热图
 */

/**
 * 监控指标
 */
export interface PerformanceMetrics {
  timestamp: Date;
  gatewayStatus: 'healthy' | 'degraded' | 'unhealthy';
  responseTime: number; // ms
  memoryUsage: number; // MB
  cpuUsage: number; // %
  activeTasks: number;
  totalTasks: number;
  errorRate: number;
  successRate: number;
}

/**
 * 任务统计
 */
export interface TaskStatistics {
  totalTasks: number;
  completedTasks: number;
  failedTasks: number;
  pendingTasks: number;
  runningTasks: number;
  avgExecutionTime: number;
  throughput: number; // tasks per second
  taskCompletionRate: number;
  avgWaitTime: number;
}

/**
 * 技能使用数据
 */
export interface SkillUsageData {
  skillName: string;
  totalCalls: number;
  avgResponseTime: number;
  successRate: number;
  lastUsed: Date;
  usageTrend: number[]; // 周趋势数据
}

/**
 * 系统状态
 */
export interface SystemStatus {
  uptime: number;
  startTime: Date;
  lastCheck: Date;
  metrics: PerformanceMetrics;
  taskStats: TaskStatistics;
  skillUsage: SkillUsageData[];
}

/**
 * 视图类型
 */
export enum DashboardView {
  OVERVIEW = 'overview',
  PERFORMANCE = 'performance',
  TASKS = 'tasks',
  SKILLS = 'skills',
  LOGS = 'logs'
}

/**
 * 可视化组件
 */
export interface VisualizationComponent {
  type: string;
  title: string;
  data: any;
  options?: any;
}

/**
 * 数据可视化面板
 */
export class DataVisualizationDashboard {
  private systemStatus: SystemStatus;
  private view: DashboardView;
  private components: VisualizationComponent[] = [];

  constructor() {
    this.systemStatus = this.initializeSystemStatus();
    this.view = DashboardView.OVERVIEW;
  }

  /**
   * 初始化系统状态
   */
  private initializeSystemStatus(): SystemStatus {
    return {
      uptime: 0,
      startTime: new Date(),
      lastCheck: new Date(),
      metrics: {
        timestamp: new Date(),
        gatewayStatus: 'healthy',
        responseTime: 50,
        memoryUsage: 200,
        cpuUsage: 30,
        activeTasks: 0,
        totalTasks: 0,
        errorRate: 0.01,
        successRate: 0.99
      },
      taskStats: {
        totalTasks: 0,
        completedTasks: 0,
        failedTasks: 0,
        pendingTasks: 0,
        runningTasks: 0,
        avgExecutionTime: 0,
        throughput: 0,
        taskCompletionRate: 0,
        avgWaitTime: 0
      },
      skillUsage: []
    };
  }

  /**
   * 更新系统状态
   */
  updateSystemStatus(metrics: Partial<PerformanceMetrics>, taskStats: Partial<TaskStatistics>, skillUsage: SkillUsageData[]): void {
    // 更新指标
    this.systemStatus.metrics = {
      ...this.systemStatus.metrics,
      ...metrics
    };

    // 更新任务统计
    this.systemStatus.taskStats = {
      ...this.systemStatus.taskStats,
      ...taskStats
    };

    // 更新技能使用数据
    this.systemStatus.skillUsage = skillUsage;

    // 更新时间戳
    this.systemStatus.lastCheck = new Date();

    // 更新运行时间
    const uptime = Date.now() - this.systemStatus.startTime.getTime();
    this.systemStatus.uptime = uptime;
  }

  /**
   * 切换视图
   */
  switchView(view: DashboardView): void {
    this.view = view;
    this.components = this.generateComponentsForView(view);
  }

  /**
   * 为视图生成组件
   */
  private generateComponentsForView(view: DashboardView): VisualizationComponent[] {
    switch (view) {
      case DashboardView.OVERVIEW:
        return [
          {
            type: 'card',
            title: '系统健康状态',
            data: this.getSystemHealthStatus()
          },
          {
            type: 'card',
            title: '任务统计',
            data: this.getTaskStatistics()
          },
          {
            type: 'card',
            title: '资源使用',
            data: this.getResourceUsage()
          },
          {
            type: 'card',
            title: '最近活动',
            data: this.getRecentActivity()
          }
        ];

      case DashboardView.PERFORMANCE:
        return [
          {
            type: 'line-chart',
            title: '响应时间趋势',
            data: this.getResponseTimeTrend()
          },
          {
            type: 'line-chart',
            title: '内存使用趋势',
            data: this.getMemoryUsageTrend()
          },
          {
            type: 'line-chart',
            title: 'CPU使用趋势',
            data: this.getCPUUsageTrend()
          },
          {
            type: 'bar-chart',
            title: '任务成功率',
            data: this.getSuccessRateData()
          }
        ];

      case DashboardView.TASKS:
        return [
          {
            type: 'gauge-chart',
            title: '任务完成率',
            data: this.getTaskCompletionRate()
          },
          {
            type: 'bar-chart',
            title: '任务执行时间',
            data: this.getExecutionTimeData()
          },
          {
            type: 'pie-chart',
            title: '任务类型分布',
            data: this.getTaskTypeDistribution()
          },
          {
            type: 'table',
            title: '最近任务',
            data: this.getRecentTasks()
          }
        ];

      case DashboardView.SKILLS:
        return [
          {
            type: 'bar-chart',
            title: '技能使用频率',
            data: this.getSkillUsageFrequency()
          },
          {
            type: 'line-chart',
            title: '技能响应时间',
            data: this.getSkillResponseTime()
          },
          {
            type: 'pie-chart',
            title: '技能成功率',
            data: this.getSkillSuccessRate()
          },
          {
            type: 'heatmap',
            title: '技能使用热图',
            data: this.getSkillUsageHeatmap()
          }
        ];

      case DashboardView.LOGS:
        return [
          {
            type: 'table',
            title: '系统日志',
            data: this.getSystemLogs()
          },
          {
            type: 'bar-chart',
            title: '错误类型分布',
            data: this.getErrorDistribution()
          },
          {
            type: 'line-chart',
            title: '错误率趋势',
            data: this.getErrorRateTrend()
          },
          {
            type: 'card',
            title: '系统摘要',
            data: this.getSystemSummary()
          }
        ];

      default:
        return [];
    }
  }

  /**
   * 获取系统健康状态
   */
  private getSystemHealthStatus(): any {
    return {
      status: this.systemStatus.metrics.gatewayStatus,
      uptime: this.formatUptime(this.systemStatus.uptime),
      lastCheck: this.systemStatus.lastCheck.toLocaleString(),
      healthScore: this.calculateHealthScore(),
      recommendations: this.getHealthRecommendations()
    };
  }

  /**
   * 获取任务统计
   */
  private getTaskStatistics(): any {
    return {
      totalTasks: this.systemStatus.taskStats.totalTasks,
      completedTasks: this.systemStatus.taskStats.completedTasks,
      failedTasks: this.systemStatus.taskStats.failedTasks,
      pendingTasks: this.systemStatus.taskStats.pendingTasks,
      runningTasks: this.systemStatus.taskStats.runningTasks,
      completionRate: `${((this.systemStatus.taskStats.taskCompletionRate) * 100).toFixed(1)}%`,
      throughput: `${this.systemStatus.taskStats.throughput.toFixed(2)} tasks/s`
    };
  }

  /**
   * 获取资源使用
   */
  private getResourceUsage(): any {
    return {
      memory: {
        used: `${this.systemStatus.metrics.memoryUsage.toFixed(1)} MB`,
        total: '1024 MB',
        percentage: `${((this.systemStatus.metrics.memoryUsage / 1024) * 100).toFixed(1)}%`
      },
      cpu: {
        usage: `${this.systemStatus.metrics.cpuUsage.toFixed(1)}%`,
        cores: '8 cores',
        status: this.systemStatus.metrics.cpuUsage < 50 ? '正常' : this.systemStatus.metrics.cpuUsage < 80 ? '警告' : '严重'
      }
    };
  }

  /**
   * 获取系统日志
   */
  private getSystemLogs(): any {
    // TODO: 实际获取系统日志
    return {
      logs: [
        { time: '14:00:00', level: 'info', message: '系统启动完成' },
        { time: '14:05:00', level: 'info', message: '定时任务执行成功' },
        { time: '14:10:00', level: 'warning', message: 'CPU使用率较高' }
      ]
    };
  }

  /**
   * 获取响应时间趋势
   */
  private getResponseTimeTrend(): any {
    // TODO: 实际获取趋势数据
    return {
      labels: ['10:00', '10:10', '10:20', '10:30', '10:40', '10:50', '11:00'],
      data: [45, 52, 48, 60, 55, 50, 48],
      unit: 'ms'
    };
  }

  /**
   * 获取内存使用趋势
   */
  private getMemoryUsageTrend(): any {
    // TODO: 实际获取趋势数据
    return {
      labels: ['10:00', '10:10', '10:20', '10:30', '10:40', '10:50', '11:00'],
      data: [180, 190, 195, 200, 205, 210, 200],
      unit: 'MB'
    };
  }

  /**
   * 获取CPU使用趋势
   */
  private getCPUUsageTrend(): any {
    // TODO: 实际获取趋势数据
    return {
      labels: ['10:00', '10:10', '10:20', '10:30', '10:40', '10:50', '11:00'],
      data: [25, 30, 35, 40, 38, 32, 30],
      unit: '%'
    };
  }

  /**
   * 获取成功率数据
   */
  private getSuccessRateData(): any {
    return {
      labels: ['过去1小时', '过去2小时', '过去3小时', '过去4小时', '过去5小时', '过去6小时'],
      data: [98.5, 97.8, 98.2, 98.9, 98.0, 98.5]
    };
  }

  /**
   * 获取任务完成率
   */
  private getTaskCompletionRate(): any {
    return {
      value: this.systemStatus.taskStats.taskCompletionRate,
      target: 0.95,
      status: this.systemStatus.taskStats.taskCompletionRate >= 0.95 ? '良好' : '需要改进'
    };
  }

  /**
   * 获取执行时间数据
   */
  private getExecutionTimeData(): any {
    // TODO: 实际获取数据
    return {
      labels: ['Task A', 'Task B', 'Task C', 'Task D', 'Task E'],
      data: [150, 200, 180, 220, 160],
      unit: 'ms'
    };
  }

  /**
   * 获取任务类型分布
   */
  private getTaskTypeDistribution(): any {
    return {
      labels: ['Unit Test', 'Integration Test', 'E2E Test', 'Regression Test'],
      data: [40, 30, 20, 10]
    };
  }

  /**
   * 获取技能使用频率
   */
  private getSkillUsageFrequency(): any {
    return {
      labels: this.systemStatus.skillUsage.map(s => s.skillName),
      data: this.systemStatus.skillUsage.map(s => s.totalCalls)
    };
  }

  /**
   * 获取技能响应时间
  */
  private getSkillResponseTime(): any {
    return {
      labels: this.systemStatus.skillUsage.map(s => s.skillName),
      data: this.systemStatus.skillUsage.map(s => s.avgResponseTime)
    };
  }

  /**
   * 获取技能成功率
   */
  private getSkillSuccessRate(): any {
    return {
      labels: this.systemStatus.skillUsage.map(s => s.skillName),
      data: this.systemStatus.skillUsage.map(s => s.successRate * 100)
    };
  }

  /**
   * 获取技能使用热图
  */
  private getSkillUsageHeatmap(): any {
    // TODO: 实际获取热图数据
    return {
      weeks: ['第1周', '第2周', '第3周', '第4周'],
      days: ['周一', '周二', '周三', '周四', '周五', '周六', '周日'],
      data: [
        [5, 8, 12, 7, 10, 3, 4],
        [6, 9, 11, 8, 9, 4, 5],
        [4, 7, 13, 6, 11, 2, 3],
        [5, 8, 12, 7, 10, 3, 4]
      ]
    };
  }

  /**
   * 获取系统摘要
  */
  private getSystemSummary(): any {
    return {
      uptime: this.formatUptime(this.systemStatus.uptime),
      status: this.systemStatus.metrics.gatewayStatus,
      healthScore: this.calculateHealthScore(),
      uptimeScore: this.systemStatus.taskStats.taskCompletionRate,
      uptimePercentage: `${(this.systemStatus.taskStats.taskCompletionRate * 100).toFixed(1)}%`
    };
  }

  /**
   * 获取最近任务
  */
  private getRecentTasks(): any {
    // TODO: 实际获取最近任务
    return {
      tasks: [
        { id: 'task-1', name: 'Data Processing', status: 'completed', duration: '120ms' },
        { id: 'task-2', name: 'API Call', status: 'completed', duration: '45ms' },
        { id: 'task-3', name: 'Database Query', status: 'pending', duration: '-' }
      ]
    };
  }

  /**
   * 获取错误分布
  */
  private getErrorDistribution(): any {
    return {
      labels: ['Network Error', 'Timeout', 'Validation Error', 'Dependency Error'],
      data: [40, 25, 20, 15]
    };
  }

  /**
   * 获取错误率趋势
  */
  private getErrorRateTrend(): any {
    return {
      labels: ['10:00', '10:10', '10:20', '10:30', '10:40', '10:50', '11:00'],
      data: [1.0, 0.8, 1.2, 0.9, 1.1, 1.0, 0.7]
    };
  }

  /**
   * 获取最近活动
  */
  private getRecentActivity(): any {
    return {
      activities: [
        { time: '14:00:00', event: '定时任务执行成功' },
        { time: '14:05:00', event: '新技能注册: Copilot' },
        { time: '14:10:00', event: '系统健康检查完成' }
      ]
    };
  }

  /**
   * 计算健康得分
  */
  private calculateHealthScore(): number {
    let score = 100;

    // 基于响应时间评分
    if (this.systemStatus.metrics.responseTime > 100) score -= 20;
    else if (this.systemStatus.metrics.responseTime > 50) score -= 10;

    // 基于错误率评分
    if (this.systemStatus.metrics.errorRate > 0.05) score -= 20;
    else if (this.systemStatus.metrics.errorRate > 0.01) score -= 10;

    // 基于CPU使用率评分
    if (this.systemStatus.metrics.cpuUsage > 80) score -= 20;
    else if (this.systemStatus.metrics.cpuUsage > 50) score -= 10;

    return Math.max(0, Math.min(100, score));
  }

  /**
   * 获取健康建议
  */
  private getHealthRecommendations(): string[] {
    const recommendations: string[] = [];

    if (this.systemStatus.metrics.responseTime > 100) {
      recommendations.push('响应时间较长，建议优化系统性能');
    }

    if (this.systemStatus.metrics.errorRate > 0.05) {
      recommendations.push('错误率较高，建议检查系统稳定性');
    }

    if (this.systemStatus.metrics.cpuUsage > 80) {
      recommendations.push('CPU使用率较高，建议优化资源分配');
    }

    if (this.systemStatus.taskStats.avgExecutionTime > 1000) {
      recommendations.push('平均执行时间较长，建议优化任务处理流程');
    }

    if (recommendations.length === 0) {
      recommendations.push('系统运行良好，继续保持！');
    }

    return recommendations;
  }

  /**
   * 格式化运行时间
  */
  private formatUptime(ms: number): string {
    const seconds = Math.floor(ms / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (days > 0) {
      return `${days}天 ${hours % 24}小时 ${minutes % 60}分钟`;
    } else if (hours > 0) {
      return `${hours}小时 ${minutes % 60}分钟`;
    } else if (minutes > 0) {
      return `${minutes}分钟 ${seconds % 60}秒`;
    } else {
      return `${seconds}秒`;
    }
  }

  /**
   * 获取当前组件
  */
  getComponents(): VisualizationComponent[] {
    return this.components;
  }

  /**
   * 获取系统状态
  */
  getSystemStatus(): SystemStatus {
    return this.systemStatus;
  }

  /**
   * 获取当前视图
  */
  getCurrentView(): DashboardView {
    return this.view;
  }
}

// 导出类型
export type {
  PerformanceMetrics,
  TaskStatistics,
  SkillUsageData,
  SystemStatus,
  TestType,
  TestStatus,
  TestCase,
  TestSuite,
  TestResult,
  TestCoverage,
  VisualizationComponent
};
