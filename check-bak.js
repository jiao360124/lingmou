const fs = require('fs');
const path = require('path');

const openclawDir = path.join(__dirname, '.openclaw');
const workspaceDir = path.join(__dirname, 'workspace');

console.log('🔍 检查 .bak 备份文件\n');
console.log('='.repeat(60));

const dirsToCheck = [
  { path: openclawDir, name: '.openclaw' },
  { path: workspaceDir, name: 'workspace' },
];

dirsToCheck.forEach(({ path: dirPath, name }) => {
  console.log(`\n📁 ${name} 目录:`);

  if (!fs.existsSync(dirPath)) {
    console.log('  ❌ 目录不存在');
    return;
  }

  // 查找所有 .bak, .backup, .old 文件
  const backupFiles = [];
  const otherFiles = [];

  function findFiles(currentDir) {
    try {
      const items = fs.readdirSync(currentDir, { withFileTypes: true });

      items.forEach(item => {
        const fullPath = path.join(currentDir, item.name);

        if (item.isDirectory()) {
          findFiles(fullPath);
        } else if (item.isFile()) {
          if (item.name.includes('.bak') || item.name.includes('.backup') || item.name.includes('.old')) {
            backupFiles.push({
              name: item.name,
              path: fullPath,
              size: item.size,
              mtime: item.mtime,
            });
          } else {
            otherFiles.push({
              name: item.name,
              path: fullPath,
              size: item.size,
              mtime: item.mtime,
            });
          }
        }
      });
    } catch (error) {
      console.log(`  ⚠️  读取失败: ${error.message}`);
    }
  }

  findFiles(dirPath);

  if (backupFiles.length === 0) {
    console.log('  ✅ 未找到备份文件');
  } else {
    console.log(`  📦 备份文件 (${backupFiles.length}):`);
    backupFiles.forEach(file => {
      const daysOld = Math.floor((Date.now() - file.mtime.getTime()) / (1000 * 60 * 60 * 24));
      console.log(`    - ${file.name}`);
      console.log(`      大小: ${formatSize(file.size)}`);
      console.log(`      创建时间: ${file.mtime.toLocaleString()}`);
      console.log(`      存在天数: ${daysOld} 天`);
    });
  }

  if (otherFiles.length > 0 && otherFiles.length < 10) {
    console.log(`\n📄 其他文件 (${otherFiles.length}):`);
    otherFiles.forEach(file => {
      console.log(`  - ${file.name} (${formatSize(file.size)})`);
    });
  }
});

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
          total += item.size;
        }
      });
    } catch (error) {
      // 忽略错误
    }
  }

  traverse(dir);
  return total;
}

function formatSize(bytes) {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i];
}

console.log('\n' + '='.repeat(60));
