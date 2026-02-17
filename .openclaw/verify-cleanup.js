const fs = require('fs');
const path = require('path');

const workspaceDir = path.join(__dirname);

console.log('🧹 安全清理验证\n');
console.log('='.repeat(60));

// 检查清理前的文件
console.log('📋 检查剩余文件...');

const filesToCheck = [
  { pattern: '*.log', name: '日志文件', shouldExist: false },
  { pattern: '*.tmp', name: '临时文件', shouldExist: false },
  { pattern: '*.temp', name: '临时文件', shouldExist: false },
  { pattern: '.DS_Store', name: 'Mac缓存', shouldExist: false },
  { pattern: 'Thumbs.db', name: 'Windows缓存', shouldExist: false },
  { pattern: '*.backup*', name: '备份文件', shouldExist: false },
  { pattern: '*.bak*', name: '备份文件', shouldExist: false },
  { pattern: '*.old', name: '旧文件', shouldExist: false },
];

let foundCount = 0;
let notFoundCount = 0;

filesToCheck.forEach(({ pattern, name, shouldExist }) => {
  try {
    const files = fs.readdirSync(workspaceDir, { withFileTypes: true, recursive: true });
    const matchingFiles = files.filter(f => f.isFile() && f.name.includes(pattern));

    if (matchingFiles.length > 0) {
      console.log(`❌ ${name} (${pattern}): 找到 ${matchingFiles.length} 个文件`);
      foundCount += matchingFiles.length;
    } else {
      console.log(`✅ ${name} (${pattern}): 未找到`);
      notFoundCount++;
    }
  } catch (error) {
    console.log(`⚠️  ${name}: 检查失败`);
  }
});

// 检查目录大小
const totalSize = getDirSize(workspaceDir);
console.log('\n📊 目录大小:', formatSize(totalSize));
console.log('='.repeat(60));

if (foundCount === 0) {
  console.log('🎉 所有冗余文件已清理！');
} else {
  console.log(`⚠️  发现 ${foundCount} 个文件未被清理`);
}

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
