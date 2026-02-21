const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('🔍 OpenClaw Gateway 诊断\n');
console.log('=' .repeat(60));

// 1. 检查Node.js
console.log('\n1️⃣ 检查 Node.js 环境:');
try {
  const nodeVersion = execSync('node -v', { encoding: 'utf8' }).trim();
  console.log('   ✅ Node.js 版本:', nodeVersion);

  const npmVersion = execSync('npm -v', { encoding: 'utf8' }).trim();
  console.log('   ✅ npm 版本:', npmVersion);
} catch (e) {
  console.log('   ❌ Node.js 未安装');
  process.exit(1);
}

// 2. 检查OpenClaw命令
console.log('\n2️⃣ 检查 OpenClaw 命令:');
try {
  const openclawVersion = execSync('openclaw --version', { encoding: 'utf8', timeout: 5000 }).trim();
  console.log('   ✅ OpenClaw 版本:', openclawVersion);
} catch (e) {
  console.log('   ❌ OpenClaw 命令不可用');
  console.log('   路径:', process.env.PATH);
}

// 3. 检查Gateway配置
console.log('\n3️⃣ 检查 Gateway 配置:');
const configPath = path.join(process.cwd(), '.openclaw', 'config', 'gateway.json');
if (fs.existsSync(configPath)) {
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  console.log('   ✅ Gateway 配置存在');
  console.log('   配置:', JSON.stringify(config, null, 2));
} else {
  console.log('   ⚠️  Gateway 配置文件不存在');
}

// 4. 检查端口占用
console.log('\n4️⃣ 检查端口占用:');
try {
  const netstatOutput = execSync('netstat -ano | findstr :18789', { encoding: 'utf8' }).trim();
  if (netstatOutput) {
    console.log('   ❌ 端口 18789 已被占用:');
    console.log('   ', netstatOutput);
  } else {
    console.log('   ✅ 端口 18789 可用');
  }
} catch (e) {
  console.log('   ✅ 端口 18789 可用');
}

// 5. 检查进程
console.log('\n5️⃣ 检查相关进程:');
try {
  const tasklistOutput = execSync('tasklist | findstr node', { encoding: 'utf8' }).trim();
  if (tasklistOutput) {
    console.log('   已运行 Node.js 进程:');
    console.log('   ', tasklistOutput);
  } else {
    console.log('   ✅ 无 Node.js 进程运行');
  }
} catch (e) {
  console.log('   ✅ 无 Node.js 进程运行');
}

// 6. 检查Dashboard文件
console.log('\n6️⃣ 检查 Dashboard 文件:');
const dashboardFiles = ['dashboard-server.js', 'dashboard.html', 'package.json'];
let allFilesExist = true;
dashboardFiles.forEach(file => {
  if (fs.existsSync(file)) {
    const stats = fs.statSync(file);
    console.log(`   ✅ ${file} (${formatSize(stats.size)})`);
  } else {
    console.log(`   ❌ ${file} 不存在`);
    allFilesExist = false;
  }
});

// 7. 检查Dashboard依赖
console.log('\n7️⃣ 检查 Dashboard 依赖:');
if (fs.existsSync('node_modules/express')) {
  console.log('   ✅ express 已安装');
} else {
  console.log('   ❌ express 未安装');
}
if (fs.existsSync('node_modules/socket.io')) {
  console.log('   ✅ socket.io 已安装');
} else {
  console.log('   ❌ socket.io 未安装');
}

console.log('\n' + '='.repeat(60));
console.log('\n📋 总结:');
if (allFilesExist && !fs.existsSync('node_modules/express')) {
  console.log('⚠️  Dashboard 文件完整，但依赖未安装');
  console.log('   需要运行: npm install express socket.io --legacy-peer-deps');
}
console.log('\n💡 建议操作:');
console.log('   1. 运行此诊断脚本查看完整信息');
console.log('   2. 手动启动 Gateway: openclaw gateway start');
console.log('   3. 如果失败，检查日志: openclaw gateway logs');

function formatSize(bytes) {
  if (bytes < 1024) return bytes + ' B';
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
  return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
}
