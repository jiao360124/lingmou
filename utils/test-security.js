/**
 * 安全验证模块实际应用测试
 * 使用 OpenClaw 安全验证
 */

const SecurityValidator = require('./security-validator');

console.log('🛡️ 安全验证模块测试\n');

const validator = new SecurityValidator();

// 测试 1: 输入验证
console.log('测试 1: 通用输入验证');
const testInputs = [
  { input: 'hello', name: '普通字符串' },
  { input: '', name: '空字符串' },
  { input: '   ', name: '空格字符串' },
  { input: null, name: 'null' },
  { input: undefined, name: 'undefined' },
  { input: 123, name: '数字' },
  { input: {}, name: '对象' }
];

testInputs.forEach(item => {
  const isValid = validator.validateInput(item.input);
  console.log(`  - ${item.name}: ${isValid ? '✅ 有效' : '❌ 无效'}`);
});

// 测试 2: 邮箱验证
console.log('\n测试 2: 邮箱验证');
const emails = [
  { email: 'test@example.com', expected: true },
  { email: 'invalid-email', expected: false },
  { email: '', expected: false },
  { email: 'test@test', expected: false }
];

emails.forEach(item => {
  const isValid = validator.validateEmail(item.email);
  const status = isValid === item.expected ? '✅' : '❌';
  console.log(`  - ${item.email}: ${isValid ? '✅ 有效' : '❌ 无效'} ${status}`);
});

// 测试 3: URL验证
console.log('\n测试 3: URL验证');
const urls = [
  { url: 'https://example.com', expected: true },
  { url: 'http://example.com', expected: true },
  { url: 'ftp://files.example.com', expected: true },
  { url: 'not-a-url', expected: false },
  { url: '', expected: false }
];

urls.forEach(item => {
  const isValid = validator.validateUrl(item.url);
  const status = isValid === item.expected ? '✅' : '❌';
  console.log(`  - ${item.url}: ${isValid ? '✅ 有效' : '❌ 无效'} ${status}`);
});

// 测试 4: 整数验证
console.log('\n测试 4: 整数验证');
const numbers = [
  { value: 100, min: 0, max: 200, expected: true },
  { value: 50, min: 0, max: 200, expected: true },
  { value: -10, min: 0, max: 200, expected: false },
  { value: 250, min: 0, max: 200, expected: false },
  { value: null, min: 0, max: 200, expected: false }
];

numbers.forEach(item => {
  const result = validator.validateInteger(item.value, { min: item.min, max: item.max });
  const isValid = result.isValid;
  const status = isValid === item.expected ? '✅' : '❌';
  console.log(`  - ${item.value} [${item.min}-${item.max}]: ${isValid ? '✅ 有效' : '❌ 无效'} ${status}`);
});

// 测试 5: SQL注入检测
console.log('\n测试 5: SQL注入检测');
const sqlInputs = [
  { input: "' OR '1'='1'", expected: true },
  { input: "'; DROP TABLE users; --", expected: true },
  { input: 'SELECT * FROM users', expected: true },
  { input: 'normal input', expected: false }
];

sqlInputs.forEach(item => {
  const detected = validator.detectSqlInjection(item.input).length > 0;
  const status = detected === item.expected ? '✅' : '❌';
  console.log(`  - "${item.input}": ${detected ? '⚠️ 检测到注入' : '✅ 安全'} ${status}`);
});

// 测试 6: XSS防护
console.log('\n测试 6: XSS防护');
const xssInputs = [
  { input: '<script>alert("XSS")</script>', expected: true },
  { input: '<img src=x onerror=alert("XSS")>', expected: true },
  { input: '<div>正常内容</div>', expected: false },
  { input: 'normal text', expected: false }
];

xssInputs.forEach(item => {
  const detected = validator.detectXSS(item.input).length > 0;
  const status = detected === item.expected ? '✅' : '❌';
  console.log(`  - "${item.input}": ${detected ? '⚠️ 检测到XSS' : '✅ 安全'} ${status}`);
});

// 测试 7: JSON验证
console.log('\n测试 7: JSON验证');
const jsonInputs = [
  { json: '{"key": "value"}', expected: true },
  { json: '{"key": 123}', expected: true },
  { json: 'invalid json', expected: false },
  { json: '', expected: false }
];

jsonInputs.forEach(item => {
  const isValid = validator.validateJson(item.json);
  const status = isValid === item.expected ? '✅' : '❌';
  console.log(`  - ${item.json}: ${isValid ? '✅ 有效' : '❌ 无效'} ${status}`);
});

// 测试 8: 数据加密
console.log('\n测试 8: 数据加密');
const secret = 'my-secret-password';
const encrypted = validator.encryptString(secret);
const decrypted = validator.decryptString(encrypted);

console.log(`  - 原文: ${secret}`);
console.log(`  - 加密: ${encrypted.substring(0, 20)}...`);
console.log(`  - 解密: ${decrypted}`);
console.log(`  - 验证: ${decrypted === secret ? '✅ 成功' : '❌ 失败'}`);

// 测试 9: Hash计算
console.log('\n测试 9: Hash计算');
const text1 = 'hello world';
const text2 = 'hello world';
const hash1 = validator.hashString(text1);
const hash2 = validator.hashString(text2);

console.log(`  - "${text1}": ${hash1}`);
console.log(`  - "${text2}": ${hash2}`);
console.log(`  - 相同输入: ${hash1 === hash2 ? '✅ 相同' : '❌ 不同'}`);

console.log('\n🎉 安全验证模块测试完成！');
