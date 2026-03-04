# Cron Scheduler

[![npm version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://www.npmjs.com/package/cron-scheduler)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

高性能的基于 Cron 表达式的定时任务管理系统，支持任务优先级、重试机制、状态监控等功能。

A high-performance periodic task management system based on Cron expressions, supporting task prioritization, retry mechanism, and status monitoring.

## ✨ 特性 (Features)

- 🕐 **精确定时**：基于 Cron 表达式的精确时间控制
- 🎯 **任务优先级**：支持 1-20 级优先级管理
- 🔄 **自动重试**：任务失败自动重试机制
- 📊 **状态监控**：实时任务状态跟踪和监控
- 📝 **日志记录**：完整的执行日志和错误追踪
- 🚀 **高性能**：轻量级设计，高效执行
- 🛡️ **安全可靠**：完善的错误处理和恢复机制

## 📦 安装 (Installation)

```bash
# 进入项目目录
cd cron-scheduler

# 安装依赖
npm install
```

## 🚀 快速开始 (Quick Start)

```bash
# 启动调度器
npm start

# 运行测试
npm test

# 任务管理
npm run schedule
```

## 📖 使用文档 (Documentation)

详细文档请查看 [CRON-CONFIG.md](./CRON-CONFIG.md)

For detailed documentation, please refer to [CRON-CONFIG.md](./CRON-CONFIG.md)

## ⚙️ 配置 (Configuration)

### 基本配置 (Basic Configuration)

编辑 `config/cron-config.json`：

Edit `config/cron-config.json`:

```json
{
  "version": "1.0.0",
  "timezone": "Asia/Shanghai",
  "maxRetries": 3,
  "tasks": [
    {
      "id": "daily-report",
      "name": "每日报告生成",
      "cronExpression": "0 4 * * *",
      "timezone": "Asia/Shanghai",
      "enabled": true,
      "priority": 10,
      "script": "scripts/generate-daily-report.js",
      "description": "每天凌晨4点生成每日报告"
    }
  ]
}
```

### Cron 表达式 (Cron Expressions)

| 表达式 (Expression) | 说明 (Description) |
|---------------------|-------------------|
| `0 4 * * *` | 每天 4:00 |
| `0 3 * * *` | 每天 3:00 |
| `0 0 * * 0` | 每周日 0:00 |
| `0 0 * * 1` | 每周一 0:00 |
| `*/30 * * * *` | 每30分钟 |

## 🎯 默认任务 (Default Tasks)

| 任务 (Task) | 功能 (Function) | 频率 (Frequency) |
|-------------|-----------------|------------------|
| daily-report | 生成每日报告 | 每天 4:00 |
| weekly-report | 生成每周报告 | 每周一 0:00 |
| daily-metrics-reset | 重置每日指标 | 每天 3:00 |
| weekly-cleanup | 清理旧数据 | 每周日 0:00 |
| heartbeat-monitor | 心跳监控 | 每30分钟 |

## 🛠️ API (API Reference)

### CronScheduler 类 (CronScheduler Class)

```javascript
const { CronScheduler, scheduler } = require('./index.js');

// 创建实例
const scheduler = new CronScheduler();

// 初始化
await scheduler.initialize();

// 启用/禁用任务
await scheduler.toggleTask('daily-report', true);

// 查看状态
const status = scheduler.getTaskStatus('daily-report');
const allStatus = scheduler.getAllTaskStatus();
const info = scheduler.getSchedulerInfo();
```

### 方法 (Methods)

| 方法 (Method) | 参数 (Parameters) | 返回值 (Returns) | 说明 (Description) |
|--------------|-------------------|------------------|-------------------|
| initialize() | - | Promise | 初始化调度器 |
| startScheduler() | - | void | 启动调度器 |
| stopScheduler() | - | void | 停止调度器 |
| toggleTask(taskId, enabled) | string, boolean | Promise | 启用/禁用任务 |
| getTaskStatus(taskId) | string | object | 获取任务状态 |
| getAllTaskStatus() | - | object | 获取所有任务状态 |
| getSchedulerInfo() | - | object | 获取调度器信息 |

## 📁 项目结构 (Project Structure)

```
cron-scheduler/
├── config/
│   ├── cron-config.json        # 主配置文件
│   └── scheduler-tasks.json    # 任务定义
├── scripts/
│   ├── generate-daily-report.js   # 每日报告生成脚本
│   ├── generate-weekly-report.js  # 每周报告生成脚本
│   ├── reset-daily-metrics.js     # 每日指标重置脚本
│   ├── weekly-data-cleanup.js     # 数据清理脚本
│   └── heartbeat-monitor.js       # 心跳监控脚本
├── logs/                        # 日志目录
├── data/                        # 数据目录
├── reports/                     # 报告输出目录
├── index.js                     # 主入口文件
├── test-cron-scheduler.js       # 测试文件
├── schedule-manager.js          # 任务管理工具
├── package.json                 # 项目配置
├── CRON-CONFIG.md               # 详细配置文档
└── README.md                    # 项目说明
```

## 🧪 测试 (Testing)

```bash
# 运行测试套件
npm test

# 测试覆盖
✓ 配置文件加载
✓ 任务脚本存在性检查
✓ Cron 表达式验证
✓ 任务执行测试
✓ 状态跟踪机制
✓ 输出文件生成
```

## 🔧 维护 (Maintenance)

### 查看任务状态 (View Task Status)

```bash
# 查看任务状态文件
cat data/task-status.json

# 查看最近日志
tail -f logs/cron-scheduler.log
```

### 日志管理 (Log Management)

```bash
# 查看最后100行日志
tail -n 100 logs/cron-scheduler.log

# 搜索错误
grep ERROR logs/cron-scheduler.log
```

## 🚦 生产部署 (Production Deployment)

### 使用 PM2 (Using PM2)

```bash
# 安装 PM2
npm install -g pm2

# 启动调度器
pm2 start index.js --name cron-scheduler

# 保存进程列表
pm2 save

# 设置开机自启
pm2 startup
```

### Docker 部署 (Docker Deployment)

```dockerfile
FROM node:16-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["node", "index.js"]
```

```bash
docker build -t cron-scheduler .
docker run -d --name cron-scheduler cron-scheduler
```

## 🐛 故障排除 (Troubleshooting)

### 常见问题 (Common Issues)

1. **任务未执行**
   - 检查 Cron 表达式是否正确
   - 确认任务是否被禁用
   - 查看日志文件排查错误

2. **脚本执行失败**
   - 验证脚本依赖是否安装
   - 检查脚本路径是否正确
   - 手动测试脚本执行

3. **状态文件损坏**
   - 删除 `data/task-status.json`
   - 重启调度器

详细故障排除请参考 [CRON-CONFIG.md](./CRON-CONFIG.md)

## 📈 性能指标 (Performance Metrics)

| 指标 (Metric) | 数值 (Value) |
|---------------|--------------|
| 任务执行时间 | < 1分钟 |
| 内存占用 | < 50MB |
| CPU 占用 | < 1% |
| 日志大小 | ~10KB/天 |

## 🤝 贡献 (Contributing)

欢迎提交 Issue 和 Pull Request！

Issues and Pull Requests are welcome!

## 📄 许可证 (License)

MIT License - 详见 [LICENSE](LICENSE)

## 📞 联系方式 (Contact)

- GitHub: [OpenClaw](#)
- Email: [support@openclaw.io](mailto:support@openclaw.io)

## 🙏 致谢 (Acknowledgments)

- [node-cron](https://github.com/node-cron/node-cron) - Cron 表达式解析
- [winston](https://github.com/winstonjs/winston) - 日志管理
- [moment-timezone](https://momentjs.com/timezone/) - 时区处理

---

**维护者：** OpenClaw Team
**版本：** 1.0.0
**最后更新：** 2026-02-16
