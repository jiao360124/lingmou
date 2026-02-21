const { execSync } = require('child_process');
const fs = require('fs');

console.log('🚀 Dashboard 启动脚本\n');

// 检查 Node.js
try {
  const nodeVersion = execSync('node -v', { encoding: 'utf8' }).trim();
  console.log('✅ Node.js:', nodeVersion);
} catch (e) {
  console.log('❌ Node.js 未安装');
  process.exit(1);
}

// 检查文件
const files = ['dashboard-server.js', 'dashboard.html', 'package.json'];
console.log('\n📁 检查文件:');
files.forEach(file => {
  if (fs.existsSync(file)) {
    const stats = fs.statSync(file);
    console.log(`  ✅ ${file} (${formatSize(stats.size)})`);
  } else {
    console.log(`  ❌ ${file} 不存在`);
  }
});

// 检查依赖
console.log('\n📦 检查依赖:');
if (fs.existsSync('node_modules/express')) {
  console.log('  ✅ express 已安装');
} else {
  console.log('  ⚠️  express 未安装，正在安装...');
  try {
    execSync('npm install express socket.io --legacy-peer-deps --silent', { stdio: 'inherit' });
    console.log('  ✅ 依赖安装完成');
  } catch (e) {
    console.log('  ❌ 依赖安装失败:', e.message);
    process.exit(1);
  }
}

// 启动服务器
console.log('\n====================================');
console.log('🚀 启动 Dashboard 服务器...');
console.log('====================================\n');

try {
  execSync('node dashboard-server.js', { stdio: 'inherit' });
} catch (e) {
  console.log('\n❌ 服务器启动失败');
  process.exit(1);
}

function formatSize(bytes) {
  if (bytes < 1024) return bytes + ' B';
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
  return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
}
