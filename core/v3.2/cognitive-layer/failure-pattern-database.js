/**
 * OpenClaw V3.2 - Failure Pattern Database
 * 认知层核心模块：失败模式数据库
 *
 * 功能：
 * - 识别重复错误
 * - 建立失败模式库
 * - 生成规避建议
 *
 * @author OpenClaw V3.2
 * @date 2026-02-22
 */

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

class FailurePatternDatabase {
  constructor() {
    this.name = 'FailurePatternDatabase';
    this.patterns = new Map();
    this.mergerThreshold = 5;  // 相似模式合并阈值
  }

  /**
   * 分析任务结果
   * @param {Object} taskResult - 任务结果
   * @returns {Promise<void>}
   */
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

  /**
   * 检测失败模式
   * @param {Object} taskResult - 任务结果
   * @returns {Promise<Object|null>}
   */
  async detectPattern(taskResult) {
    const { failureReason, context, errorDetails } = taskResult;

    console.log(`[FailurePatternDatabase] 检测失败模式: ${failureReason}`);

    // 搜索现有模式
    for (const [patternId, pattern] of this.patterns) {
      const similarity = this.calculateSimilarity(failureReason, pattern);

      if (similarity > 0.7) {
        console.log(`[FailurePatternDatabase] 发现相似模式: ${patternId}, 相似度: ${similarity.toFixed(3)}`);

        return {
          patternId,
          similarity,
          details: pattern,
          isNew: false
        };
      }
    }

    // 如果没有相似模式，创建新模式
    console.log(`[FailurePatternDatabase] 创建新模式: ${failureReason}`);

    const newPattern = this.createNewPattern(taskResult);

    return {
      patternId: newPattern.patternId,
      similarity: 1.0,
      isNew: true,
      details: newPattern
    };
  }

  /**
   * 创建新模式
   * @param {Object} taskResult - 任务结果
   * @returns {FailurePattern}
   */
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
      tags: this.extractTags(taskResult),
      createdAt: new Date()
    };
  }

  /**
   * 生成模式名称
   * @param {Object} taskResult - 任务结果
   * @returns {string}
   */
  generatePatternName(taskResult) {
    // 生成模式名称
    const reason = taskResult.failureReason.toLowerCase();

    if (reason.includes("memory")) return "memory_error";
    if (reason.includes("timeout")) return "timeout_error";
    if (reason.includes("api")) return "api_error";
    if (reason.includes("network")) return "network_error";
    if (reason.includes("permission")) return "permission_error";
    if (reason.includes("validation")) return "validation_error";
    if (reason.includes("authentication")) return "auth_error";
    if (reason.includes("database")) return "database_error";

    // 默认
    return "unknown_error";
  }

  /**
   * 生成描述
   * @param {Object} taskResult - 任务结果
   * @returns {string}
   */
  generateDescription(taskResult) {
    // 生成描述
    return `Task failed due to: ${taskResult.failureReason}. Context: ${taskResult.context}`;
  }

  /**
   * 确定严重程度
   * @param {Object} taskResult - 任务结果
   * @returns {"LOW"|"MEDIUM"|"HIGH"|"CRITICAL"}
   */
  determineSeverity(taskResult) {
    // 确定严重程度
    const errorRate = taskResult.errorRate || 0;
    const hasCriticalDetails = errorDetails?.critical === true;

    if (hasCriticalDetails || errorRate > 0.5) return "CRITICAL";
    if (errorRate > 0.3) return "HIGH";
    if (errorRate > 0.15) return "MEDIUM";
    return "LOW";
  }

  /**
   * 提取失败因素
   * @param {Object} taskResult - 任务结果
   * @returns {string[]}
   */
  extractFactors(taskResult) {
    const factors = [];

    // 检查上下文长度
    if (taskResult.contextLength > 80000) {
      factors.push("too_long_context");
    }

    // 检查 Token 消耗
    if (taskResult.tokensUsed > 150000) {
      factors.push("excessive_tokens");
    }

    // 检查错误率
    if (taskResult.errorRate > 0.3) {
      factors.push("high_error_rate");
    }

    // 检查特定错误类型
    if (taskResult.failureReason) {
      if (taskResult.failureReason.includes("timeout")) {
        factors.push("timeout");
      }
      if (taskResult.failureReason.includes("memory")) {
        factors.push("out_of_memory");
      }
      if (taskResult.failureReason.includes("network")) {
        factors.push("network_failure");
      }
    }

    return factors;
  }

  /**
   * 提取标签
   * @param {Object} taskResult - 任务结果
   * @returns {string[]}
   */
  extractTags(taskResult) {
    const tags = [];

    // 提取严重程度标签
    tags.push(`severity_${taskResult.severity}`);

    // 提取错误类型标签
    if (taskResult.failureReason) {
      const reason = taskResult.failureReason.toLowerCase();
      if (reason.includes("memory")) tags.push("memory");
      if (reason.includes("timeout")) tags.push("timeout");
      if (reason.includes("api")) tags.push("api");
      if (reason.includes("network")) tags.push("network");
    }

    return tags;
  }

  /**
   * 记录模式
   * @param {Object} pattern - 模式
   * @returns {Promise<void>}
   */
  async recordPattern(pattern) {
    console.log(`[FailurePatternDatabase] 记录模式: ${pattern.patternId}, ${pattern.details.patternName}`);

    if (pattern.isNew) {
      // 创建新模式
      this.patterns.set(pattern.patternId, pattern.details);
      await this.saveToDatabase(pattern.patternId, pattern.details);
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

  /**
   * 合并相似模式
   * @param {string} patternId - 模式ID
   * @returns {Promise<void>}
   */
  async mergeSimilarPatterns(patternId) {
    const pattern = this.patterns.get(patternId);

    for (const [otherId, other] of this.patterns) {
      if (otherId === patternId) continue;

      const similarity = this.calculateSimilarity(pattern.description, other.description);

      if (similarity > this.mergerThreshold / 10) {
        // 合并模式
        console.log(`[FailurePatternDatabase] 合并相似模式: ${patternId} → ${otherId}`);
        await this.mergePatterns(patternId, otherId);
      }
    }
  }

  /**
   * 合并模式
   * @param {string} patternId1 - 模式1 ID
   * @param {string} patternId2 - 模式2 ID
   * @returns {Promise<void>}
   */
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
    await this.deleteFromDatabase(patternId2);

    console.log(`[FailurePatternDatabase] 合并完成: ${patternId1} 包含 ${patternId2}`);
  }

  /**
   * 建议缓解措施
   * @param {Object} pattern - 模式
   * @returns {Promise<void>}
   */
  async suggestMitigation(pattern) {
    console.log(`[FailurePatternDatabase] 建议缓解措施: ${pattern.patternId}`);

    const suggestions = [];

    if (pattern.severity === 'HIGH' || pattern.severity === 'CRITICAL') {
      suggestions.push({
        priority: 'HIGH',
        action: 'Review error logs for root cause',
        reason: '风险过高，需要详细分析'
      });
      suggestions.push({
        priority: 'HIGH',
        action: 'Implement additional error handling',
        reason: '需要添加错误处理逻辑'
      });
      suggestions.push({
        priority: 'HIGH',
        action: 'Consider alternative approaches',
        reason: '考虑使用替代方案'
      });
    }

    if (pattern.severity === 'HIGH' || pattern.severity === 'MEDIUM') {
      suggestions.push({
        priority: 'MEDIUM',
        action: 'Add try-catch blocks',
        reason: '需要添加异常捕获'
      });
      suggestions.push({
        priority: 'MEDIUM',
        action: 'Add logging for debugging',
        reason: '添加日志以便调试'
      });
    }

    if (pattern.factors.includes("too_long_context")) {
      suggestions.push({
        priority: 'MEDIUM',
        action: 'Reduce context size before retry',
        reason: '减少上下文大小可以避免错误'
      });
      suggestions.push({
        priority: 'MEDIUM',
        action: 'Use compression strategies',
        reason: '使用压缩策略降低负担'
      });
    }

    if (pattern.factors.includes("excessive_tokens")) {
      suggestions.push({
        priority: 'MEDIUM',
        action: 'Add token limit check',
        reason: '添加 token 限制检查'
      });
    }

    if (pattern.factors.includes("high_error_rate")) {
      suggestions.push({
        priority: 'HIGH',
        action: 'Implement rate limiting',
        reason: '需要限制请求频率'
      });
      suggestions.push({
        priority: 'HIGH',
        action: 'Add circuit breakers',
        reason: '添加熔断器防止级联失败'
      });
      suggestions.push({
        priority: 'MEDIUM',
        action: 'Log errors for analysis',
        reason: '记录错误用于分析'
      });
    }

    pattern.mitigation = suggestions;
    pattern.prevention = this.generatePreventionStrategies(pattern);

    await this.saveToDatabase(pattern.patternId, pattern);
  }

  /**
   * 生成预防策略
   * @param {Object} pattern - 模式
   * @returns {string[]}
   */
  generatePreventionStrategies(pattern) {
    const strategies = [];

    if (pattern.severity === 'CRITICAL') {
      strategies.push('Monitor for early warnings');
      strategies.push('Implement fail-safe mechanisms');
      strategies.push('Route to backup systems');
    }

    if (pattern.factors.includes("high_error_rate")) {
      strategies.push('Implement rate limiting');
      strategies.push('Add circuit breakers');
      strategies.push('Log errors for analysis');
    }

    if (pattern.factors.includes("timeout")) {
      strategies.push('Add timeout checks');
      strategies.push('Use async/await properly');
      strategies.push('Implement retry logic with exponential backoff');
    }

    if (pattern.factors.includes("network_failure")) {
      strategies.push('Implement network retry logic');
      strategies.push('Add network status checks');
      strategies.push('Use offline-first architecture if needed');
    }

    return strategies;
  }

  /**
   * 计算相似度
   * @param {string} reason1 - 错误原因1
   * @param {string} reason2 - 错误原因2
   * @returns {number} 0-1
   */
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

  /**
   * 合并描述
   * @param {FailurePattern} pattern1 - 模式1
   * @param {FailurePattern} pattern2 - 模式2
   * @returns {string}
   */
  mergeDescriptions(pattern1, pattern2) {
    // 合并描述
    return `${pattern1.description}. Also: ${pattern2.description}`;
  }

  /**
   * 保存到数据库
   * @param {string} patternId - 模式ID
   * @param {FailurePattern} pattern - 模式
   * @returns {Promise<void>}
   */
  async saveToDatabase(patternId, pattern) {
    // 实际实现中应该保存到数据库
    // await this.database.save("failure-pattern", patternId, pattern);

    console.log(`[FailurePatternDatabase] 已保存到数据库: ${patternId}`);
  }

  /**
   * 从数据库加载
   * @returns {Promise<void>}
   */
  async loadFromDatabase() {
    // 实际实现中应该从数据库加载
    // const patterns = await this.database.loadAll("failure-pattern");

    // 模拟加载
    // patterns.forEach(pattern => {
    //   this.patterns.set(pattern.patternId, pattern);
    // });

    console.log(`[FailurePatternDatabase] 已从数据库加载 ${this.patterns.size} 个模式`);
  }

  /**
   * 从数据库删除
   * @param {string} patternId - 模式ID
   * @returns {Promise<void>}
   */
  async deleteFromDatabase(patternId) {
    // 实际实现中应该从数据库删除
    // await this.database.delete("failure-pattern", patternId);

    console.log(`[FailurePatternDatabase] 已从数据库删除: ${patternId}`);
  }

  /**
   * 获取所有模式
   * @returns {Map}
   */
  getAllPatterns() {
    return this.patterns;
  }

  /**
   * 获取模式统计
   * @returns {Promise<Object>}
   */
  async getStatistics() {
    const stats = {
      total: this.patterns.size,
      bySeverity: new Map(),
      byType: new Map(),
      recent: [],
      oldest: [],
      mostCommonFactors: []
    };

    for (const pattern of this.patterns.values()) {
      // 按严重程度统计
      stats.bySeverity.set(
        pattern.severity,
        (stats.bySeverity.get(pattern.severity) || 0) + 1
      );

      // 按类型统计
      stats.byType.set(
        pattern.patternName,
        (stats.byType.get(pattern.patternName) || 0) + 1
      );

      // 最近的模式
      if (stats.recent.length < 5) {
        stats.recent.push(pattern);
      }

      // 最旧的模式
      if (stats.oldest.length < 5) {
        stats.oldest.push(pattern);
      }

      // 统计因素
      pattern.factors.forEach(factor => {
        stats.mostCommonFactors.push(factor);
      });
    }

    return stats;
  }

  /**
   * 获取高严重程度模式
   * @returns {Array<FailurePattern>}
   */
  getHighSeverityPatterns() {
    const highSeverity = [];

    for (const pattern of this.patterns.values()) {
      if (pattern.severity === 'HIGH' || pattern.severity === 'CRITICAL') {
        highSeverity.push(pattern);
      }
    }

    return highSeverity;
  }

  /**
   * 获取指定类型的模式
   * @param {string} type - 类型
   * @returns {Array<FailurePattern>}
   */
  getPatternsByType(type) {
    const patterns = [];

    for (const pattern of this.patterns.values()) {
      if (pattern.patternName === type) {
        patterns.push(pattern);
      }
    }

    return patterns;
  }
}

module.exports = FailurePatternDatabase;
