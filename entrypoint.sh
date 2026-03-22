#!/bin/bash

export MICROMAMBA_ROOT_PREFIX=/root/micromamba
export PYTHONUSERBASE=/pip_packages
export PATH="/pip_packages/bin:/root/micromamba/envs/bioenv/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
export OPENCLAW_CONFIG_PATH="/root/.openclaw/openclaw.json"
export HOME="/root"

PINCHCHAT_PORT="${PINCHCHAT_PORT:-8080}"
OPENCLAW_MODE="${OPENCLAW_MODE:-tui}"

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--pinchchat)
            OPENCLAW_MODE="pinchchat"
            shift
            ;;
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
            echo "  -p, --pinchchat   启动 PinchChat 模式 (双端口，推荐测试方案)"
            echo "  -d, --dashboard   启动 Dashboard 模式 (Web界面，兜底)"
            echo "  -t, --tui         启动 TUI 模式 (终端界面，默认)"
            echo "  -h, --help        显示此帮助信息"
            echo ""
            echo "环境变量:"
            echo "  OPENCLAW_MODE      设置启动模式 (tui/dashboard/pinchchat)"
            echo "  PINCHCHAT_PORT     PinchChat 静态页面端口 (默认 8080)"
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

cleanup() {
    echo ""
    echo "正在关闭服务..."
    kill "$GATEWAY_PID" 2>/dev/null
    kill "$PINCHCHAT_PID" 2>/dev/null
    exit 0
}

trap cleanup EXIT INT TERM

echo "=========================================="
echo "OpenClaw 生信分析环境"
echo "=========================================="

get_server_info() {
    SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
    if [ -z "$SERVER_IP" ]; then
        SERVER_IP="<服务器IP>"
    fi

    TOKEN=$(grep -o '"token"[[:space:]]*:[[:space:]]*"[^"]*"' /root/.openclaw/openclaw.json 2>/dev/null | head -1 | sed 's/.*"token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    if [ -z "$TOKEN" ]; then
        TOKEN="<token>"
    fi
}

wait_gateway_ready() {
    local port=$1
    MAX_WAIT=${OPENCLAW_GATEWAY_TIMEOUT:-180}
    WAIT_COUNT=0
    while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
        if curl -s "http://127.0.0.1:${port}/healthz" > /dev/null 2>&1; then
            echo ""
            echo "Gateway 已就绪 (PID: $GATEWAY_PID)"
            return 0
        fi
        sleep 1
        WAIT_COUNT=$((WAIT_COUNT + 1))
        printf "\r等待 Gateway 启动中... %ds/%ds" "$WAIT_COUNT" "$MAX_WAIT"
    done

    echo ""
    echo "警告: Gateway 启动超时，但进程仍在后台运行"
    echo "Gateway PID: $GATEWAY_PID"
    return 1
}

start_gateway() {
    local port=$1
    echo ""
    echo "启动 Gateway (端口: ${port})..."

    export OPENCLAW_GATEWAY_PORT="$port"
    sed -i "s/\"port\"[[:space:]]*:[[:space:]]*[0-9]*/\"port\": $port/" /root/.openclaw/openclaw.json 2>/dev/null

    openclaw gateway &
    GATEWAY_PID=$!

    wait_gateway_ready "$port"
}

start_pinchchat_static() {
    echo ""
    echo "启动 PinchChat 静态页面服务 (端口: ${PINCHCHAT_PORT})..."
    python3 -m http.server "$PINCHCHAT_PORT" --directory /var/www/pinchchat >/tmp/pinchchat-http.log 2>&1 &
    PINCHCHAT_PID=$!
    sleep 1
}

if [ "${OPENCLAW_MODE}" = "pinchchat" ]; then
    start_gateway 18789
    start_pinchchat_static

    if [ "${OPENCLAW_SILENT_PROMPT}" != "1" ]; then
        get_server_info
        echo ""
        echo "=========================================="
        echo "PinchChat 模式（双端口）"
        echo "=========================================="
        echo ""
        echo "PinchChat 页面端口: ${PINCHCHAT_PORT}"
        echo "Gateway 端口: 18789"
        echo ""
        echo "远程访问步骤:"
        echo ""
        echo "1. 在本地终端执行端口转发:"
        echo "   ssh -L 28080:127.0.0.1:${PINCHCHAT_PORT} -L 28789:127.0.0.1:18789 -p <SSH端口> <用户名>@${SERVER_IP}"
        echo ""
        echo "2. 在本地浏览器访问 PinchChat 页面:"
        echo "   http://127.0.0.1:28080"
        echo ""
        echo "3. 在 PinchChat 登录页填写:"
        echo "   网关地址: ws://127.0.0.1:28789"
        echo "   令牌: ${TOKEN}"
        echo ""
        echo "4. 首次使用如需配对审批:"
        echo "   ./run_openclaw_devices.sh approve-latest"
        echo ""
        echo "按 Ctrl+C 退出"
        echo ""
    fi

    wait "$GATEWAY_PID"

elif [ "${OPENCLAW_MODE}" = "dashboard" ]; then
    start_gateway 18789

    if [ "${OPENCLAW_SILENT_PROMPT}" != "1" ]; then
        get_server_info
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
    fi

    wait "$GATEWAY_PID"

else
    start_gateway 18789
    echo ""
    echo "启动 OpenClaw TUI..."
    echo ""
    openclaw tui
fi
