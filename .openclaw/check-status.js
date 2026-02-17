const fs = require('fs');

console.log('🧹 安全清理状态检查\n');
console.log('='.repeat(60));

const workspaceDir = __dirname;

// 检查各类文件
const checks = {
  logs: false,
  temp: false,
  old: false,
};

// 检查日志文件
try {
  const logFiles = [];
  const walk = (dir) => {
    const items = fs.readdirSync(dir, { withFileTypes: true });
    items.forEach(item => {
      const fullPath = path.join(dir, item.name);
      if (item.isDirectory()) {
        walk(fullPath);
      } else if (item.isFile()) {
        if (item.name.endsWith('.log')) {
          logFiles.push(item.name);
        }
      }
    });
  };

  walk(workspaceDir);
  checks.logs = logFiles.length === 0;
  console.log(`✅ 日志文件 (*.log): ${checks.logs ? '已清理' : `未清理 (${logFiles.length} 个)`}`);
} catch (error) {
  console.log(`❌ 检查日志文件失败: ${error.message}`);
}

// 检查临时文件
try {
  const tempFiles = [];
  const walk = (dir) => {
    const items = fs.readdirSync(dir, { withFileTypes: true });
    items.forEach(item => {
      const fullPath = path.join(dir, item.name);
      if (item.isDirectory()) {
        walk(fullPath);
      } else if (item.isFile()) {
        if (item.name.endsWith('.tmp') || item.name.endsWith('.temp')) {
          tempFiles.push(item.name);
        }
      }
    });
  };

  walk(workspaceDir);
  checks.temp = tempFiles.length === 0;
  console.log(`✅ 临时文件 (*.tmp, *.temp): ${checks.temp ? '已清理' : `未清理 (${tempFiles.length} 个)`}`);
} catch (error) {
  console.log(`❌ 检查临时文件失败: ${error.message}`);
}

// 检查备份文件
try {
  const backupFiles = [];
  const walk = (dir) => {
    const items = fs.readdirSync(dir, { withFileTypes: true });
    items.forEach(item => {
      const fullPath = path.join(dir, item.name);
      if (item.isDirectory()) {
        walk(fullPath);
      } else if (item.isFile()) {
        if (item.name.endsWith('.backup') || item.name.endsWith('.bak') || item.name.endsWith('.old')) {
          backupFiles.push(item.name);
        }
      }
    });
  };

  walk(workspaceDir);
  checks.old = backupFiles.length === 0;
  console.log(`✅ 备份文件 (*.backup, *.bak, *.old): ${checks.old ? '已清理' : `未清理 (${backupFiles.length} 个)`}`);
} catch (error) {
  console.log(`❌ 检查备份文件失败: ${error.message}`);
}

// 总结
console.log('\n' + '='.repeat(60));
if (checks.logs && checks.temp && checks.old) {
  console.log('🎉 所有安全清理已完成！');
  console.log('='.repeat(60));
  process.exit(0);
} else {
  console.log('⚠️  部分文件未清理完成');
  console.log('='.repeat(60));
  process.exit(1);
}
