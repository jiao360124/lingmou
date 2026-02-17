const fs = require('fs');
const path = require('path');

console.log('🔍 完整诊断：检查 Node.js 和 OpenClaw 安装\n');
console.log('='.repeat(60));

// 常见的 Node.js 安装位置
const nodeLocations = [
  'C:\\Program Files\\nodejs\\node.exe',
  'C:\\Program Files (x86)\\nodejs\\node.exe',
  'C:\\Users\\Administrator\\AppData\\Roaming\\npm\\node.exe',
  'C:\\Users\\Administrator\\AppData\\Local\\Programs\\nodejs\\node.exe',
];

console.log('📁 检查 Node.js 安装位置:\n');

let nodeFound = false;
nodeLocations.forEach(loc => {
  if (fs.existsSync(loc)) {
    console.log(`✅ 找到 Node.js: ${loc}`);
    nodeFound = true;

    // 读取版本信息
    try {
      const { execSync } = require('child_process');
      const version = execSync(loc.replace('node.exe', 'node.exe -v'), { encoding: 'utf8' }).trim();
      console.log(`   版本: ${version}`);

      // 读取 npm 版本
      try {
        const npmVersion = execSync(loc.replace('node.exe', 'npm -v'), { encoding: 'utf8' }).trim();
        console.log(`   npm 版本: ${npmVersion}`);
      } catch (npmErr) {
        console.log(`   npm 版本: (无法读取)`);
      }
    } catch (err) {
      console.log(`   版本信息: (无法读取)`);
    }
  } else {
    console.log(`❌ 未找到: ${loc}`);
  }
});

console.log('\n' + '='.repeat(60));
console.log('📁 检查 OpenClaw 安装:\n');

// 检查全局 npm 模块
try {
  const { execSync } = require('child_process');

  // 获取 npm 全局模块路径
  const npmGlobalPath = execSync('npm config get prefix', { encoding: 'utf8' }).trim();
  console.log(`   npm 全局路径: ${npmGlobalPath}`);

  const openclawPath = path.join(npmGlobalPath, 'node_modules', 'openclaw', 'index.js');

  if (fs.existsSync(openclawPath)) {
    console.log(`✅ 找到 OpenClaw: ${openclawPath}`);

    // 读取版本信息
    try {
      const version = execSync(`node "${openclawPath}" --version`, { encoding: 'utf8' }).trim();
      console.log(`   版本: ${version}`);
    } catch (err) {
      console.log(`   版本信息: (无法读取)`);
    }
  } else {
    console.log(`❌ 未找到 OpenClaw: ${openclawPath}`);
  }
} catch (err) {
  console.log(`❌ 无法检查 OpenClaw: ${err.message}`);
}

console.log('\n' + '='.repeat(60));
console.log('📋 检查 PATH 环境变量:\n');

try {
  const { execSync } = require('child_process');
  const pathEnv = execSync('echo %PATH%', { encoding: 'utf8' }).replace(/\r\n/g, ';');

  // 检查是否包含 node.js 路径
  let hasNodePath = false;
  nodeLocations.forEach(loc => {
    const normalizedLoc = loc.replace(/\\/g, '/');
    if (pathEnv.includes(normalizedLoc) || pathEnv.includes(loc.replace('nodejs', 'nodejs\\'))) {
      console.log(`✅ PATH 中包含 Node.js 路径`);
      hasNodePath = true;
    }
  });

  if (!hasNodePath) {
    console.log(`❌ PATH 中不包含 Node.js 路径`);
  }

  // 检查是否包含 openclaw 路径
  let hasOpenclawPath = false;
  const openclawPath = path.join(npmGlobalPath, 'node_modules', 'openclaw');
  if (pathEnv.includes(openclawPath)) {
    console.log(`✅ PATH 中包含 OpenClaw 路径`);
    hasOpenclawPath = true;
  } else {
    console.log(`❌ PATH 中不包含 OpenClaw 路径`);
  }

} catch (err) {
  console.log(`❌ 无法检查 PATH: ${err.message}`);
}

console.log('\n' + '='.60);
console.log('🎯 诊断总结:\n');

if (!nodeFound) {
  console.log('❌ Node.js 未安装或未找到');
} else {
  console.log('✅ Node.js 已安装');
}

console.log('\n' + '='.repeat(60));
