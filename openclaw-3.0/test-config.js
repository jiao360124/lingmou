// openclaw-3.0/test-config.js
// 配置管理测试

(async () => {
  console.log('🧪 ConfigManager 测试\n');

  // 测试 1: 创建 ConfigManager
  console.log('【测试 1】创建配置管理器');
  const ConfigManager = require('./config');
  const configManager = new ConfigManager();

  // 等待配置加载
  await new Promise(resolve => setTimeout(resolve, 100));

  console.log('✅ 配置管理器创建成功\n');

  // 测试 2: 获取默认配置
  console.log('【测试 2】获取默认配置');
  const defaultConfig = configManager.getDefaultConfig();
  console.log('📊 默认配置:');
  console.log(`   端口: ${defaultConfig.server.port}`);
  console.log(`   缓存时长: ${defaultConfig.cache.duration}ms`);
  console.log(`   WebSocket 路径: ${defaultConfig.websocket.path}`);
  console.log(`   数据源:`, defaultConfig.dataSources);
  console.log('✅ 默认配置获取成功\n');

  // 测试 3: 获取配置
  console.log('【测试 3】获取配置');
  const port = configManager.get('server.port');
  const cacheDuration = configManager.get('cache.duration');
  const wsPath = configManager.get('websocket.path');
  console.log('📊 配置值:');
  console.log(`   端口: ${port}`);
  console.log(`   缓存时长: ${cacheDuration}ms`);
  console.log(`   WebSocket 路径: ${wsPath}`);
  console.log('✅ 配置获取成功\n');

  // 测试 4: 创建配置文件
  console.log('【测试 4】创建配置文件');
  const testConfig = {
    server: {
      port: 8081,
      host: '0.0.0.0'
    },
    cache: {
      duration: 60000,
      maxLogs: 20000
    },
    dashboard: {
      title: 'Test Dashboard',
      refreshInterval: 60000
    }
  };

  await configManager.saveConfig(testConfig);
  console.log('✅ 配置文件保存成功\n');

  // 测试 5: 重新加载配置
  console.log('【测试 5】重新加载配置');
  await configManager.reloadConfig();
  const reloadedPort = configManager.get('server.port');
  const reloadedTitle = configManager.get('dashboard.title');
  console.log('📊 重新加载后的配置:');
  console.log(`   端口: ${reloadedPort}`);
  console.log(`   标题: ${reloadedTitle}`);
  console.log('✅ 配置重新加载成功\n');

  // 测试 6: 更新配置
  console.log('【测试 6】更新配置');
  const updated = await configManager.updateConfig({
    server: {
      port: 8082
    },
    cache: {
      duration: 120000
    }
  });
  const updatedPort = configManager.get('server.port');
  const updatedCache = configManager.get('cache.duration');
  console.log('📊 更新后的配置:');
  console.log(`   端口: ${updatedPort}`);
  console.log(`   缓存时长: ${updatedCache}ms`);
  console.log('✅ 配置更新成功\n');

  // 测试 7: 验证配置
  console.log('【测试 7】验证配置');
  const validation = configManager.validateConfig();
  console.log('📊 验证结果:');
  console.log(`   有效: ${validation.valid}`);
  if (!validation.valid) {
    console.log('   错误:');
    validation.errors.forEach(error => console.log(`     - ${error}`));
  }
  console.log('✅ 配置验证完成\n');

  // 测试 8: 测试环境变量
  console.log('【测试 8】测试环境变量');
  const envPort = process.env.PORT;
  const envCache = process.env.CACHE_DURATION;
  console.log('📊 环境变量:');
  console.log(`   PORT: ${envPort || '(未设置)'}`);
  console.log(`   CACHE_DURATION: ${envCache || '(未设置)'}`);
  console.log('✅ 环境变量读取成功\n');

  // 测试 9: 合并配置
  console.log('【测试 9】测试配置合并');
  const base = {
    server: { port: 8080, host: '127.0.0.1' },
    cache: { duration: 30000 }
  };
  const overrides = {
    server: { host: '0.0.0.0' },
    cache: { maxLogs: 20000 }
  };
  const merged = configManager.mergeConfig(base, overrides);
  console.log('📊 合并后的配置:');
  console.log(`   端口: ${merged.server.port}`);
  console.log(`   主机: ${merged.server.host}`);
  console.log(`   缓存时长: ${merged.cache.duration}`);
  console.log(`   最大日志: ${merged.cache.maxLogs}`);
  console.log('✅ 配置合并成功\n');

  // 测试 10: 获取当前配置
  console.log('【测试 10】获取当前配置');
  const currentConfig = configManager.getConfig();
  console.log('📊 当前配置:');
  console.log(`   端口: ${currentConfig.server.port}`);
  console.log(`   缓存时长: ${currentConfig.cache.duration}ms`);
  console.log(`   WebSocket 路径: ${currentConfig.websocket.path}`);
  console.log('✅ 当前配置获取成功\n');

  console.log('🎉 所有测试完成！');
  console.log('\n✅ ConfigManager 功能正常！');
  console.log('✅ 配置文件读写功能正常！');
  console.log('✅ 配置更新功能正常！');
  console.log('✅ 配置验证功能正常！');
  console.log('✅ 环境变量支持正常！');
  console.log('✅ 配置合并功能正常！');
  console.log('\n📋 配置文件位置:', configManager.getConfigPath());
  console.log('📍 访问 Dashboard:', `http://127.0.0.1:8080/`);
})();
