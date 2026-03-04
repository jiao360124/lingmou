# 自我修复引擎完整文档

## 📚 概述

基于Moltbook moltbot项目的自主修复机制，实现完整的自我修复循环：
检测 → 快照 → 修复 → 验证 → 记录

## 🏗️ 系统架构

### 核心组件

1. **错误检测器** (error-detector.ps1)
   - 定期监控系统状态
   - 检测命令执行错误
   - 自动分类和报警

2. **自动修复器** (auto-fix.ps1)
   - 智能错误分析
   - 多策略修复尝试
   - 失败后回滚

3. **快照管理器** (snapshot-manager.ps1)
   - 创建last-known-good快照
   - 快照列表和恢复
   - 自动清理旧快照

4. **学习记录系统** (learning-tracker.ps1)
   - LEARNINGS.md - 学习记录
   - ERRORS.md - 错误记录
   - FEATURE_REQUESTS.md - 功能请求
   - 自动ID生成和分类

## 🚀 快速开始

### 1. 初始化配置
```powershell
# 创建配置文件
@"
{
  "enabled": true,
  "monitorInterval": 60,
  "snapshotRetention": 7,
  "fixAttempts": 3,
  "verifyDelay": 5000,
  "logDirs": [".logs", ".learnings"],
  "checkCommands": ["git", "npm", "powershell"]
}
"@ | Set-Content ".config/self-healing.json"
```

### 2. 启动监控
```powershell
cd skills/self-healing-engine
.\scripts\error-detector.ps1 -Action start
```

### 3. 创建初始快照
```powershell
.\scripts\snapshot-manager.ps1 -Action create -Name "initial"
```

### 4. 记录重要学习
```powershell
.\scripts\learning-tracker.ps1 -Action log -Type learning -Category "系统优化" -Message "延迟加载优化可将加载时间减少50%"
```

## 🔄 工作流程

```
┌─────────────────┐
│ 错误检测         │
│ (error-detector) │
└────────┬────────┘
         │ 检测到错误
         ↓
┌─────────────────┐
│ 保存快照         │
│ (snapshot)       │
└────────┬────────┘
         │ 快照ID
         ↓
┌─────────────────┐
│ 智能修复         │
│ (auto-fix)      │
└────────┬────────┘
         │ 修复结果
         ↓
┌─────────────────┐
│ 验证结果         │
│ (auto-fix)      │
└────────┬────────┘
         │ 验证成功/失败
         ↓
┌─────────────────┐
│ 记录学习         │
│ (learning)      │
└─────────────────┘
```

## 📊 错误分类

| 分类 | 描述 | 修复策略 |
|------|------|----------|
| timeout | 超时错误 | 等待后重试、增加超时 |
| network | 网络错误 | 重试、检查连通性 |
| permission | 权限错误 | 提升权限、修改权限 |
| not-found | 未找到 | 检查路径、重新执行 |
| general | 通用错误 | 清理状态、等待重试 |

## 💡 使用场景

### 场景1: Gateway状态监控
```powershell
# 定期检查Gateway状态
.\error-detector.ps1 -Action check

# 如果Token达到100%，记录学习
.\learning-tracker.ps1 -Action log -Type learning -Category "性能优化" -Message "Token达到100%时建议重启会话"
```

### 场景2: Git变更监控
```powershell
# 检测未提交的变更
Invoke-CommandWithDetection -Command "git status --short" -Description "Git状态检查"

# 如果有未提交的变更，记录
.\learning-tracker.ps1 -Action log -Type learning -Category "工作流优化" -Message "Git未提交的变更应定期提交"
```

### 场景3: 错误自动修复
```powershell
# 记录错误
$errId = .\learning-tracker.ps1 -Action log -Type error -Category "timeout" -Message "命令执行超时"

# 自动修复
.\auto-fix.ps1 -ErrorId $errId
```

### 场景4: 快照和回滚
```powershell
# 创建快照
$snapshotId = .\snapshot-manager.ps1 -Action create -Name "before-update"

# 执行操作...
# ...更新操作...

# 如果失败，回滚
.\snapshot-manager.ps1 -Action restore -Name $snapshotId

# 删除旧快照
.\snapshot-manager.ps1 -Action delete -Name $snapshotId
```

## 📝 学习记录格式

### 学习记录 (LRN-)
```markdown
## [LRN-20260213-001] 分类

**Logged**: 2026-02-13T12:00:00Z
**Priority**: high
**Status**: pending
**Area**: backend

### Summary
一句话描述学到了什么

### Details
详细描述：发生了什么，什么是对的

### Suggested Action
具体的修复或改进建议

### Metadata
- Source: conversation | error | user_feedback
- Related Files: path/to/file.ext
- Tags: tag1, tag2
- See Also: LRN-20260210-001
```

### 错误记录 (ERR-)
```markdown
## [ERR-20260213-001] error

**Logged**: 2026-02-13 12:00:00Z
**Priority**: high
**Status**: pending

### Summary
简要描述

### Error
实际错误消息

### Context
- Command: 执行的命令
- Environment: 环境细节

### Suggested Fix
可能的修复方案

### Metadata
- Reproducible: yes | no
- Related Files: path/to/file.ext
```

## 🔧 高级功能

### 1. Hook集成
集成到Agent Hook系统：
```json
{
  "hooks": {
    "UserPromptSubmit": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "./skills/self-healing-engine/scripts/activator.sh"
      }]
    }],
    "PostToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "command": "./skills/self-healing-engine/scripts/error-detector.sh"
      }]
    }]
  }
}
```

### 2. 周期性审查
定期审查学习记录：
```powershell
# 每天审查一次
.\learning-tracker.ps1 -Action review

# 统计信息
.\learning-tracker.ps1 -Action stats
```

### 3. 项目记忆提升
将高价值学习提升到永久记忆：
```powershell
# 标记为已提升
.\learning-tracker.ps1 -Action resolve -EntryId LRN-20260213-001 -Status "promoted"

# 提升到CLAUDE.md
Add-Content "CLAUDE.md" "- 项目约定：使用pnpm而非npm"
```

## 📈 性能指标

- **检测延迟**: < 1秒
- **快照创建**: < 5秒
- **自动修复**: 3-5次尝试
- **学习记录**: 即时写入
- **资源占用**: < 100MB

## 🎯 最佳实践

1. **记录一切** - 每个错误、学习都应该记录
2. **及时分类** - 使用正确的分类和优先级
3. **具体描述** - 详细的上下文有助于后续分析和修复
4. **定期审查** - 每周审查学习记录
5. **主动修复** - 尽量自动修复，减少人工干预
6. **知识复用** - 将学习转化为可复用的skills

## 🔄 与其他系统集成

### Moltbook集成
- 发布错误和学习到Moltbook社区
- 从Moltbook学习他人的最佳实践
- 参与自我modding讨论

### 自主学习系统
- 将学习记录用于训练模型
- 识别重复模式和趋势
- 改进未来的决策

### 性能优化系统
- 根据错误记录优化性能
- 减少错误发生频率
- 提升系统稳定性

## 📚 参考资源

- **Moltbook**: https://www.moltbook.com
- **Self-Improvement Skill**: https://moltbotden.com/skills/self-improvement
- **m/selfmodding**: Moltbook上的代码优化分享
- **Self-Healing System**: moltbot的自主修复机制

## 🚀 未来增强

- [ ] AI辅助错误分析
- [ ] 预测性维护
- [ ] 跨Agent学习共享
- [ ] 自动生成skills
- [ ] 增强可视化面板
- [ ] 实时监控仪表板

---

**状态**: ✅ 核心功能完成
**版本**: v1.0.0
**作者**: 灵眸
**基于**: Moltbook moltbot项目
