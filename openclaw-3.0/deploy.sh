#!/bin/bash
# OpenClaw 3.0 一键部署脚本（Linux/Mac）

set -e

echo "🚀 OpenClaw 3.0 一键部署"
echo "=========================="

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker 未安装${NC}"
    echo "请先安装 Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

# 检查 Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}⚠️  Docker Compose 未安装，尝试使用 docker compose${NC}"
    if ! command -v docker compose &> /dev/null; then
        echo -e "${RED}❌ Docker Compose 未安装${NC}"
        exit 1
    fi
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi

# 检查配置文件
if [ ! -f "config.json" ]; then
    echo -e "${YELLOW}⚠️  config.json 不存在，创建默认配置${NC}"
    cp config.json.example config.json
fi

# 检查 .env 文件
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  .env 不存在，创建示例文件${NC}"
    cp .env.example .env
    echo -e "${YELLOW}💡 请编辑 .env 文件配置 API 密钥等参数${NC}"
fi

# 构建镜像
echo -e "\n📦 构建镜像..."
$COMPOSE_CMD build

# 启动服务
echo -e "\n🚀 启动服务..."
$COMPOSE_CMD up -d

# 等待服务启动
echo -e "\n⏳ 等待服务启动..."
sleep 5

# 检查服务状态
echo -e "\n📋 检查服务状态..."
$COMPOSE_CMD ps

# 显示日志
echo -e "\n📊 查看日志:"
echo "运行命令: $COMPOSE_CMD logs -f"

# 测试 API
echo -e "\n🧪 测试 API..."
sleep 3
curl -s http://localhost:18789/api/status | jq . || echo "API 测试失败，请检查服务状态"

echo -e "\n${GREEN}✅ 部署完成！${NC}"
echo ""
echo "访问地址:"
echo "  Dashboard API: http://localhost:18789"
echo "  Dashboard UI: http://localhost:3000"
echo ""
echo "常用命令:"
echo "  查看日志: $COMPOSE_CMD logs -f"
echo "  停止服务: $COMPOSE_CMD stop"
echo "  重启服务: $COMPOSE_CMD restart"
echo "  查看状态: $COMPOSE_CMD ps"
echo "  删除服务: $COMPOSE_CMD down"
