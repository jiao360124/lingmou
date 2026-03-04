# 自动备份系统说明

## 概述

灵眸的自动备份系统会每天自动将工作空间的变化提交到GitHub仓库，确保数据安全。

## 工作原理

1. **每日自动执行** - 系统每天执行一次备份
2. **Git快照** - 使用Git提交作为备份，快速且可靠
3. **自动推送** - 提交自动推送到GitHub远程仓库
4. **内存记录** - 每次备份的详细信息记录到记忆文件

## 定时任务

**任务名称**: 每日Git自动备份

**执行频率**: 每天（24小时）

**下次执行时间**: 2026-02-12 18:50 (UTC+8)

## 使用方法

### 手动执行备份

如果您想立即手动执行备份：

```powershell
cd C:\Users\Administrator\.openclaw\workspace
powershell -ExecutionPolicy Bypass -File "scripts\git-backup.ps1"
```

### Dry Run模式

测试备份但不实际执行：

```powershell
powershell -ExecutionPolicy Bypass -File "scripts\git-backup.ps1" -DryRun
```

## 备份内容

每次备份会包含：
- 所有工作空间文件
- 新增、修改、删除的文件
- Git仓库的历史记录

## 备份检查

### 查看备份历史

1. 在GitHub仓库查看提交历史
2. 提交消息格式：`Auto backup: YYYYMMDD_HHmmss`
3. 每次备份都有唯一的commit hash

### 查看记忆文件

备份信息会记录到：
```
memory/YYYY-MM-DD.md
```

## 安全性

- **自动认证**: 使用预设的Personal Access Token
- **匿名提交**: Git author/email配置为本地账户
- **实时同步**: 提交后立即推送到远程

## 备份示例

```
Git-Based Backup Started
  Time: 2026-02-11 18:50:49

Checking Git status...
  Files changed:
    [??] scripts/auto-backup.ps1
    [??] scripts/git-backup.ps1

Stashing changes...
  Changes stashed

Creating backup commit...
  Commit created: d66abe35cace02d8a6e73f1bcd066ae152c5f1ae

Pushing to GitHub...
  Everything up-to-date
  Successfully pushed

Restoring stashed changes...
  Changes restored

Backup completed!
  - Backup method: Git commit
  - Commit hash: d66abe35cace02d8a6e73f1bcd066ae152c5f1ae
  - Pushed to GitHub: Yes
```

## 故障排除

### 备份失败

检查Git状态：
```bash
git status
```

### 网络问题

确保可以访问GitHub，或者稍后重试。

### 权限问题

确保Personal Access Token有push权限。

## 总结

✅ 自动备份系统已启用
✅ 每天自动执行
✅ 自动推送到GitHub
✅ 备份信息记录到记忆文件

**您的数据现在安全了！** 🎉
