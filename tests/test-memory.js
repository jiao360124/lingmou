const MemoryMonitor = require('./memory-monitor');

console.log('测试 forceGC 方法:');
const mm = new MemoryMonitor();
console.log('forceGC 类型:', typeof mm.forceGC);

console.log('\n运行 forceGC:');
const result = mm.forceGC();
console.log('结果:', result);

console.log('\n测试其他方法...');
mm.recordMemoryUsage('test');
const stats = mm.getStatistics();
console.log('统计数据:', stats);

console.log('\n测试完成！');
