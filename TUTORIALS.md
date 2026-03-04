# 详细教程

**灵眸系统完整指南**
**版本**: 1.0.0
**更新日期**: 2026-02-11

---

## 📚 目录

1. [系统概述](#系统概述)
2. [安装指南](#安装指南)
3. [配置指南](#配置指南)
4. [核心模块使用](#核心模块使用)
5. [高级功能](#高级功能)
6. [最佳实践](#最佳实践)

---

## 系统概述

### 什么是灵眸？

灵眸是一个基于OpenClaw的自动化运维和智能管理系统，具有以下特点：

- ✅ **高可用性**: 正常运行时间 >99.5%
- ✅ **智能调度**: 基于优先级的自动化任务管理
- ✅ **自我修复**: 自动错误检测和恢复
- ✅ **性能优化**: 实时监控和性能调优
- ✅ **完整监控**: Gateway、资源、API、错误全方位监控

### 系统架构

```
┌─────────────────────────────────────┐
│         用户界面（可选）              │
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│       系统集成管理器                   │
│  (统一接口、配置管理、架构协调)        │
└─────────────────┬───────────────────┘
                  │
        ┌─────────┼─────────┐
        │         │         │
┌───────▼────┐ ┌─▼───────┐ ┌▼────────────┐
│  监控模块  │ │ 自动化  │ │  优化模块   │
│  Nightly   │ │  技能   │ │  Performance│
└────────────┘ └─────────┘ └─────────────┘
        │         │         │
        └─────────┼─────────┘
                  │
┌─────────────────▼───────────────────┐
│     数据层（日志、错误、性能）         │
└─────────────────────────────────────┘
```

---

## 安装指南

### 系统要求

- **操作系统**: Windows 10+, Linux, macOS
- **PowerShell**: 5.1+ 或 7.0+
- **内存**: 至少 4GB RAM
- **磁盘**: 至少 1GB 可用空间
- **网络**: 稳定的网络连接

### 1. 克隆仓库

```bash
git clone <repository-url>
cd <workspace-directory>
```

### 2. 配置环境变量

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑 .env 文件
nano .env
```

**必需配置项**:
```env
GATEWAY_PORT=18789
BACKUP_PATH=./backup
LOG_LEVEL=Info
```

### 3. 加载环境变量

```bash
# PowerShell
. .env-loader.ps1

# Bash
source .env-loader.sh
```

### 4. 验证安装

```bash
# 检查环境
powershell -ExecutionPolicy Bypass -File "scripts/environment-check.ps1"

# 启动Gateway
openclaw gateway start

# 检查状态
openclaw status
```

---

## 配置指南

### 基础配置

#### Gateway端口配置

编辑 `.ports.env`:

```env
GATEWAY_PORT=18789
CANVAS_PORT=18789
HEARTBEAT_PORT=18789
WEBSOCKET_PORT=18789
```

#### 日志配置

编辑 `.env`:

```env
LOG_LEVEL=Info          # Debug, Info, Warn, Error
LOG_PATH=./logs
LOG_MAX_SIZE=100MB
LOG_RETENTION_DAYS=7
```

#### 备份配置

编辑 `.env`:

```env
BACKUP_PATH=./backup
BACKUP_RETENTION=7      # 保留最近7个备份
BACKUP_SCHEDULE=0 2 * * *
```

### 高级配置

#### 优化配置

编辑 `config/optimization.json`:

```json
{
  "memory_limit": "80%",
  "cache_enabled": true,
  "max_concurrent_tasks": 10,
  "retry_attempts": 3
}
```

#### 监控配置

编辑 `config/monitoring.json`:

```json
{
  "check_interval": 60,
  "alert_threshold": {
    "memory": 90,
    "disk": 85,
    "error_rate": 5
  }
}
```

---

## 核心模块使用

### 模块1: Nightly Evolution（夜航计划）

#### 功能描述
自动化系统监控、错误检测、性能分析、智能修复

#### 使用方法

```bash
# 运行夜航计划（所有检查）
powershell -ExecutionPolicy Bypass -File "scripts/nightly-evolution.ps1"

# 运行特定检查
powershell -ExecutionPolicy Bypass -File "scripts/nightly-evolution.ps1" -Check Gateway
powershell -ExecutionPolicy Bypass -File "scripts/nightly-evolution.ps1" -Check Performance
```

#### 输出文件
- `logs/nightly-evolution-YYYY-MM-DD.json` - 结构化日志
- `logs/nightly-evolution-YYYY-MM-DD.log` - 详细日志
- `reports/nightly-evolution-YYYY-MM-DD.md` - 摘要报告

#### 配置文件
- `config/nightly-evolution.json`

---

### 模块2: Simple Health Check

#### 功能描述
快速系统健康检查，返回简洁状态

#### 使用方法

```bash
# 运行健康检查
powershell -ExecutionPolicy Bypass -File "scripts/simple-health-check.ps1"

# 检查特定项目
powershell -ExecutionPolicy Bypass -File "scripts/simple-health-check.ps1" -Target Gateway,Memory,Disk
```

#### 输出格式

```json
{
  "status": "OK",
  "timestamp": "2026-02-11T21:00:00Z",
  "checks": {
    "Gateway": {"status": "OK", "response_time": "27ms"},
    "Memory": {"status": "OK", "usage": "3%"},
    "Disk": {"status": "OK", "usage": "89%"}
  }
}
```

---

### 模块3: Integration Manager

#### 功能描述
统一管理所有模块，一键启动

#### 使用方法

```bash
# 运行所有模块
powershell -ExecutionPolicy Bypass -File "scripts/integration-manager.ps1"

# 启动特定模块
powershell -ExecutionPolicy Bypass -File "scripts/integration-manager.ps1" -Module Nightly

# 查看模块状态
powershell -ExecutionPolicy Bypass -File "scripts/integration-manager.ps1" -Status
```

#### 支持的模块
- `Nightly` - Nightly Evolution
- `HealthCheck` - Simple Health Check
- `Monitor` - 实时监控
- `Optimize` - 性能优化
- `Backup` - 自动备份

---

## 高级功能

### 1. 性能基准测试

```bash
# 运行性能测试
powershell -ExecutionPolicy Bypass -File "scripts/performance-benchmark.ps1"

# 查看历史结果
Get-ChildItem "reports/performance-benchmark-*.json" | Format-Table
```

### 2. 错误日志分析

```bash
# 分析错误日志
powershell -ExecutionPolicy Bypass -File "scripts/analyze-errors.ps1"

# 查看错误统计
Get-Content "logs/nightly-evolution-*.json" | ConvertFrom-Json | Select-Object -ExpandProperty errors
```

### 3. 自动化工作流

```bash
# 使用智能任务调度器
powershell -ExecutionPolicy Bypass -File "scripts/automation/smart-task-scheduler.ps1"

# 查看任务队列
Get-Content "tasks/scheduler-tasks.json"
```

---

## 最佳实践

### 1. 定期健康检查

```bash
# 每日检查（可以设置为定时任务）
powershell -ExecutionPolicy Bypass -File "scripts/simple-health-check.ps1"
```

### 2. 错误日志管理

```bash
# 定期清理旧日志
powershell -ExecutionPolicy Bypass -File "scripts/cleanup-logs.ps1"

# 保留最近7天的日志
```

### 3. 数据备份

```bash
# 手动备份
powershell -ExecutionPolicy Bypass -File "scripts/daily-backup.ps1"

# 检查备份状态
Test-Path "backup/20260211_*.zip"
```

### 4. 监控告警

```bash
# 配置监控告警（在config/monitoring.json中）
# 根据阈值设置告警
```

---

## 故障排除

### 问题1: 脚本执行失败

**症状**: 提示"无法加载模块"或"脚本执行策略错误"

**解决方案**:
```bash
# 使用 -ExecutionPolicy Bypass 参数
powershell -ExecutionPolicy Bypass -File "scripts/xxx.ps1"

# 或者临时更改策略
Set-ExecutionPolicy RemoteSigned -Scope Process
```

### 问题2: Gateway连接失败

**症状**: `openclaw status` 返回错误

**解决方案**:
```bash
# 检查Gateway是否运行
openclaw gateway status

# 重启Gateway
openclaw gateway restart

# 检查端口是否被占用
netstat -ano | findstr "18789"
```

### 问题3: 环境变量未生效

**症状**: 脚本中使用端口变量时返回默认值

**解决方案**:
```bash
# 确保加载了环境变量
. .env-loader.ps1

# 验证变量
echo $GATEWAY_PORT

# 重新加载环境
Remove-Variable -Name GATEWAY_PORT -Force
. .env-loader.ps1
```

---

## 获取帮助

- 📖 **完整文档**: [API_DOCUMENTATION.md](API_DOCUMENTATION.md)
- 🐛 **问题反馈**: 查看 [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) 中的故障排除部分
- 💬 **社区支持**: 访问 [OpenClaw文档](https://docs.openclaw.ai)

---

**文档版本**: 1.0.0
**最后更新**: 2026-02-11
