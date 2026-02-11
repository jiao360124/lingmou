# OpenClaw 用户手册

## 版本信息

- **当前版本**: 1.0.0
- **发布日期**: 2026-02-11
- **文档版本**: 1.0
- **维护者**: LingMou

---

## 📚 目录

1. [简介](#简介)
2. [快速开始](#快速开始)
3. [功能介绍](#功能介绍)
4. [配置指南](#配置指南)
5. [常见问题](#常见问题)
6. [参考资源](#参考资源)

---

## 简介

### 什么是 OpenClaw？

OpenClaw 是一个高度自动化、模块化的系统管理平台，旨在提供：

- **统一管理**: 集中管理所有脚本和模块
- **自动备份**: 智能备份和版本控制
- **健康监控**: 实时系统健康检查
- **性能优化**: 自动化性能监控和优化
- **测试框架**: 完整的测试套件

### 主要功能

#### 1. 集成管理
- 统一管理所有脚本模块
- 提供统一的操作接口
- 实时监控系统状态

#### 2. 自动备份
- 每日自动备份
- Git集成版本控制
- 多种备份策略

#### 3. 健康监控
- 系统健康检查
- 模块完整性验证
- 性能指标监控

#### 4. 性能优化
- 性能基准测试
- Gateway优化
- 内存优化

#### 5. 测试框架
- 语法验证
- 模块测试
- 集成测试

### 适用场景

- **开发者**: 自动化开发和部署
- **运维人员**: 系统监控和维护
- **测试人员**: 自动化测试框架
- **项目经理**: 项目管理和进度追踪

---

## 快速开始

### 环境要求

- **操作系统**: Windows 10+, Linux, macOS
- **PowerShell**: 5.1+ (Windows)
- **Git**: 2.0+
- **Node.js**: 18+ (可选)

### 安装部署

#### 1. 克隆代码

```bash
git clone https://github.com/jiao360124/lingmou.git
cd lingmou
```

#### 2. 配置环境

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑配置文件
notepad .env
```

#### 3. 加载环境变量

```powershell
# PowerShell
. .\env-loader.ps1
```

```bash
# Bash
source .env-loader.sh
```

### 基本配置

#### 端口配置

所有服务统一使用端口 `18789`：

- **Gateway**: `ws://127.0.0.1:18789`
- **Dashboard**: `http://127.0.0.1:18789/`

#### 配置文件

创建 `.env` 文件：

```env
# Gateway 配置
GATEWAY_PORT=18789

# Canvas 配置
CANVAS_PORT=18789

# 日志配置
LOG_LEVEL=info
LOG_PATH=./logs
```

### 首次使用

#### 1. 检查系统状态

```powershell
.\scripts\integration-manager.ps1 -Action status
```

#### 2. 运行健康检查

```powershell
.\scripts\integration-manager.ps1 -Action health
```

#### 3. 查看系统报告

```powershell
.\scripts\integration-manager.ps1 -Action report
```

---

## 功能介绍

### 集成管理器

#### 概述

集成管理器是OpenClaw的核心工具，提供统一的系统管理接口。

#### 功能列表

| 命令 | 功能 | 说明 |
|------|------|------|
| `status` | 查看状态 | 显示系统状态和模块信息 |
| `health` | 健康检查 | 运行系统健康检查 |
| `report` | 生成报告 | 生成详细的系统报告 |
| `test` | 模块测试 | 测试所有模块的语法 |
| `start` | 启动模块 | 启动所有模块 |
| `stop` | 停止模块 | 停止所有模块 |

#### 使用示例

##### 查看系统状态

```powershell
.\scripts\integration-manager.ps1 -Action status
```

**输出**:

```
====================================================
  System Status
====================================================

Module Statistics:
  Common: 6 modules
  Performance: 5 modules
  Testing: 8 modules
  Total: 19 modules

Modules List:

[Common]:
  [OK] clear-context
  [OK] git-backup
  ...

System Information:
  Workspace: C:\Users\Administrator\.openclaw\workspace
  Scripts: C:\Users\Administrator\.openclaw\workspace\scripts
  ...
```

##### 运行健康检查

```powershell
.\scripts\integration-manager.ps1 -Action health
```

**输出**:

```
====================================================
  System Health Check
====================================================

  [OK] Scripts Directory
  [OK] Config: .env-loader.ps1
  [WARN] Module Integrity
  [OK] Directory: logs
  [OK] Directory: memory
  ...
```

##### 生成详细报告

```powershell
.\scripts\integration-manager.ps1 -Action report
```

**报告内容**:

- 系统概览
- 模块分类和状态
- 目录结构
- 配置文件
- 脚本统计
- Cron任务
- Git仓库状态

---

### 模块功能

#### Common Scripts

##### clear-context

清除OpenClaw上下文，释放token空间。

```powershell
.\scripts\clear-context.ps1
```

**功能**:
- 删除旧会话文件
- 清理.lock文件
- 重置token计数器

**使用场景**:
- Token使用率接近100%
- 会话卡死
- 需要清理缓存

##### git-backup

使用Git进行自动备份。

```powershell
.\scripts\git-backup.ps1
```

**功能**:
- 检测文件变化
- 创建Git提交
- 自动推送到GitHub
- 更新记忆文件

**参数**:
- `-DryRun`: 测试模式，不实际执行

**使用场景**:
- 定期备份工作空间
- 版本控制
- 数据恢复

##### daily-backup

创建ZIP格式的本地备份。

```powershell
.\scripts\daily-backup.ps1
```

**功能**:
- 创建ZIP压缩文件
- 保留最近7个备份
- 自动清理旧备份

**注意事项**:
- 备份文件不推送到GitHub（>100MB限制）
- 适合本地备份

#### Performance Modules

##### performance-benchmark

性能基准测试。

```powershell
.\scripts\performance-benchmark.ps1
```

**功能**:
- 测试系统性能
- 生成基准报告
- 识别性能瓶颈

##### gateway-optimizer

Gateway优化工具。

```powershell
.\scripts\gateway-optimizer.ps1
```

**功能**:
- 优化Gateway配置
- 调整性能参数
- 重启Gateway服务

#### Testing Modules

##### test-simple

简单测试模块。

```powershell
.\scripts\test-simple.ps1
```

**功能**:
- 快速语法验证
- 基本功能测试

##### test-full

完整测试套件。

```powershell
.\scripts\test-full.ps1
```

**功能**:
- 全面测试
- 生成详细报告
- 性能分析

---

## 配置指南

### 环境变量配置

#### .env 文件

创建 `.env` 文件：

```env
# Gateway 配置
GATEWAY_PORT=18789

# Canvas 配置
CANVAS_PORT=18789

# 日志配置
LOG_LEVEL=info
LOG_PATH=./logs

# 备份配置
MAX_BACKUPS=7
MAX_ZIP_SIZE_MB=100
```

### 端口配置

#### 统一端口

所有服务统一使用端口 `18789`：

```env
GATEWAY_PORT=18789
CANVAS_PORT=18789
```

#### 环境变量加载器

**PowerShell**:

```powershell
. .\.env-loader.ps1
```

**Bash**:

```bash
source .\.env-loader.sh
```

### 模块配置

#### 模块列表

```powershell
$modules = Get-AllModules
```

#### 模块状态

```powershell
Get-ModuleStatus -ModuleName "git-backup"
```

### 定时任务配置

#### Cron 任务列表

```bash
openclaw cron list
```

#### 添加Cron任务

```bash
openclaw cron add --schedule "0 2 * * *" --command "backup"
```

---

## 常见问题

### Q1: 如何清除OpenClaw上下文？

**方法1**: 使用集成管理器

```powershell
.\scripts\integration-manager.ps1 -Action clear-context
```

**方法2**: 直接运行脚本

```powershell
.\scripts\clear-context.ps1
```

### Q2: Token使用率100%怎么办？

**解决方案**:

```powershell
# 清除上下文
.\scripts\clear-context.ps1

# 重新开始会话
```

### Q3: 如何检查系统健康状态？

**方法**:

```powershell
# 使用集成管理器
.\scripts\integration-manager.ps1 -Action health

# 查看状态
.\scripts\integration-manager.ps1 -Action status
```

### Q4: 如何创建自动备份？

**方法1**: 手动备份

```powershell
.\scripts\git-backup.ps1
```

**方法2**: 定时备份

```bash
# 添加Cron任务
openclaw cron add \
  --schedule "0 2 * * *" \
  --command "powershell -ExecutionPolicy Bypass -File scripts/git-backup.ps1"
```

### Q5: 模块测试失败怎么办？

**检查步骤**:

1. 查看模块状态

```powershell
.\scripts\integration-manager.ps1 -Action status
```

2. 查看健康检查

```powershell
.\scripts\integration-manager.ps1 -Action health -Detailed
```

3. 检查模块是否存在

```powershell
Test-Path .\scripts\your-module.ps1
```

### Q6: 如何修改Gateway端口？

**方法1**: 环境变量

```env
GATEWAY_PORT=28089
```

**方法2**: 配置文件

```json
{
  "gateway": {
    "port": 28089
  }
}
```

### Q7: 备份文件超过100MB怎么办？

**解决方案**:

1. 减少保留的备份数量

```env
MAX_BACKUPS=3
```

2. 使用Git备份替代ZIP备份

```powershell
.\scripts\git-backup.ps1
```

3. 删除旧备份

```bash
# 删除7天前的备份
find ./backup -name "*.zip" -mtime +7 -delete
```

### Q8: 如何查看系统日志？

**日志位置**:

```
logs/
  ├── gateway.log
  ├── agent.log
  └── cron.log
```

**查看实时日志**:

```bash
tail -f logs/gateway.log
```

**查看最近日志**:

```powershell
Get-Content logs/gateway.log -Tail 50
```

---

## 参考资源

### 官方文档

- [OpenClaw 文档](https://docs.openclaw.ai)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [OpenClaw 社区](https://discord.com/invite/clawd)

### 内部资源

- [系统集成指南](SYSTEM_INTEGRATION_GUIDE.md)
- [Week 3 完成报告](week3-final-report.md)
- [Week 4 计划](week4-plan.md)

### 相关工具

- [Git](https://git-scm.com/)
- [PowerShell](https://docs.microsoft.com/powershell/)
- [Node.js](https://nodejs.org/)

### 示例代码

详细示例代码请参考：
- [示例目录](./examples)
- [测试脚本](./scripts)

---

## 获取帮助

### 在线支持

- **GitHub Issues**: https://github.com/jiao360124/lingmou/issues
- **Discord**: https://discord.com/invite/clawd

### 联系方式

**维护者**: LingMou
**邮箱**: lingmou@openclaw.local
**GitHub**: https://github.com/jiao360124

---

## 更新日志

### v1.0.0 (2026-02-11)

**新增**:
- ✅ 统一集成管理器
- ✅ 用户手册
- ✅ 系统集成指南
- ✅ 自动备份系统

**改进**:
- 🚀 模块化设计
- 🚀 统一接口
- 🚀 健康检查系统
- 🚀 测试框架

---

**文档版本**: 1.0
**最后更新**: 2026-02-11
**维护者**: LingMou
