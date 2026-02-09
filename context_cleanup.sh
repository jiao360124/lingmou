#!/bin/bash

# OpenClaw 上下文清理脚本
# 解决 Context Overflow 问题

echo "开始清理 OpenClaw 工作空间..."

# 创建备份目录
mkdir -p "C:\Users\Administrator\.openclaw\workspace\backup\$(date +%Y%m%d)"

# 备份重要配置文件
cp "C:\Users\Administrator\.openclaw\workspace\SOUL.md" "C:\Users\Administrator\.openclaw\workspace\backup\$(date +%Y%m%d)\"
cp "C:\Users\Administrator\.openclaw\workspace\USER.md" "C:\Users\Administrator\.openclaw\workspace\backup\$(date +%Y%m%d)\"
cp "C:\Users\Administrator\.openclaw\workspace\IDENTITY.md" "C:\Users\Administrator\.openclaw\workspace\backup\$(date +%Y%m%d)\"

# 压缩moltbook相关文件（但保留最近的几个）
cd "C:\Users\Administrator\.openclaw\workspace"
7z a "backup\$(date +%Y%m%d)\moltbook_archive.zip" moltbook_*.md

# 清理旧的memory文件（保留最近3天）
find "C:\Users\Administrator\.openclaw\workspace\memory" -name "*.md" -mtime +2 -delete

# 清理临时文件
rm -f *.tmp *.log *.cache

echo "清理完成！"
echo "工作空间已重置，请重新启动会话。"