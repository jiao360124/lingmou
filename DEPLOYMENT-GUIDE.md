# OpenClaw 3.0 - 部署指南

## 📋 部署前准备

### 1. 环境要求
```
✅ Node.js 18+
✅ npm 8+
✅ Windows/Linux/macOS
```

### 2. 安装依赖
```bash
cd openclaw-3.0
npm install
```

---

## 🚀 部署步骤

### 方式1: 直接运行（开发环境）
```bash
node index.js
```

### 方式2: 使用启动脚本（Windows）
```bash
start.bat
```

### 方式3: 使用PM2（生产环境）
```bash
# 安装PM2
npm install pm2 -g

# 启动服务
pm2 start ecosystem.config.js

# 保存配置
pm2 save

# 设置开机自启
pm2 startup

# 查看状态
pm2 status

# 查看日志
pm2 logs openclaw-3.0

# 重启服务
pm2 restart openclaw-3.0

# 停止服务
pm2 stop openclaw-3.0
```

### 方式4: 使用Docker（推荐）
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm install --save-dev pm2
EXPOSE 3000
CMD ["pm2", "start", "index.js"]
```

```bash
docker build -t openclaw-3.0 .
docker run -d -p 3000:3000 --name openclaw-3.0 openclaw-3.0
```

---

## 🔧 配置调整

### 修改每日Token限制
编辑 `config.json`:
```json
{
  "dailyTokenLimit": 200000
}
```

### 修改夜间任务时间
编辑 `config.json`:
```json
{
  "nightlyTaskTime": "03:00"
}
```

### 修改会话摘要间隔
编辑 `core/runtime.js`:
```javascript
const summaryInterval = 10; // 改为其他数字
```

---

## 📊 监控和维护

### 查看实时状态
```bash
# PM2监控
pm2 monit

# 查看进程
pm2 list

# 查看日志
pm2 logs openclaw-3.0

# 重启
pm2 restart openclaw-3.0
```

### 查看指标数据
```bash
# Token使用
cat data/token-governor.json

# Metrics
cat data/metrics.json

# 目标进度
cat data/goals.json
```

### 查看报告
```bash
# 每日报告
cat reports/daily-report.json

# 日志
tail -f logs/openclaw-3.0.log

# 错误日志
tail -f logs/error.log
```

---

## 🔍 故障排查

### 问题1: 端口被占用
```
错误: EADDRINUSE: address already in use :::3000
解决:
  1. 修改config.json中的端口
  2. 或者停止占用端口的进程
```

### 问题2: 模块未找到
```
错误: Cannot find module '...'
解决:
  1. 确保依赖已安装: npm install
  2. 检查路径是否正确
```

### 问题3: Token使用超限
```
问题: 今日Token使用量已达上限
解决: 等待凌晨4:00自动重置
```

### 问题4: 429错误频繁
```
问题: API调用频繁遇到429错误
解决: 系统自动实施指数退避重试
查看日志: logs/openclaw-3.0.log
```

---

## 📈 性能优化

### 1. Token优化
- 启用上下文摘要（每10轮）
- 使用cheap-model（聊天模式）
- 夜间使用cheap-model（3-6点）

### 2. 调度优化
- 避免高频API调用
- 批量处理请求
- 使用缓存减少重复调用

### 3. 模板优化
- 定期审查和更新模板
- 删除低质量模板
- 优化模板内容

---

## 🔄 更新和维护

### 更新依赖
```bash
npm update
```

### 重新安装
```bash
rm -rf node_modules package-lock.json
npm install
```

### 备份数据
```bash
# 备份数据文件
tar -czf openclaw-3.0-backup-$(date +%Y%m%d).tar.gz data/ logs/

# 备份配置
cp config.json config.json.backup
```

### 恢复数据
```bash
tar -xzf openclaw-3.0-backup-20260214.tar.gz
```

---

## 🎯 部署检查清单

- [ ] Node.js 18+ 已安装
- [ ] 依赖已安装 (`npm install`)
- [ ] 配置文件已修改 (`config.json`)
- [ ] 目录结构已创建
- [ ] 测试通过 (`node test.js`)
- [ ] 服务已启动 (`node index.js` 或 `pm2 start`)
- [ ] 日志正常生成 (`logs/openclaw-3.0.log`)
- [ ] 指标数据正常 (`data/metrics.json`)
- [ ] 夜间任务已配置 (`node-cron`)
- [ ] 监控已启用

---

## 📞 支持和帮助

### 查看日志
```bash
# 所有日志
cat logs/openclaw-3.0.log

# 实时日志
tail -f logs/openclaw-3.0.log

# 错误日志
cat logs/error.log
```

### 查看文档
```bash
# README
cat README.md

# 使用指南
cat USAGE.md
```

### 获取帮助
```bash
# PM2帮助
pm2 --help

# Node帮助
node --help

# NPM帮助
npm --help
```

---

## 🎊 部署成功标志

当看到以下情况时，说明部署成功：

```
✅ Gateway状态: 正常
✅ 服务状态: 运行中
✅ Token使用: 正常追踪
✅ 目标引擎: 正常工作
✅ 夜间任务: 已配置
✅ 指标追踪: 正常记录
✅ 日志生成: 正常输出
```

---

**部署完成时间**: 2026-02-14 00:40:00
**版本**: 3.0.0
**状态**: ✅ 就绪
