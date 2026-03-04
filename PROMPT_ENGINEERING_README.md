# Prompt-Engineering Skill

智能提示工程工具，提供模板库、质量检查和优化建议。

## 🎯 核心功能

### 1. 模板库（Template Library）
- 100+ 预设提示模板
- 5个分类：代码、写作、分析、创意、管理
- 快速调用和修改

### 2. 质量检查器（Quality Checker）
5维度评分系统：
- ✅ 清晰度 (30%)
- ✅ 完整性 (25%)
- ✅ 结构 (20%)
- ✅ 风格 (15%)
- ✅ 一致性 (10%)

### 3. 优化建议（Optimizer）
- AI驱动的提示改进
- 逐项建议和解释
- 优化前后对比

### 4. 预设库（Preset Manager）
- 常用提示快速调用
- 保存自定义预设
- 批量管理

---

## 📁 文件结构

```
skills/prompt-engineering/
├── SKILL.md                          # 技能文档
├── data/
│   └── quality-rules.json            # 质量评分规则
├── templates/
│   ├── code.json                     # 代码模板
│   ├── writing.json                  # 写作模板
│   ├── analysis.json                 # 分析模板
│   ├── creative.json                 # 创意模板
│   └── admin.json                    # 管理模板
└── scripts/
    ├── template-manager.ps1          # 模板管理器
    ├── quality-checker.ps1           # 质量检查器
    ├── optimizer.ps1                 # 优化引擎
    └── preset-manager.ps1            # 预设管理器
```

---

## 🚀 快速开始

### 加载模块
```powershell
Import-Module .\scripts\template-manager.ps1
```

### 使用模板
```powershell
$params = @{
    language = "Python"
    task = "计算斐波那契数列"
}
$result = New-TemplatePrompt -Category code -Name function-generation -Parameters $params
Write-Host $result.Prompt
```

### 检查质量
```powershell
$prompt = "写一个Python函数计算斐波那契数列"
Invoke-PromptQualityCheck -Prompt $prompt -Detailed
```

### 获取优化建议
```powershell
$prompt = "写一个Python函数"
$result = New-OptimizedPrompt -OriginalPrompt $prompt
Show-OptimizationResult -Result $result -Detailed
```

---

## 📊 模板示例

### 代码生成
```json
{
  "name": "function-generation",
  "template": "请生成一个${language}的${function_type}函数，要求：\n1. 完成${task_description}\n2. 遵循${best_practices}\n3. 包含${error_handling}",
  "parameters": {
    "language": ["JavaScript", "Python", "Go"],
    "function_type": ["async", "sync"],
    "task_description": ["处理API请求"],
    "best_practices": ["错误处理", "性能优化"]
  }
}
```

### 质量评分示例
```
=== Prompt Quality Check ===

提示词：
写一个Python函数计算斐波那契数列

--- Scoring ---
清晰度: 20/30 ████░░░░
完整性: 15/25 ███░░░░░
结构: 15/20 ████░░░░
风格: 12/15 ███░░░░░
一致性: 8/10 ██░░░░░░

--- Summary ---
Total Score: 70 / 100 ⚠️
```

---

## 💻 命令行使用

### 列出模板
```bash
pe templates --list
pe templates --list -Category code
```

### 使用模板
```bash
pe templates --use code.function-generation --language Python
```

### 检查质量
```bash
pe quality --check "写一个Python函数计算斐波那契数列"
pe quality --check "..." -Detailed
```

### 获取优化建议
```bash
pe optimize --prompt "写一个Python函数"
pe optimize --prompt "..." -Detailed
```

---

## 🔧 高级用法

### 自定义模板
```powershell
$template = @{
    name = "custom-template"
    title = "自定义模板"
    template = "生成一个${topic}的${type}"
    parameters = @{
        topic = ["人工智能", "机器学习"]
        type = ["模型", "算法"]
    }
}
New-PromptTemplate -Category custom -Name "custom-template" -Template $template.template
```

### 批量优化
```powershell
$prompts = @(
    "写一个Python函数"
    "生成一段文本"
    "分析数据"
)
$results = New-BatchOptimizedPrompts -Prompts $prompts
```

### 管理预设
```powershell
# 保存预设
Save-Preset -Name "my-preset" -Category custom -Parameters @{topic="AI"} -Description "我的预设"

# 使用预设
$params = Invoke-Preset -Name "my-preset"

# 导出/导入预设
Export-Presets -OutputPath presets.json
Import-Presets -InputPath presets.json
```

---

## 📈 性能指标

| 指标 | 目标值 | 状态 |
|------|--------|------|
| 模板加载速度 | <100ms | - |
| 质量检查速度 | <500ms | - |
| 优化建议生成 | <1s | - |
| 模板数量 | 100+ | 100+ ✅ |
| 分类数 | 5 | 5 ✅ |

---

## 🔗 集成点

### 与其他技能集成
- **Auto-GPT**: 提供高质量提示词用于任务分解
- **RAG**: 检索相关模板和最佳实践
- **Copilot**: 基于模板提供代码补全建议

### API端点
- `POST /api/templates` - 获取模板
- `POST /api/quality/check` - 质量检查
- `POST /api/optimize` - 优化建议
- `POST /api/presets/use` - 使用预设

---

## 📝 更新日志

### v1.0.0 (2026-02-13)
- 初始版本发布
- 100+ 模板覆盖5大分类
- 完整的质量检查系统
- AI驱动的优化引擎
- 预设管理系统

---

## 🤝 贡献

欢迎提交Issue和Pull Request！

---

## 📄 许可证

MIT License
