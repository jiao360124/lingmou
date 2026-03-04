# 🧹 冗余文件清理指南

## 📋 概述

本目录包含清理 `.openclaw` workspace 中冗余文件的脚本。

## 🛠️ 可用脚本

### Windows 用户
使用 `cleanup.bat`:
```cmd
cd C:\Users\Administrator\.openclaw\workspace\.openclaw
cleanup.bat
```

### Linux/Mac 用户
使用 `cleanup.sh`:
```bash
cd /path/to/.openclaw
chmod +x cleanup.sh
./cleanup.sh
```

## 📋 清理内容

### 1. 日志文件
- 所有 `.log` 文件
- 错误日志
- 访问日志

### 2. 备份文件
- `.backup` 文件
- `.bak` 文件
- `.old` 文件

### 3. 临时文件
- `.tmp` 文件
- `.temp` 文件
- `.DS_Store` (Mac)
- `Thumbs.db` (Windows)

### 4. 构建产物（可选）
- `node_modules/`
- `dist/`
- `build/`
- `coverage/`
- `.cache/`

## ⚠️ 注意事项

### 清理前
1. **备份重要数据**（推荐）
   ```bash
   # Windows
   copy .openclaw .openclaw.backup

   # Linux/Mac
   cp -r .openclaw .openclaw.backup
   ```

2. **查看将要清理的文件**
   ```bash
   # Windows
   dir /s /b .openclaw\*.log

   # Linux/Mac
   find .openclaw -name "*.log"
   ```

### 清理后
1. **验证清理结果**
   ```bash
   # 检查目录大小
   du -sh .openclaw

   # 查看剩余文件
   find .openclaw -type f
   ```

2. **重新安装依赖**（如果清理了 node_modules）
   ```bash
   npm install
   ```

## 📊 预期效果

### 清理安全（仅日志、临时、备份）
- 节省空间: 10-100 MB
- 风险: 低
- 可逆: 是

### 清理完整（包括构建产物）
- 节省空间: 150-600 MB
- 风险: 中等
- 需要重新安装依赖

## 🎯 清理策略

### 策略 1: 安全清理（推荐）
只清理日志和临时文件，不影响代码功能。

```bash
# Windows
cleanup.bat
# 选择不清理构建产物
```

### 策略 2: 完全清理
清理所有冗余文件，包括构建产物。

```bash
# Windows
cleanup.bat
# 选择清理构建产物
```

## 📝 手动清理

如果不想使用脚本，可以手动执行：

```bash
# 清理日志
find .openclaw -name "*.log" -delete

# 清理备份
find .openclaw -name "*.backup*" -delete
find .openclaw -name "*.bak*" -delete

# 清理临时文件
find .openclaw -name "*.tmp" -delete
find .openclaw -name "*.temp" -delete
find .openclaw -name ".DS_Store" -delete
find .openclaw -name "Thumbs.db" -delete
```

## 🔍 常见问题

### Q: 清理后 node_modules 丢失怎么办？
A: 重新安装依赖：
```bash
npm install
```

### Q: 清理的文件可以恢复吗？
A: 如果之前做了备份，可以从备份中恢复。

### Q: 清理会删除重要文件吗？
A: 脚本只会删除以下类型文件：
- 日志文件 (*.log)
- 备份文件 (*.backup*, *.bak*, *.old)
- 临时文件 (*.tmp, *.temp, .DS_Store, Thumbs.db)

不会删除源代码和配置文件。

## 📞 需要帮助？

如果遇到问题：
1. 查看清理前的文件列表
2. 检查备份是否正确
3. 查看错误日志

---

**创建时间**: 2026-02-17
**版本**: 1.0
