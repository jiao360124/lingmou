# OpenClaw 系统集成指南

## 概述

OpenClaw 系统现在由统一的集成管理器协调，提供集中化的系统管理和监控能力。

## 系统架构

```
┌─────────────────────────────────────────────────────────┐
│              Integration Manager v1.0                   │
│              统一集成管理器                              │
└──────────────────────┬──────────────────────────────────┘
                       │
         ┌─────────────┼─────────────┐
         │             │             │
         ▼             ▼             ▼
    ┌─────────┐  ┌─────────┐  ┌─────────┐
    │ Common  │  │Performance│  │Testing  │
    │ Scripts │  │ Modules  │  │ Modules │
    └─────────┘  └─────────┘  └─────────┘
```

## 模块分类

### 1. Common Scripts (6个)
日常维护和管理脚本：
- `clear-context` - 上下文清理
- `daily-backup` - 每日备份（Zipped）
- `git-backup` - Git备份（推荐）
- `simple-health-check` - 基础健康检查
- `cleanup-logs-manual` - 手动日志清理
- `cleanup-github-tokens` - 令牌清理

### 2. Performance Modules (5个)
性能优化和监控：
- `performance-benchmark` - 性能基准测试
- `gradual-degradation` - 渐进式降级
- `gateway-optimizer` - Gateway优化
- `response-optimizer` - 响应优化（待实现）
- `memory-optimizer` - 内存优化（待实现）

### 3. Testing Modules (8个)
测试和验证框架：
- `test-simple` - 简单测试
- `test-full` - 完整测试
- `test-predictive-maintenance` - 预测性维护测试
- `test-smart-enhanced` - 智能增强测试
- `stress-test` - 压力测试（待实现）
- `error-recovery-test` - 错误恢复测试（待实现）
- `integration-test` - 集成测试（待实现）
- `final-test` - 最终测试（待实现）

## 使用方法

### 1. 查看系统状态

```powershell
.\scripts\integration-manager.ps1 -Action status
```

**输出示例**:
```
====================================================
  System Status
====================================================

Module Statistics:
  Common: 6 modules
  Testing: 8 modules
  Performance: 5 modules
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

### 2. 运行健康检查

```powershell
.\scripts\integration-manager.ps1 -Action health
```

**输出示例**:
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

Health Summary:
  OK: 9
  WARNING: 3
  ERROR: 0
```

### 3. 生成系统报告

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

### 4. 测试所有模块

```powershell
.\scripts\integration-manager.ps1 -Action test
```

### 5. 启动所有模块

```powershell
.\scripts\integration-manager.ps1 -Action start
```

### 6. 停止所有模块

```powershell
.\scripts\integration-manager.ps1 -Action stop
```

## 配置管理

### 环境变量

系统使用以下环境变量文件：

1. **`.env.example`** - 配置模板
2. **`.env-loader.ps1`** - PowerShell加载器
3. **`.env-loader.sh`** - Bash加载器
4. **`.ports.env`** - 端口配置

### 端口配置

统一使用端口 18789：
- Gateway: 18789
- Dashboard: 18789
- API: 18789

## 模块管理

### 检查模块完整性

```powershell
.\scripts\integration-manager.ps1 -Action status
```

查看 `[OK]` 和 `[MISS]` 标记：
- `[OK]` - 模块存在且可用
- `[MISS]` - 模块不存在

### 识别缺失模块

Day 3 Day 5 创建的脚本：
- `stress-test` (MISS)
- `error-recovery-test` (MISS)
- `integration-test` (MISS)
- `final-test` (MISS)
- `response-optimizer` (MISS)
- `memory-optimizer` (MISS)

### 模块迁移

对于缺失的模块，需要：
1. 创建对应脚本
2. 更新 `Get-AllModules()` 函数
3. 运行健康检查验证

## 定时任务

当前激活的Cron任务：

| 任务名称 | 执行频率 | 下次执行 |
|---------|---------|---------|
| 每日Git自动备份 | 每天 | 2026-02-12 18:50 |
| 每小时Gateway状态检查 | 每小时 | 持续运行 |
| 每日Doctor检查 | 每天 | 持续运行 |
| 日志自动清理 | 每天 | 持续运行 |
| 健康检查脚本 | 每天 | 持续运行 |
| Gateway服务优化 | 每3天 | 持续运行 |
| 每周自动更新 | 每周日20:00 | 持续运行 |

## 日志管理

### 日志位置
```
logs/
  ├── gateway.log
  ├── agent.log
  └── cron.log
```

### 清理日志

```powershell
# 手动清理
.\scripts\cleanup-logs-manual.ps1

# 或使用Git备份（推荐）
.\scripts\git-backup.ps1
```

## 备份策略

### 本地备份
```powershell
.\scripts\daily-backup.ps1
```
- 创建ZIP文件
- 保留最近7个备份
- 不推送到GitHub（>100MB限制）

### Git备份（推荐）
```powershell
.\scripts\git-backup.ps1
```
- Git提交快照
- 自动推送到GitHub
- 记录在MEMORY.md

## 最佳实践

### 1. 定期检查

```powershell
# 每日健康检查
.\scripts\integration-manager.ps1 -Action health

# 每周系统报告
.\scripts\integration-manager.ps1 -Action report
```

### 2. 安全清理

```powershell
# 清理GitHub令牌
.\scripts\cleanup-github-tokens.ps1

# 清理上下文
.\scripts\clear-context.ps1
```

### 3. 性能优化

```powershell
# 性能基准测试
.\scripts\performance-benchmark.ps1

# Gateway优化
.\scripts\gateway-optimizer.ps1
```

### 4. 定时备份

```powershell
# Git备份（每日自动）
# Cron任务: "每日Git自动备份"
```

## 故障排除

### 问题: 模块缺失

**解决方案**:
```powershell
# 检查状态
.\scripts\integration-manager.ps1 -Action status

# 查看缺失模块
# response-optimizer, memory-optimizer 等
```

### 问题: 健康检查警告

**解决方案**:
```powershell
# 详细输出
.\scripts\integration-manager.ps1 -Action health -Detailed

# 检查配置文件
Test-Path .env
Test-Path .env-loader.ps1
```

### 问题: Git同步失败

**解决方案**:
```powershell
# 检查远程仓库
git remote -v

# 查看状态
git status

# 推送更改
git push origin main
```

## 扩展开发

### 添加新模块

1. 创建脚本文件：
   ```
   scripts/your-module.ps1
   ```

2. 更新模块列表：
   ```powershell
   $commonModules += @(
       "your-module"
   )
   ```

3. 测试模块：
   ```powershell
   .\scripts\your-module.ps1
   ```

4. 更新集成管理器：
   ```powershell
   # 重新加载模块列表
   .\scripts\integration-manager.ps1 -Action status
   ```

### 添加新命令

在 `Main()` 函数中添加：

```powershell
switch ($Action) {
    # ... existing actions ...
    "new-action" {
        New-ActionFunction
    }
}
```

## 系统要求

- PowerShell 5.1+
- Git 2.x
- OpenClaw Gateway 1.x
- 每日定时任务权限

## 版本信息

- **集成管理器**: v1.0
- **创建时间**: 2026-02-11
- **总模块数**: 19个脚本
- **代码行数**: ~5,183行

## 参考资料

- [Week 3 Final Report](week3-final-report.md)
- [Week 4 Plan](week4-plan.md)
- [AUTO_BACKUP_README.md](AUTO_BACKUP_README.md)
- [OpenClaw Documentation](https://docs.openclaw.ai)
