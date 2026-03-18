# OpenClaw Bioinfo

基于 OpenClaw 的生信分析智能体容器化环境，支持 TUI 和 Dashboard 两种运行模式。

## 项目架构

```
openclaw_test/
├── Dockerfile.openclaw-bioinfo   # Docker 镜像定义
├── entrypoint.sh                 # 容器入口脚本，支持 TUI/Dashboard 模式切换
├── install.sh                    # 安装脚本（生成配置和启动脚本）
├── run_openclaw_bioinfo.sh       # 运行脚本（本项目测试用）
├── build.sh                      # Docker 镜像构建脚本
├── build_sif.sh                  # SIF 文件构建脚本
├── micromamba-2.5.0-2.tar.bz2    # Micromamba 离线安装包
└── openclaw-bioinfo-slim.sif     # 构建好的 SIF 文件
```

## 主要开发内容

### 1. 容器环境

- 基础镜像：`alpine/openclaw:latest`
- 包含 Micromamba 包管理器
- 预装生信工具：samtools、bedtools、python、pip
- 配置国内镜像源（清华源）

### 2. 运行模式

支持两种运行模式：

- **TUI 模式**（默认）：终端交互界面
- **Dashboard 模式**：Web 图形界面，支持远程访问

### 3. 远程访问支持

Dashboard 模式提供完整的远程访问指南：
- 自动检测服务器 IP
- 自动提取 Token
- 提供 SSH 端口转发命令
- 生成带 Token 的访问链接

## 安装与使用

### 前置要求

- Apptainer（原 Singularity）
- Docker（仅构建时需要）

### 安装步骤

1. 运行安装脚本：

```bash
chmod +x install.sh
./install.sh -d /path/to/install
```

安装脚本会创建以下目录结构：

```
/path/to/install/
├── openclaw_config/          # OpenClaw 配置目录
│   └── openclaw.json         # 配置文件（需编辑填入 API Key）
├── workspace/                # 工作空间
├── skills/                   # 技能目录
├── data/                     # 数据目录（只读挂载）
├── work/                     # 工作目录
├── micromamba_envs/          # Conda 环境存储
├── micromamba_pkgs/          # Conda 包缓存
├── micromamba_etc/           # Micromamba 配置
├── pip_packages/             # pip 安装的包
├── openclaw-bioinfo-slim.sif # SIF 文件（需放置）
└── run_openclaw_bioinfo.sh   # 启动脚本
```

2. 编辑配置文件，填入 API Key：

```bash
vim /path/to/install/openclaw_config/openclaw.json
```

3. 将 SIF 文件复制到安装目录：

```bash
cp openclaw-bioinfo-slim.sif /path/to/install/
```

### 使用方法

**TUI 模式（默认）：**

```bash
cd /path/to/install
./run_openclaw_bioinfo.sh
```

**Dashboard 模式：**

```bash
cd /path/to/install
./run_openclaw_bioinfo.sh --dashboard
```

Dashboard 模式会输出远程访问指南：

```
==========================================
Dashboard 模式
==========================================

Gateway 已在端口 18789 启动

远程访问步骤:

1. 在本地终端执行端口转发:
   ssh -L 18789:127.0.0.1:18789 -p <SSH端口> <用户名>@<服务器IP>

2. 在本地浏览器访问:
   http://127.0.0.1:18789?token=<token>

按 Ctrl+C 退出
```

### 查看帮助

```bash
./run_openclaw_bioinfo.sh --help
```

## 构建

### 构建 Docker 镜像

```bash
./build.sh
```

### 构建 SIF 文件

```bash
./build_sif.sh
```

## 配置说明

配置文件 `openclaw.json` 主要配置项：

| 配置项 | 说明 |
|--------|------|
| `env.API_KEY_*` | API 密钥 |
| `models.providers` | 模型提供商配置 |
| `agents.defaults.model.primary` | 默认使用的模型 |
| `gateway.port` | Gateway 端口（默认 18789） |
| `gateway.auth.token` | Dashboard 访问 Token |

## 注意事项

1. 远程访问 Dashboard 需要通过 SSH 端口转发，不支持直接通过服务器 IP 访问
2. Token 从配置文件中自动提取，首次使用请检查配置文件中的 Token 设置
3. 数据目录 `/data` 默认只读挂载，保护数据安全
