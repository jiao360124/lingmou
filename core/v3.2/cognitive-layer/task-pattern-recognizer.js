/**
 * OpenClaw V3.2 - Task Pattern Recognizer
 * 认知层核心模块：任务模式识别器
 *
 * 功能：
 * - 自动识别任务类型
 * - 按模式分组
 * - 提取任务特征
 *
 * @author OpenClaw V3.2
 * @date 2026-02-22
 */

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

class TaskPatternRecognizer {
  constructor() {
    this.name = 'TaskPatternRecognizer';
    this.taskPatterns = new Map();
    this.featureVectors = new Map();
    this.trained = false;
    this.stopWords = new Set([
      'the', 'is', 'at', 'which', 'on', 'a', 'an', 'and', 'or', 'but',
      'in', 'to', 'for', 'of', 'with', 'by', 'from', 'as', 'at', 'into'
    ]);
  }

  /**
   * 训练任务模式
   * @param {Array<Object>} patterns - 训练模式列表
   * @returns {Promise<void>}
   */
  async train(patterns) {
    console.log(`[TaskPatternRecognizer] 开始训练 ${patterns.length} 个任务模式`);

    for (const pattern of patterns) {
      this.taskPatterns.set(pattern.name, pattern);
      this.featureVectors.set(pattern.name, this.extractFeatures(pattern));
    }

    this.trained = true;
    await this.saveModel();

    console.log(`[TaskPatternRecognizer] 训练完成`);
  }

  /**
   * 识别任务类型
   * @param {Object} task - 任务对象
   * @returns {Promise<TaskType>}
   */
  async identify(task) {
    if (!this.trained) {
      await this.loadModel();
    }

    console.log(`[TaskPatternRecognizer] 识别任务: ${task.id || 'unknown'}`);

    const features = this.extractFeatures(task);
    const scores = new Map();

    for (const [patternName, patternFeatures] of this.featureVectors) {
      const similarity = this.calculateSimilarity(features, patternFeatures);
      const confidence = this.adjustConfidence(similarity, features);

      scores.set(patternName, {
        pattern: patternName,
        similarity,
        confidence
      });

      console.log(`[TaskPatternRecognizer] ${patternName}: confidence=${confidence.toFixed(3)}`);
    }

    const best = this.findBestMatch(scores);

    if (best.confidence < 0.5) {
      console.log(`[TaskPatternRecognizer] 识别置信度过低: ${best.confidence.toFixed(3)}, 使用默认类型`);
      return {
        taskType: 'unknown',
        confidence: best.confidence,
        features,
        suggestedStrategy: 'DEFAULT'
      };
    }

    return {
      taskType: best.pattern,
      confidence: best.confidence,
      features,
      suggestedStrategy: this.suggestStrategy(best.pattern)
    };
  }

  /**
   * 提取任务特征
   * @param {Object} task - 任务对象
   * @returns {TaskFeatures}
   */
  extractFeatures(task) {
    return {
      keywords: this.extractKeywords(task.description || task.prompt || task.type || ''),
      complexity: this.assessComplexity(task.description || task.prompt || task.type || '', task.contextLength || task.tokens || 0),
      contextLength: task.contextLength || task.tokens || 0,
      previousFrequency: this.calculateFrequency(task),
      duration: task.duration || 0,
      tokensUsed: task.tokensUsed || task.tokens || 0,
      errorRate: task.errorRate || 0
    };
  }

  /**
   * 提取关键词
   * @param {string} text - 文本内容
   * @returns {string[]}
   */
  extractKeywords(text) {
    const normalized = text.toLowerCase();

    // 移除特殊字符
    const cleaned = normalized.replace(/[^\w\s]/g, ' ');

    // 分词
    const words = cleaned.split(/\s+/).filter(word => word.length > 2);

    // 过滤停用词
    const filtered = words.filter(word => !this.stopWords.has(word));

    // 计算词频
    const freq = {};
    filtered.forEach(word => {
      freq[word] = (freq[word] || 0) + 1;
    });

    // 返回出现频率最高的关键词
    const topKeywords = Object.entries(freq)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 10)
      .map(([word]) => word);

    return topKeywords;
  }

  /**
   * 评估复杂度
   * @param {string} text - 文本内容
   * @param {number} contextLength - 上下文长度
   * @returns {number} 0-1
   */
  assessComplexity(text, contextLength) {
    let complexity = 0;

    // 1. 上下文长度影响
    complexity += Math.min(contextLength / 50000, 1);

    // 2. 文本复杂度（基于字符数、句子数、段落数）
    const sentences = text.split(/[.!?]+/).filter(s => s.trim()).length;
    const words = text.split(/\s+/).filter(w => w.trim()).length;
    const paragraphs = text.split(/\n\s*\n/).filter(p => p.trim()).length;

    const avgSentenceLength = words / Math.max(sentences, 1);
    const avgParagraphLength = words / Math.max(paragraphs, 1);

    complexity += Math.min(avgSentenceLength / 20, 1);
    complexity += Math.min(avgParagraphLength / 100, 1);

    // 3. 特殊字符比例
    const specialChars = (text.match(/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/g) || []).length;
    const wordsCount = words || 1;
    complexity += specialChars / wordsCount;

    // 4. 代码相关指标
    const codeBlocks = (text.match(/```/g) || []).length;
    if (codeBlocks > 0) {
      complexity += 0.2;
    }

    return Math.min(complexity, 1);
  }

  /**
   * 计算频率
   * @param {Object} task - 任务对象
   * @returns {number} 0-1
   */
  calculateFrequency(task) {
    if (!task.id) return 0;

    const history = this.getTaskHistory(task.id);
    const total = history.length || 1;
    const relevant = history.filter(h => this.isSameType(h, task)).length;

    return relevant / total;
  }

  /**
   * 获取任务历史
   * @param {string} taskId - 任务ID
   * @returns {Array<Object>}
   */
  getTaskHistory(taskId) {
    // 实际实现中应该从数据库读取
    // 这里返回模拟数据
    return [];
  }

  /**
   * 判断是否相同类型
   * @param {Object} task1 - 任务1
   * @param {Object} task2 - 任务2
   * @returns {boolean}
   */
  isSameType(task1, task2) {
    // 实际实现中应该检查任务类型
    return true;
  }

  /**
   * 计算相似度
   * @param {TaskFeatures} features1 - 特征1
   * @param {TaskFeatures} features2 - 特征2
   * @returns {number} 0-1
   */
  calculateSimilarity(features1, features2) {
    const vector1 = this.vectorizeFeatures(features1);
    const vector2 = this.vectorizeFeatures(features2);

    let dotProduct = 0;
    let magnitude1 = 0;
    let magnitude2 = 0;

    const keys = new Set([...Object.keys(vector1), ...Object.keys(vector2)]);

    for (const key of keys) {
      const v1 = vector1[key] || 0;
      const v2 = vector2[key] || 0;

      dotProduct += v1 * v2;
      magnitude1 += v1 * v1;
      magnitude2 += v2 * v2;
    }

    magnitude1 = Math.sqrt(magnitude1);
    magnitude2 = Math.sqrt(magnitude2);

    if (magnitude1 === 0 || magnitude2 === 0) return 0;

    return dotProduct / (magnitude1 * magnitude2);
  }

  /**
   * 向量化特征
   * @param {TaskFeatures} features - 特征对象
   * @returns {Object}
   */
  vectorizeFeatures(features) {
    // 权重配置
    const weights = {
      keywords: 0.3,
      complexity: 0.25,
      contextLength: 0.2,
      previousFrequency: 0.1,
      duration: 0.05,
      tokensUsed: 0.05,
      errorRate: 0.05
    };

    // 处理keywords - 使用关键词匹配而非数量
    let keywordScore = 0;
    if (features.keywords && features.keywords.length > 0) {
      keywordScore = features.keywords.length / 10 * weights.keywords;
    }

    return {
      keywords: keywordScore,
      complexity: features.complexity * weights.complexity,
      contextLength: features.contextLength / 50000 * weights.contextLength,
      previousFrequency: features.previousFrequency * weights.previousFrequency,
      duration: Math.min(features.duration / 300, 1) * weights.duration,
      tokensUsed: Math.min(features.tokensUsed / 100000, 1) * weights.tokensUsed,
      errorRate: features.errorRate * weights.errorRate
    };
  }

  /**
   * 调整置信度
   * @param {number} similarity - 相似度
   * @param {TaskFeatures} features - 特征对象
   * @returns {number} 0-1
   */
  adjustConfidence(similarity, features) {
    let confidence = similarity;

    // 如果之前的频率很高，提高置信度
    if (features.previousFrequency > 0.5) {
      confidence = Math.min(confidence + 0.1, 1);
    }

    // 如果上下文长度很短，降低置信度
    if (features.contextLength < 5000) {
      confidence = Math.max(confidence - 0.1, 0);
    }

    return confidence;
  }

  /**
   * 找到最佳匹配
   * @param {Map} scores - 评分Map
   * @returns {Object} 最佳匹配
   */
  findBestMatch(scores) {
    let best = null;

    for (const score of scores.values()) {
      if (!best || score.confidence > best.confidence) {
        best = score;
      }
    }

    return best;
  }

  /**
   * 推荐策略
   * @param {string} taskType - 任务类型
   * @returns {string} 策略名称
   */
  suggestStrategy(taskType) {
    const strategies = {
      coding: "CODE_OPTIMIZATION",
      analysis: "DEEP_THINKING",
      routine: "QUICK_RESPONSE",
      creative: "GENERATIVE_MODE",
      question: "ANSWER"
    };

    return strategies[taskType] || "DEFAULT";
  }

  /**
   * 保存模型
   * @returns {Promise<void>}
   */
  async saveModel() {
    const model = {
      taskPatterns: Array.from(this.taskPatterns.entries()),
      featureVectors: Array.from(this.featureVectors.entries()),
      trained: this.trained
    };

    // 实际实现中应该保存到数据库
    // await this.database.save("task-pattern-model", model);
    console.log('[TaskPatternRecognizer] 模型已保存');
  }

  /**
   * 加载模型
   * @returns {Promise<void>}
   */
  async loadModel() {
    // 实际实现中应该从数据库加载
    // const model = await this.database.load("task-pattern-model");

    // 这里模拟加载
    // if (model) {
    //   this.taskPatterns = new Map(model.taskPatterns);
    //   this.featureVectors = new Map(model.featureVectors);
    //   this.trained = model.trained;
    // }

    console.log('[TaskPatternRecognizer] 模型已加载');
  }

  /**
   * 添加任务模式
   * @param {string} name - 模式名称
   * @param {Object} pattern - 模式对象
   * @returns {Promise<void>}
   */
  async addPattern(name, pattern) {
    this.taskPatterns.set(name, pattern);
    this.featureVectors.set(name, this.extractFeatures(pattern));
    console.log(`[TaskPatternRecognizer] 已添加模式: ${name}`);
  }

  /**
   * 获取所有任务类型
   * @returns {Array<string>}
   */
  getAllTaskTypes() {
    return Array.from(this.taskPatterns.keys());
  }
}

module.exports = TaskPatternRecognizer;
