/**
 * 单元测试运行器
 * 运行所有单元测试
 */

const { spawn } = require('child_process');
const path = require('path');

const testFiles = [
  './test/unit/config.test.js',
  './test/unit/logger.test.js',
  './test/unit/error-handler.test.js',
  './test/unit/retry.test.js',
  './test/unit/cache.test.js',
];

let totalTests = 0;
let passedTests = 0;
let failedTests = 0;

console.log('🧪 Running Unit Tests...\n');
console.log('='.repeat(60));
console.log('Test Files:');
testFiles.forEach((file, index) => {
  console.log(`${index + 1}. ${path.basename(file)}`);
});
console.log('='.repeat(60));

// Run each test file
testFiles.forEach((testFile) => {
  console.log(`\nRunning: ${testFile}`);
  console.log('-'.repeat(60));

  const testProcess = spawn('node', [testFile], {
    cwd: path.join(__dirname, '..'),
    stdio: 'inherit',
  });

  testProcess.on('close', (code) => {
    console.log(`\n✅ ${path.basename(testFile)} completed with code ${code}`);

    if (code === 0) {
      passedTests++;
    } else {
      failedTests++;
    }

    totalTests++;

    // Print summary after all tests are done
    if (totalTests === testFiles.length) {
      printSummary();
    }
  });

  testProcess.on('error', (error) => {
    console.error(`❌ Error running ${testFile}:`, error);
    failedTests++;
    totalTests++;

    if (totalTests === testFiles.length) {
      printSummary();
    }
  });
});

function printSummary() {
  console.log('\n' + '='.repeat(60));
  console.log('📊 Test Summary');
  console.log('='.repeat(60));
  console.log(`Total Test Files: ${totalTests}`);
  console.log(`Passed: ${passedTests}`);
  console.log(`Failed: ${failedTests}`);
  console.log(`Success Rate: ${((passedTests / totalTests) * 100).toFixed(2)}%`);
  console.log('='.repeat(60));

  if (failedTests > 0) {
    process.exit(1);
  } else {
    console.log('\n🎉 All tests passed!');
    process.exit(0);
  }
}
