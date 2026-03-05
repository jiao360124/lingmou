/**
 * 检查策略引擎模块的方法名
 */

const fs = require('fs');
const path = require('path');

const strategyPath = path.join(__dirname, 'core', 'strategy');

console.log('=== 策略引擎模块方法名检查 ===\n');

fs.readdirSync(strategyPath).forEach(file => {
  if (file.endsWith('.js')) {
    try {
      const modulePath = path.join(strategyPath, file);
      const module = require(modulePath);

      // 获取类
      const Class = module.default || module;

      if (Class && typeof Class === 'function') {
        // 获取实例方法
        const methods = Object.getOwnPropertyNames(Class.prototype)
          .filter(name => name !== 'constructor' && typeof Class.prototype[name] === 'function');

        console.log(`=== ${file} ===`);
        console.log('方法:', methods.join(', '));
        console.log('');
      } else if (typeof module === 'object') {
        // 对于不是类的对象
        console.log(`=== ${file} ===`);
        console.log('导出类型: Object');
        console.log('属性:', Object.keys(module).join(', '));
        console.log('');
      }
    } catch (e) {
      console.log(`=== ${file} ===`);
      console.log('错误:', e.message);
      console.log('');
    }
  }
});
