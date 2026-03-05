/**
 * OpenClaw v4.0 技能模块HAML格式修复脚本
 *
 * 将所有技能从markdown格式转换为HAML格式
 */

const fs = require('fs');
const path = require('path');

const skillsPath = path.join(__dirname, 'skills');

// 获取所有技能目录
const skills = fs.readdirSync(skillsPath).filter(s =>
  fs.statSync(path.join(skillsPath, s)).isDirectory()
);

const results = {
  converted: [],
  errors: []
};

console.log('=== 技能模块HAML格式转换 ===\n');
console.log(`待转换技能数: ${skills.length}\n`);

skills.forEach(skillName => {
  const skillPath = path.join(skillsPath, skillName);
  const skillFile = path.join(skillPath, 'SKILL.md');

  try {
    if (fs.existsSync(skillFile)) {
      const content = fs.readFileSync(skillFile, 'utf-8');

      // 检查是否已经是HAML格式
      if (content.startsWith('---')) {
        console.log(`⏭️  ${skillName} - 已是HAML格式`);
        return;
      }

      // 生成HAML front matter
      // 尝试从文件内容提取名称（使用第一个标题）
      const titleMatch = content.match(/^#\s+(.+)$/m);
      const skillTitle = titleMatch ? titleMatch[1].trim() : skillName;

      const frontMatter = `---
name: ${skillName}
description: "${skillTitle}"
---

`;

      // 添加到内容开头
      const newContent = frontMatter + content;

      // 写回文件
      fs.writeFileSync(skillFile, newContent, 'utf-8');

      results.converted.push(skillName);
      console.log(`✅ ${skillName} - 转换成功`);
    } else {
      results.errors.push({ skill: skillName, error: '文件不存在' });
      console.log(`❌ ${skillName} - 文件不存在`);
    }
  } catch (e) {
    results.errors.push({ skill: skillName, error: e.message });
    console.log(`❌ ${skillName} - ${e.message}`);
  }
});

// 生成转换报告
const report = {
  timestamp: new Date().toISOString(),
  summary: {
    total: skills.length,
    converted: results.converted.length,
    errors: results.errors.length
  },
  converted: results.converted,
  errors: results.errors
};

fs.writeFileSync(
  path.join(__dirname, 'memory', 'skill-conversion-report.json'),
  JSON.stringify(report, null, 2)
);

console.log('\n=== 转换完成 ===');
console.log(`转换成功: ${results.converted.length}个`);
console.log(`错误: ${results.errors.length}个`);
console.log(`报告: memory/skill-conversion-report.json`);
