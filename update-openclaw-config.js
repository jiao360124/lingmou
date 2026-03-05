/**
 * OpenClaw v4.0 - 更新 openclaw.json 配置
 *
 * 添加所有44个技能到 openclaw.json 的 skills.entries
 */

const fs = require('fs');
const path = require('path');

const openclawJsonPath = path.join(process.env.OPENCLAW_HOME || path.join(__dirname, '..'), 'openclaw.json');
const skillsPath = path.join(__dirname, 'skills');

console.log('=== 更新 openclaw.json 配置 ===\n');

// 读取现有配置
const config = JSON.parse(fs.readFileSync(openclawJsonPath, 'utf-8'));

// 获取所有技能目录
const skills = fs.readdirSync(skillsPath).filter(s =>
  fs.statSync(path.join(skillsPath, s)).isDirectory()
);

console.log(`找到 ${skills.length} 个技能目录\n`);

// 更新 skills.entries
skills.forEach(skillName => {
  if (!config.skills.entries[skillName]) {
    config.skills.entries[skillName] = {
      enabled: true
    };
    console.log(`✅ ${skillName} - 已添加`);
  } else {
    console.log(`⏭️  ${skillName} - 已存在`);
  }
});

// 写回配置
fs.writeFileSync(openclawJsonPath, JSON.stringify(config, null, 2), 'utf-8');

console.log('\n=== 配置更新完成 ===');
console.log(`总技能数: ${skills.length}`);
console.log(`配置文件: ${openclawJsonPath}`);
