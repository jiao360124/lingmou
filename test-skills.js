/**
 * OpenClaw v4.0 技能模块测试脚本
 */

const fs = require('fs');
const path = require('path');

const results = {
  timestamp: new Date().toISOString(),
  skills: []
};

const skillsPath = path.join(__dirname, 'skills');

// 读取所有技能目录
fs.readdirSync(skillsPath).forEach(skillName => {
  const skillPath = path.join(skillsPath, skillName);
  const skillFile = path.join(skillPath, 'SKILL.md');

  if (fs.existsSync(skillFile)) {
    try {
      const skillContent = fs.readFileSync(skillFile, 'utf-8');

      // 检查是否配置正确
      if (skillContent.includes('description:') && skillContent.includes('name:')) {
        // 提取名称和描述
        const nameMatch = skillContent.match(/name:\s*(.+?)(?:\n|$)/);
        const descMatch = skillContent.match(/description:\s*"(.+?)"/);

        results.skills.push({
          skill: skillName,
          name: nameMatch ? nameMatch[1].trim() : skillName,
          description: descMatch ? descMatch[1] : 'No description',
          status: 'CONFIGURED',
          passed: true
        });
      } else {
        results.skills.push({
          skill: skillName,
          name: skillName,
          description: 'Missing required fields',
          status: 'INVALID',
          passed: false
        });
      }
    } catch (e) {
      results.skills.push({
        skill: skillName,
        name: skillName,
        description: e.message,
        status: 'ERROR',
        passed: false
      });
    }
  }
});

// 保存测试结果
fs.writeFileSync(
  path.join(__dirname, 'memory', 'skill-test-results.json'),
  JSON.stringify(results, null, 2)
);

// 生成摘要报告
const summary = {
  ...results,
  summary: {
    totalSkills: results.skills.length,
    passedSkills: results.skills.filter(s => s.passed).length,
    failedSkills: results.skills.filter(s => !s.passed).length,
    overall: results.skills.length > 0
      ? (results.skills.filter(s => s.passed).length / results.skills.length) * 100
      : 0
  }
};

fs.writeFileSync(
  path.join(__dirname, 'memory', 'skill-test-summary.json'),
  JSON.stringify(summary, null, 2)
);

console.log('=== 技能模块配置测试完成 ===');
console.log(`总技能数: ${summary.summary.totalSkills}`);
console.log(`配置成功: ${summary.summary.passedSkills}`);
console.log(`配置失败: ${summary.summary.failedSkills}`);
console.log(`总体通过率: ${summary.summary.overall.toFixed(2)}%`);

// 显示技能列表
console.log('\n=== 技能列表 ===');
results.skills.forEach(skill => {
  const statusEmoji = skill.passed ? '✅' : '❌';
  console.log(`${statusEmoji} ${skill.skill} - ${skill.name}`);
  if (!skill.passed) {
    console.log(`   描述: ${skill.description}`);
  }
});
