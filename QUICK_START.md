# 快速开始指南

**灵眸系统 v1.0**
**版本**: 1.0.0
**更新日期**: 2026-02-11

---

## 🚀 5分钟快速上手

### 第一步：安装依赖

确保你的系统已安装：
- ✅ PowerShell 5.1+ 或 PowerShell 7+
- ✅ Git
- ✅ 必要的环境变量（`.env` 文件）

### 第二步：配置环境

```bash
# 加载环境变量
. .env-loader.ps1

# 检查配置
powershell -ExecutionPolicy Bypass -File "scripts/environment-check.ps1"
```

### 第三步：启动系统

```bash
# 运行所有系统（推荐）
powershell -ExecutionPolicy Bypass -File "scripts/integration-manager.ps1"

# 或者单独运行各个模块
powershell -ExecutionPolicy Bypass -File "scripts/nightly-evolution.ps1"
powershell -ExecutionPolicy Bypass -File "scripts/simple-health-check.ps1"
```

### 第四步：查看状态

```bash
# 检查Gateway状态
openclaw status

# 检查系统健康
powershell -ExecutionPolicy Bypass -File "scripts/simple-health-check.ps1"
```

---

## 📚 核心功能一览

### 1. 系统监控 ✅
- 实时状态检查
- Gateway监控
- 资源使用追踪

### 2. 自动化运维 ✅
- Nightly Evolution（夜航计划）
- 错误自动修复
- 智能日志分析

### 3. 性能优化 ✅
- 性能基准测试
- 内存优化
- API调用优化

### 4. 技能集成 ✅
- Code Mentor（编程教学）
- Git Essentials（Git辅助）
- Deepwork Tracker（深度工作）

### 5. 自动化工作流 ✅
- 智能任务调度
- 跨技能协作
- 条件触发器

---

## 💡 常用命令

### 健康检查
```bash
# 简单健康检查
powershell -ExecutionPolicy Bypass -File "scripts/simple-health-check.ps1"

# 详细环境检查
powershell -ExecutionPolicy Bypass -File "scripts/environment-check.ps1"
```

### 数据备份
```bash
# 执行自动备份
powershell -ExecutionPolicy Bypass -File "scripts/daily-backup.ps1"
```

### 日志管理
```bash
# 清理旧日志
powershell -ExecutionPolicy Bypass -File "scripts/cleanup-logs.ps1"

# 查看系统日志
Get-Content logs/nightly-evolution-*.log -Tail 50
```

### Gateway操作
```bash
# 重启Gateway
openclaw gateway restart

# 查看Gateway状态
openclaw gateway status
```

---

## 🔧 配置文件

### 环境变量（.env）
- **GATEWAY_PORT**: Gateway端口（默认：18789）
- **BACKUP_PATH**: 备份目录
- **LOG_LEVEL**: 日志级别（Debug/Info/Warn/Error）

### 端口配置（.ports.env）
- **GATEWAY_PORT**: Gateway端口
- **CANVAS_PORT**: Canvas端口
- **HEARTBEAT_PORT**: Heartbeat端口
- **WEBSOCKET_PORT**: WebSocket端口

---

## ⚠️ 常见问题

### Q1: 执行脚本时提示权限错误
**A**: 使用 `-ExecutionPolicy Bypass` 参数
```bash
powershell -ExecutionPolicy Bypass -File "scripts/xxx.ps1"
```

### Q2: 找不到模块
**A**: 检查环境变量是否正确加载
```bash
. .env-loader.ps1
```

### Q3: Gateway连接失败
**A**: 检查Gateway是否启动
```bash
openclaw gateway status
```

---

## 📖 下一步

1. **阅读完整教程**: 见 [TUTORIALS.md](TUTORIALS.md)
2. **查看API文档**: 见 [API_DOCUMENTATION.md](API_DOCUMENTATION.md)
3. **了解部署**: 见 [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

---

## 🆘 获取帮助

- 查看日志文件：`logs/` 目录
- 检查错误数据库：`error-database.json`
- 运行系统诊断：`scripts/simple-health-check.ps1`

---

**文档版本**: 1.0.0
**最后更新**: 2026-02-11
