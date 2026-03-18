#!/bin/bash

export MICROMAMBA_ROOT_PREFIX=/root/micromamba
export PYTHONUSERBASE=/pip_packages
export PATH="/pip_packages/bin:/root/micromamba/envs/bioenv/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
export OPENCLAW_CONFIG_PATH="/root/.openclaw/openclaw.json"
export HOME="/root"

# 默认模式
OPENCLAW_MODE="${OPENCLAW_MODE:-tui}"

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dashboard)
            OPENCLAW_MODE="dashboard"
            shift
            ;;
        -t|--tui)
            OPENCLAW_MODE="tui"
            shift
            ;;
        -h|--help)
            echo "用法: openclaw-bioinfo [选项]"
            echo ""
            echo "选项:"
            echo "  -d, --dashboard    启动 Dashboard 模式 (Web界面)"
            echo "  -t, --tui          启动 TUI 模式 (终端界面，默认)"
            echo "  -h, --help         显示此帮助信息"
            echo ""
            echo "环境变量:"
            echo "  OPENCLAW_MODE      设置启动模式 (tui/dashboard)"
            echo ""
            exit 0
            ;;
        *)
            echo "未知选项: $1"
            echo "使用 -h 或 --help 查看帮助"
            exit 1
            ;;
    esac
done

# 清理函数：退出时终止gateway
cleanup() {
    echo ""
    echo "正在关闭 Gateway..."
    kill $GATEWAY_PID 2>/dev/null
    exit 0
}

# 捕获退出信号
trap cleanup EXIT INT TERM

echo "=========================================="
echo "OpenClaw 生信分析环境"
echo "=========================================="

echo ""
echo "启动 Gateway..."
openclaw gateway &
GATEWAY_PID=$!

# 等待gateway真正就绪
# 支持环境变量自定义等待时间，默认180秒
MAX_WAIT=${OPENCLAW_GATEWAY_TIMEOUT:-180}
WAIT_COUNT=0
while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
    if curl -s http://127.0.0.1:18789/healthz > /dev/null 2>&1; then
        echo ""
        echo "Gateway 已就绪 (PID: $GATEWAY_PID)"
        break
    fi
    sleep 1
    WAIT_COUNT=$((WAIT_COUNT + 1))
    printf "\r等待 Gateway 启动中... %ds/%ds" $WAIT_COUNT $MAX_WAIT
done

if [ $WAIT_COUNT -ge $MAX_WAIT ]; then
    echo ""
    echo "警告: Gateway 启动超时，但进程仍在后台运行"
    echo "Gateway PID: $GATEWAY_PID"
fi

# 根据模式选择启动方式
if [ "${OPENCLAW_MODE}" = "dashboard" ]; then
    # 获取服务器 IP 地址
    SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
    if [ -z "$SERVER_IP" ]; then
        SERVER_IP="<服务器IP>"
    fi
    
    # 获取 token
    TOKEN=$(grep -o '"token"[[:space:]]*:[[:space:]]*"[^"]*"' /root/.openclaw/openclaw.json 2>/dev/null | head -1 | sed 's/.*"token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    if [ -z "$TOKEN" ]; then
        TOKEN="<token>"
    fi
    
    echo ""
    echo "=========================================="
    echo "Dashboard 模式"
    echo "=========================================="
    echo ""
    echo "Gateway 已在端口 18789 启动"
    echo ""
    echo "远程访问步骤:"
    echo ""
    echo "1. 在本地终端执行端口转发:"
    echo "   ssh -L 18789:127.0.0.1:18789 -p <SSH端口> <用户名>@${SERVER_IP}"
    echo ""
    echo "2. 在本地浏览器访问:"
    echo "   http://127.0.0.1:18789?token=${TOKEN}"
    echo ""
    echo "按 Ctrl+C 退出"
    echo ""
    # 保持容器运行
    wait $GATEWAY_PID
else
    echo ""
    echo "启动 OpenClaw TUI..."
    echo ""
    # 直接进入TUI界面
    openclaw tui
fi
