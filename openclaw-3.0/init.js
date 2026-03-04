// openclaw-3.0/init.js
// 初始化脚本

const fs = require('fs-extra');
const path = require('path');

console.log('🚀 OpenClaw 3.0 初始化中...\n');

// 1. 创建目录结构
const dirs = [
  'core',
  'economy',
  'objective',
  'value',
  'metrics',
  'data',
  'templates',
  'reports',
  'logs'
];

console.log('📁 创建目录结构...');
for (const dir of dirs) {
  fs.ensureDirSync(path.join(__dirname, dir));
  console.log(`  ✅ ${dir}/`);
}

// 2. 创建初始数据文件
console.log('\n📄 创建初始数据文件...');

const initialData = {
  goals: {
    longTerm: {
      title: "降低30% API成本",
      current: 5,
      target: -30,
      unit: "%"
    },
    monthly: {
      title: "自动恢复率 >90%",
      current: 87,
      target: 90,
      unit: "%"
    },
    daily: {
      title: "优化429退避策略",
      current: 0,
      target: 1,
      unit: "条"
    }
  },
  metrics: {
    dailyTokens: 0,
    totalTokens: 0,
    cost: 0,
    successCount: 0,
    errorCount: 0,
    recoveryRate: 876,
    avgContextSize: 1200,
    templatesGenerated: 0,
    nightlyTasksExecuted: 0,
    costReduction: 5,
    dailyOptimizations: 0,
    lastUpdated: new Date().toISOString()
  }
};

fs.writeJSONSync(path.join(__dirname, 'data/metrics.json'), initialData.metrics, { spaces: 2 });
console.log('  ✅ data/metrics.json');

fs.writeJSONSync(path.join(__dirname, 'data/goals.json'), initialData.goals, { spaces: 2 });
console.log('  ✅ data/goals.json');

fs.writeJSONSync(path.join(__dirname, 'data/token-governor.json'), {
  todayUsage: 0,
  costToday: 0,
  lastReset: new Date().toDateString(),
  modelUsage: { cheap: 0, mid: 0, high: 0 }
}, { spaces: 2 });
console.log('  ✅ data/token-governor.json');

// 3. 创建示例模板
console.log('\n📄 创建示例模板...');

const templates = {
  'token_saver.md': `# Token节省策略

## 背景
需要减少API调用中的Token使用量

## 实施步骤
1. 启用上下文摘要
2. 减少冗余调用
3. 使用便宜模型

## 预期效果
- 降低30% Token使用
- 节省30% API成本

## 验证方法
- 每日Token统计
- 成本分析
`,
  'recovery_optimization.md': `# 自动恢复优化

## 优化内容
1. 增强错误检测
2. 优化重试策略
3. 增加降级机制

## 实施方案
- 实施指数退避重试
- 增加自动恢复脚本
- 建立监控告警

## 目标
- 自动恢复率 >90%
`,
  '429_optimization.md': `# 429错误优化

## 问题描述
API调用频繁遇到429错误

## 优化方案
1. 实施指数退避重试
2. 智能排队机制
3. 速率限制监控

## 实施细节
- 重试次数: 5次
- 初始延迟: 1秒
- 最大延迟: 60秒
- 退避算法: 指数退避

## 预期效果
- 减少429错误
- 提升成功率
- 优化用户体验
`,
  'api_optimization.md': `# API优化模板

## 优化内容
1. ...
2. ...

## 实施步骤
1. ...
2. ...

## 预期效果
- ...
`,
  'error_handling.md': `# 错误处理模板

## 错误分类
1. 网络错误
2. API错误
3. 业务错误

## 处理策略
1. ...
2. ...
`
};

for (const [name, content] of Object.entries(templates)) {
  fs.writeFileSync(path.join(__dirname, 'templates', name), content);
  console.log(`  ✅ templates/${name}`);
}

// 4. 创建README
console.log('\n📄 创建README...');
const readme = `# OpenClaw 3.0 - Node.js落地架构

## 🎉 欢迎使用OpenClaw 3.0！

### 核心功能
✅ 429自动排队
✅ 会话摘要（省30% token）
✅ Token Governor（省钱）
✅ Objective Engine（进化核心）
✅ Gap Analyzer（分析差距）
✅ Value Mining（夜间生成模板）
✅ 自动回滚机制

### 快速开始
\`\`\`bash
npm install
npm start
\`\`\`

### 监控
访问 http://localhost:18789 查看Dashboard

### 日志
查看 logs/openclaw-3.0.log

## 📊 成功标准
运行30天后:
- ✅ Token ↓30%
- ✅ 自动恢复率 >90%
- ✅ ≥5个可复用模板
- ✅ 夜间自动优化 ≥5次
- ✅ 成本趋势稳定下降

## 🎯 文件结构
\`\`\`
openclaw-3.0/
├── core/              # 核心模块
├── economy/           # 经济模块
├── objective/         # 目标引擎
├── value/             # 价值挖掘
├── metrics/           # 指标追踪
├── data/              # 数据存储
├── templates/         # 可复用模板
└── index.js           # 主入口
\`\`\`

---

**版本**: 3.0.0
**作者**: AgentX2026
**日期**: 2026-02-14
`;

fs.writeFileSync(path.join(__dirname, 'README.md'), readme);
console.log('  ✅ README.md');

console.log('\n✅ OpenClaw 3.0 初始化完成！');
console.log('\n🚀 现在可以运行: npm start\n');
