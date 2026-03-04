const fs = require('fs');
const path = require('path');
const moment = require('moment-timezone');

// Test configuration
const TEST_CONFIG = {
  version: '1.0.0',
  description: 'Cron Scheduler Test Suite',
  tests: {
    schedulerInitialization: true,
    taskRegistration: true,
    cronExpressionValidation: true,
    taskExecution: true,
    retryMechanism: true,
    taskStatusTracking: true,
    taskPriority: true,
    allTasksScheduled: true
  }
};

console.log('========================================');
console.log('   Cron Scheduler Test Suite');
console.log('========================================\n');

const results = {
  total: 0,
  passed: 0,
  failed: 0,
  tests: []
};

// Helper functions
function logTest(name, status, message) {
  results.total++;
  const test = {
    name,
    status,
    message
  };
  results.tests.push(test);

  if (status === 'passed') {
    results.passed++;
    console.log(`✓ ${name}`);
  } else {
    results.failed++;
    console.log(`✗ ${name}`);
  }

  if (message) {
    console.log(`  ${message}`);
  }
  console.log('');
}

function assert(condition, testName, message) {
  if (condition) {
    logTest(testName, 'passed', message);
  } else {
    logTest(testName, 'failed', message);
  }
}

// Set project root
const PROJECT_ROOT = __dirname;

async function runTests() {
  // Set working directory to project root
  process.chdir(PROJECT_ROOT);

  console.log('Running Cron Scheduler Tests...\n');
  console.log(`PROJECT_ROOT: ${PROJECT_ROOT}`);
  console.log(`__dirname: ${__dirname}\n`);

  // Test 1: Configuration Loading
  console.log('--- Test 1: Configuration Loading ---');
  try {
    const configPath = path.join(__dirname, 'config', 'cron-config.json');
    const configExists = fs.existsSync(configPath);

    assert(configExists, 'Configuration file exists', configExists ? 'File found at cron-scheduler/config/cron-config.json' : 'File not found');

    if (configExists) {
      const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
      assert(config.version, 'Configuration has version', `Version: ${config.version}`);
      assert(config.timezone, 'Configuration has timezone', `Timezone: ${config.timezone}`);
      assert(Array.isArray(config.tasks), 'Configuration has tasks array', `Number of tasks: ${config.tasks.length}`);
    }
  } catch (error) {
    logTest('Configuration Loading', 'failed', error.message);
  }

  // Test 2: Task Scripts Existence
  console.log('\n--- Test 2: Task Scripts Existence ---');
  const taskScripts = [
    'scripts/generate-daily-report.js',
    'scripts/generate-weekly-report.js',
    'scripts/reset-daily-metrics.js',
    'scripts/weekly-data-cleanup.js',
    'scripts/heartbeat-monitor.js'
  ];
  taskScripts.forEach(script => {
    const scriptPath = path.join(PROJECT_ROOT, script);
    const scriptExists = fs.existsSync(scriptPath);
    assert(scriptExists, `${script} exists`, scriptExists ? '✓' : '✗');
  });

  // Test 3: Task Configuration
  console.log('\n--- Test 3: Task Configuration ---');
  try {
    const configPath = path.join(__dirname, 'config', 'cron-config.json');
    const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));

    config.tasks.forEach(task => {
      assert(task.id, `Task ${task.name} has ID`, task.id);
      assert(task.cronExpression, `Task ${task.name} has cron expression`, task.cronExpression);
      assert(task.script, `Task ${task.name} has script path`, task.script);
      assert(task.enabled !== undefined, `Task ${task.name} has enabled status`, String(task.enabled));
      assert(task.priority !== undefined, `Task ${task.name} has priority`, String(task.priority));
    });

    // Check cron expression format
    // Format: minute hour day month weekday
    // Example: "0 4 * * *" means "0 minutes past hour 4, every day, every month"
    // Support for */interval syntax
    const validCron = /^(?:\*|\d+|\*\/\d+|\d{1,2})(?: (?:\*|\d+|\*\/\d+|\d{1,2})){3}(?: (?:\*|\d{1,2}|0?[0-9]|1\d|2[0-3]))?$/;
    config.tasks.forEach(task => {
      const isValidCron = validCron.test(task.cronExpression);
      assert(isValidCron, `Task ${task.name} has valid cron expression`, `${task.cronExpression}`);
    });

    // Check task priorities
    const priorities = config.tasks.map(t => t.priority);
    const uniquePriorities = new Set(priorities);
    assert(uniquePriorities.size === priorities.length, 'All tasks have unique priorities', `Unique priorities: ${uniquePriorities.size}`);

  } catch (error) {
    logTest('Task Configuration', 'failed', error.message);
  }

  // Test 4: Script Execution - Daily Report
  console.log('\n--- Test 4: Script Execution - Daily Report ---');
  try {
    const scriptPath = path.join(PROJECT_ROOT, 'scripts', 'generate-daily-report.js');

    if (fs.existsSync(scriptPath)) {
      const { spawn } = require('child_process');
      const process = spawn('node', [scriptPath], { cwd: PROJECT_ROOT });

      let stdout = '';
      let stderr = '';

      process.stdout.on('data', (data) => {
        stdout += data.toString();
      });

      process.stderr.on('data', (data) => {
        stderr += data.toString();
      });

      await new Promise((resolve, reject) => {
        process.on('close', (code) => {
          if (code === 0) {
            resolve();
          } else {
            reject(new Error(`Script exited with code ${code}`));
          }
        });
        process.on('error', (error) => {
          reject(error);
        });

        // Timeout after 30 seconds
        setTimeout(() => {
          process.kill();
          reject(new Error('Script timeout'));
        }, 30000);
      });

      assert(stdout.includes('✓'), 'Daily report script executed successfully', 'Report generated');
    } else {
      logTest('Script Execution - Daily Report', 'failed', 'Script file not found');
    }
  } catch (error) {
    logTest('Script Execution - Daily Report', 'failed', error.message);
  }

  // Test 5: Script Execution - Weekly Report
  console.log('\n--- Test 5: Script Execution - Weekly Report ---');
  try {
    const scriptPath = path.join(PROJECT_ROOT, 'scripts', 'generate-weekly-report.js');

    if (fs.existsSync(scriptPath)) {
      const { spawn } = require('child_process');
      const process = spawn('node', [scriptPath], { cwd: PROJECT_ROOT });

      let stdout = '';
      let stderr = '';

      process.stdout.on('data', (data) => {
        stdout += data.toString();
      });

      process.stderr.on('data', (data) => {
        stderr += data.toString();
      });

      await new Promise((resolve, reject) => {
        process.on('close', (code) => {
          if (code === 0) {
            resolve();
          } else {
            reject(new Error(`Script exited with code ${code}`));
          }
        });
        process.on('error', (error) => {
          reject(error);
        });

        setTimeout(() => {
          process.kill();
          reject(new Error('Script timeout'));
        }, 30000);
      });

      assert(stdout.includes('✓'), 'Weekly report script executed successfully', 'Report generated');
    } else {
      logTest('Script Execution - Weekly Report', 'failed', 'Script file not found');
    }
  } catch (error) {
    logTest('Script Execution - Weekly Report', 'failed', error.message);
  }

  // Test 6: Script Execution - Metrics Reset
  console.log('\n--- Test 6: Script Execution - Metrics Reset ---');
  try {
    const scriptPath = path.join(PROJECT_ROOT, 'scripts', 'reset-daily-metrics.js');

    if (fs.existsSync(scriptPath)) {
      const { spawn } = require('child_process');
      const process = spawn('node', [scriptPath], { cwd: PROJECT_ROOT });

      let stdout = '';
      let stderr = '';

      process.stdout.on('data', (data) => {
        stdout += data.toString();
      });

      process.stderr.on('data', (data) => {
        stderr += data.toString();
      });

      await new Promise((resolve, reject) => {
        process.on('close', (code) => {
          if (code === 0) {
            resolve();
          } else {
            reject(new Error(`Script exited with code ${code}`));
          }
        });
        process.on('error', (error) => {
          reject(error);
        });

        setTimeout(() => {
          process.kill();
          reject(new Error('Script timeout'));
        }, 30000);
      });

      assert(stdout.includes('✓'), 'Metrics reset script executed successfully', 'Metrics reset');
    } else {
      logTest('Script Execution - Metrics Reset', 'failed', 'Script file not found');
    }
  } catch (error) {
    logTest('Script Execution - Metrics Reset', 'failed', error.message);
  }

  // Test 7: Script Execution - Data Cleanup
  console.log('\n--- Test 7: Script Execution - Data Cleanup ---');
  try {
    const scriptPath = path.join(PROJECT_ROOT, 'scripts', 'weekly-data-cleanup.js');

    if (fs.existsSync(scriptPath)) {
      const { spawn } = require('child_process');
      const process = spawn('node', [scriptPath], { cwd: PROJECT_ROOT });

      let stdout = '';
      let stderr = '';

      process.stdout.on('data', (data) => {
        stdout += data.toString();
      });

      process.stderr.on('data', (data) => {
        stderr += data.toString();
      });

      await new Promise((resolve, reject) => {
        process.on('close', (code) => {
          if (code === 0) {
            resolve();
          } else {
            reject(new Error(`Script exited with code ${code}`));
          }
        });
        process.on('error', (error) => {
          reject(error);
        });

        setTimeout(() => {
          process.kill();
          reject(new Error('Script timeout'));
        }, 30000);
      });

      assert(stdout.includes('✓'), 'Data cleanup script executed successfully', 'Data cleaned');
    } else {
      logTest('Script Execution - Data Cleanup', 'failed', 'Script file not found');
    }
  } catch (error) {
    logTest('Script Execution - Data Cleanup', 'failed', error.message);
  }

  // Test 8: Script Execution - Heartbeat Monitor
  console.log('\n--- Test 8: Script Execution - Heartbeat Monitor ---');
  try {
    const scriptPath = path.join(PROJECT_ROOT, 'scripts', 'heartbeat-monitor.js');

    if (fs.existsSync(scriptPath)) {
      const { spawn } = require('child_process');
      const process = spawn('node', [scriptPath], { cwd: PROJECT_ROOT });

      let stdout = '';
      let stderr = '';

      process.stdout.on('data', (data) => {
        stdout += data.toString();
      });

      process.stderr.on('data', (data) => {
        stderr += data.toString();
      });

      await new Promise((resolve, reject) => {
        process.on('close', (code) => {
          if (code === 0) {
            resolve();
          } else {
            reject(new Error(`Script exited with code ${code}`));
          }
        });
        process.on('error', (error) => {
          reject(error);
        });

        setTimeout(() => {
          process.kill();
          reject(new Error('Script timeout'));
        }, 30000);
      });

      assert(stdout.includes('✓'), 'Heartbeat monitor script executed successfully', 'Heartbeat check completed');
    } else {
      logTest('Script Execution - Heartbeat Monitor', 'failed', 'Script file not found');
    }
  } catch (error) {
    logTest('Script Execution - Heartbeat Monitor', 'failed', error.message);
  }

  // Test 9: Scheduler Instance
  console.log('\n--- Test 9: Scheduler Instance ---');
  try {
    const { CronScheduler } = require('./index.js');

    const scheduler = new CronScheduler();
    assert(scheduler, 'CronScheduler class can be instantiated', 'Scheduler instance created');

    const config = scheduler.getDefaultConfig();
    assert(config, 'Default config loaded', `${config.tasks.length} tasks configured`);

    const status = scheduler.getSchedulerInfo();
    assert(status, 'Scheduler info retrieved', `Running: ${status.running}, Tasks: ${status.taskCount}`);

  } catch (error) {
    logTest('Scheduler Instance', 'failed', error.message);
  }

  // Test 10: Output Files Generated
  console.log('\n--- Test 10: Output Files Generated ---');
  try {
    const reportsDir = path.join(PROJECT_ROOT, 'reports');
    const dataDir = path.join(PROJECT_ROOT, 'data');

    // Check for daily report
    const today = moment().tz('Asia/Shanghai').format('YYYY-MM-DD');
    const dailyReport = fs.existsSync(path.join(reportsDir, `daily-report-${today}.json`));

    // Check for health check
    const healthCheck = fs.existsSync(path.join(dataDir, 'health-check.json'));

    assert(dailyReport, 'Daily report file created', `daily-report-${today}.json`);
    assert(healthCheck, 'Health check file created', 'health-check.json');
  } catch (error) {
    logTest('Output Files Generated', 'failed', error.message);
  }

  // Print summary
  console.log('========================================');
  console.log('   Test Summary');
  console.log('========================================');
  console.log(`Total Tests: ${results.total}`);
  console.log(`Passed: ${results.passed}`);
  console.log(`Failed: ${results.failed}`);
  console.log(`Success Rate: ${((results.passed / results.total) * 100).toFixed(2)}%`);
  console.log('');

  // Print failed tests
  if (results.failed > 0) {
    console.log('Failed Tests:');
    results.tests.filter(t => t.status === 'failed').forEach(test => {
      console.log(`  - ${test.name}: ${test.message}`);
    });
    console.log('');
  }

  // Exit with appropriate code
  process.exit(results.failed > 0 ? 1 : 0);
}

// Run tests
runTests().catch(error => {
  console.error('Test suite error:', error);
  process.exit(1);
});
