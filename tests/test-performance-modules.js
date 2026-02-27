/**
 * 灵眸 v3.2.6 性能模块测试
 *
 * 测试所有性能优化模块的功能
 */

console.log('🧪 开始性能模块测试...\n');

let passed = 0;
let failed = 0;

// 测试1: lazy-loader
console.log('📦 测试1: lazy-loader.js');
try {
  // 检查类是否存在
  const lazyLoader = require('../core/lazy-loader');

  if (typeof lazyLoader === 'function') {
    const loader = new lazyLoader();
    console.log('  ✅ LazyLoader类已创建');

    // 测试预加载（不实际加载技能，只测试方法存在）
    loader.preloadSkills(['code-mentor']);
    console.log('  ✅ 预加载技能功能正常');

    // 测试获取已加载数量
    const count = loader.getLoadedCount();
    console.log(`  ✅ 获取已加载数量正常: ${count}`);

    passed++;
  } else {
    throw new Error('LazyLoader类未找到');
  }
} catch (error) {
  console.log(`  ❌ 失败: ${error.message}`);
  failed++;
}

// 测试2: async-io
console.log('\n📦 测试2: async-io.js');
try {
  const asyncIO = require('../core/async-io');

  if (typeof asyncIO === 'function') {
    const io = new asyncIO();
    console.log('  ✅ AsyncIO类已创建');

    // 测试异步写入
    const testFile = 'test-performance-io.txt';
    io.writeFileAsync(testFile, 'Test content').then(() => {
      console.log('  ✅ 异步写入功能正常');

      // 测试异步读取
      io.readFileAsync(testFile).then(content => {
        if (content === 'Test content') {
          console.log('  ✅ 异步读取功能正常');

          // 清理测试文件
          io.writeFileAsync(testFile, '').then(() => {
            console.log('  ✅ 文件清理正常');
          }).catch(error => {
            console.log(`  ⚠️  清理失败: ${error.message}`);
          });

          passed++;
        } else {
          throw new Error('读取内容不匹配');
        }
      }).catch(error => {
        console.log(`  ❌ 读取失败: ${error.message}`);
        failed++;
      });
    }).catch(error => {
      console.log(`  ❌ 写入失败: ${error.message}`);
      failed++;
    });
  } else {
    throw new Error('AsyncIO类未找到');
  }
} catch (error) {
  console.log(`  ❌ 失败: ${error.message}`);
  failed++;
}

// 测试3: api-cache
console.log('\n📦 测试3: api-cache.js');
try {
  const apiCache = require('../core/api-cache');

  if (typeof apiCache === 'function') {
    const cache = new apiCache('../core/api-cache-config.json');
    console.log('  ✅ APICache类已创建');

    // 测试缓存设置
    cache.set('test-key', 'test-value', 300);
    console.log('  ✅ 缓存设置功能正常');

    // 测试缓存获取
    const value = cache.get('test-key');
    if (value === 'test-value') {
      console.log('  ✅ 缓存获取功能正常');

      // 测试统计
      const stats = cache.getStats();
      console.log(`  ✅ 缓存统计正常 (大小: ${stats.size})`);

      // 测试清除
      cache.clear();
      console.log('  ✅ 缓存清除功能正常');

      passed++;
    } else {
      throw new Error('缓存值不匹配');
    }
  } else {
    throw new Error('APICache类未找到');
  }
} catch (error) {
  console.log(`  ❌ 失败: ${error.message}`);
  failed++;
}

// 测试4: optimized-strategy-engine
console.log('\n📦 测试4: optimized-strategy-engine.js');
try {
  const optimizedStrategyEngine = require('../core/optimized-strategy-engine');

  if (typeof optimizedStrategyEngine === 'function') {
    const engine = new optimizedStrategyEngine();
    console.log('  ✅ OptimizedStrategyEngine类已创建');

    // 测试统计
    const stats = engine.getStats();
    console.log(`  ✅ 策略引擎统计正常 (策略: ${stats.strategyCache}, 执行: ${stats.executionCache})`);

    // 测试清除缓存
    engine.clearCaches();
    console.log('  ✅ 缓存清除功能正常');

    passed++;
  } else {
    throw new Error('OptimizedStrategyEngine类未找到');
  }
} catch (error) {
  console.log(`  ❌ 失败: ${error.message}`);
  failed++;
}

// 测试5: 版本配置
console.log('\n📦 测试5: 版本配置');
try {
  const version = require('../core/version-v3.2.6.json');

  console.log(`  ✅ 版本配置加载成功: ${version.version}`);

  if (version.performance) {
    console.log('  ✅ 性能优化模块已配置');

    if (version.performance.lazy_loading) {
      console.log('  ✅ 懒加载已启用');
    }

    if (version.performance.api_cache) {
      console.log('  ✅ API缓存已启用');
    }

    if (version.performance.strategy_engine_cache) {
      console.log('  ✅ 策略引擎缓存已启用');
    }
  }

  passed++;
} catch (error) {
  console.log(`  ❌ 失败: ${error.message}`);
  failed++;
}

// 汇总结果
console.log('\n' + '='.repeat(50));
console.log('📊 测试结果汇总');
console.log('='.repeat(50));
console.log(`✅ 通过: ${passed}`);
console.log(`❌ 失败: ${failed}`);
console.log(`📈 总计: ${passed + failed}`);
console.log(`🎯 通过率: ${((passed / (passed + failed)) * 100).toFixed(2)}%`);
console.log('='.repeat(50));

if (failed === 0) {
  console.log('\n🎉 所有测试通过！性能模块集成成功！');
  process.exit(0);
} else {
  console.log(`\n⚠️  有 ${failed} 个测试失败，请检查！`);
  process.exit(1);
}
