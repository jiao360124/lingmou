// openclaw-3.0/test-dynamic-primary-switcher.js
// 动态主模型切换系统测试

const DynamicPrimarySwitcher = require('./core/dynamic-primary-switcher');

console.log('🧪 动态主模型切换系统测试\n');

const switcher = new DynamicPrimarySwitcher({
  zaiHealthThreshold: 50,
  recoveryThreshold: 80
});

// 测试 1: 初始化
console.log('【测试 1】初始化检查');
console.log(`✅ 当前主模型: ${switcher.primaryModel}`);
console.log(`✅ 备用模型: ${switcher.backupModel}`);
console.log(`✅ 切换次数: ${switcher.switchCount}`);
console.log(`✅ 是否切换: ${switcher.isSwitched}`);
console.log('');

// 测试 2: Tier 映射（正常模式）
console.log('【测试 2】Tier 映射（正常模式）');
const normalMapping = switcher.getTierMapping();
console.log(JSON.stringify(normalMapping, null, 2));
console.log('');

// 测试 3: 更新 ZAI 健康度（低于阈值，应该切换）
console.log('【测试 3】ZAI 健康度 < 50%（应该切换到 Trinity）');
switcher.updateZAIHealth(45);
console.log(`✅ ZAI 健康度: ${switcher.zaiHealth}%`);
console.log(`✅ 当前主模型: ${switcher.primaryModel}`);
console.log(`✅ 是否切换: ${switcher.isSwitched}`);
const emergencyMapping = switcher.getTierMapping();
console.log('Tier 映射（紧急模式）:');
console.log(JSON.stringify(emergencyMapping, null, 2));
console.log('');

// 测试 4: 记录 ZAI 成功（应该恢复）
console.log('【测试 4】ZAI 健康度 > 80%（应该恢复到 ZAI）');
switcher.recordZAISuccess();
console.log(`✅ ZAI 健康度: ${switcher.zaiHealth}%`);
console.log(`✅ 当前主模型: ${switcher.primaryModel}`);
console.log(`✅ 是否切换: ${switcher.isSwitched}`);
console.log('');

// 测试 5: 再次降低 ZAI 健康度（应该保持切换）
console.log('【测试 5】ZAI 健康度 < 50%（保持切换状态）');
switcher.updateZAIHealth(40);
console.log(`✅ ZAI 健康度: ${switcher.zaiHealth}%`);
console.log(`✅ 当前主模型: ${switcher.primaryModel}`);
console.log(`✅ 是否切换: ${switcher.isSwitched}`);
console.log('');

// 测试 6: 记录多次 ZAI 成功（应该恢复）
console.log('【测试 6】多次 ZAI 成功（应该恢复到 ZAI）');
for (let i = 0; i < 10; i++) {
  switcher.recordZAISuccess();
}
console.log(`✅ ZAI 健康度: ${switcher.zaiHealth}%`);
console.log(`✅ 当前主模型: ${switcher.primaryModel}`);
console.log(`✅ 是否切换: ${switcher.isSwitched}`);
console.log('');

// 测试 7: 获取状态
console.log('【测试 7】获取完整状态');
const status = switcher.getStatus();
console.log(JSON.stringify(status, null, 2));
console.log('');

// 测试 8: 获取切换历史
console.log('【测试 8】获取切换历史');
const history = switcher.getSwitchHistory(5);
console.log('最近 5 次切换:');
history.forEach((h, i) => {
  console.log(`  ${i + 1}. ${h.from} → ${h.to} (${h.reason})`);
});
console.log('');

// 测试 9: 获取健康度报告
console.log('【测试 9】获取健康度报告');
const report = switcher.getHealthReport();
console.log(JSON.stringify(report, null, 2));
console.log('');

// 测试 10: 模拟故障链（ZAI 失败 → 切换 → 继续失败 → 恢复）
console.log('【测试 10】模拟真实故障链');
switcher.updateZAIHealth(100);
console.log(`Step 1: ZAI 健康度 100%，当前主模型 ${switcher.primaryModel}`);
switcher.updateZAIHealth(30);
console.log(`Step 2: ZAI 健康度 30%，切换到 Trinity`);
switcher.recordZAIFailure();
console.log(`Step 3: ZAI 失败 1 次，健康度 ${switcher.zaiHealth}%`);
switcher.recordZAIFailure();
console.log(`Step 4: ZAI 失败 2 次，健康度 ${switcher.zaiHealth}%`);
switcher.recordZAIFailure();
console.log(`Step 5: ZAI 失败 3 次，健康度 ${switcher.zaiHealth}%`);
switcher.recordZAIFailure();
console.log(`Step 6: ZAI 失败 4 次，健康度 ${switcher.zaiHealth}%`);
switcher.recordZAIFailure();
console.log(`Step 7: ZAI 失败 5 次，健康度 ${switcher.zaiHealth}%`);
console.log(`Step 8: 当前主模型 ${switcher.primaryModel}（仍在 Trinity）`);
console.log(`Step 9: ZAI 成功 1 次，健康度 ${switcher.zaiHealth}%`);
console.log(`Step 10: ZAI 成功 2 次，健康度 ${switcher.zaiHealth}%`);
console.log(`Step 11: ZAI 成功 3 次，健康度 ${switcher.zaiHealth}%`);
console.log(`Step 12: ZAI 健康度 > 80%，恢复到 ZAI`);
console.log(`Final: 当前主模型 ${switcher.primaryModel}（已恢复）`);
console.log('');

// 测试 11: 手动控制
console.log('【测试 11】手动控制');
console.log(`Step 1: 当前模式 ${switcher.isSwitched ? '紧急' : '正常'}`);
switcher.setMode('emergency');
console.log(`Step 2: 切换到紧急模式，当前主模型 ${switcher.primaryModel}`);
switcher.setMode('normal');
console.log(`Step 3: 切换回正常模式，当前主模型 ${switcher.primaryModel}`);
console.log('');

// 测试 12: 强制切换
console.log('【测试 12】强制切换');
console.log(`Step 1: 当前主模型 ${switcher.primaryModel}`);
switcher.forceSwitch('Trinity');
console.log(`Step 2: 强制切换到 Trinity，当前主模型 ${switcher.primaryModel}`);
switcher.forceSwitchBack();
console.log(`Step 3: 强制恢复到 ZAI，当前主模型 ${switcher.primaryModel}`);
console.log('');

// 测试 13: 导出配置
console.log('【测试 13】导出配置');
const config = switcher.exportConfig();
console.log(JSON.stringify(config, null, 2));
console.log('');

console.log('🎉 所有测试完成！');
