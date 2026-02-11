# 常见问题 FAQ

**灵眸系统常见问题解答**
**版本**: 1.0.0
**更新日期**: 2026-02-11

---

## 📋 目录

1. [安装和配置](#安装和配置)
2. [使用问题](#使用问题)
3. [性能问题](#性能问题)
4. [错误处理](#错误处理)
5. [高级功能](#高级功能)
6. [故障排除](#故障排除)

---

## 安装和配置

### Q1: 系统安装失败怎么办？

**A**: 请按照以下步骤排查：

1. **检查系统要求**
   ```bash
   # 检查PowerShell版本
   $PSVersionTable.PSVersion

   # 检查Git
   git --version
   ```

2. **检查环境变量**
   ```bash
   . .env-loader.ps1
   echo $GATEWAY_PORT
   ```

3. **检查端口占用**
   ```bash
   netstat -ano | findstr "18789"
   ```

4. **查看错误日志**
   ```bash
   Get-Content logs/nightly-evolution-*.log -Tail 50
   ```

### Q2: 如何修改Gateway端口？

**A**: 按照以下步骤操作：

1. **编辑端口配置文件**
   ```bash
   nano .ports.env
   ```

2. **修改端口值**
   ```env
   GATEWAY_PORT=8080  # 改为你想要的端口
   ```

3. **重启Gateway**
   ```bash
   openclaw gateway restart
   ```

4. **更新环境变量**
   ```bash
   . .env-loader.ps1
   ```

### Q3: 环境变量不生效怎么办？

**A**:

1. **确保正确加载**
   ```bash
   . .env-loader.ps1
   ```

2. **验证变量**
   ```bash
   echo $GATEWAY_PORT
   echo $BACKUP_PATH
   ```

3. **如果仍然不生效，手动设置**
   ```bash
   $env:GATEWAY_PORT = "18789"
   ```

### Q4: 如何备份系统？

**A**:

**方法1: 使用自动备份**
```bash
powershell -ExecutionPolicy Bypass -File "scripts/daily-backup.ps1"
```

**方法2: 手动备份**
```bash
# 停止服务
openclaw gateway stop

# 备份整个工作空间
robocopy . backup\$(Get-Date -Format "yyyyMMddHHmmss") /E

# 启动服务
openclaw gateway start
```

**方法3: 使用Git备份**
```bash
git add .
git commit -m "Manual backup"
git push
```

---

## 使用问题

### Q5: 脚本执行时提示"执行策略错误"？

**A**:

**方法1: 使用 -ExecutionPolicy 参数（推荐）**
```bash
powershell -ExecutionPolicy Bypass -File "scripts/xxx.ps1"
```

**方法2: 临时更改策略**
```bash
Set-ExecutionPolicy RemoteSigned -Scope Process
powershell -ExecutionPolicy Bypass -File "scripts/xxx.ps1"
Set-ExecutionPolicy Default -Scope Process
```

**方法3: 使用Git Bash**
```bash
powershell.exe -ExecutionPolicy Bypass -File "scripts/xxx.ps1"
```

### Q6: 如何查看系统状态？

**A**:

**方法1: 使用openclaw命令**
```bash
openclaw status
openclaw gateway status
```

**方法2: 使用健康检查脚本**
```bash
powershell -ExecutionPolicy Bypass -File "scripts/simple-health-check.ps1"
```

**方法3: 查看日志文件**
```bash
# 查看最近日志
Get-Content logs/nightly-evolution-*.log -Tail 50

# 查看JSON日志
Get-Content logs/nightly-evolution-*.json | ConvertFrom-Json
```

### Q7: 如何运行特定模块？

**A**:

```bash
# 使用集成管理器
powershell -ExecutionPolicy Bypass -File "scripts/integration-manager.ps1" -Module Nightly
powershell -ExecutionPolicy Bypass -File "scripts/integration-manager.ps1" -Module HealthCheck

# 直接运行脚本
powershell -ExecutionPolicy Bypass -File "scripts/nightly-evolution.ps1"
powershell -ExecutionPolicy Bypass -File "scripts/simple-health-check.ps1"
```

### Q8: 如何自定义任务调度？

**A**:

1. **编辑任务定义文件**
   ```bash
   nano tasks/scheduler-tasks.json
   ```

2. **添加或修改任务**
   ```json
   {
     "tasks": [
       {
         "id": "daily-backup",
         "name": "Daily Backup",
         "command": "powershell -ExecutionPolicy Bypass -File scripts/daily-backup.ps1",
         "schedule": "0 2 * * *",
         "enabled": true
       }
     ]
   }
   ```

3. **重启调度器**
   ```bash
   powershell -ExecutionPolicy Bypass -File "scripts/automation/smart-task-scheduler.ps1"
   ```

---

## 性能问题

### Q9: 系统响应慢怎么办？

**A**:

**步骤1: 检查系统资源**
```bash
powershell -ExecutionPolicy Bypass -File "scripts/simple-health-check.ps1"
```

**步骤2: 运行性能优化**
```bash
powershell -ExecutionPolicy Bypass -File "scripts/automation/performance-optimizer.ps1"
```

**步骤3: 检查进程**
```bash
# 查看内存使用
Get-Process | Sort-Object Memory -Descending | Select-Object -First 10

# 查看CPU使用
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10
```

**步骤4: 重启服务**
```bash
openclaw gateway restart
```

### Q10: 如何清理磁盘空间？

**A**:

**方法1: 清理临时文件**
```bash
# 清理临时脚本
Remove-Item temp-*.ps1 -Force

# 清理会话缓存
Remove-Item .session -Recurse -Force
```

**方法2: 清理旧日志**
```bash
powershell -ExecutionPolicy Bypass -File "scripts/cleanup-logs.ps1"
```

**方法3: 清理旧备份**
```bash
# 保留最近7个备份
powershell -ExecutionPolicy Bypass -File "scripts/cleanup-logs.ps1"
```

### Q11: 如何监控性能指标？

**A**:

**方法1: 使用性能基准测试**
```bash
powershell -ExecutionPolicy Bypass -File "scripts/performance-benchmark.ps1"
```

**方法2: 查看历史数据**
```bash
Get-ChildItem "reports/performance-benchmark-*.json" | Sort-Object LastWriteTime -Descending
```

**方法3: 实时监控**
```bash
# 持续运行健康检查
while ($true) {
  powershell -ExecutionPolicy Bypass -File "scripts/simple-health-check.ps1"
  Start-Sleep -Seconds 60
}
```

---

## 错误处理

### Q12: 出现错误时如何调试？

**A**:

**步骤1: 查看错误日志**
```bash
Get-Content logs/nightly-evolution-*.log -Tail 100
```

**步骤2: 检查错误数据库**
```bash
Get-Content error-database.json | ConvertFrom-Json
```

**步骤3: 运行诊断脚本**
```bash
powershell -ExecutionPolicy Bypass -File "scripts/diagnose.ps1"
```

**步骤4: 查看详细输出**
```bash
# 添加 -Verbose 参数
powershell -ExecutionPolicy Bypass -File "scripts/xxx.ps1" -Verbose
```

### Q13: 如何处理传输阻塞？

**A**:

**解决方案1: 增加重试次数**
```bash
# 在配置文件中设置
"retry_attempts": 5
```

**解决方案2: 添加延迟**
```bash
"retry_delay": "5000"  # 5秒延迟
```

**解决方案3: 启用缓存**
```bash
"cache_enabled": true
```

### Q14: 错误自动修复失败怎么办？

**A**:

**步骤1: 查看修复日志**
```bash
Get-Content logs/repair-*.log
```

**步骤2: 手动修复**
```bash
# 根据错误类型执行相应命令
# 参考错误数据库了解修复策略
```

**步骤3: 禁用自动修复**
```bash
# 在配置中禁用
"auto_repair_enabled": false
```

---

## 高级功能

### Q15: 如何使用技能集成？

**A**:

**方法1: 使用技能管理器**
```bash
powershell -ExecutionPolicy Bypass -File "scripts/skill-integration/skill-manager.ps1"
```

**方法2: 直接调用技能**
```bash
# Code Mentor
powershell -ExecutionPolicy Bypass -File "scripts/skill-integration/code-mentor-integration.ps1"

# Git Essentials
powershell -ExecutionPolicy Bypass -File "scripts/skill-integration/git-essentials-integration.ps1"
```

**方法3: 通过命令行**
```bash
# 代码审查
code-review -File "example.ps1"

# Git状态
git-status --short
```

### Q16: 如何配置告警通知？

**A**:

**步骤1: 编辑监控配置**
```bash
nano config/monitoring.json
```

**步骤2: 设置告警阈值**
```json
{
  "alert_enabled": true,
  "alert_channels": ["telegram", "email"],
  "alert_threshold": {
    "memory": 90,
    "disk": 85,
    "error_rate": 5
  }
}
```

**步骤3: 测试告警**
```bash
# 触发告警测试
powershell -ExecutionPolicy Bypass -File "scripts/test-alert.ps1"
```

### Q17: 如何创建自定义任务？

**A**:

**步骤1: 编辑任务定义**
```bash
nano tasks/scheduler-tasks.json
```

**步骤2: 添加任务**
```json
{
  "tasks": [
    {
      "id": "my-task",
      "name": "My Custom Task",
      "command": "echo 'Hello from custom task'",
      "schedule": "0 */6 * * *",
      "enabled": true
    }
  ]
}
```

**步骤3: 测试任务**
```bash
powershell -ExecutionPolicy Bypass -File "scripts/automation/smart-task-scheduler.ps1"
```

---

## 故障排除

### Q18: 系统无法启动怎么办？

**A**:

**步骤1: 检查端口占用**
```bash
netstat -ano | findstr "18789"
```

**步骤2: 检查进程**
```bash
Get-Process | Where-Object {$_.ProcessName -like "*openclaw*"}
```

**步骤3: 查看错误日志**
```bash
Get-Content logs/*.log | Select-String -Pattern "error" -Context 2
```

**步骤4: 重启服务**
```bash
openclaw gateway stop
Start-Sleep -Seconds 5
openclaw gateway start
```

### Q19: 如何完全卸载系统？

**A**:

**警告**: 此操作不可逆！请确保已备份！

```bash
# 1. 停止服务
openclaw gateway stop

# 2. 删除工作空间（先备份！）
# rm -rf C:\Users\Administrator\.openclaw\workspace

# 3. 删除配置（可选）
# 删除 .env 和 .ports.env
```

### Q20: 如何升级系统版本？

**A**:

**步骤1: 拉取最新代码**
```bash
git pull origin master
```

**步骤2: 检查新版本**
```bash
git tag
```

**步骤3: 运行升级脚本**
```bash
powershell -ExecutionPolicy Bypass -File "scripts/upgrade.ps1"
```

**步骤4: 验证升级**
```bash
openclaw status
```

---

## 💬 还需要帮助？

如果以上答案无法解决你的问题：

1. **查看详细文档**: [TUTORIALS.md](TUTORIALS.md)
2. **查看API文档**: [API_DOCUMENTATION.md](API_DOCUMENTATION.md)
3. **查看部署指南**: [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
4. **提交Issue**: [GitHub Issues](https://github.com/jiao360124/AE8F88/issues)

---

**FAQ版本**: 1.0.0
**最后更新**: 2026-02-11
