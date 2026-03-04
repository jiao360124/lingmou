const fs = require('fs');
const path = require('path');

console.log('🔍 查找 Node.js 安装位置\n');
console.log('='.repeat(60));

// 常见的 Node.js 安装位置
const possibleLocations = [
  'C:\\Program Files\\nodejs\\',
  'C:\\Program Files (x86)\\nodejs\\',
  'C:\\Users\\Administrator\\AppData\\Roaming\\npm\\',
  'C:\\Users\\Administrator\\AppData\\Local\\Programs\\nodejs\\',
  'C:\\Users\\Administrator\\.nvm\\',
];

console.log('📁 检查常见安装位置:\n');

let nodeFound = false;
let nodePath = null;

possibleLocations.forEach(loc => {
  const nodeExe = path.join(loc, 'node.exe');
  const cmdNodeExe = path.join(loc, 'cmd', 'node.exe');

  if (fs.existsSync(nodeExe)) {
    console.log(`✅ 找到 Node.js: ${loc}`);
    console.log(`   路径: ${nodeExe}`);
    nodeFound = true;
    nodePath = loc;

    // 读取版本
    try {
      const { execSync } = require('child_process');
      const version = execSync(`"${nodeExe}" --version`, { encoding: 'utf8', windowsHide: true }).trim();
      console.log(`   版本: ${version}`);

      // 读取 npm 版本
      try {
        const npmPath = path.join(loc, 'npm.cmd');
        const npmVersion = execSync(`"${npmPath}" --version`, { encoding: 'utf8', windowsHide: true }).trim();
        console.log(`   npm 版本: ${npmVersion}`);
      } catch (npmErr) {
        console.log(`   npm 版本: (无法读取)`);
      }
    } catch (err) {
      console.log(`   版本: (无法读取)`);
    }
  } else if (fs.existsSync(cmdNodeExe)) {
    console.log(`✅ 找到 Node.js (cmd版本): ${loc}`);
    console.log(`   路径: ${cmdNodeExe}`);
    nodeFound = true;
    nodePath = loc;
  } else {
    console.log(`❌ 未找到: ${loc}`);
  }
});

// 检查用户主目录
console.log('\n📁 检查用户主目录:\n');

const userHome = process.env.USERPROFILE;
console.log(`   用户目录: ${userHome}`);

const userNodePaths = [
  path.join(userHome, 'nodejs'),
  path.join(userHome, 'AppData', 'Roaming', 'npm'),
  path.join(userHome, 'AppData', 'Local', 'Programs', 'nodejs'),
];

userNodePaths.forEach(loc => {
  const nodeExe = path.join(loc, 'node.exe');
  const cmdNodeExe = path.join(loc, 'cmd', 'node.exe');

  if (fs.existsSync(nodeExe) || fs.existsSync(cmdNodeExe)) {
    console.log(`✅ 找到 Node.js: ${loc}`);
    nodeFound = true;
    nodePath = loc;
  } else {
    console.log(`❌ 未找到: ${loc}`);
  }
});

// 检查 npm 全局模块路径
console.log('\n📋 检查 npm 全局模块路径:\n');

try {
  const { execSync } = require('child_process');
  const npmPrefix = execSync('npm config get prefix', { encoding: 'utf8', windowsHide: true }).trim();
  console.log(`   npm prefix: ${npmPrefix}`);

  if (fs.existsSync(npmPrefix)) {
    console.log(`   路径存在: ${npmPrefix}`);

    // 检查 node_modules
    const nodeModulesPath = path.join(npmPrefix, 'node_modules', 'openclaw');
    if (fs.existsSync(nodeModulesPath)) {
      console.log(`   ✅ OpenClaw 已安装: ${nodeModulesPath}`);

      // 读取版本
      try {
        const openclawIndex = path.join(nodeModulesPath, 'index.js');
        if (fs.existsSync(openclawIndex)) {
          console.log(`   ✅ OpenClaw index.js 存在`);
        }
      } catch (err) {
        console.log(`   ❌ 无法读取 OpenClaw index.js`);
      }
    } else {
      console.log(`   ❌ OpenClaw 未安装: ${nodeModulesPath}`);
    }
  }
} catch (err) {
  console.log(`   ❌ 无法读取 npm prefix: ${err.message}`);
}

// 检查 PATH 环境变量
console.log('\n📋 检查 PATH 环境变量:\n');

try {
  const { execSync } = require('child_process');
  const pathEnv = execSync('echo %PATH%', { encoding: 'utf8' }).replace(/\r\n/g, ';');

  console.log(`   PATH 环境变量长度: ${pathEnv.length} 字符`);
  console.log(`   PATH 长度 (估计): ${Math.floor(pathEnv.length / 100)} 个路径条目`);

  // 检查是否包含 node.js 路径
  let hasNodePath = false;
  const paths = pathEnv.split(';');

  paths.forEach((p, index) => {
    if (p.toLowerCase().includes('nodejs') ||
        p.toLowerCase().includes('npm') ||
        p.toLowerCase().includes('program files\\nodejs')) {
      console.log(`\n   找到 Node.js 路径 (${index}):`);
      console.log(`   ${p}`);

      if (p.toLowerCase().includes('nodejs')) {
        nodeFound = true;
        nodePath = p;
      }
      hasNodePath = true;
    }
  });

  if (!hasNodePath) {
    console.log(`   ❌ PATH 中未找到 Node.js 路径`);
  }

} catch (err) {
  console.log(`   ❌ 无法读取 PATH: ${err.message}`);
}

// 总结
console.log('\n' + '='.repeat(60));
console.log('🎯 诊断总结:\n');

if (!nodeFound) {
  console.log('❌ 未找到 Node.js 安装');
  console.log('\n建议:\n');
  console.log('1. 手动下载安装 Node.js');
  console.log('   下载地址: https://nodejs.org/');
  console.log('2. 安装时使用默认设置');
  console.log('3. 安装完成后重启计算机');
  console.log('4. 运行: node --version 验证');
} else {
  console.log(`✅ 找到 Node.js 安装`);
  console.log(`   安装位置: ${nodePath}`);
  console.log('\n建议:\n');
  console.log('1. 验证 PATH 环境变量包含上述路径');
  console.log('2. 重启 PowerShell 窗口');
  console.log('3. 运行: node --version 验证');
}

console.log('\n' + '='.repeat(60));
