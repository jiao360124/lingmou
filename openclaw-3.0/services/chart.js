/**
 * 图表生成服务
 * 生成各种类型的图表数据
 */

const logger = require('../utils/logger');
const errorHandler = require('../utils/error-handler');

/**
 * 获取成本图表数据
 */
function getCostChart(data) {
  const chart = {
    type: 'line',
    title: 'Cost Overview',
    labels: [],
    datasets: [
      {
        label: 'Daily Cost ($)',
        data: [],
        borderColor: '#3B82F6',
        backgroundColor: 'rgba(59, 130, 246, 0.1)',
        tension: 0.4,
        fill: true,
      },
      {
        label: 'Total Cost ($)',
        data: [],
        borderColor: '#10B981',
        backgroundColor: 'rgba(16, 185, 129, 0.1)',
        tension: 0.4,
        fill: true,
      },
    ],
    options: {
      responsive: true,
      plugins: {
        legend: {
          position: 'bottom',
        },
      },
      scales: {
        y: {
          beginAtZero: true,
          title: {
            display: true,
            text: 'Cost (USD)',
          },
        },
      },
    },
  };

  return chart;
}

/**
 * 获取模型使用图表数据
 */
function getModelChart(costByModel) {
  const chart = {
    type: 'doughnut',
    title: 'Cost by Model',
    labels: [],
    datasets: [
      {
        data: [],
        backgroundColor: [
          '#3B82F6',
          '#10B981',
          '#F59E0B',
          '#EF4444',
          '#8B5CF6',
          '#EC4899',
          '#06B6D4',
        ],
        borderWidth: 2,
      },
    ],
    options: {
      responsive: true,
      plugins: {
        legend: {
          position: 'bottom',
        },
      },
    },
  };

  if (costByModel && costByModel.models) {
    Object.entries(costByModel.models).forEach(([model, data]) => {
      chart.labels.push(model);
      chart.datasets[0].data.push(data.amount);
    });
  }

  return chart;
}

/**
 * 获取 Fallback 图表数据
 */
function getFallbackChart(data) {
  const chart = {
    type: 'bar',
    title: 'Fallback Performance',
    labels: [],
    datasets: [
      {
        label: 'Fallback Rate (%)',
        data: [],
        backgroundColor: '#F59E0B',
        borderColor: '#F59E0B',
        borderWidth: 1,
      },
    ],
    options: {
      responsive: true,
      plugins: {
        legend: {
          position: 'bottom',
        },
      },
      scales: {
        y: {
          beginAtZero: true,
          max: 100,
          title: {
            display: true,
            text: 'Rate (%)',
          },
        },
      },
    },
  };

  if (data && data.labels) {
    chart.labels = data.labels;
    chart.datasets[0].data = data.datasets[0].data;
  }

  return chart;
}

/**
 * 获取延迟图表数据
 */
function getLatencyChart(data) {
  const chart = {
    type: 'line',
    title: 'Latency Distribution',
    labels: [],
    datasets: [
      {
        label: 'p50',
        data: [],
        borderColor: '#3B82F6',
        tension: 0.2,
      },
      {
        label: 'p95',
        data: [],
        borderColor: '#F59E0B',
        tension: 0.2,
      },
      {
        label: 'p99',
        data: [],
        borderColor: '#EF4444',
        tension: 0.2,
      },
    ],
    options: {
      responsive: true,
      plugins: {
        legend: {
          position: 'bottom',
        },
      },
      scales: {
        y: {
          beginAtZero: true,
          title: {
            display: true,
            text: 'Latency (ms)',
          },
        },
      },
    },
  };

  if (data && data.labels) {
    chart.labels = data.labels;
    chart.datasets[0].data = data.p50 || [];
    chart.datasets[1].data = data.p95 || [];
    chart.datasets[2].data = data.p99 || [];
  }

  return chart;
}

/**
 * 获取成功率图表数据
 */
function getSuccessRateChart(data) {
  const chart = {
    type: 'line',
    title: 'Success Rate',
    labels: [],
    datasets: [
      {
        label: 'Success Rate (%)',
        data: [],
        borderColor: '#10B981',
        backgroundColor: 'rgba(16, 185, 129, 0.1)',
        tension: 0.4,
        fill: true,
        yAxisID: 'y',
      },
      {
        label: 'Errors',
        data: [],
        type: 'bar',
        backgroundColor: 'rgba(239, 68, 68, 0.5)',
        yAxisID: 'y1',
      },
    ],
    options: {
      responsive: true,
      plugins: {
        legend: {
          position: 'bottom',
        },
      },
      scales: {
        y: {
          beginAtZero: true,
          max: 100,
          title: {
            display: true,
            text: 'Success Rate (%)',
          },
          position: 'left',
        },
        y1: {
          beginAtZero: true,
          title: {
            display: true,
            text: 'Errors',
          },
          position: 'right',
          grid: {
            drawOnChartArea: false,
          },
        },
      },
    },
  };

  if (data && data.labels) {
    chart.labels = data.labels;
    chart.datasets[0].data = data.successRate || [];
    chart.datasets[1].data = data.errors || [];
  }

  return chart;
}

/**
 * 获取资源使用图表数据
 */
function getResourceChart(data) {
  const chart = {
    type: 'bar',
    title: 'Resource Usage',
    labels: [],
    datasets: [
      {
        label: 'Memory (MB)',
        data: [],
        backgroundColor: 'rgba(59, 130, 246, 0.8)',
        yAxisID: 'y',
      },
      {
        label: 'CPU (%)',
        data: [],
        backgroundColor: 'rgba(16, 185, 129, 0.8)',
        yAxisID: 'y1',
      },
    ],
    options: {
      responsive: true,
      plugins: {
        legend: {
          position: 'bottom',
        },
      },
      scales: {
        y: {
          beginAtZero: true,
          title: {
            display: true,
            text: 'Memory (MB)',
          },
        },
        y1: {
          beginAtZero: true,
          max: 100,
          title: {
            display: true,
            text: 'CPU (%)',
          },
          position: 'right',
          grid: {
            drawOnChartArea: false,
          },
        },
      },
    },
  };

  if (data && data.labels) {
    chart.labels = data.labels;
    chart.datasets[0].data = data.memory || [];
    chart.datasets[1].data = data.cpu || [];
  }

  return chart;
}

/**
 * 获取系统负载图表数据
 */
function getLoadChart(data) {
  const chart = {
    type: 'line',
    title: 'System Load',
    labels: [],
    datasets: [
      {
        label: 'Load Average',
        data: [],
        borderColor: '#F59E0B',
        tension: 0.4,
        fill: true,
        yAxisID: 'y',
      },
      {
        label: 'CPU Usage (%)',
        data: [],
        borderColor: '#8B5CF6',
        tension: 0.4,
        yAxisID: 'y1',
      },
    ],
    options: {
      responsive: true,
      plugins: {
        legend: {
          position: 'bottom',
        },
      },
      scales: {
        y: {
          beginAtZero: true,
          title: {
            display: true,
            text: 'Load Average',
          },
        },
        y1: {
          beginAtZero: true,
          max: 100,
          title: {
            display: true,
            text: 'CPU Usage (%)',
          },
          position: 'right',
          grid: {
            drawOnChartArea: false,
          },
        },
      },
    },
  };

  if (data && data.labels) {
    chart.labels = data.labels;
    chart.datasets[0].data = data.loadavg || [];
    chart.datasets[1].data = data.cpu || [];
  }

  return chart;
}

/**
 * 获取按时间段成本图表
 */
function getCostByPeriodChart(data) {
  const chart = {
    type: 'line',
    title: 'Cost Trends',
    labels: [],
    datasets: [
      {
        label: 'Cost',
        data: [],
        borderColor: '#10B981',
        backgroundColor: 'rgba(16, 185, 129, 0.1)',
        tension: 0.4,
        fill: true,
      },
    ],
    options: {
      responsive: true,
      plugins: {
        legend: {
          position: 'bottom',
        },
      },
      scales: {
        y: {
          beginAtZero: true,
          title: {
            display: true,
            text: 'Cost (USD)',
          },
        },
      },
    },
  };

  if (data && data.periods) {
    chart.labels = Object.keys(data.periods);
    chart.datasets[0].data = Object.values(data.periods).map(p => p.amount);
  }

  return chart;
}

/**
 * 获取汇总卡片数据
 */
function getSummaryCards(data) {
  const cards = [
    {
      title: 'Total Cost',
      value: `$${data.totalCost?.total?.toFixed(2) || '0.00'}`,
      trend: data.totalCost?.trend || 'stable',
      icon: '💰',
      color: 'blue',
    },
    {
      title: 'Daily Cost',
      value: `$${data.totalCost?.daily?.today?.toFixed(2) || '0.00'}`,
      trend: data.totalCost?.daily?.trend || 'stable',
      icon: '📅',
      color: 'green',
    },
    {
      title: 'Success Rate',
      value: `${data.successRate || '0.00'}%`,
      trend: data.successTrend || 'stable',
      icon: '✅',
      color: 'purple',
    },
    {
      title: 'Avg Response Time',
      value: `${data.avgResponseTime || '0'}ms`,
      trend: data.latencyTrend || 'stable',
      icon: '⚡',
      color: 'orange',
    },
  ];

  return cards;
}

/**
 * 获取成本分布图表
 */
function getCostDistributionChart(data) {
  const chart = {
    type: 'doughnut',
    title: 'Cost Distribution',
    labels: [],
    datasets: [
      {
        data: [],
        backgroundColor: [
          '#3B82F6',
          '#10B981',
          '#F59E0B',
          '#EF4444',
          '#8B5CF6',
          '#EC4899',
          '#06B6D4',
          '#84CC16',
        ],
        borderWidth: 2,
      },
    ],
    options: {
      responsive: true,
      plugins: {
        legend: {
          position: 'bottom',
        },
        tooltip: {
          callbacks: {
            label: function(context) {
              const total = context.dataset.data.reduce((a, b) => a + b, 0);
              const percentage = ((context.raw / total) * 100).toFixed(1);
              return `${context.label}: $${context.raw} (${percentage}%)`;
            },
          },
        },
      },
    },
  };

  if (data && data.distribution) {
    Object.entries(data.distribution).forEach(([category, value]) => {
      chart.labels.push(category);
      chart.datasets[0].data.push(value);
    });
  }

  return chart;
}

/**
 * 获取性能指标图表
 */
function getPerformanceChart(data) {
  const chart = {
    type: 'line',
    title: 'Performance Metrics',
    labels: [],
    datasets: [
      {
        label: 'Throughput (req/s)',
        data: [],
        borderColor: '#06B6D4',
        backgroundColor: 'rgba(6, 182, 212, 0.1)',
        tension: 0.4,
        fill: true,
      },
      {
        label: 'Error Rate (%)',
        data: [],
        borderColor: '#EF4444',
        backgroundColor: 'rgba(239, 68, 68, 0.1)',
        tension: 0.4,
        fill: true,
      },
    ],
    options: {
      responsive: true,
      plugins: {
        legend: {
          position: 'bottom',
        },
      },
      scales: {
        y: {
          beginAtZero: true,
          title: {
            display: true,
            text: 'Throughput (req/s)',
          },
          position: 'left',
        },
        y1: {
          beginAtZero: true,
          max: 100,
          title: {
            display: true,
            text: 'Error Rate (%)',
          },
          position: 'right',
          grid: {
            drawOnChartArea: false,
          },
        },
      },
    },
  };

  if (data && data.labels) {
    chart.labels = data.labels;
    chart.datasets[0].data = data.throughput || [];
    chart.datasets[1].data = data.errorRate || [];
  }

  return chart;
}

module.exports = {
  getCostChart,
  getModelChart,
  getFallbackChart,
  getLatencyChart,
  getSuccessRateChart,
  getResourceChart,
  getLoadChart,
  getCostByPeriodChart,
  getSummaryCards,
  getCostDistributionChart,
  getPerformanceChart,
};
