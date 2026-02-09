#!/bin/bash
# Nightly Evolution Plan (夜航计划)
# 自动化自我优化和修复系统
# 运行时间：凌晨 3-6 点

set -e

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
LOG_FILE="logs/nightly-evolution.log"
BACKUP_DIR="backup"

# 确保日志目录存在
mkdir -p logs

log() {
    echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"
}

log "🚀 夜航计划启动"

# 1. 检查系统状态
log "📊 步骤 1: 检查系统状态"
if [ -f "moltbook_health_check.ps1" ]; then
    log "✅ 健康检查脚本存在"
    # 可以在这里调用健康检查脚本
else
    log "⚠️  健康检查脚本不存在，跳过"
fi

# 2. 检查磁盘空间
DISK_USAGE=$(df -h . | awk 'NR==2 {print $5}' | sed 's/%//')
log "💾 磁盘使用率: ${DISK_USAGE}%"
if [ $DISK_USAGE -lt 90 ]; then
    log "✅ 磁盘空间充足"
else
    log "⚠️  磁盘空间紧张，建议清理"
fi

# 3. 检查 GitHub 连接
log "🔗 步骤 2: 检查 GitHub 连接"
if git remote -v | grep -q "github.com"; then
    log "✅ GitHub 远程仓库已配置"
    # 测试连接
    if git fetch origin 2>&1 | grep -q "error"; then
        log "⚠️  GitHub 连接有问题"
    else
        log "✅ GitHub 连接正常"
    fi
else
    log "⚠️  GitHub 远程仓库未配置"
fi

# 4. 检查本地备份
log "📦 步骤 3: 检查本地备份"
if [ -d "$BACKUP_DIR" ]; then
    BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/*.zip 2>/dev/null | wc -l)
    log "📦 本地备份文件数: $BACKUP_COUNT"
    if [ $BACKUP_COUNT -gt 7 ]; then
        log "⚠️  备份文件过多，需要清理"
        # 清理旧备份
        ls -t "$BACKUP_DIR"/*.zip | tail -n +8 | xargs rm -f
        log "✅ 已清理旧备份"
    else
        log "✅ 备份文件数量正常"
    fi
else
    log "⚠️  备份目录不存在"
fi

# 5. 检查技能状态
log "🧩 步骤 4: 检查技能状态"
SKILLS_COUNT=$(find skills -name "SKILL.md" 2>/dev/null | wc -l)
log "🎯 已安装技能数: $SKILLS_COUNT"

# 6. 错误日志分析（如果有）
log "📝 步骤 5: 分析错误日志"
ERROR_LOGS=$(find . -name "*.log" -type f -mtime -1 2>/dev/null | wc -l)
if [ $ERROR_LOGS -gt 0 ]; then
    log "⚠️  发现 $ERROR_LOGS 个日志文件（最近1天）"
    # 可以在这里添加错误日志分析逻辑
else
    log "✅ 未发现新的错误日志"
fi

# 7. 内存和性能检查
log "⚡ 步骤 6: 性能检查"
MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.1f%%", $3/$2 * 100.0}')
log "💾 内存使用率: $MEMORY_USAGE"
if [ $(echo "$MEMORY_USAGE < 80" | bc -l) -eq 1 ]; then
    log "✅ 内存使用正常"
else
    log "⚠️  内存使用较高，建议释放"
fi

# 8. 总结
log "🎉 夜航计划完成"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log ""

exit 0
