/**
 * OpenClaw 3.3 - 认知层增强完整测试
 * 测试任务模式识别、用户意图推断、行为预测
 * 
 * @version 3.3.0
 * @author OpenClaw V3.3
 * @date 2026-02-22
 */

const CognitiveLayerEnhanced = require('./cognitive-layer-enhanced');

async function runTests() {
  console.log('═════════════════════════════════════════════════════════════');
  console.log('   OpenClaw 3.3 - 认知层增强测试');
  console.log('   Phase 3.3-2: 任务模式识别 + 用户行为画像');
  console.log('═════════════════════════════════════════════════════════════\n');

  let passedTests = 0;
  let failedTests = 0;
  let testsRun = 0;

  try {
    // 测试1: 认知层增强初始化
    console.log('测试 1/10: CognitiveLayerEnhanced 初始化...');
    testsRun++;

    try {
      const cognitiveLayer = new CognitiveLayerEnhanced();

      if (cognitiveLayer && cognitiveLayer.name === 'CognitiveLayerEnhanced') {
        console.log('✅ CognitiveLayerEnhanced 初始化成功\n');
        passedTests++;
      } else {
        console.log('❌ CognitiveLayerEnhanced 初始化失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ CognitiveLayerEnhanced 初始化失败: ${error.message}\n`);
      failedTests++;
    }

    // 测试2: 任务模式识别
    console.log('测试 2/10: 任务模式识别（深度模式提取）...');
    testsRun++;

    try {
      const cognitiveLayer = new CognitiveLayerEnhanced();
      const context = {
        id: 'task-1',
        name: '搜索相关文档',
        type: 'QUERY',
        urgency: 'HIGH',
        deadline: '2026-02-23'
      };

      const patternRecognition = await cognitiveLayer.patternRecognizer.recognizeTaskPattern(context);

      if (patternRecognition && patternRecognition.patternCount > 0) {
        console.log(`✅ 模式识别成功: ${patternRecognition.patternCount}个模式\n`);
        passedTests++;

        console.log('   模式列表:');
        patternRecognition.recognizedPatterns.deep.forEach((p, i) => {
          console.log(`     ${i + 1}. ${p.name} (${p.confidence.toFixed(2)})`);
        });
      } else {
        console.log('❌ 任务模式识别失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 任务模式识别失败: ${error.message}\n`);
      failedTests++;
    }

    // 测试3: 用户意图推断
    console.log('测试 3/10: 用户意图推断...');
    testsRun++;

    try {
      const cognitiveLayer = new CognitiveLayerEnhanced();
      const context = {
        userId: 'user-1',
        message: '帮我搜索一下相关的技术文档',
        history: [
          { message: '搜索技术文档', timestamp: Date.now() - 3600000 }
        ],
        time: {
          hour: new Date().getHours(),
          isWeekend: false,
          isWorkHour: true
        }
      };

      const intentInference = cognitiveLayer.behaviorProfile.inferIntent(context);

      if (intentInference && intentInference.type) {
        console.log(`✅ 意图推断成功: ${intentInference.type} - ${intentInference.category}\n`);
        passedTests++;

        console.log('   意图详情:');
        console.log(`     类型: ${intentInference.type}`);
        console.log(`     类别: ${intentInference.category}`);
        console.log(`     子类别: ${intentInference.subcategory}`);
        console.log(`     置信度: ${intentInference.confidence.toFixed(3)}`);
        console.log(`     原因: ${intentInference.reasons.join(', ')}`);
      } else {
        console.log('❌ 用户意图推断失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 用户意图推断失败: ${error.message}\n`);
      failedTests++;
    }

    // 测试4: 行为预测
    console.log('测试 4/10: 行为预测...');
    testsRun++;

    try {
      const cognitiveLayer = new CognitiveLayerEnhanced();
      const context = {
        userId: 'user-1',
        time: {
          hour: new Date().getHours(),
          isWorkHour: true
        },
        frequency: {
          daily: 10
        },
        predictWindow: 24
      };

      const behaviorPrediction = cognitiveLayer.behaviorProfile.predictBehavior(context);

      if (behaviorPrediction && behaviorPrediction.behavior) {
        console.log(`✅ 行为预测成功: ${behaviorPrediction.behavior}\n`);
        passedTests++;

        console.log('   预测详情:');
        console.log(`     预测行为: ${behaviorPrediction.behavior}`);
        console.log(`     发生概率: ${behaviorPrediction.likelihood.toFixed(3)}`);
        console.log(`     行为概率: ${behaviorPrediction.probability.toFixed(3)}`);
      } else {
        console.log('❌ 行为预测失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 行为预测失败: ${error.message}\n`);
      failedTests++;
    }

    // 测试5: 用户画像更新和查询
    console.log('测试 5/10: 用户画像更新和查询...');
    testsRun++;

    try {
      const cognitiveLayer = new CognitiveLayerEnhanced();
      const userId = 'user-2';

      // 更新用户画像
      cognitiveLayer.updateUserProfile(userId, {
        lastIntent: { type: 'SEARCH', confidence: 0.85 },
        lastBehavior: { behavior: 'work_primary', duration: 3600 },
        preferences: {
          profession: 'developer',
          interests: [
            { type: 'code', name: '编程' },
            { type: 'tech', name: '技术' }
          ]
        }
      });

      // 查询用户画像
      const userProfile = cognitiveLayer.getUserProfile(userId);

      if (userProfile && userProfile.userId === userId) {
        console.log(`✅ 用户画像管理成功\n`);
        passedTests++;

        console.log('   用户画像:');
        console.log(`     用户ID: ${userProfile.userId}`);
        console.log(`     职业: ${userProfile.preferences?.profession}`);
        console.log(`     兴趣: ${userProfile.preferences?.interests?.length}个`);
      } else {
        console.log('❌ 用户画像管理失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 用户画像管理失败: ${error.message}\n`);
      failedTests++;
    }

    // 测试6: 用户模式识别
    console.log('测试 6/10: 用户模式识别...');
    testsRun++;

    try {
      const cognitiveLayer = new CognitiveLayerEnhanced();
      const userId = 'user-2';

      // 更新行为历史
      cognitiveLayer.updateUserProfile(userId, {
        lastBehavior: { behavior: 'code', duration: 1800 },
        lastBehavior: { behavior: 'work_primary', duration: 3600 },
        lastBehavior: { behavior: 'code', duration: 1500 },
        lastBehavior: { behavior: 'code', duration: 2000 }
      });

      // 识别用户模式
      const patternResult = cognitiveLayer.identifyUserPattern(userId);

      if (patternResult && patternResult.recognized) {
        console.log(`✅ 用户模式识别成功\n`);
        passedTests++;

        console.log('   识别到的模式:');
        patternResult.patterns.forEach((p, i) => {
          console.log(`     ${i + 1}. ${p.type} - ${p.frequency.toFixed(2)} (${p.count}次)`);
        });
      } else {
        console.log('❌ 用户模式识别失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 用户模式识别失败: ${error.message}\n`);
      failedTests++;
    }

    // 测试7: 认知分析完整流程
    console.log('测试 7/10: 认知分析完整流程...');
    testsRun++;

    try {
      const cognitiveLayer = new CognitiveLayerEnhanced();
      const context = {
        userId: 'user-3',
        id: 'task-2',
        name: '分析项目数据',
        type: 'ANALYSIS',
        urgency: 'HIGH',
        time: {
          hour: 14,
          isWorkHour: true
        }
      };

      const cognitiveResult = await cognitiveLayer.cognitiveAnalysis(context);

      if (cognitiveResult && cognitiveResult.intentInference && cognitiveResult.patternRecognition) {
        console.log('✅ 认知分析流程成功\n');
        passedTests++;

        console.log('   分析结果:');
        console.log(`     意图类型: ${cognitiveResult.intentInference.type}`);
        console.log(`     意图分类: ${cognitiveResult.intentInference.category}`);
        console.log(`     模式数量: ${cognitiveResult.patternRecognition.patternCount}`);
        console.log(`     认知建议: ${cognitiveResult.recommendations.length}条`);
      } else {
        console.log('❌ 认知分析流程失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 认知分析流程失败: ${error.message}\n`);
      failedTests++;
    }

    // 测试8: 意图库管理
    console.log('测试 8/10: 意图库管理...');
    testsRun++;

    try {
      const cognitiveLayer = new CognitiveLayerEnhanced();
      const context = {
        userId: 'user-4',
        message: '我想创建一个新的项目',
        time: { hour: 15 }
      };

      // 推断意图
      const intent = cognitiveLayer.behaviorProfile.inferIntent(context);

      // 检查意图库
      const intentLibrarySize = cognitiveLayer.behaviorProfile.intentLibrary.size;

      console.log(`✅ 意图库管理成功 (库大小: ${intentLibrarySize})\n`);
      passedTests++;
    } catch (error) {
      console.log(`❌ 意图库管理失败: ${error.message}\n`);
      failedTests++;
    }

    // 测试9: 行为偏差检测
    console.log('测试 9/10: 行为偏差检测...');
    testsRun++;

    try {
      const cognitiveLayer = new CognitiveLayerEnhanced();
      const userId = 'user-5';

      // 更新正常行为历史
      cognitiveLayer.updateUserProfile(userId, {
        lastBehavior: { behavior: 'work_primary', duration: 3600 },
        lastBehavior: { behavior: 'work_primary', duration: 3600 },
        lastBehavior: { behavior: 'work_primary', duration: 3600 }
      });

      // 模拟异常行为
      const context = {
        userId: userId,
        time: { hour: 20 }
      };

      const prediction = cognitiveLayer.behaviorProfile.predictBehavior(context);
      const deviations = cognitiveLayer.behaviorProfile.detectBehaviorDeviations(context);

      if (prediction && deviations) {
        console.log(`✅ 行为偏差检测成功\n`);
        passedTests++;

        if (deviations.length > 0) {
          console.log('   检测到的偏差:');
          deviations.forEach((d, i) => {
            console.log(`     ${i + 1}. ${d.type} - ${d.message}`);
          });
        } else {
          console.log('   无异常偏差');
        }
      } else {
        console.log('❌ 行为偏差检测失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 行为偏差检测失败: ${error.message}\n`);
      failedTests++;
    }

    // 测试10: 综合认知建议生成
    console.log('测试 10/10: 综合认知建议生成...');
    testsRun++;

    try {
      const cognitiveLayer = new CognitiveLayerEnhanced();
      const context = {
        userId: 'user-6',
        id: 'task-3',
        name: '优化系统性能',
        type: 'OPTIMIZATION',
        time: { hour: 16 }
      };

      const cognitiveResult = await cognitiveLayer.cognitiveAnalysis(context);

      if (cognitiveResult && cognitiveResult.recommendations) {
        console.log(`✅ 认知建议生成成功 (${cognitiveResult.recommendations.length}条建议)\n`);
        passedTests++;

        cognitiveResult.recommendations.forEach((r, i) => {
          console.log(`   ${i + 1}. [${r.priority}] ${r.title}`);
          console.log(`      ${r.description}`);
          console.log(`      动作: ${r.actions.join(', ')}`);
        });
      } else {
        console.log('❌ 认知建议生成失败\n');
        failedTests++;
      }
    } catch (error) {
      console.log(`❌ 认知建议生成失败: ${error.message}\n`);
      failedTests++;
    }

  } catch (error) {
    console.error(`❌ 测试过程中发生错误: ${error.message}`);
    console.error(error.stack);
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
    console.log('✨ Phase 3.3-2: 任务模式识别 + 用户行为画像 - 完成！');
  } else {
    console.log('⚠️  部分测试失败，需要修复');
  }
}

// 运行测试
runTests().catch(console.error);
