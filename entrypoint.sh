#!/bin/bash

export MICROMAMBA_ROOT_PREFIX=/root/micromamba
export PYTHONUSERBASE=/pip_packages
export PATH="/pip_packages/bin:/root/micromamba/envs/bioenv/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
export OPENCLAW_CONFIG_PATH="/root/.openclaw/openclaw.json"
export HOME="/root"

PINCHCHAT_PORT="${PINCHCHAT_PORT:-18080}"
GATEWAY_PORT="${GATEWAY_PORT:-18789}"

GATEWAY_PID=""
PINCHCHAT_PID=""
CLEANUP_DONE=0

cleanup() {
    local exit_code=${1:-$?}

    if [ "$CLEANUP_DONE" -eq 1 ]; then
        return
    fi
    CLEANUP_DONE=1

    echo ""
    echo "正在关闭服务..."

    openclaw gateway stop >/dev/null 2>&1 || true

    [ -n "$GATEWAY_PID" ] && kill "$GATEWAY_PID" 2>/dev/null || true
    [ -n "$PINCHCHAT_PID" ] && kill "$PINCHCHAT_PID" 2>/dev/null || true

    return "$exit_code"
}

trap 'cleanup $?' EXIT
trap 'exit 130' INT TERM

check_port_available() {
    local port=$1

    if command -v ss >/dev/null 2>&1; then
        ! ss -tln 2>/dev/null | grep -q ":${port} "
        return $?
    fi

    if command -v netstat >/dev/null 2>&1; then
        ! netstat -tln 2>/dev/null | grep -q ":${port} "
        return $?
    fi

    python3 - "$port" <<'PY'
import socket
import sys

port = int(sys.argv[1])
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

try:
    sock.bind(("0.0.0.0", port))
    sys.exit(0)
except OSError:
    sys.exit(1)
finally:
    sock.close()
PY
}

find_available_port() {
    local start_port=$1
    local max_attempts=100
    local port=$start_port
    
    for i in $(seq 1 $max_attempts); do
        if check_port_available "$port"; then
            echo "$port"
            return 0
        fi
        port=$((port + 1))
    done
    echo "$start_port"
}

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
            return 0
        fi
        sleep 1
        WAIT_COUNT=$((WAIT_COUNT + 1))
        printf "\r等待 Gateway 启动中... %ds/%ds" "$WAIT_COUNT" "$MAX_WAIT"
    done
    return 1
}

start_gateway() {
    local preferred_port=$1
    GATEWAY_PORT=$(find_available_port "$preferred_port")
    
    echo "启动 Gateway (端口: ${GATEWAY_PORT})..."
    
    export OPENCLAW_GATEWAY_PORT="$GATEWAY_PORT"
    sed -i "s/\"port\"[[:space:]]*:[[:space:]]*[0-9]*/\"port\": $GATEWAY_PORT/" /root/.openclaw/openclaw.json 2>/dev/null
    
    openclaw gateway &
    GATEWAY_PID=$!
    
    if wait_gateway_ready "$GATEWAY_PORT"; then
        echo "Gateway 已就绪 (PID: $GATEWAY_PID, 端口: $GATEWAY_PORT)"
    else
        echo "警告: Gateway 启动超时，进程 PID: $GATEWAY_PID"
    fi
}

start_pinchchat() {
    PINCHCHAT_PORT=$(find_available_port "${PINCHCHAT_PORT:-18080}")
    echo "启动 PinchChat 静态服务 (端口: ${PINCHCHAT_PORT})..."
    python3 -m http.server "$PINCHCHAT_PORT" --directory /var/www/pinchchat >/tmp/pinchchat-http.log 2>&1 &
    PINCHCHAT_PID=$!
    sleep 1
    echo "PinchChat 服务已启动 (PID: $PINCHCHAT_PID)"
    echo ""
    echo "本地访问: http://127.0.0.1:${PINCHCHAT_PORT}"
    echo "Gateway: ws://127.0.0.1:${GATEWAY_PORT}"
    echo "Token: ${TOKEN}"
}

print_usage() {
    get_server_info
    echo ""
    echo "=========================================="
    echo " OpenClaw 生信分析环境"
    echo "=========================================="
    echo ""
    echo "Gateway 已启动: http://127.0.0.1:${GATEWAY_PORT}"
    echo "Dashboard: http://127.0.0.1:${GATEWAY_PORT}?token=${TOKEN}"
    echo "Token: ${TOKEN}"
    echo ""
    echo "默认行为: 当前仅启动 Gateway，并保持在容器交互环境。"
    echo ""
    echo "容器内可用命令:"
    echo "  openclaw tui          启动 TUI 终端界面"
    echo "  start-pinchchat       启动 PinchChat Web 界面"
    echo ""
    echo "飞书接入:"
    echo "  npx -y @larksuite/openclaw-lark install    安装飞书插件"
    echo "  openclaw pairing approve feishu <id>        审批飞书配对"
    echo ""
    echo "远程访问 (SSH 端口转发):"
    echo "  # Gateway / Dashboard"
    echo "  ssh -L ${GATEWAY_PORT}:127.0.0.1:${GATEWAY_PORT} -p <SSH端口> <用户>@${SERVER_IP}"
    echo "  # PinchChat (先在容器内执行 start-pinchchat，再转发页面端口)"
    echo "  ssh -L <本地页面端口>:127.0.0.1:<容器内PinchChat端口> -p <SSH端口> <用户>@${SERVER_IP}"
    echo ""
    echo "输入 'help' 查看更多命令，'exit' 退出容器"
    echo ""
}

export -f find_available_port
export -f start_pinchchat
export PINCHCHAT_PORT GATEWAY_PORT

start_gateway "$GATEWAY_PORT"
print_usage

/bin/bash --rcfile <(echo '
PS1="\[\033[1;32m\]openclaw\[\033[0m\]:\w\$ "
alias start-pinchchat="start_pinchchat"
alias help="echo \"\"; echo \"默认行为:\"; echo \"  已自动启动 Gateway，并保持在容器交互环境\"; echo \"\"; echo \"可用命令:\"; echo \"  openclaw tui     - 启动 TUI 终端界面\"; echo \"  start-pinchchat  - 启动 PinchChat Web 界面\"; echo \"  openclaw --help  - 查看 openclaw 帮助\"; echo \"\"; echo \"飞书接入:\"; echo \"  npx -y @larksuite/openclaw-lark install\"; echo \"  openclaw pairing approve feishu <id>\"; echo \"\"; echo \"端口信息:\"; echo \"  Gateway: $GATEWAY_PORT\"; echo \"\""
')
SHELL_EXIT_CODE=$?
cleanup "$SHELL_EXIT_CODE"
exit "$SHELL_EXIT_CODE"
