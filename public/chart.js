/**
 * 🎨 简易图表库
 * 支持：折线图、柱状图、饼图
 */

class Chart {
    constructor(canvasId, options = {}) {
        this.canvas = document.getElementById(canvasId);
        this.ctx = this.canvas.getContext('2d');
        this.type = options.type || 'line';
        this.data = options.data || [];
        this.labels = options.labels || [];
        this.colors = options.colors || ['#6366f1', '#ec4899', '#22c55e', '#f59e0b'];
        this.resize();
    }

    resize() {
        const container = this.canvas.parentElement;
        this.canvas.width = container.clientWidth;
        this.canvas.height = container.clientHeight;
    }

    update(data, labels) {
        this.data = data;
        this.labels = labels || this.labels;
        this.render();
    }

    render() {
        const { width, height } = this.canvas;
        const ctx = this.ctx;

        ctx.clearRect(0, 0, width, height);

        switch (this.type) {
            case 'line':
                this.drawLineChart();
                break;
            case 'bar':
                this.drawBarChart();
                break;
            case 'doughnut':
                this.drawDoughnutChart();
                break;
        }
    }

    drawLineChart() {
        const { width, height } = this.canvas;
        const ctx = this.ctx;
        const padding = 40;

        // 绘制网格
        ctx.strokeStyle = 'rgba(255, 255, 255, 0.1)';
        ctx.lineWidth = 1;
        for (let i = 0; i <= 5; i++) {
            const y = padding + (height - 2 * padding) * i / 5;
            ctx.beginPath();
            ctx.moveTo(padding, y);
            ctx.lineTo(width - padding, y);
            ctx.stroke();
        }

        // 绘制折线
        const maxVal = Math.max(...this.data) * 1.2;
        const stepX = (width - 2 * padding) / (this.data.length - 1);

        ctx.beginPath();
        this.data.forEach((val, i) => {
            const x = padding + stepX * i;
            const y = height - padding - (val / maxVal) * (height - 2 * padding);
            if (i === 0) ctx.moveTo(x, y);
            else ctx.lineTo(x, y);
        });

        // 填充区域
        const gradient = ctx.createLinearGradient(0, 0, 0, height);
        gradient.addColorStop(0, this.colors[0] + '40');
        gradient.addColorStop(1, this.colors[0] + '00');

        ctx.lineTo(padding + stepX * (this.data.length - 1), height - padding);
        ctx.lineTo(padding, height - padding);
        ctx.closePath();
        ctx.fillStyle = gradient;
        ctx.fill();

        // 绘制线条
        ctx.beginPath();
        this.data.forEach((val, i) => {
            const x = padding + stepX * i;
            const y = height - padding - (val / maxVal) * (height - 2 * padding);
            if (i === 0) ctx.moveTo(x, y);
            else ctx.lineTo(x, y);
        });
        ctx.strokeStyle = this.colors[0];
        ctx.lineWidth = 3;
        ctx.stroke();

        // 绘制点
        this.data.forEach((val, i) => {
            const x = padding + stepX * i;
            const y = height - padding - (val / maxVal) * (height - 2 * padding);

            ctx.beginPath();
            ctx.arc(x, y, 5, 0, Math.PI * 2);
            ctx.fillStyle = this.colors[0];
            ctx.fill();
            ctx.strokeStyle = '#fff';
            ctx.lineWidth = 2;
            ctx.stroke();
        });

        // 绘制标签
        ctx.fillStyle = 'rgba(255, 255, 255, 0.6)';
        ctx.font = '12px sans-serif';
        this.data.forEach((val, i) => {
            const x = padding + stepX * i;
            const y = height - 10;
            ctx.fillText(val.toFixed(0), x - 10, y);
        });
    }

    drawBarChart() {
        const { width, height } = this.canvas;
        const ctx = this.ctx;
        const padding = 40;
        const barWidth = (width - 2 * padding) / this.data.length - 20;

        const maxVal = Math.max(...this.data) * 1.2;

        this.data.forEach((val, i) => {
            const x = padding + i * ((width - 2 * padding) / this.data.length) + 10;
            const barHeight = (val / maxVal) * (height - 2 * padding);
            const y = height - padding - barHeight;

            // 绘制柱子
            const gradient = ctx.createLinearGradient(x, y, x, height - padding);
            gradient.addColorStop(0, this.colors[i % this.colors.length]);
            gradient.addColorStop(1, this.colors[i % this.colors.length] + '40');

            ctx.fillStyle = gradient;
            ctx.fillRect(x, y, barWidth, barHeight);

            // 绘制标签
            ctx.fillStyle = 'rgba(255, 255, 255, 0.6)';
            ctx.font = '12px sans-serif';
            ctx.textAlign = 'center';
            ctx.fillText(this.labels[i] || '', x + barWidth / 2, height - 15);
        });
    }

    drawDoughnutChart() {
        const { width, height } = this.canvas;
        const ctx = this.ctx;
        const centerX = width / 2;
        const centerY = height / 2;
        const radius = Math.min(width, height) / 2 - 40;

        const total = this.data.reduce((a, b) => a + b, 0);
        let startAngle = -Math.PI / 2;

        this.data.forEach((val, i) => {
            const sliceAngle = (val / total) * Math.PI * 2;
            const endAngle = startAngle + sliceAngle;

            ctx.beginPath();
            ctx.moveTo(centerX, centerY);
            ctx.arc(centerX, centerY, radius, startAngle, endAngle);
            ctx.closePath();
            ctx.fillStyle = this.colors[i % this.colors.length];
            ctx.fill();

            startAngle = endAngle;
        });

        // 绘制中心圆
        ctx.beginPath();
        ctx.arc(centerX, centerY, radius * 0.6, 0, Math.PI * 2);
        ctx.fillStyle = 'rgba(10, 10, 15, 0.9)';
        ctx.fill();

        // 绘制标签
        ctx.fillStyle = 'rgba(255, 255, 255, 0.6)';
        ctx.font = '12px sans-serif';
        ctx.textAlign = 'center';
        ctx.fillText('Fallback', centerX, centerY - 10);
        ctx.fillText(`${total}`, centerX, centerY + 10);
    }
}
