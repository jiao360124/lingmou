/**
 * OpenClaw v4.0 - 核心模块插件入口
 *
 * 将 core/strategy/ 和 core/monitoring/ 中的模块注册为 Agent Tools
 */

const fs = require('fs');
const path = require('path');

/**
 * 创建一个简单的插件包装器
 * 将 JS 模块注册为 Agent Tool
 */
function createPluginWrapper(moduleName, modulePath, description) {
  return {
    name: moduleName.replace(/-/g, '_'),
    description: description,
    parameters: {
      type: "object",
      properties: {},
      required: []
    },
    async execute(_id, params) {
      try {
        // 动态加载模块
        const module = require(modulePath);

        // 尝试获取实例或类
        const Class = module.default || module;
        const instance = new Class();

        // 尝试调用实例的 getStatus 方法获取状态
        if (typeof instance.getStatus === 'function') {
          const status = instance.getStatus();
          return {
            content: [{
              type: "text",
              text: JSON.stringify({
                success: true,
                module: moduleName,
                status: status
              }, null, 2)
            }]
          };
        }

        return {
          content: [{
            type: "text",
            text: JSON.stringify({
              success: true,
              module: moduleName,
              message: "模块已加载，实例化成功"
            }, null, 2)
          }]
        };
      } catch (error) {
        return {
          content: [{
            type: "text",
            text: JSON.stringify({
              success: false,
              module: moduleName,
              error: error.message,
              stack: error.stack
            }, null, 2)
          }]
        };
      }
    }
  };
}

/**
 * 主函数：注册所有核心模块为 Agent Tools
 */
module.exports = function(api) {
  console.log('🎯 OpenClaw v4.0 核心模块插件初始化...');

  // 监控模块
  const monitoringPath = path.join(__dirname, 'monitoring');

  if (fs.existsSync(monitoringPath)) {
    console.log('📦 发现监控模块目录');

    const monitoringModules = fs.readdirSync(monitoringPath)
      .filter(f => f.endsWith('.js') && f !== 'index.js')
      .map(f => f.replace('.js', ''));

    monitoringModules.forEach(moduleName => {
      try {
        const modulePath = path.join(monitoringPath, `${moduleName}.js`);
        const moduleContent = fs.readFileSync(modulePath, 'utf-8');

        // 提取模块描述
        const descMatch = moduleContent.match(/\/\/.*?(?:\n|$)/g) || [];
        const description = descMatch.slice(0, 5).join('\n').trim();

        const tool = createPluginWrapper(
          `monitoring_${moduleName}`,
          modulePath,
          description
        );

        api.registerTool(tool);
        console.log(`✅ 已注册: monitoring_${moduleName}`);
      } catch (error) {
        console.error(`❌ 注册失败: monitoring_${moduleName}`, error.message);
      }
    });
  }

  // 策略引擎模块
  const strategyPath = path.join(__dirname, 'strategy');

  if (fs.existsSync(strategyPath)) {
    console.log('📦 发现策略引擎模块目录');

    const strategyModules = fs.readdirSync(strategyPath)
      .filter(f => f.endsWith('.js') && f !== 'index.js')
      .map(f => f.replace('.js', ''));

    strategyModules.forEach(moduleName => {
      try {
        const modulePath = path.join(strategyPath, `${moduleName}.js`);
        const moduleContent = fs.readFileSync(modulePath, 'utf-8');

        // 提取模块描述
        const descMatch = moduleContent.match(/\/\/.*?(?:\n|$)/g) || [];
        const description = descMatch.slice(0, 5).join('\n').trim();

        const tool = createPluginWrapper(
          `strategy_${moduleName}`,
          modulePath,
          description
        );

        api.registerTool(tool);
        console.log(`✅ 已注册: strategy_${moduleName}`);
      } catch (error) {
        console.error(`❌ 注册失败: strategy_${moduleName}`, error.message);
      }
    });
  }

  console.log('✅ OpenClaw v4.0 核心模块插件初始化完成\n');
};
