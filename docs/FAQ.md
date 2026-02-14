# OpenClaw 常见问题 (FAQ)

本文档解答了OpenClaw系统使用中常见的问题。

---

## 📋 目录

1. [安装和配置](#安装和配置)
2. [常见错误](#常见错误)
3. [性能问题](#性能问题)
4. [使用问题](#使用问题)
5. [API问题](#api问题)
6. [安全问题](#安全问题)

---

## 安装和配置

### Q1: 如何安装OpenClaw？

**A**: 有多种安装方式：

#### 使用npm安装（推荐）

```bash
npm install -g openclaw
```

#### 使用Homebrew安装（macOS）

```bash
brew install openclaw
```

#### 使用二进制文件安装

1. 下载对应平台的二进制文件
2. 解压到本地目录
3. 添加到PATH环境变量

#### 验证安装

```bash
openclaw --version
```

---

### Q2: 如何配置环境变量？

**A**: 有多种配置方式：

#### 方式1：使用.env文件

```bash
# 复制示例配置
cp .env.example .env

# 编辑配置文件
notepad .env
```

#### 方式2：命令行参数

```bash
openclaw --port=18789 --token=your_token
```

#### 方式3：系统环境变量

```bash
# Windows
set GATEWAY_TOKEN=your_token
set GATEWAY_PORT=18789

# Linux/macOS
export GATEWAY_TOKEN=your_token
export GATEWAY_PORT=18789
```

---

### Q3: 端口被占用怎么办？

**A**: 检查并释放端口：

#### 查看端口占用（Windows）

```powershell
netstat -ano | findstr :18789
```

#### 终止进程（Windows）

```powershell
taskkill /PID <进程ID> /F
```

#### 查看端口占用（Linux/macOS）

```bash
lsof -i :18789
```

#### 终止进程（Linux/macOS）

```bash
kill -9 <进程ID>
```

#### 或更改端口配置

```bash
# 使用其他端口
openclaw --port=18790

# 或在.env文件中配置
GATEWAY_PORT=18790
```

---

### Q4: 配置文件在哪里？

**A**: 配置文件位置：

- **默认位置**: `~/.openclaw/openclaw.json`
- **项目配置**: 项目根目录下的 `.env` 文件
- **自定义配置**: 可指定 `--config` 参数

**查看配置**:

```bash
openclaw config get
```

**验证配置**:

```bash
openclaw config validate
```

---

## 常见错误

### Q5: 出现"Permission denied"错误

**A**: 权限问题解决：

#### Linux/macOS

```bash
# 添加执行权限
chmod +x openclaw

# 使用sudo运行（不推荐）
sudo openclaw start

# 使用当前用户
./openclaw start
```

#### Windows

```powershell
# 右键运行PowerShell -> "以管理员身份运行"
```

---

### Q6: 提示"Module not found"

**A**: 模块缺失解决：

```bash
# 更新模块
openclaw update

# 查看已安装模块
openclaw modules list

# 重新安装
npm install openclaw
```

---

### Q7: 无法连接到Gateway

**A**: 连接问题排查：

```bash
# 1. 检查Gateway状态
openclaw status

# 2. 检查端口
netstat -ano | findstr :18789

# 3. 检查防火墙
# Windows: 允许端口18789
# Linux: sudo ufw allow 18789/tcp

# 4. 检查配置
cat .env | grep GATEWAY_URL

# 5. 重启服务
openclaw restart
```

---

### Q8: API Token无效

**A**: Token问题解决：

```bash
# 1. 重新生成Token
# 2. 登录系统
# 3. 访问设置页面
# 4. 生成新的API Token

# 5. 更新配置
echo "GATEWAY_TOKEN=your_new_token" >> .env

# 6. 测试连接
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:18789/api/health
```

---

## 性能问题

### Q9: 系统响应慢

**A**: 性能优化步骤：

```bash
# 1. 运行性能优化
.\scripts\performance-benchmark.ps1 -Detailed

# 2. 运行响应优化器
.\scripts\response-optimizer.ps1 -Detailed

# 3. 运行内存优化器
.\scripts\memory-optimizer.ps1 -Detailed

# 4. 检查缓存
.\scripts\check-cache.ps1

# 5. 查看慢查询
SELECT query, mean_exec_time FROM pg_stat_statements
ORDER BY mean_exec_time DESC LIMIT 10;

# 6. 检查系统资源
openclaw status
```

**优化配置**:

```bash
# 编辑.env文件
GATEWAY_PORT=18789
MAX_CONCURRENT_REQUESTS=10
REQUEST_TIMEOUT=30
CONNECTION_POOL_SIZE=50
```

---

### Q10: 内存使用过高

**A**: 内存优化：

```bash
# 1. 检查内存使用
Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 10

# 2. 运行内存优化器
.\scripts\memory-optimizer.ps1 -Detailed

# 3. 清理缓存
.\scripts\clear-cache.ps1

# 4. 增加内存限制
# 编辑.env
MEMORY_LIMIT=1024

# 5. 触发垃圾回收
[GC]::Collect()
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

### Q11: 磁盘空间不足

**A**: 磁盘清理：

```bash
# 1. 检查磁盘使用
Get-PSDrive C

# 2. 清理日志
.\scripts\cleanup-logs-manual.ps1

# 3. 清理备份
.\scripts\cleanup-backup.ps1 -RetentionDays 7

# 4. 清理临时文件
Remove-Item -Path $env:TEMP\* -Recurse -Force

# 5. 清理旧备份（保留最近7天）
# 编辑.env
BACKUP_RETENTION_DAYS=7
```

---

## 使用问题

### Q12: 如何启用技能？

**A**: 启用技能：

```bash
# 查看可用技能
openclaw skills list

# 启用技能
openclaw skills enable <skill-name>

# 示例
openclaw skills enable code-mentor
openclaw skills enable git-essentials

# 禁用技能
openclaw skills disable <skill-name>
```

**使用PowerShell**:

```powershell
$headers = @{
    "Authorization" = "Bearer $env:GATEWAY_TOKEN"
}

Invoke-RestMethod -Uri "http://localhost:18789/api/skills/code-mentor/enable" `
                  -Method Post -Headers $headers
```

---

### Q13: 如何创建备份？

**A**: 创建和恢复备份：

```bash
# 创建备份
openclaw backup create

# 查看备份列表
openclaw backup list

# 恢复备份
openclaw backup restore <backup-id>

# 验证备份
openclaw backup verify <backup-id>

# 清理旧备份
openclaw backup cleanup --retention 7
```

**使用API**:

```bash
curl -X POST http://localhost:18789/api/backup \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "full",
    "schedule": "daily"
  }'
```

---

### Q14: 如何查看日志？

**A**: 日志查看方法：

```bash
# 查看所有日志
Get-Content logs\*.log

# 查看最近100行
Get-Content logs\*.log -Tail 100

# 实时监控
Get-Content logs\*.log -Wait -Tail 50

# 搜索错误
Select-String -Path logs\*.log -Pattern "ERROR" -Context 2,2

# 按级别过滤
Select-String -Path logs\*.log -Pattern "ERROR"
Select-String -Path logs\*.log -Pattern "WARNING"
Select-String -Path logs\*.log -Pattern "INFO"
```

**日志轮转**:

```bash
# 编辑logrotate配置
sudo vim /etc/logrotate.d/openclaw

# 内容:
/path/to/logs/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
}
```

---

### Q15: 如何测试系统？

**A**: 测试系统方法：

```bash
# 健康检查
.\scripts\simple-health-check.ps1

# 集成测试
.\scripts\integration-test.ps1 -Detailed

# 压力测试
.\scripts\stress-test.ps1 -DurationSeconds 60 -Concurrency 10

# 错误恢复测试
.\scripts\error-recovery-test.ps1 -Detailed

# 性能测试
.\scripts\performance-benchmark.ps1 -Detailed
```

**API测试**:

```bash
# 系统健康
curl http://localhost:18789/api/health

# 集成测试
curl -X POST http://localhost:18789/api/integration/test

# 压力测试
curl -X POST http://localhost:18789/api/stress/test \
  -H "Content-Type: application/json" \
  -d '{"duration_seconds": 30}'
```

---

## API问题

### Q16: API返回404错误

**A**: 404错误解决：

```bash
# 1. 检查URL拼写
curl http://localhost:18789/api/health

# 2. 检查端点是否存在
# 参考API文档
# https://docs.openclaw.ai/api

# 3. 检查端口
netstat -ano | findstr :18789

# 4. 检查认证
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:18789/api/health
```

---

### Q17: API返回429错误

**A**: 速率限制解决：

```bash
# 1. 查看速率限制配置
cat .env | grep RATE_LIMIT

# 2. 实现指数退避
import time

for attempt in range(max_retries):
    try:
        response = requests.get(url)
        if response.status_code == 429:
            wait_time = (2 ** attempt) * 60
            time.sleep(wait_time)
            continue
    except Exception as e:
        pass

# 3. 增加速率限制
RATE_LIMIT_REQUESTS=1000
RATE_LIMIT_WINDOW=60
```

---

### Q18: API返回500错误

**A**: 500错误解决：

```bash
# 1. 查看错误日志
Get-Content logs\error.log -Tail 100

# 2. 检查系统状态
openclaw status

# 3. 检查数据库连接
.\scripts\check-database.ps1

# 4. 重启服务
openclaw restart

# 5. 验证配置
.\scripts\validate-config.ps1
```

---

## 安全问题

### Q19: 如何保护API Token？

**A**: Token安全最佳实践：

```bash
# 1. 不要在代码中硬编码Token
# ❌ 错误
TOKEN=abc123def456

# ✅ 正确
export GATEWAY_TOKEN=$(cat .env | grep GATEWAY_TOKEN | cut -d= -f2)

# 2. 使用环境变量
# 3. 使用配置文件（不提交到Git）
# 4. 定期更换Token
# 5. 使用最小权限原则
```

---

### Q20: 如何提高安全性？

**A**: 安全加固：

```bash
# 1. 启用HTTPS
ENABLE_SSL=true

# 2. 配置防火墙
sudo ufw allow 18789/tcp

# 3. 设置Token过期时间
TOKEN_EXPIRY=3600

# 4. 启用速率限制
RATE_LIMIT_REQUESTS=1000
RATE_LIMIT_WINDOW=60

# 5. 启用日志审计
ENABLE_AUDIT_LOG=true

# 6. 定期安全审计
openclaw security audit
```

---

### Q21: 如何备份Token？

**A**: Token备份策略：

```bash
# 1. 使用环境变量文件（不提交到Git）
cat > .env.local << EOF
GATEWAY_TOKEN=your_token_here
GATEWAY_URL=http://localhost:18789
EOF

# 2. 使用密钥管理服务
# AWS Secrets Manager
# HashiCorp Vault
# Azure Key Vault

# 3. 定期轮换Token
# 每月或每季度更换一次
```

---

## 高级问题

### Q22: 如何实现高可用？

**A**: 高可用配置：

```bash
# 1. 使用多个实例
# 2. 配置负载均衡
# 3. 使用Redis作为缓存
# 4. 配置数据库主从复制

# 示例：多个Gateway实例
# 实例1
openclaw --port=18789 --replica

# 实例2
openclaw --port=18790 --replica
```

---

### Q23: 如何监控性能？

**A**: 性能监控方案：

```bash
# 1. Prometheus + Grafana
# 2. 自定义监控脚本
# 3. 日志分析
# 4. 数据库性能监控

# 监控脚本示例
while true; do
    echo "$(date): CPU: $(top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | cut -d'%' -f1)%"
    echo "$(date): Memory: $(free -m | awk '/Mem:/{print $3}')MB / $(free -m | awk '/Mem:/{print $2}')MB"
    echo "$(date): Disk: $(df -h / | awk 'NR==2 {print $5}')"
    sleep 10
done
```

---

## 获取帮助

### Q24: 如何获取更多帮助？

**A**: 获取支持的渠道：

- **文档**: https://docs.openclaw.ai
- **GitHub Issues**: https://github.com/openclaw/openclaw/issues
- **Discord**: https://discord.com/invite/clawd
- **Email**: support@openclaw.ai
- **社区论坛**: https://community.openclaw.ai

---

### Q25: 如何提交问题？

**A**: 提交问题指南：

1. **搜索现有问题**: 避免重复
2. **收集信息**:
   - 错误消息
   - 日志文件
   - 系统配置
   - 复现步骤

3. **创建新Issue**:
   ```markdown
   ### 问题描述
   简要描述问题

   ### 环境信息
   - OS: Windows 10
   - OpenClaw Version: 1.0.0
   - Node.js: 16.14.0

   ### 错误消息
   错误消息内容

   ### 复现步骤
   1. ...
   2. ...

   ### 日志
   ```
   ```

4. **附上相关文件**:
   - 日志文件
   - 配置文件
   - 截图

---

## 更多资源

### 常用链接

- **官方文档**: https://docs.openclaw.ai
- **GitHub仓库**: https://github.com/openclaw/openclaw
- **问题追踪**: https://github.com/openclaw/openclaw/issues
- **Discord社区**: https://discord.com/invite/clawd
- **邮件支持**: support@openclaw.ai

### 文档导航

- **[API使用指南](API_GUIDE.md)** - API端点和示例
- **[性能调优手册](PERFORMANCE_TUNING.md)** - 性能优化指南
- **[故障排除手册](TROUBLESHOOTING.md)** - 问题排查指南
- **[示例代码](EXAMPLES.md)** - 代码示例
- **[迁移指南](../MIGRATION_GUIDE.md)** - 系统迁移指南

---

**版本**: 1.0.0
**最后更新**: 2026-02-14
**维护者**: OpenClaw Team
