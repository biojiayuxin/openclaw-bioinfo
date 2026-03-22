# OpenClaw Bioinfo

基于 OpenClaw 的生信分析智能体容器化项目。

当前已完成并验证：
- Docker 环境下 PinchChat 可正常连接和对话
- Apptainer 环境下 PinchChat 可正常连接和对话
- 首次使用 PinchChat 支持 device pairing / approve
- 已集成飞书官方插件安装与审批脚本，支持飞书快速部署
- Dashboard 保留为兜底方案

## 代码改动概览

本轮主要改动如下：

### 1. PinchChat 集成方式调整为双端口方案

当前采用双端口方案：
- Gateway：`18789`
- PinchChat 静态页面：`18080`（远程默认）

这样更容易调试，也更适合 Apptainer 部署。

### 2. 修改的主要文件

```text
openclaw_test/
├── Dockerfile.openclaw-bioinfo   # 镜像定义，包含 PinchChat 静态文件
├── entrypoint.sh                 # 容器入口，支持 pinchchat/dashboard/tui
├── build.sh                      # Docker 镜像构建脚本
├── build_sif.sh                  # SIF 构建脚本
├── install.sh                    # 安装脚本，生成配置和启动脚本
├── run_test.sh                   # Docker 测试脚本
├── pinchchat-dist/               # PinchChat 静态构建产物
└── README.md                     # 项目说明
```

### 3. 安装目录增加的脚本

安装目录 `openclaw-bioinfo/` 现在包含：

- `run_openclaw_bioinfo.sh`：启动主服务（含 `--gateway` 仅启动网关模式）
- `run_openclaw_devices.sh`：查看和审批设备
- `run_openclaw_add_feishu.sh`：飞书插件安装、审批与功能开关

其中 `run_openclaw_devices.sh` 支持：

```bash
./run_openclaw_devices.sh list
./run_openclaw_devices.sh approve <request-id>
./run_openclaw_devices.sh approve-latest
```

其中 `run_openclaw_add_feishu.sh` 支持：

```bash
# 安装飞书官方插件（扫码/凭证配置）
./run_openclaw_add_feishu.sh --install

# 审批飞书配对
./run_openclaw_add_feishu.sh --approve <feishu_id>

# 飞书增强功能开关（可单独开启）
./run_openclaw_add_feishu.sh --streaming
./run_openclaw_add_feishu.sh --card_more
./run_openclaw_add_feishu.sh --thread_session
./run_openclaw_add_feishu.sh --require_mention

# 一次性全开
./run_openclaw_add_feishu.sh --open_all
```

### 4. 默认端口策略

#### 远程服务器默认端口
- PinchChat 页面：`18080`
- Gateway：`18789`

#### 本地推荐端口
- 页面：`28080`
- Gateway：`28789`

#### 本地允许的页面端口
在 `openclaw.json` 的 `gateway.controlUi.allowedOrigins` 中，默认允许：
- `28080`
- `38080`
- `48080`

这样用户本地端口冲突时，不需要再改配置文件。

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

输出文件：

```text
openclaw-bioinfo-slim.sif
```

## 3. Docker 测试

```bash
./run_test.sh --pinchchat
```

本地访问：
- 页面：`http://localhost:28080`
- Gateway：`ws://localhost:28789`

## 4. Apptainer 运行

安装目录中运行：

```bash
./run_openclaw_bioinfo.sh --pinchchat
```

本地 SSH 隧道：

```bash
ssh -L 28080:127.0.0.1:18080 -L 28789:127.0.0.1:18789 -p <SSH端口> <用户名>@<服务器IP>
```

浏览器访问：

```text
http://localhost:28080
```

PinchChat 登录填写：

```text
Gateway URL: ws://localhost:28789
Token: <gateway.auth.token>
```

## 5. 飞书快速部署（新增）

推荐流程：

```bash
# 1) 安装/配置飞书官方插件
./run_openclaw_add_feishu.sh --install

# 2) 开启推荐飞书能力（流式输出/卡片更多内容/多任务并行/仅@回复）
./run_openclaw_add_feishu.sh --open_all

# 3) 启动网关（无需启动 PinchChat 前端）
./run_openclaw_bioinfo.sh --gateway
```

如出现飞书 pairing 待审批：

```bash
./run_openclaw_add_feishu.sh --approve <feishu_id>
```

## 首次配对流程

首次在某个浏览器登录 PinchChat 时，可能出现 pending 设备请求。

处理方式：

```bash
./run_openclaw_devices.sh approve-latest
```

如果要手动查看：

```bash
./run_openclaw_devices.sh list
```

## 兼容性说明

### 1. 浏览器要求
PinchChat 的 device auth 依赖浏览器 WebCrypto 对 `Ed25519` 的支持。

若浏览器不支持，会出现类似报错：

```text
Failed to load device identity
Algorithm: Unrecognized name
```

此时需要更换浏览器。

### 2. 模型兼容性
部分模型在 function schema 上与 OpenClaw 不兼容，可能出现：

```text
Invalid schema for function 'agents_list'
```

此时需要切换到已验证可用的模型。

## 当前推荐的最终交互方式

对于最终用户，建议优先使用下面几条命令：

```bash
# 飞书官方插件快速部署
./run_openclaw_add_feishu.sh --install
./run_openclaw_add_feishu.sh --open_all

# 飞书场景仅启动网关
./run_openclaw_bioinfo.sh --gateway

# PinchChat 场景
./run_openclaw_bioinfo.sh --pinchchat
./run_openclaw_devices.sh approve-latest

# 兜底 Dashboard
./run_openclaw_bioinfo.sh --dashboard
```

这样用户可以按需选择：
- 飞书机器人快速部署与接入
- PinchChat Web 对话
- 必要时回退到 Dashboard
