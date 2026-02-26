/**
 * 邮箱验证功能独立测试
 * 使用 OpenClaw 安全验证
 */

const SecurityValidator = require('./security-validator');

console.log('🛡️ 邮箱验证功能测试\n');

const validator = new SecurityValidator();

// 测试邮箱验证
console.log('测试邮箱验证功能：');
const emailTests = [
  { email: 'test@example.com', expected: true, name: '有效邮箱' },
  { email: 'user.name@domain.co.uk', expected: true, name: '复杂有效邮箱' },
  { email: 'invalid-email', expected: false, name: '无效格式' },
  { email: '', expected: false, name: '空字符串' },
  { email: 'test@test', expected: false, name: '缺少顶级域名' },
  { email: 'test@.com', expected: false, name: '无效域名' },
  { email: 'test@domain.', expected: false, name: '结尾点号' },
  { email: 'test domain@domain.com', expected: false, name: '含空格' }
];

emailTests.forEach(test => {
  const result = validator.validateEmail(test.email);
  const isValid = result.isValid;
  const status = isValid === test.expected ? '✅' : '❌';
  const statusText = isValid ? '有效' : '无效';
  
  console.log(`  - "${test.email}" (${test.name}): ${statusText} ${status}`);
  if (result.errors.length > 0) {
    console.log(`    错误: ${result.errors.join(', ')}`);
  }
});

console.log('\n📊 邮箱验证测试总结：');
const passedTests = emailTests.filter(test => {
  const result = validator.validateEmail(test.email);
  return result.isValid === test.expected;
});

console.log(`通过: ${passedTests.length}/${emailTests.length} (${(passedTests.length/emailTests.length*100).toFixed(1)}%)`);

if (passedTests.length === emailTests.length) {
  console.log('✅ 所有测试通过！邮箱验证功能正常！');
} else {
  console.log('❌ 部分测试失败，需要进一步优化');
}
