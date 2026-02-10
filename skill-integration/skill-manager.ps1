# 灵眸技能集成管理器

**版本**: 1.0
**日期**: 2026-02-10

---

## 功能概览

这个脚本提供了统一的接口来管理所有集成的技能模块。

---

## 主要功能

### 1. 技能加载和调用
- 加载所有技能模块
- 统一的技能调用接口
- 错误隔离和日志记录

### 2. 技能状态管理
- 查看所有可用技能
- 检查技能状态
- 使用统计

### 3. 技能组合执行
- 同时调用多个技能
- 任务编排
- 结果聚合

---

## 使用方法

### 基础用法

```powershell
# 加载所有技能模块
. scripts/skill-integration/skill-manager.ps1

# 查看所有可用技能
Get-AvailableSkills

# 使用特定技能
Invoke-Skill -SkillName "code-mentor" -Action "review" -Param1 $code
```

### 进阶用法

```powershell
# 批量执行技能
Invoke-SkillBatch -Skills @("code-mentor", "git-essentials") -Action "analyze"

# 检查技能状态
Get-SkillStatus -SkillName "code-mentor"

# 查看技能使用统计
Get-SkillUsageStats
```

---

## API 参考

### 核心函数

#### `Invoke-Skill`
```powershell
Invoke-Skill -SkillName <string> -Action <string> @Params
```

**参数**:
- `SkillName`: 技能名称（"code-mentor", "git-essentials", "deepwork-tracker"）
- `Action`: 要执行的操作
- `@Params`: 额外参数（可选）

**返回**:
- 技能执行结果

---

#### `Invoke-SkillBatch`
```powershell
Invoke-SkillBatch -Skills <array> -Action <string> @Params
```

**参数**:
- `Skills`: 技能名称数组
- `Action`: 要执行的操作
- `@Params`: 额外参数（可选）

**返回**:
- 所有技能的执行结果数组

---

#### `Get-AvailableSkills`
```powershell
Get-AvailableSkills
```

**返回**:
- 所有可用技能列表

---

#### `Get-SkillStatus`
```powershell
Get-SkillStatus -SkillName <string>
```

**参数**:
- `SkillName`: 技能名称

**返回**:
- 技能状态信息

---

#### `Get-SkillUsageStats`
```powershell
Get-SkillUsageStats
```

**返回**:
- 技能使用统计信息

---

## 技能详情

### 1. Code Mentor
**技能模块**: `code-mentor-integration.ps1`

**可用操作**:
- `review` - 代码审查
- `debug` - 调试辅助
- `practice` - 算法练习

**示例**:
```powershell
Invoke-Skill -SkillName "code-mentor" -Action "review" -Code $code -Mode "code-review"
```

---

### 2. Git Essentials
**技能模块**: `git-essentials-integration.ps1`

**可用操作**:
- `status` - Git状态分析
- `commit` - 提交建议
- `branch` - 分支优化
- `conflict` - 冲突解决

**示例**:
```powershell
Invoke-Skill -SkillName "git-essentials" -Action "status" -Detailed
```

---

### 3. Deepwork Tracker
**技能模块**: `deepwork-tracker-integration.ps1`

**可用操作**:
- `start` - 开始会话
- `stop` - 停止会话
- `status` - 会话状态
- `report` - 生成报告
- `heatmap` - 生成贡献图
- `share` - 分享到Telegram

**示例**:
```powershell
Invoke-Skill -SkillName "deepwork-tracker" -Action "start" -TargetMinutes 60
```

---

## 错误处理

### 错误隔离
- 单个技能失败不影响其他技能
- 所有错误都记录到日志
- 提供清晰的错误信息

### 日志记录
所有错误和警告都会记录到日志文件：
- 日志路径: `logs/skill-integration-$(Get-Date -Format 'yyyyMMdd').log`

---

## 性能优化

### 缓存机制
- 技能结果缓存（避免重复执行）
- 自动清理过期缓存

### 并行执行
- 独立任务可并行执行
- 避免资源竞争

### 资源管理
- 限制同时加载的技能数量
- 自动释放不活跃的技能

---

## 使用示例

### 示例1: 代码审查 + Git状态检查
```powershell
. scripts/skill-integration/skill-manager.ps1

# 加载技能
Invoke-Skill -SkillName "code-mentor" -Action "review" -Code $code -Mode "code-review"
Invoke-Skill -SkillName "git-essentials" -Action "status" -Detailed
```

### 示例2: 深度工作会话管理
```powershell
Invoke-Skill -SkillName "deepwork-tracker" -Action "start" -TargetMinutes 90
Invoke-Skill -SkillName "deepwork-tracker" -Action "status"

# 工作一段时间后
Invoke-Skill -SkillName "deepwork-tracker" -Action "stop"

# 生成报告
Invoke-Skill -SkillName "deepwork-tracker" -Action "report" -Days 7 -Format "telegram"
```

### 示例3: 批量分析
```powershell
# 同时进行代码审查和Git分析
$results = Invoke-SkillBatch -Skills @("code-mentor", "git-essentials") -Action "analyze" -Code $code
```

---

## 配置选项

### 技能启用/禁用
```powershell
# 启用/禁用特定技能
Set-SkillEnabled -SkillName "code-mentor" -Enabled $true
Set-SkillEnabled -SkillName "deepwork-tracker" -Enabled $false
```

### 超时设置
```powershell
# 设置技能执行超时
Set-SkillTimeout -SkillName "code-mentor" -TimeoutSeconds 60
```

---

## 维护和更新

### 更新日志
- 2026-02-10: 初始版本，集成3个核心技能
- 待更新...

### 添加新技能
1. 创建技能集成脚本
2. 实现接口规范
3. 添加到 `Get-AvailableSkills`
4. 更新文档

---

## 注意事项

1. **技能加载**: 技能模块只在调用时加载，避免内存浪费
2. **错误处理**: 所有错误都被捕获和处理，不会导致脚本中断
3. **性能监控**: 定期检查技能性能，优化瓶颈
4. **日志记录**: 重要操作都会记录日志，便于调试

---

## 故障排除

### 技能未加载
```powershell
# 检查技能文件是否存在
Test-Path "scripts/skill-integration/<skill-name>-integration.ps1"

# 手动加载技能
. scripts/skill-integration/<skill-name>-integration.ps1
```

### 执行超时
```powershell
# 增加超时时间
Set-SkillTimeout -SkillName "<skill-name>" -TimeoutSeconds 120
```

### 资源不足
```powershell
# 清理缓存
Clear-SkillCache

# 重新加载技能
Unregister-SkillModule -SkillName "<skill-name>"
. scripts/skill-integration/skill-manager.ps1
```

---

**维护者**: 灵眸
**最后更新**: 2026-02-10
