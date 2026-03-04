# Cron Scheduler Configuration Guide

## 概述 (Overview)

Cron Scheduler 是一个基于 node-cron 和 node-cron 库的定时任务管理系统，用于自动化执行各类周期性任务。系统支持任务优先级管理、失败重试、状态监控等功能。

The Cron Scheduler is a periodic task management system based on node-cron, supporting task prioritization, failure retry, and status monitoring.

## 安装 (Installation)

### 前置要求 (Prerequisites)

- Node.js 16.x 或更高版本
- npm 或 yarn

### 安装步骤 (Installation Steps)

1. 进入 cron-scheduler 目录：
   ```bash
   cd cron-scheduler
   ```

2. 安装依赖：
   ```bash
   npm install
   ```

### 快速启动 (Quick Start)

```bash
# 启动调度器
npm start

# 运行测试
npm test

# 调度管理
npm run schedule
```

## 配置文件 (Configuration Files)

### 1. cron-config.json

主配置文件，定义了所有定时任务的参数。

Main configuration file defining all scheduled tasks.

**位置：** `config/cron-config.json`

**内容：**
```json
{
  "version": "1.0.0",
  "description": "Cron scheduler configuration",
  "timezone": "Asia/Shanghai",
  "enabled": true,
  "maxRetries": 3,
  "retryDelay": 5,
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

### 配置参数说明 (Configuration Parameters)

| 参数 (Parameter) | 类型 (Type) | 必需 (Required) | 说明 (Description) |
|------------------|------------|----------------|-------------------|
| version | string | 是 | 配置文件版本 |
| description | string | 是 | 配置描述 |
| timezone | string | 是 | 时区，默认 Asia/Shanghai |
| enabled | boolean | 是 | 是否启用调度器 |
| maxRetries | number | 否 | 最大重试次数，默认 3 |
| retryDelay | number | 否 | 重试间隔（分钟），默认 5 |
| tasks | array | 是 | 任务列表 |

### 任务配置参数 (Task Configuration)

| 参数 (Parameter) | 类型 (Type) | 必需 (Required) | 说明 (Description) |
|------------------|------------|----------------|-------------------|
| id | string | 是 | 任务唯一标识 |
| name | string | 是 | 任务名称 |
| cronExpression | string | 是 | Cron 表达式 |
| timezone | string | 是 | 任务时区 |
| enabled | boolean | 是 | 是否启用任务 |
| priority | number | 是 | 任务优先级（1-20，数字越小优先级越高） |
| script | string | 是 | 执行脚本路径 |
| description | string | 是 | 任务描述 |

## Cron 表达式 (Cron Expressions)

### 格式说明 (Format)

```
分钟 小时 日 月 星期
  *     *  *  *  *
```

### 常用表达式 (Common Expressions)

| 表达式 (Expression) | 说明 (Description) | 执行时间 (Execution Time) |
|---------------------|-------------------|-------------------------|
| `0 4 * * *` | 每天 4:00 | 每天凌晨4点 |
| `0 3 * * *` | 每天 3:00 | 每天凌晨3点 |
| `0 0 * * 0` | 每天 0:00 | 每周日午夜 |
| `0 0 * * 1` | 每天 0:00 | 每周一午夜 |
| `*/30 * * * *` | 每30分钟 | 每30分钟执行一次 |

### 高级配置 (Advanced Configuration)

#### 每月执行 (Monthly)

```json
{
  "cronExpression": "0 0 1 * *"
}
```
每月1号午夜执行

#### 每季度执行 (Quarterly)

```json
{
  "cronExpression": "0 0 1 1,4,7,10 *"
}
```
每年1、4、7、10月的1号执行

#### 特定时间范围 (Time Range)

```json
{
  "cronExpression": "0 9-17 * * 1-5"
}
```
周一至周五的9:00-17:00每小时执行

## 任务脚本 (Task Scripts)

### 脚本结构 (Script Structure)

所有任务脚本应遵循以下结构：

All task scripts should follow this structure:

1. 日志记录 (Logging)
2. 错误处理 (Error Handling)
3. 数据生成/处理 (Data Generation/Processing)
4. 结果输出 (Output Results)

### 示例：每日报告 (Example: Daily Report)

```javascript
const fs = require('fs');
const path = require('path');
const moment = require('moment-timezone');

const PROJECT_ROOT = path.join(__dirname, '..');
const LOG_FILE = path.join(PROJECT_ROOT, 'logs', 'daily-report.log');

console.log(`[${moment().tz('Asia/Shanghai').format('YYYY-MM-DD HH:mm:ss')}] 开始生成每日报告...`);

try {
  // 1. 数据收集和处理
  const reportData = generateReportData();

  // 2. 保存报告
  saveReport(reportData);

  console.log('✓ 每日报告生成成功');

} catch (error) {
  console.error('✗ 每日报告生成失败:', error.message);
  throw error;
}
```

### 可用脚本 (Available Scripts)

| 脚本 (Script) | 功能 (Function) | 执行频率 (Frequency) |
|---------------|-----------------|---------------------|
| generate-daily-report.js | 生成每日报告 | 每天 4:00 |
| generate-weekly-report.js | 生成每周报告 | 每周一 0:00 |
| reset-daily-metrics.js | 重置每日指标 | 每天 3:00 |
| weekly-data-cleanup.js | 清理旧数据 | 每周日 0:00 |
| heartbeat-monitor.js | 心跳监控 | 每30分钟 |

## 任务优先级管理 (Task Priority Management)

### 优先级规则 (Priority Rules)

- **1-5** (低优先级)：清理、备份等
- **6-10** (中优先级)：指标监控、常规任务)
- **11-15** (高优先级)：报告生成、数据整理)
- **16-20** (最高优先级)：关键任务)

### 执行顺序 (Execution Order)

任务按优先级数字升序执行，相同优先级的任务按配置顺序执行。

Tasks execute in ascending order of priority numbers. Tasks with the same priority execute in the order they are configured.

## 任务状态监控 (Task Status Monitoring)

### 状态文件 (Status File)

任务状态保存在 `data/task-status.json`：

Task status is saved in `data/task-status.json`:

```json
{
  "daily-report": {
    "lastRun": "2026-02-16T04:00:00.000Z",
    "lastSuccess": "2026-02-16T04:00:30.000Z",
    "lastFailure": null,
    "failureCount": 0,
    "enabled": true,
    "priority": 10
  },
  "weekly-report": {
    "lastRun": "2026-02-15T00:00:00.000Z",
    "lastSuccess": "2026-02-15T00:00:45.000Z",
    "lastFailure": null,
    "failureCount": 0,
    "enabled": true,
    "priority": 15
  }
}
```

### 状态字段说明 (Status Fields)

| 字段 (Field) | 类型 (Type) | 说明 (Description) |
|--------------|------------|-------------------|
| lastRun | Date | 最后执行时间 |
| lastSuccess | Date | 最后成功时间 |
| lastFailure | Date | 最后失败时间 |
| failureCount | number | 失败次数 |
| enabled | boolean | 是否启用 |
| priority | number | 优先级 |

### 查看状态 (View Status)

```javascript
const { scheduler } = require('./index.js');

// 获取单个任务状态
const status = scheduler.getTaskStatus('daily-report');

// 获取所有任务状态
const allStatus = scheduler.getAllTaskStatus();

// 获取调度器信息
const info = scheduler.getSchedulerInfo();
```

## 错误处理与重试机制 (Error Handling & Retry Mechanism)

### 重试策略 (Retry Strategy)

1. **最大重试次数**：可配置，默认 3 次
2. **重试间隔**：每次重试间隔 5 分钟
3. **重试条件**：仅在错误时重试

### 失败处理 (Failure Handling)

- 任务失败记录时间戳和错误信息
- 达到最大重试次数后，任务状态设为禁用
- 可通过 API 手动启用任务

### 重启恢复 (Restart Recovery)

系统启动时，根据配置重新加载任务，并继续执行。

On system restart, tasks are reloaded from configuration and execution continues.

## 运维管理 (Operations Management)

### 启动调度器 (Start Scheduler)

```javascript
const { CronScheduler, scheduler } = require('./index.js');

scheduler.initialize()
  .then(() => {
    console.log('调度器已启动');
  })
  .catch(error => {
    console.error('启动失败:', error);
  });
```

### 停止调度器 (Stop Scheduler)

```javascript
scheduler.stopScheduler();
```

### 启用/禁用任务 (Enable/Disable Task)

```javascript
// 禁用任务
scheduler.toggleTask('daily-report', false);

// 启用任务
scheduler.toggleTask('daily-report', true);
```

### 查看日志 (View Logs)

日志文件位置：`logs/cron-scheduler.log`

Log file location: `logs/cron-scheduler.log`

```bash
# 查看实时日志
tail -f logs/cron-scheduler.log

# 查看最后100行
tail -n 100 logs/cron-scheduler.log
```

## 测试 (Testing)

### 运行测试套件 (Run Test Suite)

```bash
npm test
```

### 测试覆盖范围 (Test Coverage)

- ✅ 配置文件加载
- ✅ 任务脚本存在性检查
- ✅ Cron 表达式验证
- ✅ 任务执行测试
- ✅ 状态跟踪机制
- ✅ 输出文件生成

### 自定义测试 (Custom Tests)

```javascript
const { CronScheduler } = require('./index.js');

const scheduler = new CronScheduler();

// 初始化并运行
scheduler.initialize()
  .then(() => {
    console.log('测试完成');
  })
  .catch(error => {
    console.error('测试失败:', error);
  });
```

## 部署建议 (Deployment Recommendations)

### 生产环境 (Production)

1. **使用 PM2 管理**：
   ```bash
   pm2 start index.js --name cron-scheduler
   pm2 save
   pm2 startup
   ```

2. **日志轮转**：
   ```bash
   pm2 install pm2-logrotate
   ```

3. **健康检查**：
   定期检查 `data/health-check.json`

4. **监控告警**：
   监控 `logs/cron-scheduler.log` 中的错误

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

## 常见问题 (FAQ)

### Q1: 任务没有按时执行怎么办？ (Task not executing on time?)

**A:** 检查以下几点：
1. Cron 表达式是否正确
2. 任务是否被禁用
3. 系统时间是否正确
4. 脚本路径是否正确
5. 查看日志排查错误

### Q2: 任务执行失败如何处理？ (What to do if task execution fails?)

**A:** 排查步骤：
1. 查看任务状态文件
2. 检查日志文件
3. 验证脚本依赖是否安装
4. 测试脚本是否能独立运行
5. 手动重试执行

### Q3: 如何修改任务执行时间？ (How to change task execution time?)

**A:** 修改 `config/cron-config.json` 中的 cronExpression，然后重启调度器。

### Q4: 如何添加新任务？ (How to add a new task?)

**A:**
1. 创建新的任务脚本
2. 在 `config/cron-config.json` 中添加任务配置
3. 重启调度器

### Q5: 多个调度器实例能同时运行吗？ (Can multiple scheduler instances run simultaneously?)

**A:** 不建议。同一时间只应有一个调度器实例运行，否则可能导致任务重复执行。

## 维护计划 (Maintenance Schedule)

### 每周 (Weekly)

- 检查任务状态
- 审查执行日志
- 处理失败任务

### 每月 (Monthly)

- 备份配置文件
- 审查并优化任务
- 更新任务脚本

### 每季度 (Quarterly)

- 全面健康检查
- 性能优化
- 安全审计

## 联系与支持 (Contact & Support)

- GitHub Issues: [项目链接](#)
- 文档版本: 1.0.0
- 最后更新: 2026-02-16

---

**维护者：** OpenClaw Team
**版本：** 1.0.0
**最后更新：** 2026-02-16
