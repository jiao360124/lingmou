const fs = require('fs');

console.log('Creating test file...');

// 创建测试文件
fs.writeFileSync('test-output.txt', 'Test output\n' + new Date().toISOString());

console.log('Test file created');

// 检查文件
const exists = fs.existsSync('test-output.txt');
console.log('File exists:', exists);

if (exists) {
  const content = fs.readFileSync('test-output.txt', 'utf8');
  console.log('Content:', content);
}

// 检查当前目录
const files = fs.readdirSync('.');
console.log('Current directory files:', files);
