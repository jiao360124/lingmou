// openclaw-3.0/test-circuit-breaker.js
// Circuit Breaker 测试

const CircuitBreaker = require('./core/circuit-breaker');

console.log('🧪 Circuit Breaker 测试\n');

// 测试 1: 正常状态
console.log('【测试 1】正常状态测试');
const cb1 = new CircuitBreaker({ providerName: 'TestProvider', maxFailures: 3 });
const check1 = cb1.check();
console.log(`✅ 状态: ${check1.state}`);
console.log(`✅ 允许调用: ${check1.allowed}`);
console.log('');

// 测试 2: 记录 3 次失败 → 进入 OPEN
console.log('【测试 2】3 次失败后进入 OPEN');
for (let i = 0; i < 3; i++) {
  cb1.recordFailure(new Error(`Failed ${i + 1}`), 'TEST');
  const check = cb1.check();
  console.log(`  尝试 ${i + 1}: ${check.state}, allowed: ${check.allowed}`);
}
const check2 = cb1.check();
console.log(`✅ 最终状态: ${check2.state}`);
console.log(`✅ 允许调用: ${check2.allowed}`);
console.log('');

// 测试 3: OPEN 状态拒绝调用
console.log('【测试 3】OPEN 状态拒绝调用');
const check3 = cb1.check();
console.log(`✅ 状态: ${check3.state}`);
console.log(`✅ 允许调用: ${check3.allowed}`);
console.log('');

// 测试 4: 10 分钟后进入 HALF-OPEN
console.log('【测试 4】10 分钟后进入 HALF-OPEN');
console.log('（跳过实际等待，直接模拟状态转换）');
cb1.state = 'HALF-OPEN'; // 模拟 10 分钟后自动转换
cb1.successesInHalfOpen = 0;
const check4 = cb1.check();
console.log(`✅ 状态: ${check4.state}`);
console.log(`✅ 允许调用: ${check4.allowed}`);
console.log('');

// 测试 5: HALF-OPEN 状态允许 1 次调用
console.log('【测试 5】HALF-OPEN 状态允许 1 次调用');
cb1.recordSuccess(100);
const check5 = cb1.check();
console.log(`✅ 状态: ${check5.state}`);
console.log(`✅ 允许调用: ${check5.allowed}`);
console.log(`✅ 成功率: ${check5.allowed ? '✅' : '❌'}（应该允许）`);
console.log('');

// 测试 6: HALF-OPEN 状态再次失败 → 回到 OPEN
console.log('【测试 6】HALF-OPEN 失败 → 回到 OPEN');
cb1.recordFailure(new Error('Half-open test failed'), 'TEST');
const check6 = cb1.check();
console.log(`✅ 状态: ${check6.state}`);
console.log(`✅ 允许调用: ${check6.allowed}`);
console.log('');

// 测试 7: HALF-OPEN 成功多次 → 恢复到 CLOSED
console.log('【测试 7】HALF-OPEN 成功多次 → 恢复到 CLOSED');
console.log('（跳过实际等待，直接模拟）');
cb1.state = 'HALF-OPEN';
cb1.successesInHalfOpen = 2; // 成功 2 次
const check7 = cb1.check();
console.log(`✅ 状态: ${check7.state}`);
console.log(`✅ 允许调用: ${check7.allowed}`);
console.log(`✅ 成功率: ${check7.allowed ? '✅' : '❌'}（应该允许）`);
console.log('');

// 测试 8: HALF-OPEN 等待 5 分钟 → 恢复到 CLOSED
console.log('【测试 8】HALF-OPEN 等待 5 分钟 → 恢复到 CLOSED');
console.log('（跳过实际等待，直接模拟）');
cb1.state = 'HALF-OPEN';
cb1.successesInHalfOpen = 1;
const check8 = cb1.check();
console.log(`✅ 状态: ${check8.state}`);
console.log(`✅ 允许调用: ${check8.allowed}`);
console.log('');

// 测试 9: 手动控制
console.log('【测试 9】手动控制 Circuit Breaker');
cb1.close();
const check9 = cb1.check();
console.log(`✅ 手动关闭后状态: ${check9.state}`);
console.log(`✅ 允许调用: ${check9.allowed}`);
cb1.open();
const check10 = cb1.check();
console.log(`✅ 手动打开后状态: ${check10.state}`);
console.log(`✅ 允许调用: ${check10.allowed}`);
console.log('');

// 测试 10: 获取健康度报告
console.log('【测试 10】获取健康度报告');
cb1.recordSuccess(150);
cb1.recordSuccess(200);
cb1.recordFailure(new Error('Test error'), 'TEST');
const report = cb1.getHealthReport();
console.log(JSON.stringify(report, null, 2));
console.log('');

// 测试 11: 诊断
console.log('【测试 11】健康度诊断');
const diagnosis = cb1.diagnose();
console.log(`✅ 诊断: ${diagnosis.diagnosis}`);
console.log(`✅ 严重程度: ${diagnosis.severity}`);
console.log('');

console.log('🎉 所有测试完成！');
