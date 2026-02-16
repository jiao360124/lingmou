const StrategyEngine = require('./core/strategy-engine');

const engine = new StrategyEngine();

console.log('🧪 测试 Strategy Engine');
const strategies = engine.simulateScenarios({}, {});
console.log('生成了', strategies.length, '个策略');
console.log('第一个策略:', strategies[0].type);
