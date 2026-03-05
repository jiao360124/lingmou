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
      delete require.cache[require.resolve(modulePath)];

      const module = require(modulePath);

      // 获取类或对象
      const Class = module.default || module;

      // 获取方法名
      const methods = Object.getOwnPropertyNames(Object.getPrototypeOf(Class))
        .filter(name => name !== 'constructor' && typeof Class.prototype[name] === 'function');

      console.log(`=== ${file} ===`);
      console.log('方法:', methods.slice(0, 15).join(', '));
      console.log('');
    } catch (e) {
      console.log(`=== ${file} ===`);
      console.log('错误:', e.message);
      console.log('');
    }
  }
});
