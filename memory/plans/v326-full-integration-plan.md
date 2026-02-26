# 灵眸v3.2.6 - 全面整合计划

**目标:** 整合所有已开发的功能、模块、技能到v3.2.6，优化架构、减少重复、提升稳定性
**方法:** 三阶段渐进式整合（架构清理 → 功能整合 → 深度优化）
**预计总时间:** 45-60分钟

---

## 阶段1: 架构清理（低风险）~15分钟

### 检查点1.1: 备份当前系统
- [ ] Task 1.1.1: 创建完整备份目录 (~3 min)
  - **Action:** `New-Item -Path "backup/v326-integration-$(Get-Date -Format 'yyyyMMdd-HHmmss')" -ItemType Directory -Force`
  - **Verify:** 备份目录创建成功

- [ ] Task 1.1.2: 备份core/、utils/、skills/目录 (~5 min)
  - **Action:** `Copy-Item -Path "core","utils","skills" -Destination $backupPath -Recurse -Force`
  - **Verify:** 所有文件复制成功，文件数量匹配

- [ ] Task 1.1.3: 创建版本配置文件 (~2 min)
  - **Action:** 创建 `core/version-v3.2.6.json`
  - **Verify:** 文件创建成功，包含version、releaseDate、description

### 检查点1.2: 移除重复模块
- [ ] Task 1.2.1: 比较memory-monitor.js文件 (~2 min)
  - **Action:** 比较core/memory-monitor.js和utils/memory-monitor.js
  - **Verify:** 确定哪个版本更新/更完整

- [ ] Task 1.2.2: 移除旧版本的memory-monitor.js (~1 min)
  - **Action:** 删除utils/memory-monitor.js（保留core版本）
  - **Verify:** 文件已删除

- [ ] Task 1.2.3: 比较performance-monitor.js文件 (~2 min)
  - **Action:** 比较core/performance-monitor.js和utils/performance-monitor.js
  - **Verify:** 确定哪个版本更新/更完整

- [ ] Task 1.2.4: 移除旧版本的performance-monitor.js (~1 min)
  - **Action:** 删除utils/performance-monitor.js（保留core版本）
  - **Verify:** 文件已删除

### 检查点1.3: 重组测试文件
- [ ] Task 1.3.1: 创建tests/目录 (~1 min)
  - **Action:** `New-Item -Path "tests" -ItemType Directory -Force`
  - **Verify:** 目录创建成功

- [ ] Task 1.3.2: 移动所有test-*.js文件 (~2 min)
  - **Action:** `Move-Item -Path "utils/test-*.js" -Destination "tests/" -Force`
  - **Verify:** utils/中无test-*.js文件，tests/中有6个测试文件

### 检查点1.4: 清理过时脚本
- [ ] Task 1.4.1: 创建archives/scripts/目录 (~1 min)
  - **Action:** `New-Item -Path "archives/scripts" -ItemType Directory -Force`
  - **Verify:** 目录创建成功

- [ ] Task 1.4.2: 归档v3.2整合脚本 (~1 min)
  - **Action:** `Move-Item -Path "scripts/v32-*.ps1" -Destination "archives/scripts/" -Force`
  - **Verify:** scripts/中无v32-*.ps1文件

- [ ] Task 1.4.3: 归档v3.2.5整合脚本 (~1 min)
  - **Action:** `Move-Item -Path "scripts/v325-*.ps1" -Destination "archives/scripts/" -Force`
  - **Verify:** scripts/中无v325-*.ps1文件

- [ ] Task 1.4.4: 归档过时测试脚本 (~1 min)
  - **Action:** `Move-Item -Path "scripts/test-*.ps1" -Destination "archives/scripts/" -Force`
  - **Verify:** scripts/中无test-*.ps1文件

---

## 阶段2: 功能整合（中风险）~20分钟

### 检查点2.1: 整合AI/LLM工具
- [ ] Task 2.1.1: 分析langchain/、moltbook/、rag/技能依赖 (~3 min)
  - **Action:** 读取三个技能的SKILL.md和依赖文件
  - **Verify:** 确认无强依赖关系

- [ ] Task 2.1.2: 创建ai-toolkit/技能目录 (~1 min)
  - **Action:** `New-Item -Path "skills/ai-toolkit" -ItemType Directory -Force`
  - **Verify:** 目录创建成功

- [ ] Task 2.1.3: 合并langchain技能文档 (~2 min)
  - **Action:** 将langchain/SKILL.md内容整合到ai-toolkit/SKILL.md
  - **Verify:** 文档整合完成

- [ ] Task 2.1.4: 合并moltbook技能文档 (~2 min)
  - **Action:** 将moltbook/SKILL.md内容整合到ai-toolkit/SKILL.md
  - **Verify:** 文档整合完成

- [ ] Task 2.1.5: 合并rag技能文档 (~2 min)
  - **Action:** 将rag/SKILL.md内容整合到ai-toolkit/SKILL.md
  - **Verify:** 文档整合完成

- [ ] Task 2.1.6: 删除原始技能目录 (~1 min)
  - **Action:** `Remove-Item -Path "skills/langchain","skills/moltbook","skills/rag" -Recurse -Force`
  - **Verify:** 目录已删除

### 检查点2.2: 整合搜索工具
- [ ] Task 2.2.1: 分析smart-search/、deepwiki/技能依赖 (~2 min)
  - **Action:** 读取两个技能的SKILL.md和依赖文件
  - **Verify:** 确认无强依赖关系

- [ ] Task 2.2.2: 创建search-toolkit/技能目录 (~1 min)
  - **Action:** `New-Item -Path "skills/search-toolkit" -ItemType Directory -Force`
  - **Verify:** 目录创建成功

- [ ] Task 2.2.3: 合并smart-search技能文档 (~2 min)
  - **Action:** 将smart-search/SKILL.md内容整合到search-toolkit/SKILL.md
  - **Verify:** 文档整合完成

- [ ] Task 2.2.4: 合并deepwiki技能文档 (~2 min)
  - **Action:** 将deepwiki/SKILL.md内容整合到search-toolkit/SKILL.md
  - **Verify:** 文档整合完成

- [ ] Task 2.2.5: 删除原始技能目录 (~1 min)
  - **Action:** `Remove-Item -Path "skills/smart-search","skills/deepwiki" -Recurse -Force`
  - **Verify:** 目录已删除

### 检查点2.3: 整合开发工具
- [ ] Task 2.3.1: 分析api-dev/、database/、sql-toolkit/技能依赖 (~2 min)
  - **Action:** 读取三个技能的SKILL.md和依赖文件
  - **Verify:** 确认无强依赖关系

- [ ] Task 2.3.2: 创建dev-toolkit/技能目录 (~1 min)
  - **Action:** `New-Item -Path "skills/dev-toolkit" -ItemType Directory -Force`
  - **Verify:** 目录创建成功

- [ ] Task 2.3.3: 合并api-dev技能文档 (~2 min)
  - **Action:** 将api-dev/SKILL.md内容整合到dev-toolkit/SKILL.md
  - **Verify:** 文档整合完成

- [ ] Task 2.3.4: 合并database技能文档 (~2 min)
  - **Action:** 将database/SKILL.md内容整合到dev-toolkit/SKILL.md
  - **Verify:** 文档整合完成

- [ ] Task 2.3.5: 合并sql-toolkit技能文档 (~2 min)
  - **Action:** 将sql-toolkit/SKILL.md内容整合到dev-toolkit/SKILL.md
  - **Verify:** 文档整合完成

- [ ] Task 2.3.6: 删除原始技能目录 (~1 min)
  - **Action:** `Remove-Item -Path "skills/api-dev","skills/database","skills/sql-toolkit" -Recurse -Force`
  - **Verify:** 目录已删除

---

## 阶段3: 深度优化（高风险）~15分钟

### 检查点3.1: 部署技能整合脚本
- [ ] Task 3.1.1: 分析skill-integration/脚本依赖 (~3 min)
  - **Action:** 读取所有PS1脚本，识别部署顺序
  - **Verify:** 确定部署优先级

- [ ] Task 3.1.2: 创建集成脚本目录 (~1 min)
  - **Action:** `New-Item -Path "core/integrations" -ItemType Directory -Force`
  - **Verify:** 目录创建成功

- [ ] Task 3.1.3: 转换核心整合脚本为JS (~3 min)
  - **Action:** 选择3个最关键的PS1脚本，转换为JS模块
  - **Verify:** JS模块创建成功，语法正确

- [ ] Task 3.1.4: 归档未转换的整合脚本 (~1 min)
  - **Action:** `Move-Item -Path "skill-integration" -Destination "archives/" -Force`
  - **Verify:** skill-integration已移至archives/

### 检查点3.2: 优化核心架构
- [ ] Task 3.2.1: 创建core/monitoring/目录 (~1 min)
  - **Action:** `New-Item -Path "core/monitoring" -ItemType Directory -Force`
  - **Verify:** 目录创建成功

- [ ] Task 3.2.2: 移动监控模块到子目录 (~2 min)
  - **Action:** 移动performance-monitor、memory-monitor、api-tracker到monitoring/
  - **Verify:** 模块已移动，创建index.js导出

- [ ] Task 3.2.3: 创建core/strategy/目录 (~1 min)
  - **Action:** `New-Item -Path "core/strategy" -ItemType Directory -Force`
  - **Verify:** 目录创建成功

- [ ] Task 3.2.4: 移动策略引擎模块到子目录 (~2 min)
  - **Action:** 移动strategy相关模块到strategy/，创建index.js导出
  - **Verify:** 模块已移动，创建index.js导出

- [ ] Task 3.2.5: 创建core/index.js统一导出 (~2 min)
  - **Action:** 创建统一的导出文件，分类导出所有模块
  - **Verify:** 导出文件创建成功

### 检查点3.3: 完善文档和测试
- [ ] Task 3.3.1: 创建skills/v3.2.6-README.md (~3 min)
  - **Action:** 编写完整的v3.2.6版本文档
  - **Verify:** 文档包含：架构说明、技能列表、使用指南、更新日志

- [ ] Task 3.3.2: 生成整合报告 (~2 min)
  - **Action:** 生成详细的整合报告（reports/v326-integration-report.txt）
  - **Verify:** 报告包含：变更统计、测试结果、性能对比

- [ ] Task 3.3.3: 运行系统测试 (~2 min)
  - **Action:** 运行Gateway测试、技能加载测试、核心模块测试
  - **Verify:** 所有测试通过，系统运行正常

### 检查点3.4: Git提交
- [ ] Task 3.4.1: 生成Git提交信息 (~1 min)
  - **Action:** 使用conventional-commits格式生成提交信息
  - **Verify:** 提交信息完整、清晰

- [ ] Task 3.4.2: 提交所有更改 (~2 min)
  - **Action:** `git add . && git commit -F scripts/commit-v326.txt`
  - **Verify:** Git提交成功，commit hash获取

- [ ] Task 3.4.3: 更新MEMORY.md (~1 min)
  - **Action:** 更新memory/2026-02-26.md，记录整合结果
  - **Verify:** 记录完整，包含所有关键信息

---

## 验证标准

### 功能验证
- [ ] Gateway正常启动和运行
- [ ] 所有技能加载成功（无错误）
- [ ] 核心模块功能正常
- [ ] 测试套件全部通过

### 质量标准
- [ ] 代码重复减少 >30%
- [ ] 技能数量减少 >5个
- [ ] 目录结构清晰合理
- [ ] 文档完整且准确

### 安全验证
- [ ] 备份完整且可恢复
- [ ] 无关键文件丢失
- [ ] 回滚方案可行

---

## 回滚方案

如果整合失败，执行以下步骤：

```powershell
# 恢复备份
$backupPath = "backup/v326-integration-YYYYMMDD-HHMMSS"
Copy-Item -Path "$backupPath/core" -Destination "." -Recurse -Force
Copy-Item -Path "$backupPath/utils" -Destination "." -Recurse -Force
Copy-Item -Path "$backupPath/skills" -Destination "." -Recurse -Force

# 回滚Git
git reset --hard HEAD~1
```

---

## 执行选项

**计划已完成并保存到 `memory/plans/v326-full-integration-plan.md`**

**执行选项：**

**1. 单代理执行（当前会话）** - 我会按顺序执行任务，在每个检查点汇报进度

**2. 多代理并行执行** - 为独立任务生成子代理，并行执行

**您选择哪种执行方式？**
