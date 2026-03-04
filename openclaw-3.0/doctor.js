const fs = require('fs');
const path = require('path');

console.log('🩺 OpenClaw Doctor - 配置验证工具\n');
console.log('='.repeat(60));

let issues = 0;
let warnings = 0;

// 检查配置文件
console.log('\n📋 检查配置文件...');

const configFiles = [
  './config/index.js',
  './config/gateway.config.js',
  './config/dashboard.config.js',
  './config/report.config.js',
  './config/cron.config.js',
];

configFiles.forEach(configFile => {
  const filePath = path.join(__dirname, configFile);
  if (fs.existsSync(filePath)) {
    console.log(`✅ ${configFile}`);
  } else {
    issues++;
    console.log(`❌ ${configFile} (缺失)`);
  }
});

// 检查工具文件
console.log('\n📋 检查工具文件...');

const utils = [
  './utils/logger.js',
  './utils/error-handler.js',
  './utils/retry.js',
  './utils/cache.js',
];

utils.forEach(utilsFile => {
  const filePath = path.join(__dirname, utilsFile);
  if (fs.existsSync(filePath)) {
    console.log(`✅ ${utilsFile}`);
  } else {
    issues++;
    console.log(`❌ ${utilsFile} (缺失)`);
  }
});

// 检查模块文件
console.log('\n📋 检查模块文件...');

const modules = [
  './dashboard/server.js',
  './report-sender.js',
  './cron-scheduler/index.js',
  './services/data-fetcher.js',
];

modules.forEach(moduleFile => {
  const filePath = path.join(__dirname, moduleFile);
  if (fs.existsSync(filePath)) {
    console.log(`✅ ${moduleFile}`);
  } else {
    issues++;
    console.log(`❌ ${moduleFile} (缺失)`);
  }
});

// 检查测试文件
console.log('\n📋 检查测试文件...');

const tests = [
  './test/runner.js',
  './test/unit/config.test.js',
  './test/unit/logger.test.js',
  './test/unit/error-handler.test.js',
  './test/unit/retry.test.js',
  './test/unit/cache.test.js',
];

tests.forEach(testFile => {
  const filePath = path.join(__dirname, testFile);
  if (fs.existsSync(filePath)) {
    console.log(`✅ ${testFile}`);
  } else {
    issues++;
    console.log(`❌ ${testFile} (缺失)`);
  }
});

// 打印摘要
console.log('\n' + '='.repeat(60));
console.log('📊 检查摘要');
console.log('='.repeat(60));
console.log(`配置文件: ${configFiles.length - issues} ✅ / ${configFiles.length}`);
console.log(`工具文件: ${utils.length - issues} ✅ / ${utils.length}`);
console.log(`模块文件: ${modules.length - issues} ✅ / ${modules.length}`);
console.log(`测试文件: ${tests.length - issues} ✅ / ${tests.length}`);
console.log('='.repeat(60));

if (issues === 0) {
  console.log('\n🎉 所有检查通过！配置正常。');
} else {
  console.log(`\n❌ 发现 ${issues} 个问题，请检查。`);
}
