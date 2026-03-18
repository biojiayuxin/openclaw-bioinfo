#!/bin/bash

# ============================================
# OpenClaw 生信分析环境启动脚本
# ============================================

# ============================================
# 请修改以下两个路径
# ============================================
CONFIG_DIR="/mnt/data_1/yuxin.jia/openclaw_test_configs"
SIF_FILE="/mnt/data_1/yuxin.jia/openclaw_test/openclaw-bioinfo-slim.sif"
# ============================================

echo "=========================================="
echo "OpenClaw 生信分析环境"
echo "=========================================="
echo ""

# 检查 apptainer
if ! command -v apptainer &> /dev/null; then
    echo "错误: 未找到 apptainer"
    echo ""
    echo "请安装 Apptainer："
    echo "  conda create -n apptainer -c conda-forge apptainer"
    exit 1
fi

echo "使用容器运行时: apptainer"
echo ""

# 检查SIF文件是否存在
if [ ! -f "${SIF_FILE}" ]; then
    echo "错误: SIF文件不存在: ${SIF_FILE}"
    echo "请修改脚本中的 SIF_FILE 变量"
    exit 1
fi

# 检查配置目录是否存在
if [ ! -d "${CONFIG_DIR}" ]; then
    echo "错误: 配置目录不存在: ${CONFIG_DIR}"
    echo "请修改脚本中的 CONFIG_DIR 变量"
    exit 1
fi

echo "SIF文件: ${SIF_FILE}"
echo "配置目录: ${CONFIG_DIR}"
echo ""
echo "启动中..."
echo ""

# ============================================
# 以下为系统默认挂载，请勿修改
# ============================================
apptainer run \
    --no-home \
    --bind "${CONFIG_DIR}/openclaw_config:/root/.openclaw" \
    --bind "${CONFIG_DIR}/workspace:/root/.openclaw/workspace" \
    --bind "${CONFIG_DIR}/skills:/skills" \
    --bind "${CONFIG_DIR}/micromamba_envs:/root/micromamba/envs" \
    --bind "${CONFIG_DIR}/micromamba_pkgs:/root/micromamba/pkgs" \
    --bind "${CONFIG_DIR}/micromamba_etc:/root/micromamba/etc" \
    --bind "${CONFIG_DIR}/pip_packages:/pip_packages" \
    --bind "${CONFIG_DIR}/data:/data:ro" \
    --bind "${CONFIG_DIR}/work:/work" \
    # ============================================
    # 额外挂载目录示例（复制并修改后取消注释）
    # 建议使用 :ro 只读挂载保护数据
    # ============================================
    # --bind "/your/host/path:/container/path:ro" \
    "${SIF_FILE}"
