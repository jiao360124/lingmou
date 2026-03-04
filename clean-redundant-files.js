/**
 * 清理 .openclaw 目录中的冗余文件
 */

const fs = require('fs');
const path = require('path');

console.log('🧹 清理 .openclaw 目录中的冗余文件\n');
console.log('='.repeat(60));

// 目录配置
const workspaceDir = path.join(__dirname, '.openclaw');
const workspaceContentDir = path.join(__dirname, '.openclaw', 'workspace');
const memoryDir = path.join(__dirname, '.openclaw', 'workspace', 'memory');
const dataDir = path.join(__dirname, '.openclaw', 'workspace', 'data');

// 需要检查的目录
const directoriesToCheck = [
  { dir: workspaceDir, description: '根目录' },
  { dir: workspaceContentDir, description: 'workspace 目录' },
  { dir: memoryDir, description: 'memory 目录' },
  { dir: dataDir, description: 'data 目录' },
];

// 需要识别的文件类型
const filePatterns = {
  logs: [
    '*.log',
    'error.log',
    'combined.log',
    'access.log',
  ],
  backups: [
    '*.backup',
    '*.bak',
    '*.old',
    '*.backup.*',
    '*.bak.*',
  ],
  temp: [
    '*.tmp',
    '*.temp',
    '.DS_Store',
    'Thumbs.db',
  ],
  node_modules: [
    'node_modules/**',
  ],
  cache: [
    '.cache/**',
  ],
  dist: [
    'dist/**',
  ],
  build: [
    'build/**',
  ],
  coverage: [
    'coverage/**',
  ],
  docs: [
    'docs/**/*.md',
  ],
  node_modules: [
    'node_modules/**',
  ],
};

// 分析目录
const analysis = {
  directories: {},
  files: {
    logs: [],
    backups: [],
    temp: [],
    others: [],
  },
  totalFiles: 0,
  totalSize: 0,
};

directoriesToCheck.forEach(({ dir, description }) => {
  if (!fs.existsSync(dir)) {
    analysis.directories[description] = { exists: false };
    return;
  }

  analysis.directories[description] = {
    exists: true,
    path: dir,
  };

  // 列出文件
  const files = getAllFiles(dir);
  analysis.directories[description].fileCount = files.length;

  files.forEach(file => {
    const relPath = path.relative(dir, file);
    const stats = fs.statSync(file);
    const size = stats.size;

    analysis.totalFiles++;
    analysis.totalSize += size;

    // 检查文件类型
    let category = 'others';
    const fileName = path.basename(file);

    if (filePatterns.logs.some(pattern => pattern.includes(fileName))) {
      category = 'logs';
      analysis.files.logs.push({ path: relPath, size });
    } else if (filePatterns.backups.some(pattern => pattern.includes(fileName))) {
      category = 'backups';
      analysis.files.backups.push({ path: relPath, size });
    } else if (filePatterns.temp.some(pattern => pattern.includes(fileName))) {
      category = 'temp';
      analysis.files.temp.push({ path: relPath, size });
    } else if (fileName === 'node_modules') {
      category = 'node_modules';
      analysis.files.others.push({ path: relPath, size, isDirectory: true });
    } else if (fileName === '.cache') {
      category = 'cache';
      analysis.files.others.push({ path: relPath, size, isDirectory: true });
    } else {
      analysis.files.others.push({ path: relPath, size });
    }
  });
});

// 打印分析结果
printAnalysis(analysis);

// 询问是否清理
if (analysis.files.logs.length > 0 || analysis.files.backups.length > 0 || analysis.files.temp.length > 0) {
  console.log('\n' + '='.repeat(60));
  console.log('📦 发现可清理的文件:');
  console.log('='.repeat(60));

  if (analysis.files.logs.length > 0) {
    console.log(`\n📄 日志文件 (${analysis.files.logs.length}):`);
    analysis.files.logs.forEach(file => {
      console.log(`  - ${file.path} (${formatSize(file.size)})`);
    });
  }

  if (analysis.files.backups.length > 0) {
    console.log(`\n📄 备份文件 (${analysis.files.backups.length}):`);
    analysis.files.backups.forEach(file => {
      console.log(`  - ${file.path} (${formatSize(file.size)})`);
    });
  }

  if (analysis.files.temp.length > 0) {
    console.log(`\n📄 临时文件 (${analysis.files.temp.length}):`);
    analysis.files.temp.forEach(file => {
      console.log(`  - ${file.path} (${formatSize(file.size)})`);
    });
  }

  const totalSize = analysis.files.logs.reduce((sum, f) => sum + f.size, 0) +
                    analysis.files.backups.reduce((sum, f) => sum + f.size, 0) +
                    analysis.files.temp.reduce((sum, f) => sum + f.size, 0);

  console.log(`\n总大小: ${formatSize(totalSize)}`);
  console.log('='.repeat(60));

  // 询问是否清理
  const readline = require('readline');
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  rl.question('\n🤔 是否清理这些文件？(y/n): ', (answer) => {
    if (answer.toLowerCase() === 'y' || answer.toLowerCase() === 'yes') {
      cleanFiles(analysis);
    } else {
      console.log('\n✅ 未进行清理。');
    }
    rl.close();
  });
} else {
  console.log('\n✅ 未发现冗余文件。');
}

// 获取目录下所有文件
function getAllFiles(dir) {
  const files = [];

  function traverse(currentDir) {
    const items = fs.readdirSync(currentDir, { withFileTypes: true });

    items.forEach(item => {
      const fullPath = path.join(currentDir, item.name);

      if (item.isDirectory()) {
        traverse(fullPath);
      } else {
        files.push(fullPath);
      }
    });
  }

  traverse(dir);
  return files;
}

// 格式化文件大小
function formatSize(bytes) {
  if (bytes === 0) return '0 B';

  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));

  return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i];
}

// 打印分析结果
function printAnalysis(analysis) {
  console.log('\n📊 目录分析:');
  console.log('='.repeat(60));

  Object.entries(analysis.directories).forEach(([name, info]) => {
    if (info.exists) {
      console.log(`✅ ${name}: ${info.path}`);
      console.log(`   文件数: ${info.fileCount}`);
    } else {
      console.log(`❌ ${name}: 目录不存在`);
    }
  });

  console.log('\n📄 文件分类:');
  console.log('='.repeat(60));

  if (analysis.files.logs.length > 0) {
    console.log(`📄 日志文件: ${analysis.files.logs.length}`);
  }
  if (analysis.files.backups.length > 0) {
    console.log(`📄 备份文件: ${analysis.files.backups.length}`);
  }
  if (analysis.files.temp.length > 0) {
    console.log(`📄 临时文件: ${analysis.files.temp.length}`);
  }
  if (analysis.files.others.length > 0) {
    console.log(`📄 其他文件: ${analysis.files.others.length}`);
  }

  console.log('\n📊 统计:');
  console.log('='.repeat(60));
  console.log(`总文件数: ${analysis.totalFiles}`);
  console.log(`总大小: ${formatSize(analysis.totalSize)}`);
  console.log('='.repeat(60));
}

// 清理文件
function cleanFiles(analysis) {
  console.log('\n🧹 开始清理...\n');

  let cleanedCount = 0;
  let cleanedSize = 0;

  // 清理日志文件
  if (analysis.files.logs.length > 0) {
    console.log('📄 清理日志文件...');
    analysis.files.logs.forEach(file => {
      const filePath = path.join(workspaceDir, file.path);
      if (fs.existsSync(filePath)) {
        const stats = fs.statSync(filePath);
        fs.unlinkSync(filePath);
        cleanedCount++;
        cleanedSize += stats.size;
        console.log(`  ✅ ${file.path} (${formatSize(stats.size)})`);
      }
    });
  }

  // 清理备份文件
  if (analysis.files.backups.length > 0) {
    console.log('\n📄 清理备份文件...');
    analysis.files.backups.forEach(file => {
      const filePath = path.join(workspaceDir, file.path);
      if (fs.existsSync(filePath)) {
        const stats = fs.statSync(filePath);
        fs.unlinkSync(filePath);
        cleanedCount++;
        cleanedSize += stats.size;
        console.log(`  ✅ ${file.path} (${formatSize(stats.size)})`);
      }
    });
  }

  // 清理临时文件
  if (analysis.files.temp.length > 0) {
    console.log('\n📄 清理临时文件...');
    analysis.files.temp.forEach(file => {
      const filePath = path.join(workspaceDir, file.path);
      if (fs.existsSync(filePath)) {
        const stats = fs.statSync(filePath);
        fs.unlinkSync(filePath);
        cleanedCount++;
        cleanedSize += stats.size;
        console.log(`  ✅ ${file.path} (${formatSize(stats.size)})`);
      }
    });
  }

  console.log('\n' + '='.repeat(60));
  console.log('✅ 清理完成！');
  console.log('='.repeat(60));
  console.log(`清理文件数: ${cleanedCount}`);
  console.log(`节省空间: ${formatSize(cleanedSize)}`);
  console.log('='.repeat(60));
}
