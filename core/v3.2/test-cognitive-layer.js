/**
 * OpenClaw V3.2 - 认知层完整测试
 * 测试认知层所有核心模块功能
 *
 * @author OpenClaw V3.2
 * @date 2026-02-22
 */

const TaskPatternRecognizer = require('./cognitive-layer/task-pattern-recognizer');
const UserBehaviorProfile = require('./cognitive-layer/user-behavior-profile');
const StructuredExperience = require('./cognitive-layer/structured-experience');
const FailurePatternDatabase = require('./cognitive-layer/failure-pattern-database');

const fs = require('fs');
const path = require('path');

// 测试配置
const testDataDir = path.join(__dirname, 'cognitive-layer-test-data');

// 清理测试数据
if (fs.existsSync(testDataDir)) {
  fs.rmSync(testDataDir, { recursive: true, force: true });
}
fs.mkdirSync(testDataDir, { recursive: true });

async function runTests() {
  console.log('═════════════════════════════════════════════════════════════');
  console.log('   OpenClaw V3.2 认知层完整测试');
  console.log('═════════════════════════════════════════════════════════════\n');

  let passedTests = 0;
  let failedTests = 0;
  let testsRun = 0;

  let taskRecognizer, userProfile, structuredExperience, failureDB;

  try {
    // 测试 1: TaskPatternRecognizer 初始化
    console.log('测试 1/16: TaskPatternRecognizer 初始化...');
    testsRun++;

    taskRecognizer = new TaskPatternRecognizer();
    taskRecognizer.setStorageDir(testDataDir);

    if (taskRecognizer && taskRecognizer.name === 'TaskPatternRecognizer') {
      console.log('✅ TaskPatternRecognizer 初始化成功\n');
      passedTests++;
    } else {
      console.log('❌ TaskPatternRecognizer 初始化失败\n');
      failedTests++;
    }

    // 测试 2: UserBehaviorProfile 初始化
    console.log('测试 2/16: UserBehaviorProfile 初始化...');
    testsRun++;

    userProfile = new UserBehaviorProfile();
    userProfile.setStorageDir(testDataDir);

    if (userProfile && userProfile.name === 'UserBehaviorProfile') {
      console.log('✅ UserBehaviorProfile 初始化成功\n');
      passedTests++;
    } else {
      console.log('❌ UserBehaviorProfile 初始化失败\n');
      failedTests++;
    }

    // 测试 3: StructuredExperience 初始化
    console.log('测试 3/16: StructuredExperience 初始化...');
    testsRun++;

    structuredExperience = new StructuredExperience();
    structuredExperience.setStorageDir(testDataDir);

    if (structuredExperience && structuredExperience.name === 'StructuredExperience') {
      console.log('✅ StructuredExperience 初始化成功\n');
      passedTests++;
    } else {
      console.log('❌ StructuredExperience 初始化失败\n');
      failedTests++;
    }

    // 测试 4: FailurePatternDatabase 初始化
    console.log('测试 4/16: FailurePatternDatabase 初始化...');
    testsRun++;

    failureDB = new FailurePatternDatabase();
    failureDB.setStorageDir(testDataDir);

    if (failureDB && failureDB.name === 'FailurePatternDatabase') {
      console.log('✅ FailurePatternDatabase 初始化成功\n');
      passedTests++;
    } else {
      console.log('❌ FailurePatternDatabase 初始化失败\n');
      failedTests++;
    }

    // 初始化测试数据
    const testTask1 = {
      id: 'task-1',
      type: 'code-review',
      description: 'Review code for potential bugs and improvements',
      tokens: 5000
    };

    const testTask2 = {
      id: 'task-2',
      type: 'documentation',
      description: 'Write documentation for the new feature',
      tokens: 8000
    };

    const testTask3 = {
      id: 'task-3',
      type: 'debugging',
      description: 'Debug the authentication issue',
      tokens: 3000
    };

    const testUser = {
      userId: 'user-1',
      name: 'John Doe',
      preferences: {
        verboseResponse: true,
        conciseResponse: false
      }
    };

    const testFailure = {
      id: 'failure-1',
      type: 'auth-error',
      description: 'Authentication token expired',
      severity: 'high',
      timestamp: new Date().toISOString()
    };

    const testSuccess = {
      id: 'success-1',
      type: 'code-review',
      description: 'Successfully reviewed and approved code',
      effectiveness: 0.95,
      timestamp: new Date().toISOString()
    };

    // 测试 5: TaskPatternRecognizer 训练
    console.log('测试 5/16: TaskPatternRecognizer 训练...');
    testsRun++;

    try {
      await taskRecognizer.train([
        { name: 'code-review', keywords: ['code', 'review', 'bug', 'improvement'], category: 'development' },
        { name: 'documentation', keywords: ['documentation', 'doc', 'write', 'explain'], category: 'documentation' },
        { name: 'debugging', keywords: ['debug', 'error', 'fix', 'bug'], category: 'development' }
      ]);

      if (taskRecognizer.isTrained()) {
        console.log('✅ TaskPatternRecognizer 训练成功\n');
        console.log(`  训练模式数: ${taskRecognizer.getTrainedPatterns().length}`);
        passedTests++;
      } else {
        console.log('❌ TaskPatternRecognizer 训练失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ TaskPatternRecognizer 训练失败: ${error.message}\n`);
      failedTests++;
    }

    // 测试 6: TaskPatternRecognizer 识别任务
    console.log('测试 6/16: TaskPatternRecognizer 识别任务...');
    testsRun++;

    try {
      const result1 = await taskRecognizer.identify(testTask1);
      const result2 = await taskRecognizer.identify(testTask2);
      const result3 = await taskRecognizer.identify(testTask3);

      if (result1 && result2 && result3) {
        console.log('✅ 任务识别成功\n');
        console.log(`  Task 1: ${result1.taskType} (置信度: ${result1.confidence.toFixed(3)})`);
        console.log(`  Task 2: ${result2.taskType} (置信度: ${result2.confidence.toFixed(3)})`);
        console.log(`  Task 3: ${result3.taskType} (置信度: ${result3.confidence.toFixed(3)})`);
        console.log();
        passedTests++;
      } else {
        console.log('❌ 任务识别失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 任务识别失败: ${error.message}\n`);
      failedTests++;
    }

    // 测试 7: TaskPatternRecognizer 特征提取
    console.log('测试 7/16: TaskPatternRecognizer 特征提取...');
    testsRun++;

    try {
      const features1 = taskRecognizer.extractFeatures(testTask1);
      const features2 = taskRecognizer.extractFeatures(testTask2);

      if (features1 && features2 && features1.taskType && features2.taskType) {
        console.log('✅ 特征提取成功\n');
        console.log(`  Task 1 特征:`, {
          taskType: features1.taskType,
          description: features1.description,
          tokenCount: features1.tokenCount
        });
        console.log(`  Task 2 特征:`, {
          taskType: features2.taskType,
          description: features2.description,
          tokenCount: features2.tokenCount
        });
        console.log();
        passedTests++;
      } else {
        console.log('❌ 特征提取失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 特征提取失败: ${error.message}\n`);
      failedTests++;
    }

    // 测试 8: UserBehaviorProfile 记录用户行为
    console.log('测试 8/16: UserBehaviorProfile 记录用户行为...');
    testsRun++;

    try {
      userProfile.recordBehavior(testUser, {
        action: 'task-completion',
        taskType: 'code-review',
        success: true,
        responseTime: 5000,
        tokensUsed: 4500
      });

      userProfile.recordBehavior(testUser, {
        action: 'task-completion',
        taskType: 'documentation',
        success: true,
        responseTime: 8000,
        tokensUsed: 7200
      });

      userProfile.recordBehavior(testUser, {
        action: 'task-completion',
        taskType: 'debugging',
        success: false,
        responseTime: 12000,
        tokensUsed: 3800
      });

      const profile = userProfile.getProfile(testUser.userId);
      if (profile && profile.behaviors && profile.behaviors.length >= 3) {
        console.log('✅ 用户行为记录成功\n');
        console.log(`  用户行为数: ${profile.behaviors.length}`);
        console.log(`  任务完成次数: ${profile.behaviors.filter(b => b.success).length}`);
        console.log(`  平均响应时间: ${Math.round(profile.behaviors.reduce((sum, b) => sum + b.responseTime, 0) / profile.behaviors.length)}ms`);
        console.log();
        passedTests++;
      } else {
        console.log('❌ 用户行为记录失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 用户行为记录失败: ${error.message}\n`);
      failedTests++;
    }

    // 测试 9: UserBehaviorProfile 识别行为模式
    console.log('测试 9/16: UserBehaviorProfile 识别行为模式...');
    testsRun++;

    try {
      const patterns = userProfile.analyzePatterns(testUser.userId);

      if (patterns && Object.keys(patterns).length > 0) {
        console.log('✅ 行为模式识别成功\n');
        console.log(`  识别的模式数: ${Object.keys(patterns).length}`);
        console.log(`  模式详情:`, JSON.stringify(patterns, null, 2));
        console.log();
        passedTests++;
      } else {
        console.log('❌ 行为模式识别失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 行为模式识别失败: ${error.message}\n`);
      failedTests++;
    }

    // 测试 10: UserBehaviorProfile 生成用户画像
    console.log('测试 10/16: UserBehaviorProfile 生成用户画像...');
    testsRun++;

    try {
      const profile = userProfile.generateUserProfile(testUser.userId);

      if (profile && profile.userId && profile.behaviorMetrics) {
        console.log('✅ 用户画像生成成功\n');
        console.log(`  用户ID: ${profile.userId}`);
        console.log(`  任务完成率: ${(profile.behaviorMetrics.successRate * 100).toFixed(1)}%`);
        console.log(`  平均Token消耗: ${Math.round(profile.behaviorMetrics.avgTokensUsed)}`);
        console.log(`  平均响应时间: ${Math.round(profile.behaviorMetrics.avgResponseTime)}ms`);
        console.log();
        passedTests++;
      } else {
        console.log('❌ 用户画像生成失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 用户画像生成失败: ${error.message}\n`);
      failedTests++;
    }

    // 测试 11: StructuredExperience 记录成功案例
    console.log('测试 11/16: StructuredExperience 记录成功案例...');
    testsRun++;

    try {
      structuredExperience.recordSuccess(testSuccess);
      structuredExperience.recordSuccess({
        id: 'success-2',
        type: 'documentation',
        description: 'Successfully created comprehensive docs',
        effectiveness: 0.98,
        timestamp: new Date().toISOString()
      });

      const successes = structuredExperience.getSuccesses('code-review');
      if (successes && successes.length >= 1) {
        console.log('✅ 成功案例记录成功\n');
        console.log(`  code-review 成功案例数: ${successes.length}`);
        console.log(`  平均效果: ${(successes.reduce((sum, s) => sum + s.effectiveness, 0) / successes.length).toFixed(3)}`);
        console.log();
        passedTests++;
      } else {
        console.log('❌ 成功案例记录失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 成功案例记录失败: ${error.message}\n`);
      failedTests++;
    }

    // 测试 12: StructuredExperience 提取模式
    console.log('测试 12/16: StructuredExperience 提取模式...');
    testsRun++;

    try {
      const patterns = structuredExperience.extractPatterns('code-review');
      const patterns2 = structuredExperience.extractPatterns('documentation');

      if (patterns && patterns2) {
        console.log('✅ 模式提取成功\n');
        console.log(`  code-review 模式数: ${Object.keys(patterns).length}`);
        console.log(`  documentation 模式数: ${Object.keys(patterns2).length}`);
        console.log();
        passedTests++;
      } else {
        console.log('❌ 模式提取失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 模式提取失败: ${error.message}\n`);
      failedTests++;
    }

    // 测试 13: StructuredExperience 复用模式
    console.log('测试 13/16: StructuredExperience 复用模式...');
    testsRun++;

    try {
      const suggestedStrategy = structuredExperience.reusePattern({
        id: 'reuse-1',
        type: 'code-review',
        description: 'Review similar code review patterns',
        effectiveness: 0.9,
        timestamp: new Date().toISOString()
      });

      if (suggestedStrategy) {
        console.log('✅ 模式复用成功\n');
        console.log(`  建议策略: ${suggestedStrategy}`);
        console.log();
        passedTests++;
      } else {
        console.log('❌ 模式复用失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 模式复用失败: ${error.message}\n`);
      failedTests++;
    }

    // 测试 14: FailurePatternDatabase 注册失败模式
    console.log('测试 14/16: FailurePatternDatabase 注册失败模式...');
    testsRun++;

    try {
      failureDB.registerFailure(testFailure);
      failureDB.registerFailure({
        id: 'failure-2',
        type: 'auth-error',
        description: 'API rate limit exceeded',
        severity: 'medium',
        timestamp: new Date().toISOString()
      });

      const failures = failureDB.getFailures('auth-error');
      if (failures && failures.length >= 2) {
        console.log('✅ 失败模式注册成功\n');
        console.log(`  auth-error 失败数: ${failures.length}`);
        console.log(`  失败类型分布:`, failureDB.getFailureStatistics());
        console.log();
        passedTests++;
      } else {
        console.log('❌ 失败模式注册失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 失败模式注册失败: ${error.message}\n`);
      failedTests++;
    }

    // 测试 15: FailurePatternDatabase 分析失败类型
    console.log('测试 15/16: FailurePatternDatabase 分析失败类型...');
    testsRun++;

    try {
      const types = failureDB.analyzeFailureTypes();
      const statistics = failureDB.getFailureStatistics();

      if (types && statistics) {
        console.log('✅ 失败类型分析成功\n');
        console.log(`  识别的失败类型数: ${types.length}`);
        console.log(`  统计信息:`, statistics);
        console.log();
        passedTests++;
      } else {
        console.log('❌ 失败类型分析失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 失败类型分析失败: ${error.message}\n`);
      failedTests++;
    }

    // 测试 16: FailurePatternDatabase 检测相似失败
    console.log('测试 16/16: FailurePatternDatabase 检测相似失败...');
    testsRun++;

    try {
      const similarFailures = failureDB.detectSimilarFailures({
        description: 'Authentication token issue',
        type: 'auth-error'
      });

      if (similarFailures && similarFailures.length >= 1) {
        console.log('✅ 相似失败检测成功\n');
        console.log(`  发现相似失败数: ${similarFailures.length}`);
        console.log(`  相似失败:`, similarFailures);
        console.log();
        passedTests++;
      } else {
        console.log('❌ 相似失败检测失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 相似失败检测失败: ${error.message}\n`);
      failedTests++;
    }

  } catch (error) {
    console.log(`❌ 测试过程中发生错误: ${error.message}`);
    console.log(error.stack);
    failedTests++;
  }

  // 测试总结
  console.log('═════════════════════════════════════════════════════════════');
  console.log('   测试总结');
  console.log('═════════════════════════════════════════════════════════════');
  console.log(`  测试数: ${testsRun}`);
  console.log(`  通过: ${passedTests}`);
  console.log(`  失败: ${failedTests}`);
  console.log(`  通过率: ${((passedTests / testsRun) * 100).toFixed(1)}%`);
  console.log('═════════════════════════════════════════════════════════════\n');

  if (failedTests === 0) {
    console.log('🎉 所有测试通过！');
  } else {
    console.log('⚠️  部分测试失败，请检查错误信息。');
  }

  // 清理测试数据
  if (fs.existsSync(testDataDir)) {
    fs.rmSync(testDataDir, { recursive: true, force: true });
    console.log('\n🗑️  已清理测试数据');
  }
}

// 运行测试
runTests().catch(console.error);
