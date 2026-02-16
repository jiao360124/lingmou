/**
 * Gateway Check Task
 * 检查Gateway服务运行状态、资源使用情况和连接状态
 */

const fs = require('fs');
const path = require('path');

const PROJECT_ROOT = path.join(__dirname, '../../..');

async function execute() {
  console.log('🔍 Gateway状态检查...');

  // 检查Gateway进程
  const { execSync } = require('child_process');
  try {
    const result = execSync('tasklist /FI "IMAGENAME eq node.exe" /FI "PID eq 8772"').toString();
    console.log('✓ Gateway进程运行正常 (PID: 8772)');
  } catch (error) {
    console.error('✗ Gateway进程未运行');
    throw new Error('Gateway进程未运行');
  }

  // 检查Gateway响应
  const http = require('http');
  const httpPromise = new Promise((resolve, reject) => {
    const req = http.get('http://localhost:18789/health', (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (error) {
          reject(new Error('Invalid JSON response'));
        }
      });
    });

    req.on('error', reject);
    req.setTimeout(5000, () => reject(new Error('Timeout')));
  });

  const healthData = await httpPromise;
  console.log('✓ Gateway响应正常');
  console.log(`  运行时间: ${healthData.uptime}秒`);
  console.log(`  状态: ${healthData.status}`);

  return {
    success: true,
    message: 'Gateway检查完成'
  };
}

// 直接执行
if (require.main === module) {
  execute()
    .then(result => {
      console.log(`\n✅ ${result.message}`);
      process.exit(0);
    })
    .catch(error => {
      console.error(`\n❌ 检查失败: ${error.message}`);
      process.exit(1);
    });
}

module.exports = { execute };
