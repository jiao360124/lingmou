/**
 * Template Manager - 模板管理系统
 * 管理和检索优化模板
 *
 * @module value/templateManager
 * @author AgentX2026
 * @version 1.0.0
 */

const fs = require('fs');
const path = require('path');

class TemplateManager {
  constructor(configPath = 'templates/') {
    this.configPath = configPath;
    this.templates = this.loadTemplates();
  }

  /**
   * 加载所有模板
   */
  loadTemplates() {
    const templates = [];
    const templateTypes = [
      'error-resolution',
      'troubleshooting',
      'code-generation',
      'explanation',
      'testing',
      'general'
    ];

    for (const type of templateTypes) {
      try {
        const templatePath = path.join(__dirname, this.configPath, `${type}.md`);
        if (fs.existsSync(templatePath)) {
          const content = fs.readFileSync(templatePath, 'utf8');
          const template = this.parseTemplate(type, content);
          templates.push(template);
        }
      } catch (error) {
        console.error(`[TemplateManager] 加载${type}模板失败:`, error.message);
      }
    }

    return templates;
  }

  /**
   * 解析模板内容
   */
  parseTemplate(type, content) {
    // 简化版：提取标题和内容
    const lines = content.split('\n');
    const title = lines.find(line => line.startsWith('#')) || `#${type}`;
    const description = lines.find(line => line.startsWith('## 使用场景')) || `使用场景：${type}`;
    const usageExamples = lines
      .filter(line => line.startsWith('## '))
      .slice(0, 2)
      .map(line => line.replace('## ', ''));

    return {
      id: this.generateId(),
      type: type,
      title: title,
      description: description,
      usageExamples: usageExamples,
      content: content,
      lastUpdated: new Date().toISOString(),
      usageCount: 0
    };
  }

  /**
   * 生成唯一ID
   */
  generateId() {
    return 'template_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
  }

  /**
   * 保存模板
   */
  saveTemplate(template) {
    try {
      const templatePath = path.join(__dirname, this.configPath, `${template.type}-${template.id}.md`);

      let content = `# ${template.title}\n\n`;
      content += `${template.description}\n\n`;
      content += `## 使用场景\n${template.usageExamples.join('\n')}\n\n`;
      content += `## 模板内容\n${template.content}\n\n`;
      content += `## 统计信息\n`;
      content += `- 使用次数: ${template.usageCount || 0}\n`;
      content += `- 最后更新: ${template.lastUpdated}\n`;

      fs.writeFileSync(templatePath, content, 'utf8');

      // 更新内存中的模板
      const index = this.templates.findIndex(t => t.id === template.id);
      if (index >= 0) {
        this.templates[index] = template;
      }

      return template;
    } catch (error) {
      console.error('[TemplateManager] 保存模板失败:', error.message);
      return null;
    }
  }

  /**
   * 获取模板库
   */
  getTemplates() {
    return this.templates;
  }

  /**
   * 按类型获取模板
   */
  getTemplatesByType(type) {
    return this.templates.filter(t => t.type === type);
  }

  /**
   * 获取特定模板
   */
  getTemplateById(id) {
    return this.templates.find(t => t.id === id);
  }

  /**
   * 搜索模板
   */
  searchTemplates(query) {
    const lowerQuery = query.toLowerCase();
    return this.templates.filter(template => {
      return (
        template.type.toLowerCase().includes(lowerQuery) ||
        template.title.toLowerCase().includes(lowerQuery) ||
        template.description.toLowerCase().includes(lowerQuery) ||
        template.usageExamples.some(ex => ex.toLowerCase().includes(lowerQuery))
      );
    });
  }

  /**
   * 根据关键词推荐模板
   */
  recommendTemplates(keywords) {
    const keywordList = keywords.toLowerCase().split(/\s+/);

    const scoredTemplates = this.templates.map(template => {
      const score = this.calculateKeywordScore(template, keywordList);
      return { ...template, score };
    });

    scoredTemplates.sort((a, b) => b.score - a.score);
    return scoredTemplates.filter(t => t.score > 0).slice(0, 5);
  }

  /**
   * 计算关键词匹配分数
   */
  calculateKeywordScore(template, keywords) {
    let score = 0;

    // 模板类型匹配
    if (template.type.toLowerCase().includes(keywords[0])) {
      score += 10;
    }

    // 描述匹配
    if (template.description.toLowerCase().includes(keywords[0])) {
      score += 8;
    }

    // 示例匹配
    for (const keyword of keywords) {
      if (template.usageExamples.some(ex => ex.toLowerCase().includes(keyword))) {
        score += 5;
      }
    }

    // 标题匹配
    if (template.title.toLowerCase().includes(keywords[0])) {
      score += 6;
    }

    return score;
  }

  /**
   * 使用模板
   */
  useTemplate(id) {
    const template = this.getTemplateById(id);
    if (template) {
      template.usageCount = (template.usageCount || 0) + 1;
      template.lastUsed = new Date().toISOString();
      this.saveTemplate(template);
      return template;
    }
    return null;
  }

  /**
   * 统计模板使用情况
   */
  getTemplateStats() {
    const stats = {
      total: this.templates.length,
      byType: {},
      mostUsed: [],
      recentlyUpdated: []
    };

    // 按类型统计
    this.templates.forEach(template => {
      stats.byType[template.type] = (stats.byType[template.type] || 0) + 1;
    });

    // 最常用模板
    stats.mostUsed = [...this.templates]
      .sort((a, b) => (b.usageCount || 0) - (a.usageCount || 0))
      .slice(0, 5);

    // 最近更新
    stats.recentlyUpdated = [...this.templates]
      .sort((a, b) => new Date(b.lastUpdated) - new Date(a.lastUpdated))
      .slice(0, 5);

    return stats;
  }

  /**
   * 生成模板报告
   */
  generateTemplateReport() {
    const stats = this.getTemplateStats();

    let report = `## 模板库统计报告\n\n`;
    report += `**总模板数**: ${stats.total}\n\n`;
    report += `### 按类型统计\n`;
    Object.entries(stats.byType).forEach(([type, count]) => {
      report += `- ${type}: ${count}\n`;
    });
    report += `\n`;

    if (stats.mostUsed.length > 0) {
      report += `### 最常用模板\n`;
      stats.mostUsed.forEach((template, i) => {
        report += `${i + 1}. ${template.type} - ${template.usageCount || 0}次\n`;
      });
      report += `\n`;
    }

    if (stats.recentlyUpdated.length > 0) {
      report += `### 最近更新\n`;
      stats.recentlyUpdated.forEach((template, i) => {
        report += `${i + 1}. ${template.type} - ${template.lastUpdated}\n`;
      });
      report += `\n`;
    }

    return report;
  }

  /**
   * 批量导入模板
   */
  batchImport(templates) {
    let imported = 0;

    for (const templateData of templates) {
      const template = {
        id: this.generateId(),
        type: templateData.type,
        title: templateData.title || `${templateData.type} Template`,
        description: templateData.description || templateData.type,
        usageExamples: templateData.usageExamples || [],
        content: templateData.content || '',
        lastUpdated: new Date().toISOString(),
        usageCount: 0
      };

      if (this.saveTemplate(template)) {
        imported++;
      }
    }

    return imported;
  }
}

module.exports = TemplateManager;
