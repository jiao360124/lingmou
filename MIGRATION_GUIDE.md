# OpenClaw 迁移指南

本文档提供了从旧版本或从零开始设置OpenClaw工作空间的完整指南。

---

## 📋 目录

1. [环境要求](#环境要求)
2. [快速开始](#快速开始)
3. [配置步骤](#配置步骤)
4. [功能模块](#功能模块)
5. [常见问题](#常见问题)
6. [故障排除](#故障排除)

---

## 🖥️ 环境要求

### 系统要求

- **操作系统**: Windows 10/11, macOS 10.14+, Linux (Ubuntu 18.04+, Debian 9+)
- **内存**: 最低 2GB RAM, 推荐 4GB+
- **磁盘空间**: 最低 500MB, 推荐 1GB+
- **Python**: 3.6+ (用于某些脚本)
- **PowerShell**: 5.1+ (Windows)

### 安装

#### Windows

1. 下载 OpenClaw 安装包
2. 运行安装程序
3. 按照向导完成安装
4. 验证安装: `openclaw --version`

#### macOS

```bash
# 使用 Homebrew
brew install openclaw

# 验证安装
openclaw --version
```

#### Linux

```bash
# 使用 npm (Node.js 12+)
npm install -g openclaw

# 验证安装
openclaw --version
```

---

## 🚀 快速开始

### 1. 首次设置

```bash
# 克隆仓库
git clone https://github.com/jiao360124/AE8F88.git
cd AE8F88

# 复制环境配置
cp .env.example .env

# 编辑配置文件
notepad .env
```

### 2. 初始化工作空间

```bash
# 初始化 Git
git init
git remote add origin https://github.com/jiao360124/AE8F88.git
git pull origin main

# 运行初始化脚本
.\scripts\init.ps1
```

### 3. 验证安装

```bash
# 检查系统状态
openclaw status

# 测试核心功能
.\scripts\simple-health-check.ps1
```

---

## ⚙️ 配置步骤

### 1. 环境变量配置

编辑 `.env` 文件，配置以下关键参数：

#### 基本配置

```bash
# 工作空间目录
WORKSPACE_DIR=C:\Users\Administrator\.openclaw\workspace

# 时区
TIMEZONE=Asia/Shanghai

# Git 仓库
GITHUB_REPO=https://github.com/jiao360124/AE8F88.git
GITHUB_USERNAME=your-username
GITHUB_TOKEN=your-github-token
```

#### 日志配置

```bash
# 日志级别
LOG_LEVEL=INFO

# 日志轮转
LOG_ROTATION_SIZE=10
LOG_RETENTION_DAYS=30
```

#### 备份配置

```bash
# 备份计划 (Cron 格式)
BACKUP_SCHEDULE=0 2 * * *  # 每天 2:00 AM

# 备份保留
BACKUP_RETENTION_DAYS=7
```

### 2. 端口配置

编辑 `.ports.env` 文件：

```bash
# Gateway 端口
GATEWAY_PORT=8080

# API 端口
API_PORT=8081

# 其他服务端口
...
```

### 3. Moltbook 配置 (可选)

```bash
# Moltbook API
MOLTBOOK_API_URL=https://moltbook.com/api
MOLTBOOK_API_KEY=your-api-key
MOLTBOOK_AGENT_NAME=灵眸
```

---

## 📦 功能模块

### 核心模块

#### 1. 系统健康检查

```powershell
# 运行健康检查
.\scripts\simple-health-check.ps1

# 详细输出
.\scripts\simple-health-check.ps1 -Detailed
```

#### 2. 集成测试

```powershell
# 运行集成测试
.\scripts\integration-test.ps1

# 详细输出
.\scripts\integration-test.ps1 -Detailed
```

#### 3. 压力测试

```powershell
# 运行压力测试
.\scripts\stress-test.ps1 -DurationSeconds 60 -Concurrency 10
```

#### 4. 错误恢复测试

```powershell
# 运行错误恢复测试
.\scripts\error-recovery-test.ps1 -Detailed
```

### 备份模块

#### 1. 自动备份

```powershell
# 手动触发备份
.\scripts\git-backup.ps1 -CommitMessage "Backup"

# 查看备份历史
.\scripts\diagnose-git-backup.ps1
```

#### 2. 定时备份

```powershell
# 添加定时任务
.\scripts\add-cron-job.ps1 -Job "Daily Backup" -Command ".\scripts\git-backup.ps1"
```

### 性能优化模块

#### 1. 响应优化器

```powershell
# 运行响应优化
.\scripts\response-optimizer.ps1 -Detailed

# Dry run 模式
.\scripts\response-optimizer.ps1 -DryRun
```

#### 2. 内存优化器

```powershell
# 运行内存优化
.\scripts\memory-optimizer.ps1 -Detailed

# Dry run 模式
.\scripts\memory-optimizer.ps1 -DryRun
```

#### 3. 性能基准测试

```powershell
# 运行性能基准
.\scripts\performance-benchmark.ps1 -Detailed
```

### 日志管理

#### 1. 日志清理

```powershell
# 手动清理日志
.\scripts\cleanup-logs-manual.ps1

# 自动清理
.\scripts\cleanup-logs-auto.ps1
```

#### 2. 日志查看

```powershell
# 查看日志
Get-Content logs\*.log -Tail 100
```

---

## 📚 API 文档

### 系统健康检查 API

**请求**
```http
GET /health
```

**响应**
```json
{
  "status": "healthy",
  "uptime": "12345s",
  "memory": {
    "used": "256MB",
    "available": "256MB",
    "percentage": "50%"
  }
}
```

### 集成测试 API

**请求**
```http
POST /api/integration/test
```

**响应**
```json
{
  "total": 19,
  "passed": 15,
  "failed": 4,
  "success_rate": "78.9%"
}
```

### 备份 API

**请求**
```http
POST /api/backup
```

**响应**
```json
{
  "status": "success",
  "backup_id": "backup-20260214-001",
  "files_backed_up": 45
}
```

---

## ❓ 常见问题

### 1. 端口被占用

**问题**: `Error: Port 8080 is already in use`

**解决方案**:
```bash
# 查找占用进程
netstat -ano | findstr :8080

# 终止进程
taskkill /PID <PID> /F

# 或更改端口配置
# 编辑 .ports.env 文件，设置不同的端口
```

### 2. Git 认证失败

**问题**: `Authentication failed`

**解决方案**:
```bash
# 生成新的 Personal Access Token
# 1. 访问 GitHub Settings > Developer settings > Personal access tokens
# 2. Generate new token with repo scope
# 3. 复制 token 到 .env 文件
```

### 3. 权限问题

**问题**: `Access denied`

**解决方案**:
```powershell
# 以管理员身份运行 PowerShell
# 右键点击 PowerShell > "Run as administrator"

# 或授予脚本执行权限
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 4. 内存不足

**问题**: `Out of memory`

**解决方案**:
```bash
# 1. 减少并发请求
MAX_CONCURRENT_REQUESTS=5

# 2. 增加缓存大小
CACHE_MAX_SIZE=200

# 3. 运行内存优化
.\scripts\memory-optimizer.ps1 -Detailed

# 4. 清理临时文件
.\scripts\cleanup-logs-manual.ps1
```

### 5. 备份失败

**问题**: `Backup failed`

**解决方案**:
```bash
# 1. 检查 Git 状态
git status

# 2. 查看详细错误
.\scripts\diagnose-git-backup.ps1

# 3. 手动执行备份
.\scripts\git-backup.ps1 -Verbose
```

---

## 🔧 故障排除

### 日志位置

- **应用日志**: `logs\openclaw.log`
- **错误日志**: `logs\error.log`
- **系统日志**: `logs\system.log`

### 检查系统状态

```bash
# 检查所有服务状态
openclaw status

# 查看详细日志
Get-Content logs\*.log -Tail 100 -Wait

# 重启服务
openclaw restart
```

### 重置配置

```bash
# 备份当前配置
cp .env .env.backup
cp .ports.env .ports.env.backup

# 重新生成配置
.\scripts\init.ps1

# 从备份恢复
cp .env.backup .env
cp .ports.env.backup .ports.env
```

### 联系支持

- **GitHub Issues**: https://github.com/jiao360124/AE8F88/issues
- **Discord**: https://discord.com/invite/clawd
- **Email**: support@openclaw.ai

---

## 📖 附录

### A. 命令参考

#### 常用命令

```bash
# 状态检查
openclaw status

# 启动服务
openclaw start

# 停止服务
openclaw stop

# 重启服务
openclaw restart

# 查看日志
openclaw logs

# 更新
openclaw update

# 帮助
openclaw --help
```

#### 脚本命令

```powershell
# 健康检查
.\scripts\simple-health-check.ps1

# 集成测试
.\scripts\integration-test.ps1

# 备份
.\scripts\git-backup.ps1

# 性能优化
.\scripts\performance-benchmark.ps1
```

### B. 配置示例

#### 生产环境配置

```bash
# 生产环境配置示例
LOG_LEVEL=ERROR
BACKUP_SCHEDULE=0 3 * * *
MAX_CONCURRENT_REQUESTS=20
REQUEST_TIMEOUT=60
```

#### 开发环境配置

```bash
# 开发环境配置示例
LOG_LEVEL=DEBUG
BACKUP_SCHEDULE=0 5 * * *
MAX_CONCURRENT_REQUESTS=5
REQUEST_TIMEOUT=30
```

### C. 版本历史

- **v1.0.0** (2026-02-13)
  - 初始版本
  - 核心模块实现
  - 集成测试框架

---

**文档版本**: 1.0.0
**最后更新**: 2026-02-14
**维护者**: OpenClaw Team
