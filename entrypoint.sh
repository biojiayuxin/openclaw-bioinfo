#!/bin/bash

APP_HOME="${OPENCLAW_APP_HOME:-/openclaw-home}"
OPENCLAW_CONFIG_DIR="${OPENCLAW_CONFIG_DIR:-${APP_HOME}/.openclaw}"

export HOME="$APP_HOME"
export MICROMAMBA_ROOT_PREFIX="${MICROMAMBA_ROOT_PREFIX:-${APP_HOME}/micromamba}"
export PYTHONUSERBASE=/pip_packages
export PATH="/pip_packages/bin:${MICROMAMBA_ROOT_PREFIX}/envs/bioenv/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
export OPENCLAW_CONFIG_PATH="${OPENCLAW_CONFIG_PATH:-${OPENCLAW_CONFIG_DIR}/openclaw.json}"
export npm_config_cache="${npm_config_cache:-/tmp/.npm-cache-${UID:-$(id -u)}}"
mkdir -p "$HOME" "$OPENCLAW_CONFIG_DIR" "$MICROMAMBA_ROOT_PREFIX" "$npm_config_cache" 2>/dev/null || true
mkdir -p "$npm_config_cache" 2>/dev/null || true

GATEWAY_PORT="${GATEWAY_PORT:-18789}"
OPENCLAW_LOG_BASE_DIR="${OPENCLAW_LOG_BASE_DIR:-/tmp/openclaw-${UID:-$(id -u)}}"
GATEWAY_LOG_SUFFIX="$(date +%Y%m%d-%H%M%S)-$$"
GATEWAY_STDOUT_LOG="${GATEWAY_STDOUT_LOG:-${OPENCLAW_LOG_BASE_DIR}/gateway.${GATEWAY_LOG_SUFFIX}.stdout.log}"

GATEWAY_PID=""
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

    TOKEN=$(grep -o '"token"[[:space:]]*:[[:space:]]*"[^"]*"' "$OPENCLAW_CONFIG_PATH" 2>/dev/null | head -1 | sed 's/.*"token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    if [ -z "$TOKEN" ]; then
        TOKEN="<token>"
    fi
}

wait_gateway_ready() {
    local port=$1
    MAX_WAIT=${OPENCLAW_GATEWAY_TIMEOUT:-180}
    WAIT_COUNT=0
    while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
        if [ -n "$GATEWAY_PID" ] && ! kill -0 "$GATEWAY_PID" 2>/dev/null; then
            return 2
        fi
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

    if [ ! -r "$OPENCLAW_CONFIG_PATH" ]; then
        echo "错误: OpenClaw 配置文件不可读: $OPENCLAW_CONFIG_PATH"
        echo "请检查 run_openclaw_bioinfo.sh 中的挂载路径是否存在且当前用户可访问"
        exit 1
    fi

    GATEWAY_PORT=$(find_available_port "$preferred_port")

    if [ "$GATEWAY_PORT" != "$preferred_port" ]; then
        echo "检测到首选端口 ${preferred_port} 已占用，自动切换到 ${GATEWAY_PORT}"
    fi
    echo "启动 Gateway (端口: ${GATEWAY_PORT})..."
    
    export OPENCLAW_GATEWAY_PORT="$GATEWAY_PORT"
    sed -i "s/\"port\"[[:space:]]*:[[:space:]]*[0-9]*/\"port\": $GATEWAY_PORT/" "$OPENCLAW_CONFIG_PATH" 2>/dev/null || true

    mkdir -p "$(dirname "$GATEWAY_STDOUT_LOG")"
    : > "$GATEWAY_STDOUT_LOG"

    openclaw gateway run --port "$GATEWAY_PORT" >> "$GATEWAY_STDOUT_LOG" 2>&1 &
    GATEWAY_PID=$!

    wait_gateway_ready "$GATEWAY_PORT"
    local wait_status=$?

    if [ "$wait_status" -eq 0 ]; then
        echo "Gateway 已就绪 (PID: $GATEWAY_PID, 端口: $GATEWAY_PORT)"
    elif [ "$wait_status" -eq 2 ]; then
        echo "错误: Gateway 进程在就绪前已退出 (PID: $GATEWAY_PID)"
        echo "最近日志如下:"
        tail -n 40 "$GATEWAY_STDOUT_LOG" 2>/dev/null || true
        exit 1
    else
        echo "警告: Gateway 启动超时，进程 PID: $GATEWAY_PID"
    fi
}

print_usage() {
    get_server_info
    echo ""
    echo "=========================================="
    echo " OpenClaw 生信分析环境"
    echo "=========================================="
    echo ""
    echo "Gateway 已启动: http://127.0.0.1:${GATEWAY_PORT}"
    echo "当前实际 Gateway 端口: ${GATEWAY_PORT}"
    echo "Dashboard: http://127.0.0.1:${GATEWAY_PORT}?token=${TOKEN}"
    echo "Token: ${TOKEN}"
    echo "Gateway 日志: ${GATEWAY_STDOUT_LOG}"
    echo ""
    echo "默认行为: 当前仅启动 Gateway，并保持在容器交互环境。"
    echo ""
    echo "容器内可用命令:"
    echo "  openclaw tui          启动 TUI 终端界面"
    echo "  logs-gw               实时查看 Gateway 日志"
    echo "  logs-gw-last          查看 Gateway 最近 200 行日志"
    echo ""
    echo "飞书接入:"
    echo "  npx -y @larksuite/openclaw-lark install    安装飞书插件"
    echo "  openclaw pairing approve feishu <id>        审批飞书配对"
    echo ""
    echo "远程访问 (SSH 端口转发):"
    echo "  # Gateway / Dashboard"
    echo "  # <本地网关端口> 为你本机空闲端口；容器内 Gateway 端口为 ${GATEWAY_PORT}"
    echo "  ssh -L <本地网关端口>:127.0.0.1:${GATEWAY_PORT} -p <SSH端口> <用户>@${SERVER_IP}"
    echo ""
    echo "输入 'help' 查看更多命令，'exit' 退出容器"
    echo ""
}

export -f check_port_available
export -f find_available_port
export GATEWAY_PORT GATEWAY_STDOUT_LOG TOKEN SERVER_IP

start_gateway "$GATEWAY_PORT"
print_usage

/bin/bash --rcfile <(echo '
shopt -s expand_aliases
PS1="\[\033[1;32m\]openclaw\[\033[0m\]:\w\$ "
logs-gw() { tail -f "$GATEWAY_STDOUT_LOG"; }
logs-gw-last() { tail -n 200 "$GATEWAY_STDOUT_LOG"; }
alias help="echo \"\"; echo \"默认行为:\"; echo \"  已自动启动 Gateway，并保持在容器交互环境\"; echo \"\"; echo \"可用命令:\"; echo \"  openclaw tui      - 启动 TUI 终端界面\"; echo \"  logs-gw          - 实时查看 Gateway 日志\"; echo \"  logs-gw-last     - 查看 Gateway 最近 200 行日志\"; echo \"  openclaw --help  - 查看 openclaw 帮助\"; echo \"\"; echo \"飞书接入:\"; echo \"  npx -y @larksuite/openclaw-lark install\"; echo \"  openclaw pairing approve feishu <id>\"; echo \"\"; echo \"端口信息:\"; echo \"  Gateway: $GATEWAY_PORT\"; echo \"  日志: $GATEWAY_STDOUT_LOG\"; echo \"\""
') -i
SHELL_EXIT_CODE=$?
cleanup "$SHELL_EXIT_CODE"
exit "$SHELL_EXIT_CODE"
