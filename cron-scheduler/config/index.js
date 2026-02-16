/**
 * Cron Scheduler Configuration
 */

module.exports = {
  // 配置文件路径
  config: {
    configPath: 'config/cron-config.json',
    tasksPath: 'config/scheduler-tasks.json'
  },

  // 默认任务配置
  defaultTasks: [
    {
      id: 'gateway-check',
      name: 'Gateway状态检查',
      cronExpression: '*/30 * * * *',
      timezone: 'Asia/Shanghai',
      enabled: true,
      priority: 5,
      script: 'cron-scheduler/jobs/gateway-check.js',
      description: '每30分钟检查Gateway服务运行状态、资源使用情况和连接状态'
    },
    {
      id: 'heartbeat',
      name: '系统健康检查',
      cronExpression: '*/30 * * * *',
      timezone: 'Asia/Shanghai',
      enabled: true,
      priority: 10,
      script: 'cron-scheduler/jobs/heartbeat.js',
      description: '每30分钟执行系统健康检查'
    },
    {
      id: 'daily-report',
      name: '每日报告生成',
      cronExpression: '0 4 * * *',
      timezone: 'Asia/Shanghai',
      enabled: true,
      priority: 15,
      script: 'cron-scheduler/jobs/daily-report.js',
      description: '每天凌晨4点生成每日报告'
    },
    {
      id: 'weekly-report',
      name: '每周报告生成',
      cronExpression: '0 0 * * 1',
      timezone: 'Asia/Shanghai',
      enabled: true,
      priority: 20,
      script: 'cron-scheduler/jobs/weekly-report.js',
      description: '每周一凌晨生成每周报告'
    }
  ],

  // 调度器配置
  scheduler: {
    timezone: 'Asia/Shanghai',
    maxRetries: 3,
    retryDelay: 5 * 60 * 1000, // 5分钟
    enableLogRotation: true,
    logRetentionDays: 7
  },

  // 任务状态保存配置
  taskStatus: {
    enabled: true,
    saveInterval: 5 * 60 * 1000, // 5分钟
    savePath: 'data/task-status.json'
  },

  // 日志配置
  logging: {
    level: 'info',
    format: 'json',
    maxFileSize: '10M',
    maxFiles: 5
  }
};
