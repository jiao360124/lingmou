// test-unified-integration.js
// V3.0 + V3.2 完全集成测试

const UnifiedIndex = require('./core/unified-index');

console.log('🚀 开始测试 V3.0 + V3.2 完全集成...\n');

const config = {
  dailyBudget: 200000,
  validationDays: 3,
  maxRequestsPerMinute: 60,
  checkInterval: 60000
};

// 创建统一索引
const unified = new UnifiedIndex(config);

// 初始化系统
unified.initialize()
  .then(async (result) => {
    console.log('\n✅ 系统初始化成功!\n');

    // 获取系统状态
    const status = unified.getStatus();
    console.log('📊 系统状态:', JSON.stringify(status, null, 2));
    console.log('');

    // 测试1: 测试性能监控
    console.log('🧪 测试1: 性能监控模块');
    const PerformanceMonitor = require('./core/performance-monitor');
    const pm = new PerformanceMonitor();
    pm.recordCall(1200, true);
    pm.recordCall(2500, true);
    pm.recordCall(1800, false);
    pm.recordCall(3200, true);
    pm.recordCall(1500, true);
    pm.check();
    const perfStats = pm.getStatus();
    console.log('✅ 性能监控测试通过:', perfStats);
    console.log('');

    // 测试2: 测试内存监控
    console.log('🧪 测试2: 内存监控模块');
    const MemoryMonitor = require('./core/memory-monitor');
    const mm = new MemoryMonitor();
    mm.check();
    const memStats = mm.getStatus();
    console.log('✅ 内存监控测试通过:', memStats);
    console.log('');

    // 测试3: 测试API追踪
    console.log('🧪 测试3: API追踪模块');
    const APITracker = require('./core/api-tracker');
    const api = new APITracker();
    api.recordCall('glm-4', '/chat/completions', true, 1500);
    api.recordCall('glm-4', '/chat/completions', true, 2000);
    api.recordCall('glm-4', '/chat/completions', false, 3000, 'timeout');
    api.recordCall('glm-4.5', '/chat/completions', true, 1200);
    api.recordCall('glm-4.5', '/chat/completions', true, 1800);
    const apiStats = api.getStatus();
    console.log('✅ API追踪测试通过:', {
      successRate: apiStats.successRate,
      errorRate: apiStats.errorRate,
      avgLatency: apiStats.avgLatency,
      modelStats: apiStats.modelStats
    });
    console.log('');

    // 测试4: 测试策略引擎
    console.log('🧪 测试4: 策略引擎');
    const StrategyEngine = require('./core/strategy-engine');
    const se = new StrategyEngine();
    const context = {
      taskType: 'optimization',
      priority: 'high',
      urgency: 'high',
      budget: 'normal'
    };
    const advice = se.getStrategyAdvice(context);
    console.log('✅ 策略引擎测试通过:', JSON.stringify(advice, null, 2));
    console.log('');

    // 测试5: 测试认知层
    console.log('🧪 测试5: 认知层');
    const CognitiveLayer = require('./core/cognitive-layer');
    const cl = new CognitiveLayer();
    const taskPattern = cl.getTaskPatternTypes();
    const userProfile = cl.getDominantBehaviorStyles();
    console.log('✅ 认知层测试通过:', {
      taskPattern: Object.keys(taskPattern),
      userProfile: userProfile
    });
    console.log('');

    // 测试6: 测试差异回滚引擎
    console.log('🧪 测试6: 差异回滚引擎');
    const RollbackEngine = require('./core/rollback-engine');
    // 测试配置对比
    const currentConfig = { dailyBudget: 200000, validationDays: 3 };
    const newConfig = { dailyBudget: 250000, validationDays: 3, newFeature: true };
    const diff = RollbackEngine.compareConfigs(newConfig);
    console.log('✅ 差异回滚测试通过:', {
      added: Object.keys(diff.added),
      removed: Object.keys(diff.removed),
      modified: Object.keys(diff.modified)
    });
    console.log('');

    // 测试7: 测试System Memory Layer
    console.log('🧪 测试7: System Memory Layer');
    const SystemMemoryLayer = require('./core/system-memory');
    const systemMemory = SystemMemoryLayer;
    systemMemory.recordOptimization({ type: 'strategy', timestamp: Date.now() });
    const stats = systemMemory.getOptimizationSummary();
    console.log('✅ System Memory Layer测试通过:', stats);
    console.log('');

    // 测试8: 测试Watchdog
    console.log('🧪 测试8: Watchdog守护线程');
    const Watchdog = require('./core/watchdog');
    const watchdog = new Watchdog(config);
    const wdStatus = await watchdog.check();
    console.log('✅ Watchdog测试通过:', wdStatus);
    console.log('');

    // 测试9: 测试Nightly Worker
    console.log('🧪 测试9: Nightly Worker');
    const NightlyWorker = require('./core/nightly-worker');
    const nw = new NightlyWorker(config);
    const hasBudget = nw.hasBudget({ type: 'strategy', estimatedTokens: 5000 });
    console.log('✅ Nightly Worker测试通过:', {
      hasBudget,
      budgetInfo: nw.getBudgetInfo()
    });
    console.log('');

    // 测试10: 测试架构审计
    console.log('🧪 测试10: 架构审计');
    const ArchitectureAuditor = require('./core/architecture-auditor');
    const auditor = new ArchitectureAuditor();
    const auditResult = auditor.audit();
    console.log('✅ 架构审计测试通过:', {
      couplingDegree: auditResult.couplingDegree.toFixed(3),
      redundancyRatio: auditResult.redundancyRatio.toFixed(2) + '%',
      performanceHotspots: auditResult.performanceHotspots.length
    });
    console.log('');

    // 关闭系统
    await unified.shutdown();

    console.log('═════════════════════════════════════════════════════════════');
    console.log('✅ 所有测试完成!');
    console.log('═════════════════════════════════════════════════════════════\n');

    process.exit(0);
  })
  .catch(error => {
    console.error('❌ 测试失败:', error);
    process.exit(1);
  });
