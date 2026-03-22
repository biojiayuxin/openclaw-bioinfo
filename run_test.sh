#!/bin/bash

BUILD_DIR="/mnt/data_1/yuxin.jia/openclaw_test"
CONFIG_DIR="/mnt/data_1/yuxin.jia/openclaw-bioinfo"
IMAGE_NAME="openclaw-bioinfo:latest"
HOST_GATEWAY_PORT=28789
HOST_PINCHCHAT_PORT=28080
CONTAINER_PINCHCHAT_PORT=8080

OPENCLAW_MODE=""
PORT_MAPPING=""

usage() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -p, --pinchchat   启动 PinchChat 模式测试（双端口）"
    echo "  -d, --dashboard   启动 Dashboard 模式测试"
    echo "  -t, --tui         启动 TUI 模式测试 (默认)"
    echo "  -h, --help        显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 --pinchchat"
    echo "  $0 --dashboard"
    echo "  $0 --tui"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--pinchchat)
            OPENCLAW_MODE="pinchchat"
            PORT_MAPPING="-p ${HOST_GATEWAY_PORT}:18789 -p ${HOST_PINCHCHAT_PORT}:${CONTAINER_PINCHCHAT_PORT}"
            shift
            ;;
        -d|--dashboard)
            OPENCLAW_MODE="dashboard"
            PORT_MAPPING="-p ${HOST_GATEWAY_PORT}:18789"
            shift
            ;;
        -t|--tui)
            OPENCLAW_MODE="tui"
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "未知选项: $1"
            usage
            ;;
    esac
done

cleanup() {
    echo ""
    echo "正在停止容器..."
    docker stop openclaw-test 2>/dev/null
    docker rm openclaw-test 2>/dev/null
    exit 0
}

trap cleanup EXIT INT TERM

echo "=========================================="
echo "OpenClaw 生信分析环境测试 (Docker)"
echo "=========================================="
echo ""

if [ -n "$OPENCLAW_MODE" ]; then
    echo "测试模式: ${OPENCLAW_MODE}"
else
    echo "测试模式: tui (默认)"
fi
echo "镜像: ${IMAGE_NAME}"
echo ""

docker rm -f openclaw-test 2>/dev/null

ENV_ARGS=""
if [ -n "$OPENCLAW_MODE" ]; then
    ENV_ARGS="-e OPENCLAW_MODE=${OPENCLAW_MODE} -e OPENCLAW_SILENT_PROMPT=1 -e PINCHCHAT_PORT=${CONTAINER_PINCHCHAT_PORT}"
fi

show_local_access() {
    TOKEN=$(grep -o '"token"[[:space:]]*:[[:space:]]*"[^"]*"' "${CONFIG_DIR}/openclaw_config/openclaw.json" 2>/dev/null | head -1 | sed 's/.*"token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    if [ -z "$TOKEN" ]; then
        TOKEN="<token>"
    fi

    echo ""
    echo "=========================================="
    echo "本地访问提示 (Docker 测试)"
    echo "=========================================="
    echo ""

    if [ "${OPENCLAW_MODE}" = "pinchchat" ]; then
        echo "PinchChat 页面: http://localhost:${HOST_PINCHCHAT_PORT}"
        echo "PinchChat 网关地址: ws://localhost:${HOST_GATEWAY_PORT}"
        echo "Token: ${TOKEN}"
    elif [ "${OPENCLAW_MODE}" = "dashboard" ]; then
        echo "浏览器访问: http://localhost:${HOST_GATEWAY_PORT}?token=${TOKEN}"
    fi
    echo ""
}

if [ "${OPENCLAW_MODE}" = "pinchchat" ] || [ "${OPENCLAW_MODE}" = "dashboard" ]; then
    docker run -d \
        --name openclaw-test \
        -u root \
        $PORT_MAPPING \
        $ENV_ARGS \
        -v "${CONFIG_DIR}/openclaw_config:/root/.openclaw" \
        -v "${CONFIG_DIR}/workspace:/root/.openclaw/workspace" \
        -v "${CONFIG_DIR}/skills:/skills" \
        -v "${CONFIG_DIR}/micromamba_envs:/root/micromamba/envs" \
        -v "${CONFIG_DIR}/micromamba_pkgs:/root/micromamba/pkgs" \
        -v "${CONFIG_DIR}/micromamba_etc:/root/micromamba/etc" \
        -v "${CONFIG_DIR}/pip_packages:/pip_packages" \
        -v "${CONFIG_DIR}/data:/data:ro" \
        -v "${CONFIG_DIR}/work:/work" \
        "${IMAGE_NAME}"

    echo "容器已启动，等待服务就绪..."
    sleep 25

    show_local_access

    echo "查看日志 (按 Ctrl+C 停止容器):"
    echo ""
    docker logs -f openclaw-test
else
    docker run --rm -it \
        -u root \
        $PORT_MAPPING \
        $ENV_ARGS \
        -v "${CONFIG_DIR}/openclaw_config:/root/.openclaw" \
        -v "${CONFIG_DIR}/workspace:/root/.openclaw/workspace" \
        -v "${CONFIG_DIR}/skills:/skills" \
        -v "${CONFIG_DIR}/micromamba_envs:/root/micromamba/envs" \
        -v "${CONFIG_DIR}/micromamba_pkgs:/root/micromamba/pkgs" \
        -v "${CONFIG_DIR}/micromamba_etc:/root/micromamba/etc" \
        -v "${CONFIG_DIR}/pip_packages:/pip_packages" \
        -v "${CONFIG_DIR}/data:/data:ro" \
        -v "${CONFIG_DIR}/work:/work" \
        "${IMAGE_NAME}"
fi
