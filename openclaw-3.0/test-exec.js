const { execSync } = require('child_process');
const fs = require('fs');

console.log('Test Exec Module');
console.log('='.repeat(60));

// 测试 1: 尝试执行简单的命令
console.log('\n1. 测试执行简单命令:');
try {
  const result = execSync('echo "Hello"', { encoding: 'utf8', windowsHide: true });
  console.log('   成功:', result.trim());
} catch (err) {
  console.log('   失败:', err.message);
}

// 测试 2: 测试 path.join
console.log('\n2. 测试 path.join:');
const testPath = path.join(__dirname, 'test-node.js');
console.log('   路径:', testPath);
console.log('   文件存在:', fs.existsSync(testPath));

// 测试 3: 尝试查找 node.js
console.log('\n3. 尝试查找 node.exe:');
try {
  const result = execSync('where node', { encoding: 'utf8', windowsHide: true });
  console.log('   找到路径:');
  const paths = result.trim().split('\n');
  paths.forEach(p => console.log(`     - ${p}`));
} catch (err) {
  console.log('   未找到');
}

// 测试 4: 尝试查找 npm
console.log('\n4. 尝试查找 npm:');
try {
  const result = execSync('where npm', { encoding: 'utf8', windowsHide: true });
  console.log('   找到路径:');
  const paths = result.trim().split('\n');
  paths.forEach(p => console.log(`     - ${p}`));
} catch (err) {
  console.log('   未找到');
}

// 测试 5: 尝试查找 openclaw
console.log('\n5. 尝试查找 openclaw:');
try {
  const result = execSync('where openclaw', { encoding: 'utf8', windowsHide: true });
  console.log('   找到路径:');
  const paths = result.trim().split('\n');
  paths.forEach(p => console.log(`     - ${p}`));
} catch (err) {
  console.log('   未找到');
}

console.log('\n' + '='.60);
console.log('测试完成');
