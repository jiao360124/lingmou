const fs = require('fs');
const path = require('path');

console.log('Test Node.js Environment');
console.log('='.repeat(60));

// 测试 1: 检查当前目录
console.log('\n1. 当前目录:');
console.log('   ', process.cwd());

// 测试 2: 检查文件系统
console.log('\n2. 检查当前目录文件:');
try {
  const files = fs.readdirSync('.');
  console.log('   文件数量:', files.length);
  files.forEach(file => {
    console.log('     -', file);
  });
} catch (err) {
  console.log('   错误:', err.message);
}

// 测试 3: 检查文件系统模块
console.log('\n3. 文件系统模块:');
console.log('   fs 模块:', typeof fs);
console.log('   path 模块:', typeof path);

// 测试 4: 检查 process
console.log('\n4. Process 对象:');
console.log('   node 版本:', process.version);
console.log('   node 命令:', process.execPath);
console.log('   当前目录:', process.cwd());

// 测试 5: 检查常见路径
console.log('\n5. 检查常见 Node.js 路径:');
const testPaths = [
  'C:\\Program Files\\nodejs\\node.exe',
  'C:\\Users\\Administrator\\AppData\\Roaming\\npm\\node.exe',
];

testPaths.forEach(p => {
  const exists = fs.existsSync(p);
  console.log(`   ${exists ? '✅' : '❌'} ${p}`);
});

console.log('\n' + '='.60);
console.log('测试完成');
