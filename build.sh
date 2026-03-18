#!/bin/bash

BASE_DIR="/mnt/data_1/yuxin.jia/openclaw_test"
IMAGE_NAME="openclaw-bioinfo:latest"

echo "=========================================="
echo "构建 OpenClaw 生信分析环境"
echo "=========================================="

cd "$BASE_DIR"

echo "[1/2] 构建 Docker 镜像..."
docker build \
    -t "$IMAGE_NAME" \
    -f Dockerfile.openclaw-bioinfo \
    .

if [ $? -eq 0 ]; then
    echo ""
    echo "[2/2] 构建成功!"
    echo ""
    echo "=========================================="
    echo "测试运行命令:"
    echo "=========================================="
    echo ""
    echo "docker run --rm -it \\"
    echo "    --bind ${BASE_DIR}/config:/root/.config/openclaw \\"
    echo "    --bind ${BASE_DIR}/skills:/root/.local/share/openclaw/skills \\"
    echo "    --bind ${BASE_DIR}/user_envs:/root/micromamba/envs \\"
    echo "    --bind ${BASE_DIR}/data:/data \\"
    echo "    --bind ${BASE_DIR}/workspace:/workspace \\"
    echo "    $IMAGE_NAME \\"
    echo "    bash"
    echo ""
else
    echo ""
    echo "[错误] 构建失败，请检查日志"
    exit 1
fi
