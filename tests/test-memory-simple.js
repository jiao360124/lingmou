const MemoryMonitor = require('./memory-monitor');

console.log('测试 forceGC 方法:');
const mm = new MemoryMonitor();
console.log('类型:', typeof mm.forceGC);
console.log('名称:', mm.forceGC ? mm.forceGC.name : 'undefined');

console.log('\n测试其他方法:');
console.log('- getCurrentMemoryUsage:', typeof mm.getCurrentMemoryUsage);
console.log('- recordMemoryUsage:', typeof mm.recordMemoryUsage);
console.log('- getStatistics:', typeof mm.getStatistics);
