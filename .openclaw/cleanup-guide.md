# 🧹 C:\Users\Administrator\.openclaw 清理计划

## 📋 目录结构

```
C:\Users\Administrator\.openclaw\
├── workspace\.openclaw\                    ← 已清理 ✅
│   ├── logs\                               ← 已清理
│   ├── *.log                               ← 已清理
│   ├── *.tmp                               ← 已清理
│   ├── *.temp                              ← 已清理
│   ├── *.backup*                           ← 已清理
│   ├── *.bak*                              ← 已清理
│   ├── *.old                               ← 已清理
│   ├── memory\                             ← 保留
│   ├── data\                               ← 保留
│   └── workspace\                          ← 保留
│
├── node_modules\                           ← 可能需要清理
│   └── (依赖包)                             ← 100-500 MB
│
├── logs\                                   ← 可以清理
│   └── *.log                                ← 10-100 MB
│
├── config\                                 ← 保留
│
├── package.json                            ← 保留
├── package-lock.json                       ← 保留
├── pnpm-lock.yaml                          ← 保留
│
├── .cache\                                 ← 可以清理
├── dist\                                   ← 可以清理（如果存在）
├── build\                                  ← 可以清理（如果存在）
├── .DS_Store                               ← 可以清理
└── Thumbs.db                               ← 可以清理
```

---

## 🎯 清理建议

### 阶段 1: 安全清理（推荐立即执行）

#### 1. 清理日志文件
```powershell
# 清理根目录的日志
Get-ChildItem -Path "C:\Users\Administrator\.openclaw\logs" -Filter "*.log" | Remove-Item -Force

# 清理 workspace\.openclaw 中的日志（已完成）
Get-ChildItem -Path "C:\Users\Administrator\.openclaw\workspace\.openclaw" -Filter "*.log" -Recurse | Remove-Item -Force
```

**预计节省**: 10-100 MB
**风险**: 低
**可逆**: ✅ 是

---

### 阶段 2: 构建产物清理（谨慎）

#### 2. 清理 node_modules
```powershell
# 删除 node_modules
Remove-Item -Path "C:\Users\Administrator\.openclaw\node_modules" -Recurse -Force
```

**预计节省**: 100-500 MB
**风险**: 中等
**可逆**: ⚠️ 需要重新安装

**需要先检查 package.json**

---

#### 3. 清理构建目录
```powershell
# 删除构建产物
Remove-Item -Path "C:\Users\Administrator\.openclaw\dist" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Users\Administrator\.openclaw\build" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Users\Administrator\.openclaw\.cache" -Recurse -Force -ErrorAction SilentlyContinue
```

**预计节省**: 10-50 MB
**风险**: 低
**可逆**: ✅ 是

---

#### 4. 清理系统缓存
```powershell
# 清理系统缓存
Remove-Item -Path "C:\Users\Administrator\.openclaw\.DS_Store" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Users\Administrator\.openclaw\Thumbs.db" -Force -ErrorAction SilentlyContinue
```

**预计节省**: 1-5 MB
**风险**: 无
**可逆**: ✅ 是

---

## 📊 清理效果预测

| 清理项 | 大小 | 风险 | 可逆性 |
|--------|------|------|--------|
| 日志文件 | 10-100 MB | 低 | ✅ 可恢复 |
| node_modules | 100-500 MB | 中 | ⚠️ 需重新安装 |
| 构建目录 | 10-50 MB | 低 | ✅ 可恢复 |
| 系统缓存 | 1-5 MB | 无 | ✅ 可恢复 |
| **总计** | **121-655 MB** | - | - |

---

## 🚀 快速清理（推荐）

### 阶段 1: 安全清理（推荐先做）
```powershell
cd C:\Users\Administrator\.openclaw

# 清理日志文件
Get-ChildItem -Path "logs" -Filter "*.log" -Recurse | Remove-Item -Force

# 清理构建产物
Remove-Item -Path "dist" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "build" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path ".cache" -Recurse -Force -ErrorAction SilentlyContinue

# 清理系统缓存
Remove-Item -Path ".DS_Store" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "Thumbs.db" -Force -ErrorAction SilentlyContinue

Write-Host "✅ 阶段 1 清理完成！" -ForegroundColor Green
```

---

### 阶段 2: 完全清理（需要重新安装依赖）
```powershell
cd C:\Users\Administrator\.openclaw

# 备份 package.json（可选）
copy package.json package.json.backup

# 删除 node_modules
Remove-Item -Path "node_modules" -Recurse -Force

Write-Host "✅ 阶段 2 清理完成！" -ForegroundColor Green
Write-Host "⚠️  需要运行: npm install" -ForegroundColor Yellow
```

---

## ⚠️ 注意事项

### 清理前
1. ✅ **备份重要配置**（如果需要）
2. ✅ **确认 package.json 存在**
3. ✅ **了解 node_modules 用途**

### 清理后
1. ✅ **验证系统功能**
2. ✅ **重新安装依赖**（如果删除了 node_modules）
3. ✅ **检查日志文件**（如果需要）

---

## 🔄 恢复方法

### 如果需要恢复 node_modules
```powershell
cd C:\Users\Administrator\.openclaw
npm install
```

### 如果需要恢复日志
日志会自动重新生成，无需手动恢复。

---

## 💡 我的建议

**推荐清理顺序**:

1. **先执行阶段 1**（安全清理）
   - 节省: 21-155 MB
   - 风险: 低
   - 可逆: ✅ 是

2. **确认需要后执行阶段 2**（完全清理）
   - 节省: 121-655 MB
   - 风险: 中
   - 可逆: ⚠️ 需重新安装

---

**创建时间**: 2026-02-17 00:45
**版本**: 1.0
