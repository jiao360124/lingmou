/**
 * Gap Analyzer - 优化Gap分析器
 * 分析当前指标与目标的差距，生成优化建议
 *
 * @module objective/gapAnalyzer
 * @author AgentX2026
 * @version 1.0.0
 */

const fs = require('fs');
const path = require('path');

class GapAnalyzer {
  constructor(configPath = 'data/goals.json') {
    this.configPath = configPath;
    this.goals = this.loadGoals();
  }

  /**
   * 加载目标配置
   */
  loadGoals() {
    try {
      const goalsPath = path.resolve(__dirname, this.configPath);
      if (fs.existsSync(goalsPath)) {
        return JSON.parse(fs.readFileSync(goalsPath, 'utf8'));
      }
    } catch (error) {
      console.error('[GapAnalyzer] 加载goals配置失败:', error.message);
    }
    return {
      long_term: '降低30%API成本',
      monthly: '自动恢复率>90%',
      daily: '优化429退避策略'
    };
  }

  /**
   * 加载指标数据
   */
  loadMetrics(metricsPath = 'data/metrics.json') {
    try {
      const metricsPathResolved = path.resolve(__dirname, metricsPath);
      if (fs.existsSync(metricsPathResolved)) {
        return JSON.parse(fs.readFileSync(metricsPathResolved, 'utf8'));
      }
    } catch (error) {
      console.error('[GapAnalyzer] 加载metrics失败:', error.message);
    }
    return {
      dailyTokens: 0,
      recoveryRate: 0,
      avgContextSize: 0,
      templatesGenerated: 0,
      costReduction: 0,
      errorRate: 0,
      successRate: 0
    };
  }

  /**
   * 分析Gap - 返回优化建议
   */
  analyzeGap(metricsPath) {
    const metrics = this.loadMetrics(metricsPath);
    const gap = {
      costGap: this.calculateCostGap(metrics),
      recoveryGap: this.calculateRecoveryGap(metrics),
      contextGap: this.calculateContextGap(metrics),
      errorGap: this.calculateErrorGap(metrics),
      successGap: this.calculateSuccessGap(metrics),
      suggestions: []
    };

    // 生成优化建议
    gap.suggestions = this.generateSuggestions(gap, metrics);

    return gap;
  }

  /**
   * 计算成本Gap
   */
  calculateCostGap(metrics) {
    // 目标：降低30% API成本
    const targetReduction = 30;
    const currentReduction = metrics.costReduction || 0;
    return currentReduction - targetReduction; // 正数表示差距
  }

  /**
   * 计算恢复率Gap
   */
  calculateRecoveryGap(metrics) {
    // 目标：自动恢复率 >90%
    const targetRate = 90;
    const currentRate = metrics.recoveryRate || 0;
    return targetRate - currentRate; // 正数表示差距
  }

  /**
   * 计算上下文Gap
   */
  calculateContextGap(metrics) {
    // 目标：平均上下文 <5000 tokens
    const targetSize = 5000;
    const currentSize = metrics.avgContextSize || 0;
    return currentSize - targetSize; // 正数表示差距
  }

  /**
   * 计算错误率Gap
   */
  calculateErrorGap(metrics) {
    // 目标：错误率 <10%
    const targetRate = 10;
    const currentRate = metrics.errorRate || 0;
    return currentRate - targetRate; // 正数表示差距
  }

  /**
   * 计算成功率Gap
   */
  calculateSuccessGap(metrics) {
    // 目标：成功率 >90%
    const targetRate = 90;
    const currentRate = metrics.successRate || 0;
    return targetRate - currentRate; // 正数表示差距
  }

  /**
   * 生成优化建议
   */
  generateSuggestions(gap, metrics) {
    const suggestions = [];

    // 成本Gap建议
    if (gap.costGap > 0) {
      suggestions.push({
        priority: 'high',
        category: 'cost',
        message: `成本未达标：当前${metrics.costReduction || 0}%，目标30%，差距${gap.costGap}%`,
        action: '增加Token预算压缩频率',
        impact: '预计可减少20-30% token使用'
      });
    }

    // 恢复率Gap建议
    if (gap.recoveryGap > 0) {
      suggestions.push({
        priority: 'high',
        category: 'recovery',
        message: `自动恢复率未达标：当前${metrics.recoveryRate || 0}%，目标90%，差距${gap.recoveryGap}%`,
        action: '增加Watchdog检查频率',
        impact: '预计可提高恢复率至95%以上'
      });
    }

    // 上下文Gap建议
    if (gap.contextGap > 0) {
      suggestions.push({
        priority: 'medium',
        category: 'context',
        message: `上下文过大：当前${metrics.avgContextSize || 0}，目标5000，差距${gap.contextGap}`,
        action: '增加session compaction频率',
        impact: '预计可减少15-25% token使用'
      });
    }

    // 错误率Gap建议
    if (gap.errorGap > 0) {
      suggestions.push({
        priority: 'high',
        category: 'error',
        message: `错误率过高：当前${metrics.errorRate || 0}%，目标10%，差距${gap.errorGap}%`,
        action: '优化429重试策略',
        impact: '预计可降低错误率至5%以下'
      });
    }

    // 成功率Gap建议
    if (gap.successGap > 0) {
      suggestions.push({
        priority: 'medium',
        category: 'success',
        message: `成功率未达标：当前${metrics.successRate || 0}%，目标90%，差距${gap.successGap}%`,
        action: '改进参数级优化',
        impact: '预计可提高成功率至95%'
      });
    }

    // 模板建议
    if (metrics.templatesGenerated < 5) {
      suggestions.push({
        priority: 'low',
        category: 'templates',
        message: `模板库不足：当前${metrics.templatesGenerated}个，目标5个`,
        action: '运行夜间任务生成模板',
        impact: '预计可减少30%重复请求'
      });
    }

    // 按优先级排序
    suggestions.sort((a, b) => {
      const priorityOrder = { high: 0, medium: 1, low: 2 };
      return priorityOrder[a.priority] - priorityOrder[b.priority];
    });

    return suggestions;
  }

  /**
   * 获取最紧迫的优化建议（只返回1条）
   */
  getTopPrioritySuggestion(metricsPath) {
    const gap = this.analyzeGap(metricsPath);
    return gap.suggestions.length > 0 ? gap.suggestions[0] : null;
  }

  /**
   * 保存优化建议
   */
  saveSuggestion(suggestion) {
    try {
      const suggestionsPath = path.resolve(__dirname, 'data/suggestions.json');
      let suggestions = [];

      if (fs.existsSync(suggestionsPath)) {
        suggestions = JSON.parse(fs.readFileSync(suggestionsPath, 'utf8'));
      }

      suggestions.push({
        ...suggestion,
        timestamp: new Date().toISOString(),
        source: 'gap-analyzer'
      });

      // 只保留最近10条
      if (suggestions.length > 10) {
        suggestions = suggestions.slice(-10);
      }

      fs.writeFileSync(suggestionsPath, JSON.stringify(suggestions, null, 2), 'utf8');
      console.log('[GapAnalyzer] 保存优化建议:', suggestion.message);
    } catch (error) {
      console.error('[GapAnalyzer] 保存建议失败:', error.message);
    }
  }

  /**
   * 获取历史优化建议
   */
  getHistory() {
    try {
      const suggestionsPath = path.resolve(__dirname, 'data/suggestions.json');
      if (fs.existsSync(suggestionsPath)) {
        return JSON.parse(fs.readFileSync(suggestionsPath, 'utf8'));
      }
    } catch (error) {
      console.error('[GapAnalyzer] 读取历史建议失败:', error.message);
    }
    return [];
  }
}

module.exports = GapAnalyzer;
