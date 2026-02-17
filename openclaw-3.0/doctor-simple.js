const fs = require('fs');
const path = require('path');

console.log('🩺 OpenClaw Doctor - 配置验证工具\n');
console.log('='.repeat(60));

let issues = 0;
let warnings = 0;
let checks = {
  configuration: 0,
  dependencies: 0,
  files: 0,
  modules: 0,
};

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
    checks.files++;
    console.log(`✅ ${configFile}`);
  } else {
    checks.files++;
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
    checks.files++;
    console.log(`✅ ${utilsFile}`);
  } else {
    checks.files++;
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
  const filePath = path.join(__DOCTYPE__, moduleFile);
  if (fs.existsSync(filePath)) {
    checks.files++;
    console.log(`✅ ${moduleFile}`);
  } else {
    checks.files++;
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
    checks.files++;
    console.log(`✅ ${testFile}`);
  } else {
    checks.files++;
    warnings++;
    console.log(`⚠️  ${testFile} (缺失)`);
  }
});

// 检查目录
console.log('\n📋 检查目录...');

const directories = [
  'config',
  'utils',
  'dashboard',
  'report-sender.js',
  'cron-scheduler',
  'services',
  'test',
  'test/unit',
  'data',
  'logs',
];

directories.forEach(dir => {
  const dirPath = path.join(__dirname, dir);
  if (fs.existsSync(dirPath)) {
    checks.files++;
    console.log(`✅ ${dir}/`);
  } else {
    checks.files++;
    issues++;
    console.log(`❌ ${dir}/ (缺失)`);
  }
});

// 打印摘要
console.log('\n' + '='.repeat(60));
console.log('📊 检查摘要');
console.log('='.repeat(60));
console.log(`配置文件: ${configFiles.length - issues} ✅ / ${configFiles.length} ${issues > 0 ? '❌' : ''}`);
console.log(`工具文件: ${utils.length - issues} ✅ / ${utils.length} ${issues > utils.length ? '❌' : ''}`);
console.log(`模块文件: ${modules.length - issues} ✅ / ${modules.length} ${issues > modules.length ? '❌' : ''}`);
console.log(`测试文件: ${tests.length - warnings} ✅ / ${tests.length} ${warnings > 0 ? '⚠️' : ''}`);
console.log('='.repeat(60));

if (issues === 0 && warnings === 0) {
  console.log('\n🎉 所有检查通过！配置正常。');
} else if (issues === 0) {
  console.log(`\n✅ 检查通过！发现 ${warnings} 个警告。`);
} else {
  console.log(`\n❌ 发现 ${issues} 个问题，${warnings} 个警告，请检查。`);
}
