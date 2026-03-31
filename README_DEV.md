# OpenClaw Bioinfo

基于 OpenClaw 的生信分析智能体容器化项目。

当前已完成并验证：
- 已移除 PinchChat 内置集成，镜像回归纯净 OpenClaw；用户按需在容器内自行安装插件
- 默认启动仅拉起 Gateway，其他能力按需在容器内安装和启用
- Gateway 后台日志已重定向到文件，避免持续占用容器交互终端
- 已集成飞书官方插件安装与审批指引，支持飞书快速部署
- 支持自动查找可用端口
- 已修复 Apptainer 非 root 场景下配置 / workspace 路径不一致导致的 Gateway 启动卡住问题
- `build.sh`、`install.sh`、运行目录挂载路径已统一到 `/openclaw-home` 布局

## 代码改动概览

本轮主要改动如下：

### 1. 启动方式优化

启动后默认进入容器交互模式：
- 自动启动 Gateway（自动查找可用端口）
- 进入交互式 shell
- 用户可按需运行 TUI，或自行安装并启用需要的插件

### 2. 修改的主要文件

```text
openclaw_test/
├── Dockerfile.openclaw-bioinfo   # 镜像定义（纯净 OpenClaw + 生信依赖）
├── entrypoint.sh                 # 容器入口，启动 gateway + 交互模式
├── build.sh                      # Docker 镜像构建脚本
├── build_sif.sh                  # SIF 构建脚本
├── install.sh                    # 安装脚本，生成配置和启动脚本
└── README.md                     # 项目说明
```

### 3. 安装目录结构

安装目录 `openclaw-bioinfo/` 包含：

- `openclaw_config/`：挂载到 `/openclaw-home/.openclaw`
- `workspace/`：挂载到 `/openclaw-home/workspace`
- `skills/`：挂载到 `/skills`
- `micromamba_envs/`：挂载到 `/openclaw-home/micromamba/envs`
- `micromamba_pkgs/`：挂载到 `/openclaw-home/micromamba/pkgs`
- `micromamba_etc/`：挂载到 `/openclaw-home/micromamba/etc`
- `pip_packages/`：挂载到 `/pip_packages`
- `data/`：挂载到 `/data`（只读）
- `work/`：挂载到 `/work`
- `run_openclaw_bioinfo.sh`：启动容器（默认只启动 Gateway 并进入交互模式）

### 4. 默认端口策略

- Gateway：`18789`（自动查找可用端口）

可通过环境变量覆盖：
```bash
GATEWAY_PORT=28789 ./run_openclaw_bioinfo.sh
```

## 运行方法

## 1. 构建 Docker 镜像

```bash
cd /mnt/data_1/yuxin.jia/openclaw_test
./build.sh
```

## 2. 构建 SIF 文件

```bash
./build_sif.sh
```

输出文件：`openclaw-bioinfo.sif`

## 3. 安装运行目录

```bash
./install.sh -d <安装目录>
```

## 4. Apptainer 运行

```bash
cd <安装目录>
./run_openclaw_bioinfo.sh
```

说明：
- `run_openclaw_bioinfo.sh` 不再接受历史模式参数（如 `--dashboard`）
- 启动后默认只拉起 Gateway，并留在容器内供你按需执行命令
- 容器内 `HOME` 使用 `/openclaw-home`
- `workspace` 显式挂载到 `/openclaw-home/workspace`，避免 Apptainer 环境下自动创建路径带来的权限和持久化问题

启动后进入容器交互模式，可用命令：

```bash
# 查看帮助
help

# 启动 TUI 终端界面
openclaw tui

# 实时查看 Gateway 日志
logs-gw

# 查看 Gateway 最近 200 行日志
logs-gw-last

# 安装飞书插件
npx -y @larksuite/openclaw-lark install

# 审批飞书配对
openclaw pairing approve feishu <feishu_id>
```

## 5. 远程访问

### 5.1 Gateway / Dashboard

SSH 端口转发说明：
- `<本地网关端口>`：你本机空闲端口（可自定义，例如 `28888`）
- `<网关端口>`：容器实际 Gateway 端口（以启动输出为准）

```bash
ssh -L <本地网关端口>:127.0.0.1:<网关端口> -p <SSH端口> <用户名>@<服务器IP>
```

浏览器访问：

```text
http://127.0.0.1:<本地网关端口>?token=<token>
```

## 6. 飞书快速部署

在容器内执行：

```bash
# 安装飞书插件
npx -y @larksuite/openclaw-lark install

# 开启飞书增强功能
openclaw config set channels.feishu.streaming true
openclaw config set channels.feishu.threadSession true
openclaw config set channels.feishu.requireMention true
```

## 已修复问题

1. 退出容器后，Gateway 进程持续运行并占用端口的问题已修复（已增加退出清理流程）。
2. `run_openclaw_bioinfo.sh` 启动后会明确区分“首选端口”和“实际端口”，并且 SSH 转发示例会随实际可用端口动态更新。
3. Apptainer 非 root 场景下，原先 `/root/.openclaw/workspace` 与实际可写路径不一致，导致 Gateway 启动等待 180 秒的问题已修复。

## 兼容性说明

### 1. 模型兼容性
部分模型在 function schema 上与 OpenClaw 不兼容，需要切换到已验证可用的模型。
