/**
 * Chart Service
 * 生成图表数据
 */

/**
 * 获取成本数据
 */
async function getCostData() {
  return {
    labels: ['周一', '周二', '周三', '周四', '周五', '周六', '周日'],
    values: [10, 12, 11, 15, 14, 8, 9],
    current: 11,
    unit: 'Tokens'
  };
}

/**
 * 获取模型数据
 */
async function getModelData() {
  return {
    labels: ['glm-4.7-flash', 'gpt-4', 'claude-3', 'gemini-pro'],
    values: [45, 30, 15, 10],
    current: 35,
    unit: 'Count'
  };
}

/**
 * 获取Fallback数据
 */
async function getFallbackData() {
  return {
    labels: ['周一', '周二', '周三', '周四', '周五', '周六', '周日'],
    values: [2, 3, 2, 5, 4, 1, 2],
    current: 3,
    unit: 'Count'
  };
}

/**
 * 获取延迟数据
 */
async function getLatencyData() {
  return {
    labels: ['周一', '周二', '周三', '周四', '周五', '周六', '周日'],
    values: [50, 55, 45, 60, 58, 52, 48],
    current: 54,
    unit: 'ms'
  };
}

/**
 * 生成图表HTML
 */
function generateChartHTML(chartType, data) {
  const chartConfigs = {
    line: generateLineChart(data),
    pie: generatePieChart(data),
    bar: generateBarChart(data),
    histogram: generateHistogram(data)
  };

  return chartConfigs[chartType] || chartConfigs.line;
}

/**
 * 生成折线图HTML
 */
function generateLineChart(data) {
  const { labels, values, current, unit } = data;

  const points = values.map((value, index) => {
    const x = (index / (values.length - 1)) * 100;
    const y = 100 - (value / Math.max(...values)) * 80;
    return `<circle cx="${x}%" cy="${y}%" r="6" fill="#3b82f6" />
            <text x="${x}%" y="${y - 15}" text-anchor="middle" fill="#3b82f6" font-size="12">${value}</text>`;
  }).join('\n');

  const labelsHTML = labels.map(label =>
    `<text x="${100 / labels.length / 2}%" y="${100}" text-anchor="middle" fill="#6b7280" font-size="12">${label}</text>`
  ).join('\n');

  return `
    <svg width="100%" height="200" viewBox="0 0 600 200">
      <!-- 网格线 -->
      <line x1="50" y1="30" x2="550" y2="30" stroke="#e5e7eb" stroke-dasharray="4"/>
      <line x1="50" y1="75" x2="550" y2="75" stroke="#e5e7eb" stroke-dasharray="4"/>
      <line x1="50" y1="120" x2="550" y2="120" stroke="#e5e7eb" stroke-dasharray="4"/>
      <line x1="50" y1="165" x2="550" y2="165" stroke="#e5e7eb" stroke-dasharray="4"/>

      <!-- 数据点 -->
      ${points}

      <!-- 当前值标记 -->
      <text x="550" y="20" fill="#ef4444" font-size="14" font-weight="bold">当前: ${current} ${unit}</text>

      <!-- X轴标签 -->
      ${labelsHTML}
    </svg>
  `;
}

/**
 * 生成饼图HTML
 */
function generatePieChart(data) {
  const { labels, values } = data;
  const total = values.reduce((a, b) => a + b, 0);
  let startAngle = 0;

  const slices = labels.map((label, index) => {
    const sliceAngle = (values[index] / total) * 360;
    const endAngle = startAngle + sliceAngle;
    const midAngle = (startAngle + endAngle) / 2;

    const x1 = 100 + 80 * Math.cos(midAngle * Math.PI / 180);
    const y1 = 100 + 80 * Math.sin(midAngle * Math.PI / 180);
    const x2 = 100 + 80 * Math.cos((startAngle + sliceAngle / 2) * Math.PI / 180);
    const y2 = 100 + 80 * Math.sin((startAngle + sliceAngle / 2) * Math.PI / 180);

    const color = ['#3b82f6', '#10b981', '#f59e0b', '#ef4444'][index % 4];

    startAngle = endAngle;

    return `<path d="M100,100 L${x1},${y1} A80,80 0 ${sliceAngle > 180 ? 1 : 0},1 ${x2},${y2} Z" fill="${color}" />
            <text x="${x1}" y="${y1}" text-anchor="middle" fill="white" font-size="10">${values[index]}</text>`;
  }).join('\n');

  return `
    <svg width="100%" height="200" viewBox="0 0 200 200">
      ${slices}
      <text x="100" y="100" text-anchor="middle" fill="#6b7280" font-size="12">Pie Chart</text>
    </svg>
  `;
}

/**
 * 生成柱状图HTML
 */
function generateBarChart(data) {
  const { labels, values, current, unit } = data;
  const maxValue = Math.max(...values);
  const barWidth = 60 / values.length;

  const bars = values.map((value, index) => {
    const height = (value / maxValue) * 150;
    const x = index * barWidth + (barWidth - 20) / 2;
    const color = ['#3b82f6', '#10b981', '#f59e0b', '#ef4444'][index % 4];

    return `<rect x="${x}" y="${150 - height}" width="20" height="${height}" fill="${color}" rx="3" />
            <text x="${x + 10}" y="${150 - height - 5}" text-anchor="middle" fill="#6b7280" font-size="10">${value}</text>`;
  }).join('\n');

  return `
    <svg width="100%" height="200" viewBox="0 0 600 200">
      <!-- 网格线 -->
      <line x1="30" y1="30" x2="570" y2="30" stroke="#e5e7eb"/>
      <line x1="30" y1="75" x2="570" y2="75" stroke="#e5e7eb"/>
      <line x1="30" y1="120" x2="570" y2="120" stroke="#e5e7eb"/>
      <line x1="30" y1="165" x2="570" y2="165" stroke="#e5e7eb"/>

      <!-- 柱状图 -->
      ${bars}

      <!-- 当前值 -->
      <text x="550" y="20" fill="#ef4444" font-size="14" font-weight="bold">当前: ${current} ${unit}</text>

      <!-- X轴标签 -->
      ${labels.map((label, index) =>
        `<text x="${index * 60 + 30}" y="180" text-anchor="middle" fill="#6b7280" font-size="12">${label}</text>`
      ).join('\n')}
    </svg>
  `;
}

/**
 * 生成直方图HTML
 */
function generateHistogram(data) {
  const { labels, values, current, unit } = data;

  return `
    <div style="background: #f9fafb; padding: 20px; border-radius: 8px;">
      <h3>${labels[0]} - ${labels[labels.length - 1]} 统计</h3>
      <p>当前值: ${current} ${unit}</p>
      <p>最大值: ${Math.max(...values)} ${unit}</p>
      <p>最小值: ${Math.min(...values)} ${unit}</p>
      <p>平均值: ${(values.reduce((a, b) => a + b, 0) / values.length).toFixed(2)} ${unit}</p>
    </div>
  `;
}

module.exports = {
  getCostData,
  getModelData,
  getFallbackData,
  getLatencyData,
  generateChartHTML
};
