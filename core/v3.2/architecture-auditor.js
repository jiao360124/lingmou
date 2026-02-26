/**
 * OpenClaw V3.2 - Architecture Auditor
 * 自我重构能力：模块耦合度、冗余代码、重复逻辑、性能瓶颈
 */

class ArchitectureAuditor {
  constructor(config = {}) {
    this.name = 'ArchitectureAuditor';
    this.config = {
      couplingThreshold: 3.0,           // 耦合度阈值
      redundancyThreshold: 0.05,        // 冗余代码阈值 (5%)
      duplicateLogicThreshold: 0.7,     // 重复逻辑相似度阈值 (70%)
      performanceBottleneckThreshold: 0.20, // 性能瓶颈阈值 (20% CPU)
      moduleDependancyThreshold: 0.5,   // 模块依赖度阈值 (50%)
      refactoringPriorityScore: 60,      // 重构优先级评分阈值
      ...config
    };

    this.modules = new Map();
    this.dependencies = [];
    this.couplingReport = null;
  }

  /**
   * 启动架构审计
   */
  async audit(projectPath = process.cwd()) {
    console.log('🔍 开始架构审计...\n');

    // 1. 扫描模块
    await this.scanModules(projectPath);

    // 2. 分析耦合度
    const couplingAnalysis = this.analyzeCoupling();

    // 3. 检测冗余代码
    const redundancyAnalysis = this.detectRedundancy();

    // 4. 识别重复逻辑
    const duplicateLogicAnalysis = this.findDuplicateLogic();

    // 5. 扫描性能瓶颈
    const performanceAnalysis = this.identifyBottlenecks();

    // 6. 生成重构建议
    const refactoringSuggestions = this.generateRefactoringSuggestions({
      coupling: couplingAnalysis,
      redundancy: redundancyAnalysis,
      duplicateLogic: duplicateLogicAnalysis,
      performance: performanceAnalysis
    });

    // 7. 生成模块拆分方案
    const decompositionPlan = this.proposeModuleDecomposition({
      coupling: couplingAnalysis,
      redundancy: redundancyAnalysis,
      duplicateLogic: duplicateLogicAnalysis,
      performance: performanceAnalysis
    });

    const report = {
      timestamp: Date.now(),
      projectPath,
      modules: Array.from(this.modules.entries()),
      coupling: couplingAnalysis,
      redundancy: redundancyAnalysis,
      duplicateLogic: duplicateLogicAnalysis,
      performance: performanceAnalysis,
      refactoringSuggestions,
      decompositionPlan
    };

    console.log('\n✅ 架构审计完成\n');
    return report;
  }

  /**
   * 扫描模块
   */
  async scanModules(projectPath) {
    const jsFiles = await this.findJsFiles(projectPath);
    const tsFiles = await this.findTsFiles(projectPath);

    const allFiles = [...jsFiles, ...tsFiles];

    for (const file of allFiles) {
      const relativePath = this.getRelativePath(projectPath, file);

      try {
        const stats = {
          path: relativePath,
          size: this.getFileSize(file),
          cyclomaticComplexity: await this.calculateCyclomaticComplexity(file),
          codeLines: await this.countCodeLines(file),
          dependencies: await this.extractDependencies(file),
          lastModified: this.getLastModified(file)
        };

        this.modules.set(relativePath, stats);
      } catch (error) {
        console.log(`⚠️  跳过文件 ${file}: ${error.message}`);
      }
    }

    console.log(`✅ 扫描了 ${this.modules.size} 个模块\n`);
  }

  /**
   * 分析耦合度
   */
  analyzeCoupling() {
    const couplingReport = {
      modulePairCoupling: [],
      totalCouplingScore: 0,
      highlyCoupledModules: [],
      couplingByModule: {}
    };

    // 分析模块间依赖关系
    for (const [path1, stats1] of this.modules) {
      const dependencies1 = new Set(stats1.dependencies || []);

      for (const [path2, stats2] of this.modules) {
        if (path1 >= path2) continue;

        const dependencies2 = new Set(stats2.dependencies || []);
        const intersection = [...dependencies1].filter(d => dependencies2.has(d));
        const union = [...dependencies1, ...dependencies2];

        const couplingScore = union.length > 0
          ? intersection.length / union.length
          : 0;

        couplingReport.modulePairCoupling.push({
          module1: path1,
          module2: path2,
          couplingScore: couplingScore.toFixed(3),
          dependencies: intersection
        });

        couplingReport.totalCouplingScore += couplingScore;

        // 高耦合模块
        if (couplingScore > this.config.couplingThreshold) {
          couplingReport.highlyCoupledModules.push({
            module: path1,
            couplingWith: path2,
            score: couplingScore
          });
        }

        // 模块耦合度统计
        couplingReport.couplingByModule[path1] =
          (couplingReport.couplingByModule[path1] || 0) + couplingScore;
      }
    }

    // 平均耦合度
    const pairCount = couplingReport.modulePairCoupling.length;
    couplingReport.averageCoupling = pairCount > 0
      ? (couplingReport.totalCouplingScore / pairCount).toFixed(3)
      : 0;

    // 按模块分组耦合度
    Object.keys(couplingReport.couplingByModule).forEach(module => {
      couplingReport.couplingByModule[module] =
        (couplingReport.couplingByModule[module] / (this.modules.size - 1)).toFixed(3);
    });

    // 存储到实例变量
    this.couplingReport = couplingReport;

    return couplingReport;
  }

  /**
   * 获取模块的耦合度（供其他方法调用）
   */
  couplingByModule(module) {
    if (!this.couplingReport || !this.couplingReport.couplingByModule) {
      return 1.5; // 默认值
    }
    return parseFloat(this.couplingReport.couplingByModule[module] || 1.5);
  }

  /**
   * 检测冗余代码
   */
  detectRedundancy() {
    const redundancyReport = {
      totalLines: 0,
      redundantLines: 0,
      redundantPercentage: 0,
      redundantBlocks: [],
      moduleRedundancy: {}
    };

    const codeBatches = Array.from(this.modules.values())
      .map(m => ({ path: m.path, code: this.readCodeFile(m.path) }));

    // 查找重复代码块（基于哈希）
    const seenBlocks = new Map();
    const blocks = [];

    codeBatches.forEach(({ path, code }) => {
      const lines = code.split('\n');
      const blockMap = new Map();

      lines.forEach((line, index) => {
        // 查找10-50行代码块
        for (let length = 10; length <= 50; length++) {
          if (index + length > lines.length) break;

          const block = lines.slice(index, index + length).join('\n');
          const hash = this.hashString(block);

          if (!blockMap.has(hash)) {
            blockMap.set(hash, { lines: [], hash, firstIndex: index });
          }

          blockMap.get(hash).lines.push(index);
        }
      });

      // 检查重复块
      blockMap.forEach((blockInfo, hash) => {
        if (blockInfo.lines.length > 1) {
          const uniqueLines = blockInfo.lines.length;
          const duplicateLines = blockInfo.lines.length - 1;
          const totalLines = blockInfo.lines.length * blockInfo.lines[0];

          const block = {
            path,
            hash,
            uniqueLines,
            duplicateLines,
            totalLines,
            firstIndex: blockInfo.firstIndex
          };

          blocks.push(block);
          redundancyReport.redundantLines += duplicateLines * blockInfo.lines.length;

          // 按模块统计
          redundancyReport.moduleRedundancy[path] =
            (redundancyReport.moduleRedundancy[path] || 0) + duplicateLines;
        }
      });
    });

    redundancyReport.totalLines = this.modules.size > 0
      ? Object.values(redundancyReport.moduleRedundancy).reduce((a, b) => a + b, 0)
      : 0;

    redundancyReport.redundantPercentage = redundancyReport.totalLines > 0
      ? ((redundancyReport.redundantLines / redundancyReport.totalLines) * 100).toFixed(2)
      : 0;

    redundancyReport.redundantBlocks = blocks
      .sort((a, b) => b.totalLines - a.totalLines)
      .slice(0, 10);

    return redundancyReport;
  }

  /**
   * 识别重复逻辑
   */
  findDuplicateLogic() {
    const duplicateReport = {
      duplicateFunctions: [],
      duplicateClasses: [],
      duplicateCodeSnippets: [],
      totalSimilarities: 0,
      similarPairs: []
    };

    const codeBatches = Array.from(this.modules.values())
      .map(m => ({ path: m.path, code: this.readCodeFile(m.path) }));

    // 基于方法/函数匹配查找重复逻辑
    const functionMap = new Map();

    codeBatches.forEach(({ path, code }) => {
      const functions = this.extractFunctions(code);

      functions.forEach(func => {
        const key = this.sanitizeFunctionSignature(func);
        if (!functionMap.has(key)) {
          functionMap.set(key, []);
        }
        functionMap.get(key).push({ path, ...func });
      });
    });

    // 检查重复函数
    functionMap.forEach((occurrences, key) => {
      if (occurrences.length > 1) {
        const similarity = this.calculateFunctionSimilarity(occurrences[0], occurrences[1]);
        if (similarity >= this.config.duplicateLogicThreshold) {
          duplicateReport.duplicateFunctions.push({
            key,
            count: occurrences.length,
            occurrences,
            similarity: similarity.toFixed(3)
          });
          duplicateReport.totalSimilarities += 1;
        }
      }
    });

    // 生成相似代码对
    codeBatches.forEach((batch1, i) => {
      codeBatches.slice(i + 1).forEach(batch2 => {
        const similarity = this.calculateCodeSimilarity(batch1.code, batch2.code);

        if (similarity >= this.config.duplicateLogicThreshold) {
          duplicateReport.similarPairs.push({
            module1: batch1.path,
            module2: batch2.path,
            similarity: similarity.toFixed(3),
            similarityPercentage: similarity.toFixed(2)
          });
          duplicateReport.totalSimilarities += 1;
        }
      });
    });

    duplicateReport.duplicateCodeSnippets =
      duplicateReport.similarPairs.slice(0, 10);

    return duplicateReport;
  }

  /**
   * 扫描性能瓶颈
   */
  identifyBottlenecks() {
    const performanceReport = {
      performanceHotspots: [],
      slowModules: [],
      memoryUsageBottlenecks: [],
      optimizationOpportunities: []
    };

    // 基于模块统计的性能分析
    this.modules.forEach((stats, path) => {
      const complexityRatio = stats.cyclomaticComplexity / stats.codeLines;
      const sizeRatio = stats.size / 1000;

      // 高复杂度模块
      if (stats.cyclomaticComplexity > 20) {
        performanceReport.performanceHotspots.push({
          module: path,
          complexity: stats.cyclomaticComplexity,
          complexityRatio: complexityRatio.toFixed(3),
          size: stats.size,
          severity: 'HIGH'
        });
      }

      // 大型模块
      if (sizeRatio > 10) {
        performanceReport.slowModules.push({
          module: path,
          size: sizeRatio.toFixed(2),
          codeLines: stats.codeLines,
          complexity: stats.cyclomaticComplexity,
          severity: 'MEDIUM'
        });
      }

      // 高耦合模块（性能问题）
      if (this.couplingByModule(path) > this.config.moduleDependancyThreshold) {
        performanceReport.memoryUsageBottlenecks.push({
          module: path,
          coupling: this.couplingByModule(path),
          severity: 'LOW'
        });
      }
    });

    // 优化机会
    performanceReport.optimizationOpportunities = [
      ...performanceReport.performanceHotspots.map(h => ({
        type: 'reduce_complexity',
        module: h.module,
        recommendation: `降低 ${h.module} 的圈复杂度 (${h.complexity})`,
        priority: h.severity === 'HIGH' ? 3 : 2
      })),
      ...performanceReport.slowModules.map(s => ({
        type: 'reduce_size',
        module: s.module,
        recommendation: `重构 ${s.module}，减少代码行数 (${s.codeLines})`,
        priority: s.severity === 'MEDIUM' ? 2 : 1
      }))
    ];

    // 按严重程度排序
    performanceReport.performanceHotspots.sort((a, b) => b.complexity - a.complexity);
    performanceReport.slowModules.sort((a, b) => b.size - a.size);

    return performanceReport;
  }

  /**
   * 生成重构建议
   */
  generateRefactoringSuggestions(analysis) {
    const suggestions = [];

    // 基于耦合度
    analysis.coupling.highlyCoupledModules.forEach(({ module, couplingWith, score }) => {
      suggestions.push({
        priority: score > 2.0 ? 3 : 2,
        category: 'coupling',
        module,
        problem: `模块 ${module} 与 ${couplingWith} 高度耦合 (评分: ${score})`,
        recommendation: `考虑将 ${module} 和 ${couplingWith} 分离为独立模块`,
        severity: 'HIGH'
      });
    });

    // 基于冗余
    if (analysis.redundancy.redundantPercentage > this.config.redundancyThreshold * 100) {
      const topRedundancy = analysis.redundancy.redundantBlocks[0];

      suggestions.push({
        priority: 3,
        category: 'redundancy',
        module: topRedundancy.path,
        problem: `${topRedundancy.redundantLines} 行冗余代码 (占比 ${analysis.redundancy.redundantPercentage}%)`,
        recommendation: `重构冗余代码，提取公共逻辑`,
        severity: 'HIGH'
      });
    }

    // 基于重复逻辑
    analysis.duplicateLogic.duplicateFunctions.slice(0, 3).forEach(func => {
      suggestions.push({
        priority: 2,
        category: 'duplication',
        module: func.occurrences[0].path,
        problem: `发现 ${func.count} 个相似函数`,
        recommendation: `提取公共函数或继承/组合模式`,
        severity: 'MEDIUM'
      });
    });

    // 基于性能瓶颈
    analysis.performance.performanceHotspots.slice(0, 3).forEach(hotspot => {
      suggestions.push({
        priority: 2,
        category: 'performance',
        module: hotspot.module,
        problem: `圈复杂度过高 (${hotspot.complexity})`,
        recommendation: `重构代码，减少嵌套和分支`,
        severity: 'HIGH'
      });
    });

    // 按优先级排序
    suggestions.sort((a, b) => b.priority - a.priority);

    return suggestions;
  }

  /**
   * 生成模块拆分方案
   */
  proposeModuleDecomposition(analysis) {
    const plan = {
      totalModules: this.modules.size,
      modulesAtRisk: [],
      decompositions: [],
      estimatedImpact: {}
    };

    // 识别需要拆分的模块
    const highlyCoupledModules = new Set();

    analysis.coupling.highlyCoupledModules.forEach(({ module1, module2 }) => {
      highlyCoupledModules.add(module1);
      highlyCoupledModules.add(module2);
    });

    analysis.performance.slowModules.forEach(({ module }) => {
      highlyCoupledModules.add(module);
    });

    // 生成拆分建议
    plan.modulesAtRisk = Array.from(highlyCoupledModules).slice(0, 5);

    highlyCoupledModules.forEach(module => {
      plan.decompositions.push({
        module,
        reason: '高耦合或性能瓶颈',
        suggestedActions: [
          '提取公共接口',
          '解耦依赖关系',
          '拆分为多个子模块',
          '使用事件或消息总线解耦'
        ],
        estimatedImpact: {
          maintainability: '+30%',
          testability: '+40%',
          performance: '+15%'
        }
      });
    });

    // 估算整体影响
    plan.estimatedImpact = {
      totalRiskModules: plan.modulesAtRisk.length,
      estimatedComplexityReduction: (plan.modulesAtRisk.length * 25).toFixed(0),
      estimatedCodeLines: Object.values(analysis.redundancy.moduleRedundancy).reduce((a, b) => a + b, 0).toFixed(0),
      estimatedTestCoverage: 'Expected to improve by 20-30%'
    };

    return plan;
  }

  // ========== 辅助方法 ==========

  async findJsFiles(path) {
    // 简化实现
    return [];
  }

  async findTsFiles(path) {
    // 简化实现
    return [];
  }

  getRelativePath(base, target) {
    // 简化实现
    return target.replace(base + '/', '').replace(base + '\\', '');
  }

  getFileSize(path) {
    // 简化实现
    return 1000;
  }

  async calculateCyclomaticComplexity(path) {
    // 简化实现
    return 10;
  }

  async countCodeLines(path) {
    // 简化实现
    return 100;
  }

  async extractDependencies(path) {
    // 简化实现
    return [];
  }

  getLastModified(path) {
    // 简化实现
    return Date.now();
  }

  readCodeFile(path) {
    // 简化实现
    return '';
  }

  hashString(str) {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash;
    }
    return hash;
  }

  sanitizeFunctionSignature(func) {
    return `${func.name}_${func.params}`.toLowerCase();
  }

  calculateFunctionSimilarity(func1, func2) {
    // 简化实现
    return 0.8;
  }

  calculateCodeSimilarity(code1, code2) {
    // 简化实现
    return 0.75;
  }

  extractFunctions(code) {
    // 简化实现
    return [];
  }

  couplingByModule(module) {
    // 简化实现
    return 1.5;
  }
}

module.exports = ArchitectureAuditor;
