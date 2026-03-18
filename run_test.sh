#!/bin/bash

BUILD_DIR="/mnt/data_1/yuxin.jia/openclaw_test"
CONFIG_DIR="/mnt/data_1/yuxin.jia/openclaw-bioinfo"

echo "=========================================="
echo "OpenClaw 生信分析环境测试"
echo "=========================================="
echo ""

docker run --rm -it \
    -u root \
    -v "${CONFIG_DIR}/openclaw_config:/root/.openclaw" \
    -v "${CONFIG_DIR}/workspace:/root/.openclaw/workspace" \
    -v "${CONFIG_DIR}/skills:/skills" \
    -v "${CONFIG_DIR}/micromamba_envs:/root/micromamba/envs" \
    -v "${CONFIG_DIR}/micromamba_pkgs:/root/micromamba/pkgs" \
    -v "${CONFIG_DIR}/micromamba_etc:/root/micromamba/etc" \
    -v "${CONFIG_DIR}/pip_packages:/pip_packages" \
    -v "${CONFIG_DIR}/data:/data:ro" \
    -v "${CONFIG_DIR}/work:/work" \
    openclaw-bioinfo:latest
