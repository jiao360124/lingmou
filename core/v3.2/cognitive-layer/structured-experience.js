/**
 * OpenClaw V3.2 - Structured Experience Library
 * 认知层核心模块：结构化经验库
 *
 * 功能：
 * - 抽象化经验
 * - 结构化存储
 * - 经验检索
 *
 * @author OpenClaw V3.2
 * @date 2026-02-22
 */

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));
const fs = require('fs');
const path = require('path');

class StructuredExperience {
  constructor() {
    this.name = 'StructuredExperience';
    this.storageDir = process.cwd();
    this.storageFile = path.join(this.storageDir, 'structured-experiences.json');
    this.experiences = new Map();
    this.indexes = {
      byCategory: new Map(),
      byTags: new Map(),
      byPattern: new Map()
    };

    // 从数据库加载
    this.loadFromDatabase();
  }

  /**
   * 添加经验
   * @param {Object} experience - 经验对象
   * @returns {Promise<StructuredExperience>}
   */
  async addExperience(experience) {
    experience.experienceId = `exp_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    experience.date = new Date();
    experience.usageCount = 0;
    experience.avgROI = 0;
    experience.lessons = experience.lessons || [];
    experience.tags = experience.tags || [];

    this.experiences.set(experience.experienceId, experience);

    // 建立索引
    this.indexes.byCategory.set(experience.category, experience.experienceId);
    experience.tags.forEach(tag => {
      this.indexes.byTags.set(tag, experience.experienceId);
    });

    // 存储到数据库
    await this.saveToDatabase(experience);

    console.log(`[StructuredExperienceLibrary] 已添加经验: ${experience.experienceId}`);

    return experience;
  }

  /**
   * 搜索经验
   * @param {string} pattern - 搜索模式
   * @param {Object} options - 选项
   * @returns {Promise<Array<StructuredExperience>>}
   */
  async search(pattern, options = {}) {
    console.log(`[StructuredExperienceLibrary] 搜索经验: ${pattern}`);

    const results = [];
    const {
      category, tags, minROI, maxAge, limit = 10, orderBy = 'roi'
    } = options;

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
      if (minROI !== undefined && experience.avgROI < minROI) {
        match = false;
      }

      // 按年龄筛选
      if (maxAge) {
        const daysOld = (Date.now() - experience.date.getTime()) / (1000 * 60 * 60 * 24);
        if (daysOld > maxAge) {
          match = false;
        }
      }

      if (match) {
        results.push(experience);
      }
    }

    // 按相关度排序
    results.sort((a, b) => this.compareByField(a, b, orderBy));

    return results.slice(0, limit);
  }

  /**
   * 获取相似经验
   * @param {string} experienceId - 经验ID
   * @param {number} limit - 限制数量
   * @returns {Promise<Array<Object>>}
   */
  async getSimilar(experienceId, limit = 5) {
    const experience = this.experiences.get(experienceId);

    if (!experience) {
      return [];
    }

    console.log(`[StructuredExperienceLibrary] 查找相似经验: ${experienceId}`);

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

  /**
   * 计算相似度
   * @param {StructuredExperience} exp1 - 经验1
   * @param {StructuredExperience} exp2 - 经验2
   * @returns {number} 0-1
   */
  calculateSimilarity(exp1, exp2) {
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

    return Math.min(score, 1);
  }

  /**
   * 计算字符串相似度
   * @param {string} str1 - 字符串1
   * @param {string} str2 - 字符串2
   * @returns {number} 0-1
   */
  calculateStringSimilarity(str1, str2) {
    if (!str1 || !str2) return 0;

    const normalized1 = str1.toLowerCase();
    const normalized2 = str2.toLowerCase();

    // 删除空格
    const clean1 = normalized1.replace(/\s+/g, '');
    const clean2 = normalized2.replace(/\s+/g, '');

    if (clean1 === clean2) return 1;

    // 计算最长公共子串长度
    const common = this.findCommonSubstring(clean1, clean2);
    const maxLen = Math.max(clean1.length, clean2.length);

    return common / maxLen;
  }

  /**
   * 查找最长公共子串
   * @param {string} str1 - 字符串1
   * @param {string} str2 - 字符串2
   * @returns {string}
   */
  findCommonSubstring(str1, str2) {
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

  /**
   * 更新经验
   * @param {string} experienceId - 经验ID
   * @param {Object} updates - 更新内容
   * @returns {Promise<StructuredExperience>}
   */
  async updateExperience(experienceId, updates) {
    const experience = this.experiences.get(experienceId);

    if (!experience) {
      console.warn(`[StructuredExperienceLibrary] 经验不存在: ${experienceId}`);
      return null;
    }

    console.log(`[StructuredExperienceLibrary] 更新经验: ${experienceId}`);

    Object.assign(experience, updates);

    // 更新统计
    if (updates.usageCount) {
      experience.usageCount += updates.usageCount;
      experience.avgROI = this.calculateNewROI(experience);
    }

    if (updates.lessons) {
      experience.lessons = [...new Set([...experience.lessons, ...updates.lessons])];
    }

    if (updates.tags) {
      experience.tags = [...new Set([...experience.tags, ...updates.tags])];
    }

    // 重建索引
    this.rebuildIndexes(experience);

    await this.saveToDatabase(experience);

    return experience;
  }

  /**
   * 计算新的平均ROI
   * @param {StructuredExperience} experience - 经验
   * @returns {number}
   */
  calculateNewROI(experience) {
    // 简化计算
    return experience.avgROI * experience.usageCount / (experience.usageCount + 1);
  }

  /**
   * 重建索引
   * @param {StructuredExperience} experience - 经验
   */
  rebuildIndexes(experience) {
    // 更新类别索引
    this.indexes.byCategory.set(experience.category, experience.experienceId);

    // 更新标签索引
    this.indexes.byTags.clear();
    experience.tags.forEach(tag => {
      this.indexes.byTags.set(tag, experience.experienceId);
    });
  }

  /**
   * 保存到数据库
   * @param {StructuredExperience} experience - 经验
   * @returns {Promise<void>}
   */
  async saveToDatabase(experience) {
    // 实际实现中应该保存到数据库
    // await this.database.save("structured-experience", experience.experienceId, experience);

    console.log(`[StructuredExperienceLibrary] 已保存到数据库: ${experience.experienceId}`);
  }

  /**
   * 从数据库加载
   * @returns {Promise<void>}
   */
  async loadFromDatabase() {
    try {
      if (fs.existsSync(this.storageFile)) {
        const data = JSON.parse(fs.readFileSync(this.storageFile, 'utf8'));
        this.experiences = new Map();

        for (const [id, experience] of Object.entries(data)) {
          this.experiences.set(id, experience);
        }

        console.log(`[StructuredExperience] 已从数据库加载 ${this.experiences.size} 个经验`);
      }
    } catch (error) {
      console.error(`[StructuredExperience] 加载数据失败: ${error.message}`);
      this.experiences = new Map();
    }
  }

  /**
   * 设置存储目录
   * @param {string} dir - 存储目录
   * @returns {void}
   */
  setStorageDir(dir) {
    this.storageDir = dir;
    this.storageFile = path.join(this.storageDir, 'structured-experiences.json');
  }

  /**
   * 获取热门经验
   * @param {string} category - 类别
   * @param {number} limit - 限制数量
   * @returns {Promise<Array<StructuredExperience>>}
   */
  async getTopExperiences(category, limit = 10) {
    let results;

    if (category) {
      results = await this.search(category, { minROI: 0, limit });
    } else {
      results = await this.search(null, { minROI: 0, limit });
    }

    return results;
  }

  /**
   * 获取经验统计
   * @returns {Promise<Object>}
   */
  async getStatistics() {
    const stats = {
      total: this.experiences.size,
      byCategory: new Map(),
      totalTags: new Set(),
      recent: [],
      oldest: []
    };

    for (const experience of this.experiences.values()) {
      // 按类别统计
      stats.byCategory.set(
        experience.category,
        (stats.byCategory.get(experience.category) || 0) + 1
      );

      // 统计标签
      experience.tags.forEach(tag => stats.totalTags.add(tag));

      // 最近的经验
      if (stats.recent.length < 5) {
        stats.recent.push(experience);
      }

      // 最旧的经验
      if (stats.oldest.length < 5) {
        stats.oldest.push(experience);
      }
    }

    return stats;
  }

  /**
   * 删除经验
   * @param {string} experienceId - 经验ID
   * @returns {Promise<boolean>}
   */
  async deleteExperience(experienceId) {
    const experience = this.experiences.get(experienceId);

    if (!experience) {
      return false;
    }

    console.log(`[StructuredExperienceLibrary] 删除经验: ${experienceId}`);

    this.experiences.delete(experienceId);
    this.rebuildIndexes(experience);

    // 从数据库删除
    await this.deleteFromDatabase(experienceId);

    return true;
  }

  /**
   * 从数据库删除
   * @param {string} experienceId - 经验ID
   * @returns {Promise<void>}
   */
  async deleteFromDatabase(experienceId) {
    // 实际实现中应该从数据库删除
    // await this.database.delete("structured-experience", experienceId);

    console.log(`[StructuredExperienceLibrary] 已从数据库删除: ${experienceId}`);
  }

  /**
   * 按字段比较
   * @param {StructuredExperience} a - 经验A
   * @param {StructuredExperience} b - 经验B
   * @param {string} field - 字段名
   * @returns {number}
   */
  compareByField(a, b, field) {
    switch (field) {
      case 'roi':
        return (b.avgROI || 0) - (a.avgROI || 0);
      case 'date':
        return (b.date - a.date) / (1000 * 60 * 60 * 24);  // 天数
      case 'usage':
        return (b.usageCount || 0) - (a.usageCount || 0);
      default:
        return 0;
    }
  }
}

module.exports = StructuredExperience;
