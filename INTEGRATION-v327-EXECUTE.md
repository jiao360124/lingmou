# v3.2.7 整合执行计划

## 执行日期
2026-03-02 17:35

## 整合状态

### ✅ 已完成
1. 核心模块集成（core/）
   - monitoring/ - 监控模块
   - strategy/ - 策略引擎增强

2. 技能集成（skills/）
   - 41个技能全部集成

3. 评估报告
   - INTEGRATION-v327-PLAN.md - 整合计划
   - INTEGRATION-v327-COMPLETE.md - 完成报告
   - INTEGRATION-v327-FINAL.md - 最终报告
   - AUTOMATION-EVALUATION.md - automation评估

### ⏭️ 待执行

#### 1. 清理废弃内容
```powershell
# 删除已废弃的v3.0和v3.2/memory
Remove-Item -Path "C:\Users\Administrator\.openclaw\workspace\openclaw-3.0" -Recurse -Force
Remove-Item -Path "C:\Users\Administrator\.openclaw\workspace\openclaw-3.2\memory" -Recurse -Force

# 删除废弃脚本
Remove-Item -Path "C:\Users\Administrator\.openclaw\workspace\automation\openclaw-3.0-startup.ps1" -Force
```

#### 2. 清理空目录
```powershell
# 删除8个空目录
$emptyDirs = @(
    "skill-modules",
    "cron-scheduler",
    "moltbook-integration",
    "self-healing-engine",
    "self-evolution",
    "economy",
    "metrics",
    "knowledge"
)

foreach ($dir in $emptyDirs) {
    $path = Join-Path "C:\Users\Administrator\.openclaw\workspace" $dir
    if (Test-Path $path) {
        Remove-Item -Path $path -Recurse -Force
        Write-Host "Deleted: $dir"
    }
}
```

#### 3. 优化automation脚本
```powershell
# 优化week5-automation.ps1
# 删除OpenClaw 3.0相关代码
# 保留监控和任务计划功能
```

#### 4. 提交Git
```bash
git add .
git commit -m "chore: v3.2.7 整合完成 - 清理废弃内容"
git push
```

---

## 执行步骤

### Step 1: 备份当前状态
```bash
git stash
git branch backup-v326
```

### Step 2: 清理废弃内容
```powershell
# 执行上面的清理命令
```

### Step 3: 验证清理结果
```bash
# 检查目录结构
ls workspace/
```

### Step 4: 测试系统
```bash
# 测试Gateway
openclaw gateway status

# 测试技能
ls skills/

# 测试核心模块
ls core/
```

### Step 5: 提交更改
```bash
git add .
git commit -m "chore: v3.2.7 integration complete

- Integrated core modules (monitoring, strategy engine)
- Integrated 41 skills
- Cleaned up deprecated v3.0 and v3.2/memory
- Removed empty directories
- Optimized automation scripts

Status: ✅ v3.2.7 complete"
git push
```

---

## 验证清单

### ✅ 核心模块
- [ ] monitoring/ 存在且正常
- [ ] strategy/ 存在且正常
- [ ] core/index.js 存在

### ✅ 技能
- [ ] 41个技能目录存在
- [ ] 所有技能有SKILL.md
- [ ] skills/目录整洁

### ✅ 清理结果
- [ ] openclaw-3.0/ 已删除
- [ ] openclaw-3.2/memory/ 已删除
- [ ] 8个空目录已删除
- [ ] automation/openclaw-3.0-startup.ps1 已删除

### ✅ 系统测试
- [ ] Gateway运行正常
- [ ] 技能加载正常
- [ ] 核心模块正常

---

## 预期结果

### 目录结构
```
workspace/
├── core/                    # 核心模块 ✅
│   ├── monitoring/         # 监控模块 ✅
│   ├── strategy/           # 策略引擎 ✅
│   ├── data/               # 数据
│   └── integrations/       # 集成
├── skills/                  # 41个技能 ✅
├── automation/              # 自动化脚本 ✅
├── memory/                  # 记忆
├── reports/                 # 报告
├── docs/                    # 文档
└── ...
```

### 系统能力
- ✅ 智能决策（多方案评估、成本收益、风险控制）
- ✅ 自我监控（API、内存、性能）
- ✅ 技能集成（41个技能）
- ✅ 架构优化（模块化、可维护）

---

## 风险评估

| 风险 | 级别 | 缓解措施 |
|------|------|---------|
| 删除v3.0导致功能丢失 | 低 | v3.0已废弃，功能已集成到v3.2.6 |
| 删除空目录影响恢复 | 低 | 空目录无内容，可随时重建 |
| 系统测试失败 | 低 | 有备份，可快速回滚 |
| Git提交冲突 | 低 | 先stash再提交 |

---

## 执行时间线

- **Step 1**: 备份（5分钟）
- **Step 2**: 清理废弃内容（5分钟）
- **Step 3**: 验证清理结果（5分钟）
- **Step 4**: 测试系统（5分钟）
- **Step 5**: 提交Git（3分钟）

**总计**: ~23分钟

---

**状态**: ✅ 计划完成，待执行
**优先级**: 中（不影响核心功能）
**风险**: 低
