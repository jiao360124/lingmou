const { exec } = require('child_process');
const fs = require('fs');

console.log('🚀 开始安装 Dashboard 依赖...\n');

// 检查 Node.js
try {
  const nodeVersion = require('child_process').execSync('node -v').toString().trim();
  console.log('✅ Node.js 版本:', nodeVersion);
} catch (e) {
  console.error('❌ Node.js 未安装或未配置到 PATH');
  process.exit(1);
}

try {
  const npmVersion = require('child_process').execSync('npm -v').toString().trim();
  console.log('✅ npm 版本:', npmVersion);
} catch (e) {
  console.error('❌ npm 未安装或未配置到 PATH');
  process.exit(1);
}

console.log('\n📦 安装 express 和 socket.io...\n');

const installProcess = exec('npm install express socket.io --legacy-peer-deps', {
  cwd: process.cwd(),
  timeout: 60000
});

installProcess.stdout.on('data', (data) => {
  process.stdout.write(data);
});

installProcess.stderr.on('data', (data) => {
  process.stderr.write(data);
});

installProcess.on('close', (code) => {
  if (code === 0) {
    console.log('\n✅ 依赖安装成功！\n');
    console.log('🎉 准备启动 Dashboard！');
    console.log('\n运行命令: node dashboard-server.js\n');
  } else {
    console.log('\n❌ 安装失败，退出码:', code);
    process.exit(code);
  }
});
