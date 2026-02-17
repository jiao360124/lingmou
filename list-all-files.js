const fs = require('fs');
const path = require('path');

console.log('📂 .openclaw workspace 文件列表');
console.log('='.repeat(60));

const workspaceDir = path.join(__dirname, '.openclaw');

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

      // 递归列出子目录
      try {
        const subItems = fs.readdirSync(fullPath);
        if (subItems.length > 0) {
          listFiles(fullPath, indent + 1);
        }
      } catch (error) {
        // 忽略错误
      }
    } else {
      const stats = fs.statSync(fullPath);
      const size = stats.size;

      // 判断文件类型
      let icon = '📄';
      if (item.name.endsWith('.log')) icon = '📄';
      else if (item.name.endsWith('.backup') || item.name.endsWith('.bak') || item.name.endsWith('.old')) icon = '📦';
      else if (item.name.endsWith('.tmp') || item.name.endsWith('.temp')) icon = '⏳';
      else if (item.name.endsWith('.md')) icon = '📝';
      else if (item.name.endsWith('.js')) icon = '📜';
      else if (item.name.endsWith('.json')) icon = '📋';
      else if (item.name.endsWith('.bat')) icon = '🪟';
      else if (item.name.endsWith('.sh')) icon = '🐧';

      console.log(`${'  '.repeat(indent)}${icon} ${item.name} (${formatSize(size)})`);
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

// 获取目录大小
function getDirSize(dir) {
  let total = 0;

  function traverse(currentDir) {
    const items = fs.readdirSync(currentDir, { withFileTypes: true });

    items.forEach(item => {
      const fullPath = path.join(currentDir, item.name);

      if (item.isDirectory()) {
        traverse(fullPath);
      } else {
        const stats = fs.statSync(fullPath);
        total += stats.size;
      }
    });
  }

  traverse(dir);
  return total;
}

// 打印统计信息
function printStats() {
  console.log('\n' + '='.repeat(60));
  console.log('📊 统计信息');
  console.log('='.repeat(60));

  const totalSize = getDirSize(workspaceDir);
  console.log(`总大小: ${formatSize(totalSize)}`);

  // 统计文件数量
  let fileCount = 0;
  let dirCount = 0;

  function countItems(dir) {
    const items = fs.readdirSync(dir, { withFileTypes: true });

    items.forEach(item => {
      const fullPath = path.join(dir, item.name);

      if (item.isDirectory()) {
        dirCount++;
        countItems(fullPath);
      } else {
        fileCount++;
      }
    });
  }

  countItems(workspaceDir);
  console.log(`总文件数: ${fileCount}`);
  console.log(`总目录数: ${dirCount}`);
  console.log('='.repeat(60));
}

// 主函数
try {
  listFiles(workspaceDir);
  printStats();
} catch (error) {
  console.error('❌ 错误:', error.message);
  process.exit(1);
}
