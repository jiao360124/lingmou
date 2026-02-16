/**
 * Doctor - 配置验证工具
 * 检查所有配置和依赖是否有效
 */

const fs = require('fs');
const path = require('path');
const { getConfig, validateConfig } = require('./config');
const logger = require('./utils/logger');

console.log('🩺 OpenClaw Doctor - 配置验证工具\n');
console.log('='.repeat(60));

let issues = [];
let warnings = [];
let checks = {
  configuration: 0,
  dependencies: 0,
  files: 0,
  modules: 0,
};

// ==================== 配置检查 ====================

function checkConfiguration() {
  console.log('\n📋 检查配置...');

  try {
    const config = getConfig();
    validateConfig();

    checks.configuration++;

    console.log('✅ 配置加载成功');

    // 检查配置项
    const requiredKeys = ['env', 'ports', 'log', 'cache', 'retry', 'errorHandler'];
    requiredKeys.forEach(key => {
      if (!config[key]) {
        issues.push(`缺少配置项: ${key}`);
      }
    });

    // 检查端口
    if (config.ports.gateway < 1 || config.ports.gateway > 65535) {
      issues.push(`无效的 Gateway 端口: ${config.ports.gateway}`);
    }

    if (config.ports.dashboard < 1 || config.ports.dashboard > 65535) {
      issues.push(`无效的 Dashboard 端口: ${config.ports.dashboard}`);
    }

    console.log('✅ 配置验证通过');

  } catch (error) {
    checks.configuration++;
    issues.push(`配置错误: ${error.message}`);
    console.log(`❌ 配置验证失败: ${error.message}`);
  }
}

// ==================== 依赖检查 ====================

function checkDependencies() {
  console.log('\n📦 检查依赖...');

  const dependencies = [
    { name: 'express', required: true },
    { name: 'node-fetch', required: true },
    { name: 'node-cache', required: true },
    { name: 'node-cron', required: true },
  ];

  dependencies.forEach(dep => {
    try {
      require.resolve(dep.name);
      checks.dependencies++;
      console.log(`✅ ${dep.name}`);
    } catch (error) {
      checks.dependencies++;
      if (dep.required) {
        issues.push(`缺少必需依赖: ${dep.name}`);
        console.log(`❌ ${dep.name} (必需)`);
      } else {
        warnings.push(`可选依赖缺失: ${dep.name}`);
        console.log(`⚠️  ${dep.name} (可选)`);
      }
    }
  });
}

// ==================== 文件检查 ====================

function checkFiles() {
  console.log('\n📁 检查文件...');

  const files = [
    { path: './config/index.js', required: true },
    { path: './utils/logger.js', required: true },
    { path: './utils/error-handler.js', required: true },
    { path: './utils/retry.js', required: true },
    { path: './utils/cache.js', required: true },
    { path: './dashboard/server.js', required: false },
    { path: './report-sender.js', required: false },
    { path: './cron-scheduler/index.js', required: false },
    { path: './services/data-fetcher.js', required: false },
  ];

  files.forEach(file => {
    const filePath = path.join(__dirname, file.path);
    if (fs.existsSync(filePath)) {
      checks.files++;
      console.log(`✅ ${file.path}`);
    } else {
      checks.files++;
      if (file.required) {
        issues.push(`缺少必需文件: ${file.path}`);
        console.log(`❌ ${file.path} (必需)`);
      } else {
        warnings.push(`文件缺失: ${file.path}`);
        console.log(`⚠️  ${file.path} (可选)`);
      }
    }
  });
}

// ==================== 模块检查 ====================

function checkModules() {
  console.log('\n⚙️  检查模块...');

  const modules = [
    { name: 'Logger', path: './utils/logger.js' },
    { name: 'ErrorHandler', path: './utils/error-handler.js' },
    { name: 'RetryManager', path: './utils/retry.js' },
    { name: 'CacheManager', path: './utils/cache.js' },
    { name: 'DataFetcher', path: './services/data-fetcher.js' },
  ];

  modules.forEach(module => {
    try {
      const modulePath = path.join(__dirname, module.path);
      require(modulePath);

      checks.modules++;
      console.log(`✅ ${module.name}`);
    } catch (error) {
      checks.modules++;
      issues.push(`模块加载失败: ${module.name} - ${error.message}`);
      console.log(`❌ ${module.name}`);
    }
  });
}

// ==================== 日志目录检查 ====================

function checkLogDirectory() {
  console.log('\n📝 检查日志目录...');

  const config = getConfig();
  const logDir = path.join(__dirname, '../../logs');

  if (!fs.existsSync(logDir)) {
    try {
      fs.mkdirSync(logDir, { recursive: true });
      console.log('✅ 日志目录已创建');
    } catch (error) {
      issues.push(`无法创建日志目录: ${error.message}`);
      console.log(`❌ 日志目录创建失败`);
    }
  } else {
    console.log('✅ 日志目录存在');
  }
}

// ==================== 数据目录检查 ====================

function checkDataDirectory() {
  console.log('\n💾 检查数据目录...');

  const dataDir = path.join(__dirname, '../../data');

  if (!fs.existsSync(dataDir)) {
    try {
      fs.mkdirSync(dataDir, { recursive: true });
      console.log('✅ 数据目录已创建');
    } catch (error) {
      issues.push(`无法创建数据目录: ${error.message}`);
      console.log(`❌ 数据目录创建失败`);
    }
  } else {
    console.log('✅ 数据目录存在');
  }
}

// ==================== 配置文件检查 ====================

function checkConfigFiles() {
  console.log('\n⚙️  检查配置文件...');

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
      issues.push(`配置文件缺失: ${configFile}`);
      console.log(`❌ ${configFile}`);
    }
  });
}

// ==================== 测试检查 ====================

function checkTests() {
  console.log('\n🧪 检查测试...');

  const testFiles = [
    './test/runner.js',
    './test/unit/config.test.js',
    './test/unit/logger.test.js',
    './test/unit/error-handler.test.js',
    './test/unit/retry.test.js',
    './test/unit/cache.test.js',
  ];

  testFiles.forEach(testFile => {
    const filePath = path.join(__dirname, testFile);
    if (fs.existsSync(filePath)) {
      checks.files++;
      console.log(`✅ ${testFile}`);
    } else {
      checks.files++;
      warnings.push(`测试文件缺失: ${testFile}`);
      console.log(`⚠️  ${testFile}`);
    }
  });
}

// ==================== 运行所有检查 ====================

function runDoctor() {
  console.log('开始检查...\n');

  try {
    checkConfiguration();
    checkDependencies();
    checkFiles();
    checkModules();
    checkLogDirectory();
    checkDataDirectory();
    checkConfigFiles();
    checkTests();

    // 打印摘要
    printSummary();

    // 打印问题
    printIssues();

  } catch (error) {
    console.error('\n❌ Doctor 检查过程中出错:', error);
    process.exit(1);
  }
}

// ==================== 打印摘要 ====================

function printSummary() {
  console.log('\n' + '='.repeat(60));
  console.log('📊 检查摘要');
  console.log('='.repeat(60));
  console.log(`配置检查: ${checks.configuration} ✅`);
  console.log(`依赖检查: ${checks.dependencies} ✅`);
  console.log(`文件检查: ${checks.files} ✅`);
  console.log(`模块检查: ${checks.modules} ✅`);
  console.log('='.repeat(60));
}

// ==================== 打印问题 ====================

function printIssues() {
  if (issues.length > 0) {
    console.log('\n❌ 发现的问题:');
    console.log('-'.repeat(60));
    issues.forEach((issue, index) => {
      console.log(`${index + 1}. ${issue}`);
    });
    console.log('-'.repeat(60));
  }

  if (warnings.length > 0) {
    console.log('\n⚠️  警告:');
    console.log('-'.repeat(60));
    warnings.forEach((warning, index) => {
      console.log(`${index + 1}. ${warning}`);
    });
    console.log('-'.repeat(60));
  }

  if (issues.length === 0 && warnings.length === 0) {
    console.log('\n🎉 所有检查通过！配置正常。');
  }
}

// ==================== 运行 ====================

runDoctor();
