/**
 * 验证技能模块配置（v3）
 */

const fs = require('fs');
const path = require('path');

const skillsPath = path.join(__dirname, 'skills');
const results = { total: 0, valid: 0, invalid: 0, issues: [] };

console.log('=== 技能配置验证（v3）===\n');

fs.readdirSync(skillsPath).forEach(skillName => {
  const skillPath = path.join(skillsPath, skillName);
  const skillFile = path.join(skillPath, 'SKILL.md');

  if (fs.existsSync(skillFile)) {
    results.total++;

    try {
      let content = fs.readFileSync(skillFile, 'utf-8');
      content = content.replace(/^\uFEFF/, '');

      if (content.startsWith('---')) {
        // 修改后的正则表达式：允许可选的空行
        const frontMatterMatch = content.match(/^---\s*\n([\s\S]*?)\n---/);

        if (frontMatterMatch) {
          const yaml = frontMatterMatch[1];

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
          results.issues.push({ skill: skillName, reason: '格式错误，---分隔符格式不对' });
          console.log(`❌ ${skillName} - 格式错误，---分隔符格式不对`);
        }
      } else {
        results.invalid++;
        results.issues.push({ skill: skillName, reason: '不是HAML格式' });
        console.log(`❌ ${skillName} - 不是HAML格式`);
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
  console.log('\n=== 问题详情（前20个）===');
  results.issues.slice(0, 20).forEach(issue => {
    console.log(`${issue.skill}: ${issue.reason || issue.error}`);
  });
}
