# 技能自动提取器

## 概述
基于Moltbook学习记录，自动从LEARNINGS.md、ERRORS.md中提取可复用的skills，无需人工干预。

## 核心功能

### 1. 自动提取
- 分析学习记录的模式
- 识别可复用的解决方案
- 提取为独立的skills

### 2. 质量检查
- 验证技能完整性
- 检查代码示例
- 确保独立性

### 3. 分类和打包
- 自动分类到合适目录
- 生成skill.json元数据
- 创建SKILL.md文档

## 使用示例

### 自动提取
```powershell
.\auto-skill-extractor.ps1 -Action extract -Category "performance" -MaxSkills 5

.\auto-skill-extractor.ps1 -Action extract-all
```

### 手动提取
```powershell
.\auto-skill-extractor.ps1 -Action extract -From "learning-tracker.ps1" -Category "error-handling"
```

### 质量检查
```powershell
.\auto-skill-extractor.ps1 -Action check -Skill "error-recovery"
```

## 提取标准

### 成功条件
- [x] 重复问题（2+相关条目）
- [x] 已验证的修复
- [x] 非显而易见的解决方案
- [x] 广泛适用的最佳实践
- [x] 包含代码示例
- [x] 清晰的描述

### 提取流程
1. 识别候选学习条目
2. 提取解决方案模式
3. 创建skill模板
4. 填充元数据和内容
5. 质量检查
6. 部署到skills目录

## 输出格式

### Skill结构
```
skills/extracted/
├── error-recovery/
│   ├── SKILL.md
│   ├── skill.json
│   ├── README.md
│   └── examples/
│       ├── example-1.ps1
│       └── example-2.ps1
```

### skill.json
```json
{
  "name": "error-recovery",
  "version": "1.0.0",
  "description": "自动错误恢复机制",
  "author": "灵眸",
  "category": "error-handling",
  "tags": ["error", "recovery", "auto-fix"],
  "dependencies": [],
  "author": "灵眸"
}
```

## 配置

`skills/auto-skill-extractor/config.json`:
```json
{
  "extractionPath": ".logs/learnings",
  "outputPath": "skills/extracted",
  "minRelatedEntries": 2,
  "maxSkillsPerCategory": 10,
  "qualityCheck": true,
  "autoDeploy": true
}
```

## 状态
- ✅ 架构设计完成
- ⏳ 实施中
