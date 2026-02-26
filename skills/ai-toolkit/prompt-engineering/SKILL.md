# Prompt-Engineering Skill

智能提示工程工具，提供提示模板、质量检查和优化建议。

## 功能概览

### 1. 模板库（Template Library）
- 20+ 常用场景模板
- 分类管理：代码、写作、分析、创意等
- 快速调用和修改

### 2. 质量检查器（Quality Checker）
5维度评分系统：
- **清晰度**（30%）：明确的目标和范围
- **完整性**（25%）：包含必要的上下文
- **结构**（20%）：良好的组织结构
- **风格**（15%）：适合的语气和格式
- **一致性**（10%）：各部分统一协调

### 3. 优化建议（Optimization Suggestion）
- AI驱动的提示改进
- 逐项建议和解释
- 优化前后对比

### 4. 预设库（Preset Library）
- 常用提示快速调用
- 行业场景预设
- 自定义预设保存

## 核心文件

### 模板库
- `templates/code.json` - 代码生成模板
- `templates/writing.json` - 写作辅助模板
- `templates/analysis.json` - 分析推理模板
- `templates/creative.json` - 创意生成模板
- `templates/admin.json` - 管理决策模板

### 核心脚本
- `scripts/template-manager.ps1` - 模板管理器
- `scripts/quality-checker.ps1` - 质量检查器
- `scripts/optimizer.ps1` - 优化建议引擎
- `scripts/preset-manager.ps1` - 预设管理器

### 数据文件
- `data/templates/` - 模板数据目录
- `data/presets/` - 预设数据目录
- `data/quality-rules.json` - 质量评分规则

## 使用方法

### 基本用法
```powershell
# 加载模板库
Import-Module .\scripts\template-manager.ps1

# 使用模板
$template = Get-Template -Category "code" -Name "function"
$enhancedPrompt = $template.Enhance($context)

# 检查质量
$quality = Check-PromptQuality -Prompt $prompt

# 获取优化建议
$improvements = Get-OptimizationSuggestions -Prompt $prompt
```

### 命令行接口
```bash
# 列出所有模板
pe templates --list

# 使用模板
pe templates --use code.function

# 检查质量
pe quality --check "your prompt"

# 获取优化建议
pe optimize --prompt "your prompt"
```

## 模板示例

### 代码生成模板
```json
{
  "name": "function-generation",
  "category": "code",
  "template": "请生成一个${language}的${function_type}函数，要求：\n1. 完成${task_description}\n2. 遵循${best_practices}\n3. 包含${error_handling}",
  "examples": [
    {
      "language": "JavaScript",
      "function_type": "async",
      "task_description": "处理API请求并返回数据",
      "best_practices": "错误处理、类型检查、日志记录",
      "error_handling": "try-catch块、错误信息"
    }
  ]
}
```

### 质量评分示例
```
提示词：写一个Python函数计算斐波那契数列
-----------------------------------
清晰度: 20/30 ❌ 缺少具体要求
完整性: 15/25 ❌ 缺少上下文
结构: 15/20 ⚠️ 基本完整
风格: 12/15 ⚠️ 一般
一致性: 8/10 ⚠️ 基本一致
-----------------------------------
总分: 70/100

优化建议：
1. 添加函数签名和参数说明
2. 添加使用示例和文档字符串
3. 明确输入输出类型
4. 添加性能优化要求
```

## 扩展接口

### 自定义模板
```powershell
New-PromptTemplate -Category "custom" -Name "my-template" -Template "..."
Register-Preset -Name "my-preset" -Templates @(...)
```

### 质量规则扩展
```powershell
Update-QualityRules -Rule "clarity" -Weight 0.35
Add-QualityRule -Name "custom-rule" -Weight 0.05 -Check {...}
```

## 集成点

### 与其他技能集成
- **Auto-GPT**: 提供高质量提示词用于任务分解
- **RAG**: 检索相关模板和最佳实践
- **Copilot**: 基于模板提供代码补全建议

### API端点
- `POST /api/templates` - 获取模板
- `POST /api/quality/check` - 质量检查
- `POST /api/optimize` - 优化建议
- `POST /api/presets/use` - 使用预设

## 性能指标

| 指标 | 目标值 | 当前值 |
|------|--------|--------|
| 模板加载速度 | <100ms | - |
| 质量检查速度 | <500ms | - |
| 优化建议生成 | <1s | - |
| 模板数量 | 20+ | - |

## 更新日志

### v1.0.0 (2026-02-13)
- 初始版本
- 4个模板分类
- 质量检查器
- 优化建议引擎
- 预设管理系统
