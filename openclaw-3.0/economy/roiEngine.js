/**
 * ROI Engine - 投资回报率引擎
 * 计算优化建议的投资回报率
 *
 * @module economy/roiEngine
 * @author AgentX2026
 * @version 1.0.0
 */

const fs = require('fs');
const path = require('path');

class ROIEngine {
  constructor() {
    this.metrics = this.loadMetrics();
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
      console.error('[ROIEngine] 加载metrics失败:', error.message);
    }
    return {
      dailyTokens: 0,
      costPerToken: 0.0001, // 假设成本
      recoveryRate: 0,
      errorRate: 0,
      avgResponseTime: 0,
      successRate: 0
    };
  }

  /**
   * 计算优化建议的ROI
   */
  calculateROI(suggestion, executionTime = 5) {
    const currentMetrics = this.metrics;
    const estimatedImpact = this.estimateImpact(suggestion);
    const cost = executionTime * currentMetrics.costPerToken; // 执行成本

    // 先计算所有值，最后创建对象
    const roiPercentage = ((estimatedImpact.benefit - cost) / cost) * 100;
    const roiRatio = (estimatedImpact.benefit - cost) / cost;
    const paybackPeriod = estimatedImpact.benefit > 0 ? cost / estimatedImpact.benefit : Infinity;
    const confidence = estimatedImpact.confidence;
    const priority = this.determinePriority(suggestion, { estimatedBenefit: estimatedImpact.benefit });

    const roi = {
      ...suggestion,
      estimatedBenefit: estimatedImpact.benefit,
      executionCost: cost,
      roiPercentage,
      roiRatio,
      paybackPeriod,
      confidence,
      priority
    };

    return roi;
  }

  /**
   * 估算优化建议的影响
   */
  estimateImpact(suggestion) {
    const impact = {
      benefit: 0,
      costReduction: 0,
      timeSaved: 0,
      risk: 0,
      confidence: 0
    };

    switch (suggestion.action) {
      case '增加Token预算压缩频率':
        impact.benefit = suggestion.estimatedBenefit || 20000; // 预估节省2万token
        impact.costReduction = 20; // 20%
        impact.confidence = 0.85;
        break;

      case '增加Watchdog检查频率':
        impact.benefit = 5000; // 预估节省5000 token
        impact.costReduction = 10; // 10%
        impact.confidence = 0.75;
        break;

      case '增加session compaction频率':
        impact.benefit = 15000; // 预估节省1.5万token
        impact.costReduction = 15; // 15%
        impact.confidence = 0.9;
        break;

      case '优化429重试策略':
        impact.benefit = 8000; // 预估节省8000 token
        impact.costReduction = 8; // 8%
        impact.confidence = 0.8;
        break;

      case '改进参数级优化':
        impact.benefit = 30000; // 预估节省3万token
        impact.costReduction = 30; // 30%
        impact.confidence = 0.7;
        break;

      case '运行夜间任务生成模板':
        impact.benefit = 40000; // 预估节省4万token
        impact.costReduction = 35; // 35%
        impact.confidence = 0.65;
        break;

      case '增加缓存策略':
        impact.benefit = 10000; // 预估节省1万token
        impact.costReduction = 10; // 10%
        impact.confidence = 0.8;
        break;

      case '优化数据库查询':
        impact.benefit = 5000; // 预估节省5000 token
        impact.costReduction = 5; // 5%
        impact.confidence = 0.7;
        break;

      default:
        impact.benefit = 10000;
        impact.costReduction = 10;
        impact.confidence = 0.5;
    }

    return impact;
  }

  /**
   * 确定优先级
   */
  determinePriority(suggestion, roi) {
    // ROI百分比 + 可行性
    const roiScore = roi.roiPercentage;
    const feasibilityScore = suggestion.priority === 'high' ? 0.8 : suggestion.priority === 'medium' ? 0.5 : 0.2;
    const confidenceScore = roi.confidence;

    const totalScore = roiScore * 0.5 + feasibilityScore * 0.3 + confidenceScore * 0.2;

    if (totalScore >= 60) return 'critical';
    if (totalScore >= 40) return 'high';
    if (totalScore >= 20) return 'medium';
    return 'low';
  }

  /**
   * 获取最佳ROI优化建议
   */
  getBestROI(suggestions) {
    const roiSuggestions = suggestions.map(s => this.calculateROI(s));
    roiSuggestions.sort((a, b) => b.roiRatio - a.roiRatio);
    return roiSuggestions[0];
  }

  /**
   * 获取高ROI建议列表
   */
  getHighROIList(suggestions) {
    const roiSuggestions = suggestions.map(s => this.calculateROI(s));
    return roiSuggestions.filter(s => s.roiRatio > 1) // ROI > 100%
      .sort((a, b) => b.roiRatio - a.roiRatio)
      .slice(0, 5);
  }

  /**
   * 优化建议排序
   */
  rankSuggestions(suggestions) {
    const roiSuggestions = suggestions.map(s => this.calculateROI(s));
    roiSuggestions.sort((a, b) => {
      // 先按ROI排序，再按优先级排序
      if (b.roiRatio !== a.roiRatio) {
        return b.roiRatio - a.roiRatio;
      }
      const priorityOrder = { critical: 0, high: 1, medium: 2, low: 3 };
      return priorityOrder[a.priority] - priorityOrder[b.priority];
    });

    return roiSuggestions;
  }

  /**
   * 保存ROI报告
   */
  saveROIReport(roiList, outputPath = 'reports/roi-report.json') {
    try {
      const report = {
        timestamp: new Date().toISOString(),
        currentMetrics: this.metrics,
        roiList: roiList,
        totalEstimatedSavings: roiList.reduce((sum, item) => sum + item.estimatedBenefit, 0),
        averageROI: roiList.length > 0
          ? roiList.reduce((sum, item) => sum + item.roiRatio, 0) / roiList.length
          : 0
      };

      const dir = path.dirname(outputPath);
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }

      fs.writeFileSync(outputPath, JSON.stringify(report, null, 2), 'utf8');
      console.log('[ROIEngine] 保存ROI报告:', outputPath);
      return report;
    } catch (error) {
      console.error('[ROIEngine] 保存ROI报告失败:', error.message);
      return null;
    }
  }

  /**
   * 生成ROI摘要
   */
  generateSummary(roiList) {
    if (!roiList || roiList.length === 0) {
      return '没有可用的优化建议';
    }

    // 计算总ROI
    const totalROI = roiList.reduce((sum, s) => sum + s.roiRatio, 0);

    // 分类
    const critical = roiList.filter(s => s.priority === 'critical');
    const high = roiList.filter(s => s.priority === 'high');

    let summary = `## ROI优化建议摘要\n\n`;
    summary += `**总ROI**: ${totalROI.toFixed(2)}% (${roiList.length}条建议)\n\n`;

    if (critical.length > 0) {
      summary += `### 🔴 关键优先级 (${critical.length}条)\n`;
      critical.forEach((s, i) => {
        summary += `${i + 1}. ${s.message} - ROI: ${s.roiPercentage.toFixed(2)}%\n`;
      });
      summary += `\n`;
    }

    if (high.length > 0) {
      summary += `### 🟡 高优先级 (${high.length}条)\n`;
      high.forEach((s, i) => {
        summary += `${i + 1}. ${s.message} - ROI: ${s.roiPercentage.toFixed(2)}%\n`;
      });
      summary += `\n`;
    }

    const top = roiList.slice(0, 3);
    summary += `### 🏆 最佳建议\n`;
    top.forEach((s, i) => {
      summary += `${i + 1}. ${s.message}\n`;
      summary += `   - ROI: ${s.roiPercentage.toFixed(2)}%\n`;
      summary += `   - 预估收益: ${s.estimatedBenefit.toLocaleString()} tokens\n`;
      summary += `   - 执行成本: ${s.executionCost.toFixed(2)} tokens\n`;
      summary += `   - 回收期: ${s.paybackPeriod === Infinity ? 'N/A' : s.paybackPeriod.toFixed(2) + 's'}\n\n`;
    });

    return summary;
  }

  /**
   * 预测长期ROI趋势
   */
  predictROI(timeHorizon = 30) {
    // 简化版：假设持续优化
    const trends = [];
    const currentROI = this.metrics.costReduction || 0;

    for (let i = 1; i <= timeHorizon; i++) {
      // 每天递增2%，直到达到目标30%
      const projectedROI = Math.min(currentROI + i * 2, 30);
      trends.push({
        day: i,
        projectedROI: projectedROI,
        estimatedSavings: projectedROI * 20000 / 30 // 假设基础消耗2万token
      });
    }

    return trends;
  }
}

module.exports = ROIEngine;
