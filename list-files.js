/**
 * 列出 .openclaw 目录中的所有文件
 */

const fs = require('fs');
const path = require('path');

const workspaceDir = path.join(__dirname, '.openclaw');

console.log('📁 .openclaw 目录内容:');
console.log('='.repeat(60));

// 递归列出所有文件
function listFiles(dir, indent = 0) {
  if (!fs.existsSync(dir)) {
    console.log(`${'  '.repeat(indent)}❌ ${dir} (不存在)`);
    return;
  }

  const items = fs.readdirSync(dir, { withFileTypes: true });

  items.forEach(item => {
    const fullPath = path.join(dir, item.name);

    if (item.isDirectory()) {
      console.log(`${'  '.repeat(indent)}📁 ${item.name}/`);
      listFiles(fullPath, indent + 1);
    } else {
      const stats = fs.statSync(fullPath);
      console.log(`${'  '.repeat(indent)}📄 ${item.name} (${formatSize(stats.size)})`);
    }
  });
}

function formatSize(bytes) {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i];
}

listFiles(workspaceDir);
