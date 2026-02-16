const fs = require('fs');
const path = require('path');
const moment = require('moment-timezone');

const PROJECT_ROOT = path.join(__dirname, '..');
const LOG_FILE = path.join(PROJECT_ROOT, 'logs', 'data-cleanup.log');

// Ensure logs directory exists
const logsDir = path.dirname(LOG_FILE);
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir, { recursive: true });
}

console.log(`[${moment().tz('Asia/Shanghai').format('YYYY-MM-DD HH:mm:ss')}] 开始清理旧数据...`);

try {
  const now = moment().tz('Asia/Shanghai');
  const today = now.format('YYYY-MM-DD');
  const weekNumber = now.isoWeek();

  // Define cleanup rules
  const cleanupRules = [
    {
      name: '过期日志文件',
      pattern: 'logs/*.log',
      maxAgeDays: 30,
      patternType: 'glob'
    },
    {
      name: '旧备份文件',
      pattern: 'backups/*.zip',
      maxAgeDays: 60,
      patternType: 'glob'
    },
    {
      name: '临时文件',
      pattern: 'temp/*',
      maxAgeDays: 7,
      patternType: 'glob'
    },
    {
      name: '旧报告文件',
      pattern: 'reports/*',
      maxAgeDays: 90,
      patternType: 'glob'
    },
    {
      name: '过期的任务状态文件',
      pattern: 'data/task-status-*.json',
      maxAgeDays: 30,
      patternType: 'glob'
    }
  ];

  let cleanupSummary = {
    weekNumber: weekNumber,
    date: today,
    timestamp: now.toISOString(),
    rules: []
  };

  // Execute cleanup rules
  cleanupRules.forEach(rule => {
    const result = { name: rule.name, deleted: 0, kept: 0, total: 0 };

    if (rule.patternType === 'glob') {
      const pattern = path.join(PROJECT_ROOT, rule.pattern);
      const files = fs.existsSync(pattern) ? fs.readdirSync(path.dirname(pattern)) : [];

      files.forEach(file => {
        const filePath = path.join(PROJECT_ROOT, rule.pattern.replace('*', file));
        const stats = fs.statSync(filePath);
        const ageInDays = (now - stats.mtime) / (1000 * 60 * 60 * 24);

        if (ageInDays > rule.maxAgeDays) {
          try {
            if (fs.existsSync(filePath)) {
              fs.unlinkSync(filePath);
              result.deleted++;
            }
          } catch (error) {
            console.warn(`  无法删除 ${file}: ${error.message}`);
          }
        } else {
          result.kept++;
        }
        result.total++;
      });
    }

    cleanupSummary.rules.push(result);
  });

  // Clean up old report files (older than 2 weeks)
  const reportDir = path.join(PROJECT_ROOT, 'reports');
  if (fs.existsSync(reportDir)) {
    const reportFiles = fs.readdirSync(reportDir).filter(f => f.endsWith('.json'));
    reportFiles.forEach(file => {
      const filePath = path.join(reportDir, file);
      const stats = fs.statSync(filePath);
      const ageInDays = (now - stats.mtime) / (1000 * 60 * 60 * 24);

      if (ageInDays > 14) {
        try {
          fs.unlinkSync(filePath);
          cleanupSummary.oldReports = (cleanupSummary.oldReports || 0) + 1;
        } catch (error) {
          console.warn(`  无法删除报告文件 ${file}: ${error.message}`);
        }
      }
    });
  }

  // Clean up empty directories
  cleanupSummary.emptyDirs = [];
  const dirsToClean = [path.join(PROJECT_ROOT, 'temp'), path.join(PROJECT_ROOT, 'logs', 'archive')];

  dirsToClean.forEach(dir => {
    if (fs.existsSync(dir)) {
      const files = fs.readdirSync(dir);
      if (files.length === 0) {
        try {
          fs.rmdirSync(dir);
          cleanupSummary.emptyDirs.push(path.basename(dir));
        } catch (error) {
          console.warn(`  无法删除空目录 ${dir}: ${error.message}`);
        }
      }
    }
  });

  // Save cleanup summary
  const cleanupSummaryPath = path.join(PROJECT_ROOT, 'logs', `cleanup-summary-week${weekNumber}.json`);
  fs.writeFileSync(cleanupSummaryPath, JSON.stringify(cleanupSummary, null, 2), 'utf8');

  // Log summary
  console.log(`✓ 数据清理完成`);
  cleanupSummary.rules.forEach(rule => {
    console.log(`  - ${rule.name}: 删除 ${rule.deleted} 个文件，保留 ${rule.kept} 个`);
  });
  if (cleanupSummary.oldReports > 0) {
    console.log(`  - 过期报告: 删除 ${cleanupSummary.oldReports} 个文件`);
  }
  if (cleanupSummary.emptyDirs.length > 0) {
    console.log(`  - 空目录: 删除 ${cleanupSummary.emptyDirs.length} 个`);
  }

} catch (error) {
  console.error(`✗ 数据清理失败:`, error.message);
  throw error;
}
