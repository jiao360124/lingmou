/**
 * 将 core-modules 添加到 openclaw.json
 */

const fs = require('fs');
const path = require('path');

const openclawHome = process.env.OPENCLAW_HOME || path.join(__dirname, '..');
const configPath = path.join(openclawHome, 'openclaw.json');
const config = JSON.parse(fs.readFileSync(configPath, 'utf-8'));

console.log('=== 更新 openclaw.json ===\n');

if (!config.skills || !config.skills.entries) {
  config.skills = { entries: {} };
}

if (!config.skills.entries['core-modules']) {
  config.skills.entries['core-modules'] = {
    enabled: true
  };
  console.log('✅ 已添加 core-modules 到 skills.entries\n');
} else {
  console.log('⏭️  core-modules 已存在\n');
}

// 写回配置
fs.writeFileSync(configPath, JSON.stringify(config, null, 2), 'utf-8');
console.log('✅ 配置已保存到:', configPath);
