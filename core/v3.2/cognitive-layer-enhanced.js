/**
 * OpenClaw 3.3 - 认知层增强（Cognitive Layer Enhanced）
 * 集成任务模式识别和用户行为画像
 * 
 * @version 3.3.0
 * @author OpenClaw V3.3
 * @date 2026-02-22
 */

const EnhancedTaskPatternRecognizer = require('./enhanced-task-pattern-recognizer');
const AdvancedUserBehaviorProfile = require('./advanced-user-behavior-profile');

class CognitiveLayerEnhanced {
  constructor(config = {}) {
    this.name = 'CognitiveLayerEnhanced';
    this.config = {
      // 认知层配置
      enablePatternRecognition: true,
      enableIntentInference: true,
      enableBehaviorPrediction: true,
      enableExperienceRetrieval: true,
      enableFailureAnalysis: true,

      // 集成配置
      patternRecognitionConfig: {},
      intentInferenceConfig: {},
      behaviorPredictionConfig: {},

      ...config
    };

    // 初始化各模块
    this.patternRecognizer = new EnhancedTaskPatternRecognizer(this.config.patternRecognitionConfig);
    this.behaviorProfile = new AdvancedUserBehaviorProfile(this.config.intentInferenceConfig);

    console.log('🧠 CognitiveLayerEnhanced 初始化完成\n');
  }

  /**
   * 认知分析主流程
   * @param {Object} context - 上下文信息
   * @returns {Promise<Object>} 认知分析结果
   */
  async cognitiveAnalysis(context) {
    console.log('═════════════════════════════════════════════════════════════');
    console.log('              🧠 认知分析流程开始');
    console.log('═════════════════════════════════════════════════════════════\n');

    try {
      // 1. 任务模式识别
      console.log('📊 步骤1: 任务模式识别（深度模式提取）');
      const patternRecognition = await this.patternRecognizer.recognizeTaskPattern(context);
      console.log(`✅ 模式识别完成: ${patternRecognition.patternCount}个模式\n`);

      // 2. 用户意图推断
      console.log('📊 步骤2: 用户意图推断');
      const intentInference = this.behaviorProfile.inferIntent(context);
      console.log(`✅ 意图推断完成: ${intentInference.type} - ${intentInference.category}\n`);

      // 3. 行为预测
      console.log('📊 步骤3: 行为预测');
      const behaviorPrediction = this.behaviorProfile.predictBehavior(context);
      console.log(`✅ 行为预测完成: ${behaviorPrediction.behavior} (${behaviorPrediction.probability.toFixed(3)})\n`);

      // 4. 经验检索
      console.log('📊 步骤4: 经验检索');
      const experienceRetrieval = this.retrieveExperiences(patternRecognition, intentInference);
      console.log(`✅ 经验检索完成: ${experienceRetrieval.experiences.length}条相关经验\n`);

      // 5. 生成认知建议
      console.log('📊 步骤5: 生成认知建议');
      const recommendations = this.generateRecommendations(
        patternRecognition,
        intentInference,
        behaviorPrediction,
        experienceRetrieval
      );
      console.log(`✅ 认知建议生成完成: ${recommendations.length}条建议\n`);

      console.log('═════════════════════════════════════════════════════════════');
      console.log('              ✅ 认知分析流程完成');
      console.log('═════════════════════════════════════════════════════════════\n');

      return {
        timestamp: Date.now(),
        context: context,
        patternRecognition: patternRecognition,
        intentInference: intentInference,
        behaviorPrediction: behaviorPrediction,
        experienceRetrieval: experienceRetrieval,
        recommendations: recommendations
      };

    } catch (error) {
      console.error('❌ 认知分析流程失败:', error.message);
      throw error;
    }
  }

  /**
   * 检索相关经验
   * @param {Object} patternRecognition - 模式识别结果
   * @param {Object} intentInference - 意图推断结果
   * @returns {Object} 经验检索结果
   */
  retrieveExperiences(patternRecognition, intentInference) {
    console.log(`   🔍 检索模式相关经验...`);

    const experiences = {
      byPattern: this.retrieveByPatterns(patternRecognition),
      byIntent: this.retrieveByIntent(intentInference),
      combined: this.retrieveCombined(patternRecognition, intentInference)
    };

    console.log(`   ✓ 模式相关: ${experiences.byPattern.length}条`);
    console.log(`   ✓ 意图相关: ${experiences.byIntent.length}条`);
    console.log(`   ✓ 综合检索: ${experiences.combined.length}条`);

    return experiences;
  }

  /**
   * 按模式检索经验
   * @param {Object} patternRecognition - 模式识别结果
   * @returns {Array>} 经验列表
   */
  retrieveByPatterns(patternRecognition) {
    const experiences = [];

    // 从模式库检索
    if (patternRecognition.patternLibrary) {
      for (const [key, pattern] of patternRecognition.patternLibrary) {
        if (pattern.pattern) {
          experiences.push({
            pattern: pattern.pattern,
            description: pattern.description,
            confidence: pattern.confidence
          });
        }
      }
    }

    return experiences.slice(0, 5); // 限制返回数量
  }

  /**
   * 按意图检索经验
   * @param {Object} intentInference - 意图推断结果
   * @returns {Array>} 经验列表
   */
  retrieveByIntent(intentInference) {
    const experiences = [];

    // 从用户画像检索
    const userProfile = this.behaviorProfile.getUserProfile(intentInference.userId);

    if (userProfile && userProfile.intentHistory) {
      for (const intent of userProfile.intentHistory.slice(-10)) {
        experiences.push({
          intentType: intent.type,
          confidence: intent.confidence,
          description: `历史${intent.type}意图`
        });
      }
    }

    return experiences.slice(0, 5);
  }

  /**
   * 综合检索经验
   * @param {Object} patternRecognition - 模式识别结果
   * @param {Object} intentInference - 意图推断结果
   * @returns {Array>} 经验列表
   */
  retrieveCombined(patternRecognition, intentInference) {
    const experiences = [];

    // 结合模式意图和用户历史
    const userProfile = this.behaviorProfile.getUserProfile(intentInference.userId);

    if (userProfile && userProfile.intentHistory) {
      for (const intent of userProfile.intentHistory.slice(-5)) {
        experiences.push({
          intentType: intent.type,
          confidence: intent.confidence,
          source: 'user_history'
        });
      }
    }

    // 添加模式识别经验
    if (patternRecognition.patternLibrary) {
      for (const [key, pattern] of patternRecognition.patternLibrary) {
        if (pattern.category) {
          experiences.push({
            pattern: pattern.category,
            confidence: pattern.confidence,
            source: 'pattern_recognition'
          });
        }
      }
    }

    return experiences.slice(0, 10);
  }

  /**
   * 生成认知建议
   * @param {Object} patternRecognition - 模式识别结果
   * @param {Object} intentInference - 意图推断结果
   * @param {Object} behaviorPrediction - 行为预测结果
   * @param {Object} experienceRetrieval - 经验检索结果
   * @returns {Array>} 建议列表
   */
  generateRecommendations(patternRecognition, intentInference, behaviorPrediction, experienceRetrieval) {
    const recommendations = [];

    // 1. 基于模式识别的建议
    if (patternRecognition.patternCount > 0) {
      recommendations.push({
        type: 'pattern',
        priority: 'HIGH',
        category: 'task_optimization',
        title: `优化${patternRecognition.patternCount}个任务模式`,
        description: `识别到${patternRecognition.patternCount}个模式，建议优化`,
        actions: [
          '根据模式分析优化任务流程',
          '应用历史成功模式',
          '避免已知低效模式'
        ]
      });
    }

    // 2. 基于意图推断的建议
    if (intentInference.confidence > 0.8) {
      recommendations.push({
        type: 'intent',
        priority: 'HIGH',
        category: 'intent_understanding',
        title: `准确识别意图: ${intentInference.type}`,
        description: `意图置信度${intentInference.confidence.toFixed(2)}，可直接响应`,
        actions: [
          '快速响应识别意图',
          '提供相关上下文',
          '减少确认步骤'
        ]
      });
    }

    // 3. 基于行为预测的建议
    if (behaviorPrediction.probability > 0.8) {
      recommendations.push({
        type: 'behavior',
        priority: 'MEDIUM',
        category: 'proactive_service',
        title: `预测行为: ${behaviorPrediction.behavior}`,
        description: `行为发生概率${behaviorPrediction.probability.toFixed(3)}，可以预先准备`,
        actions: [
          '提前加载相关资源',
          '准备响应模板',
          '优化性能瓶颈'
        ]
      });
    }

    // 4. 基于经验的建议
    if (experienceRetrieval.combined.length > 0) {
      recommendations.push({
        type: 'experience',
        priority: 'MEDIUM',
        category: 'experience_based',
        title: `基于${experienceRetrieval.combined.length}条相关经验`,
        description: '应用历史经验优化当前任务',
        actions: [
          '参考相似任务的成功经验',
          '避免历史错误模式',
          '复用成功实践'
        ]
      });
    }

    // 按优先级排序
    recommendations.sort((a, b) => {
      const priorityOrder = { 'HIGH': 3, 'MEDIUM': 2, 'LOW': 1 };
      return priorityOrder[b.priority] - priorityOrder[a.priority];
    });

    console.log(`   📝 生成${recommendations.length}条认知建议`);

    return recommendations;
  }

  /**
   * 更新用户画像
   * @param {String} userId - 用户ID
   * @param {Object} data - 画像数据
   */
  updateUserProfile(userId, data) {
    this.behaviorProfile.updateUserProfile(userId, data);
  }

  /**
   * 获取用户画像
   * @param {String} userId - 用户ID
   * @returns {Object} 用户画像
   */
  getUserProfile(userId) {
    return this.behaviorProfile.getUserProfile(userId);
  }

  /**
   * 识别用户模式
   * @param {String} userId - 用户ID
   * @returns {Object} 用户模式识别结果
   */
  identifyUserPattern(userId) {
    const userProfile = this.behaviorProfile.getUserProfile(userId);

    if (!userProfile) {
      return {
        recognized: false,
        patterns: []
      };
    }

    // 分析用户行为模式
    const patterns = this.analyzeUserPatterns(userProfile);

    return {
      recognized: true,
      patterns: patterns,
      profile: userProfile
    };
  }

  /**
   * 分析用户模式
   * @param {Object} userProfile - 用户画像
   * @returns {Array>} 模式列表
   */
  analyzeUserPatterns(userProfile) {
    const patterns = [];

    // 基于行为历史分析
    if (userProfile.behaviorHistory && userProfile.behaviorHistory.length > 0) {
      const behaviors = userProfile.behaviorHistory.map(h => h.behavior);
      const behaviorCount = {};

      for (const behavior of behaviors) {
        behaviorCount[behavior] = (behaviorCount[behavior] || 0) + 1;
      }

      for (const [behavior, count] of Object.entries(behaviorCount)) {
        const total = behaviors.length;
        const frequency = count / total;

        patterns.push({
          type: behavior,
          frequency: frequency,
          count: count,
          description: `行为${behavior}出现${count}次`
        });
      }
    }

    // 基于意图历史分析
    if (userProfile.intentHistory && userProfile.intentHistory.length > 0) {
      const intents = userProfile.intentHistory.map(h => h.type);
      const intentCount = {};

      for (const intent of intents) {
        intentCount[intent] = (intentCount[intent] || 0) + 1;
      }

      for (const [intent, count] of Object.entries(intentCount)) {
        const total = intents.length;
        const frequency = count / total;

        patterns.push({
          type: intent,
          frequency: frequency,
          count: count,
          description: `意图${intent}出现${count}次`
        });
      }
    }

    // 排序：按频率降序
    patterns.sort((a, b) => b.frequency - a.frequency);

    return patterns;
  }

  /**
   * 获取系统状态
   * @returns {Object} 系统状态
   */
  getStatus() {
    return {
      name: this.name,
      config: this.config,
      patternRecognizer: this.patternRecognizer.getStatus(),
      behaviorProfile: this.behaviorProfile.getStatus(),
      userProfiles: this.behaviorProfile.userProfiles.size,
      patternsLibrary: this.patternRecognizer.patternLibrary.size
    };
  }
}

module.exports = CognitiveLayerEnhanced;
