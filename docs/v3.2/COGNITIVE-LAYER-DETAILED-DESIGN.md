# 认知层详细设计 (V3.2)

**模块**: 认知层
**优先级**: P0
**预计工时**: 24h
**负责人**: 灵眸

---

## 📋 模块概述

认知层是 V3.2 的第二个核心模块，将 OpenClaw 从"记录历史"升级为"结构化学习"。通过任务模式识别、用户行为画像、结构化经验库和失败模式数据库，实现真正的智能进化。

---

## 🎯 核心功能

### 1. 任务模式识别器 (Task Pattern Recognizer)

**功能描述**：
自动识别任务类型，按模式分组，提取任务特征。

#### 识别模型

```typescript
interface TaskType {
  name: string;
  description: string;
  confidence: number;  // 0-1
  features: TaskFeatures;
  suggestedStrategy: string;
  tags: string[];
}

interface TaskFeatures {
  keywords: string[];
  complexity: number;  // 0-1
  contextLength: number;  // tokens
  previousFrequency: number;  // 0-1
  duration: number;  // seconds
  tokensUsed: number;
  errorRate: number;
}
```

#### 识别算法

```javascript
class TaskPatternRecognizer {
  constructor() {
    this.taskPatterns = new Map();
    this.featureVectors = new Map();
    this.trained = false;
  }

  async train(patterns) {
    // 训练任务模式
    for (const pattern of patterns) {
      this.taskPatterns.set(pattern.name, pattern);
      this.featureVectors.set(pattern.name, this.extractFeatures(pattern));
    }

    this.trained = true;
    await this.saveModel();
  }

  async identify(task) {
    if (!this.trained) {
      await this.loadModel();
    }

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
    }

    const best = this.findBestMatch(scores);

    return {
      taskType: best.pattern,
      confidence: best.confidence,
      features,
      suggestedStrategy: this.suggestStrategy(best.pattern)
    };
  }

  extractFeatures(task) {
    return {
      keywords: this.extractKeywords(task.prompt),
      complexity: this.assessComplexity(task.prompt, task.contextLength),
      contextLength: task.contextLength,
      previousFrequency: this.calculateFrequency(task),
      duration: task.duration,
      tokensUsed: task.tokensUsed,
      errorRate: task.errorRate || 0
    };
  }

  extractKeywords(text) {
    const keywords = text.toLowerCase()
      .split(/\s+/)
      .filter(word => word.length > 2)
      .filter(word => !this.stopWords.has(word));

    // TF-IDF
    const freq = {};
    keywords.forEach(word => {
      freq[word] = (freq[word] || 0) + 1;
    });

    // 返回出现频率最高的关键词
    return Object.entries(freq)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 10)
      .map(([word]) => word);
  }

  assessComplexity(text, contextLength) {
    let complexity = 0;

    // 1. 上下文长度
    complexity += contextLength / 50000;  // 归一化到 0-1

    // 2. 文本复杂度（基于字符数、句子数、段落数）
    const sentences = text.split(/[.!?]+/).length;
    const words = text.split(/\s+/).length;
    const avgSentenceLength = words / sentences;
    complexity += Math.min(avgSentenceLength / 20, 1);

    // 3. 特殊字符比例
    const specialChars = (text.match(/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/g) || []).length;
    complexity += specialChars / words;

    return Math.min(complexity, 1);
  }

  calculateFrequency(task) {
    if (!task.id) return 0;

    const history = this.getTaskHistory(task.id);
    const total = history.length || 1;
    const relevant = history.filter(h => this.isSameType(h, task)).length;

    return relevant / total;
  }

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

    return {
      keywords: features.keywords.length * weights.keywords,
      complexity: features.complexity * weights.complexity,
      contextLength: features.contextLength / 50000 * weights.contextLength,
      previousFrequency: features.previousFrequency * weights.previousFrequency,
      duration: Math.min(features.duration / 300, 1) * weights.duration,
      tokensUsed: Math.min(features.tokensUsed / 100000, 1) * weights.tokensUsed,
      errorRate: features.errorRate * weights.errorRate
    };
  }

  adjustConfidence(similarity, features) {
    // 调整置信度
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

  findBestMatch(scores) {
    let best = null;

    for (const score of scores.values()) {
      if (!best || score.confidence > best.confidence) {
        best = score;
      }
    }

    return best;
  }

  suggestStrategy(taskType) {
    const strategies = {
      coding: "CODE_OPTIMIZATION",
      analysis: "DEEP_THINKING",
      routine: "QUICK_RESPONSE",
      creative: "GENERATIVE_MODE",
      // ... 更多映射
    };

    return strategies[taskType] || "DEFAULT";
  }

  async saveModel() {
    const model = {
      taskPatterns: Array.from(this.taskPatterns.entries()),
      featureVectors: Array.from(this.featureVectors.entries()),
      trained: this.trained
    };

    // 保存到数据库
    await this.database.save("task-pattern-model", model);
  }

  async loadModel() {
    const model = await this.database.load("task-pattern-model");

    if (model) {
      this.taskPatterns = new Map(model.taskPatterns);
      this.featureVectors = new Map(model.featureVectors);
      this.trained = model.trained;
    }
  }

  getTaskHistory(taskId) {
    // 从数据库获取任务历史
    return this.database.query("task-history", { taskId });
  }

  isSameType(task1, task2) {
    // 判断两个任务是否类型相同
    return task1.type === task2.type;
  }
}
```

#### 使用示例

```javascript
const recognizer = new TaskPatternRecognizer();

// 训练
const trainingPatterns = [
  {
    name: "coding",
    description: "Code writing and debugging",
    features: {
      keywords: ["fix", "bug", "error", "function", "class", "import"],
      complexity: 0.6,
      contextLength: 30000,
      previousFrequency: 0.4,
      duration: 120,
      tokensUsed: 35000,
      errorRate: 0.15
    }
  },
  {
    name: "analysis",
    description: "Data analysis and reporting",
    features: {
      keywords: ["analyze", "data", "report", "chart", "table"],
      complexity: 0.4,
      contextLength: 40000,
      previousFrequency: 0.3,
      duration: 180,
      tokensUsed: 45000,
      errorRate: 0.1
    }
  }
];

await recognizer.train(trainingPatterns);

// 识别新任务
const result = await recognizer.identify({
  prompt: "Fix the bug in the function and add error handling",
  contextLength: 28000,
  duration: 95,
  tokensUsed: 32000,
  errorRate: 0.18,
  id: "task_001"
});

console.log(result);
/*
{
  taskType: "coding",
  confidence: 0.87,
  features: {
    keywords: ["fix", "bug", "error", "function"],
    complexity: 0.58,
    contextLength: 28000,
    previousFrequency: 0.18,
    duration: 95,
    tokensUsed: 32000,
    errorRate: 0.18
  },
  suggestedStrategy: "CODE_OPTIMIZATION"
}
*/
```

**文件位置**: `core/task-pattern-recognizer.js`

---

### 2. 用户行为画像 (User Behavior Profile)

**功能描述**：
学习主人工作习惯，建立用户画像，预测偏好。

#### 画像模型

```typescript
interface UserProfile {
  userId: string;
  profileType: string;
  preferences: UserPreferences;
  history: UserHistory;
  predictions: UserPredictions;
  lastUpdated: Date;
}
```

#### 画像构建

```javascript
class UserBehaviorProfile {
  constructor(userId) {
    this.userId = userId;
    this.profile = null;
    this.profileLoaded = false;
  }

  async load() {
    if (this.profileLoaded) {
      return this.profile;
    }

    this.profile = await this.database.load("user-profile", this.userId);

    if (!this.profile) {
      this.profile = this.createEmptyProfile();
    }

    this.profileLoaded = true;
    return this.profile;
  }

  createEmptyProfile() {
    return {
      userId: this.userId,
      profileType: "unknown",
      preferences: {
        preferredModel: "default",
        compressionLevel: 1,
        responseStyle: "balanced",
        timePatterns: {},
        channelPreferences: {},
        qualityThreshold: 0.8
      },
      history: {
        totalSessions: 0,
        avgTokensPerSession: 0,
        avgSuccessRate: 0,
        last30Days: 0,
        byHour: {},
        byDay: {},
        taskDistribution: {}
      },
      predictions: {
        preferredModel: null,
        bestTime: null,
        taskPredictions: {}
      },
      lastUpdated: new Date()
    };
  }

  async update(taskResult) {
    const profile = await this.load();

    // 1. 更新历史
    this.updateHistory(profile, taskResult);

    // 2. 更新偏好
    this.updatePreferences(profile, taskResult);

    // 3. 生成预测
    this.updatePredictions(profile);

    // 4. 保存
    await this.database.save("user-profile", this.userId, profile);

    return profile;
  }

  updateHistory(profile, taskResult) {
    profile.history.totalSessions++;
    profile.history.avgTokensPerSession =
      (profile.history.avgTokensPerSession * (profile.history.totalSessions - 1) +
       taskResult.tokensUsed) / profile.history.totalSessions;

    profile.history.avgSuccessRate =
      (profile.history.avgSuccessRate * (profile.history.totalSessions - 1) +
       (taskResult.successRate || 0)) / profile.history.totalSessions;

    // 按小时统计
    const hour = new Date().getHours();
    profile.history.byHour[hour] = (profile.history.byHour[hour] || 0) + 1;

    // 按天统计
    const day = new Date().getDay();
    profile.history.byDay[day] = (profile.history.byDay[day] || 0) + 1;

    // 任务分布
    if (taskResult.taskType) {
      profile.history.taskDistribution[taskResult.taskType] =
        (profile.history.taskDistribution[taskResult.taskType] || 0) + 1;
    }

    profile.history.last30Days++;
  }

  updatePreferences(profile, taskResult) {
    const prevTokens = profile.history.avgTokensPerSession;
    const currentTokens = taskResult.tokensUsed;
    const prevSuccess = profile.history.avgSuccessRate;
    const currentSuccess = taskResult.successRate || 0;

    // 模型偏好
    if (currentSuccess > prevSuccess) {
      profile.preferences.preferredModel = taskResult.model;
    }

    // 压缩等级偏好
    if (prevTokens > 50000 && currentTokens < prevTokens * 0.8) {
      profile.preferences.compressionLevel =
        Math.max(profile.preferences.compressionLevel + 1, 3);
    }

    // 响应风格偏好
    if (taskResult.userSatisfaction) {
      profile.preferences.userSatisfaction = taskResult.userSatisfaction;
    }

    // 时间偏好
    const hour = new Date().getHours();
    if (taskResult.taskType === "deep") {
      profile.preferences.timePatterns.deepWork = hour;
    } else {
      profile.preferences.timePatterns.routine = hour;
    }
  }

  updatePredictions(profile) {
    // 1. 模型预测
    const taskCounts = Object.entries(profile.history.taskDistribution);
    if (taskCounts.length > 0) {
      const topTask = taskCounts.reduce((max, t) => t[1] > max[1] ? t : max);
      profile.predictions.taskPredictions[topTask[0]] = {
        probability: topTask[1] / profile.history.totalSessions,
        confidence: this.calculateConfidence(profile.history.totalSessions, topTask[1])
      };
    }

    // 2. 最佳时间预测
    const topHour = Object.entries(profile.history.byHour)
      .reduce((max, h) => h[1] > max[1] ? h : max);
    profile.predictions.bestTime = {
      hour: topHour[0],
      frequency: topHour[1],
      probability: topHour[1] / profile.history.totalSessions
    };

    profile.lastUpdated = new Date();
  }

  calculateConfidence(total, count) {
    // 贝叶斯置信度计算
    return count / total;
  }

  async predictContext(context) {
    const profile = await this.load();

    // 根据用户画像预测上下文
    return {
      suggestedStrategy: profile.preferences.responseStyle,
      suggestedCompression: profile.preferences.compressionLevel,
      suggestedModel: profile.preferences.preferredModel,
      timeOfDay: profile.predictions.bestTime,
      contextPrediction: this.predictContextSize(profile)
    };
  }

  predictContextSize(profile) {
    // 根据历史平均预测
    const avg = profile.history.avgTokensPerSession;
    const variance = this.calculateVariance(profile.history.byHour);

    return {
      suggested: Math.round(avg * (1 + variance * 0.1)),
      range: [Math.round(avg * 0.8), Math.round(avg * 1.2)]
    };
  }

  calculateVariance(data) {
    const values = Object.values(data);
    const avg = values.reduce((sum, v) => sum + v, 0) / values.length;
    const variance = values.reduce((sum, v) => sum + Math.pow(v - avg, 2), 0) / values.length;
    return Math.sqrt(variance);
  }
}
```

#### 使用示例

```javascript
const profile = new UserBehaviorProfile("user_001");

// 更新画像
await profile.update({
  model: "mid-tier",
  tokensUsed: 45000,
  successRate: 0.92,
  userSatisfaction: 0.9,
  taskType: "coding"
});

// 加载画像
const loadedProfile = await profile.load();

console.log(loadedProfile);
/*
{
  userId: "user_001",
  profileType: "unknown",
  preferences: {
    preferredModel: "mid-tier",
    compressionLevel: 1,
    responseStyle: "balanced",
    timePatterns: {
      deepWork: 14,
      routine: 10
    },
    qualityThreshold: 0.8
  },
  history: {
    totalSessions: 127,
    avgTokensPerSession: 78500,
    avgSuccessRate: 0.88,
    last30Days: 127,
    byHour: {
      10: 15,
      14: 20,
      // ... 更多
    },
    taskDistribution: {
      coding: 45,
      analysis: 38,
      // ... 更多
    }
  },
  predictions: {
    preferredModel: "mid-tier",
    bestTime: {
      hour: 14,
      frequency: 20,
      probability: 0.16
    },
    taskPredictions: {
      coding: {
        probability: 0.35,
        confidence: 0.35
      },
      analysis: {
        probability: 0.30,
        confidence: 0.30
      }
    }
  },
  lastUpdated: "2026-02-21T22:50:00Z"
}
*/
```

**文件位置**: `core/user-behavior-profile.js`

---

### 3. 结构化经验库 (Structured Experience Library)

**功能描述**：
抽象化经验，结构化存储，经验检索。

#### 经验模型

```typescript
interface StructuredExperience {
  experienceId: string;
  category: string;
  abstractPattern: string;
  description: string;
  lessons: string[];
  tags: string[];
  date: Date;
  verified: boolean;
  usageCount: number;
  avgROI: number;
}
```

#### 经验管理

```javascript
class StructuredExperienceLibrary {
  constructor() {
    this.experiences = new Map();
    this.indexes = {
      byCategory: new Map(),
      byTags: new Map(),
      byPattern: new Map()
    };
  }

  async addExperience(experience) {
    experience.experienceId = `exp_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    experience.date = new Date();
    experience.usageCount = 0;
    experience.avgROI = 0;

    this.experiences.set(experience.experienceId, experience);

    // 建立索引
    this.indexes.byCategory.set(experience.category, experience.experienceId);
    experience.tags.forEach(tag => {
      this.indexes.byTags.set(tag, experience.experienceId);
    });

    // 存储到数据库
    await this.database.save("structured-experience", experience.experienceId, experience);

    return experience;
  }

  async search(pattern, options = {}) {
    const results = [];
    const { category, tags, minROI, limit = 10 } = options;

    // 根据参数搜索
    for (const [id, experience] of this.experiences) {
      let match = true;

      // 按类别筛选
      if (category && experience.category !== category) {
        match = false;
      }

      // 按标签筛选
      if (tags && tags.some(tag => !experience.tags.includes(tag))) {
        match = false;
      }

      // 按ROI筛选
      if (minROI && experience.avgROI < minROI) {
        match = false;
      }

      if (match) {
        results.push(experience);
      }
    }

    // 按相关度排序
    results.sort((a, b) => b.avgROI - a.avgROI);

    return results.slice(0, limit);
  }

  async getSimilar(experienceId, limit = 5) {
    const experience = this.experiences.get(experienceId);

    if (!experience) {
      return [];
    }

    const similarities = [];

    for (const [id, other] of this.experiences) {
      if (id === experienceId) continue;

      const similarity = this.calculateSimilarity(experience, other);

      if (similarity > 0.5) {  // 只返回高相似度
        similarities.push({
          experienceId: id,
          similarity,
          experience: other
        });
      }
    }

    return similarities
      .sort((a, b) => b.similarity - a.similarity)
      .slice(0, limit);
  }

  calculateSimilarity(exp1, exp2) {
    // 计算经验相似度
    let score = 0;

    // 相同类别
    if (exp1.category === exp2.category) {
      score += 0.4;
    }

    // 共享标签
    const sharedTags = exp1.tags.filter(tag => exp2.tags.includes(tag));
    score += sharedTags.length * 0.1;

    // 相似描述
    const descSimilarity = this.calculateStringSimilarity(exp1.description, exp2.description);
    score += descSimilarity * 0.5;

    return score;
  }

  calculateStringSimilarity(str1, str2) {
    // 简单的字符串相似度计算
    const longer = str1.length > str2.length ? str1 : str2;
    const shorter = str1.length > str2.length ? str2 : str1;

    if (longer.length === 0) {
      return 1.0;
    }

    const editDistance = this.editDistance(longer, shorter);
    return (longer.length - editDistance) / longer.length;
  }

  editDistance(str1, str2) {
    // 编辑距离算法
    const matrix = [];

    for (let i = 0; i <= str1.length; i++) {
      matrix[i] = [i];
    }

    for (let j = 0; j <= str2.length; j++) {
      matrix[0][j] = j;
    }

    for (let i = 1; i <= str1.length; i++) {
      for (let j = 1; j <= str2.length; j++) {
        const cost = str1[i - 1] === str2[j - 1] ? 0 : 1;
        matrix[i][j] = Math.min(
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost
        );
      }
    }

    return matrix[str1.length][str2.length];
  }

  async updateExperience(experienceId, updates) {
    const experience = this.experiences.get(experienceId);

    if (!experience) {
      return null;
    }

    Object.assign(experience, updates);

    // 更新统计
    if (updates.usageCount) {
      experience.usageCount += updates.usageCount;
      experience.avgROI = this.calculateNewROI(experience);
    }

    await this.database.save("structured-experience", experienceId, experience);

    return experience;
  }

  calculateNewROI(experience) {
    // 计算新的平均ROI
    return experience.avgROI * experience.usageCount / (experience.usageCount + 1);
  }

  async getTopExperiences(category, limit = 10) {
    return this.search(null, { category, minROI: 0, limit });
  }
}
```

#### 使用示例

```javascript
const library = new StructuredExperienceLibrary();

// 添加经验
await library.addExperience({
  category: "optimization",
  abstractPattern: "high_context_inefficiency",
  description: "When context > 40k tokens, compression improves ROI by 2.3x",
  lessons: [
    "Use level 2 compression at 40k tokens",
    "Monitor success rate after compression",
    "Test different compression levels"
  ],
  tags: ["compression", "roi", "context"]
});

// 搜索经验
const results = await library.search(
  "compression",
  { minROI: 1.5, limit: 5 }
);

console.log(results);
// 返回高ROI的压缩经验

// 获取相似经验
const similar = await library.getSimilar("exp_001", 3);
```

**文件位置**: `memory/structured-experience.js`

---

### 4. 失败模式数据库 (Failure Pattern Database)

**功能描述**：
识别重复错误，建立失败模式库，生成规避建议。

#### 模式模型

```typescript
interface FailurePattern {
  patternId: string;
  patternName: string;
  description: string;
  occurrences: number;
  lastOccurrence: Date;
  severity: "LOW" | "MEDIUM" | "HIGH" | "CRITICAL";
  factors: string[];
  mitigation: string[];
  prevention: string[];
  tags: string[];
}
```

#### 模式识别

```javascript
class FailurePatternDatabase {
  constructor() {
    this.patterns = new Map();
    this.mergerThreshold = 5;  // 相似模式合并阈值
  }

  async analyzeTask(taskResult) {
    // 分析任务结果，检测失败模式
    if (!taskResult.success) {
      const pattern = await this.detectPattern(taskResult);

      if (pattern) {
        await this.recordPattern(pattern);
        await this.suggestMitigation(pattern);
      }
    }
  }

  async detectPattern(taskResult) {
    const { failureReason, context, errorDetails } = taskResult;

    // 搜索现有模式
    for (const [patternId, pattern] of this.patterns) {
      const similarity = this.calculateSimilarity(failureReason, pattern);

      if (similarity > 0.7) {
        return {
          patternId,
          similarity,
          details: pattern
        };
      }
    }

    // 如果没有相似模式，创建新模式
    const newPattern = this.createNewPattern(taskResult);
    return {
      patternId: newPattern.patternId,
      similarity: 1.0,
      isNew: true,
      details: newPattern
    };
  }

  createNewPattern(taskResult) {
    return {
      patternId: `fp_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      patternName: this.generatePatternName(taskResult),
      description: this.generateDescription(taskResult),
      occurrences: 1,
      lastOccurrence: new Date(),
      severity: this.determineSeverity(taskResult),
      factors: this.extractFactors(taskResult),
      mitigation: [],
      prevention: [],
      tags: this.extractTags(taskResult)
    };
  }

  generatePatternName(taskResult) {
    // 生成模式名称
    const reason = taskResult.failureReason.toLowerCase();
    if (reason.includes("memory")) return "memory_error";
    if (reason.includes("timeout")) return "timeout_error";
    if (reason.includes("api")) return "api_error";
    // ... 更多映射
    return "unknown_error";
  }

  generateDescription(taskResult) {
    // 生成描述
    return `Task failed due to: ${taskResult.failureReason}. Context: ${taskResult.context}`;
  }

  determineSeverity(taskResult) {
    // 确定严重程度
    const errorRate = taskResult.errorRate || 0;
    const isCritical = errorRate > 0.5;

    if (isCritical) return "CRITICAL";
    if (errorRate > 0.3) return "HIGH";
    if (errorRate > 0.15) return "MEDIUM";
    return "LOW";
  }

  extractFactors(taskResult) {
    // 提取失败因素
    const factors = [];

    if (taskResult.contextLength > 80000) {
      factors.push("too_long_context");
    }

    if (taskResult.tokensUsed > 150000) {
      factors.push("excessive_tokens");
    }

    if (taskResult.errorRate > 0.3) {
      factors.push("high_error_rate");
    }

    return factors;
  }

  async recordPattern(pattern) {
    if (pattern.isNew) {
      // 创建新模式
      this.patterns.set(pattern.patternId, pattern.details);
      await this.database.save("failure-pattern", pattern.patternId, pattern.details);
    } else {
      // 更新模式
      const existing = this.patterns.get(pattern.patternId);
      existing.occurrences++;

      if (pattern.details.failureReason !== existing.description) {
        existing.description = this.mergeDescriptions(existing, pattern.details);
      }

      existing.lastOccurrence = new Date();
    }

    // 合并相似模式
    await this.mergeSimilarPatterns(pattern.patternId);
  }

  async suggestMitigation(pattern) {
    // 建议缓解措施
    const suggestions = [];

    if (pattern.severity === "HIGH" || pattern.severity === "CRITICAL") {
      suggestions.push("Review error logs for root cause");
      suggestions.push("Implement additional error handling");
      suggestions.push("Consider alternative approaches");
    }

    if (pattern.factors.includes("too_long_context")) {
      suggestions.push("Reduce context size before retry");
      suggestions.push("Use compression strategies");
    }

    pattern.mitigation = suggestions;
    pattern.prevention = this.generatePreventionStrategies(pattern);

    await this.database.save("failure-pattern", pattern.patternId, pattern);
  }

  generatePreventionStrategies(pattern) {
    // 生成预防策略
    const strategies = [];

    if (pattern.severity === "CRITICAL") {
      strategies.push("Monitor for early warnings");
      strategies.push("Implement fail-safe mechanisms");
      strategies.push("Route to backup systems");
    }

    if (pattern.factors.includes("high_error_rate")) {
      strategies.push("Implement rate limiting");
      strategies.push("Add circuit breakers");
      strategies.push("Log errors for analysis");
    }

    return strategies;
  }

  calculateSimilarity(reason1, reason2) {
    // 计算相似度
    const normalized1 = reason1.toLowerCase();
    const normalized2 = reason2.toLowerCase();

    const words1 = normalized1.split(/\s+/);
    const words2 = normalized2.split(/\s+/);

    const intersection = words1.filter(w => words2.includes(w));
    const union = [...new Set([...words1, ...words2])];

    return intersection.length / union.length;
  }

  async mergeSimilarPatterns(patternId) {
    const pattern = this.patterns.get(patternId);

    for (const [otherId, other] of this.patterns) {
      if (otherId === patternId) continue;

      const similarity = this.calculateSimilarity(pattern.description, other.description);

      if (similarity > this.mergerThreshold / 10) {
        // 合并模式
        await this.mergePatterns(patternId, otherId);
      }
    }
  }

  async mergePatterns(patternId1, patternId2) {
    const pattern1 = this.patterns.get(patternId1);
    const pattern2 = this.patterns.get(patternId2);

    // 合并描述
    pattern1.description = `${pattern1.description}. Also: ${pattern2.description}`;

    // 合并因素
    pattern1.factors = [...new Set([...pattern1.factors, ...pattern2.factors])];

    // 更新出现次数
    pattern1.occurrences += pattern2.occurrences;

    // 删除第二个模式
    this.patterns.delete(patternId2);
    await this.database.delete("failure-pattern", patternId2);
  }
}
```

**文件位置**: `memory/failure-pattern-database.js`

---

## 📊 性能指标

| 指标 | 目标值 | 当前值 | 状态 |
|------|--------|--------|------|
| 识别准确率 | > 85% | - | 📋 |
| 画像更新延迟 | < 50ms | - | 📋 |
| 经验检索速度 | < 100ms | - | 📋 |
| 模式识别速度 | < 200ms | - | 📋 |

---

## 🧪 测试计划

### 单元测试

- 任务模式识别器测试
- 用户行为画像测试
- 结构化经验库测试
- 失败模式数据库测试

### 集成测试

- 认知层完整流程测试
- 与记忆系统集成测试
- 端到端学习测试

---

## 🚀 实施顺序

1. **Week 3**:
   - Day 1-3: 任务模式识别器
   - Day 4-5: 用户行为画像

2. **Week 4**:
   - Day 1-3: 结构化经验库
   - Day 4-5: 失败模式数据库

---

**下一步**: 开始实施认知层？ 🎯
