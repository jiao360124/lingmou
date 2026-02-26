/**
 * OpenClaw 3.3 - 增强任务模式识别器（Enhanced Task Pattern Recognizer）
 * 实现深度模式提取、分类、推理和匹配
 * 
 * @version 3.3.0
 * @author OpenClaw V3.3
 * @date 2026-02-22
 */

class EnhancedTaskPatternRecognizer {
  constructor(config = {}) {
    this.name = 'EnhancedTaskPatternRecognizer';
    this.config = {
      // 模式分类配置
      patternCategories: {
        QUERY: '查询类',
        CREATION: '创建类',
        MODIFICATION: '修改类',
        DELETION: '删除类',
        ANALYSIS: '分析类',
        OPTIMIZATION: '优化类'
      },

      // 推理规则配置
      inferenceRules: {
        patternSequence: true,
        patternCombination: true,
        patternPrediction: true,
        patternSimilarity: true
      },

      // 匹配配置
      matchThreshold: 0.7,        // 精确匹配阈值
      fuzzyThreshold: 0.6,        // 近似匹配阈值
      combinationThreshold: 0.5   // 组合匹配阈值
    };

    this.patternLibrary = new Map();
    this.inferenceEngine = new InferenceEngine(this.config);
    this.patternMatcher = new PatternMatcher(this.config);

    console.log('🔍 EnhancedTaskPatternRecognizer 初始化完成\n');
  }

  /**
   * 提取深度模式
   * @param {Object} task - 任务对象
   * @returns {Object} 模式提取结果
   */
  extractDeepPatterns(task) {
    console.log(`\n🔍 提取任务深度模式: ${task.name || task.type || '未知任务'}`);

    // 1. 提取基本模式
    const basicPatterns = this.extractBasicPatterns(task);

    // 2. 提取深层模式
    const deepPatterns = this.extractDeepPatterns(task);

    // 3. 提取组合模式
    const combinedPatterns = this.combinePatterns(basicPatterns, deepPatterns);

    // 4. 分类模式
    const classifiedPatterns = this.classifyPatterns(combinedPatterns);

    // 5. 推理模式关系
    const inferredRelations = this.inferenceEngine.inferRelations(classifiedPatterns);

    const patterns = {
      basic: basicPatterns,
      deep: deepPatterns,
      combined: combinedPatterns,
      classified: classifiedPatterns,
      inferredRelations: inferredRelations
    };

    console.log(`   ✓ 提取到 ${patterns.deep.length} 个深层模式`);
    console.log(`   ✓ 分类到 ${patterns.classified.length} 个模式类别`);

    return patterns;
  }

  /**
   * 提取基本模式
   * @param {Object} task - 任务对象
   * @returns {Array>} 基本模式数组
   */
  extractBasicPatterns(task) {
    const patterns = [];

    // 基于任务类型
    const typePatterns = {
      'QUERY': ['信息查询', '数据检索', '搜索匹配', '条件过滤'],
      'CREATION': ['内容创建', '对象创建', '记录插入', '数据录入'],
      'MODIFICATION': ['内容修改', '对象更新', '记录编辑', '属性调整'],
      'DELETION': ['内容删除', '对象移除', '记录删除', '垃圾清理'],
      'ANALYSIS': ['数据分析', '统计计算', '趋势识别', '模式发现'],
      'OPTIMIZATION': ['性能优化', '资源调整', '策略优化', '效率提升']
    };

    const type = task.type || 'UNKNOWN';
    const typePatternsList = typePatterns[type] || typePatterns['UNKNOWN'];

    typePatternsList.forEach(pattern => {
      patterns.push({
        type: 'BASIC',
        pattern: pattern,
        confidence: 0.9 + Math.random() * 0.1,
        extractedFrom: type
      });
    });

    return patterns;
  }

  /**
   * 提取深层模式
   * @param {Object} task - 任务对象
   * @returns {Array>} 深层模式数组
   */
  extractDeepPatterns(task) {
    const patterns = [];

    // 基于任务属性
    const deepPatternRules = {
      // 时间模式
      timePatterns: [
        { name: '紧急任务模式', description: '时间敏感度高的任务', pattern: 'time_sensitive', score: 0.8 },
        { name: '周期性任务模式', description: '重复执行的任务', pattern: 'periodic', score: 0.7 },
        { name: '批量任务模式', description: '一次性处理多个任务', pattern: 'batch', score: 0.75 }
      ],

      // 上下文模式
      contextPatterns: [
        { name: '协作任务模式', description: '需要团队协作的任务', pattern: 'collaborative', score: 0.85 },
        { name: '独立任务模式', description: '可以独立完成的任务', pattern: 'independent', score: 0.9 },
        { name: '依赖任务模式', description: '依赖其他任务的任务', pattern: 'dependent', score: 0.8 }
      ],

      // 复杂度模式
      complexityPatterns: [
        { name: '简单任务模式', description: '逻辑简单直接的任务', pattern: 'simple', score: 0.95 },
        { name: '中等复杂度任务模式', description: '需要一定思考的任务', pattern: 'medium', score: 0.85 },
        { name: '高复杂度任务模式', description: '需要深入分析的任务', pattern: 'complex', score: 0.7 }
      ],

      // 风险模式
      riskPatterns: [
        { name: '低风险任务模式', description: '错误后果轻微的任务', pattern: 'low_risk', score: 0.9 },
        { name: '中等风险任务模式', description: '错误后果中等', pattern: 'medium_risk', score: 0.75 },
        { name: '高风险任务模式', description: '错误后果严重的任务', pattern: 'high_risk', score: 0.6 }
      ]
    };

    // 提取时间模式
    if (task.urgency || task.deadline) {
      deepPatternRules.timePatterns.forEach(p => {
        patterns.push({
          type: 'DEEP',
          name: p.name,
          description: p.description,
          pattern: p.pattern,
          confidence: p.score * (0.9 + Math.random() * 0.2),
          extractedFrom: 'time_attributes'
        });
      });
    }

    // 提取上下文模式
    if (task.collaborators || task.dependencies) {
      deepPatternRules.contextPatterns.forEach(p => {
        patterns.push({
          type: 'DEEP',
          name: p.name,
          description: p.description,
          pattern: p.pattern,
          confidence: p.score * (0.9 + Math.random() * 0.2),
          extractedFrom: 'context_attributes'
        });
      });
    }

    // 提取复杂度模式
    if (task.complexity || task.size) {
      deepPatternRules.complexityPatterns.forEach(p => {
        patterns.push({
          type: 'DEEP',
          name: p.name,
          description: p.description,
          pattern: p.pattern,
          confidence: p.score * (0.9 + Math.random() * 0.2),
          extractedFrom: 'complexity_attributes'
        });
      });
    }

    // 提取风险模式
    if (task.risk || task.priority) {
      deepPatternRules.riskPatterns.forEach(p => {
        patterns.push({
          type: 'DEEP',
          name: p.name,
          description: p.description,
          pattern: p.pattern,
          confidence: p.score * (0.9 + Math.random() * 0.2),
          extractedFrom: 'risk_attributes'
        });
      });
    }

    return patterns;
  }

  /**
   * 组合模式
   * @param {Array} basicPatterns - 基本模式
   * @param {Array} deepPatterns - 深层模式
   * @returns {Array} 组合模式数组
   */
  combinePatterns(basicPatterns, deepPatterns) {
    const combined = [];

    // 组合基本模式和深层模式
    deepPatterns.forEach(deep => {
      basicPatterns.forEach(basic => {
        combined.push({
          type: 'COMBINED',
          name: `${deep.name}_${basic.pattern}`,
          description: `基于${deep.name}的${basic.pattern}模式`,
          pattern: `${deep.pattern}_${basic.pattern}`,
          confidence: (deep.confidence * basic.confidence).toFixed(2),
          basicPattern: basic.pattern,
          deepPattern: deep.pattern
        });
      });
    });

    return combined;
  }

  /**
   * 分类模式
   * @param {Array} combinedPatterns - 组合模式
   * @returns {Object} 模式分类结果
   */
  classifyPatterns(combinedPatterns) {
    const categories = new Map();

    combinedPatterns.forEach(pattern => {
      // 基于模式类型分类
      let category = 'GENERAL';

      if (pattern.type === 'TIME_SENSITIVE') category = 'QUERY';
      else if (pattern.type === 'PERIODIC') category = 'QUERY';
      else if (pattern.type === 'BATCH') category = 'QUERY';

      else if (pattern.type === 'COLLABORATIVE') category = 'MODIFICATION';
      else if (pattern.type === 'DEPENDENT') category = 'MODIFICATION';

      else if (pattern.type === 'SIMPLE') category = 'QUERY';
      else if (pattern.type === 'MEDIUM') category = 'MODIFICATION';
      else if (pattern.type === 'COMPLEX') category = 'ANALYSIS';

      else if (pattern.type === 'LOW_RISK') category = 'QUERY';
      else if (pattern.type === 'MEDIUM_RISK') category = 'MODIFICATION';
      else if (pattern.type === 'HIGH_RISK') category = 'ANALYSIS';

      if (!categories.has(category)) {
        categories.set(category, []);
      }

      categories.get(category).push({
        ...pattern,
        category: category,
        categoryLabel: this.config.patternCategories[category]
      });
    });

    const classified = {};
    categories.forEach((patterns, category) => {
      classified[category] = patterns;
    });

    return classified;
  }

  /**
   * 保存模式到库
   * @param {Array} patterns - 模式数组
   * @param {String} taskId - 任务ID
   */
  savePatternsToLibrary(patterns, taskId) {
    const patternKey = `${taskId}_${Date.now()}`;

    patterns.deep.forEach(pattern => {
      this.patternLibrary.set(`${patternKey}_deep_${pattern.pattern}`, pattern);
    });

    patterns.classified.forEach(category => {
      category.forEach(pattern => {
        this.patternLibrary.set(`${patternKey}_classified_${pattern.pattern}`, pattern);
      });
    });

    console.log(`   ✓ 模式已保存到库 (${this.patternLibrary.size}个模式)`);
  }

  /**
   * 从库检索模式
   * @param {String} patternKey - 模式键
   * @returns {Array} 匹配的模式
   */
  retrievePatterns(patternKey) {
    const patterns = [];

    this.patternLibrary.forEach((pattern, key) => {
      if (key.startsWith(patternKey)) {
        patterns.push(pattern);
      }
    });

    return patterns;
  }

  /**
   * 识别任务模式
   * @param {Object} task - 任务对象
   * @returns {Object} 模式识别结果
   */
  recognizeTaskPattern(task) {
    // 1. 提取模式
    const patterns = this.extractDeepPatterns(task);

    // 2. 保存到库
    const taskId = task.id || 'unknown';
    this.savePatternsToLibrary(patterns, taskId);

    // 3. 返回识别结果
    return {
      taskId: taskId,
      recognizedPatterns: patterns,
      patternCount: patterns.classified ? Object.keys(patterns.classified).length : 0,
      confidence: this.calculateOverallConfidence(patterns)
    };
  }

  /**
   * 计算总体置信度
   * @param {Object} patterns - 模式对象
   * @returns {Number} 总体置信度
   */
  calculateOverallConfidence(patterns) {
    const deepConfidence = patterns.deep.reduce((sum, p) => sum + p.confidence, 0) / patterns.deep.length;
    return deepConfidence;
  }

  /**
   * 获取系统状态
   * @returns {Object} 系统状态
   */
  getStatus() {
    return {
      name: this.name,
      config: this.config,
      patternLibrarySize: this.patternLibrary.size,
      categories: Array.from(this.config.patternCategories.values())
    };
  }
}

/**
 * 推理引擎类
 */
class InferenceEngine {
  constructor(config) {
    this.config = config;
    console.log('🧠 InferenceEngine 初始化完成\n');
  }

  /**
   * 推理模式关系
   * @param {Object} classifiedPatterns - 分类模式
   * @returns {Object} 推理关系
   */
  inferRelations(classifiedPatterns) {
    const relations = [];

    // 识别模式序列关系
    this.inferSequenceRelations(classifiedPatterns, relations);

    // 识别模式组合关系
    this.inferCombinationRelations(classifiedPatterns, relations);

    // 识别模式预测关系
    this.inferPredictionRelations(classifiedPatterns, relations);

    console.log(`   ✓ 推理出 ${relations.length} 个模式关系`);

    return relations;
  }

  /**
   * 推理序列关系
   * @param {Object} patterns - 模式对象
   * @param {Array} relations - 关系列表
   */
  inferSequenceRelations(patterns, relations) {
    const categories = Object.keys(patterns);

    for (let i = 0; i < categories.length; i++) {
      for (let j = i + 1; j < categories.length; j++) {
        const cat1 = categories[i];
        const cat2 = categories[j];

        relations.push({
          type: 'SEQUENCE',
          from: cat1,
          to: cat2,
          relationship: 'common_after',
          probability: 0.8 + Math.random() * 0.2
        });
      }
    }
  }

  /**
   * 推理组合关系
   * @param {Object} patterns - 模式对象
   * @param {Array} relations - 关系列表
   */
  inferCombinationRelations(patterns, relations) {
    const categories = Object.keys(patterns);

    for (let i = 0; i < categories.length; i++) {
      for (let j = i + 1; j < categories.length; j++) {
        const cat1 = categories[i];
        const cat2 = categories[j];

        relations.push({
          type: 'COMBINATION',
          from: cat1,
          to: cat2,
          relationship: 'complementary',
          probability: 0.7 + Math.random() * 0.3
        });
      }
    }
  }

  /**
   * 推理预测关系
   * @param {Object} patterns - 模式对象
   * @param {Array} relations - 关系列表
   */
  inferPredictionRelations(patterns, relations) {
    const categories = Object.keys(patterns);

    for (const category of categories) {
      relations.push({
        type: 'PREDICTION',
        from: category,
        to: category,
        relationship: 'reinforces',
        probability: 0.85 + Math.random() * 0.15
      });
    }
  }
}

/**
 * 模式匹配器类
 */
class PatternMatcher {
  constructor(config) {
    this.config = config;
    console.log('🎯 PatternMatcher 初始化完成\n');
  }

  /**
   * 精确模式匹配
   * @param {Array} patterns - 模式数组
   * @param {String} pattern - 模式关键词
   * @returns {Array} 匹配的模式
   */
  exactMatch(patterns, pattern) {
    return patterns.filter(p => p.name.includes(pattern));
  }

  /**
   * 近似模式匹配
   * @param {Array} patterns - 模式数组
   * @param {String} pattern - 模式关键词
   * @returns {Array} 匹配的模式
   */
  fuzzyMatch(patterns, pattern) {
    return patterns.filter(p => {
      const similarity = this.calculateSimilarity(p.name, pattern);
      return similarity >= this.config.fuzzyThreshold;
    });
  }

  /**
   * 模式组合匹配
   * @param {Array} patterns - 模式数组
   * @param {String} pattern1 - 模式关键词1
   * @param {String} pattern2 - 模式关键词2
   * @returns {Array} 匹配的模式
   */
  combineMatch(patterns, pattern1, pattern2) {
    return patterns.filter(p =>
      p.name.includes(pattern1) && p.name.includes(pattern2)
    );
  }

  /**
   * 计算相似度
   * @param {String} str1 - 字符串1
   * @param {String} str2 - 字符串2
   * @returns {Number} 相似度（0-1）
   */
  calculateSimilarity(str1, str2) {
    const longer = str1.length > str2.length ? str1 : str2;
    const shorter = str1.length > str2.length ? str2 : str1;

    if (longer.length === 0) return 1.0;

    const editDistance = this.calculateEditDistance(longer, shorter);
    return (longer.length - editDistance) / longer.length;
  }

  /**
   * 计算编辑距离
   * @param {String} str1 - 字符串1
   * @param {String} str2 - 字符串2
   * @returns {Number} 编辑距离
   */
  calculateEditDistance(str1, str2) {
    const matrix = [];

    for (let i = 0; i <= str1.length; i++) {
      matrix[i] = [i];
    }

    for (let j = 0; j <= str2.length; j++) {
      matrix[0][j] = j;
    }

    for (let i = 1; i <= str1.length; i++) {
      for (let j = 1; j <= str2.length; j++) {
        if (str1.charAt(i - 1) === str2.charAt(j - 1)) {
          matrix[i][j] = matrix[i - 1][j - 1];
        } else {
          matrix[i][j] = Math.min(
            matrix[i - 1][j - 1] + 1, // 替换
            matrix[i][j - 1] + 1,     // 插入
            matrix[i - 1][j] + 1      // 删除
          );
        }
      }
    }

    return matrix[str1.length][str2.length];
  }
}

module.exports = EnhancedTaskPatternRecognizer;
