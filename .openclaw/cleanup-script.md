# OpenClaw 冗余文件清理脚本

## 🧹 清理步骤

### 1. 备份重要文件
```bash
# 备份配置文件
cp -r .openclaw .openclaw.backup
```

### 2. 清理日志文件
```bash
cd .openclaw/workspace
# 删除所有日志文件
rm -f logs/*.log
rm -f error.log
rm -f combined.log
rm -f access.log
```

### 3. 清理备份文件
```bash
# 删除备份文件
find . -name "*.backup" -delete
find . -name "*.bak" -delete
find . -name "*.old" -delete
find . -name "*.backup.*" -delete
find . -name "*.bak.*" -delete
```

### 4. 清理临时文件
```bash
# 删除临时文件
find . -name "*.tmp" -delete
find . -name "*.temp" -delete
find . -name ".DS_Store" -delete
find . -name "Thumbs.db" -delete
```

### 5. 清理构建产物
```bash
# 删除 node_modules（需要重新安装）
rm -rf node_modules

# 删除构建文件
rm -rf dist
rm -rf build
rm -rf coverage

# 删除缓存
rm -rf .cache
```

### 6. 清理 package-lock.json（可选）
```bash
# 如果想重新安装依赖
rm package-lock.json
```

## 📊 清理前检查

在清理之前，建议先查看文件列表：

```bash
# 查看日志文件
find .openclaw -name "*.log" -ls

# 查看备份文件
find .openclaw -name "*.backup*" -ls
find .openclaw -name "*.bak*" -ls

# 查看临时文件
find .openclaw -name "*.tmp" -ls
find .openclaw -name "*.temp" -ls

# 查看构建产物
find .openclaw -type d -name "node_modules" -ls
find .openclaw -type d -name "dist" -ls
find .openclaw -type d -name "build" -ls
find .openclaw -type d -name ".cache" -ls
```

## ⚠️ 注意事项

1. **备份重要数据**
2. **node_modules 清理后需要重新安装**
3. **删除前确认文件不是必需的**
4. **建议先查看文件列表**

## 🚀 快速清理（谨慎使用）

```bash
# 只清理日志和临时文件（安全）
find .openclaw -name "*.log" -delete
find .openclaw -name "*.tmp" -delete
find .openclaw -name "*.temp" -delete
find .openclaw -name ".DS_Store" -delete
find .openclaw -name "Thumbs.db" -delete

# 只清理备份文件（安全）
find .openclaw -name "*.backup*" -delete
find .openclaw -name "*.bak*" -delete
find .openclaw -name "*.old" -delete
```

## 📝 清理后验证

```bash
# 检查清理结果
du -sh .openclaw

# 查看剩余文件
find .openclaw -type f
```

## 💡 预期清理效果

清理后应该删除：
- 旧的日志文件
- 临时文件
- 备份文件
- 缓存文件
- 构建产物

节省空间：
- 日志文件: 可节省 10-50 MB
- 临时文件: 可节省 1-10 MB
- node_modules: 可节省 100-500 MB
- 其他: 可节省 1-5 MB

**总计**: 可节省 150-600 MB
