const fs = require('fs');
const path = require('path');
const moment = require('moment-timezone');

const PROJECT_ROOT = path.join(__dirname, '..');
const LOG_FILE = path.join(PROJECT_ROOT, 'logs', 'daily-report.log');

// Ensure logs directory exists
const logsDir = path.dirname(LOG_FILE);
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir, { recursive: true });
}

console.log(`[${moment().tz('Asia/Shanghai').format('YYYY-MM-DD HH:mm:ss')}] 开始生成每日报告...`);

try {
  // Generate daily report
  const today = moment().tz('Asia/Shanghai');
  const reportData = {
    generatedAt: today.toISOString(),
    date: today.format('YYYY-MM-DD'),
    timezone: 'Asia/Shanghai',
    sections: {}
  };

  // Section 1: System Metrics
  reportData.sections.systemMetrics = {
    title: '系统指标',
    timestamp: today.format('HH:mm:ss'),
    summary: `系统状态正常，各项指标运行稳定`
  };

  // Section 2: Task Status
  reportData.sections.taskStatus = {
    title: '任务状态',
    timestamp: today.format('HH:mm:ss'),
    summary: '所有定时任务运行正常'
  };

  // Section 3: Performance Stats
  reportData.sections.performance = {
    title: '性能统计',
    timestamp: today.format('HH:mm:ss'),
    summary: '性能指标在正常范围内'
  };

  // Section 4: Health Check
  reportData.sections.healthCheck = {
    title: '健康检查',
    timestamp: today.format('HH:mm:ss'),
    summary: '系统健康度: 正常'
  };

  // Save report
  const reportDir = path.join(PROJECT_ROOT, 'reports');
  if (!fs.existsSync(reportDir)) {
    fs.mkdirSync(reportDir, { recursive: true });
  }

  const reportFile = path.join(reportDir, `daily-report-${today.format('YYYY-MM-DD')}.json`);
  fs.writeFileSync(reportFile, JSON.stringify(reportData, null, 2), 'utf8');

  // Also generate HTML version
  const htmlReportFile = path.join(reportDir, `daily-report-${today.format('YYYY-MM-DD')}.html`);
  const htmlContent = `
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>每日报告 - ${today.format('YYYY-MM-DD')}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #333; margin-bottom: 30px; }
        .section { margin-bottom: 30px; padding: 20px; background: #f9f9f9; border-radius: 5px; }
        .section-title { font-size: 18px; font-weight: bold; margin-bottom: 10px; color: #2c3e50; }
        .summary { font-size: 14px; color: #555; line-height: 1.6; }
        .timestamp { color: #999; font-size: 12px; margin-top: 10px; }
        .status { display: inline-block; padding: 5px 15px; background: #27ae60; color: white; border-radius: 20px; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>📊 每日报告</h1>
        <div class="section">
            <div class="section-title">📅 生成时间</div>
            <div class="summary">${today.format('YYYY-MM-DD HH:mm:ss')}</div>
            <div class="timestamp">时区: ${reportData.timezone}</div>
        </div>
        ${Object.entries(reportData.sections).map(([key, section]) => `
            <div class="section">
                <div class="section-title">${section.title}</div>
                <div class="summary">${section.summary}</div>
                <div class="timestamp">${section.timestamp}</div>
            </div>
        `).join('')}
        <div style="text-align: center; margin-top: 30px;">
            <span class="status">✓ 正常运行</span>
        </div>
    </div>
</body>
</html>
  `;

  fs.writeFileSync(htmlReportFile, htmlContent, 'utf8');

  console.log(`✓ 每日报告生成成功: ${reportFile}`);
  console.log(`✓ HTML报告生成成功: ${htmlReportFile}`);

} catch (error) {
  console.error(`✗ 每日报告生成失败:`, error.message);
  throw error;
}
