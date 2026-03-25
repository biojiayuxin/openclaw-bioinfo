#!/bin/bash

# ============================================
# OpenClaw Bioinfo 环境安装脚本
# ============================================

set -e

SCRIPT_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印函数
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# 帮助信息
show_help() {
    cat << EOF
OpenClaw Bioinfo 环境安装脚本 v${SCRIPT_VERSION}

用法: $0 [选项]

选项:
    -d, --dir DIR       指定安装目录 (默认: 当前目录/openclaw-bioinfo)
    -h, --help          显示此帮助信息
    -v, --version       显示版本信息

示例:
    $0                          # 使用默认目录安装
    $0 -d /path/to/install      # 指定安装目录

EOF
    exit 0
}

# 解析参数
INSTALL_DIR=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dir)
            INSTALL_DIR="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            ;;
        -v|--version)
            echo "OpenClaw Bioinfo Installer v${SCRIPT_VERSION}"
            exit 0
            ;;
        *)
            error "未知选项: $1"
            ;;
    esac
done

# 设置默认安装目录
if [ -z "$INSTALL_DIR" ]; then
    INSTALL_DIR="$(pwd)/openclaw-bioinfo"
fi

# 转换为绝对路径
INSTALL_DIR="$(cd "$(dirname "$INSTALL_DIR")" 2>/dev/null && pwd)/$(basename "$INSTALL_DIR")"

echo "=========================================="
echo "  OpenClaw Bioinfo 环境安装脚本"
echo "  版本: ${SCRIPT_VERSION}"
echo "=========================================="
echo ""

# 检查必要的命令
check_dependencies() {
    info "检查系统依赖..."
    
    local missing=()
    
    # 检查 apptainer
    if command -v apptainer &> /dev/null; then
        success "找到 Apptainer"
    else
        warn "未找到 apptainer，安装后请确保已安装"
    fi
    
    # 检查其他必要命令
    for cmd in curl tar base64; do
        if command -v $cmd &> /dev/null; then
            success "找到 $cmd"
        else
            missing+=("$cmd")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        error "缺少必要命令: ${missing[*]}"
    fi
}

# 创建目录结构
create_directories() {
    info "创建目录结构: $INSTALL_DIR"
    
    mkdir -p "$INSTALL_DIR"/{openclaw_config,skills}
    mkdir -p "$INSTALL_DIR"/{micromamba_envs,micromamba_pkgs,micromamba_etc}
    mkdir -p "$INSTALL_DIR"/{pip_packages,data,work}
    
    success "目录结构创建完成"
}

# 生成 openclaw.json
generate_config() {
    info "生成配置文件..."
    
    local config_file="$INSTALL_DIR/openclaw_config/openclaw.json"
    
    cat > "$config_file" << 'EOF'
{
  "env": {
    "API_KEY_1": "YOUR_API_KEY_1",
    "API_KEY_2": "YOUR_API_KEY_2",
    "API_KEY_3": "YOUR_API_KEY_3"
  },
  "models": {
    "mode": "merge",
    "providers": {
      "provider-1": {
        "baseUrl": "YOUR_API_URL_1",
        "apiKey": "${API_KEY_1}",
        "api": "openai-completions",
        "models": [
          {
            "id": "YOUR_MODEL_ID_1",
            "name": "Model 1",
            "api": "openai-completions",
            "reasoning": true,
            "input": ["text", "image"],
            "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}
          }
        ]
      },
      "provider-2": {
        "baseUrl": "YOUR_API_URL_2",
        "apiKey": "${API_KEY_2}",
        "api": "openai-completions",
        "models": [
          {
            "id": "YOUR_MODEL_ID_2",
            "name": "Model 2",
            "api": "openai-completions",
            "reasoning": true,
            "input": ["text", "image"],
            "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}
          }
        ]
      },
      "provider-3": {
        "baseUrl": "YOUR_API_URL_3",
        "apiKey": "${API_KEY_3}",
        "api": "openai-completions",
        "models": [
          {
            "id": "YOUR_MODEL_ID_3",
            "name": "Model 3",
            "api": "openai-completions",
            "reasoning": true,
            "input": ["text", "image"],
            "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "provider-1/YOUR_MODEL_ID_1",
        "fallbacks": []
      },
      "models": {
        "provider-1/YOUR_MODEL_ID_1": {"alias": "model1"},
        "provider-2/YOUR_MODEL_ID_2": {"alias": "model2"},
        "provider-3/YOUR_MODEL_ID_3": {"alias": "model3"}
      },
      "workspace": "/root/.openclaw/workspace",
      "compaction": {"mode": "safeguard"},
      "thinkingDefault": "medium"
    },
    "list": [
      {
        "id": "main",
        "default": true,
        "identity": {
          "name": "BioAgent",
          "theme": "bioinformatics assistant",
          "emoji": "🧬"
        }
      }
    ]
  },
  "gateway": {
    "port": 18789,
    "mode": "local",
    "bind": "lan",
    "controlUi": {
      "allowedOrigins": [
        "http://localhost:18789",
        "http://127.0.0.1:18789",
        "http://localhost:28080",
        "http://127.0.0.1:28080",
        "http://localhost:38080",
        "http://127.0.0.1:38080",
        "http://localhost:48080",
        "http://127.0.0.1:48080"
      ]
    },
    "auth": {
      "mode": "token",
      "token": "bioagent-local-token-2024"
    }
  },
  "skills": {
    "load": {
      "extraDirs": ["/skills"]
    }
  }
}
EOF
    
    success "配置文件生成完成: $config_file"
    echo ""
    echo "配置说明:"
    echo "  - 配置文件包含3个provider，可切换不同API"
    echo "  - 修改 agents.defaults.model.primary 切换模型"
    echo "  - 例如: \"primary\": \"provider-2/YOUR_MODEL_ID_2\""
}

# 生成 run_openclaw_bioinfo.sh
generate_run_script() {
    info "生成启动脚本..."

    local run_script="$INSTALL_DIR/run_openclaw_bioinfo.sh"

    cat > "$run_script" << 'RUNSCRIPT'
#!/bin/bash

# ============================================
# OpenClaw 生信分析环境启动脚本
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIF_FILE="${SCRIPT_DIR}/openclaw-bioinfo.sif"

GATEWAY_PORT="${GATEWAY_PORT:-18789}"
PINCHCHAT_PORT="${PINCHCHAT_PORT:-18080}"

if [[ $# -gt 0 ]]; then
    case "$1" in
        -h|--help)
            echo "用法: $0"
            echo ""
            echo "环境变量:"
            echo "  GATEWAY_PORT     Gateway 首选端口 (默认: 18789, 若占用会自动顺延)"
            echo "  PINCHCHAT_PORT   PinchChat 首选端口 (默认: 18080, 若占用会自动顺延)"
            echo ""
            echo "说明:"
            echo "  启动后默认仅拉起 OpenClaw Gateway，并进入容器交互模式。"
            echo ""
            echo "容器内常用命令:"
            echo "  openclaw tui                                  启动 TUI 终端界面"
            echo "  start-pinchchat                               启动 PinchChat Web 界面"
            echo "  npx -y @larksuite/openclaw-lark install       安装飞书插件"
            echo "  openclaw pairing approve feishu <id>          审批飞书配对"
            exit 0
            ;;
        *)
            echo "错误: 不支持的参数: $1"
            echo "当前脚本不再支持模式参数，请直接运行: $0"
            echo "如需帮助请使用: $0 --help"
            exit 1
            ;;
    esac
fi

echo "=========================================="
echo "OpenClaw 生信分析环境"
echo "=========================================="
echo ""

if ! command -v apptainer &> /dev/null; then
    echo "错误: 未找到 apptainer"
    echo "请安装或激活 Apptainer："
    echo "  conda activate apptainer"
    exit 1
fi

if [ ! -f "${SIF_FILE}" ]; then
    echo "错误: SIF文件不存在: ${SIF_FILE}"
    echo ""
    echo "请将 openclaw-bioinfo.sif 文件放置到以下目录:"
    echo "  ${SCRIPT_DIR}"
    exit 1
fi

if [ ! -d "${SCRIPT_DIR}/openclaw_config" ]; then
    echo "错误: 配置目录不存在"
    echo "请重新运行 install.sh 进行安装"
    exit 1
fi

echo "SIF文件: ${SIF_FILE}"
echo "配置目录: ${SCRIPT_DIR}"
echo "Gateway 端口: ${GATEWAY_PORT}"
echo ""

# ============================================
# 额外挂载目录示例（复制到下方 --bind 行之前）:
#   --bind "/your/host/path:/container/path:ro" \
# 建议使用 :ro 只读挂载保护数据
# ============================================

apptainer run \
    --no-home \
    --env GATEWAY_PORT="${GATEWAY_PORT}" \
    --env PINCHCHAT_PORT="${PINCHCHAT_PORT}" \
    --bind "${SCRIPT_DIR}/openclaw_config:/root/.openclaw" \
    --bind "${SCRIPT_DIR}/skills:/skills" \
    --bind "${SCRIPT_DIR}/micromamba_envs:/root/micromamba/envs" \
    --bind "${SCRIPT_DIR}/micromamba_pkgs:/root/micromamba/pkgs" \
    --bind "${SCRIPT_DIR}/micromamba_etc:/root/micromamba/etc" \
    --bind "${SCRIPT_DIR}/pip_packages:/pip_packages" \
    --bind "${SCRIPT_DIR}/data:/data:ro" \
    --bind "${SCRIPT_DIR}/work:/work" \
    "${SIF_FILE}"
RUNSCRIPT

    chmod +x "$run_script"

    success "启动脚本生成完成: $run_script"
}


# 显示安装完成信息
show_completion() {
    echo ""
    echo "=========================================="
    echo "  安装完成!"
    echo "=========================================="
    echo ""
    echo "安装目录: $INSTALL_DIR"
    echo ""
    echo "目录结构:"
    echo "  ${INSTALL_DIR}/"
    echo "  ├── openclaw_config/     # OpenClaw 配置"
    echo "  ├── workspace/           # 工作空间"
    echo "  ├── skills/              # 技能目录"
    echo "  ├── data/                # 数据目录 (只读挂载)"
    echo "  ├── work/                # 工作目录"
    echo "  ├── micromamba_*/        # Conda 环境"
    echo "  ├── pip_packages/        # pip 安装的包"
    echo "  ├── openclaw-bioinfo.sif  # SIF 文件 (需放置)"
    echo "  └── run_openclaw_bioinfo.sh  # 启动脚本"
    echo ""
    echo "下一步:"
    echo "  1. 编辑配置文件，填入 API 信息:"
    echo "     ${INSTALL_DIR}/openclaw_config/openclaw.json"
    echo ""
    echo "  2. 将 openclaw-bioinfo.sif 文件复制到:"
    echo "     ${INSTALL_DIR}/"
    echo ""
    echo "  3. 如需挂载额外目录，编辑 run_openclaw_bioinfo.sh"
    echo "     参考脚本中的挂载示例注释"
    echo ""
    echo "  4. 运行启动脚本 (启动后进入容器交互模式):"
    echo "     cd ${INSTALL_DIR}"
    echo "     ./run_openclaw_bioinfo.sh"
    echo ""
    echo "  5. 容器内可用命令:"
    echo "     openclaw tui          # 启动 TUI 终端界面"
    echo "     start-pinchchat       # 启动 PinchChat Web 界面"
    echo ""
    echo "  6. 飞书接入 (在容器内执行):"
    echo "     npx -y @larksuite/openclaw-lark install"
    echo "     openclaw pairing approve feishu <id>"
}

# 主函数
main() {
    check_dependencies
    
    # 确认安装目录
    echo ""
    echo "安装目录: $INSTALL_DIR"
    read -p "确认安装? [Y/n]: " confirm
    confirm=${confirm:-Y}
    
    if [[ ! "$confirm" =~ ^[Yy] ]]; then
        echo "安装已取消"
        exit 0
    fi
    
    # 检查目录是否存在
    if [ -d "$INSTALL_DIR" ]; then
        warn "目录已存在: $INSTALL_DIR"
        read -p "是否覆盖? [y/N]: " overwrite
        if [[ ! "$overwrite" =~ ^[Yy] ]]; then
            echo "安装已取消"
            exit 0
        fi
        rm -rf "$INSTALL_DIR"
    fi
    
    create_directories
    
    generate_config
    generate_run_script
    show_completion
}

# 执行主函数
main

exit 0
