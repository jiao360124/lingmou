/**
 * 验证技能模块配置
 */

const fs = require('fs');
const path = require('path');

const skillsPath = path.join(__dirname, 'skills');
const results = { total: 0, valid: 0, invalid: 0, issues: [] };

console.log('=== 技能配置验证 ===\n');

fs.readdirSync(skillsPath).forEach(skillName => {
  const skillPath = path.join(skillsPath, skillName);
  const skillFile = path.join(skillPath, 'SKILL.md');

  if (fs.existsSync(skillFile)) {
    results.total++;

    try {
      const content = fs.readFileSync(skillFile, 'utf-8');

      // 检查YAML格式（HAML）- 描述以---开头
      if (content.startsWith('---')) {
        // 提取YAML front matter
        const frontMatterMatch = content.match(/^---\n([\s\S]*?)\n---/);
        if (frontMatterMatch) {
          const yaml = frontMatterMatch[1];

          // 检查是否包含name和description
          const hasName = yaml.includes('name:');
          const hasDesc = yaml.includes('description:');

          if (hasName && hasDesc) {
            results.valid++;
            console.log(`✅ ${skillName}`);
          } else {
            results.invalid++;
            results.issues.push({
              skill: skillName,
              reason: hasName ? '缺少description' : '缺少name'
            });
            console.log(`❌ ${skillName} - ${results.issues[results.issues.length - 1].reason}`);
          }
        } else {
          results.invalid++;
          results.issues.push({ skill: skillName, reason: '格式错误，缺少---' });
          console.log(`❌ ${skillName} - 格式错误，缺少---`);
        }
      } else {
        // 检查markdown格式（非HAML）
        const hasTitle = content.includes('#');
        const hasName = content.includes('name:');
        const hasDesc = content.includes('description:');

        if (hasName && hasDesc) {
          results.valid++;
          console.log(`✅ ${skillName} (markdown格式)`);
        } else {
          results.invalid++;
          results.issues.push({
            skill: skillName,
            reason: hasName ? '缺少description' : '缺少name'
          });
          console.log(`❌ ${skillName} - ${results.issues[results.issues.length - 1].reason}`);
        }
      }
    } catch (e) {
      results.invalid++;
      results.issues.push({ skill: skillName, error: e.message });
      console.log(`❌ ${skillName} - ${e.message}`);
    }
  }
});

console.log('\n=== 验证结果 ===');
console.log(`总技能数: ${results.total}`);
console.log(`有效配置: ${results.valid}`);
console.log(`无效配置: ${results.invalid}`);
console.log(`通过率: ${(results.valid / results.total * 100).toFixed(2)}%`);

if (results.issues.length > 0) {
  console.log('\n=== 问题详情 ===');
  results.issues.forEach(issue => {
    console.log(`${issue.skill}: ${issue.reason || issue.error}`);
  });
}
