const ROIEngine = require('./economy/roiEngine');

console.log('测试ROIEngine...');

try {
  const roiEngine = new ROIEngine();
  console.log('✅ ROIEngine初始化成功');
  console.log('Metrics:', JSON.stringify(roiEngine.metrics, null, 2));

  const suggestions = [
    { priority: 'high', action: '增加Token预算压缩频率', message: '成本未达标' },
    { priority: 'medium', action: '优化429重试策略', message: '错误率过高' }
  ];

  console.log('\n测试rankSuggestions...');
  const roiList = roiEngine.rankSuggestions(suggestions);
  console.log('✅ ROI列表生成成功');
  console.log('ROI数量:', roiList.length);
  console.log('ROI列表:', JSON.stringify(roiList, null, 2));

  console.log('\n测试generateSummary...');
  const summary = roiEngine.generateSummary(roiList);
  console.log('✅ 摘要生成成功');
  console.log(summary);

  console.log('\n🎉 ROIEngine测试通过！');
} catch (error) {
  console.error('❌ ROIEngine测试失败:', error.message);
  console.error(error.stack);
}
