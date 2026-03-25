# OpenClaw Bioinfo

基于 OpenClaw 的生信分析智能体容器化项目。

当前已完成并验证：
- Docker 环境下 PinchChat 可正常连接和对话
- Apptainer 环境下 PinchChat 可正常连接和对话
- 首次使用 PinchChat 支持 device pairing / approve
- 已集成飞书官方插件安装与审批脚本，支持飞书快速部署
- 默认启动仅拉起 Gateway，其他能力按需在容器内启动
- 支持自动查找可用端口

## 代码改动概览

本轮主要改动如下：

### 1. 启动方式优化

启动后默认进入容器交互模式：
- 自动启动 Gateway（自动查找可用端口）
- 进入交互式 shell
- 用户可按需选择运行 TUI、PinchChat 或配置飞书

### 2. 修改的主要文件

```text
openclaw_test/
├── Dockerfile.openclaw-bioinfo   # 镜像定义，包含 PinchChat 静态文件
├── entrypoint.sh                 # 容器入口，启动 gateway + 交互模式
├── build.sh                      # Docker 镜像构建脚本
├── build_sif.sh                  # SIF 构建脚本
├── install.sh                    # 安装脚本，生成配置和启动脚本
├── pinchchat-dist/               # PinchChat 静态构建产物
└── README.md                     # 项目说明
```

### 3. 安装目录脚本

安装目录 `openclaw-bioinfo/` 包含：

- `run_openclaw_bioinfo.sh`：启动容器（默认只启动 Gateway 并进入交互模式）

### 4. 默认端口策略

- Gateway：`18789`（自动查找可用端口）
- PinchChat 页面：`18080`（启动时自动查找可用端口）

可通过环境变量覆盖：
```bash
GATEWAY_PORT=28789 PINCHCHAT_PORT=28080 ./run_openclaw_bioinfo.sh
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

## 3. Apptainer 运行

```bash
cd openclaw-bioinfo
./run_openclaw_bioinfo.sh
```

说明：
- `run_openclaw_bioinfo.sh` 不再接受 `--dashboard`、`--pinchchat` 等模式参数
- 启动后默认只拉起 Gateway，并留在容器内供你按需执行命令

启动后进入容器交互模式，可用命令：

```bash
# 查看帮助
help

# 启动 TUI 终端界面
openclaw tui

# 启动 PinchChat Web 界面
start-pinchchat

# 安装飞书插件
npx -y @larksuite/openclaw-lark install

# 审批飞书配对
openclaw pairing approve feishu <feishu_id>
```

## 4. 远程访问

SSH 端口转发（将 `<网关端口>` 替换为容器启动时显示的 Gateway 端口）：

```bash
ssh -L <网关端口>:127.0.0.1:<网关端口> -p <SSH端口> <用户名>@<服务器IP>
```

浏览器访问 Gateway Dashboard：

```text
http://localhost:<网关端口>?token=<token>
```

## 5. 飞书快速部署

在容器内执行：

```bash
# 安装飞书插件
npx -y @larksuite/openclaw-lark install

# 开启飞书增强功能
openclaw config set channels.feishu.streaming true
openclaw config set channels.feishu.threadSession true
openclaw config set channels.feishu.requireMention true
```

## 首次配对流程

首次在某个浏览器登录 PinchChat 时，可能出现 pending 设备请求。

在容器内执行：

```bash
openclaw pairing list
openclaw pairing approve <request-id>
```

## 下一步待解决 BUG

1. [已解决，待持续观察] 退出容器后，Gateway 进程持续运行并占用端口的问题已修复（已增加退出清理流程），后续继续观察是否在不同环境下稳定。
2. [已解决，待持续观察] `run_openclaw_bioinfo.sh` 启动后会明确区分“首选端口”和“实际端口”，并且 SSH 转发示例会随实际可用端口动态更新。
3. PinchChat 的 SSH 转发说明需要更明确：明确区分“本地页面端口”（浏览器访问的本地端口）与“容器内 PinchChat 端口”（`start-pinchchat` 实际监听端口），并给出完整示例。

## 兼容性说明

### 1. 浏览器要求
PinchChat 的 device auth 依赖浏览器 WebCrypto 对 `Ed25519` 的支持。

若浏览器不支持，需要更换浏览器。

### 2. 模型兼容性
部分模型在 function schema 上与 OpenClaw 不兼容，需要切换到已验证可用的模型。
