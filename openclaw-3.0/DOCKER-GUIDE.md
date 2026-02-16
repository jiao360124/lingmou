# OpenClaw 3.0 Docker 部署指南

**版本**: 1.0
**更新日期**: 2026-02-16

---

## 📋 目录

- [前置要求](#前置要求)
- [快速开始](#快速开始)
- [配置说明](#配置说明)
- [常用命令](#常用命令)
- [健康检查](#健康检查)
- [故障排查](#故障排查)
- [更新升级](#更新升级)

---

## 前置要求

### 必需软件

1. **Docker** 20.10+
   - 下载: https://docs.docker.com/get-docker/
   - 安装后验证: `docker --version`

2. **Docker Compose** 2.0+
   - 下载: https://docs.docker.com/compose/install/
   - 或使用 Docker Desktop 内置的 Compose

3. **API 密钥**
   - OpenAI API Key
   - 或其他兼容的 API 密钥

---

## 快速开始

### 1. 克隆项目

```bash
git clone <repository-url>
cd openclaw-3.0
```

### 2. 配置环境变量

```bash
# 复制示例配置
cp .env.example .env

# 编辑配置
nano .env
```

**.env 文件示例**:
```env
API_BASE_URL=https://api.openai.com/v1
API_KEY=your_api_key_here
DAILY_BUDGET=200000
LOG_LEVEL=info
```

### 3. 一键部署

**Linux/Mac**:
```bash
chmod +x deploy.sh
./deploy.sh
```

**Windows**:
```cmd
deploy.bat
```

### 4. 访问 Dashboard

- **API**: http://localhost:18789
- **Dashboard UI**: http://localhost:3000

---

## 配置说明

### config.json

主要配置文件：

```json
{
  "apiBaseURL": "https://api.openai.com/v1",
  "dailyBudget": 200000,
  "turnThreshold": 10,
  "baseContextThreshold": 40000,
  "nightBudgetTokens": 50000,
  "nightBudgetCalls": 10
}
```

### docker-compose.yml

服务配置：

```yaml
services:
  openclaw:
    ports:
      - "18789:18789"  # Dashboard API
      - "3000:3000"    # Dashboard UI
    environment:
      - NODE_ENV=production
    volumes:
      - ./logs:/app/logs      # 日志目录
      - ./data:/app/data      # 数据目录
      - ./reports:/app/reports  # 报告目录
```

---

## 常用命令

### 服务管理

```bash
# 启动服务
docker-compose up -d

# 停止服务
docker-compose stop

# 重启服务
docker-compose restart

# 查看服务状态
docker-compose ps

# 查看服务日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f openclaw

# 进入容器
docker-compose exec openclaw sh
```

### 容器管理

```bash
# 删除服务
docker-compose down

# 删除服务和数据卷
docker-compose down -v

# 删除镜像
docker-compose down --rmi all

# 重新构建镜像
docker-compose build --no-cache

# 拉取最新镜像
docker-compose pull
```

### 备份与恢复

```bash
# 运行备份脚本
./backup.sh

# 回滚到指定版本
./rollback.sh
```

---

## 健康检查

Docker 会自动执行健康检查：

```bash
# 查看健康状态
docker-compose ps

# 手动测试 API
curl http://localhost:18789/api/status

# 查看健康检查日志
docker inspect openclaw-3.0 --format='{{json .State.Health}}' | jq
```

**健康检查间隔**: 30秒
**健康检查超时**: 3秒
**启动等待期**: 10秒
**重试次数**: 3次

---

## 故障排查

### 常见问题

#### 1. 端口被占用

**问题**: `Bind for 0.0.0.0:18789 failed: port is already allocated`

**解决**:
```bash
# 修改 docker-compose.yml 中的端口映射
ports:
  - "18790:18789"  # 使用不同端口
```

#### 2. 容器无法启动

**问题**: 容器退出代码非 0

**解决**:
```bash
# 查看容器日志
docker-compose logs openclaw

# 检查配置文件
cat config.json

# 重新构建镜像
docker-compose build --no-cache
```

#### 3. API 连接失败

**问题**: API 调用失败

**解决**:
```bash
# 检查 API 密钥
cat .env | grep API_KEY

# 测试 API 连接
curl https://api.openai.com/v1/models
```

#### 4. 数据卷权限问题

**问题**: 无法写入日志或数据文件

**解决**:
```bash
# 修改文件权限
chmod -R 755 data logs reports

# 或使用 root 用户
docker-compose run --rm openclaw chown -R 1001:1001 /app
```

### 调试技巧

```bash
# 查看容器详细信息
docker inspect openclaw-3.0

# 查看容器资源使用
docker stats openclaw-3.0

# 进入容器调试
docker-compose exec openclaw sh

# 重启并进入容器
docker-compose restart openclaw
docker-compose exec openclaw sh
```

---

## 更新升级

### 更新镜像

```bash
# 拉取最新代码
git pull

# 重新构建镜像
docker-compose build

# 重启服务
docker-compose up -d

# 查看日志
docker-compose logs -f
```

### 更新配置

```bash
# 编辑配置文件
nano config.json

# 重启服务
docker-compose restart
```

### 滚动更新

```bash
# 滚动更新服务
docker-compose up -d --no-deps --build openclaw
```

---

## 生产环境建议

### 1. 使用反向代理

推荐使用 Nginx 或 Traefik 作为反向代理：

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:18789;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 2. 启用 SSL/TLS

使用 Let's Encrypt 或其他证书服务：

```bash
# 使用 Certbot
certbot --nginx -d your-domain.com
```

### 3. 配置资源限制

```yaml
services:
  openclaw:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
```

### 4. 监控和告警

集成监控工具：

- **Prometheus**: 监控系统指标
- **Grafana**: 可视化监控数据
- **Sentry**: 错误跟踪

### 5. 日志管理

配置日志轮转：

```yaml
services:
  openclaw:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

---

## 高级配置

### 多实例部署

```yaml
services:
  openclaw-1:
    container_name: openclaw-1
    environment:
      - INSTANCE_ID=1

  openclaw-2:
    container_name: openclaw-2
    environment:
      - INSTANCE_ID=2
```

### 使用外部数据库

```yaml
services:
  openclaw:
    environment:
      - DB_TYPE=postgres
      - DB_HOST=postgres
      - DB_NAME=openclaw
    depends_on:
      - postgres
```

---

## 参考资源

- [Docker 官方文档](https://docs.docker.com/)
- [Docker Compose 文档](https://docs.docker.com/compose/)
- [OpenClaw 文档](https://docs.openclaw.ai)

---

## 支持

如有问题，请：

1. 查看本文档的"故障排查"部分
2. 查看 GitHub Issues
3. 联系技术支持

---

**祝部署顺利！** 🚀
