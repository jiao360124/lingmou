/**
 * OpenClaw V3.2 - User Behavior Profile
 * 认知层核心模块：用户行为画像
 *
 * 功能：
 * - 学习主人工作习惯
 * - 建立用户画像
 * - 预测偏好
 *
 * @author OpenClaw V3.2
 * @date 2026-02-22
 */

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));
const fs = require('fs');
const path = require('path');

class UserBehaviorProfile {
  constructor(userId) {
    this.userId = userId || 'default';
    this.profile = null;
    this.profileLoaded = false;
    this.storageDir = process.cwd();
    this.storageFile = path.join(this.storageDir, 'user-behavior-profiles.json');
  }

  /**
   * 设置存储目录
   * @param {string} dir - 存储目录
   * @returns {void}
   */
  setStorageDir(dir) {
    this.storageDir = dir;
    this.storageFile = path.join(this.storageDir, 'user-behavior-profiles.json');
  }

  /**
   * 加载画像
   * @returns {Promise<UserProfile>}
   */
  async load() {
    if (this.profileLoaded) {
      return this.profile;
    }

    this.profile = await this.loadProfileFromDB();

    if (!this.profile) {
      this.profile = this.createEmptyProfile();
      console.log(`[UserBehaviorProfile] 创建新用户画像: ${this.userId}`);
    } else {
      console.log(`[UserBehaviorProfile] 加载用户画像: ${this.userId}`);
    }

    this.profileLoaded = true;
    return this.profile;
  }

  /**
   * 从数据库加载
   * @returns {Promise<UserProfile>}
   */
  async loadProfileFromDB() {
    try {
      if (fs.existsSync(this.storageFile)) {
        const data = JSON.parse(fs.readFileSync(this.storageFile, 'utf8'));
        return data[this.userId] || null;
      }
    } catch (error) {
      console.error(`[UserBehaviorProfile] 加载数据失败: ${error.message}`);
    }
    return null;
  }

  /**
   * 保存画像
   * @param {UserProfile} profile - 画像
   * @returns {Promise<void>}
   */
  async saveProfile(profile) {
    try {
      let profiles = {};
      if (fs.existsSync(this.storageFile)) {
        profiles = JSON.parse(fs.readFileSync(this.storageFile, 'utf8'));
      }

      profiles[this.userId] = profile;
      fs.writeFileSync(this.storageFile, JSON.stringify(profiles, null, 2));
      console.log(`[UserBehaviorProfile] 画像已保存: ${this.userId}`);
    } catch (error) {
      console.error(`[UserBehaviorProfile] 保存失败: ${error.message}`);
    }
  }

  /**
   * 加载用户画像
   * @returns {Promise<UserProfile>}
   */
  async load() {
    if (this.profileLoaded) {
      return this.profile;
    }

    this.profile = await this.loadProfileFromDB();

    if (!this.profile) {
      this.profile = this.createEmptyProfile();
      console.log(`[UserBehaviorProfile] 创建新用户画像: ${this.userId}`);
    } else {
      console.log(`[UserBehaviorProfile] 加载用户画像: ${this.userId}`);
    }

    this.profileLoaded = true;
    return this.profile;
  }

  /**
   * 从数据库加载
   * @returns {Promise<UserProfile>}
   */
  async loadProfileFromDB() {
    // 实际实现中应该从数据库读取
    // return await this.database.load("user-profile", this.userId);

    // 模拟数据
    return {
      userId: this.userId,
      profileType: "developer",
      preferences: {
        preferredModel: "mid-tier",
        compressionLevel: 2,
        responseStyle: "balanced",
        timePatterns: {},
        channelPreferences: {},
        qualityThreshold: 0.8
      },
      history: {
        totalSessions: 127,
        avgTokensPerSession: 78500,
        avgSuccessRate: 0.88,
        last30Days: 127,
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

  /**
   * 创建空画像
   * @returns {UserProfile}
   */
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

  /**
   * 更新画像
   * @param {Object} taskResult - 任务结果
   * @returns {Promise<UserProfile>}
   */
  async update(taskResult) {
    console.log(`[UserBehaviorProfile] 更新用户画像: ${this.userId}`);

    const profile = await this.load();

    // 1. 更新历史
    this.updateHistory(profile, taskResult);

    // 2. 更新偏好
    this.updatePreferences(profile, taskResult);

    // 3. 生成预测
    this.updatePredictions(profile);

    // 4. 保存
    await this.saveProfile(profile);

    console.log(`[UserBehaviorProfile] 画像已更新: ${this.userId}`);

    return profile;
  }

  /**
   * 更新历史
   * @param {UserProfile} profile - 画像
   * @param {Object} taskResult - 任务结果
   */
  updateHistory(profile, taskResult) {
    profile.history.totalSessions++;

    // 平均 Token 使用
    const prevAvg = profile.history.avgTokensPerSession;
    const newAvg = (prevAvg * (profile.history.totalSessions - 1) + taskResult.tokensUsed) / profile.history.totalSessions;
    profile.history.avgTokensPerSession = newAvg;

    // 平均成功率
    const prevSuccess = profile.history.avgSuccessRate;
    const newSuccess = (prevSuccess * (profile.history.totalSessions - 1) + (taskResult.successRate || 0)) / profile.history.totalSessions;
    profile.history.avgSuccessRate = newSuccess;

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

  /**
   * 更新偏好
   * @param {UserProfile} profile - 画像
   * @param {Object} taskResult - 任务结果
   */
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

  /**
   * 更新预测
   * @param {UserProfile} profile - 画像
   */
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

  /**
   * 计算置信度
   * @param {number} total - 总数
   * @param {number} count - 数量
   * @returns {number}
   */
  calculateConfidence(total, count) {
    // 贝叶斯置信度计算
    return count / total;
  }

  /**
   * 预测上下文
   * @param {Object} context - 上下文
   * @returns {Promise<Object>}
   */
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

  /**
   * 预测上下文大小
   * @param {UserProfile} profile - 画像
   * @returns {Object}
   */
  predictContextSize(profile) {
    // 根据历史平均预测
    const avg = profile.history.avgTokensPerSession;
    const variance = this.calculateVariance(profile.history.byHour);

    return {
      suggested: Math.round(avg * (1 + variance * 0.1)),
      range: [Math.round(avg * 0.8), Math.round(avg * 1.2)]
    };
  }

  /**
   * 计算方差
   * @param {Object} data - 数据
   * @returns {number}
   */
  calculateVariance(data) {
    const values = Object.values(data);
    if (values.length === 0) return 0;

    const avg = values.reduce((sum, v) => sum + v, 0) / values.length;
    const variance = values.reduce((sum, v) => sum + Math.pow(v - avg, 2), 0) / values.length;

    return Math.sqrt(variance);
  }

  /**
   * 保存画像
   * @param {UserProfile} profile - 画像
   * @returns {Promise<void>}
   */
  async saveProfile(profile) {
    // 实际实现中应该保存到数据库
    // await this.database.save("user-profile", this.userId, profile);

    console.log(`[UserBehaviorProfile] 画像已保存: ${this.userId}`);
  }

  /**
   * 预测行为
   * @param {Object} context - 上下文
   * @returns {Promise<Object>}
   */
  async predictBehavior(context) {
    const profile = await this.load();

    const predictions = {
      preferredModel: profile.preferences.preferredModel,
      likelyTaskType: this.predictLikelyTaskType(profile),
      bestTime: profile.predictions.bestTime,
      confidence: this.calculatePredictionConfidence(profile)
    };

    return predictions;
  }

  /**
   * 预测任务类型
   * @param {UserProfile} profile - 画像
   * @returns {string|null}
   */
  predictLikelyTaskType(profile) {
    if (Object.keys(profile.history.taskDistribution).length === 0) {
      return null;
    }

    const topTask = Object.entries(profile.history.taskDistribution)
      .reduce((max, t) => t[1] > max[1] ? t : max);

    return topTask[0];
  }

  /**
   * 计算预测置信度
   * @param {UserProfile} profile - 画像
   * @returns {number}
   */
  calculatePredictionConfidence(profile) {
    if (profile.history.totalSessions === 0) {
      return 0;
    }

    // 置信度基于历史数据
    return Math.min(profile.history.totalSessions / 50, 1);
  }

  /**
   * 获取画像
   * @returns {Promise<UserProfile>}
   */
  async getProfile() {
    return await this.load();
  }

  /**
   * 更新偏好设置
   * @param {Object} preferences - 偏好设置
   * @returns {Promise<void>}
   */
  async updatePreferencesSet(preferences) {
    const profile = await this.load();

    Object.assign(profile.preferences, preferences);

    await this.saveProfile(profile);

    console.log(`[UserBehaviorProfile] 偏好已更新: ${this.userId}`);
  }

  /**
   * 获取推荐策略
   * @param {Object} context - 上下文
   * @returns {Promise<Object>}
   */
  async getRecommendedStrategy(context) {
    const profile = await this.load();

    return {
      responseStyle: profile.preferences.responseStyle,
      compressionLevel: profile.preferences.compressionLevel,
      preferredModel: profile.preferences.preferredModel,
      qualityThreshold: profile.preferences.qualityThreshold
    };
  }
}

module.exports = UserBehaviorProfile;
