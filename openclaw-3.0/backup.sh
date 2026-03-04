#!/bin/bash
# OpenClaw 3.0 自动备份脚本

set -e

echo "💾 OpenClaw 3.0 自动备份"
echo "========================"

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 配置
BACKUP_DIR="backups/$(date +%Y%m%d)"
KEEP_DAYS=7

# 检查 Docker Compose
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
elif command -v docker compose &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    echo -e "${RED}❌ Docker Compose 未安装${NC}"
    exit 1
fi

# 创建备份目录
mkdir -p "$BACKUP_DIR"

echo -e "\n📦 创建备份: $BACKUP_DIR"

# 停止服务（可选）
read -p "是否停止服务进行备份？(y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🛑 停止服务..."
    $COMPOSE_CMD down
fi

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

# 备份日志（可选）
if [ -d "logs" ]; then
    # 只保留最近7天的日志
    find logs -name "*.log" -mtime +7 -delete
    cp -r logs "$BACKUP_DIR/"
    echo "  ✅ 日志文件已备份"
fi

# 备份报告
if [ -d "reports" ]; then
    cp -r reports "$BACKUP_DIR/"
    echo "  ✅ 报告文件已备份"
fi

# 重启服务（如果停止了）
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 重启服务..."
    $COMPOSE_CMD up -d
fi

echo -e "\n✅ 备份完成: $BACKUP_DIR"
echo ""
echo "查看备份:"
ls -lh "$BACKUP_DIR"
echo ""

# 清理旧备份
echo "🧹 清理 $KEEP_DAYS 天前的旧备份..."
find "backups" -type d -name "2026*" -mtime +$KEEP_DAYS -exec rm -rf {} \; 2>/dev/null || true
echo "✅ 清理完成"

echo -e "\n${GREEN}✅ 自动备份完成！${NC}"
