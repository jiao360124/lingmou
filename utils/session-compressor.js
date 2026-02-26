/**
 * OpenClaw Session Compressor - 会话压缩模块
 * V3.2 核心功能：智能上下文压缩和摘要生成
 */

class SessionCompressor {
  constructor(options = {}) {
    this.options = {
      compressionLevel: options.compressionLevel || 2, // 1=轻度, 2=中度, 3=重度
      maxMessages: options.maxMessages || 50,
      preserveKeyMessages: options.preserveKeyMessages || true,
      preserveErrors: options.preserveErrors || true,
      maxContextTokens: options.maxContextTokens || 40000,
      ...options
    };

    this.compressionStrategies = {
      1: this.lightStrategy.bind(this),
      2: this.mediumStrategy.bind(this),
      3: this.heavyStrategy.bind(this)
    };
  }

  /**
   * 轻度压缩策略
   * 保留关键对话节点、错误信息和最新/最早消息
   */
  lightStrategy(messages) {
    const preserved = [];
    const compressed = [];

    messages.forEach((msg, index) => {
      // 保留第一条和最后一条
      if (index === 0 || index === messages.length - 1) {
        preserved.push(msg);
        return;
      }

      // 保留错误信息
      if (this.options.preserveErrors && msg.hasError) {
        preserved.push(msg);
        return;
      }

      // 保留重要决策点
      if (msg.hasDecision) {
        preserved.push(msg);
        return;
      }

      // 其他消息合并到压缩列表
      compressed.push(msg);
    });

    return {
      preserved,
      compressed,
      total: preserved.length + compressed.length
    };
  }

  /**
   * 中度压缩策略
   * 保留完整对话链、关键决策点、最新消息
   */
  mediumStrategy(messages) {
    const preserved = [];
    const compressed = [];

    messages.forEach((msg, index) => {
      // 保留最后N条消息
      if (index >= messages.length - this.options.maxMessages) {
        preserved.push(msg);
        return;
      }

      // 保留重要决策点
      if (msg.isKey && msg.hasDecision) {
        preserved.push(msg);
        return;
      }

      // 合并相似内容
      if (compressed.length > 0) {
        const last = compressed[compressed.length - 1];
        if (this.isSimilar(msg, last)) {
          last.combinedContent += '\n' + msg.content;
          last.combinedCount++;
          return;
        }
      }

      compressed.push(msg);
    });

    return {
      preserved,
      compressed,
      total: preserved.length + compressed.length
    };
  }

  /**
   * 重度压缩策略
   * 生成摘要，只保留主题和关键决策
   */
  heavyStrategy(messages) {
    const summary = this.generateSummary(messages);
    const keyMessages = [];

    // 保留关键决策和错误
    messages.forEach(msg => {
      if (msg.hasDecision || (this.options.preserveErrors && msg.hasError)) {
        keyMessages.push(msg);
      }
    });

    return {
      preserved: keyMessages,
      compressed: [summary],
      total: keyMessages.length + 1
    };
  }

  /**
   * 检查两条消息是否相似
   */
  isSimilar(msg1, msg2) {
    if (!msg1 || !msg2) return false;

    // 相同角色的连续消息
    if (msg1.role === msg2.role) {
      const timeDiff = Math.abs(msg1.timestamp - msg2.timestamp);
      if (timeDiff < 60000) { // 1分钟内
        return true;
      }
    }

    // 主题相似（简单实现）
    const similarKeywords = ['你好', '好的', '明白', '请', '需要', '问题'];
    return similarKeywords.some(keyword =>
      msg1.content.includes(keyword) && msg2.content.includes(keyword)
    );
  }

  /**
   * 生成会话摘要
   */
  generateSummary(messages) {
    const userMessages = messages.filter(m => m.role === 'user').slice(-10);
    const decisions = messages.filter(m => m.hasDecision);

    const summary = {
      role: 'system',
      content: `会话摘要：本会话涉及 ${messages.length} 条消息\n`,
      summaryType: 'auto-generated'
    };

    if (decisions.length > 0) {
      summary.content += `\n关键决策：\n`;
      decisions.forEach(dec => {
        summary.content += `- ${dec.content.substring(0, 100)}...\n`;
      });
    }

    if (userMessages.length > 0) {
      summary.content += `\n用户查询：\n`;
      userMessages.forEach(u => {
        summary.content += `- ${u.content}\n`;
      });
    }

    summary.content += `\n总消息数: ${messages.length}`;
    summary.content += `\n关键决策数: ${decisions.length}`;
    summary.content += `\n生成时间: ${new Date().toISOString()}`;

    return summary;
  }

  /**
   * 压缩会话
   */
  compressSession(messages) {
    if (messages.length <= this.options.maxMessages) {
      return {
        original: messages,
        compressed: messages,
        preserved: [],
        compressed: [],
        total: messages.length,
        preservedCount: messages.length,
        compressedCount: messages.length,
        reductionRatio: 0,
        strategy: 'none'
      };
    }

    const strategy = this.compressionStrategies[this.options.compressionLevel];
    const result = strategy(messages);

    // 计算压缩比
    const originalTokens = result.preserved.length * 1000 + result.compressed.length * 1000;
    const compressedTokens = result.total * 1000;
    const reductionRatio = originalTokens > 0
      ? ((originalTokens - compressedTokens) / originalTokens * 100).toFixed(2)
      : 0;

    return {
      original: messages,
      compressed: [...result.preserved, ...result.compressed],
      preservedCount: result.preserved.length,
      compressedCount: result.compressed.length,
      total: result.total,
      reductionRatio: parseFloat(reductionRatio),
      strategy: this.options.compressionLevel
    };
  }

  /**
   * 获取压缩统计
   */
  getCompressionStats(messages) {
    const originalCount = messages.length;
    const originalTokens = originalCount * 1000;

    const result = this.compressSession(messages);

    return {
      originalCount,
      originalTokens,
      compressedCount: result.compressedCount,
      compressedTokens: result.total * 1000,
      reductionRatio: parseFloat(result.reductionRatio),
      strategy: result.strategy,
      preservedCount: result.preservedCount,
      compressedSegments: result.compressedCount
    };
  }
}

module.exports = SessionCompressor;
