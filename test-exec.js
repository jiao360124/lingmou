const { execSync } = require('child_process');

try {
  const output = execSync('echo "Test command executed"', { encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'] });
  console.log('输出:', output);
} catch (e) {
  console.log('执行失败:', e.message);
}
