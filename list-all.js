const fs = require('fs');
const path = require('path');

const openclawDir = 'C:\\Users\\Administrator\\.openclaw';

console.log('📂 C:\\Users\\Administrator\\.openclaw 目录内容');
console.log('='.repeat(60));

// 检查目录是否存在
if (!fs.existsSync(openclawDir)) {
  console.log('❌ 目录不存在');
  process.exit(1);
}

// 递归列出所有文件
function listFiles(dir, indent = 0) {
  try {
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
        else if (item.name.endsWith('.json')) icon = '📋';
        else if (item.name.endsWith('package.json')) icon = '📦';
        else if (item.name.endsWith('.lock')) icon = '🔒';
        else if (item.name.endsWith('.js')) icon = '📜';

        console.log(`${'  '.repeat(indent)}${icon} ${item.name} (${formatSize(size)})`);
      }
    });
  } catch (error) {
    console.log(`${'  '.repeat(indent)}❌ 无法读取: ${error.message}`);
  }
}

// 获取目录大小
function getDirSize(dir) {
  let total = 0;

  function traverse(currentDir) {
    try {
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
    } catch (error) {
      // 忽略错误
    }
  }

  traverse(dir);
  return total;
}

// 打印统计信息
function printStats() {
  console.log('\n' + '='.repeat(60));
  console.log('📊 统计信息');
  console.log('='.repeat(60));

  const totalSize = getDirSize(openclawDir);
  console.log(`总大小: ${formatSize(totalSize)}`);

  // 统计文件数量
  let fileCount = 0;
  let dirCount = 0;

  function countItems(dir) {
    try {
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
    } catch (error) {
      // 忽略错误
    }
  }

  countItems(openclawDir);
  console.log(`总文件数: ${fileCount}`);
  console.log(`总目录数: ${dirCount}`);
  console.log('='.repeat(60));
}

// 主函数
try {
  listFiles(openclawDir);
  printStats();
} catch (error) {
  console.error('❌ 错误:', error.message);
  process.exit(1);
}

function formatSize(bytes) {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i];
}
