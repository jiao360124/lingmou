#!/usr/bin/env node

const { execSync } = require('child_process');
const fs = require('fs');

console.log('🚀 开始安装 Dashboard 依赖...\n');

try {
  // 检查当前目录
  const cwd = process.cwd();
  console.log('📁 当前目录:', cwd);

  // 检查 package.json
  const packageJsonPath = './package.json';
  if (!fs.existsSync(packageJsonPath)) {
    console.error('❌ package.json 不存在');
    process.exit(1);
  }
  console.log('✅ package.json 存在\n');

  // 安装依赖
  console.log('📦 安装 express 和 socket.io...\n');
  execSync('npm install express socket.io --legacy-peer-deps', {
    cwd: cwd,
    stdio: 'inherit',
    timeout: 60000
  });

  console.log('\n✅ 依赖安装成功！\n');

  // 验证安装
  console.log('🔍 验证安装...\n');
  const nodeModules = fs.readdirSync('./node_modules');
  console.log('已安装的模块:', nodeModules.filter(m => m.startsWith('exp') || m.startsWith('sof')));

  console.log('\n🎉 准备启动 Dashboard！');
  console.log('运行命令: node dashboard-server.js');

} catch (error) {
  console.error('\n❌ 安装失败:', error.message);
  process.exit(1);
}
