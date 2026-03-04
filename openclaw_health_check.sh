#!/bin/bash
# OpenClaw 健康检查脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查函数
check_gateway() {
    echo "检查 OpenClaw Gateway 状态..."
    local status=$(/usr/bin/openclaw gateway status)
    if echo "$status" | grep -q "running"; then
        echo -e "${GREEN}✓ Gateway 运行正常${NC}"
        return 0
    else
        echo -e "${RED}✗ Gateway 状态异常${NC}"
        return 1
    fi
}

check_sessions() {
    echo "检查活动会话..."
    local sessions=$(/usr/bin/openclaw sessions list --limit 5)
    local active_count=$(echo "$sessions" | grep -c "active")
    if [[ $active_count -gt 0 ]]; then
        echo -e "${GREEN}✓ 发现 $active_count 个活动会话${NC}"
    else
        echo -e "${YELLOW}⚠ 当前无活动会话${NC}"
    fi
}

check_memory() {
    echo "检查内存使用..."
    local memory_used=$(ps aux | grep "openclaw" | grep -v grep | awk '{sum+=$6} END {print sum/1024/1024 " GB"}')
    echo "内存使用: $memory_used"
}

check_moltbook() {
    echo "检查Moltbook集成状态..."
    if [[ -f "/tmp/moltbook_integration.log" ]]; then
        local latest_check=$(tail -n 5 "/tmp/moltbook_integration.log" | grep "认证\|检查")
        if echo "$latest_check" | grep -q "✓"; then
            echo -e "${GREEN}✓ Moltbook集成正常${NC}"
        else
            echo -e "${YELLOW}⚠ Moltbook待认证${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ Moltbook配置未完成${NC}"
    fi
}

# 主检查流程
main() {
    echo "=== OpenClaw 健康检查 $(date) ==="
    
    check_gateway
    check_sessions  
    check_memory
    check_moltbook
    
    echo "=== 检查完成 ==="
    
    # 发送状态报告（可选）
    if [[ -n "$1" ]]; then
        main | mail -s "OpenClaw 健康报告" "$1"
    fi
}

# 执行主函数
main "$@"