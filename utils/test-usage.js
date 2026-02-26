/**
 * 工具函数实际应用测试
 * 使用 OpenClaw 工具库进行实际操作
 */

const utils = require('./index.js');
const fs = require('fs');
const path = require('path');

console.log('🧪 工具函数实际应用测试\n');

// 1. ID生成测试
const testIds = [
  utils.generateId('USER'),
  utils.generateId('TASK'),
  utils.generateId('SESSION')
];
console.log('✅ ID生成测试:');
console.log('  -', testIds.join(', '));

// 2. 数值处理测试
const numbers = [
  utils.calculatePercentage(25, 100),
  utils.clamp(150, 0, 100, 0),
  utils.clamp(-50, 0, 100, 0),
  utils.formatNumber(1234567.89)
];
console.log('\n✅ 数值处理测试:');
console.log('  - 25/100 的百分比:', numbers[0], '%');
console.log('  - clamp(150, 0, 100):', numbers[1]);
console.log('  - clamp(-50, 0, 100):', numbers[2]);
console.log('  - 格式化数字:', numbers[3]);

// 3. 字符串处理测试
const testStr = 'Hello World!';
const truncated = utils.truncate(testStr, 5);
const escaped = utils.escapeHtml('<script>alert("XSS")</script>');
console.log('\n✅ 字符串处理测试:');
console.log('  - 原始字符串:', testStr);
console.log('  - 截断后:', truncated);
console.log('  - 转义HTML:', escaped);

// 4. 数组处理测试
const arr = [1, 2, 3, 2, 4, 3, 5];
const unique = utils.uniqueArray(arr);
const shuffled = utils.shuffleArray([...arr]);
const chunked = utils.chunkArray(arr, 3);
console.log('\n✅ 数组处理测试:');
console.log('  - 原数组:', arr);
console.log('  - 去重后:', unique);
console.log('  - 随机打乱:', shuffled);
console.log('  - 分块结果:', chunked);

// 5. 日期处理测试
const today = new Date();
const formatted = utils.formatDate(today, 'YYYY-MM-DD');
console.log('\n✅ 日期处理测试:');
console.log('  - 今日:', formatted);

// 6. 对象处理测试
const testObj = { name: 'Test', age: 25 };
const isEmpty = utils.isEmpty(testObj);
const keysCount = utils.getObjectKeysCount(testObj);
console.log('\n✅ 对象处理测试:');
console.log('  - 测试对象:', testObj);
console.log('  - isEmpty:', isEmpty ? '是' : '否');
console.log('  - keysCount:', keysCount);

// 7. 数据处理测试
const data = { key1: 'value1', key2: 'value2' };
const queryStr = utils.objectToQueryString(data);
const parsed = utils.queryStringToObject(queryStr);
console.log('\n✅ 数据处理测试:');
console.log('  - 原始对象:', data);
console.log('  - 查询字符串:', queryStr);
console.log('  - 解析后:', parsed);

// 8. 安全处理测试
const json = '{"key": "value"}';
const parsedJson = utils.parseJsonSafe(json);
const jsonStr = utils.stringifySafe(parsedJson);
console.log('\n✅ 安全处理测试:');
console.log('  - 解析JSON:', parsedJson);
console.log('  - 序列化JSON:', jsonStr);

// 9. 实际应用 - 分析工作空间文件数量
const workspacePath = path.join(__dirname, '..');
let fileCount = 0;
try {
  const files = fs.readdirSync(workspacePath, { withFileTypes: true });
  files.forEach(file => {
    if (file.isDirectory()) {
      try {
        const subFiles = fs.readdirSync(path.join(workspacePath, file.name));
        fileCount += subFiles.length;
      } catch (e) {
        // 忽略错误
      }
    }
  });
} catch (e) {
  console.log('  - 扫描JS文件数量: 错误 -', e.message);
}
console.log('\n✅ 实际应用测试:');
console.log('  - 扫描工作空间文件数量:', fileCount);

// 10. 防抖和节流测试
let counter = 0;
const debouncedFn = utils.debounce(() => {
  counter++;
  console.log('  - 防抖函数被调用 (第' + counter + '次)');
}, 500);
debouncedFn();
debouncedFn();
setTimeout(() => debouncedFn(), 600);
debouncedFn();

// 11. 延迟函数测试
setTimeout(() => {
  console.log('  - 延迟函数正常工作');
}, 100);

console.log('\n🎉 所有工具函数测试完成！');
