#!/bin/bash

BUILD_DIR="/mnt/data_1/yuxin.jia/openclaw_test"
SIF_OUTPUT="${BUILD_DIR}/openclaw-bioinfo-slim.sif"

echo "=========================================="
echo "打包 OpenClaw 生信分析环境为 SIF 文件"
echo "=========================================="
echo ""

# 检查apptainer是否可用
if ! command -v apptainer &> /dev/null; then
    echo "错误: apptainer 未安装或未激活"
    echo "请运行: conda activate apptainer"
    exit 1
fi

# 检查Docker镜像是否存在
if ! docker images openclaw-bioinfo:latest | grep -q openclaw-bioinfo; then
    echo "错误: Docker镜像 openclaw-bioinfo:latest 不存在"
    echo "请先运行: docker build -t openclaw-bioinfo:latest -f Dockerfile.openclaw-bioinfo ."
    exit 1
fi

echo "正在从Docker镜像构建SIF文件..."
echo "输出: ${SIF_OUTPUT}"
echo ""

apptainer build "${SIF_OUTPUT}" docker-daemon://openclaw-bioinfo:latest

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "构建成功!"
    echo "=========================================="
    echo ""
    echo "SIF文件: ${SIF_OUTPUT}"
    ls -lh "${SIF_OUTPUT}"
    echo ""
    echo "运行测试:"
    echo "  cd ${BUILD_DIR}"
    echo "  ./run_openclaw_bioinfo.sh --pinchchat"
    echo "  # 或 ./run_openclaw_bioinfo.sh --dashboard"
else
    echo ""
    echo "构建失败，请检查错误信息"
    exit 1
fi
