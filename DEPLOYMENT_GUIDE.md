# OpenClaw 部署指南

## 版本信息

- **当前版本**: 1.0.0
- **发布日期**: 2026-02-11
- **部署指南版本**: 1.0

---

## 📚 目录

1. [部署概述](#部署概述)
2. [环境准备](#环境准备)
3. [安装部署](#安装部署)
4. [配置指南](#配置指南)
5. [启动服务](#启动服务)
6. [验证部署](#验证部署)
7. [生产环境部署](#生产环境部署)
8. [监控维护](#监控维护)
9. [故障排除](#故障排除)
10. [回滚方案](#回滚方案)

---

## 部署概述

### 支持的环境

OpenClaw支持以下部署环境：

| 环境 | 操作系统 | 说明 |
|------|---------|------|
| **开发环境** | Windows/Linux/macOS | 本地开发 |
| **测试环境** | Linux (Ubuntu 20.04+) | CI/CD测试 |
| **生产环境** | Linux (Ubuntu 20.04+) | 正式部署 |

### 部署架构

```
┌─────────────────────────────────────┐
│          用户/客户端                 │
└────────────────┬────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────┐
│         OpenClaw Gateway            │
│    (ws://host:18789)                │
└──────────────┬──────────────────────┘
               │
    ┌──────────┼──────────┐
    │          │          │
    ▼          ▼          ▼
┌───────┐  ┌───────┐  ┌───────┐
│Script │  │Script │  │Script │
│Module │  │Module │  │Module │
└───────┘  └───────┘  └───────┘
```

---

## 环境准备

### 最低系统要求

#### 硬件要求

| 资源 | 开发环境 | 测试环境 | 生产环境 |
|------|---------|---------|---------|
| CPU | 2核 | 4核 | 8核+ |
| 内存 | 4GB | 8GB | 16GB+ |
| 磁盘 | 20GB | 50GB | 100GB+ |

#### 软件要求

| 软件 | 版本 | 用途 |
|------|------|------|
| **操作系统** | Windows 10+ / Linux / macOS | 运行环境 |
| **PowerShell** | 5.1+ (Windows) | 脚本执行 |
| **Git** | 2.0+ | 版本控制 |
| **Node.js** | 18+ | 可选（Web客户端） |
| **Nginx** | 1.18+ (可选) | 反向代理 |

### 网络要求

- **端口**: 18789（Gateway端口）
- **带宽**: 10Mbps+（生产环境）
- **防火墙**: 需要开放18789端口

### 依赖项安装

#### Linux (Ubuntu)

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装Git
sudo apt install git -y

# 安装PowerShell (可选)
wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt update
sudo apt install -y powershell

# 安装Node.js (可选)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# 安装Nginx (可选)
sudo apt install nginx -y
```

#### macOS

```bash
# 安装Homebrew (如果未安装)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装Git
brew install git

# 安装PowerShell
brew install --cask powershell

# 安装Node.js
brew install node
```

#### Windows

```powershell
# 安装Git
winget install Git.Git

# 安装PowerShell
winget install Microsoft.PowerShell

# 安装Node.js (可选)
winget install OpenJS.NodeJS.LTS
```

---

## 安装部署

### 方式1: 手动安装

#### 步骤1: 克隆代码

```bash
git clone https://github.com/jiao360124/lingmou.git
cd lingmou
```

#### 步骤2: 配置环境

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑配置文件
nano .env
```

#### 步骤3: 验证环境

```bash
# 检查Git版本
git --version

# 检查PowerShell版本 (Windows)
powershell --version

# 检查Node版本 (如果安装了Node)
node --version
```

#### 步骤4: 加载环境变量

```bash
# PowerShell
. .\env-loader.ps1
```

```bash
# Bash
source ./.env-loader.sh
```

### 方式2: Docker部署 (推荐)

#### Dockerfile示例

```dockerfile
FROM mcr.microsoft.com/powershell:7

# 设置工作目录
WORKDIR /app

# 复制代码
COPY . .

# 安装依赖 (如果需要)
RUN apt-get update && apt-get install -y git

# 设置环境变量
ENV GATEWAY_PORT=18789

# 启动服务
CMD ["powershell", "-ExecutionPolicy", "Bypass", "-File", "scripts/integration-manager.ps1", "-Action", "status"]
```

#### 构建和运行

```bash
# 构建镜像
docker build -t openclaw:latest .

# 运行容器
docker run -d \
  --name openclaw \
  -p 18789:18789 \
  -v $(pwd)/data:/app/data \
  openclaw:latest
```

#### Docker Compose

```yaml
version: '3.8'

services:
  openclaw:
    build: .
    container_name: openclaw
    ports:
      - "18789:18789"
    volumes:
      - ./data:/app/data
      - ./logs:/app/logs
      - ./memory:/app/memory
      - ./backup:/app/backup
    environment:
      - GATEWAY_PORT=18789
      - LOG_LEVEL=info
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "powershell", "-Command", "Test-Path", "logs/gateway.log"]
      interval: 30s
      timeout: 10s
      retries: 3
```

```bash
# 启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

### 方式3: 自动部署 (CI/CD)

#### GitHub Actions示例

```yaml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v2

      - name: Setup environment
        run: |
          cp .env.example .env
          ./.env-loader.sh

      - name: Deploy to server
        run: |
          # 这里可以使用rsync、scp或其他部署工具
          rsync -avz --delete \
            ./user@server:/var/www/lingmou/

      - name: Restart service
        run: |
          ssh user@server "systemctl restart openclaw"
```

---

## 配置指南

### 环境变量配置

#### .env 文件

```env
# Gateway配置
GATEWAY_PORT=18789
GATEWAY_HOST=0.0.0.0

# Canvas配置
CANVAS_PORT=18789
CANVAS_HOST=0.0.0.0

# 日志配置
LOG_LEVEL=info
LOG_PATH=/app/logs
LOG_MAX_SIZE=100MB
LOG_MAX_AGE=7d

# 备份配置
MAX_BACKUPS=7
BACKUP_INTERVAL=24h

# 安全配置
AUTH_TOKEN=your_secure_token
JWT_SECRET=your_jwt_secret

# 性能配置
WORKER_THREADS=4
MAX_REQUEST_SIZE=10MB
```

### 端口配置

#### 统一端口

所有服务统一使用端口 `18789`：

```env
GATEWAY_PORT=18789
CANVAS_PORT=18789
```

### 反向代理配置 (Nginx)

#### Nginx配置

```nginx
upstream openclaw {
    server 127.0.0.1:18789;
    keepalive 64;
}

server {
    listen 80;
    server_name openclaw.example.com;

    # 重定向到HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name openclaw.example.com;

    # SSL证书
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    # SSL配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # 日志
    access_log /var/log/nginx/openclaw_access.log;
    error_log /var/log/nginx/openclaw_error.log;

    # 代理配置
    location / {
        proxy_pass http://openclaw;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # API端点
    location /api {
        proxy_pass http://openclaw/api;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

#### 启动Nginx

```bash
# 测试配置
sudo nginx -t

# 启动Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# 重载配置
sudo systemctl reload nginx
```

---

## 启动服务

### 开发环境

#### 前台运行

```bash
# 使用集成管理器
.\scripts\integration-manager.ps1 -Action health
```

#### 后台运行

```bash
# 使用PowerShell后台运行
Start-Process powershell -ArgumentList "-NoExit", "-File", ".\scripts\integration-manager.ps1"
```

### 生产环境

#### 使用Systemd (Linux)

**创建服务文件**:

```ini
[Unit]
Description=OpenClaw Integration Manager
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/var/www/lingmou
ExecStart=/usr/bin/powershell -ExecutionPolicy Bypass -File scripts/integration-manager.ps1 -Action status
Restart=on-failure
RestartSec=10

# 环境变量
Environment="GATEWAY_PORT=18789"
Environment="LOG_LEVEL=info"

# 资源限制
LimitNOFILE=65536
MemoryLimit=1G

[Install]
WantedBy=multi-user.target
```

**启动服务**:

```bash
# 复制服务文件
sudo cp openclaw.service /etc/systemd/system/

# 重新加载systemd
sudo systemctl daemon-reload

# 启动服务
sudo systemctl start openclaw

# 设置开机自启
sudo systemctl enable openclaw

# 查看状态
sudo systemctl status openclaw

# 查看日志
sudo journalctl -u openclaw -f
```

#### 使用Docker

```bash
# 启动容器
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

---

## 验证部署

### 健康检查

#### 方式1: 使用集成管理器

```powershell
.\scripts\integration-manager.ps1 -Action health
```

#### 方式2: 直接访问Gateway

```bash
# 测试Gateway连接
curl http://127.0.0.1:18789/health

# 测试WebSocket连接
wscat -c ws://127.0.0.1:18789
```

#### 方式3: 查看日志

```bash
# 查看Gateway日志
tail -f logs/gateway.log

# 查看Cron日志
tail -f logs/cron.log
```

### 功能测试

#### 测试1: 查看系统状态

```powershell
.\scripts\integration-manager.ps1 -Action status
```

#### 测试2: 测试备份功能

```powershell
.\scripts\git-backup.ps1
```

#### 测试3: 测试健康检查

```powershell
.\scripts\simple-health-check.ps1
```

#### 测试4: 检查Cron任务

```bash
openclaw cron list
```

---

## 生产环境部署

### 安全加固

#### 1. 防火墙配置

```bash
# Ubuntu/Debian
sudo ufw allow 18789/tcp
sudo ufw enable

# CentOS/RHEL
sudo firewall-cmd --permanent --add-port=18789/tcp
sudo firewall-cmd --reload
```

#### 2. SSL/TLS配置

使用Let's Encrypt：

```bash
# 安装Certbot
sudo apt install certbot python3-certbot-nginx -y

# 获取证书
sudo certbot --nginx -d openclaw.example.com

# 自动续期
sudo certbot renew --dry-run
```

#### 3. 身份认证

在Gateway配置中启用认证：

```env
# .env
GATEWAY_AUTH_ENABLED=true
GATEWAY_AUTH_TOKEN=your_secure_token
```

### 性能优化

#### 1. 资源限制

```ini
# Systemd配置
[Service]
MemoryLimit=1G
CPUQuota=200%
IOWeight=500

# Nginx配置
worker_processes auto;
worker_connections 1024;
```

#### 2. 缓存配置

```nginx
# Nginx缓存
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=openclaw_cache:10m max_size=1g inactive=60m;

location /api {
    proxy_cache openclaw_cache;
    proxy_cache_valid 200 5m;
}
```

### 监控配置

#### 1. 日志监控

```bash
# 安装logrotate
sudo apt install logrotate -y
```

**logrotate配置**:

```
/var/log/lingmou/*.log {
    daily
    rotate 30
    compress
    delaycompress
    notifempty
    create 0640 www-data www-data
    sharedscripts
    postrotate
        systemctl reload openclaw
    endscript
}
```

#### 2. 健康检查

```bash
# 添加到crontab
*/5 * * * * /usr/bin/powershell -File /path/to/health-check.ps1
```

#### 3. 监控工具

使用Prometheus + Grafana：

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'openclaw'
    static_configs:
      - targets: ['localhost:18789']
```

---

## 监控维护

### 日志管理

#### 日志位置

```
logs/
  ├── gateway.log       # Gateway日志
  ├── agent.log         # Agent日志
  ├── cron.log          # Cron任务日志
  └── error.log         # 错误日志
```

#### 日志轮转

```bash
# 自动轮转 (logrotate)
sudo logrotate -f /etc/logrotate.d/openclaw
```

### 备份策略

#### 自动备份

```bash
# Cron任务
0 2 * * * /usr/bin/powershell -ExecutionPolicy Bypass -File /app/scripts/git-backup.ps1
```

#### 备份验证

```bash
# 每周验证一次备份
0 3 * * 0 /usr/bin/powershell -File /app/scripts/verify-backup.ps1
```

### 更新维护

#### 更新步骤

```bash
# 1. 备份当前版本
cd /var/www/lingmou
git stash
git pull origin main
git stash pop

# 2. 验证环境
./scripts/integration-manager.ps1 -Action health

# 3. 重启服务
sudo systemctl restart openclaw

# 4. 检查日志
sudo journalctl -u openclaw -n 100
```

---

## 故障排除

### 常见问题

#### 问题1: Gateway无法启动

**症状**: Gateway服务启动失败

**解决方案**:

```bash
# 检查端口占用
sudo netstat -tulpn | grep 18789

# 检查防火墙
sudo ufw status

# 检查日志
sudo journalctl -u openclaw -n 50
```

#### 问题2: 权限错误

**症状**: 脚本执行权限不足

**解决方案**:

```bash
# 设置执行权限
chmod +x scripts/*.ps1
chmod +x scripts/*.sh

# 设置目录权限
sudo chown -R www-data:www-data /var/www/lingmou
```

#### 问题3: 内存泄漏

**症状**: 系统内存持续增长

**解决方案**:

```ini
# Systemd配置 - 内存限制
[Service]
MemoryLimit=1G

# 定期重启服务
[Service]
Restart=on-failure
RestartSec=10m
```

### 调试模式

#### 启用调试日志

```env
# .env
LOG_LEVEL=debug
```

#### 查看详细日志

```bash
# 查看最近100行日志
tail -n 100 logs/gateway.log

# 实时查看日志
tail -f logs/gateway.log

# 搜索错误
grep ERROR logs/gateway.log
```

---

## 回滚方案

### 快速回滚

```bash
# 1. 停止当前服务
sudo systemctl stop openclaw

# 2. 回滚到上一个版本
git reset --hard HEAD~1

# 3. 重新配置
cp .env.example .env
source ./.env-loader.sh

# 4. 启动服务
sudo systemctl start openclaw

# 5. 验证
sudo systemctl status openclaw
```

### 回滚检查清单

- [ ] 停止当前服务
- [ ] 备份当前版本
- [ ] 回滚到指定版本
- [ ] 重新配置环境变量
- [ ] 启动服务
- [ ] 验证功能正常
- [ ] 检查日志无错误
- [ ] 通知相关人员

---

## 总结

### 部署检查清单

**开发环境**:
- [ ] 环境配置完成
- [ ] 依赖项安装完成
- [ ] 代码部署完成
- [ ] 环境变量配置完成
- [ ] 服务启动成功
- [ ] 功能测试通过

**生产环境**:
- [ ] 环境准备完成
- [ ] 安全配置完成
- [ ] 反向代理配置完成
- [ ] 监控配置完成
- [ ] 备份策略配置完成
- [ ] 文档准备完成

---

**文档版本**: 1.0
**最后更新**: 2026-02-11
**维护者**: LingMou
