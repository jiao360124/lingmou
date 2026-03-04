#!/bin/bash
# OpenClaw 3.0 回滚脚本

set -e

echo "🔄 OpenClaw 3.0 回滚脚本"
echo "========================"

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 检查 Docker Compose
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
elif command -v docker compose &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    echo -e "${RED}❌ Docker Compose 未安装${NC}"
    exit 1
fi

# 检查备份
if [ ! -d "backups" ]; then
    echo -e "${YELLOW}⚠️  备份目录不存在，创建备份目录${NC}"
    mkdir -p backups
fi

# 创建备份
BACKUP_DIR="backups/rollback-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo -e "\n📦 创建备份: $BACKUP_DIR"

# 备份配置文件
if [ -f "config.json" ]; then
    cp config.json "$BACKUP_DIR/"
    echo "  ✅ 配置文件已备份"
fi

if [ -f "docker-compose.yml" ]; then
    cp docker-compose.yml "$BACKUP_DIR/"
    echo "  ✅ Docker Compose 配置已备份"
fi

# 备份数据文件
if [ -d "data" ]; then
    cp -r data "$BACKUP_DIR/"
    echo "  ✅ 数据文件已备份"
fi

# 备份日志（可选，限制大小）
if [ -d "logs" ]; then
    cp -r logs "$BACKUP_DIR/"
    echo "  ✅ 日志文件已备份"
fi

echo -e "\n✅ 备份完成: $BACKUP_DIR"
echo ""
echo "查看备份:"
ls -lh "$BACKUP_DIR"
echo ""

# 询问是否回滚
read -p "是否回滚？(y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "取消回滚"
    exit 0
fi

# 停止服务
echo -e "\n🛑 停止服务..."
$COMPOSE_CMD down

# 选择回滚点
echo -e "\n📊 可用回滚点:"
ls -d backups/rollback-* 2>/dev/null || echo "  无可用回滚点"

read -p "请输入回滚点目录: " ROLLBACK_DIR

if [ ! -d "$ROLLBACK_DIR" ]; then
    echo -e "${RED}❌ 回滚点不存在: $ROLLBACK_DIR${NC}"
    exit 1
fi

# 回滚配置文件
echo -e "\n🔄 回滚配置文件..."
if [ -f "$ROLLBACK_DIR/config.json" ]; then
    cp "$ROLLBACK_DIR/config.json" .
    echo "  ✅ 配置文件已回滚"
fi

if [ -f "$ROLLBACK_DIR/docker-compose.yml" ]; then
    cp "$ROLLBACK_DIR/docker-compose.yml" .
    echo "  ✅ Docker Compose 配置已回滚"
fi

# 回滚数据文件
if [ -d "$ROLLBACK_DIR/data" ]; then
    cp -r "$ROLLBACK_DIR/data" .
    echo "  ✅ 数据文件已回滚"
fi

# 重启服务
echo -e "\n🚀 重启服务..."
$COMPOSE_CMD up -d

# 等待服务启动
echo -e "\n⏳ 等待服务启动..."
sleep 5

# 检查服务状态
echo -e "\n📋 检查服务状态..."
$COMPOSE_CMD ps

echo -e "\n${GREEN}✅ 回滚完成！${NC}"
echo ""
echo "如果出现问题，可以使用备份目录 $BACKUP_DIR 进行恢复"
