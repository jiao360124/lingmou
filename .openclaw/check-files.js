const fs = require('fs');
const path = require('path');

console.log('🔍 检查备份文件\n');
console.log('='.repeat(60));

// 检查 .openclaw/workspace 目录
const workspaceDir = path.join(__dirname, '../workspace/.openclaw');

console.log('📁 .openclaw/workspace 目录:');
console.log('  路径:', workspaceDir);
console.log('  存在:', fs.existsSync(workspaceDir));

if (fs.existsSync(workspaceDir)) {
  const files = fs.readdirSync(workspaceDir);
  console.log('  文件数:', files.length);

  // 查找备份文件
  const backupFiles = files.filter(f =>
    f.includes('.bak') ||
    f.includes('.backup') ||
    f.includes('.old')
  );

  if (backupFiles.length > 0) {
    console.log('\n📦 找到备份文件:');
    backupFiles.forEach(file => {
      const filePath = path.join(workspaceDir, file);
      const stats = fs.statSync(filePath);

      console.log(`\n📄 ${file}:`);
      console.log(`  大小: ${formatSize(stats.size)}`);
      console.log(`  修改时间: ${stats.mtime.toLocaleString()}`);

      // 尝试读取文件内容（只读前100个字符）
      try {
        const content = fs.readFileSync(filePath, 'utf8');
        const preview = content.substring(0, 100).replace(/\n/g, ' ');
        console.log(`  内容预览: ${preview}...`);
      } catch (error) {
        console.log(`  内容: (无法读取)`);
      }
    });
  } else {
    console.log('  ✅ 未找到备份文件');
  }
}

// 检查 workspace 根目录
const workspaceRootDir = path.join(__dirname, '../workspace');

console.log('\n\n📁 workspace 根目录:');
console.log('  路径:', workspaceRootDir);
console.log('  存在:', fs.existsSync(workspaceRootDir));

if (fs.existsSync(workspaceRootDir)) {
  const files = fs.readdirSync(workspaceRootDir);
  const backupFiles = files.filter(f =>
    f.includes('.bak') ||
    f.includes('.backup') ||
    f.includes('.old')
  );

  if (backupFiles.length > 0) {
    console.log('\n📦 找到备份文件:');
    backupFiles.forEach(file => {
      const filePath = path.join(workspaceRootDir, file);
      const stats = fs.statSync(filePath);

      console.log(`\n📄 ${file}:`);
      console.log(`  大小: ${formatSize(stats.size)}`);
      console.log(`  修改时间: ${stats.mtime.toLocaleString()}`);
    });
  }
}

function formatSize(bytes) {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i];
}

console.log('\n' + '='.repeat(60));
