# 简化版清理方案

## 📋 清理目标

### 1. 清理日志文件
日志文件通常占用空间较大，但可以安全删除。

**位置**: `.openclaw/logs/` 目录
**文件类型**: `*.log`

**清理命令**:
```bash
# Windows PowerShell
Get-ChildItem -Path ".openclaw\logs" -Filter "*.log" | Remove-Item -Force

# Linux/Mac
find .openclaw/logs -name "*.log" -delete
```

---

### 2. 清理临时文件
临时文件可以安全删除。

**文件类型**:
- `*.tmp`
- `*.temp`
- `.DS_Store` (Mac)
- `Thumbs.db` (Windows)

**清理命令**:
```bash
# Windows PowerShell
Get-ChildItem -Path ".openclaw" -Filter "*.tmp" -Recurse | Remove-Item -Force
Get-ChildItem -Path ".openclaw" -Filter "*.temp" -Recurse | Remove-Item -Force
Get-ChildItem -Path ".openclaw" -Filter ".DS_Store" -Recurse | Remove-Item -Force
Get-ChildItem -Path ".openclaw" -Filter "Thumbs.db" -Recurse | Remove-Item -Force

# Linux/Mac
find .openclaw -name "*.tmp" -delete
find .openclaw -name "*.temp" -delete
find .openclaw -name ".DS_Store" -delete
find .openclaw -name "Thumbs.db" -delete
```

---

### 3. 清理备份文件
备份文件可以安全删除。

**文件类型**:
- `*.backup`
- `*.bak`
- `*.old`
- `*.backup.*`
- `*.bak.*`

**清理命令**:
```bash
# Windows PowerShell
Get-ChildItem -Path ".openclaw" -Filter "*.backup*" -Recurse | Remove-Item -Force
Get-ChildItem -Path ".openclaw" -Filter "*.bak*" -Recurse | Remove-Item -Force
Get-ChildItem -Path ".openclaw" -Filter "*.old" -Recurse | Remove-Item -Force

# Linux/Mac
find .openclaw -name "*.backup*" -delete
find .openclaw -name "*.bak*" -delete
find .openclaw -name "*.old" -delete
```

---

## 🚀 快速清理（一键执行）

### Windows 一键清理
```powershell
# 打开 PowerShell，运行:
cd C:\Users\Administrator\.openclaw\workspace\.openclaw

# 清理所有冗余文件
Get-ChildItem -Path "." -Filter "*.log" -Recurse | Remove-Item -Force
Get-ChildItem -Path "." -Filter "*.tmp" -Recurse | Remove-Item -Force
Get-ChildItem -Path "." -Filter "*.temp" -Recurse | Remove-Item -Force
Get-ChildItem -Path "." -Filter ".DS_Store" -Recurse | Remove-Item -Force
Get-ChildItem -Path "." -Filter "Thumbs.db" -Recurse | Remove-Item -Force
Get-ChildItem -Path "." -Filter "*.backup*" -Recurse | Remove-Item -Force
Get-ChildItem -Path "." -Filter "*.bak*" -Recurse | Remove-Item -Force
Get-ChildItem -Path "." -Filter "*.old" -Recurse | Remove-Item -Force

Write-Host "✅ 清理完成！" -ForegroundColor Green
```

### Linux/Mac 一键清理
```bash
# 打开终端，运行:
cd /path/to/.openclaw

# 清理所有冗余文件
find . -name "*.log" -delete
find . -name "*.tmp" -delete
find . -name "*.temp" -delete
find . -name ".DS_Store" -delete
find . -name "Thumbs.db" -delete
find . -name "*.backup*" -delete
find . -name "*.bak*" -delete
find . -name "*.old" -delete

echo "✅ 清理完成！"
```

---

## 📊 预期效果

清理后将删除:
- ✅ 日志文件（10-100 MB）
- ✅ 临时文件（1-10 MB）
- ✅ 备份文件（5-50 MB）

**总计可节省空间**: 16-160 MB

---

## ⚠️ 注意事项

1. **这些文件可以安全删除**
2. **如果需要，可以从备份恢复**
3. **清理后不会影响功能**

---

## 🔍 清理后验证

```powershell
# Windows PowerShell - 查看目录大小
Get-ChildItem -Path ".openclaw" -Recurse | Measure-Object -Property Length -Sum

# Linux/Mac - 查看目录大小
du -sh .openclaw
```

---

**创建时间**: 2026-02-17 00:35
**版本**: 1.0
