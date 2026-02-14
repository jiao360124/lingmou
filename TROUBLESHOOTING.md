# 故障排除指南

**版本**: 1.0
**最后更新**: 2026-02-14
**维护者**: 灵眸

---

## 📚 目录

1. [常见问题](#常见问题)
2. [Gateway故障](#gateway故障)
3. [API故障](#api故障)
4. [Cron任务故障](#cron任务故障)
5. [性能问题](#性能问题)
6. [安全问题](#安全问题)
7. [日志分析](#日志分析)
8. [恢复步骤](#恢复步骤)

---

## 常见问题

### 1. 无法连接到Gateway

**症状**:
```
Error: Connection refused
```

**排查步骤**:

```powershell
# 1. 检查Gateway是否运行
Get-Process -Name "openclaw" -ErrorAction SilentlyContinue

# 2. 检查端口监听
netstat -ano | findstr "18789"

# 3. 检查防火墙
netsh advfirewall firewall show rule name=all | findstr "18789"

# 4. 检查日志
Get-Content $env:APPDATA\openclaw\logs\gateway.log -Tail 50
```

**解决方案**:

```bash
# 重启Gateway
openclaw gateway restart

# 或手动启动
openclaw gateway start
```

### 2. API Key无效

**症状**:
```
Error: UNAUTHORIZED - Invalid API key
```

**排查步骤**:

```bash
# 检查API Key配置
cat .env | grep API_KEY

# 验证API Key格式
curl -H "Authorization: Bearer YOUR_API_KEY" \
  http://localhost:18789/api/v1/system/status
```

**解决方案**:

1. 重新生成API Key
2. 检查Key格式（Bearer前缀）
3. 确认Key未过期

### 3. 会话超时

**症状**:
```
Error: SESSION_EXPIRED
```

**解决方案**:

```json
{
  "session": {
    "timeout": 300,  // 5分钟
    "renewOnActivity": true
  }
}
```

---

## Gateway故障

### Gateway启动失败

**症状**:
```
Failed to start Gateway: Port 18789 already in use
```

**排查步骤**:

```powershell
# 1. 查找占用端口的进程
netstat -ano | findstr "18789"

# 2. 终止占用进程
taskkill /PID <PID> /F

# 3. 重新启动Gateway
openclaw gateway start
```

### Gateway崩溃

**症状**:
```
Gateway process terminated unexpectedly
```

**排查步骤**:

```bash
# 检查崩溃日志
cat $env:APPDATA\openclaw\logs\gateway-crash.log

# 检查错误堆栈
cat $env:APPDATA\openclaw\logs\gateway-error.log
```

**解决方案**:

1. 更新到最新版本
2. 检查系统资源
3. 查看详细错误日志
4. 联系技术支持

---

## API故障

### 请求超时

**症状**:
```
Error: Request timeout (30s)
```

**解决方案**:

```bash
# 增加超时时间
curl --max-time 60 \
  http://localhost:18789/api/v1/system/status

# 或在配置中设置
{
  "timeout": {
    "global": 60,
    "perRequest": 30
  }
}
```

### 速率限制

**症状**:
```
Error: RATE_LIMIT_EXCEEDED
```

**解决方案**:

```python
import time

def request_with_retry(func, max_retries=3):
    for attempt in range(max_retries):
        try:
            return func()
        except RateLimitError:
            wait_time = 2 ** attempt  # 指数退避
            print(f"Rate limited. Waiting {wait_time}s...")
            time.sleep(wait_time)
    raise Exception("Max retries exceeded")
```

---

## Cron任务故障

### Cron任务未执行

**症状**:
```
Cron job not running despite schedule
```

**排查步骤**:

```powershell
# 检查Cron服务状态
Get-Service | Where-Object {$_.Name -like '*openclaw*'}

# 查看Cron配置
Get-Content C:\Users\Administrator\.openclaw\cron\jobs.json

# 检查Cron日志
Get-Content $env:APPDATA\openclaw\logs\cron.log -Tail 50
```

**解决方案**:

```json
// 修正Cron任务配置
{
  "name": "daily-backup",
  "schedule": {
    "kind": "cron",
    "expr": "0 0 * * *",  // 每天0:00
    "timezone": "Asia/Shanghai"
  },
  "enabled": true
}
```

### Cron任务失败

**症状**:
```
Cron job failed: Task not found
```

**排查步骤**:

```bash
# 查看失败日志
cat $env:APPDATA\openclaw\logs\cron-failed.log

# 测试任务脚本
cd C:\Users\Administrator\.openclaw\workspace
.\scripts\backup.ps1 -DryRun
```

**解决方案**:

1. 检查脚本路径
2. 验证脚本权限
3. 查看详细错误
4. 启用错误报告

---

## 性能问题

### 系统变慢

**症状**:
- 响应时间增加
- 内存使用过高
- CPU占用率高

**排查步骤**:

```powershell
# 1. 检查系统资源
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10

# 2. 检查网络使用
netstat -ano | findstr ESTABLISHED | measure-object

# 3. 检查日志大小
Get-ChildItem $env:APPDATA\openclaw\logs\ -Recurse | Measure-Object -Property Length -Sum
```

**解决方案**:

1. 清理旧日志
2. 重启Gateway
3. 优化内存使用
4. 增加系统资源

### 内存泄漏

**症状**:
```
Memory usage increasing over time
```

**排查步骤**:

```python
# Python内存分析
import tracemalloc

tracemalloc.start()
main()  # 运行程序

snapshot = tracemalloc.take_snapshot()
top_stats = snapshot.statistics('lineno')
for stat in top_stats[:10]:
    print(stat)
```

**解决方案**:

1. 使用内存分析工具
2. 检查对象池实现
3. 定期清理缓存
4. 升级到内存优化版本

---

## 安全问题

### API Key泄露

**症状**:
```
API Key found in logs or repository
```

**解决方案**:

```bash
# 1. 立即撤销泄露的Key
# 登录Dashboard → API Keys → Revoke

# 2. 重新生成新Key
# Dashboard → API Keys → Generate New

# 3. 更新所有引用
git grep "OLD_API_KEY" .
git grep "SECRET_KEY" .

# 4. 更新配置文件
sed -i 's/OLD_API_KEY/NEW_API_KEY/' .env
```

### 未授权访问

**症状**:
```
Unauthorized access attempts detected
```

**解决方案**:

```bash
# 1. 检查访问日志
cat $env:APPDATA\openclaw\logs\access.log | grep "401"

# 2. 启用IP白名单
{
  "security": {
    "ipWhitelist": [
      "192.168.1.0/24",
      "10.0.0.0/8"
    ]
  }
}

# 3. 启用双因素认证
{
  "security": {
    "twoFactor": true
  }
}
```

---

## 日志分析

### 查看日志

```powershell
# Gateway日志
Get-Content $env:APPDATA\openclaw\logs\gateway.log -Tail 100

# Cron日志
Get-Content $env:APPDATA\openclaw\logs\cron.log -Tail 100

# 错误日志
Get-Content $env:APPDATA\openclaw\logs\*.error.log -Tail 100

# 所有日志
Get-ChildItem $env:APPDATA\openclaw\logs\ -Filter "*.log" |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 10
```

### 日志过滤

```bash
# 按级别过滤
grep "ERROR" $env:APPDATA\openclaw\logs\gateway.log
grep "WARN" $env:APPDATA\openclaw\logs\gateway.log

# 按时间过滤
grep "2026-02-14 22:" $env:APPDATA\openclaw\logs\gateway.log

# 搜索关键词
grep "timeout" $env:APPDATA\openclaw\logs\gateway.log
```

### 日志分析工具

```python
# Python日志分析
import re
from collections import Counter

with open('gateway.log', 'r') as f:
    logs = f.readlines()

# 统计错误数量
errors = [line for line in logs if 'ERROR' in line]
print(f"Total errors: {len(errors)}")

# 统计IP访问
ips = re.findall(r'(\d+\.\d+\.\d+\.\d+)', '\n'.join(logs))
print(f"Top 5 IPs: {Counter(ips).most_common(5)}")
```

---

## 恢复步骤

### 1. 基础恢复

```bash
# 1.1 检查系统状态
openclaw status

# 1.2 查看日志
cat $env:APPDATA\openclaw\logs\*.log

# 1.3 重启服务
openclaw gateway restart

# 1.4 验证功能
curl http://localhost:18789/api/v1/system/status
```

### 2. 深度恢复

```bash
# 2.1 备份当前状态
copy $env:APPDATA\openclaw\config\config.json backup\config-$(Get-Date -Format 'yyyyMMdd').json

# 2.2 清理缓存
rm -r $env:APPDATA\openclaw\cache\*

# 2.3 重启Gateway
openclaw gateway restart

# 2.4 检查Cron任务
openclaw cron list

# 2.5 运行诊断脚本
cd C:\Users\Administrator\.openclaw\workspace
.\scripts\diagnose-gateway-backup.ps1
```

### 3. 完全恢复

```bash
# 3.1 停止所有服务
openclaw gateway stop

# 3.2 备份重要数据
copy $env:APPDATA\openclaw\* backup\openclaw-$(Get-Date -Format 'yyyyMMdd-HHmmss')\*

# 3.3 卸载旧版本
npm uninstall openclaw

# 3.4 安装新版本
npm install -g openclaw@latest

# 3.5 重新配置
openclaw init

# 3.6 启动服务
openclaw gateway start

# 3.7 验证恢复
openclaw status
```

---

## 获取支持

### 联系方式

- **文档**: https://docs.openclaw.ai
- **GitHub**: https://github.com/openclaw/openclaw/issues
- **Discord**: https://discord.com/invite/clawd
- **邮件**: support@openclaw.ai

### 提交工单

1. 记录问题
2. 收集日志
3. 快照状态
4. 提交工单

**工单模板**:

```markdown
## 问题描述
[简要描述问题]

## 环境信息
- OS: Windows 10 Pro
- OpenClaw版本: 2026.2.13
- Node.js版本: v24.13.0

## 错误信息
[粘贴错误信息]

## 日志
[粘贴相关日志]

## 重现步骤
1. Step 1
2. Step 2
3. Step 3

## 期望结果
[期望的行为]
```

---

## 附录

### A. 日志文件列表

| 文件名 | 说明 |
|--------|------|
| gateway.log | Gateway主日志 |
| gateway-error.log | Gateway错误日志 |
| cron.log | Cron任务日志 |
| access.log | 访问日志 |
| performance.log | 性能日志 |
| security.log | 安全日志 |

### B. 常用命令

```bash
# 状态检查
openclaw status

# Gateway管理
openclaw gateway start
openclaw gateway stop
openclaw gateway restart

# Cron管理
openclaw cron list
openclaw cron run <job-id>

# 日志查看
openclaw logs --tail 100
openclaw logs --filter ERROR

# 配置管理
openclaw config get
openclaw config apply
```

---

**文档维护**: 灵眸
**最后更新**: 2026-02-14
**支持**: 如有问题，请联系技术支持
