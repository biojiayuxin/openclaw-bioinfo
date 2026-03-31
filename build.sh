#!/bin/bash

BASE_DIR="/mnt/data_1/yuxin.jia/openclaw_test"
IMAGE_NAME="openclaw-bioinfo:latest"
OPENCLAW_BASE_IMAGE="${OPENCLAW_BASE_IMAGE:-ghcr.io/openclaw/openclaw:latest}"

echo "=========================================="
echo "构建 OpenClaw 生信分析环境"
echo "=========================================="

cd "$BASE_DIR"

echo "[1/2] 构建 Docker 镜像..."
echo "使用 OpenClaw 基础镜像: ${OPENCLAW_BASE_IMAGE}"
docker build \
    --pull \
    --build-arg OPENCLAW_BASE_IMAGE="${OPENCLAW_BASE_IMAGE}" \
    -t "$IMAGE_NAME" \
    -f Dockerfile.openclaw-bioinfo \
    .

if [ $? -eq 0 ]; then
    echo ""
    echo "[2/2] 构建成功!"
    echo ""
    echo "=========================================="
    echo "测试运行命令 (Docker):"
    echo "=========================================="
    echo ""
    echo "docker run --rm -it \\" 
    echo "    -e GATEWAY_PORT=18789 \\" 
    echo "    -v ${BASE_DIR}/openclaw_config:/openclaw-home/.openclaw \\" 
    echo "    -v ${BASE_DIR}/skills:/skills \\" 
    echo "    -v ${BASE_DIR}/workspace:/openclaw-home/workspace \\" 
    echo "    -v ${BASE_DIR}/micromamba_envs:/openclaw-home/micromamba/envs \\" 
    echo "    -v ${BASE_DIR}/micromamba_pkgs:/openclaw-home/micromamba/pkgs \\" 
    echo "    -v ${BASE_DIR}/micromamba_etc:/openclaw-home/micromamba/etc \\" 
    echo "    -v ${BASE_DIR}/pip_packages:/pip_packages \\" 
    echo "    -v ${BASE_DIR}/data:/data:ro \\" 
    echo "    -v ${BASE_DIR}/work:/work \\" 
    echo "    $IMAGE_NAME"
    echo ""
    echo "说明:"
    echo "  - OpenClaw HOME 为 /openclaw-home"
    echo "  - 配置目录挂载到 /openclaw-home/.openclaw"
    echo "  - workspace 挂载到 /openclaw-home/workspace"
    echo ""
else
    echo ""
    echo "[错误] 构建失败，请检查日志"
    exit 1
fi

