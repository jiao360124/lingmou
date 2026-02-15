/**
 * Pattern Miner - 模式挖掘器
 * 聚类相似prompt并生成可复用模板
 *
 * @module value/patternMiner
 * @author AgentX2026
 * @version 1.0.0
 */

const fs = require('fs');
const path = require('path');

class PatternMiner {
  constructor(configPath = 'data/patterns.json') {
    this.configPath = configPath;
    this.patterns = this.loadPatterns();
  }

  /**
   * 加载模式库
   */
  loadPatterns() {
    try {
      const patternsPath = path.resolve(__dirname, this.configPath);
      if (fs.existsSync(patternsPath)) {
        return JSON.parse(fs.readFileSync(patternsPath, 'utf8'));
      }
    } catch (error) {
      console.error('[PatternMiner] 加载patterns失败:', error.message);
    }
    return [];
  }

  /**
   * 聚类相似prompt
   */
  clusterPrompts(prompts, similarityThreshold = 0.85) {
    const clusters = [];

    for (const prompt of prompts) {
      let clusterFound = false;

      for (const cluster of clusters) {
        const similarity = this.calculateSimilarity(prompt.text, cluster.representative.text);

        if (similarity >= similarityThreshold) {
          cluster.prompts.push(prompt);
          // 更新代表文本（合并）
          cluster.representative.text = this.mergeRepresentative(
            cluster.representative.text,
            prompt.text,
            cluster.prompts.length
          );
          cluster.count++;
          clusterFound = true;
          break;
        }
      }

      if (!clusterFound) {
        clusters.push({
          id: this.generateId(),
          type: this.inferType(prompt.text),
          representative: { ...prompt, text: prompt.text },
          prompts: [prompt],
          count: 1,
          avgTokens: prompt.tokenCount || 0
        });
      }
    }

    return clusters;
  }

  /**
   * 计算两个文本的相似度（简化版）
   */
  calculateSimilarity(text1, text2) {
    const tokens1 = this.tokenize(text1);
    const tokens2 = this.tokenize(text2);

    if (tokens1.length === 0 || tokens2.length === 0) return 0;

    // 使用Jaccard相似度
    const intersection = new Set([...tokens1].filter(x => tokens2.includes(x)));
    const union = new Set([...tokens1, ...tokens2]);

    return intersection.size / union.size;
  }

  /**
   * 合并代表文本
   */
  mergeRepresentative(representative1, text2, count) {
    const allText = `${representative1}\n\n${text2}`;
    return this.summarizeText(allText, count);
  }

  /**
   * 推断prompt类型
   */
  inferType(text) {
    const lowerText = text.toLowerCase();

    if (lowerText.includes('error') || lowerText.includes('failed') || lowerText.includes('bug')) {
      return 'error-resolution';
    } else if (lowerText.includes('help') || lowerText.includes('fix') || lowerText.includes('problem')) {
      return 'troubleshooting';
    } else if (lowerText.includes('code') || lowerText.includes('function') || lowerText.includes('method')) {
      return 'code-generation';
    } else if (lowerText.includes('explain') || lowerText.includes('how') || lowerText.includes('why')) {
      return 'explanation';
    } else if (lowerText.includes('test') || lowerText.includes('check')) {
      return 'testing';
    } else {
      return 'general';
    }
  }

  /**
   * 文本标记化（简化版）
   */
  tokenize(text) {
    return text
      .toLowerCase()
      .replace(/[^\w\s]/g, ' ')
      .split(/\s+/)
      .filter(word => word.length > 2);
  }

  /**
   * 文本总结
   */
  summarizeText(text, count) {
    // 简化版：取前100字符
    return text.substring(0, 100) + (text.length > 100 ? '...' : '');
  }

  /**
   * 生成唯一ID
   */
  generateId() {
    return 'pattern_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
  }

  /**
   * 生成模板
   */
  generateTemplate(cluster) {
    const template = {
      id: cluster.id,
      type: cluster.type,
      representative: cluster.representative,
      examples: cluster.prompts.map(p => p.text),
      count: cluster.count,
      avgTokens: Math.round(cluster.avgTokens),
      lastUpdated: new Date().toISOString(),
      template: this.createTemplateContent(cluster)
    };

    return template;
  }

  /**
   * 创建模板内容
   */
  createTemplateContent(cluster) {
    let content = `# ${cluster.type} Template\n\n`;

    content += `## 代表问题\n${cluster.representative.text}\n\n`;

    content += `## 使用场景\n${cluster.examples.slice(0, 3).map((ex, i) => `示例${i + 1}: ${ex}`).join('\n')}\n\n`;

    content += `## 常见关键词\n${[...new Set(cluster.examples.flatMap(ex =>
      ex.split(/\s+/).filter(w => w.length > 3)
    ))].join(', ')}\n\n`;

    content += `## 统计信息\n`;
    content += `- 出现次数: ${cluster.count}\n`;
    content += `- 平均Token: ${cluster.avgTokens}\n`;
    content += `- 相似度阈值: 85%\n`;

    return content;
  }

  /**
   * 从prompts数组生成模板
   */
  mineTemplates(prompts, outputPath = 'templates/') {
    if (!fs.existsSync(outputPath)) {
      fs.mkdirSync(outputPath, { recursive: true });
    }

    // 聚类
    const clusters = this.clusterPrompts(prompts);

    // 为每个聚类生成模板
    const templates = clusters.map(cluster => {
      const template = this.generateTemplate(cluster);

      // 保存到文件
      const templatePath = path.join(outputPath, `${template.type}-${template.id}.md`);
      fs.writeFileSync(templatePath, template.template, 'utf8');

      return template;
    });

    return templates;
  }

  /**
   * 从日志中提取prompts
   */
  extractPromptsFromLogs(logPath, keywords = ['user:', 'prompt:', 'message:']) {
    const prompts = [];

    try {
      if (fs.existsSync(logPath)) {
        const content = fs.readFileSync(logPath, 'utf8');
        const lines = content.split('\n');

        let currentPrompt = '';
        let inPrompt = false;

        for (const line of lines) {
          const lowerLine = line.toLowerCase();

          // 检查关键词
          const keywordMatch = keywords.find(kw => lowerLine.includes(kw));
          if (keywordMatch) {
            inPrompt = true;
            currentPrompt += line + '\n';
          } else if (inPrompt) {
            inPrompt = false;
            if (currentPrompt.trim()) {
              prompts.push({
                text: currentPrompt.trim(),
                tokenCount: currentPrompt.split(/\s+/).length,
                source: logPath
              });
              currentPrompt = '';
            }
          }
        }

        // 处理最后一个prompt
        if (currentPrompt.trim()) {
          prompts.push({
            text: currentPrompt.trim(),
            tokenCount: currentPrompt.split(/\s+/).length,
            source: logPath
          });
        }
      }
    } catch (error) {
      console.error('[PatternMiner] 从日志提取prompts失败:', error.message);
    }

    return prompts;
  }

  /**
   * 保存patterns配置
   */
  savePatterns() {
    try {
      const patternsPath = path.resolve(__dirname, this.configPath);
      fs.writeFileSync(patternsPath, JSON.stringify(this.patterns, null, 2), 'utf8');
      console.log('[PatternMiner] 保存patterns配置:', patternsPath);
    } catch (error) {
      console.error('[PatternMiner] 保存patterns失败:', error.message);
    }
  }

  /**
   * 添加新prompts
   */
  addPrompts(newPrompts) {
    const allPrompts = [
      ...this.patterns.flatMap(p => p.examples || []),
      ...newPrompts
    ];

    // 移除重复
    const uniquePrompts = Array.from(
      new Map(allPrompts.map(p => [p.text, p])).values()
    );

    return this.mineTemplates(uniquePrompts);
  }
}

module.exports = PatternMiner;
