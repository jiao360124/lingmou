#!/bin/bash

# OpenClaw 冗余文件清理脚本
# 使用方法: bash cleanup.sh

echo "🧹 OpenClaw 冗余文件清理工具"
echo "=".repeat(60)
echo ""

# 检查是否在 workspace 目录中
if [ ! -d ".openclaw" ]; then
  echo "❌ 错误: .openclaw 目录不存在"
  exit 1
fi

echo "📂 当前目录: $(pwd)"
echo ""

# 1. 显示将要清理的文件
echo "📋 将要清理的文件:"
echo "=".repeat(60)

LOG_COUNT=$(find .openclaw -name "*.log" 2>/dev/null | wc -l)
BACKUP_COUNT=$(find .openclaw -name "*.backup*" 2>/dev/null | wc -l)
BAK_COUNT=$(find .openclaw -name "*.bak*" 2>/dev/null | wc -l)
OLD_COUNT=$(find .openclaw -name "*.old" 2>/dev/null | wc -l)
TEMP_COUNT=$(find .openclaw -name "*.tmp" 2>/dev/null | wc -l)

echo "📄 日志文件: $LOG_COUNT"
echo "📄 备份文件: $(($BACKUP_COUNT + $BAK_COUNT))"
echo "📄 旧文件: $OLD_COUNT"
echo "📄 临时文件: $TEMP_COUNT"
echo ""

# 2. 询问是否继续
read -p "🤔 是否继续清理？(y/n): " confirm

if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
  echo "✅ 已取消清理"
  exit 0
fi

echo ""
echo "🧹 开始清理..."
echo "=".repeat(60)

# 3. 清理日志文件
if [ $LOG_COUNT -gt 0 ]; then
  echo "📄 清理日志文件..."
  find .openclaw -name "*.log" -type f -delete
  echo "  ✅ 完成"
fi

# 4. 清理备份文件
if [ $BACKUP_COUNT -gt 0 ]; then
  echo "📄 清理备份文件..."
  find .openclaw -name "*.backup*" -type f -delete
  find .openclaw -name "*.bak*" -type f -delete
  find .openclaw -name "*.old" -type f -delete
  echo "  ✅ 完成"
fi

# 5. 清理临时文件
if [ $TEMP_COUNT -gt 0 ]; then
  echo "📄 清理临时文件..."
  find .openclaw -name "*.tmp" -type f -delete
  find .openclaw -name "*.temp" -type f -delete
  find .openclaw -name ".DS_Store" -type f -delete
  find .openclaw -name "Thumbs.db" -type f -delete
  echo "  ✅ 完成"
fi

# 6. 清理构建产物（可选）
read -p "📦 是否清理构建产物？(node_modules, dist, build, coverage, .cache) (y/n): " clean_build

if [ "$clean_build" == "y" ] || [ "$clean_build" == "Y" ]; then
  echo "📦 清理构建产物..."

  # 删除 node_modules
  if [ -d "node_modules" ]; then
    rm -rf node_modules
    echo "  ✅ node_modules"
  fi

  # 删除构建目录
  rm -rf dist 2>/dev/null
  rm -rf build 2>/dev/null
  rm -rf coverage 2>/dev/null
  rm -rf .cache 2>/dev/null

  echo "  ✅ 构建/缓存目录"
fi

echo ""
echo "=".repeat(60)
echo "✅ 清理完成！"
echo "=".repeat(60)

# 4. 显示清理结果
echo ""
echo "📊 清理结果:"
echo "=".repeat(60)

LOG_COUNT=$(find .openclaw -name "*.log" 2>/dev/null | wc -l)
BACKUP_COUNT=$(find .openclaw -name "*.backup*" 2>/dev/null | wc -l)
BAK_COUNT=$(find .openclaw -name "*.bak*" 2>/dev/null | wc -l)
OLD_COUNT=$(find .openclaw -name "*.old" 2>/dev/null | wc -l)
TEMP_COUNT=$(find .openclaw -name "*.tmp" 2>/dev/null | wc -l)

echo "📄 剩余日志文件: $LOG_COUNT"
echo "📄 剩余备份文件: $(($BACKUP_COUNT + $BAK_COUNT))"
echo "📄 剩余旧文件: $OLD_COUNT"
echo "📄 剩余临时文件: $TEMP_COUNT"
echo ""

# 显示目录大小
SIZE=$(du -sh .openclaw 2>/dev/null | cut -f1)
echo "📂 .openclaw 目录大小: $SIZE"
echo "=".repeat(60)
