/**
 * OpenClaw V3.2 - Cognitive Layer
 * 从"状态/指标/历史记录"升级为"结构化认知层"
 * 任务模式识别 → 用户行为画像 → 结构化经验库 → 失败模式数据库
 */

class CognitiveLayer {
  constructor(config = {}) {
    this.config = {
      taskPatternThreshold: 0.7,       // 任务模式识别阈值
      behaviorProfileThreshold: 5,     // 行为画像最低交互次数
      experienceMemoryDays: 30,        // 经验库保留天数
      failurePatternThreshold: 3,      // 失败模式最低出现次数
      ...config
    };

    // 任务模式库
    this.taskPatterns = new Map();

    // 用户行为画像
    this.userProfiles = new Map();

    // 结构化经验库
    this.experienceLibrary = [];

    // 失败模式数据库
    this.failureDatabase = [];
  }

  /**
   * 记录任务模式
   * @param {Object} taskInfo - 任务信息
   * @param {Object} outcome - 任务结果
   */
  recordTaskPattern(taskInfo, outcome) {
    const {
      description,
      type,
      complexity,
      successRate,
      executionTime
    } = taskInfo;

    // 计算任务特征向量
    const features = this.extractTaskFeatures(description, type, complexity);

    // 查找匹配模式
    let matchedPattern = null;
    let similarityScore = 0;

    for (const [patternId, pattern] of this.taskPatterns) {
      const score = this.calculatePatternSimilarity(features, pattern.features);
      if (score > similarityScore && score >= this.config.taskPatternThreshold) {
        similarityScore = score;
        matchedPattern = { id: patternId, pattern, score };
      }
    }

    if (matchedPattern) {
      // 更新现有模式
      this.updateExistingPattern(matchedPattern.pattern, outcome, executionTime);
    } else {
      // 创建新模式
      const newPattern = {
        id: this.genId('PATTERN'),
        features,
        type,
        successRate: outcome.success ? outcome.successRate : 0,
        averageExecutionTime: executionTime,
        occurrenceCount: 1,
        lastExecuted: Date.now(),
        successCount: outcome.success ? 1 : 0,
        failureCount: outcome.success ? 0 : 1
      };
      this.taskPatterns.set(newPattern.id, newPattern);
    }
  }

  /**
   * 提取任务特征
   */
  extractTaskFeatures(description, type, complexity) {
    return {
      type,
      complexity,
      keywords: this.extractKeywords(description),
      length: description.length,
      hasTechnicalTerms: /\b(api|database|server|client|frontend|backend|api|service)\b/i.test(description),
      hasUrgency: /\b(urgent|紧急|critical|重要|必须|立刻)\b/i.test(description),
      hasOptimization: /\b(optimize|优化|improve|改进|performance|性能)\b/i.test(description)
    };
  }

  /**
   * 提取关键词
   */
  extractKeywords(description) {
    const commonWords = /\b(the|and|is|are|was|were|be|been|being|have|has|had|do|does|did|will|would|could|should|may|might|must|can|to|of|in|on|at|by|for|with|about|as|into|through|during|before|after|above|below|between|under|again|further|then|once|here|there|when|where|why|how|all|each|few|more|most|other|some|such|no|nor|not|only|own|same|so|than|too|very|s|t|can|will|just|don|should|now)\b/i;

    const sentences = description.match(/[^.!?]+[.!?]/g) || [];
    const words = sentences.join(' ').toLowerCase().split(/\s+/);
    const keywords = words.filter(w => w.length > 2 && !commonWords.test(w));

    return keywords.slice(0, 10);
  }

  /**
   * 计算模式相似度
   */
  calculatePatternSimilarity(f1, f2) {
    let score = 0;

    // 类型相似度
    if (f1.type === f2.type) score += 0.4;

    // 关键词重叠
    const keywordIntersection = f1.keywords.filter(k => f2.keywords.includes(k)).length;
    const keywordJaccard = keywordIntersection / (new Set([...f1.keywords, ...f2.keywords]).size);
    score += keywordJaccard * 0.3;

    // 复杂度相似度
    score += Math.abs(f1.complexity - f2.complexity) < 1 ? 0.3 : 0;

    return score;
  }

  /**
   * 更新现有模式
   */
  updateExistingPattern(pattern, outcome, executionTime) {
    pattern.occurrenceCount++;
    pattern.lastExecuted = Date.now();

    if (outcome.success) {
      pattern.successCount++;
      pattern.averageExecutionTime = (
        pattern.averageExecutionTime * (pattern.successCount - 1) + executionTime
      ) / pattern.successCount;
      pattern.successRate = pattern.successCount / pattern.occurrenceCount;
    } else {
      pattern.failureCount++;
      pattern.successRate = pattern.successCount / pattern.occurrenceCount;
    }
  }

  /**
   * 识别用户行为画像
   */
  buildUserProfile(interactionData) {
    const { userId, interactions } = interactionData;

    if (interactions.length < this.config.behaviorProfileThreshold) {
      return null;
    }

    // 计算行为特征
    const features = this.extractBehaviorFeatures(interactions);

    // 构建画像
    const profile = {
      id: userId || this.genId('PROFILE'),
      userId,
      behavior: features,
      interactionCount: interactions.length,
      created: Date.now(),
      lastUpdated: Date.now()
    };

    this.userProfiles.set(profile.id, profile);

    return profile;
  }

  /**
   * 提取行为特征
   */
  extractBehaviorFeatures(interactions) {
    const intentFreq = {};
    const timePattern = {};
    const responseStyle = {};
    let totalInteractions = interactions.length;

    interactions.forEach((interaction, index) => {
      // 意图频率
      intentFreq[interaction.intent] = (intentFreq[interaction.intent] || 0) + 1;

      // 时间模式
      const hour = new Date(interaction.timestamp).getHours();
      const timeKey = `${hour}:00-${hour + 2}:00`;
      timePattern[timeKey] = (timePattern[timeKey] || 0) + 1;

      // 响应风格
      if (interaction.responseStyle) {
        responseStyle[interaction.responseStyle]++;
      }
    });

    return {
      intentDistribution: intentFreq,
      intentDominant: this.getDominantKey(intentFreq),
      timeDistribution: timePattern,
      timePeak: this.getPeakTime(timePattern),
      responseStyleDistribution: responseStyle,
      responseStyleDominant: this.getDominantKey(responseStyle)
    };
  }

  /**
   * 记录结构化经验
   */
  storeStructuredExperience(patternId, strategy, outcome) {
    const experience = {
      id: this.genId('EXPERIENCE'),
      patternId,
      strategy: {
        type: strategy.type,
        config: this.sanitizeStrategyConfig(strategy)
      },
      outcome: {
        success: outcome.success,
        successRate: outcome.successRate,
        executionTime: outcome.executionTime,
        metrics: outcome.metrics
      },
      timestamp: Date.now(),
      lifetime: this.config.experienceMemoryDays * 24 * 60 * 60 * 1000
    };

    this.experienceLibrary.push(experience);
    return experience.id;
  }

  /**
   * 记录失败模式
   */
  recordFailurePattern(failureCases) {
    if (failureCases.length < this.config.failurePatternThreshold) {
      return null;
    }

    // 聚合失败模式
    const pattern = {
      id: this.genId('FAILURE_PATTERN'),
      failures: failureCases,
      totalFailures: failureCases.length,
      triggerConditions: this.extractTriggerConditions(failureCases),
      abstractPattern: this.abstractFailurePattern(failureCases),
      created: Date.now(),
      lastUpdated: Date.now()
    };

    this.failureDatabase.push(pattern);
    return pattern.id;
  }

  /**
   * 抽象失败模式
   */
  abstractFailurePattern(failureCases) {
    // 分析失败原因
    const failureReasons = failureCases.map(f => f.reason).filter(Boolean);
    const causeCategories = {};

    failureReasons.forEach(reason => {
      const category = this.categorizeFailureReason(reason);
      causeCategories[category] = (causeCategories[category] || 0) + 1;
    });

    return {
      categories: causeCategories,
      mostCommonCategory: this.getDominantKey(causeCategories),
      patterns: this.extractRecurringPatterns(failureCases)
    };
  }

  /**
   * 分类失败原因
   */
  categorizeFailureReason(reason) {
    const keywords = {
      'timeout': /timeout|超时|延迟|slow/i,
      'cost': /cost|成本|token|预算|expense|花费/i,
      'performance': /performance|性能|speed|速度|slow|慢/i,
      'error': /error|失败|fail|失败|exception|异常/i,
      'complexity': /complex|复杂|hard|难|difficult|困难/i
    };

    for (const [category, regex] of Object.entries(keywords)) {
      if (regex.test(reason)) {
        return category;
      }
    }

    return 'unknown';
  }

  /**
   * 获取推荐策略
   */
  getRecommendedStrategy(taskDescription, context = {}) {
    // 1. 查找相似任务模式
    const pattern = this.findSimilarTaskPattern(taskDescription);

    if (pattern && pattern.pattern) {
      // 2. 查找该模式下的成功策略
      const experience = this.getSuccessfulExperienceForPattern(pattern.id);

      if (experience) {
        return {
          type: 'PATTERN_BASED',
          strategy: experience.strategy,
          confidence: pattern.score,
          source: 'task_pattern'
        };
      }
    }

    // 3. 如果没有匹配模式，返回默认策略
    return {
      type: 'DEFAULT',
      strategy: this.getDefaultStrategy(),
      confidence: 0,
      source: 'default'
    };
  }

  /**
   * 预规避失败模式
   */
  getFailureAvoidanceAdvice(taskDescription) {
    // 查找与任务相关的失败模式
    const relatedPatterns = this.findRelatedFailurePatterns(taskDescription);

    if (relatedPatterns.length === 0) {
      return null;
    }

    const advice = {
      patterns: relatedPatterns,
      warnings: [],
      recommendations: []
    };

    relatedPatterns.forEach(pattern => {
      const abstract = pattern.abstractPattern;

      // 生成警告和建议
      if (abstract.categories.timeout) {
        advice.warnings.push('此类型任务存在超时失败风险，建议增加超时时间');
        advice.recommendations.push('使用较慢但更稳定的策略');
      }

      if (abstract.categories.cost) {
        advice.warnings.push('此类型任务成本较高，建议优化预算分配');
        advice.recommendations.push('使用更经济的模型和策略');
      }

      if (abstract.categories.performance) {
        advice.warnings.push('此类型任务性能瓶颈较多');
        advice.recommendations.push('优化执行流程和资源分配');
      }
    });

    return advice;
  }

  /**
   * 清理过期数据
   */
  cleanupExpiredData() {
    const now = Date.now();
    const expiredLimit = this.config.experienceMemoryDays * 24 * 60 * 60 * 1000;

    // 清理过期的经验
    this.experienceLibrary = this.experienceLibrary.filter(ex =>
      now - ex.timestamp < expiredLimit
    );

    // 清理过期的失败模式（超过1个月）
    this.failureDatabase = this.failureDatabase.filter(f =>
      now - f.created < (30 * 24 * 60 * 60 * 1000)
    );
  }

  /**
   * 获取认知层统计
   */
  getStatistics() {
    return {
      taskPatterns: this.taskPatterns.size,
      userProfiles: this.userProfiles.size,
      experienceLibrary: this.experienceLibrary.length,
      failureDatabase: this.failureDatabase.length,
      taskPatternTypes: this.getTaskPatternTypes(),
      behaviorProfileDominantStyles: this.getDominantBehaviorStyles()
    };
  }

  // ========== 辅助方法 ==========

  getDominantKey(freqMap) {
    if (Object.keys(freqMap).length === 0) return null;
    return Object.entries(freqMap).sort((a, b) => b[1] - a[1])[0][0];
  }

  getPeakTime(timePattern) {
    return Object.entries(timePattern).sort((a, b) => b[1] - a[1])[0]?.[0] || null;
  }

  sanitizeStrategyConfig(strategy) {
    const safe = { ...strategy };
    delete safe.id;
    delete safe.type;
    delete safe.label;
    delete safe.description;
    delete safe.risks;
    delete safe.benefits;
    delete safe.constraints;
    return safe;
  }

  extractTriggerConditions(failures) {
    const triggers = {};

    failures.forEach(f => {
      if (f.triggerCondition) {
        triggers[f.triggerCondition] = (triggers[f.triggerCondition] || 0) + 1;
      }
    });

    return triggers;
  }

  extractRecurringPatterns(failures) {
    const patterns = [];
    const seen = new Set();

    failures.forEach(f => {
      const pattern = `${f.reason}_${f.triggerCondition || 'no_trigger'}`;
      if (!seen.has(pattern) && f.reason) {
        seen.add(pattern);
        patterns.push(f.reason);
      }
    });

    return patterns.slice(0, 5);
  }

  findSimilarTaskPattern(description) {
    const features = this.extractTaskFeatures(description, 'generic', 1);

    let bestMatch = null;
    let bestScore = 0;

    for (const [patternId, pattern] of this.taskPatterns) {
      const score = this.calculatePatternSimilarity(features, pattern.features);
      if (score > bestScore && score >= this.config.taskPatternThreshold) {
        bestScore = score;
        bestMatch = { id: patternId, pattern, score };
      }
    }

    return bestMatch;
  }

  getSuccessfulExperienceForPattern(patternId) {
    const now = Date.now();
    const lifetime = this.config.experienceMemoryDays * 24 * 60 * 60 * 1000;

    // 查找该模式下的成功经验
    return this.experienceLibrary
      .filter(e => e.patternId === patternId && e.outcome.success)
      .filter(e => now - e.timestamp < lifetime)
      .sort((a, b) => b.outcome.successRate - a.outcome.successRate)[0];
  }

  findRelatedFailurePatterns(taskDescription) {
    const features = this.extractTaskFeatures(taskDescription, 'generic', 1);
    const related = [];

    this.failureDatabase.forEach(pattern => {
      // 检查失败模式的关键词与任务关键词的重叠
      const intersection = features.keywords.filter(k =>
        pattern.abstractPattern.patterns.includes(k)
      ).length;

      if (intersection > 0) {
        related.push(pattern);
      }
    });

    return related;
  }

  getTaskPatternTypes() {
    const types = {};
    this.taskPatterns.forEach(pattern => {
      types[pattern.type] = (types[pattern.type] || 0) + 1;
    });
    return types;
  }

  getDominantBehaviorStyles() {
    const styles = {};
    this.userProfiles.forEach(profile => {
      if (profile.behavior?.responseStyleDominant) {
        styles[profile.behavior.responseStyleDominant] = (styles[profile.behavior.responseStyleDominant] || 0) + 1;
      }
    });
    return Object.entries(styles).sort((a, b) => b[1] - a[1]);
  }

  getDefaultStrategy() {
    return {
      type: 'BALANCED',
      delay: 150,
      compressionLevel: 1,
      modelBias: 'NORMAL'
    };
  }

  genId(prefix) {
    return `${prefix}_${Date.now()}_${Math.floor(Math.random() * 10000)}`;
  }
}

module.exports = CognitiveLayer;
