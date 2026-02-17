const fs = require('fs');

const workspaceDir = './.openclaw';

console.log('检查 .openclaw 目录...\n');

if (!fs.existsSync(workspaceDir)) {
  console.log('❌ .openclaw 目录不存在');
  process.exit(1);
}

// 检查根目录文件
console.log('📁 根目录文件:');
const rootFiles = fs.readdirSync(workspaceDir);
if (rootFiles.length === 0) {
  console.log('  (无文件)');
} else {
  rootFiles.forEach(file => {
    const filePath = path.join(workspaceDir, file);
    const stats = fs.statSync(filePath);
    if (stats.isDirectory()) {
      console.log(`  📁 ${file}/`);
    } else {
      console.log(`  📄 ${file}`);
    }
  });
}

// 检查子目录
console.log('\n📦 子目录:');
const subDirs = ['memory', 'data', 'logs'];
subDirs.forEach(dir => {
  const dirPath = path.join(workspaceDir, dir);
  if (fs.existsSync(dirPath)) {
    const files = fs.readdirSync(dirPath);
    console.log(`  ✅ ${dir}/ (${files.length} 个文件)`);
  } else {
    console.log(`  ❌ ${dir}/ (不存在)`);
  }
});

// 统计大小
const totalSize = getDirSize(workspaceDir);
console.log(`\n📊 总大小: ${formatSize(totalSize)}`);

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

function formatSize(bytes) {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i];
}
