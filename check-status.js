const fs = require('fs');
const path = require('path');

console.log('=== Dashboard 状态检查 ===\n');

// 检查目录
const cwd = process.cwd();
console.log('📁 当前目录:', cwd);

// 检查关键文件
const files = [
  'dashboard-server.js',
  'dashboard.html',
  'package.json',
  'index.html'
];

console.log('\n📁 检查关键文件:');
files.forEach(file => {
  const fullPath = path.join(cwd, file);
  if (fs.existsSync(fullPath)) {
    const stats = fs.statSync(fullPath);
    console.log(`  ✅ ${file} (${formatSize(stats.size)})`);
  } else {
    console.log(`  ❌ ${file} (不存在)`);
  }
});

// 检查 node_modules
const nodeModulesPath = path.join(cwd, 'node_modules');
if (fs.existsSync(nodeModulesPath)) {
  console.log('\n📦 node_modules 目录存在');
  const modules = fs.readdirSync(nodeModulesPath).filter(m => m.startsWith('exp') || m.startsWith('sof'));
  console.log('  已安装的模块:', modules.length);
} else {
  console.log('\n📦 node_modules 目录不存在');
  console.log('  需要运行: npm install express socket.io --legacy-peer-deps');
}

// 检查端口
console.log('\n🌐 检查端口:');
checkPort(3000);
checkPort(18789);

function checkPort(port) {
  const { exec } = require('child_process');
  exec(`netstat -ano | findstr :${port}`, (error, stdout) => {
    if (stdout && !stdout.includes('active listening')) {
      console.log(`  ❌ 端口 ${port}: 未监听`);
    } else if (stdout && stdout.includes('active listening')) {
      console.log(`  ✅ 端口 ${port}: 监听中`);
    } else {
      console.log(`  ⚪ 端口 ${port}: 未使用`);
    }
  });
}

function formatSize(bytes) {
  if (bytes < 1024) return bytes + ' B';
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
  return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
}
