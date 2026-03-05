/**
 * OpenClaw v4.0 技能模块配置修复脚本
 *
 * 修复缺失的 description 和 name 字段
 */

const fs = require('fs');
const path = require('path');

const skillsPath = path.join(__dirname, 'skills');

// 获取所有需要修复的技能
const skillsToFix = [
  'agent-collaboration',
  'agentguard',
  'ai-toolkit',
  'api-gateway',
  'auto-skill-extractor',
  'community-integration',
  'copilot',
  'cyclic-review',
  'data-visualization',
  'dev-toolkit',
  'heartbeat-integration',
  'intelligent-upgrade',
  'performance',
  'search-toolkit',
  'self-evolution',
  'self-healing-engine',
  'system-integration',
  'test-runner'
];

const results = {
  fixed: [],
  alreadyValid: [],
  errors: []
};

console.log('=== 技能模块配置修复 ===\n');

// 为每个技能添加默认配置
skillsToFix.forEach(skillName => {
  const skillPath = path.join(skillsPath, skillName);
  const skillFile = path.join(skillPath, 'SKILL.md');

  try {
    if (fs.existsSync(skillFile)) {
      let content = fs.readFileSync(skillFile, 'utf-8');

      // 检查是否已经有 description 和 name
      const hasName = content.includes('name:');
      const hasDesc = content.includes('description:');

      if (hasName && hasDesc) {
        results.alreadyValid.push(skillName);
        console.log(`✅ ${skillName} - 已有完整配置`);
      } else {
        // 添加缺失的字段
        if (!hasName) {
          content = content.replace(
            /^(---\n)(.*)/s,
            `$1name: ${skillName}\n$2`
          );
          console.log(`📝 ${skillName} - 添加 name`);
        }

        if (!hasDesc) {
          // 获取skill目录下的其他文件作为描述参考
          const otherFiles = fs.readdirSync(skillPath)
            .filter(f => f !== 'SKILL.md' && f.endsWith('.js'));

          const fileDesc = otherFiles.length > 0
            ? `${otherFiles.join(', ')} 相关功能`
            : '多功能技能模块';

          content = content.replace(
            /^(---\n)/s,
            `$1description: "${fileDesc}"\n`
          );
          console.log(`📝 ${skillName} - 添加 description`);
        }

        // 写回文件
        fs.writeFileSync(skillFile, content);
        results.fixed.push(skillName);
        console.log(`✅ ${skillName} - 修复完成`);
      }
    } else {
      results.errors.push({ skill: skillName, error: '文件不存在' });
      console.log(`❌ ${skillName} - 文件不存在`);
    }
  } catch (e) {
    results.errors.push({ skill: skillName, error: e.message });
    console.log(`❌ ${skillName} - ${e.message}`);
  }
});

// 生成修复报告
const report = {
  timestamp: new Date().toISOString(),
  summary: {
    total: skillsToFix.length,
    fixed: results.fixed.length,
    alreadyValid: results.alreadyValid.length,
    errors: results.errors.length
  },
  fixed: results.fixed,
  alreadyValid: results.alreadyValid,
  errors: results.errors
};

fs.writeFileSync(
  path.join(__dirname, 'memory', 'skill-fix-report.json'),
  JSON.stringify(report, null, 2)
);

// 重新运行配置检查
console.log('\n=== 重新验证配置 ===\n');

let totalSkills = 0;
let validSkills = 0;

fs.readdirSync(skillsPath).forEach(skillName => {
  const skillFile = path.join(skillsPath, skillName, 'SKILL.md');
  if (fs.existsSync(skillFile)) {
    totalSkills++;
    const content = fs.readFileSync(skillFile, 'utf-8');

    if (content.includes('name:') && content.includes('description:')) {
      validSkills++;
    }
  }
});

console.log(`总技能数: ${totalSkills}`);
console.log(`有效配置: ${validSkills}`);
console.log(`通过率: ${(validSkills / totalSkills * 100).toFixed(2)}%`);

console.log('\n=== 修复完成 ===');
console.log(`修复完成: ${results.fixed.length}个`);
console.log(`已有效: ${results.alreadyValid.length}个`);
console.log(`错误: ${results.errors.length}个`);
console.log(`报告: memory/skill-fix-report.json`);
