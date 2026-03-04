# OpenClaw 3.0 Dockerfile
# 多阶段构建，优化镜像大小

# 第一阶段：构建
FROM node:20-alpine AS builder

# 安装构建依赖
RUN apk add --no-cache python3 make g++

# 设置工作目录
WORKDIR /app

# 复制 package.json 和 package-lock.json
COPY package*.json ./

# 安装依赖
RUN npm ci --only=production

# 复制源代码
COPY . .

# 构建生产版本（如果需要）
RUN npm run build || true

# 第二阶段：运行
FROM node:20-alpine AS runner

# 创建非 root 用户
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# 设置工作目录
WORKDIR /app

# 复制依赖文件
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./

# 复制应用文件
COPY --from=builder /app/index.js ./
COPY --from=builder /app/dashboard-server.js ./
COPY --from=builder /app/data-service.js ./
COPY --from=builder /app/config-loader.js ./
COPY --from=builder /app/dashboard ./
COPY --from=builder /app/data-sources ./
COPY --from=builder /app/reports ./
COPY --from=builder /app/logs ./

# 设置环境变量
ENV NODE_ENV=production
ENV PORT=18789

# 创建必要的目录
RUN mkdir -p logs data reports templates

# 切换到非 root 用户
USER nodejs

# 暴露端口
EXPOSE 18789 3000

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:18789/api/status', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# 启动应用
CMD ["node", "dashboard-server.js"]
