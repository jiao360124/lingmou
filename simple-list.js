const fs = require('fs');
const path = require('path');

console.log('检查 .openclaw 目录...');
console.log('='.repeat(60));

const workspaceDir = path.join(__dirname, '.openclaw');
const memoryDir = path.join(workspaceDir, 'memory');
const dataDir = path.join(workspaceDir, 'data');
const logsDir = path.join(workspaceDir, 'logs');

console.log('目录检查:');
console.log('  Workspace:', fs.existsSync(workspaceDir) ? '✅' : '❌');
console.log('  Memory:', fs.existsSync(memoryDir) ? '✅' : '❌');
console.log('  Data:', fs.existsSync(dataDir) ? '✅' : '❌');
console.log('  Logs:', fs.existsSync(logsDir) ? '✅' : '❌');

if (fs.existsSync(workspaceDir)) {
  console.log('\nWorkspace 文件:');
  const files = fs.readdirSync(workspaceDir);
  files.forEach(file => {
    const filePath = path.join(workspaceDir, file);
    const stats = fs.statSync(filePath);
    const size = stats.size;
    console.log(`  ${file} - ${stats.isDirectory() ? '📁' : '📄'} (${formatSize(size)})`);
  });
}

if (fs.existsSync(memoryDir)) {
  console.log('\nMemory 文件:');
  const files = fs.readdirSync(memoryDir);
  files.forEach(file => {
    console.log(`  ${file}`);
  });
}

if (fs.existsSync(logsDir)) {
  console.log('\nLogs 文件:');
  const files = fs.readdirSync(logsDir);
  files.forEach(file => {
    const filePath = path.join(logsDir, file);
    const stats = fs.statSync(filePath);
    const size = stats.size;
    console.log(`  ${file} - ${formatSize(size)}`);
  });
}

function formatSize(bytes) {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i];
}

console.log('\n='.repeat(60));
