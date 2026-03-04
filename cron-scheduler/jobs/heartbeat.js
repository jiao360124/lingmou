/**
 * Heartbeat Monitor Task
 * 监控系统健康状态
 */

async function execute() {
  console.log('💚 系统健康检查开始...');

  // 检查Doctor状态
  const { execSync } = require('child_process');
  try {
    const result = execSync('openclaw doctor --format json', { encoding: 'utf8' });
    const doctorData = JSON.parse(result);

    console.log('✓ Doctor检查正常');

    if (doctorData.errors && doctorData.errors.length > 0) {
      console.warn('⚠ 检测到以下问题:');
      doctorData.errors.forEach(error => console.warn(`  - ${error}`));
    }

  } catch (error) {
    console.error('✗ Doctor检查失败');
  }

  // 检查Gateway状态
  const http = require('http');
  http.get('http://localhost:18789/health', (res) => {
    let data = '';
    res.on('data', (chunk) => data += chunk);
    res.on('end', () => {
      try {
        const healthData = JSON.parse(data);
        console.log('✓ Gateway运行正常');

        // 检查Token使用
        if (healthData.tokens && healthData.tokens.current > 200000) {
          console.warn(`⚠ Token使用偏高: ${healthData.tokens.current}/${healthData.tokens.daily}`);
        }

      } catch (error) {
        console.error('✗ 无法解析Gateway响应');
      }
    });
  }).on('error', (error) => {
    console.error('✗ Gateway无响应');
  });

  return {
    success: true,
    message: '系统健康检查完成'
  };
}

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
