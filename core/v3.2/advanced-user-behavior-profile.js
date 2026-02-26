/**
 * OpenClaw 3.3 - 高级用户行为画像（Advanced User Behavior Profile）
 * 实现用户意图推断、行为预测和行为偏差检测
 * 
 * @version 3.3.0
 * @author OpenClaw V3.3
 * @date 2026-02-22
 */

class AdvancedUserBehaviorProfile {
  constructor(config = {}) {
    this.name = 'AdvancedUserBehaviorProfile';
    this.config = {
      // 意图识别配置
      intentRecognition: {
        useBehaviorHistory: true,
        useContext: true,
        usePreferences: true,
        useSocialContext: true,
        confidenceThreshold: 0.7
      },

      // 行为预测配置
      behaviorPrediction: {
        predictWithinHours: 24,
        predictWithinDays: 7,
        predictAccuracyThreshold: 0.8
      },

      // 偏差检测配置
      deviationDetection: {
        threshold: 0.85,
        windowSize: 10
      },

      // 画像更新配置
      profileUpdate: {
        minEntries: 10,
        updateFrequency: 'realtime',
        decayFactor: 0.95
      }
    };

    this.intentLibrary = new Map();
    this.behaviorPatterns = new Map();
    this.userProfiles = new Map();
    this.deviations = new Map();

    console.log('👤 AdvancedUserBehaviorProfile 初始化完成\n');
  }

  /**
   * 推断用户意图
   * @param {Object} context - 上下文信息
   * @returns {Object} 意图推断结果
   */
  inferIntent(context) {
    console.log(`\n🎯 推断用户意图...`);

    const intent = {
      type: this.identifyIntentType(context),
      category: this.classifyIntentCategory(context),
      subcategory: this.classifyIntentSubcategory(context),
      confidence: this.calculateIntentConfidence(context),
      reasons: this.generateIntentReasons(context),
      alternativeIntents: this.generateAlternativeIntents(context)
    };

    console.log(`   ✓ 意图类型: ${intent.type}`);
    console.log(`   ✓ 意图分类: ${intent.category}`);
    console.log(`   ✓ 置信度: ${intent.confidence.toFixed(3)}`);

    // 保存到意图库
    this.saveIntentToLibrary(intent);

    return intent;
  }

  /**
   * 识别意图类型
   * @param {Object} context - 上下文信息
   * @returns {String} 意图类型
   */
  identifyIntentType(context) {
    // 基于上下文识别意图类型
    const typeHints = {
      // 信息查询
      infoQuery: ['搜索', '查询', '查找', '获取', '了解', '阅读', '浏览'],

      // 操作执行
      operation: ['创建', '保存', '编辑', '修改', '删除', '移动', '更新', '提交'],

      // 决策制定
      decision: ['比较', '选择', '评估', '判断', '决策', '确认'],

      // 沟通交互
      communication: ['回复', '讨论', '评论', '反馈', '询问', '询问'],

      // 个性化
      personalization: ['设置', '定制', '个性化', '偏好', '配置']
    };

    // 检查上下文中的关键词
    for (const [type, keywords] of Object.entries(typeHints)) {
      for (const keyword of keywords) {
        if (context.message?.includes(keyword)) {
          return type;
        }
        if (context.history?.some(h => h.message?.includes(keyword))) {
          return type;
        }
      }
    }

    // 基于时间模式
    if (context.time?.isWeekend) {
      return 'personalization';
    }

    // 基于频率模式
    if (context.frequency?.daily) {
      return 'operation';
    }

    return 'infoQuery';
  }

  /**
   * 分类意图类别
   * @param {Object} context - 上下文信息
   * @returns {String} 意图类别
   */
  classifyIntentCategory(context) {
    const type = this.identifyIntentType(context);
    const categories = {
      'infoQuery': {
        query: ['搜索', '查找', '了解'],
        retrieval: ['读取', '获取'],
        reference: ['查看', '阅读']
      },
      'operation': {
        creation: ['创建', '新增'],
        modification: ['修改', '编辑', '更新'],
        deletion: ['删除', '移除'],
        organization: ['整理', '分类']
      },
      'decision': {
        comparison: ['比较', '对比'],
        evaluation: ['评估', '判断'],
        selection: ['选择', '确认']
      },
      'communication': {
        response: ['回复', '回应'],
        discussion: ['讨论', '交流'],
        feedback: ['反馈', '评价']
      },
      'personalization': {
        settings: ['设置', '配置'],
        preferences: ['偏好', '习惯'],
        customization: ['定制', '调整']
      }
    };

    const categoryMap = categories[type] || categories['infoQuery'];
    const userProfile = this.getUserProfile(context.userId);

    // 基于用户画像和上下文
    let bestCategory = 'query';
    let maxScore = 0;

    for (const [category, keywords] of Object.entries(categoryMap)) {
      let score = 0;
      for (const keyword of keywords) {
        if (context.message?.includes(keyword)) {
          score += 0.3;
        }
        if (context.history?.some(h => h.message?.includes(keyword))) {
          score += 0.2;
        }
      }

      if (userProfile && userProfile[category]) {
        score += userProfile[category] * 0.3;
      }

      if (score > maxScore) {
        maxScore = score;
        bestCategory = category;
      }
    }

    return bestCategory;
  }

  /**
   * 分类意图子类别
   * @param {Object} context - 上下文信息
   * @returns {String} 意图子类别
   */
  classifyIntentSubcategory(context) {
    const category = this.classifyIntentCategory(context);
    const subcategories = {
      query: ['搜索', '查找', '筛选', '过滤'],
      retrieval: ['读取', '获取', '拉取'],
      reference: ['查看', '浏览', '浏览'],
      creation: ['新建', '创建', '添加'],
      modification: ['编辑', '更新', '调整'],
      deletion: ['删除', '移除', '清除'],
      organization: ['整理', '归档', '分类'],
      comparison: ['对比', '比较'],
      evaluation: ['评估', '评价'],
      selection: ['选择', '确认'],
      response: ['回复', '回应'],
      discussion: ['讨论', '交流'],
      feedback: ['反馈', '评价'],
      settings: ['设置', '配置'],
      preferences: ['偏好', '习惯'],
      customization: ['定制', '调整']
    };

    const categoryMap = subcategories[category] || subcategories.query;
    const userPattern = this.identifyUserPattern(context);

    for (const subcategory of categoryMap) {
      if (userPattern && userPattern.includes(subcategory)) {
        return subcategory;
      }
    }

    return categoryMap[0];
  }

  /**
   * 计算意图置信度
   * @param {Object} context - 上下文信息
   * @returns {Number} 置信度（0-1）
   */
  calculateIntentConfidence(context) {
    const userProfile = this.getUserProfile(context.userId);
    let confidence = 0.5;

    // 基于历史意图的置信度
    if (userProfile && userProfile.lastIntent) {
      confidence = userProfile.lastIntent.confidence || 0.5;
    }

    // 基于上下文线索的置信度
    if (context.message) {
      const messageLength = context.message.length;
      confidence += Math.min(0.3, messageLength / 100);
    }

    // 基于行为模式的置信度
    if (context.behaviorPattern) {
      confidence += context.behaviorPattern * 0.2;
    }

    // 限制在0-1范围内
    return Math.min(1, Math.max(0, confidence));
  }

  /**
   * 生成意图原因
   * @param {Object} context - 上下文信息
   * @returns {Array} 意图原因列表
   */
  generateIntentReasons(context) {
    const reasons = [];
    const userProfile = this.getUserProfile(context.userId);

    // 基于时间
    if (context.time?.hour) {
      const hour = context.time.hour;
      if (hour >= 9 && hour < 12) {
        reasons.push('工作时间段 - 效率优先');
      } else if (hour >= 13 && hour < 18) {
        reasons.push('下午时段 - 持续工作');
      } else if (hour >= 18 && hour < 22) {
        reasons.push('晚间时段 - 个人兴趣');
      } else {
        reasons.push('夜间时段 - 随机查询');
      }
    }

    // 基于频率
    if (context.frequency?.daily) {
      reasons.push(`连续${context.frequency.daily}天 - 习惯性行为`);
    }

    // 基于用户画像
    if (userProfile) {
      if (userProfile.profession === 'developer') {
        reasons.push('开发者行为模式');
      } else if (userProfile.profession === 'manager') {
        reasons.push('管理者决策模式');
      } else if (userProfile.profession === 'designer') {
        reasons.push('设计师探索模式');
      }
    }

    // 基于上下文线索
    if (context.context?.previousAction) {
      reasons.push(`基于上一动作: ${context.context.previousAction}`);
    }

    // 基于环境
    if (context.context?.location) {
      reasons.push(`在${context.context.location}工作`);
    }

    return reasons;
  }

  /**
   * 生成替代意图
   * @param {Object} context - 上下文信息
   * @returns {Array} 替代意图列表
   */
  generateAlternativeIntents(context) {
    const intent = this.inferIntent(context);
    const alternatives = [];

    // 基于意图类型生成替代
    if (intent.type === 'infoQuery') {
      alternatives.push({
        type: 'operation',
        confidence: 0.4,
        description: '相关操作'
      });
    } else if (intent.type === 'operation') {
      alternatives.push({
        type: 'infoQuery',
        confidence: 0.3,
        description: '相关信息'
      });
    }

    // 基于用户画像生成替代
    const userProfile = this.getUserProfile(context.userId);
    if (userProfile && userProfile.interests) {
      userProfile.interests.forEach(interest => {
        alternatives.push({
          type: interest.type,
          confidence: 0.2,
          description: `${interest.name}相关`
        });
      });
    }

    return alternatives;
  }

  /**
   * 保存意图到库
   * @param {Object} intent - 意图对象
   */
  saveIntentToLibrary(intent) {
    const intentKey = `intent_${intent.type}_${Date.now()}`;
    this.intentLibrary.set(intentKey, intent);
  }

  /**
   * 预测用户行为
   * @param {Object} context - 上下文信息
   * @returns {Object} 行为预测结果
   */
  predictBehavior(context) {
    console.log(`\n🔮 预测用户行为...`);

    const prediction = {
      behavior: this.predictNextBehavior(context),
      likelihood: this.calculateBehaviorLikelihood(context),
      probability: this.calculateBehaviorProbability(context),
      patterns: this.identifyBehaviorPatterns(context),
      deviations: this.detectBehaviorDeviations(context)
    };

    console.log(`   ✓ 预测行为: ${prediction.behavior}`);
    console.log(`   ✓ 发生概率: ${prediction.probability.toFixed(3)}`);

    return prediction;
  }

  /**
   * 预测下一个行为
   * @param {Object} context - 上下文信息
   * @returns {String} 预测行为
   */
  predictNextBehavior(context) {
    const userProfile = this.getUserProfile(context.userId);

    // 基于用户画像
    if (userProfile && userProfile.behaviorHistory) {
      const behaviorScores = {};
      for (const behavior of userProfile.behaviorHistory) {
        behaviorScores[behavior.behavior] = (behaviorScores[behavior.behavior] || 0) + 1;
      }

      let bestBehavior = null;
      let maxScore = 0;
      for (const [behavior, score] of Object.entries(behaviorScores)) {
        if (score > maxScore) {
          maxScore = score;
          bestBehavior = behavior;
        }
      }

      if (bestBehavior) {
        return bestBehavior;
      }
    }

    // 基于时间模式
    const hour = context.time?.hour;
    if (hour !== undefined) {
      if (hour >= 9 && hour < 12) return 'work_primary';
      if (hour >= 13 && hour < 18) return 'work_secondary';
      if (hour >= 18 && hour < 22) return 'personal_interest';
      return 'random_browsing';
    }

    // 基于频率模式
    if (context.frequency?.daily > 5) {
      return 'routine_task';
    }

    return 'new_behavior';
  }

  /**
   * 计算行为发生概率
   * @param {Object} context - 上下文信息
   * @returns {Number} 概率（0-1）
   */
  calculateBehaviorLikelihood(context) {
    const userProfile = this.getUserProfile(context.userId);

    let likelihood = 0.5;

    // 基于用户画像
    if (userProfile) {
      if (userProfile.behaviorMatch > 0.7) {
        likelihood = userProfile.behaviorMatch;
      } else if (userProfile.behaviorMatch > 0.5) {
        likelihood = 0.6 + userProfile.behaviorMatch * 0.2;
      }
    }

    // 基于时间模式
    if (context.time?.isWorkHour) {
      likelihood += 0.2;
    }

    // 基于频率模式
    if (context.frequency?.daily) {
      likelihood += Math.min(0.3, context.frequency.daily / 20);
    }

    return Math.min(1, Math.max(0, likelihood));
  }

  /**
   * 计算行为概率
   * @param {Object} context - 上下文信息
   * @returns {Number} 概率（0-1）
   */
  calculateBehaviorProbability(context) {
    const likelihood = this.calculateBehaviorLikelihood(context);

    // 考虑预测窗口
    const window = context.predictWindow || this.config.behaviorPrediction.predictWithinHours;

    // 概率随时间衰减
    const decay = Math.exp(-context.hoursAgo / window);

    return likelihood * decay;
  }

  /**
   * 识别行为模式
   * @param {Object} context - 上下文信息
   * @returns {Object} 行为模式
   */
  identifyBehaviorPatterns(context) {
    const patterns = {
      frequency: this.analyzeBehaviorFrequency(context),
      timing: this.analyzeBehaviorTiming(context),
      sequence: this.analyzeBehaviorSequence(context),
      variation: this.analyzeBehaviorVariation(context)
    };

    return patterns;
  }

  /**
   * 检测行为偏差
   * @param {Object} context - 上下文信息
   * @returns {Array} 偏差列表
   */
  detectBehaviorDeviations(context) {
    const deviations = [];
    const userProfile = this.getUserProfile(context.userId);
    const windowSize = this.config.deviationDetection.windowSize;

    if (!userProfile || !userProfile.behaviorHistory) {
      return deviations;
    }

    const history = userProfile.behaviorHistory.slice(-windowSize);
    if (history.length < windowSize) {
      return deviations;
    }

    // 计算平均行为频率
    const avgFrequency = this.calculateAverageFrequency(history);
    const currentFrequency = this.getCurrentFrequency(context);

    // 检测频率偏差
    const frequencyDeviation = Math.abs(currentFrequency - avgFrequency) / avgFrequency;
    if (frequencyDeviation > (1 - this.config.deviationDetection.threshold)) {
      deviations.push({
        type: 'frequency',
        deviation: frequencyDeviation,
        message: `行为频率异常: 当前${currentFrequency}，平均${avgFrequency}`
      });
    }

    // 检测时间偏差
    const timingDeviation = this.calculateTimingDeviation(history, context);
    if (timingDeviation > 0.3) {
      deviations.push({
        type: 'timing',
        deviation: timingDeviation,
        message: `行为时间异常: 偏离正常时间${timingDeviation * 100}%`
      });
    }

    return deviations;
  }

  /**
   * 计算平均频率
   * @param {Array} history - 历史记录
   * @returns {Number} 平均频率
   */
  calculateAverageFrequency(history) {
    const totalTime = history.reduce((sum, h) => sum + h.duration, 0);
    const behaviorCount = history.length;
    return behaviorCount / (totalTime / 3600); // 每小时行为次数
  }

  /**
   * 计算当前频率
   * @param {Object} context - 上下文信息
   * @returns {Number} 当前频率
   */
  getCurrentFrequency(context) {
    if (context.frequency?.daily) {
      return context.frequency.daily;
    }
    return 1.0;
  }

  /**
   * 计算时间偏差
   * @param {Array} history - 历史记录
   * @param {Object} context - 上下文信息
   * @returns {Number} 时间偏差值
   */
  calculateTimingDeviation(history, context) {
    const avgHour = history.reduce((sum, h) => sum + h.hour, 0) / history.length;
    const currentHour = context.time?.hour || new Date().getHours();

    return Math.abs(currentHour - avgHour) / 24;
  }

  /**
   * 更新用户画像
   * @param {String} userId - 用户ID
   * @param {Object} data - 画像数据
   */
  updateUserProfile(userId, data) {
    if (!this.userProfiles.has(userId)) {
      this.userProfiles.set(userId, {
        userId: userId,
        lastUpdated: Date.now(),
        intentHistory: [],
        behaviorHistory: []
      });
    }

    const profile = this.userProfiles.get(userId);

    // 合并数据
    Object.assign(profile, data);

    // 更新时间戳
    profile.lastUpdated = Date.now();

    // 更新历史
    if (data.lastIntent) {
      profile.intentHistory.push(data.lastIntent);
    }

    if (data.lastBehavior) {
      profile.behaviorHistory.push(data.lastBehavior);
    }

    // 更新偏好
    if (data.preferences) {
      profile.preferences = {
        ...profile.preferences,
        ...data.preferences
      };
    }

    // 限制历史记录长度
    if (profile.intentHistory.length > 100) {
      profile.intentHistory = profile.intentHistory.slice(-100);
    }

    if (profile.behaviorHistory.length > 100) {
      profile.behaviorHistory = profile.behaviorHistory.slice(-100);
    }

    console.log(`   ✓ 用户画像已更新 (${profile.intentHistory.length}条意图记录)`);
  }

  /**
   * 获取用户画像
   * @param {String} userId - 用户ID
   * @returns {Object} 用户画像
   */
  getUserProfile(userId) {
    return this.userProfiles.get(userId) || null;
  }

  /**
   * 获取系统状态
   * @returns {Object} 系统状态
   */
  getStatus() {
    return {
      name: this.name,
      config: this.config,
      intentLibrarySize: this.intentLibrary.size,
      userProfilesCount: this.userProfiles.size,
      totalIntentsTracked: Array.from(this.userProfiles.values())
        .reduce((sum, p) => sum + (p.intentHistory?.length || 0), 0),
      totalBehaviorsTracked: Array.from(this.userProfiles.values())
        .reduce((sum, p) => sum + (p.behaviorHistory?.length || 0), 0)
    };
  }
}

module.exports = AdvancedUserBehaviorProfile;
