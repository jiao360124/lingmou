---
name: cyclic-review
description: "周期性审查系统"
---

# 周期性审查系统

## 概述
基于Moltbook Self-Improvement Skill，建立定期审查学习记录、错误和功能请求的自动化系统。

## 核心功能

### 1. 自动审查
- 周期性检查学习记录
- 识别待处理项目
- 建议优先级调整

### 2. 智能处理
- 自动标记过期项目
- 识别重复问题
- 建议解决方案

### 3. 报告生成
- 审查报告生成
- 优先级建议
- 行动计划

## 审查周期

### 每日审查
- 检查pending项目
- 更新处理进度
- 识别新问题

### 每周审查
- 综合分析所有学习记录
- 识别趋势和模式
- 制定改进计划

### 每月审查
- 深度分析
- 技能提取建议
- 系统性改进

## 使用示例

### 每日审查
```powershell
.\cyclic-review.ps1 -Action daily

.\cyclic-review.ps1 -Action daily -Verbose
```

### 每周审查
```powershell
.\cyclic-review.ps1 -Action weekly

.\cyclic-review.ps1 -Action weekly -Report "review-20260213.pdf"
```

### 每月审查
```powershell
.\cyclic-review.ps1 -Action monthly

.\cyclic-review.ps1 -Action monthly -AllCategories
```

### 生成报告
```powershell
.\cyclic-review.ps1 -Action report -Category "performance"

.\cyclic-review.ps1 -Action report -Type "priority"
```

## 审查维度

### 1. 待处理项目
- 计数和分类
- 平均处理时间
- 趋势分析

### 2. 优先级分析
- critical级别分布
- high级别处理率
- 优先级合理性

### 3. 时间分析
- 条目创建时间
- 处理延迟
- 周期性模式

### 4. 区域分析
- frontend/backend/infra分布
- 哪些区域问题最多
- 改进重点

## 审查规则

### 优先处理
- [ ] critical级别 + pending状态
- [ ] 状态超过7天 + high级别
- [ ] 重复错误（2+相关条目）

### 标记过期
- [ ] pending状态超过30天
- [ ] in_progress状态超过14天
- [ ] 不符合当前项目范围

### 建议提升
- [ ] 解决方案可复用（2+场景）
- [ ] 跨多个区域适用
- [ ] 已解决但价值高

## 输出格式

### JSON报告
```json
{
  "date": "2026-02-13",
  "reviewType": "weekly",
  "statistics": {
    "totalLearnings": 15,
    "pending": 5,
    "resolved": 8,
    "expired": 2
  },
  "byCategory": {
    "performance": { "pending": 2, "resolved": 5 },
    "security": { "pending": 1, "resolved": 2 },
    "testing": { "pending": 2, "resolved": 1 }
  },
  "priority": {
    "critical": 1,
    "high": 3,
    "medium": 6
  },
  "recommendations": [
    {
      "type": "priority_adjustment",
      "entryId": "LRN-20260210-001",
      "reason": "超过7天未处理",
      "suggestedPriority": "high"
    }
  ],
  "actionItems": [
    {
      "priority": "high",
      "type": "pending",
      "entryId": "ERR-20260212-005",
      "action": "检查网络连接配置",
      "estimatedTime": "30分钟"
    }
  ]
}
```

### Markdown报告
```markdown
# 周期性审查报告

**日期**: 2026-02-13
**类型**: 每周审查

## 📊 统计摘要

- **总学习数**: 15
- **待处理**: 5
- **已解决**: 8
- **已过期**: 2

## 📂 分类统计

### 性能优化
- 待处理: 2
- 已解决: 5
- 完成率: 71%

### 安全
- 待处理: 1
- 已解决: 2
- 完成率: 67%

### 测试
- 待处理: 2
- 已解决: 1
- 完成率: 33%

## ⚠️ 优先处理

1. **ERR-20260212-005** (网络连接超时)
   - 优先级: high
   - 处理时间: 30分钟
   - 行动: 检查网络连接配置

2. **LRN-20260211-003** (延迟加载优化)
   - 优先级: medium
   - 处理时间: 1小时
   - 行动: 实施延迟加载

## 📈 趋势分析

- 本周新增: 3个学习
- 本周解决: 2个
- 解决率: 40%

## 💡 建议

1. 性能优化完成率高，建议继续
2. 测试完成率低，增加测试资源
3. 网络问题频繁出现，需要深入排查
```

## 配置

`skills/cyclic-review/config.json`:
```json
{
  "reviewIntervals": {
    "daily": "14:00",
    "weekly": "Sunday 10:00",
    "monthly": "first-day"
  },
  "thresholds": {
    "expired": 30,
    "autoResolve": 7,
    "autoPromote": 14
  },
  "reportFormat": "markdown",
  "reportOutput": ".logs/reviews",
  "emailNotification": false,
  "slackNotification": false
}
```

## 集成

### Cron任务
```bash
# 每日审查
openclaw cron add --name "每日审查" --schedule "0 14 * * *" --payload '{"action": "daily-review"}'

# 每周审查
openclaw cron add --name "每周审查" --schedule "0 10 * * 0" --payload '{"action": "weekly-review"}'

# 每月审查
openclaw cron add --name "每月审查" --schedule "0 10 1 * *" --payload '{"action": "monthly-review"}'
```

### Hook集成
```json
{
  "hooks": {
    "UserPromptSubmit": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "./skills/cyclic-review/scripts/daily-check.sh"
      }]
    }]
  }
}
```

## 状态
- ✅ 架构设计完成
- ⏳ 实施中
