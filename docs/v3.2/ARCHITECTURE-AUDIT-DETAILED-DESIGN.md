# 架构自审详细设计 (V3.2)

**模块**: 架构自审器
**优先级**: P1
**预计工时**: 32h
**负责人**: 灵眸

---

## 📋 模块概述

架构自审器是 V3.2 的第三个核心模块，让 OpenClaw 具备自我重构能力。通过定期检查模块耦合度、冗余代码、重复逻辑和性能瓶颈，自动生成重构建议和优化方案。

---

## 🎯 核心功能

### 1. 架构健康度扫描器 (Architecture Health Scanner)

**功能描述**：
全面扫描系统架构，识别健康问题。

#### 扫描维度

```typescript
interface ArchitectureHealth {
  overallHealth: "EXCELLENT" | "GOOD" | "FAIR" | "POOR" | "CRITICAL";
  scores: {
    coupling: number;        // 0-1
    duplication: number;     // 0-1
    cyclomaticComplexity: number;  // 0-1
    performance: number;     // 0-1
  };
  issues: Issue[];
  recommendations: Recommendation[];
  timestamp: Date;
}
```

#### 扫描算法

```javascript
class ArchitectureHealthScanner {
  constructor(projectRoot) {
    this.projectRoot = projectRoot;
    this.fileCache = new Map();
    this.dependencyGraph = new Map();
  }

  async scan() {
    const startTime = Date.now();

    // 1. 扫描项目结构
    await this.scanProjectStructure();

    // 2. 分析依赖关系
    await this.analyzeDependencies();

    // 3. 检测代码重复
    const duplicationScore = await this.detectDuplication();

    // 4. 检测循环依赖
    const cyclomaticComplexity = await this.analyzeComplexity();

    // 5. 检测性能瓶颈
    const performance = await this.analyzePerformance();

    // 6. 检测模块耦合度
    const couplingScore = await this.analyzeCoupling();

    // 7. 生成综合评分
    const scores = {
      coupling: couplingScore,
      duplication: duplicationScore,
      cyclomaticComplexity,
      performance
    };

    const overallHealth = this.calculateOverallHealth(scores);

    // 8. 生成问题报告
    const issues = await this.generateIssues(scores);
    const recommendations = await this.generateRecommendations(scores, issues);

    return {
      overallHealth,
      scores,
      issues,
      recommendations,
      timestamp: new Date(),
      scanDuration: Date.now() - startTime
    };
  }

  async scanProjectStructure() {
    // 扫描项目结构
    const files = await this.scanFiles();

    for (const file of files) {
      this.fileCache.set(file.path, {
        path: file.path,
        size: file.size,
        lastModified: file.lastModified,
        content: null  // 延迟加载
      });
    }
  }

  async scanFiles() {
    // 扫描所有源文件
    const filePatterns = [
      '**/*.js',
      '**/*.ts',
      '**/*.jsx',
      '**/*.tsx'
    ];

    const files = [];

    for (const pattern of filePatterns) {
      const matchedFiles = await this.glob(pattern, this.projectRoot);
      files.push(...matchedFiles);
    }

    return files;
  }

  async analyzeDependencies() {
    // 分析依赖关系
    this.dependencyGraph = new Map();

    for (const [path, file] of this.fileCache) {
      const deps = await this.extractDependencies(path);

      this.dependencyGraph.set(path, {
        file,
        dependencies: deps,
        dependents: []
      });

      // 记录依赖关系
      for (const dep of deps) {
        const depPath = this.resolveDependencyPath(dep);
        if (depPath && this.dependencyGraph.has(depPath)) {
          this.dependencyGraph.get(depPath).dependents.push(path);
        }
      }
    }
  }

  async extractDependencies(filePath) {
    // 提取文件依赖
    const content = await this.readFile(filePath);
    const deps = new Set();

    // 检查 require/imports
    const requireRegex = /require\(['"]([^'"]+)['"]\)/g;
    let match;
    while ((match = requireRegex.exec(content)) !== null) {
      deps.add(match[1]);
    }

    // 检查 ES6 imports
    const importRegex = /import\s+(?:\w+\s+from\s+)?['"]([^'"]+)['"]/g;
    while ((match = importRegex.exec(content)) !== null) {
      deps.add(match[1]);
    }

    return Array.from(deps);
  }

  async detectDuplication() {
    // 检测代码重复
    let duplicateLines = 0;
    let totalLines = 0;
    const duplicateBlocks = [];

    const files = Array.from(this.fileCache.values());

    for (let i = 0; i < files.length; i++) {
      for (let j = i + 1; j < files.length; j++) {
        const block = await this.findDuplicateBlock(files[i], files[j]);

        if (block) {
          duplicateLines += block.lines;
          duplicateBlocks.push({
            file1: files[i].path,
            file2: files[j].path,
            lines: block.lines,
            similarity: block.similarity
          });
        }
      }
    }

    // 计算重复率
    totalLines = await this.countTotalLines();
    const duplicationRate = duplicateLines / totalLines;

    return {
      score: 1 - duplicationRate,  // 1-重复率
      duplicationRate,
      duplicateBlocks,
      totalLines,
      duplicateLines
    };
  }

  async analyzeComplexity() {
    // 分析圈复杂度
    const files = Array.from(this.fileCache.values());
    let totalComplexity = 0;
    let maxComplexity = 0;
    const highComplexityFiles = [];

    for (const file of files) {
      const content = await this.readFile(file.path);
      const complexity = this.calculateCyclomaticComplexity(content);

      totalComplexity += complexity;

      if (complexity > maxComplexity) {
        maxComplexity = complexity;
      }

      if (complexity > 15) {  // 高复杂度阈值
        highComplexityFiles.push({
          path: file.path,
          complexity,
          estimatedLines: await this.countLines(file.path)
        });
      }
    }

    const avgComplexity = totalComplexity / files.length;
    const complexityScore = Math.max(0, 1 - avgComplexity / 20);  // 归一化

    return {
      score: complexityScore,
      avgComplexity,
      maxComplexity,
      highComplexosityFiles
    };
  }

  async calculateCyclomaticComplexity(code) {
    // 计算圈复杂度
    let complexity = 1;  // 基础复杂度

    // 检测条件语句
    const conditions = [
      /\b(if|else if|else|switch|case)\b/g,
      /\b(for|while|do|for...in|for...of)\b/g,
      /\b(return|break|continue)\b/g
    ];

    for (const condition of conditions) {
      const matches = code.match(condition);
      if (matches) {
        complexity += matches.length;
      }
    }

    return complexity;
  }

  async analyzePerformance() {
    // 分析性能瓶颈
    const performanceIssues = [];
    const metrics = {
      totalFiles: 0,
      totalLines: 0,
      totalSize: 0,
      avgFileComplexity: 0,
      biggestFiles: []
    };

    for (const file of this.fileCache.values()) {
      metrics.totalFiles++;
      metrics.totalSize += file.size;
      metrics.totalLines += await this.countLines(file.path);

      const complexity = await this.calculateComplexity(file.path);
      metrics.avgFileComplexity += complexity;

      if (file.size > 100000) {  // 超过100KB
        performanceIssues.push({
          type: "large_file",
          path: file.path,
          size: file.size,
          suggestion: "Consider splitting this file"
        });
      }

      if (complexity > 10) {
        performanceIssues.push({
          type: "high_complexity",
          path: file.path,
          complexity,
          suggestion: "Refactor to reduce complexity"
        });
      }

      metrics.biggestFiles.push({
        path: file.path,
        size: file.size
      });
    }

    metrics.avgFileComplexity /= metrics.totalFiles;
    metrics.biggestFiles.sort((a, b) => b.size - a.size);

    // 计算性能评分
    const performanceScore = this.calculatePerformanceScore(metrics, performanceIssues);

    return {
      score: performanceScore,
      metrics,
      issues: performanceIssues
    };
  }

  async analyzeCoupling() {
    // 分析模块耦合度
    let totalDependencies = 0;
    let totalDependents = 0;
    let maxCoupling = 0;
    const highCouplingFiles = [];

    for (const [path, info] of this.dependencyGraph) {
      const depCount = info.dependencies.length;
      const dependents = info.dependents.length;

      totalDependencies += depCount;
      totalDependents += dependents;

      const couplingDegree = dependents.length / Math.max(depCount, 1);

      if (couplingDegree > maxCoupling) {
        maxCoupling = couplingDegree;
      }

      if (couplingDegree > 0.5) {
        highCouplingFiles.push({
          path,
          dependencies: depCount,
          dependents,
          couplingDegree
        });
      }
    }

    const avgCoupling = totalDependents / Math.max(totalDependencies, 1);
    const couplingScore = Math.max(0, 1 - avgCoupling);

    return {
      score: couplingScore,
      avgCoupling,
      maxCoupling,
      highCouplingFiles,
      totalDependencies,
      totalDependents
    };
  }

  calculateOverallHealth(scores) {
    // 计算综合健康度
    const avgScore = Object.values(scores).reduce((a, b) => a + b, 0) / 4;

    if (avgScore > 0.8) return "EXCELLENT";
    if (avgScore > 0.7) return "GOOD";
    if (avgScore > 0.5) return "FAIR";
    if (avgScore > 0.3) return "POOR";
    return "CRITICAL";
  }

  async generateIssues(scores) {
    // 生成问题列表
    const issues = [];

    if (scores.duplication.score < 0.8) {
      issues.push({
        category: "duplication",
        severity: "MEDIUM",
        description: `高代码重复率 (${(1 - scores.duplication.duplicationRate).toFixed(2)})`,
        suggestion: "提取公共函数到独立模块"
      });
    }

    if (scores.cyclomaticComplexity.score < 0.6) {
      issues.push({
        category: "complexity",
        severity: "MEDIUM",
        description: `平均圈复杂度 ${(scores.cyclomaticComplexity.avgComplexity).toFixed(2)}`,
        suggestion: "重构复杂函数，拆分为小函数"
      });
    }

    if (scores.performance.score < 0.6) {
      issues.push({
        category: "performance",
        severity: "HIGH",
        description: "发现性能瓶颈",
        suggestion: "优化大文件和复杂函数"
      });
    }

    if (scores.coupling.score < 0.7) {
      issues.push({
        category: "coupling",
        severity: "HIGH",
        description: `平均耦合度 ${(scores.coupling.avgCoupling).toFixed(2)}`,
        suggestion: "降低模块耦合度，增加模块内聚"
      });
    }

    return issues;
  }

  async generateRecommendations(scores, issues) {
    // 生成重构建议
    const recommendations = [];

    if (issues.some(i => i.category === "coupling")) {
      recommendations.push({
        title: "降低模块耦合度",
        category: "coupling",
        priority: "HIGH",
        description: "当前平均耦合度较高，建议引入接口抽象",
        solution: "创建 IControlTower 接口，减少直接依赖",
        estimatedEffort: "MEDIUM",
        expectedBenefit: "提高可测试性、可维护性"
      });
    }

    if (issues.some(i => i.category === "duplication")) {
      recommendations.push({
        title: "消除代码重复",
        category: "duplication",
        priority: "MEDIUM",
        description: "检测到重复代码，建议提取公共逻辑",
        solution: "创建公共工具模块",
        estimatedEffort: "LOW",
        expectedBenefit: "减少维护成本、提高代码质量"
      });
    }

    if (issues.some(i => i.category === "performance")) {
      recommendations.push({
        title: "性能优化",
        category: "performance",
        priority: "MEDIUM",
        description: "发现性能瓶颈，建议优化大文件",
        solution: "拆分大文件、优化算法",
        estimatedEffort: "MEDIUM",
        expectedBenefit: "提高响应速度、减少资源占用"
      });
    }

    if (issues.some(i => i.category === "complexity")) {
      recommendations.push({
        title: "降低复杂度",
        category: "complexity",
        priority: "LOW",
        description: "部分函数复杂度过高",
        solution: "重构函数、拆分子函数",
        estimatedEffort: "MEDIUM",
        expectedBenefit: "提高可读性、降低维护难度"
      });
    }

    return recommendations;
  }

  async calculatePerformanceScore(metrics, issues) {
    // 计算性能评分
    let score = 0.5;  // 基础分

    // 根据文件大小评分
    const avgFileSize = metrics.totalSize / metrics.totalFiles;
    if (avgFileSize < 50000) score += 0.1;
    else if (avgFileSize > 100000) score -= 0.1;

    // 根据复杂度评分
    if (metrics.avgFileComplexity < 10) score += 0.1;
    else if (metrics.avgFileComplexity > 20) score -= 0.1;

    // 根据问题数量评分
    score -= issues.length * 0.05;

    return Math.max(0, Math.min(1, score));
  }

  async findDuplicateBlock(file1, file2) {
    // 查找重复代码块
    const content1 = await this.readFile(file1.path);
    const content2 = await this.readFile(file2.path);

    // 简化比较：按行比较
    const lines1 = content1.split('\n');
    const lines2 = content2.split('\n');

    let maxSimilarity = 0;
    let block = null;

    for (let i = 0; i < lines1.length; i++) {
      for (let j = 0; j < lines2.length; j++) {
        const similarity = this.calculateLineSimilarity(lines1[i], lines2[j]);

        if (similarity > maxSimilarity) {
          maxSimilarity = similarity;
          block = {
            line1: i,
            line2: j,
            similarity
          };
        }
      }
    }

    return maxSimilarity > 0.8 ? block : null;
  }

  calculateLineSimilarity(line1, line2) {
    // 计算行相似度
    if (line1 === line2) return 1;

    // 简单比较：删除空格后比较
    const clean1 = line1.trim();
    const clean2 = line2.trim();

    if (clean1 === clean2) return 1;

    // 计算公共子串长度
    const common = this.findCommonSubstring(clean1, clean2);
    return common / Math.max(clean1.length, clean2.length);
  }

  findCommonSubstring(str1, str2) {
    // 查找最长公共子串
    const matrix = [];

    for (let i = 0; i <= str1.length; i++) {
      matrix[i] = new Array(str2.length + 1).fill(0);
    }

    let maxLength = 0;
    let endIndex = 0;

    for (let i = 1; i <= str1.length; i++) {
      for (let j = 1; j <= str2.length; j++) {
        if (str1[i - 1] === str2[j - 1]) {
          matrix[i][j] = matrix[i - 1][j - 1] + 1;

          if (matrix[i][j] > maxLength) {
            maxLength = matrix[i][j];
            endIndex = i;
          }
        } else {
          matrix[i][j] = 0;
        }
      }
    }

    return str1.substring(endIndex - maxLength, endIndex);
  }

  async readFile(filePath) {
    const file = this.fileCache.get(filePath);

    if (!file.content) {
      file.content = await this.readFileContent(filePath);
    }

    return file.content;
  }

  async readFileContent(filePath) {
    // 读取文件内容（实际实现）
    // 这里只是示例
    return "";
  }

  async countLines(filePath) {
    const content = await this.readFileContent(filePath);
    return content.split('\n').length;
  }

  async countTotalLines() {
    let total = 0;
    for (const file of this.fileCache.values()) {
      total += await this.countLines(file.path);
    }
    return total;
  }

  resolveDependencyPath(dep) {
    // 解析依赖路径
    return null;  // 示例
  }

  glob(pattern, cwd) {
    // 实现文件匹配
    return [];  // 示例
  }
}
```

**文件位置**: `core/architecture-health-scanner.js`

---

## 🚀 实施计划

### Week 5: 架构自审基础

| 任务 | 工时 | 优先级 | 状态 |
|------|------|--------|------|
| 架构健康度扫描器 | 10h | P0 | 📋 |
| 模块耦合度分析 | 6h | P0 | 📋 |
| 代码重复检测 | 6h | P1 | 📋 |
| 性能瓶颈定位 | 6h | P1 | 📋 |

### Week 6: 重构建议

| 任务 | 工时 | 优先级 | 状态 |
|------|------|--------|------|
| 模块拆分建议器 | 8h | P0 | 📋 |
| 依赖优化建议器 | 6h | P0 | 📋 |
| 架构演进路线图 | 4h | P1 | 📋 |
| 自动化重构工具 | 12h | P2 | 📋 |

---

## 📊 性能指标

| 指标 | 目标 | 预期 |
|------|------|------|
| 扫描速度 | < 5s | 3.2s |
| 重复检测准确率 | > 85% | 88% |
| 耦合度分析准确率 | > 90% | 92% |

---

**下一步**: 完成 V3.2 规划文档？ 🎯
