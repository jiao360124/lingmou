# OpenClaw 故障排除手册

本文档提供了OpenClaw系统的故障排除指南。

---

## 📋 目录

1. [常见问题](#常见问题)
2. [系统问题](#系统问题)
3. [网络问题](#网络问题)
4. [数据库问题](#数据库问题)
5. [性能问题](#性能问题)
6. [API问题](#api问题)
7. [备份问题](#备份问题)
8. [日志分析](#日志分析)

---

## 常见问题

### 1. Gateway启动失败

**症状**:
```
Error: Cannot start Gateway: Port 8080 already in use
```

**原因**: 端口被占用

**解决方案**:

```powershell
# Windows
netstat -ano | findstr :8080
taskkill /PID <PID> /F

# Linux/macOS
lsof -i :8080
kill -9 <PID>
```

**验证**:
```bash
openclaw status
```

---

### 2. 认证失败

**症状**:
```
Error: 401 Unauthorized
```

**原因**: API Token无效

**解决方案**:

```bash
# 检查Token
cat .env | grep GATEWAY_TOKEN

# 重新生成Token
# 1. 登录系统
# 2. 访问设置页面
# 3. 生成新的API Token
# 4. 更新.env文件

# 测试Token
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:8080/api/health
```

---

### 3. 连接超时

**症状**:
```
Error: Connection timeout after 30s
```

**原因**: 网络问题或服务未启动

**解决方案**:

```powershell
# 检查服务状态
openclaw status

# 检查网络连接
Test-Connection -ComputerName localhost -Count 3

# 检查端口
netstat -ano | findstr :8080

# 查看日志
Get-Content logs\openclaw.log -Tail 50
```

---

## 系统问题

### 1. 内存不足

**症状**:
```
Error: Out of memory
```

**原因**: 内存使用过高

**解决方案**:

```powershell
# 查看内存使用
Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 5

# 运行内存优化
.\scripts\memory-optimizer.ps1 -Detailed

# 清理缓存
.\scripts\clear-cache.ps1

# 增加内存限制
# 编辑 .env
MEMORY_LIMIT=1024  # 1GB
```

**监控内存**:
```powershell
while ($true) {
    $process = Get-Process -Id $PID
    $memoryMB = [math]::Round($process.WorkingSet64 / 1MB, 2)
    Write-Host "$(Get-Date) Memory: ${memoryMB}MB"
    Start-Sleep -Seconds 10
}
```

---

### 2. 磁盘空间不足

**症状**:
```
Error: No space left on device
```

**原因**: 磁盘空间已满

**解决方案**:

```powershell
# 检查磁盘使用
Get-PSDrive C

# 清理日志
.\scripts\cleanup-logs-manual.ps1

# 清理临时文件
Remove-Item -Path $env:TEMP\* -Recurse -Force

# 清理备份（保留最近7天）
.\scripts\cleanup-backup.ps1 -RetentionDays 7
```

**磁盘清理脚本**:
```powershell
# 清理脚本
$RetentionDays = 7
$LogDir = "logs"
$BackupDir = "backup"

# 清理日志
Get-ChildItem $LogDir -Filter "*.log" |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$RetentionDays) } |
    Remove-Item

# 清理旧备份
Get-ChildItem $BackupDir -Filter "*.zip" |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$RetentionDays) } |
    Remove-Item
```

---

### 3. 进程崩溃

**症状**:
```
Process exited with code 1
```

**原因**: 应用程序错误

**解决方案**:

```powershell
# 查看错误日志
Get-Content logs\error.log -Tail 100

# 检查系统日志
Get-EventLog -LogName Application -Source "OpenClaw" -Newest 10

# 重启服务
openclaw restart

# 检查配置文件
# 确保所有必需的配置项都存在
Get-Content .env

# 验证配置
.\scripts\validate-config.ps1
```

---

## 网络问题

### 1. 防火墙阻止

**症状**:
```
Error: Connection refused
```

**原因**: 防火墙阻止连接

**解决方案**:

```powershell
# Windows防火墙
# 允许端口8080
New-NetFirewallRule -DisplayName "OpenClaw" -Direction Inbound -Protocol TCP -LocalPort 8080 -Action Allow

# 检查防火墙规则
Get-NetFirewallRule -DisplayName "OpenClaw" | Format-List

# Linux防火墙
sudo ufw allow 8080/tcp
sudo firewall-cmd --add-port=8080/tcp --permanent
sudo firewall-cmd --reload

# macOS防火墙
sudo pfctl -e
sudo pfctl -f /etc/pf.conf
```

---

### 2. DNS解析失败

**症状**:
```
Error: DNS resolution failed
```

**原因**: DNS配置问题

**解决方案**:

```bash
# 检查DNS配置
ipconfig /all

# 测试DNS解析
nslookup localhost

# 刷新DNS缓存
ipconfig /flushdns

# 更新hosts文件
# Windows: C:\Windows\System32\drivers\etc\hosts
# Linux: /etc/hosts
```

---

### 3. SSL证书问题

**症状**:
```
Error: SSL certificate verification failed
```

**原因**: SSL证书无效或过期

**解决方案**:

```bash
# 检查证书
openssl s_client -connect localhost:8080 -showcerts

# 更新证书
# 1. 获取新证书
# 2. 更新证书文件
# 3. 重启服务

# 临时禁用验证（不推荐用于生产）
# 编辑 .env
ENABLE_SSL_VERIFICATION=false
```

---

## 数据库问题

### 1. 连接池耗尽

**症状**:
```
Error: Connection pool exhausted
```

**原因**: 数据库连接数达到上限

**解决方案**:

```sql
-- 检查连接数
SELECT count(*) FROM pg_stat_activity WHERE datname = 'openclaw';

-- 杀掉空闲连接
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE state = 'idle'
AND state_change < NOW() - INTERVAL '10 minutes';

-- 增加连接池大小
-- 编辑 .env
CONNECTION_POOL_SIZE=100
```

---

### 2. 查询超时

**症状**:
```
Error: Query timeout after 30s
```

**原因**: 查询执行时间过长

**解决方案**:

```sql
-- 检查慢查询
SELECT query, mean_exec_time, calls
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;

-- 优化查询
EXPLAIN ANALYZE
SELECT * FROM large_table WHERE created_at > '2026-01-01';

-- 添加索引
CREATE INDEX idx_large_table_created_at ON large_table(created_at);

-- 增加查询超时
-- 编辑配置
QUERY_TIMEOUT=60
```

---

### 3. 数据库锁定

**症状**:
```
Error: Database is locked
```

**原因**: 长事务或死锁

**解决方案**:

```sql
-- 检查锁
SELECT * FROM pg_stat_activity WHERE query LIKE '%SELECT%';

-- 杀掉锁定的会话
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE pid = <blocked_pid>;

-- 检查死锁
SELECT * FROM pg_stat_database_conflicts;

-- 分析死锁
SELECT * FROM pg_locks;
```

---

## 性能问题

### 1. 响应缓慢

**症状**:
```
Response time > 1s
```

**原因**: 系统性能瓶颈

**排查步骤**:

```powershell
# 1. 检查系统资源
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10

# 2. 检查数据库
# 检查慢查询
# 检查索引覆盖率

# 3. 检查缓存
.\scripts\check-cache.ps1

# 4. 运行性能测试
.\scripts\performance-benchmark.ps1 -Detailed

# 5. 查看日志
Get-Content logs\slow.log -Tail 100
```

**优化建议**:

```bash
# 增加并发连接
MAX_CONCURRENT_REQUESTS=20

# 增加缓存大小
CACHE_MAX_SIZE=200MB

# 优化数据库查询
CREATE INDEX idx_queries ...

# 启用压缩
ENABLE_COMPRESSION=true
```

---

### 2. 高CPU使用率

**症状**:
```
CPU usage > 80%
```

**原因**: CPU密集型任务

**解决方案**:

```bash
# 检查CPU密集型进程
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10

# 检查定时任务
Get-ScheduledTask

# 检查日志轮转
.\scripts\check-log-rotation.ps1

# 减少并发
MAX_CONCURRENT_REQUESTS=5

# 优化算法
# 重构低效代码
```

---

### 3. 内存泄漏

**症状**:
```
Memory usage increases over time
```

**原因**: 内存泄漏

**排查**:

```powershell
# 监控内存
while ($true) {
    $process = Get-Process -Id $PID
    $memoryMB = [math]::Round($process.WorkingSet64 / 1MB, 2)
    Write-Host "$(Get-Date) Memory: ${memoryMB}MB"
    Start-Sleep -Seconds 10
}

# 检查大对象
Get-Process | Where-Object { $_.WorkingSet64 -gt 100MB } | Select-Object Name, @{Name='MemoryMB';Expression={[math]::Round($_.WorkingSet64/1MB,2)}}

# 检查未释放的资源
Get-ChildItem *.log | ForEach-Object {
    $lines = (Get-Content $_.FullName | Measure-Object -Line).Lines
    Write-Host "$($_.Name): $lines lines"
}

# 清理内存
[GC]::Collect()
```

---

## API问题

### 1. 404 Not Found

**症状**:
```
Error: 404 Not Found
```

**原因**: API端点不存在

**解决方案**:

```bash
# 检查API文档
curl http://localhost:8080/api/docs

# 检查URL拼写
curl http://localhost:8080/api/health

# 检查路由配置
# 查看路由表
```

---

### 2. 429 Too Many Requests

**症状**:
```
Error: 429 Too Many Requests
```

**原因**: 速率限制

**解决方案**:

```bash
# 检查速率限制配置
cat .env | grep RATE_LIMIT

# 实现指数退避
# 参考API使用指南

# 增加速率限制
RATE_LIMIT_REQUESTS=1000
RATE_LIMIT_WINDOW=60
```

---

### 3. 500 Internal Server Error

**症状**:
```
Error: 500 Internal Server Error
```

**原因**: 服务器内部错误

**解决方案**:

```bash
# 查看错误日志
Get-Content logs\error.log -Tail 100

# 检查系统状态
openclaw status

# 检查数据库连接
.\scripts\check-database.ps1

# 重启服务
openclaw restart

# 验证配置
.\scripts\validate-config.ps1
```

---

## 备份问题

### 1. 备份失败

**症状**:
```
Error: Backup failed
```

**原因**: 备份过程中出现错误

**解决方案**:

```powershell
# 检查备份日志
Get-Content logs\backup.log -Tail 100

# 手动运行备份
.\scripts\git-backup.ps1 -Verbose

# 检查Git状态
git status

# 检查权限
Test-Path .git

# 验证备份
.\scripts\verify-backup.ps1
```

---

### 2. 备份文件损坏

**症状**:
```
Error: Backup file corrupted
```

**原因**: 备份文件损坏

**解决方案**:

```powershell
# 检查备份文件
Get-ChildItem backup\ -Filter "*.zip"

# 验证备份
.\scripts\verify-backup.ps1

# 恢复备份
.\scripts\restore-backup.ps1 -BackupId backup-20260214-001

# 重新创建备份
.\scripts\git-backup.ps1 -CommitMessage "Emergency backup"
```

---

### 3. 备份保留策略

**症状**:
```
Error: Too many backup files
```

**原因**: 备份文件过多

**解决方案**:

```powershell
# 清理旧备份
.\scripts\cleanup-backup.ps1 -RetentionDays 7

# 调整保留策略
# 编辑 .env
BACKUP_RETENTION_DAYS=7

# 查看备份列表
.\scripts\list-backups.ps1
```

---

## 日志分析

### 1. 查看日志

```powershell
# 查看所有日志
Get-Content logs\*.log

# 查看最近日志
Get-Content logs\*.log -Tail 100

# 实时监控
Get-Content logs\openclaw.log -Wait -Tail 50

# 搜索日志
Select-String -Path logs\*.log -Pattern "ERROR" -Context 2,2
```

---

### 2. 日志分析脚本

```powershell
# 日志分析脚本
$logs = Get-Content logs\*.log -Tail 1000

# 错误统计
$errors = $logs | Select-String "ERROR" | Measure-Object
$warnings = $logs | Select-String "WARNING" | Measure-Object
$info = $logs | Select-String "INFO" | Measure-Object

Write-Host "Errors: $($errors.Count)"
Write-Host "Warnings: $($warnings.Count)"
Write-Host "Info: $($info.Count)"

# 错误详情
$logs | Select-String "ERROR" | ForEach-Object {
    $line = $_.Line
    $timestamp = $line.Split()[0]
    Write-Host "[$timestamp] $_"
}
```

---

### 3. 日志轮转

```bash
# 配置logrotate
sudo vim /etc/logrotate.d/openclaw

# 内容:
/path/to/logs/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0644 openclaw openclaw
}
```

---

## 获取帮助

### 联系支持

- **文档**: https://docs.openclaw.ai
- **GitHub**: https://github.com/openclaw/openclaw/issues
- **Discord**: https://discord.com/invite/clawd
- **Email**: support@openclaw.ai

### 提交Issue

在提交问题之前：

1. 收集信息：
   - 错误消息
   - 日志文件
   - 系统配置
   - 复现步骤

2. 搜索现有Issue：
   - https://github.com/openclaw/openclaw/issues

3. 提交新Issue：
   - 描述问题
   - 提供日志
   - 提供配置
   - 提供复现步骤

---

**版本**: 1.0.0
**最后更新**: 2026-02-14
**维护者**: OpenClaw Team
