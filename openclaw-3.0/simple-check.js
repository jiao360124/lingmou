const fs = require('fs');
const path = require('path');

console.log('🔍 简化诊断\n');
console.log('='.repeat(60));

// 尝试多个可能的 Node.js 安装路径
const possiblePaths = [
  'C:\\Program Files\\nodejs\\node.exe',
  'C:\\Program Files (x86)\\nodejs\\node.exe',
  'C:\\Users\\Administrator\\AppData\\Roaming\\npm\\node.exe',
  'C:\\Users\\Administrator\\AppData\\Local\\Programs\\nodejs\\node.exe',
  'C:\\Program Files\\nodejs\\cmd\\node.exe',
  'C:\\Program Files (x86)\\nodejs\\cmd\\node.exe',
];

console.log('📁 检查 Node.js 路径:\n');

let nodeFound = false;
possiblePaths.forEach(p => {
  if (fs.existsSync(p)) {
    console.log(`✅ 找到: ${p}`);

    // 读取文件大小
    const stats = fs.statSync(p);
    console.log(`   大小: ${stats.size} 字节`);
    console.log(`   修改时间: ${stats.mtime.toLocaleString()}`);

    nodeFound = true;
  }
});

if (!nodeFound) {
  console.log('❌ 未找到 Node.js 安装');
  console.log('\n建议:\n');
  console.log('1. 检查是否真的安装了 Node.js');
  console.log('2. 检查安装位置是否正确');
  console.log('3. 重新安装 Node.js: https://nodejs.org/');
}

// 检查常见的全局 npm 路径
console.log('\n' + '='.repeat(60));
console.log('📁 检查全局 npm 路径:\n');

const npmGlobalPaths = [
  'C:\\Users\\Administrator\\AppData\\Roaming\\npm',
  'C:\\Program Files\\nodejs\\',
];

npmGlobalPaths.forEach(npmPath => {
  if (fs.existsSync(npmPath)) {
    console.log(`✅ 找到: ${npmPath}`);

    // 列出文件
    try {
      const files = fs.readdirSync(npmPath);
      console.log(`   文件列表:`);

      files.slice(0, 10).forEach(file => {
        const filePath = path.join(npmPath, file);
        const stats = fs.statSync(filePath);

        if (stats.isFile()) {
          console.log(`     - ${file} (${formatSize(stats.size)})`);
        } else {
          console.log(`     - ${file}/`);
        }
      });

      if (files.length > 10) {
        console.log(`     ... 还有 ${files.length - 10} 个文件`);
      }
    } catch (err) {
      console.log(`   无法读取文件列表`);
    }
  } else {
    console.log(`❌ 未找到: ${npmPath}`);
  }
});

// 检查是否有 Node.js 进程在运行
console.log('\n' + '='.repeat(60));
console.log('📋 检查运行的 Node.js 进程:\n');

try {
  const { execSync } = require('child_process');

  // 尝试查找 node 进程
  try {
    const result = execSync('tasklist | findstr node', { encoding: 'utf8', windowsHide: true });
    console.log('找到运行的 Node.js 进程:');
    console.log(result);
  } catch (err) {
    console.log('没有找到运行的 Node.js 进程');
  }
} catch (err) {
  console.log('无法检查 Node.js 进程');
}

function formatSize(bytes) {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i];
}

console.log('\n' + '='.repeat(60));
