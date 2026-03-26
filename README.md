# OpenClaw Bioinfo 使用说明

本项目提供两种使用方式：

1. **本地克隆代码自行构建**（Docker -> SIF）
2. **直接从 Figshare 下载 SIF + install.sh 快速安装**

---

## 方式一：本地构建（推荐给需要二次定制的用户）

### 1) 克隆代码

```bash
git clone <你的仓库地址>
cd openclaw_test
```

### 2) 构建 Docker 镜像

```bash
./build.sh
```

### 3) 打包 SIF

```bash
./build_sif.sh
```

打包完成后会生成：

- `openclaw-bioinfo.sif`

### 4) 安装并生成运行脚本

```bash
./install.sh -d <安装目录>
```

安装目录中会生成：

- `openclaw-bioinfo.sif`（你需要放入该目录）
- `run_openclaw_bioinfo.sh`

### 5) 运行

```bash
cd <安装目录>
./run_openclaw_bioinfo.sh
```

---

## 方式二：从 Figshare 直接下载（推荐给普通用户）

从 Figshare 下载以下文件（下载地址请自行补充）：

- `openclaw-bioinfo.sif`
- `install.sh`

然后执行：

```bash
chmod +x install.sh
./install.sh -d <安装目录>
```

把下载的 `openclaw-bioinfo.sif` 放到安装目录后，运行：

```bash
cd <安装目录>
./run_openclaw_bioinfo.sh
```

---

## 运行后说明

默认行为：

- 自动启动 Gateway（会自动查找可用端口）
- 进入容器交互环境

容器内常用命令：

```bash
openclaw tui
logs-gw
logs-gw-last
```

远程访问 Dashboard（SSH 转发）：

```bash
ssh -L <本地端口>:127.0.0.1:<容器内网关端口> -p <SSH端口> <用户名>@<服务器IP>
```

浏览器访问：

```text
http://127.0.0.1:<本地端口>?token=<token>
```